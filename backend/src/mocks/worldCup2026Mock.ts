/**
 * FALLBACK MOCK — used only when TheSportsDB returns empty/error.
 * These are placeholder fixtures for Copa do Mundo 2026.
 * Replace with real data once the API has full coverage.
 *
 * DO NOT import this outside of worldCupService.ts.
 */

import type { Match, Team, WorldCupGroup } from "../shared/database/seed";

function team(id: string, name: string, short: string, flag: string): Team {
  return { id, name, shortName: short, logoUrl: flag, country: name };
}

const TEAMS = {
  BRA: team("bra", "Brasil",     "BRA", "https://www.thesportsdb.com/images/media/team/badge/Brazil.png"),
  ARG: team("arg", "Argentina",  "ARG", "https://www.thesportsdb.com/images/media/team/badge/Argentina.png"),
  FRA: team("fra", "França",     "FRA", "https://www.thesportsdb.com/images/media/team/badge/France.png"),
  ENG: team("eng", "Inglaterra", "ENG", "https://www.thesportsdb.com/images/media/team/badge/England.png"),
  ESP: team("esp", "Espanha",    "ESP", "https://www.thesportsdb.com/images/media/team/badge/Spain.png"),
  GER: team("ger", "Alemanha",   "GER", "https://www.thesportsdb.com/images/media/team/badge/Germany.png"),
  POR: team("por", "Portugal",   "POR", "https://www.thesportsdb.com/images/media/team/badge/Portugal.png"),
  USA: team("usa", "EUA",        "USA", "https://www.thesportsdb.com/images/media/team/badge/USA.png"),
  MEX: team("mex", "México",     "MEX", "https://www.thesportsdb.com/images/media/team/badge/Mexico.png"),
  URU: team("uru", "Uruguai",    "URU", "https://www.thesportsdb.com/images/media/team/badge/Uruguay.png"),
  NED: team("ned", "Holanda",    "NED", "https://www.thesportsdb.com/images/media/team/badge/Netherlands.png"),
  ITA: team("ita", "Itália",     "ITA", "https://www.thesportsdb.com/images/media/team/badge/Italy.png"),
};

function match(
  id: string, home: Team, away: Team,
  kickoff: string, stage: Match["stage"], group?: string,
  homeScore: number|null = null, awayScore: number|null = null,
): Match {
  const status = homeScore !== null ? "finished" : new Date(kickoff) <= new Date() ? "live" : "scheduled";
  return {
    id, homeTeam: home, awayTeam: away,
    competition: "Copa do Mundo 2026",
    competitionLogo: "https://www.thesportsdb.com/images/media/league/badge/wc_logo.png",
    round: group ? `Grupo ${group}` : (stage === "r16" ? "Oitavas de Final" : stage === "qf" ? "Quartas de Final" : stage === "sf" ? "Semifinal" : "Final"),
    kickoffAt: kickoff,
    status, homeScore, awayScore,
    homeScoreHT: null, awayScoreHT: null,
    stage, groupName: group,
    h2h: { homeWins: 0, draws: 0, awayWins: 0, homeGoals: 0, awayGoals: 0 },
  };
}

export const mockMatches: Match[] = [
  // Grupo A
  match("m01", TEAMS.BRA, TEAMS.MEX,  "2026-06-14T18:00:00", "group", "A"),
  match("m02", TEAMS.ARG, TEAMS.URU,  "2026-06-15T15:00:00", "group", "A"),
  // Grupo B
  match("m03", TEAMS.FRA, TEAMS.GER,  "2026-06-15T18:00:00", "group", "B"),
  match("m04", TEAMS.ESP, TEAMS.ITA,  "2026-06-16T15:00:00", "group", "B"),
  // Grupo C
  match("m05", TEAMS.ENG, TEAMS.USA,  "2026-06-16T18:00:00", "group", "C"),
  match("m06", TEAMS.POR, TEAMS.NED,  "2026-06-17T15:00:00", "group", "C"),
];

export const mockGroups: WorldCupGroup[] = [
  {
    name: "Grupo A",
    teams: [
      { team: TEAMS.BRA, played: 0, won: 0, drawn: 0, lost: 0, gf: 0, ga: 0, pts: 0 },
      { team: TEAMS.ARG, played: 0, won: 0, drawn: 0, lost: 0, gf: 0, ga: 0, pts: 0 },
      { team: TEAMS.MEX, played: 0, won: 0, drawn: 0, lost: 0, gf: 0, ga: 0, pts: 0 },
      { team: TEAMS.URU, played: 0, won: 0, drawn: 0, lost: 0, gf: 0, ga: 0, pts: 0 },
    ],
  },
  {
    name: "Grupo B",
    teams: [
      { team: TEAMS.FRA, played: 0, won: 0, drawn: 0, lost: 0, gf: 0, ga: 0, pts: 0 },
      { team: TEAMS.GER, played: 0, won: 0, drawn: 0, lost: 0, gf: 0, ga: 0, pts: 0 },
      { team: TEAMS.ESP, played: 0, won: 0, drawn: 0, lost: 0, gf: 0, ga: 0, pts: 0 },
      { team: TEAMS.ITA, played: 0, won: 0, drawn: 0, lost: 0, gf: 0, ga: 0, pts: 0 },
    ],
  },
  {
    name: "Grupo C",
    teams: [
      { team: TEAMS.ENG, played: 0, won: 0, drawn: 0, lost: 0, gf: 0, ga: 0, pts: 0 },
      { team: TEAMS.USA, played: 0, won: 0, drawn: 0, lost: 0, gf: 0, ga: 0, pts: 0 },
      { team: TEAMS.POR, played: 0, won: 0, drawn: 0, lost: 0, gf: 0, ga: 0, pts: 0 },
      { team: TEAMS.NED, played: 0, won: 0, drawn: 0, lost: 0, gf: 0, ga: 0, pts: 0 },
    ],
  },
];
