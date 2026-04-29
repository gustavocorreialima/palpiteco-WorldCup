/**
 * Ranking Cache — Redis strategy for real-time leaderboards.
 *
 * Data structure: Redis Sorted Set per scope.
 *   Key pattern:  ranking:{scope}:{scopeId}   (e.g. ranking:global:0, ranking:group:uuid)
 *   Member:       userId
 *   Score:        composite — encodes points + accuracy to preserve tiebreaks
 *                 score = points * 1_000_000 + Math.round(accuracy_pct * 100)
 *
 * Why Sorted Set over DB query on every request:
 *   - ZREVRANGE is O(log N + M) — sub-millisecond even at 1M users
 *   - Atomic ZADD / ZINCRBY prevents race conditions during match settlement
 *   - TTL-less: scores persist; DB is source of truth; Redis is read cache
 */

import { Redis } from "ioredis";

export type RankingScope = "global" | "group" | "competition";

export interface RankedEntry {
  userId: string;
  points: number;
  accuracyPct: number;
  rank: number;
}

export interface UserScore {
  points: number;
  accuracyPct: number;
}

const POINTS_MULTIPLIER = 1_000_000;

function encodeScore(points: number, accuracyPct: number): number {
  return points * POINTS_MULTIPLIER + Math.round(accuracyPct * 100);
}

function decodeScore(encoded: number): UserScore {
  const points     = Math.floor(encoded / POINTS_MULTIPLIER);
  const accuracyPct = (encoded % POINTS_MULTIPLIER) / 100;
  return { points, accuracyPct };
}

function rankingKey(scope: RankingScope, scopeId: string): string {
  return `ranking:${scope}:${scopeId}`;
}

// ------------------------------------------------------------------
// Cache write operations (called by bet settlement worker)
// ------------------------------------------------------------------

export async function upsertUserScore(
  redis: Redis,
  scope: RankingScope,
  scopeId: string,
  userId: string,
  score: UserScore,
): Promise<void> {
  const encoded = encodeScore(score.points, score.accuracyPct);
  await redis.zadd(rankingKey(scope, scopeId), encoded, userId);
}

export async function removeUserFromRanking(
  redis: Redis,
  scope: RankingScope,
  scopeId: string,
  userId: string,
): Promise<void> {
  await redis.zrem(rankingKey(scope, scopeId), userId);
}

// ------------------------------------------------------------------
// Cache read operations (called by API handlers)
// ------------------------------------------------------------------

/**
 * Returns paginated ranking entries with rank numbers.
 * offset=0, limit=20 → top 20.
 */
export async function getTopRanking(
  redis: Redis,
  scope: RankingScope,
  scopeId: string,
  offset = 0,
  limit  = 20,
): Promise<RankedEntry[]> {
  const results = await redis.zrevrange(
    rankingKey(scope, scopeId),
    offset,
    offset + limit - 1,
    "WITHSCORES",
  );

  const entries: RankedEntry[] = [];
  for (let i = 0; i < results.length; i += 2) {
    const userId  = results[i];
    const encoded = parseFloat(results[i + 1]);
    const decoded = decodeScore(encoded);
    entries.push({
      userId,
      ...decoded,
      rank: offset + i / 2 + 1,
    });
  }
  return entries;
}

/**
 * Returns a user's current rank + score within a scope.
 * Returns null if the user has no score (no bets in scope).
 */
export async function getUserRank(
  redis: Redis,
  scope: RankingScope,
  scopeId: string,
  userId: string,
): Promise<{ rank: number } & UserScore | null> {
  const [rankRaw, scoreRaw] = await Promise.all([
    redis.zrevrank(rankingKey(scope, scopeId), userId),
    redis.zscore(rankingKey(scope, scopeId), userId),
  ]);

  if (rankRaw === null || scoreRaw === null) return null;

  const decoded = decodeScore(parseFloat(scoreRaw));
  return { rank: rankRaw + 1, ...decoded };
}

/**
 * Bootstraps a ranking key from DB results.
 * Called on cold start or after a Redis flush.
 */
export async function seedRanking(
  redis: Redis,
  scope: RankingScope,
  scopeId: string,
  entries: Array<{ userId: string; points: number; accuracyPct: number }>,
): Promise<void> {
  if (entries.length === 0) return;

  const pipeline = redis.pipeline();
  const key = rankingKey(scope, scopeId);

  for (const e of entries) {
    pipeline.zadd(key, encodeScore(e.points, e.accuracyPct), e.userId);
  }
  await pipeline.exec();
}

/**
 * Total count of ranked users in a scope.
 */
export async function getRankingSize(
  redis: Redis,
  scope: RankingScope,
  scopeId: string,
): Promise<number> {
  return redis.zcard(rankingKey(scope, scopeId));
}
