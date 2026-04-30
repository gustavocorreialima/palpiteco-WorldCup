import { FastifyInstance } from "fastify";
import { getAllMatches, toFrontendMatch } from "../../../services/worldCupStaticService";
import { matches as localMatches } from "../../../shared/database/seed";

export async function matchRoutes(app: FastifyInstance) {

  // List all Copa 2026 matches in frontend-compatible shape
  app.get("/", async (req, reply) => {
    const { status } = req.query as { status?: string };
    const all = getAllMatches().map(toFrontendMatch);
    return reply.send(status ? all.filter(m => m.status === status) : all);
  });

  // Single match by ID
  app.get("/:id", async (req, reply) => {
    const { id } = req.params as { id: string };
    const wc = getAllMatches().find(m => m.id === id);
    if (wc) return reply.send(toFrontendMatch(wc));
    const local = localMatches.find(m => m.id === id);
    if (local) return reply.send(local);
    return reply.status(404).send({ error: "Partida não encontrada." });
  });
}
