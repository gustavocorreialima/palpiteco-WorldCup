import { FastifyInstance } from "fastify";
import {
  getAllMatches,
  getUpcomingMatches,
  getPastMatches,
  getLiveMatches,
  getTeams,
  getGroups,
  getBracket,
  checkApiStatus,
} from "../../../services/worldCupService";

export async function worldCupRoutes(app: FastifyInstance) {

  // Groups / standings
  app.get("/groups", async (_req, reply) => {
    try {
      return reply.send(await getGroups());
    } catch {
      return reply.status(503).send({ error: "Não foi possível carregar os grupos agora." });
    }
  });

  // All fixtures
  app.get("/matches", async (_req, reply) => {
    try {
      return reply.send(await getAllMatches());
    } catch {
      return reply.status(503).send({ error: "Não foi possível carregar os jogos agora." });
    }
  });

  // Upcoming fixtures
  app.get("/matches/upcoming", async (_req, reply) => {
    try {
      return reply.send(await getUpcomingMatches());
    } catch {
      return reply.status(503).send({ error: "Não foi possível carregar os próximos jogos." });
    }
  });

  // Past fixtures
  app.get("/matches/past", async (_req, reply) => {
    try {
      return reply.send(await getPastMatches());
    } catch {
      return reply.status(503).send({ error: "Não foi possível carregar os jogos anteriores." });
    }
  });

  // Live scores
  app.get("/matches/live", async (_req, reply) => {
    try {
      return reply.send(await getLiveMatches());
    } catch {
      return reply.status(503).send({ error: "Placar ao vivo indisponível no momento." });
    }
  });

  // National teams
  app.get("/teams", async (_req, reply) => {
    try {
      return reply.send(await getTeams());
    } catch {
      return reply.status(503).send({ error: "Não foi possível carregar as seleções." });
    }
  });

  // Bracket (knockout stages)
  app.get("/bracket", async (_req, reply) => {
    try {
      return reply.send(await getBracket());
    } catch {
      return reply.status(503).send({ error: "Não foi possível carregar o mata-mata." });
    }
  });

  // Debug / health check (development only)
  app.get("/status", async (_req, reply) => {
    return reply.send(await checkApiStatus());
  });
}
