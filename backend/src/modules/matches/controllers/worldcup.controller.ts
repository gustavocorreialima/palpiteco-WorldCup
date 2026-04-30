import { FastifyInstance } from "fastify";
import {
  getAllMatches, getMatchesByDate, getUpcomingMatches, getFinishedMatches,
  getMatchesByGroup, getKnockoutMatches, getBracket,
  getTeams, getTeamsByGroup, getGroups, getNextMatches, getMatchDates,
} from "../../../services/worldCupStaticService";
import { getLiveMatches } from "../../../services/liveScoreService";

export async function worldCupRoutes(app: FastifyInstance) {

  // All 104 matches
  app.get("/matches", async (_req, reply) => reply.send(getAllMatches()));

  // Upcoming matches — optional ?n=20
  app.get("/matches/upcoming", async (req, reply) => {
    const { n } = req.query as { n?: string };
    return reply.send(getNextMatches(n ? Number(n) : 10));
  });

  // Finished matches
  app.get("/matches/finished", async (_req, reply) => reply.send(getFinishedMatches()));

  // Live — placeholder, returns [] until liveScoreService is wired
  app.get("/matches/live", async (_req, reply) => reply.send(await getLiveMatches()));

  // By date — ?date=2026-06-11
  app.get("/matches/by-date", async (req, reply) => {
    const { date } = req.query as { date?: string };
    if (!date) return reply.status(400).send({ error: "Parâmetro ?date=YYYY-MM-DD obrigatório." });
    return reply.send(getMatchesByDate(date));
  });

  // All match dates (for calendar strip)
  app.get("/matches/dates", async (_req, reply) => reply.send(getMatchDates()));

  // Knockout only
  app.get("/matches/knockout", async (_req, reply) => reply.send(getKnockoutMatches()));

  // Bracket split by stage
  app.get("/bracket", async (_req, reply) => reply.send(getBracket()));

  // All 48 teams
  app.get("/teams", async (_req, reply) => reply.send(getTeams()));

  // Teams by group — /teams/group/A
  app.get("/teams/group/:letter", async (req, reply) => {
    const { letter } = req.params as { letter: string };
    return reply.send(getTeamsByGroup(letter));
  });

  // All 12 groups with standings
  app.get("/groups", async (_req, reply) => reply.send(getGroups()));

  // Single group — /groups/A
  app.get("/groups/:letter", async (req, reply) => {
    const { letter } = req.params as { letter: string };
    const groups = getGroups();
    const group  = groups.find(g => g.letter === letter.toUpperCase());
    if (!group) return reply.status(404).send({ error: `Grupo ${letter} não encontrado.` });
    return reply.send(group);
  });

  // Matches in a group — /groups/A/matches
  app.get("/groups/:letter/matches", async (req, reply) => {
    const { letter } = req.params as { letter: string };
    return reply.send(getMatchesByGroup(letter));
  });
}
