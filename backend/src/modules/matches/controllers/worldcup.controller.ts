import { FastifyInstance } from "fastify";
import { worldCupGroups, matches } from "../../../shared/database/seed";

export async function worldCupRoutes(app: FastifyInstance) {
  app.get("/groups", async (_req, reply) => reply.send(worldCupGroups));

  app.get("/matches", async (_req, reply) => {
    const wcMatches = matches.filter(m => m.competition === "Copa do Mundo 2026");
    return reply.send(wcMatches);
  });

  app.get("/bracket", async (_req, reply) => {
    const wcMatches = matches.filter(m => m.competition === "Copa do Mundo 2026");
    const bracket = {
      groupStage:    wcMatches.filter(m => m.stage === "group"),
      roundOf16:     wcMatches.filter(m => m.stage === "r16"),
      quarterFinals: wcMatches.filter(m => m.stage === "qf"),
      semiFinals:    wcMatches.filter(m => m.stage === "sf"),
      final:         wcMatches.filter(m => m.stage === "final"),
    };
    return reply.send(bracket);
  });
}
