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
  exactScore: number;       // default 10
  correctOutcome: number;   // default 5
  correctDraw: number;      // default 7
  goalDiff: number;         // default 3
  streakBonus: number;      // default 2
  finalMultiplier: number;  // default 2
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
// TEAMS
// ─────────────────────────────────────────────

export const teams: Record<string, Team> = {
  flamengo:      { id:"t1",  name:"Flamengo",      shortName:"FLA", logoUrl:"https://upload.wikimedia.org/wikipedia/commons/thumb/2/2d/Flamengo_escudo.svg/180px-Flamengo_escudo.svg.png", country:"BR" },
  palmeiras:     { id:"t2",  name:"Palmeiras",      shortName:"PAL", logoUrl:"https://upload.wikimedia.org/wikipedia/commons/thumb/1/10/Palmeiras_logo.svg/180px-Palmeiras_logo.svg.png", country:"BR" },
  corinthians:   { id:"t3",  name:"Corinthians",    shortName:"COR", logoUrl:"https://upload.wikimedia.org/wikipedia/commons/thumb/6/63/Sport_Club_Corinthians_Paulista_%28logo%29.svg/180px-Sport_Club_Corinthians_Paulista_%28logo%29.svg.png", country:"BR" },
  saoPaulo:      { id:"t4",  name:"São Paulo",      shortName:"SAO", logoUrl:"https://upload.wikimedia.org/wikipedia/commons/thumb/6/6f/Brasao_do_Sao_Paulo_Futebol_Clube.svg/180px-Brasao_do_Sao_Paulo_Futebol_Clube.svg.png", country:"BR" },
  atletico:      { id:"t5",  name:"Atlético-MG",    shortName:"CAM", logoUrl:"https://upload.wikimedia.org/wikipedia/commons/thumb/7/79/Atletico_mineiro_galo.svg/180px-Atletico_mineiro_galo.svg.png", country:"BR" },
  internacional: { id:"t6",  name:"Internacional",  shortName:"INT", logoUrl:"https://upload.wikimedia.org/wikipedia/commons/thumb/f/f3/Internacional_Logo.png/180px-Internacional_Logo.png", country:"BR" },
  // Copa do Mundo
  brasil:        { id:"t10", name:"Brasil",          shortName:"BRA", logoUrl:"https://upload.wikimedia.org/wikipedia/commons/0/05/Flag_of_Brazil.svg", country:"BR" },
  argentina:     { id:"t11", name:"Argentina",       shortName:"ARG", logoUrl:"https://upload.wikimedia.org/wikipedia/commons/1/1a/24701-eagle-device-argentina-football-association.svg", country:"AR" },
  franca:        { id:"t12", name:"França",          shortName:"FRA", logoUrl:"https://upload.wikimedia.org/wikipedia/en/c/c3/Flag_of_France.svg", country:"FR" },
  alemanha:      { id:"t13", name:"Alemanha",        shortName:"GER", logoUrl:"https://upload.wikimedia.org/wikipedia/en/b/ba/Flag_of_Germany.svg", country:"DE" },
  inglaterra:    { id:"t14", name:"Inglaterra",      shortName:"ENG", logoUrl:"https://upload.wikimedia.org/wikipedia/en/b/be/Flag_of_England.svg", country:"EN" },
  espanha:       { id:"t15", name:"Espanha",         shortName:"ESP", logoUrl:"https://upload.wikimedia.org/wikipedia/en/9/9a/Flag_of_Spain.svg", country:"ES" },
  portugal:      { id:"t16", name:"Portugal",        shortName:"POR", logoUrl:"https://upload.wikimedia.org/wikipedia/commons/5/5c/Flag_of_Portugal.svg", country:"PT" },
  uruguai:       { id:"t17", name:"Uruguai",         shortName:"URU", logoUrl:"https://upload.wikimedia.org/wikipedia/commons/f/fe/Flag_of_Uruguay.svg", country:"UY" },
};

// ─────────────────────────────────────────────
// MATCHES — Brasileirão + Copa do Mundo
// ─────────────────────────────────────────────

export const matches: Match[] = [
  // ── Brasileirão ──────────────────────────────
  {
    id:"m1", homeTeam:teams.flamengo, awayTeam:teams.palmeiras,
    competition:"Brasileirão Série A", competitionLogo:"🇧🇷", round:"Rodada 15",
    kickoffAt: new Date(Date.now() + 2*3600*1000).toISOString(),
    status:"scheduled", homeScore:null, awayScore:null, homeScoreHT:null, awayScoreHT:null,
    h2h:{ homeWins:4, draws:3, awayWins:3, homeGoals:14, awayGoals:12 },
    aiTip:{ prediction:"Flamengo vence", confidence:62, reason:"Melhor aproveitamento em casa (78%) e 3 vitórias seguidas" },
  },
  {
    id:"m2", homeTeam:teams.corinthians, awayTeam:teams.saoPaulo,
    competition:"Brasileirão Série A", competitionLogo:"🇧🇷", round:"Rodada 15",
    kickoffAt: new Date(Date.now() - 40*60*1000).toISOString(),
    status:"live", homeScore:1, awayScore:1, homeScoreHT:1, awayScoreHT:0, minute:64,
    h2h:{ homeWins:5, draws:4, awayWins:6, homeGoals:18, awayGoals:20 },
    aiTip:{ prediction:"Empate", confidence:48, reason:"Clássico equilibrado — média de 2.1 gols nos últimos 10 H2H" },
  },
  {
    id:"m3", homeTeam:teams.atletico, awayTeam:teams.internacional,
    competition:"Brasileirão Série A", competitionLogo:"🇧🇷", round:"Rodada 14",
    kickoffAt: new Date(Date.now() - 24*3600*1000).toISOString(),
    status:"finished", homeScore:2, awayScore:0, homeScoreHT:1, awayScoreHT:0,
    h2h:{ homeWins:6, draws:2, awayWins:2, homeGoals:22, awayGoals:10 },
    aiTip:{ prediction:"Atlético-MG vence", confidence:71, reason:"Invicto em casa há 7 jogos" },
  },
  {
    id:"m4", homeTeam:teams.palmeiras, awayTeam:teams.saoPaulo,
    competition:"Brasileirão Série A", competitionLogo:"🇧🇷", round:"Rodada 15",
    kickoffAt: new Date(Date.now() + 26*3600*1000).toISOString(),
    status:"scheduled", homeScore:null, awayScore:null, homeScoreHT:null, awayScoreHT:null,
    h2h:{ homeWins:7, draws:5, awayWins:4, homeGoals:24, awayGoals:16 },
    aiTip:{ prediction:"Palmeiras vence", confidence:58, reason:"Visitante sem vencer nos últimos 5 jogos fora" },
  },
  // ── Copa do Mundo 2026 — Grupo A ─────────────
  {
    id:"wc1", homeTeam:teams.brasil, awayTeam:teams.alemanha,
    competition:"Copa do Mundo 2026", competitionLogo:"🌍", round:"Grupo A — Jogo 1",
    kickoffAt: new Date(Date.now() + 72*3600*1000).toISOString(),
    stage:"group", groupName:"A",
    status:"scheduled", homeScore:null, awayScore:null, homeScoreHT:null, awayScoreHT:null,
    h2h:{ homeWins:5, draws:2, awayWins:4, homeGoals:16, awayGoals:14 },
    aiTip:{ prediction:"Brasil vence", confidence:55, reason:"Brasil em casa (estádio neutro favorece torcida maior)" },
  },
  {
    id:"wc2", homeTeam:teams.argentina, awayTeam:teams.franca,
    competition:"Copa do Mundo 2026", competitionLogo:"🌍", round:"Final — Copa 2026",
    kickoffAt: new Date(Date.now() + 5*24*3600*1000).toISOString(),
    stage:"final", groupName:undefined,
    status:"scheduled", homeScore:null, awayScore:null, homeScoreHT:null, awayScoreHT:null,
    h2h:{ homeWins:3, draws:3, awayWins:4, homeGoals:12, awayGoals:14 },
    aiTip:{ prediction:"Empate + Argentina pênaltis", confidence:41, reason:"Rematch da Final 2022 — padrão histórico favorece jogo equilibrado" },
  },
  {
    id:"wc3", homeTeam:teams.inglaterra, awayTeam:teams.espanha,
    competition:"Copa do Mundo 2026", competitionLogo:"🌍", round:"Semifinal",
    kickoffAt: new Date(Date.now() + 3*24*3600*1000).toISOString(),
    stage:"sf",
    status:"scheduled", homeScore:null, awayScore:null, homeScoreHT:null, awayScoreHT:null,
    h2h:{ homeWins:4, draws:4, awayWins:6, homeGoals:15, awayGoals:18 },
    aiTip:{ prediction:"Espanha vence", confidence:53, reason:"Melhor posse e criação de chances neste torneio" },
  },
];

// ─────────────────────────────────────────────
// COPA DO MUNDO — GRUPOS
// ─────────────────────────────────────────────

export const worldCupGroups: WorldCupGroup[] = [
  {
    name:"A",
    teams:[
      { team:teams.brasil,    played:2, won:2, drawn:0, lost:0, gf:4, ga:1, pts:6 },
      { team:teams.alemanha,  played:2, won:1, drawn:0, lost:1, gf:3, ga:2, pts:3 },
      { team:teams.franca,    played:2, won:1, drawn:0, lost:1, gf:2, ga:3, pts:3 },
      { team:teams.uruguai,   played:2, won:0, drawn:0, lost:2, gf:1, ga:4, pts:0 },
    ],
  },
  {
    name:"B",
    teams:[
      { team:teams.argentina, played:2, won:2, drawn:0, lost:0, gf:5, ga:0, pts:6 },
      { team:teams.espanha,   played:2, won:1, drawn:1, lost:0, gf:3, ga:1, pts:4 },
      { team:teams.portugal,  played:2, won:0, drawn:1, lost:1, gf:2, ga:4, pts:1 },
      { team:teams.inglaterra,played:2, won:0, drawn:0, lost:2, gf:0, ga:5, pts:0 },
    ],
  },
];

// ─────────────────────────────────────────────
// USERS
// ─────────────────────────────────────────────

export const users: User[] = [
  { id:"u1", username:"gustavo",  displayName:"Gustavo Lima",    email:"gustavo@demo.com",  passwordHash:"$2b$10$demo", avatarInitials:"GL", avatarColor:"#2ECC71", points:245, accuracy:68.5, streak:4, rank:1, level:8, xp:4200, betsTotal:32, betsCorrect:22, betsExact:5, badges:["🔥 Sequência","🎯 Precisão","⚽ Veterano"], rankVariation:2 },
  { id:"u2", username:"rafaela",  displayName:"Rafaela Costa",   email:"rafa@demo.com",     passwordHash:"$2b$10$demo", avatarInitials:"RC", avatarColor:"#3498DB", points:220, accuracy:62.0, streak:2, rank:2, level:7, xp:3600, betsTotal:28, betsCorrect:17, betsExact:3, badges:["🥈 Vice","🎯 Precisão"], rankVariation:0 },
  { id:"u3", username:"marcos",   displayName:"Marcos Oliveira", email:"marcos@demo.com",   passwordHash:"$2b$10$demo", avatarInitials:"MO", avatarColor:"#9B59B6", points:198, accuracy:59.3, streak:0, rank:3, level:6, xp:3100, betsTotal:25, betsCorrect:15, betsExact:2, badges:["🥉 Bronze"], rankVariation:-1 },
  { id:"u4", username:"juliana",  displayName:"Juliana Souza",   email:"ju@demo.com",       passwordHash:"$2b$10$demo", avatarInitials:"JS", avatarColor:"#E74C3C", points:175, accuracy:55.1, streak:1, rank:4, level:5, xp:2400, betsTotal:20, betsCorrect:11, betsExact:1, badges:[], rankVariation:1 },
  { id:"u5", username:"pedro",    displayName:"Pedro Alves",     email:"pedro@demo.com",    passwordHash:"$2b$10$demo", avatarInitials:"PA", avatarColor:"#F39C12", points:150, accuracy:50.0, streak:0, rank:5, level:4, xp:1800, betsTotal:18, betsCorrect:9,  betsExact:0, badges:[], rankVariation:-2 },
];

// ─────────────────────────────────────────────
// BETS
// ─────────────────────────────────────────────

export const bets: Bet[] = [
  { id:"b1", userId:"u1", matchId:"m2", predictedHome:1, predictedAway:1, points:null, status:"pending", submittedAt: new Date(Date.now()-60*60*1000).toISOString(), editHistory:[], isExact:false, isCorrectOutcome:false },
  { id:"b2", userId:"u1", matchId:"m3", predictedHome:2, predictedAway:0, points:13,  status:"won",     submittedAt: new Date(Date.now()-25*3600*1000).toISOString(), editHistory:[], isExact:true, isCorrectOutcome:true },
  { id:"b3", userId:"u1", matchId:"wc1",predictedHome:2, predictedAway:1, points:null, status:"pending", submittedAt: new Date(Date.now()-10*60*1000).toISOString(), editHistory:[] },
];

// ─────────────────────────────────────────────
// CLUBS
// ─────────────────────────────────────────────

export const clubs: Club[] = [
  {
    id:"c1", name:"Galera do Flamengo 🔴⚫", description:"Bolão dos rubro-negros",
    ownerId:"u1", inviteCode:"FLA2026",
    type:"private", password:"mengao",
    members:[
      { userId:"u1", role:"admin",  points:245, rank:1, joinedAt:"2026-01-01T00:00:00Z" },
      { userId:"u2", role:"member", points:180, rank:2, joinedAt:"2026-01-02T00:00:00Z" },
      { userId:"u3", role:"member", points:155, rank:3, joinedAt:"2026-01-03T00:00:00Z" },
    ],
    chat:[
      { id:"msg1", userId:"u2", content:"Hoje o Mengão vai massacrar! 🔥", reactions:{"🔥":4,"❤️":2}, createdAt:new Date(Date.now()-30*60*1000).toISOString() },
      { id:"msg2", userId:"u1", content:"Concordo, palpitei 2-0 🎯",       reactions:{"👍":3},         createdAt:new Date(Date.now()-20*60*1000).toISOString() },
      { id:"msg3", userId:"u3", content:"Vou de empate, confio no Palestra", reactions:{"😂":2},        createdAt:new Date(Date.now()-5*60*1000).toISOString() },
    ],
    scoringRules: DEFAULT_RULES,
    createdAt:"2026-01-01T00:00:00Z",
  },
  {
    id:"c2", name:"Bolão Copa 2026 🌍", description:"Bolão público da Copa do Mundo",
    ownerId:"u2", inviteCode:"COPA26",
    type:"public",
    members:[
      { userId:"u1", role:"member", points:120, rank:1, joinedAt:"2026-03-01T00:00:00Z" },
      { userId:"u2", role:"admin",  points:100, rank:2, joinedAt:"2026-03-01T00:00:00Z" },
      { userId:"u4", role:"member", points:85,  rank:3, joinedAt:"2026-03-02T00:00:00Z" },
      { userId:"u5", role:"member", points:70,  rank:4, joinedAt:"2026-03-03T00:00:00Z" },
    ],
    chat:[
      { id:"msg4", userId:"u4", content:"Brasil campeão! 🏆🇧🇷", reactions:{"🔥":8,"🇧🇷":5}, createdAt:new Date(Date.now()-2*3600*1000).toISOString() },
    ],
    scoringRules: { ...DEFAULT_RULES, exactScore:15, finalMultiplier:3 },
    createdAt:"2026-03-01T00:00:00Z",
  },
];

// ─────────────────────────────────────────────
// NOTIFICATIONS
// ─────────────────────────────────────────────

export const notifications: Notification[] = [
  { id:"n1", userId:"u1", type:"match_soon",    title:"⏰ Jogo em 2 horas!", body:"Flamengo × Palmeiras começa às "+new Date(Date.now()+2*3600*1000).toLocaleTimeString("pt-BR",{hour:"2-digit",minute:"2-digit"})+". Faça seu palpite!", read:false, createdAt:new Date(Date.now()-10*60*1000).toISOString(), matchId:"m1" },
  { id:"n2", userId:"u1", type:"bet_result",    title:"✅ Palpite certeiro!",  body:"Você acertou o placar exato do Atlético × Internacional (2-0). +13 pts!", read:false, createdAt:new Date(Date.now()-23*3600*1000).toISOString(), matchId:"m3" },
  { id:"n3", userId:"u1", type:"rank_change",   title:"📈 Você subiu 2 posições!", body:"Você está em #1 no ranking geral. Continue assim! 🔥", read:true,  createdAt:new Date(Date.now()-2*24*3600*1000).toISOString() },
  { id:"n4", userId:"u1", type:"club_message",  title:"💬 Novo no Galera do Flamengo", body:"marcos: 'Vou de empate, confio no Palestra'", read:false, createdAt:new Date(Date.now()-5*60*1000).toISOString() },
  { id:"n5", userId:"u1", type:"pending_bet",   title:"🎯 Palpite pendente!", body:"Copa do Mundo: Brasil × Alemanha começa em 72h. Você ainda não palpitou!", read:false, createdAt:new Date(Date.now()-1*3600*1000).toISOString(), matchId:"wc1" },
];

// ─────────────────────────────────────────────
// SESSIONS (mock JWT replacement)
// ─────────────────────────────────────────────

export const sessions = new Map<string, string>(); // token → userId

export function createSession(userId: string): string {
  const token = `mock_${userId}_${Date.now()}_${Math.random().toString(36).slice(2)}`;
  sessions.set(token, userId);
  return token;
}

export function getUserFromToken(token: string): User | undefined {
  const uid = sessions.get(token);
  return uid ? users.find(u => u.id === uid) : undefined;
}

export async function seedDatabase(): Promise<void> {
  // Pre-seed a demo session for the demo user
  sessions.set("demo_token", "u1");
  console.log("  📦  Mock DB seeded —", matches.length, "matches,", clubs.length, "clubs,", notifications.length, "notifications");
}
