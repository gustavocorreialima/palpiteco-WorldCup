import { FastifyInstance } from "fastify";
import { matches } from "../../../shared/database/seed";

export async function matchRoutes(app: FastifyInstance) {
  app.get("/", async (req, reply) => {
    const { status } = req.query as { status?: string };
    const result = status ? matches.filter((m) => m.status === status) : matches;
    return reply.send(result);
  });

  app.get("/:id", async (req, reply) => {
    const { id } = req.params as { id: string };
    const match = matches.find((m) => m.id === id);
    if (!match) return reply.status(404).send({ error: "Match not found" });
    return reply.send(match);
  });
}
