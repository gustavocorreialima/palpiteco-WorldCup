/**
 * Adapters: transform TheSportsDB raw types → internal Match / Team / WorldCupGroup shapes.
 * Controllers never touch raw API shapes — they only use these normalized types.
 */

import type { RawEvent, RawTeam } from "./theSportsDb";
import type { Match, Team, WorldCupGroup } from "../shared/database/seed";

// ─── status mapping ───────────────────────────────────────────────────────────

function mapStatus(strStatus?: string): "scheduled" | "live" | "finished" {
  if (!strStatus) return "scheduled";
  const s = strStatus.toLowerCase();
  if (s === "match finished" || s === "ft" || s === "aet" || s === "pen") return "finished";
  if (s === "1h" || s === "ht" || s === "2h" || s === "et" || s === "live") return "live";
  return "scheduled";
}

// ─── stage mapping ────────────────────────────────────────────────────────────

function mapStage(round?: string): Match["stage"] {
  if (!round) return "group";
  const r = round.toLowerCase();
  if (r.includes("final") && r.includes("quarter")) return "qf";
  if (r.includes("semi"))                            return "sf";
  if (r.includes("round of 16") || r.includes("r16") || r.includes("last 16")) return "r16";
  if (r.includes("final") && !r.includes("semi") && !r.includes("quarter"))    return "final";
  return "group";
}

// ─── team helper ──────────────────────────────────────────────────────────────

function makeTeam(id: string, name: string, badge?: string): Team {
  const short = name.length > 3 ? name.slice(0, 3).toUpperCase() : name.toUpperCase();
  return {
    id:        id || name,
    name:      name,
    shortName: short,
    logoUrl:   badge ?? `https://www.thesportsdb.com/images/media/team/badge/${name.replace(/\s/g,"-")}.png`,
  };
}

// ─── main adapters ────────────────────────────────────────────────────────────

export function adaptEvent(e: RawEvent): Match {
  const kickoff = e.dateEvent
    ? `${e.dateEvent}T${e.strTime ?? "00:00:00"}`
    : new Date().toISOString();

  return {
    id:             e.idEvent,
    homeTeam:       makeTeam(e.idHomeTeam ?? e.strHomeTeam, e.strHomeTeam, e.strHomeTeamBadge),
    awayTeam:       makeTeam(e.idAwayTeam ?? e.strAwayTeam, e.strAwayTeam, e.strAwayTeamBadge),
    competition:    "Copa do Mundo 2026",
    competitionLogo:"https://www.thesportsdb.com/images/media/league/badge/wc_logo.png",
    round:          e.strRound ?? "Fase de Grupos",
    kickoffAt:      kickoff,
    status:         mapStatus(e.strStatus),
    homeScore:      e.intHomeScore != null ? Number(e.intHomeScore) : null,
    awayScore:      e.intAwayScore != null ? Number(e.intAwayScore) : null,
    homeScoreHT:    null,
    awayScoreHT:    null,
    minute:         e.intMatchMinute ? Number(e.intMatchMinute) : undefined,
    stage:          mapStage(e.strRound),
    groupName:      e.strGroup ?? undefined,
    h2h:            { homeWins: 0, draws: 0, awayWins: 0, homeGoals: 0, awayGoals: 0 },
  };
}

export function adaptTeam(t: RawTeam): Team {
  return {
    id:        t.idTeam,
    name:      t.strTeam,
    shortName: t.strTeamShort ?? t.strTeam.slice(0, 3).toUpperCase(),
    logoUrl:   t.strBadge ?? "",
    country:   t.strCountry ?? t.strTeam,
  };
}

/** Build WorldCupGroup array from a list of matches (group stage only) */
export function buildGroupsFromMatches(matches: Match[]): WorldCupGroup[] {
  const groupMatches = matches.filter(m => m.stage === "group" && m.groupName);
  const grouped = new Map<string, Match[]>();
  for (const m of groupMatches) {
    const g = m.groupName!;
    if (!grouped.has(g)) grouped.set(g, []);
    grouped.get(g)!.push(m);
  }

  const groups: WorldCupGroup[] = [];
  for (const [name, ms] of grouped.entries()) {
    const teamMap = new Map<string, { team: Team; played: number; won: number; drawn: number; lost: number; gf: number; ga: number; pts: number }>();

    for (const m of ms) {
      if (m.status !== "finished" || m.homeScore == null || m.awayScore == null) {
        // Register teams even without results
        if (!teamMap.has(m.homeTeam.id)) teamMap.set(m.homeTeam.id, { team: m.homeTeam, played:0,won:0,drawn:0,lost:0,gf:0,ga:0,pts:0 });
        if (!teamMap.has(m.awayTeam.id)) teamMap.set(m.awayTeam.id, { team: m.awayTeam, played:0,won:0,drawn:0,lost:0,gf:0,ga:0,pts:0 });
        continue;
      }
      const h = m.homeScore, a = m.awayScore;
      const home = teamMap.get(m.homeTeam.id) ?? { team: m.homeTeam, played:0,won:0,drawn:0,lost:0,gf:0,ga:0,pts:0 };
      const away = teamMap.get(m.awayTeam.id) ?? { team: m.awayTeam, played:0,won:0,drawn:0,lost:0,gf:0,ga:0,pts:0 };
      home.played++; away.played++;
      home.gf += h; home.ga += a;
      away.gf += a; away.ga += h;
      if (h > a)      { home.won++;   home.pts+=3; away.lost++; }
      else if (h < a) { away.won++;   away.pts+=3; home.lost++; }
      else            { home.drawn++; home.pts++;  away.drawn++; away.pts++; }
      teamMap.set(m.homeTeam.id, home);
      teamMap.set(m.awayTeam.id, away);
    }

    const teams = [...teamMap.values()].sort((a, b) =>
      b.pts - a.pts || (b.gf - b.ga) - (a.gf - a.ga) || b.gf - a.gf
    );
    groups.push({ name, teams });
  }

  return groups.sort((a, b) => a.name.localeCompare(b.name));
}
