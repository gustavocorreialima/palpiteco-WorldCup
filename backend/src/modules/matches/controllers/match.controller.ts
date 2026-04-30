import { FastifyInstance } from "fastify";
import { getAllMatches } from "../../../services/worldCupService";
import { matches as localMatches } from "../../../shared/database/seed";

export async function matchRoutes(app: FastifyInstance) {

  // List matches — Copa 2026 from service, other bets from in-memory store
  app.get("/", async (req, reply) => {
    const { status, source } = req.query as { status?: string; source?: string };

    // source=local bypasses API (used by bet resolution logic)
    if (source === "local") {
      const result = status ? localMatches.filter(m => m.status === status) : localMatches;
      return reply.send(result);
    }

    try {
      const wcMatches = await getAllMatches();
      const result    = status ? wcMatches.filter(m => m.status === status) : wcMatches;
      return reply.send(result);
    } catch {
      return reply.status(503).send({ error: "Não foi possível carregar os jogos agora." });
    }
  });

  // Single match by ID — check WC matches first, then local store
  app.get("/:id", async (req, reply) => {
    const { id } = req.params as { id: string };
    try {
      const wcMatches = await getAllMatches();
      const match     = wcMatches.find(m => m.id === id) ?? localMatches.find(m => m.id === id);
      if (!match) return reply.status(404).send({ error: "Match not found" });
      return reply.send(match);
    } catch {
      const match = localMatches.find(m => m.id === id);
      if (!match) return reply.status(404).send({ error: "Match not found" });
      return reply.send(match);
    }
  });
}
