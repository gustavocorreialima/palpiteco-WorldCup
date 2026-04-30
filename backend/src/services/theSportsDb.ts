/**
 * TheSportsDB API client.
 * All external HTTP calls go through here — never call the API from controllers directly.
 *
 * Free key "3" works for development/testing.
 * Set THESPORTSDB_KEY in .env for production.
 */

const BASE_URL = "https://www.thesportsdb.com/api/v1/json";
const API_KEY  = process.env.THESPORTSDB_KEY ?? "3";

// ─── in-memory cache ──────────────────────────────────────────────────────────

interface CacheEntry<T> { data: T; expiresAt: number }
const cache = new Map<string, CacheEntry<unknown>>();

async function getCachedOrFetch<T>(key: string, fetcher: () => Promise<T>, ttlMs: number): Promise<T> {
  const hit = cache.get(key);
  if (hit && hit.expiresAt > Date.now()) return hit.data as T;
  const data = await fetcher();
  cache.set(key, { data, expiresAt: Date.now() + ttlMs });
  return data;
}

// ─── HTTP helper ──────────────────────────────────────────────────────────────

async function get<T>(path: string): Promise<T> {
  const url = `${BASE_URL}/${API_KEY}/${path}`;
  const res  = await fetch(url, { headers: { "Accept": "application/json" } });
  if (!res.ok) throw new Error(`TheSportsDB ${res.status}: ${path}`);
  return res.json() as Promise<T>;
}

// ─── TTLs ─────────────────────────────────────────────────────────────────────

const TTL = {
  teams:   24 * 60 * 60 * 1000,   // 24h
  fixtures: 10 * 60 * 1000,        // 10min
  live:      60 * 1000,            // 60s
};

// ─── Raw response types ───────────────────────────────────────────────────────

export interface RawTeam {
  idTeam: string;
  strTeam: string;
  strTeamShort?: string;
  strBadge?: string;
  strCountry?: string;
  strLeague?: string;
  strDescriptionEN?: string;
}

export interface RawEvent {
  idEvent: string;
  strEvent: string;
  strHomeTeam: string;
  strAwayTeam: string;
  idHomeTeam?: string;
  idAwayTeam?: string;
  strHomeTeamBadge?: string;
  strAwayTeamBadge?: string;
  intHomeScore: string | null;
  intAwayScore: string | null;
  strStatus?: string;       // "Match Finished" | "Not Started" | "1H" | "HT" | "2H" etc.
  dateEvent: string;        // "2026-06-11"
  strTime?: string;         // "20:00:00"
  strRound?: string;
  strGroup?: string;
  strLeague?: string;
  strSeason?: string;
  intMatchMinute?: string;
  intHomeScoreExtraTime?: string | null;
  intAwayScoreExtraTime?: string | null;
}

export interface RawLivescore {
  idEvent: string;
  strHomeTeam: string;
  strAwayTeam: string;
  intHomeScore?: string;
  intAwayScore?: string;
  strStatus?: string;
  intMatchMinute?: string;
  strLeague?: string;
}

// ─── Public API functions ─────────────────────────────────────────────────────

/** Search for a league by name (e.g. "FIFA World Cup") */
export async function searchLeagueByName(name: string) {
  return getCachedOrFetch(`league:${name}`, async () => {
    const data = await get<{ leagues: RawTeam[] | null }>(`search_all_leagues.php?s=Soccer&c=International`);
    const leagues = data.leagues ?? [];
    const q = name.toLowerCase();
    return leagues.filter((l: any) => (l.strLeague ?? "").toLowerCase().includes(q));
  }, TTL.teams);
}

/** All teams in a league */
export async function getTeamsByLeague(leagueId: string): Promise<RawTeam[]> {
  return getCachedOrFetch(`teams:${leagueId}`, async () => {
    const data = await get<{ teams: RawTeam[] | null }>(`lookup_all_teams.php?id=${leagueId}`);
    return data.teams ?? [];
  }, TTL.teams);
}

/** Team details by ID */
export async function getTeamDetails(teamId: string): Promise<RawTeam | null> {
  return getCachedOrFetch(`team:${teamId}`, async () => {
    const data = await get<{ teams: RawTeam[] | null }>(`lookupteam.php?id=${teamId}`);
    return data.teams?.[0] ?? null;
  }, TTL.teams);
}

/** All events in a league for a season */
export async function getLeagueEvents(leagueId: string, season: string): Promise<RawEvent[]> {
  return getCachedOrFetch(`events:${leagueId}:${season}`, async () => {
    const data = await get<{ events: RawEvent[] | null }>(`eventsseason.php?id=${leagueId}&s=${season}`);
    return data.events ?? [];
  }, TTL.fixtures);
}

/** Next 15 upcoming events for a league */
export async function getUpcomingEventsByLeague(leagueId: string): Promise<RawEvent[]> {
  return getCachedOrFetch(`upcoming:${leagueId}`, async () => {
    const data = await get<{ events: RawEvent[] | null }>(`eventsnextleague.php?id=${leagueId}`);
    return data.events ?? [];
  }, TTL.fixtures);
}

/** Last 15 past events for a league */
export async function getPastEventsByLeague(leagueId: string): Promise<RawEvent[]> {
  return getCachedOrFetch(`past:${leagueId}`, async () => {
    const data = await get<{ events: RawEvent[] | null }>(`eventspastleague.php?id=${leagueId}`);
    return data.events ?? [];
  }, TTL.fixtures);
}

/** Event details by ID */
export async function getEventDetails(eventId: string): Promise<RawEvent | null> {
  return getCachedOrFetch(`event:${eventId}`, async () => {
    const data = await get<{ events: RawEvent[] | null }>(`lookupevent.php?id=${eventId}`);
    return data.events?.[0] ?? null;
  }, TTL.fixtures);
}

/** Live scores — only available with paid key; returns [] gracefully on free key */
export async function getLivescore(): Promise<RawLivescore[]> {
  // Not cached — always fresh, but caller should rate-limit to 60s
  try {
    const data = await get<{ events: RawLivescore[] | null }>(`livescore.php?l=FIFA%20World%20Cup`);
    return data.events ?? [];
  } catch {
    // Free key returns 403/empty — degrade gracefully
    return [];
  }
}

/** World Cup 2026 league ID on TheSportsDB */
export const WORLD_CUP_2026_LEAGUE_ID = "4429";   // FIFA World Cup
export const WORLD_CUP_2026_SEASON    = "2026";
