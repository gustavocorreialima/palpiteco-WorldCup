/**
 * In-memory mock database.
 * All modules import from here — swap each export for a real DB call in production.
 */

// ─────────────────────────────────────────────
// INTERFACES
// ─────────────────────────────────────────────

export interface Team {
  id: string; name: string; shortName: string; logoUrl: string; country?: string;
}

export interface Match {
  id: string;
  homeTeam: Team; awayTeam: Team;
  competition: string; competitionLogo: string; round: string;
  kickoffAt: string;
  status: "scheduled" | "live" | "finished";
  homeScore: number | null; awayScore: number | null;
  homeScoreHT: number | null; awayScoreHT: number | null;
  minute?: number;
  stage?: "group" | "r16" | "qf" | "sf" | "final";
  groupName?: string;
  h2h: { homeWins: number; draws: number; awayWins: number; homeGoals: number; awayGoals: number };
  aiTip?: { prediction: string; confidence: number; reason: string };
}

export interface Bet {
  id: string; userId: string; matchId: string; groupId?: string;
  predictedHome: number; predictedAway: number;
  points: number | null; status: "pending" | "won" | "lost";
  isExact?: boolean; isCorrectOutcome?: boolean;
  submittedAt: string; lockedAt?: string;
  editHistory: Array<{ home: number; away: number; at: string }>;
}

export interface User {
  id: string; username: string; displayName: string;
  email: string; passwordHash: string;
  avatarInitials: string; avatarColor: string;
  points: number; accuracy: number; streak: number; rank: number;
  level: number; xp: number;
  betsTotal: number; betsCorrect: number; betsExact: number;
  badges: string[];
  rankVariation: number;
}

export interface Club {
  id: string; name: string; description: string;
  ownerId: string; inviteCode: string;
  type: "public" | "private" | "invite";
  password?: string;
  members: ClubMember[];
  chat: ChatMessage[];
  scoringRules: ScoringRules;
  competitionId?: string;
  createdAt: string;
}

export interface ClubMember {
  userId: string; role: "admin" | "member";
  points: number; rank: number; joinedAt: string;
}

export interface ChatMessage {
  id: string; userId: string; content: string;
  reactions: Record<string, number>;
  createdAt: string;
}

export interface ScoringRules {
  exactScore: number;
  correctOutcome: number;
  correctDraw: number;
  goalDiff: number;
  streakBonus: number;
  finalMultiplier: number;
}

export interface Notification {
  id: string; userId: string; type: string;
  title: string; body: string; read: boolean; createdAt: string;
  matchId?: string;
}

export interface WorldCupGroup {
  name: string;
  teams: Array<{ team: Team; played: number; won: number; drawn: number; lost: number; gf: number; ga: number; pts: number }>;
}

// ─────────────────────────────────────────────
// SCORING ENGINE
// ─────────────────────────────────────────────

export function calculatePoints(
  predictedHome: number, predictedAway: number,
  actualHome: number,    actualAway: number,
  rules: ScoringRules = DEFAULT_RULES,
  isFinal = false,
  streakLen = 0,
): { points: number; isExact: boolean; isCorrectOutcome: boolean; breakdown: string[] } {
  const breakdown: string[] = [];
  let pts = 0;

  const predictedOutcome = Math.sign(predictedHome - predictedAway);
  const actualOutcome    = Math.sign(actualHome    - actualAway);

  const isExact          = predictedHome === actualHome && predictedAway === actualAway;
  const isCorrectOutcome = predictedOutcome === actualOutcome;
  const isDraw           = actualOutcome === 0;
  const correctDiff      = Math.abs(predictedHome - predictedAway) === Math.abs(actualHome - actualAway);

  if (isExact) {
    pts += rules.exactScore;
    breakdown.push(`Placar exato +${rules.exactScore}`);
  } else if (isDraw && isCorrectOutcome) {
    pts += rules.correctDraw;
    breakdown.push(`Empate correto +${rules.correctDraw}`);
  } else if (isCorrectOutcome) {
    pts += rules.correctOutcome;
    breakdown.push(`Vencedor correto +${rules.correctOutcome}`);
  }

  if (!isExact && isCorrectOutcome && correctDiff) {
    pts += rules.goalDiff;
    breakdown.push(`Diferença de gols +${rules.goalDiff}`);
  }

  if (streakLen >= 3) {
    pts += rules.streakBonus;
    breakdown.push(`Bônus sequência +${rules.streakBonus}`);
  }

  if (isFinal && pts > 0) {
    pts *= rules.finalMultiplier;
    breakdown.push(`Multiplicador final ×${rules.finalMultiplier}`);
  }

  return { points: pts, isExact, isCorrectOutcome, breakdown };
}

export const DEFAULT_RULES: ScoringRules = {
  exactScore: 10, correctOutcome: 5, correctDraw: 7,
  goalDiff: 3, streakBonus: 2, finalMultiplier: 2,
};

// ─────────────────────────────────────────────
// DATA — all empty, populated at runtime
// ─────────────────────────────────────────────

export const matches: Match[]             = [];
export const users: User[]                = [];
export const bets: Bet[]                  = [];
export const clubs: Club[]                = [];
export const notifications: Notification[]= [];
export const worldCupGroups: WorldCupGroup[] = [];

// ─────────────────────────────────────────────
// SESSIONS
// ─────────────────────────────────────────────

export const sessions = new Map<string, string>(); // token → userId

export function createSession(userId: string): string {
  const token = `tok_${userId}_${Date.now()}_${Math.random().toString(36).slice(2)}`;
  sessions.set(token, userId);
  return token;
}

export function getUserFromToken(token: string): User | undefined {
  const uid = sessions.get(token);
  return uid ? users.find(u => u.id === uid) : undefined;
}

export async function seedDatabase(): Promise<void> {
  // One permanent demo account — always available
  users.push({
    id: "demo",
    username: "demo",
    displayName: "Demo",
    email: "demo@bolao.com",
    passwordHash: "demo",
    avatarInitials: "DE",
    avatarColor: "#3A86FF",
    points: 0, accuracy: 0, streak: 0, rank: 1,
    level: 1, xp: 0,
    betsTotal: 0, betsCorrect: 0, betsExact: 0,
    badges: [], rankVariation: 0,
  });
  sessions.set("demo_token", "demo");
  console.log("  DB ready — demo account: demo@bolao.com / demo");
}
