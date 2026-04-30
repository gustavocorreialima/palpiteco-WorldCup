/**
 * Live score service — PLACEHOLDER for future integration.
 *
 * Currently returns empty arrays. Wire up a real API here when live data
 * becomes necessary (e.g. during the tournament in June-July 2026).
 *
 * Candidate APIs (all require a paid key during the tournament):
 *   - API-Football (api-sports.io)
 *   - TheSportsDB Patreon tier
 *   - football-data.org
 *
 * The static service (worldCupStaticService.ts) handles all schedule
 * and group data. This file only deals with in-progress score updates.
 */

export interface LiveMatch {
  id: string;
  homeTeamCode: string;
  awayTeamCode: string;
  homeScore: number;
  awayScore: number;
  minute: number;
  status: "1H" | "HT" | "2H" | "ET" | "PEN";
}

/** Returns live matches. Currently a no-op; replace body when API is ready. */
export async function getLiveMatches(): Promise<LiveMatch[]> {
  // TODO: integrate live API here
  return [];
}

/** Returns true if any Copa 2026 match is currently in progress. */
export async function hasLiveMatches(): Promise<boolean> {
  const live = await getLiveMatches();
  return live.length > 0;
}
