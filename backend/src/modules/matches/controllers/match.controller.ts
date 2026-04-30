import { FastifyInstance } from "fastify";
import { getAllMatches } from "../../../services/worldCupStaticService";
import { matches as localMatches } from "../../../shared/database/seed";

export async function matchRoutes(app: FastifyInstance) {

  // List — Copa 2026 from static data; ?status= filter supported
  app.get("/", async (req, reply) => {
    const { status } = req.query as { status?: string };
    const all = getAllMatches();
    return reply.send(status ? all.filter(m => m.status === status) : all);
  });

  // Single match — check static data first, then in-memory bets store
  app.get("/:id", async (req, reply) => {
    const { id } = req.params as { id: string };
    const wcMatch = getAllMatches().find(m => m.id === id);
    if (wcMatch) return reply.send(wcMatch);
    const local = localMatches.find(m => m.id === id);
    if (local)   return reply.send(local);
    return reply.status(404).send({ error: "Partida não encontrada." });
  });
}
