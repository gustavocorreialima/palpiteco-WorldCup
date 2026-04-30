/**
 * World Cup service — single entry point for all Copa 2026 data.
 * Controllers call only this module; never theSportsDb.ts directly.
 *
 * Strategy:
 *   1. Try TheSportsDB for live + fixture data.
 *   2. If the API returns empty or throws, fall back to mockMatches / mockGroups.
 *   3. Livescore is fetched fresh (no cache); rate-limit is the caller's responsibility.
 */

import {
  getLeagueEvents,
  getUpcomingEventsByLeague,
  getPastEventsByLeague,
  getLivescore,
  getTeamsByLeague,
  WORLD_CUP_2026_LEAGUE_ID,
  WORLD_CUP_2026_SEASON,
} from "./theSportsDb";
import { adaptEvent, adaptTeam, buildGroupsFromMatches } from "./worldCupAdapter";
import { mockMatches, mockGroups } from "../mocks/worldCup2026Mock";
import type { Match, Team, WorldCupGroup } from "../shared/database/seed";

// ─── helpers ──────────────────────────────────────────────────────────────────

function log(msg: string) {
  if (process.env.NODE_ENV !== "production") console.log(`[WorldCupService] ${msg}`);
}

// ─── public API ───────────────────────────────────────────────────────────────

/** All Copa 2026 fixtures (full season). Falls back to mock if API is empty. */
export async function getAllMatches(): Promise<Match[]> {
  try {
    const raw = await getLeagueEvents(WORLD_CUP_2026_LEAGUE_ID, WORLD_CUP_2026_SEASON);
    if (raw.length === 0) {
      log("API returned 0 events — using mock fallback");
      return mockMatches;
    }
    log(`Loaded ${raw.length} events from API`);
    return raw.map(adaptEvent);
  } catch (err) {
    log(`API error — using mock fallback. Reason: ${(err as Error).message}`);
    return mockMatches;
  }
}

/** Next upcoming Copa 2026 fixtures. */
export async function getUpcomingMatches(): Promise<Match[]> {
  try {
    const raw = await getUpcomingEventsByLeague(WORLD_CUP_2026_LEAGUE_ID);
    const wc  = raw.filter(e => e.strLeague?.toLowerCase().includes("world cup"));
    if (wc.length === 0) {
      log("No upcoming WC events — using mock fallback");
      return mockMatches.filter(m => m.status === "scheduled");
    }
    return wc.map(adaptEvent);
  } catch (err) {
    log(`Upcoming error — mock. ${(err as Error).message}`);
    return mockMatches.filter(m => m.status === "scheduled");
  }
}

/** Past Copa 2026 fixtures. */
export async function getPastMatches(): Promise<Match[]> {
  try {
    const raw = await getPastEventsByLeague(WORLD_CUP_2026_LEAGUE_ID);
    const wc  = raw.filter(e => e.strLeague?.toLowerCase().includes("world cup"));
    return wc.map(adaptEvent);
  } catch (err) {
    log(`Past error — mock. ${(err as Error).message}`);
    return mockMatches.filter(m => m.status === "finished");
  }
}

/** Live scores (paid key only; returns [] gracefully on free key). */
export async function getLiveMatches(): Promise<Match[]> {
  const raw = await getLivescore();
  return raw.map(e => adaptEvent(e as any));
}

/** All Copa 2026 national teams. Falls back to teams derived from mock. */
export async function getTeams(): Promise<Team[]> {
  try {
    const raw = await getTeamsByLeague(WORLD_CUP_2026_LEAGUE_ID);
    if (raw.length === 0) {
      log("No teams from API — deriving from mock");
      return deriveTeamsFromMock();
    }
    return raw.map(adaptTeam);
  } catch (err) {
    log(`Teams error — mock. ${(err as Error).message}`);
    return deriveTeamsFromMock();
  }
}

/** Group standings computed from match results. */
export async function getGroups(): Promise<WorldCupGroup[]> {
  try {
    const allMatches = await getAllMatches();
    const groups     = buildGroupsFromMatches(allMatches);
    if (groups.length === 0) {
      log("No groups from match data — using mock groups");
      return mockGroups;
    }
    return groups;
  } catch (err) {
    log(`Groups error — mock. ${(err as Error).message}`);
    return mockGroups;
  }
}

/** Bracket structure split by stage. */
export async function getBracket() {
  const allMatches = await getAllMatches();
  return {
    groupStage:    allMatches.filter(m => m.stage === "group"),
    roundOf16:     allMatches.filter(m => m.stage === "r16"),
    quarterFinals: allMatches.filter(m => m.stage === "qf"),
    semiFinals:    allMatches.filter(m => m.stage === "sf"),
    final:         allMatches.filter(m => m.stage === "final"),
  };
}

/** API health check — used by debug endpoint. */
export async function checkApiStatus(): Promise<{
  connected: boolean;
  hasData: boolean;
  usingMock: boolean;
  eventCount: number;
  message: string;
}> {
  try {
    const raw = await getLeagueEvents(WORLD_CUP_2026_LEAGUE_ID, WORLD_CUP_2026_SEASON);
    const hasData = raw.length > 0;
    return {
      connected:  true,
      hasData,
      usingMock:  !hasData,
      eventCount: raw.length,
      message:    hasData
        ? `API conectada — ${raw.length} jogos carregados`
        : "API conectada, mas sem dados para Copa 2026 ainda. Usando mock.",
    };
  } catch (err) {
    return {
      connected:  false,
      hasData:    false,
      usingMock:  true,
      eventCount: 0,
      message:    `API indisponível: ${(err as Error).message}. Usando mock.`,
    };
  }
}

// ─── internal ─────────────────────────────────────────────────────────────────

function deriveTeamsFromMock(): Team[] {
  const seen = new Set<string>();
  const teams: Team[] = [];
  for (const m of mockMatches) {
    for (const t of [m.homeTeam, m.awayTeam]) {
      if (!seen.has(t.id)) { seen.add(t.id); teams.push(t); }
    }
  }
  return teams;
}
