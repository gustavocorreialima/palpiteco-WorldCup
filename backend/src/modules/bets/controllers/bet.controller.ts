import { FastifyInstance } from "fastify";
import { v4 as uuidv4 } from "uuid";
import {
  bets, matches, users, Bet,
  calculatePoints, DEFAULT_RULES,
  getUserFromToken,
} from "../../../shared/database/seed";

export async function betRoutes(app: FastifyInstance) {
  // GET /api/bets — all bets for current user
  app.get("/", async (req, reply) => {
    const user = resolveUser(req.headers.authorization) ?? users[0];
    const enriched = bets
      .filter(b => b.userId === user.id)
      .map(b => ({ ...b, match: matches.find(m => m.id === b.matchId) }))
      .sort((a, b) => new Date(b.submittedAt).getTime() - new Date(a.submittedAt).getTime());
    return reply.send(enriched);
  });

  // GET /api/bets/score-rules — transparent scoring rules
  app.get("/score-rules", async (_req, reply) => reply.send(DEFAULT_RULES));

  // GET /api/bets/log/:betId — full audit trail for a bet
  app.get("/log/:betId", async (req, reply) => {
    const { betId } = req.params as { betId: string };
    const bet = bets.find(b => b.id === betId);
    if (!bet) return reply.status(404).send({ error: "Palpite não encontrado" });
    return reply.send({ bet, editHistory: bet.editHistory });
  });

  // POST /api/bets — submit or update a bet
  app.post("/", async (req, reply) => {
    const user = resolveUser(req.headers.authorization) ?? users[0];
    const { matchId, predictedHome, predictedAway, groupId } = req.body as {
      matchId: string; predictedHome: number; predictedAway: number; groupId?: string;
    };

    const match = matches.find(m => m.id === matchId);
    if (!match) return reply.status(404).send({ error: "Jogo não encontrado" });

    // Anti-cheat: lock bets once match starts
    if (match.status !== "scheduled")
      return reply.status(400).send({ error: "Palpites encerrados — jogo já iniciou" });

    if (predictedHome < 0 || predictedHome > 20 || predictedAway < 0 || predictedAway > 20)
      return reply.status(400).send({ error: "Placar inválido (0–20)" });

    const existingIdx = bets.findIndex(b => b.matchId === matchId && b.userId === user.id);

    if (existingIdx !== -1) {
      // Update: record to audit log
      const old = bets[existingIdx];
      old.editHistory.push({ home: old.predictedHome, away: old.predictedAway, at: new Date().toISOString() });
      old.predictedHome = predictedHome;
      old.predictedAway = predictedAway;
      if (groupId) old.groupId = groupId;
      return reply.send(old);
    }

    const newBet: Bet = {
      id: uuidv4(), userId: user.id, matchId,
      groupId,
      predictedHome, predictedAway,
      points: null, status: "pending",
      submittedAt: new Date().toISOString(),
      editHistory: [],
    };
    bets.push(newBet);
    return reply.status(201).send(newBet);
  });

  // POST /api/bets/settle/:matchId — settle all bets for a finished match (internal/admin)
  app.post("/settle/:matchId", async (req, reply) => {
    const { matchId } = req.params as { matchId: string };
    const match = matches.find(m => m.id === matchId);
    if (!match) return reply.status(404).send({ error: "Jogo não encontrado" });
    if (match.status !== "finished") return reply.status(400).send({ error: "Jogo não finalizado" });
    if (match.homeScore === null || match.awayScore === null)
      return reply.status(400).send({ error: "Placar não definido" });

    const isFinal  = match.stage === "final";
    const affected = bets.filter(b => b.matchId === matchId && b.status === "pending");

    affected.forEach(bet => {
      const user = users.find(u => u.id === bet.userId);
      if (!user) return;

      const result = calculatePoints(
        bet.predictedHome, bet.predictedAway,
        match.homeScore!, match.awayScore!,
        DEFAULT_RULES, isFinal, user.streak,
      );

      bet.points          = result.points;
      bet.status          = result.points > 0 ? "won" : "lost";
      bet.isExact         = result.isExact;
      bet.isCorrectOutcome= result.isCorrectOutcome;
      bet.lockedAt        = new Date().toISOString();

      user.points      += result.points;
      user.betsTotal   += 1;
      if (result.points > 0) { user.betsCorrect += 1; user.streak += 1; }
      else                    { user.streak = 0; }
      if (result.isExact) user.betsExact += 1;
      user.accuracy = user.betsTotal > 0
        ? parseFloat(((user.betsCorrect / user.betsTotal) * 100).toFixed(1))
        : 0;
    });

    // Recalculate global ranks
    [...users].sort((a, b) => b.points - a.points).forEach((u, i) => {
      const prev = u.rank;
      u.rank = i + 1;
      u.rankVariation = prev - u.rank;
    });

    return reply.send({ settled: affected.length });
  });
}

function resolveUser(auth?: string) {
  const token = auth?.startsWith("Bearer ") ? auth.slice(7) : (auth ?? "");
  return getUserFromToken(token);
}
