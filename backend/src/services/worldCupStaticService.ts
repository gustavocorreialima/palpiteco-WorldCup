/**
 * World Cup 2026 — static data service.
 * All match/team data comes from local JSON files; zero external API calls.
 * Live score updates are handled separately in liveScoreService.ts.
 */

import matchesRaw  from "../data/worldCup2026/matches.json";
import teamsRaw    from "../data/worldCup2026/teams.json";

// ─── Types ────────────────────────────────────────────────────────────────────

export interface WCTeamRef {
  name: string;
  code: string;
  flag: string;
}

export interface WCMatch {
  id: string;
  stage: "group" | "r32" | "qf" | "sf" | "third" | "final";
  group: string | null;
  round: string;
  date: string;           // "YYYY-MM-DD"
  time: string;           // "HH:MM" BRT
  venue: string;
  city: string;
  homeTeam: WCTeamRef;
  awayTeam: WCTeamRef;
  status: "scheduled" | "live" | "finished";
  homeScore: number | null;
  awayScore: number | null;
}

export interface WCTeam {
  code: string;
  name: string;
  group: string;
  flag: string;
}

export interface WCGroupStanding {
  team: WCTeam;
  played: number;
  won: number;
  drawn: number;
  lost: number;
  gf: number;
  ga: number;
  gd: number;
  pts: number;
}

export interface WCGroup {
  name: string;        // "Grupo A"
  letter: string;      // "A"
  teams: WCGroupStanding[];
  matches: WCMatch[];
}

// Frontend-compatible match shape (matches what index.html expects)
export interface FrontendMatch {
  id: string;
  competition: string;
  competitionLogo: string;
  round: string;
  kickoffAt: string;      // ISO "2026-06-11T16:00:00"
  status: "scheduled" | "live" | "finished";
  stage: string;
  groupName: string | null;
  venue: string;
  city: string;
  homeTeam: { id: string; name: string; shortName: string; logoUrl: string; flag: string };
  awayTeam: { id: string; name: string; shortName: string; logoUrl: string; flag: string };
  homeScore: number | null;
  awayScore: number | null;
  homeScoreHT: null;
  awayScoreHT: null;
  h2h: { homeWins: number; draws: number; awayWins: number; homeGoals: number; awayGoals: number };
}

export function toFrontendMatch(m: WCMatch): FrontendMatch {
  const kickoffAt = `${m.date}T${m.time}:00`;
  const mapTeam = (t: WCTeamRef) => ({
    id:        t.code,
    name:      t.name,
    shortName: t.code,
    logoUrl:   `https://flagcdn.com/w80/${countryCode(t.code)}.png`,
    flag:      t.flag,
  });
  return {
    id:             m.id,
    competition:    "Copa do Mundo 2026",
    competitionLogo:"",
    round:          m.round,
    kickoffAt,
    status:         m.status,
    stage:          m.stage,
    groupName:      m.group,
    venue:          m.venue,
    city:           m.city,
    homeTeam:       mapTeam(m.homeTeam),
    awayTeam:       mapTeam(m.awayTeam),
    homeScore:      m.homeScore,
    awayScore:      m.awayScore,
    homeScoreHT:    null,
    awayScoreHT:    null,
    h2h:            { homeWins:0, draws:0, awayWins:0, homeGoals:0, awayGoals:0 },
  };
}

// Maps FIFA team code → ISO 3166-1 alpha-2 for flagcdn.com
function countryCode(code: string): string {
  const map: Record<string, string> = {
    ARG:"ar", BRA:"br", FRA:"fr", ENG:"gb-eng", ESP:"es", GER:"de",
    POR:"pt", NED:"nl", BEL:"be", URU:"uy", MEX:"mx", USA:"us",
    CAN:"ca", JPN:"jp", KOR:"kr", AUS:"au", MAR:"ma", SEN:"sn",
    TUR:"tr", PAR:"py", ECU:"ec", GHA:"gh", CRO:"hr", PAN:"pa",
    SUI:"ch", QAT:"qa", BIH:"ba", SCO:"gb-sct", HAI:"ht", CZE:"cz",
    RSA:"za", CUW:"cw", CIV:"ci", SWE:"se", TUN:"tn", EGY:"eg",
    IRN:"ir", NZL:"nz", CPV:"cv", SAU:"sa", IRQ:"iq", NOR:"no",
    ALG:"dz", AUT:"at", JOR:"jo", POR2:"pt", COD:"cd", UZB:"uz",
    COL:"co", SRB:"rs", POL:"pl", CHI:"cl", HUN:"hu",
  };
  return map[code] ?? "un";
}

// ─── Typed data ───────────────────────────────────────────────────────────────

const ALL_MATCHES = matchesRaw as WCMatch[];
const ALL_TEAMS   = teamsRaw   as WCTeam[];

// ─── Public API ───────────────────────────────────────────────────────────────

/** All 104 matches */
export function getAllMatches(): WCMatch[] {
  return ALL_MATCHES;
}

/** Matches filtered by date "YYYY-MM-DD" */
export function getMatchesByDate(date: string): WCMatch[] {
  return ALL_MATCHES.filter(m => m.date === date);
}

/** All upcoming matches (status === "scheduled"), sorted by date+time */
export function getUpcomingMatches(): WCMatch[] {
  return ALL_MATCHES
    .filter(m => m.status === "scheduled")
    .sort(byKickoff);
}

/** All finished matches, most recent first */
export function getFinishedMatches(): WCMatch[] {
  return ALL_MATCHES
    .filter(m => m.status === "finished")
    .sort((a, b) => byKickoff(b, a));
}

/** Matches for a specific group letter ("A"…"L") */
export function getMatchesByGroup(letter: string): WCMatch[] {
  return ALL_MATCHES.filter(m => m.group === letter.toUpperCase());
}

/** All knockout matches (r32, qf, sf, third, final) */
export function getKnockoutMatches(): WCMatch[] {
  return ALL_MATCHES.filter(m => m.stage !== "group");
}

/** Knockout matches split by stage */
export function getBracket() {
  return {
    roundOf32:     ALL_MATCHES.filter(m => m.stage === "r32"),
    quarterFinals: ALL_MATCHES.filter(m => m.stage === "qf"),
    semiFinals:    ALL_MATCHES.filter(m => m.stage === "sf"),
    thirdPlace:    ALL_MATCHES.filter(m => m.stage === "third"),
    final:         ALL_MATCHES.filter(m => m.stage === "final"),
  };
}

/** All 48 national teams */
export function getTeams(): WCTeam[] {
  return ALL_TEAMS;
}

/** Teams in a specific group letter */
export function getTeamsByGroup(letter: string): WCTeam[] {
  return ALL_TEAMS.filter(t => t.group === letter.toUpperCase());
}

/** All 12 groups with standings computed from finished matches */
export function getGroups(): WCGroup[] {
  const letters = [...new Set(ALL_TEAMS.map(t => t.group))].sort();

  return letters.map(letter => {
    const teams   = ALL_TEAMS.filter(t => t.group === letter);
    const matches = ALL_MATCHES.filter(m => m.group === letter);

    // Build standings map
    const standings = new Map<string, WCGroupStanding>();
    for (const t of teams) {
      standings.set(t.code, { team: t, played:0, won:0, drawn:0, lost:0, gf:0, ga:0, gd:0, pts:0 });
    }

    for (const m of matches) {
      if (m.status !== "finished" || m.homeScore == null || m.awayScore == null) continue;
      const h = standings.get(m.homeTeam.code);
      const a = standings.get(m.awayTeam.code);
      if (!h || !a) continue;
      h.played++; a.played++;
      h.gf += m.homeScore; h.ga += m.awayScore;
      a.gf += m.awayScore; a.ga += m.homeScore;
      if (m.homeScore > m.awayScore)      { h.won++;   h.pts+=3; a.lost++; }
      else if (m.homeScore < m.awayScore) { a.won++;   a.pts+=3; h.lost++; }
      else                                 { h.drawn++; h.pts++;  a.drawn++; a.pts++; }
      h.gd = h.gf - h.ga;
      a.gd = a.gf - a.ga;
    }

    const sorted = [...standings.values()].sort(
      (a, b) => b.pts - a.pts || b.gd - a.gd || b.gf - a.gf
    );

    return { name: `Grupo ${letter}`, letter, teams: sorted, matches };
  });
}

/** Next N upcoming matches (default 10) */
export function getNextMatches(n = 10): WCMatch[] {
  return getUpcomingMatches().slice(0, n);
}

/** Matches for a date range */
export function getMatchesByDateRange(from: string, to: string): WCMatch[] {
  return ALL_MATCHES.filter(m => m.date >= from && m.date <= to).sort(byKickoff);
}

/** Unique match dates with at least one game */
export function getMatchDates(): string[] {
  return [...new Set(ALL_MATCHES.map(m => m.date))].sort();
}

// ─── helper ───────────────────────────────────────────────────────────────────

function byKickoff(a: WCMatch, b: WCMatch): number {
  const da = `${a.date}T${a.time}`;
  const db = `${b.date}T${b.time}`;
  return da < db ? -1 : da > db ? 1 : 0;
}
