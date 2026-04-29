import { FastifyInstance } from "fastify";
import { users, bets, matches } from "../../../shared/database/seed";

export async function rankingRoutes(app: FastifyInstance) {
  // Global ranking
  app.get("/global", async (_req, reply) => {
    const sorted = [...users]
      .sort((a, b) => b.points - a.points || b.accuracy - a.accuracy)
      .map((u, i) => ({ ...u, rank: i + 1 }));
    return reply.send(sorted);
  });

  // Round/competition-specific ranking (mock: by bets on Copa or Brasileirão)
  app.get("/round", async (req, reply) => {
    const { competition } = req.query as { competition?: string };
    const relevantMatches = competition
      ? matches.filter(m => m.competition.toLowerCase().includes(competition.toLowerCase()))
      : matches;
    const matchIds = new Set(relevantMatches.map(m => m.id));

    const scoreMap: Record<string, number> = {};
    bets
      .filter(b => matchIds.has(b.matchId) && b.status === "won")
      .forEach(b => { scoreMap[b.userId] = (scoreMap[b.userId] ?? 0) + (b.points ?? 0); });

    const result = users
      .map(u => ({ ...u, roundPoints: scoreMap[u.id] ?? 0 }))
      .sort((a, b) => b.roundPoints - a.roundPoints)
      .map((u, i) => ({ ...u, roundRank: i + 1 }));

    return reply.send(result);
  });
}
