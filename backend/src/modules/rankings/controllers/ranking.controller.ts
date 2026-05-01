import { FastifyInstance } from "fastify";
import { supabase } from "../../../shared/database/supabase";

export async function rankingRoutes(app: FastifyInstance) {

  // Global ranking
  app.get("/global", async (_req, reply) => {
    const { data, error } = await supabase
      .from("users")
      .select("id, username, display_name, avatar_initials, avatar_color, points, accuracy, streak, rank, level, xp, bets_total, bets_correct, bets_exact, rank_variation, badges")
      .order("points", { ascending: false })
      .order("accuracy", { ascending: false })
      .limit(100);

    if (error) return reply.status(500).send({ error: error.message });

    return reply.send((data ?? []).map((u, i) => ({
      id:             u.id,
      username:       u.username,
      displayName:    u.display_name,
      avatarInitials: u.avatar_initials,
      avatarColor:    u.avatar_color,
      points:         u.points,
      accuracy:       u.accuracy,
      streak:         u.streak,
      rank:           i + 1,
      level:          u.level,
      xp:             u.xp,
      betsTotal:      u.bets_total,
      betsCorrect:    u.bets_correct,
      betsExact:      u.bets_exact,
      rankVariation:  u.rank_variation,
      badges:         u.badges,
    })));
  });

  // Round ranking (points from Copa 2026 matches only — all static)
  app.get("/round", async (_req, reply) => {
    const { data, error } = await supabase
      .from("bets")
      .select("user_id, points, users(display_name, avatar_initials, avatar_color)")
      .eq("status", "won")
      .not("points", "is", null);

    if (error) return reply.status(500).send({ error: error.message });

    const scoreMap: Record<string, { pts: number; user: any }> = {};
    for (const b of (data ?? [])) {
      if (!scoreMap[b.user_id]) scoreMap[b.user_id] = { pts: 0, user: b.users };
      scoreMap[b.user_id].pts += b.points ?? 0;
    }

    return reply.send(
      Object.entries(scoreMap)
        .sort((a, b) => b[1].pts - a[1].pts)
        .map(([userId, { pts, user }], i) => ({
          id:             userId,
          displayName:    (user as any)?.display_name,
          avatarInitials: (user as any)?.avatar_initials,
          avatarColor:    (user as any)?.avatar_color,
          roundPoints:    pts,
          roundRank:      i + 1,
        }))
    );
  });
}
