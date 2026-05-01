import { FastifyInstance } from "fastify";
import { supabase } from "../../../shared/database/supabase";
import { calculatePoints, DEFAULT_RULES } from "../../../shared/database/seed";
import { getAllMatches, toFrontendMatch } from "../../../services/worldCupStaticService";

export async function betRoutes(app: FastifyInstance) {

  // GET /api/bets — all bets for current user
  app.get("/", async (req, reply) => {
    const user = await resolveUser(req.headers.authorization);
    if (!user) return reply.status(401).send({ error: "Não autenticado" });

    const { data: bets, error } = await supabase
      .from("bets")
      .select("*, bet_edits(predicted_home, predicted_away, edited_at)")
      .eq("user_id", user.id)
      .order("submitted_at", { ascending: false });

    if (error) return reply.status(500).send({ error: error.message });

    const allMatches = getAllMatches();
    const enriched = (bets ?? []).map(b => ({
      ...toBet(b),
      match: (() => {
        const wc = allMatches.find(m => m.id === b.match_id);
        return wc ? toFrontendMatch(wc) : null;
      })(),
    }));

    return reply.send(enriched);
  });

  // GET /api/bets/score-rules
  app.get("/score-rules", async (_req, reply) => reply.send(DEFAULT_RULES));

  // GET /api/bets/log/:betId
  app.get("/log/:betId", async (req, reply) => {
    const user = await resolveUser(req.headers.authorization);
    if (!user) return reply.status(401).send({ error: "Não autenticado" });

    const { betId } = req.params as { betId: string };
    const { data: bet, error } = await supabase
      .from("bets")
      .select("*, bet_edits(predicted_home, predicted_away, edited_at)")
      .eq("id", betId)
      .eq("user_id", user.id)
      .maybeSingle();

    if (error || !bet) return reply.status(404).send({ error: "Palpite não encontrado" });
    return reply.send({
      bet: toBet(bet),
      editHistory: (bet.bet_edits ?? []).map((e: any) => ({
        home: e.predicted_home,
        away: e.predicted_away,
        at:   e.edited_at,
      })),
    });
  });

  // POST /api/bets — submit or update
  app.post("/", async (req, reply) => {
    const user = await resolveUser(req.headers.authorization);
    if (!user) return reply.status(401).send({ error: "Não autenticado" });

    const { matchId, predictedHome, predictedAway, groupId } = req.body as {
      matchId: string; predictedHome: number; predictedAway: number; groupId?: string;
    };

    const match = getAllMatches().find(m => m.id === matchId);
    if (!match) return reply.status(404).send({ error: "Jogo não encontrado" });
    if (match.status !== "scheduled")
      return reply.status(400).send({ error: "Palpites encerrados — jogo já iniciou" });
    if (predictedHome < 0 || predictedHome > 20 || predictedAway < 0 || predictedAway > 20)
      return reply.status(400).send({ error: "Placar inválido (0–20)" });

    const { data: existing } = await supabase
      .from("bets")
      .select("id, predicted_home, predicted_away")
      .eq("user_id", user.id)
      .eq("match_id", matchId)
      .maybeSingle();

    if (existing) {
      // Save to edit history first
      await supabase.from("bet_edits").insert({
        bet_id:        existing.id,
        predicted_home: existing.predicted_home,
        predicted_away: existing.predicted_away,
      });
      // Update bet
      const { data: updated } = await supabase
        .from("bets")
        .update({ predicted_home: predictedHome, predicted_away: predictedAway, group_id: groupId ?? null })
        .eq("id", existing.id)
        .select()
        .single();
      return reply.send(toBet(updated));
    }

    const { data: newBet, error } = await supabase
      .from("bets")
      .insert({
        user_id:        user.id,
        match_id:       matchId,
        group_id:       groupId ?? null,
        predicted_home: predictedHome,
        predicted_away: predictedAway,
        status:         "pending",
      })
      .select()
      .single();

    if (error) return reply.status(500).send({ error: error.message });
    return reply.status(201).send(toBet(newBet));
  });

  // POST /api/bets/settle/:matchId — settle all bets (admin/internal)
  app.post("/settle/:matchId", async (req, reply) => {
    const { matchId } = req.params as { matchId: string };
    const match = getAllMatches().find(m => m.id === matchId);
    if (!match) return reply.status(404).send({ error: "Jogo não encontrado" });
    if (match.status !== "finished") return reply.status(400).send({ error: "Jogo não finalizado" });
    if (match.homeScore === null || match.awayScore === null)
      return reply.status(400).send({ error: "Placar não definido" });

    const { data: pendingBets } = await supabase
      .from("bets")
      .select("*, users(streak)")
      .eq("match_id", matchId)
      .eq("status", "pending");

    if (!pendingBets?.length) return reply.send({ settled: 0 });

    const isFinal = match.stage === "final";
    let settled = 0;

    for (const bet of pendingBets) {
      const streak = bet.users?.streak ?? 0;
      const result = calculatePoints(
        bet.predicted_home, bet.predicted_away,
        match.homeScore!, match.awayScore!,
        DEFAULT_RULES, isFinal, streak,
      );

      await supabase.from("bets").update({
        points:             result.points,
        status:             result.points > 0 ? "won" : "lost",
        is_exact:           result.isExact,
        is_correct_outcome: result.isCorrectOutcome,
        locked_at:          new Date().toISOString(),
      }).eq("id", bet.id);

      // Update user stats
      const wonBet = result.points > 0;
      const { data: u } = await supabase.from("users")
        .select("points, bets_total, bets_correct, bets_exact, streak")
        .eq("id", bet.user_id)
        .single();
      if (u) {
        const newStreak  = wonBet ? (u.streak + 1) : 0;
        const newTotal   = u.bets_total + 1;
        const newCorrect = u.bets_correct + (wonBet ? 1 : 0);
        await supabase.from("users").update({
          points:       u.points + result.points,
          bets_total:   newTotal,
          bets_correct: newCorrect,
          bets_exact:   u.bets_exact + (result.isExact ? 1 : 0),
          streak:       newStreak,
          accuracy:     newTotal > 0 ? parseFloat(((newCorrect / newTotal) * 100).toFixed(1)) : 0,
        }).eq("id", bet.user_id);
      }

      settled++;
    }

    // Recalculate global ranks
    const { data: allUsers } = await supabase
      .from("users")
      .select("id, points")
      .order("points", { ascending: false });

    if (allUsers) {
      const updates = allUsers.map((u, i) => supabase
        .from("users")
        .update({ rank: i + 1 })
        .eq("id", u.id));
      await Promise.all(updates);
    }

    return reply.send({ settled });
  });
}

function toBet(b: any) {
  return {
    id:               b.id,
    userId:           b.user_id,
    matchId:          b.match_id,
    groupId:          b.group_id,
    predictedHome:    b.predicted_home,
    predictedAway:    b.predicted_away,
    points:           b.points,
    status:           b.status,
    isExact:          b.is_exact,
    isCorrectOutcome: b.is_correct_outcome,
    submittedAt:      b.submitted_at,
    lockedAt:         b.locked_at,
    editHistory:      (b.bet_edits ?? []).map((e: any) => ({
      home: e.predicted_home,
      away: e.predicted_away,
      at:   e.edited_at,
    })),
  };
}

async function resolveUser(auth?: string) {
  const token = auth?.startsWith("Bearer ") ? auth.slice(7) : (auth ?? "");
  if (!token) return null;
  const { data: { user } } = await supabase.auth.getUser(token);
  return user ?? null;
}
