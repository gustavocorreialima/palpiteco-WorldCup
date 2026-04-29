import { FastifyInstance } from "fastify";
import {
  clubs, Club, ClubMember, ChatMessage, users,
  getUserFromToken, DEFAULT_RULES,
} from "../../../shared/database/seed";

export async function groupRoutes(app: FastifyInstance) {
  // List all clubs (public) or clubs user is member of
  app.get("/", async (req, reply) => {
    const user   = resolveUser(req.headers.authorization);
    const userId = user?.id;
    const result = clubs.map(c => ({
      ...c,
      chat:    c.chat.slice(-3),           // last 3 messages preview
      isMember: c.members.some(m => m.userId === userId),
      memberCount: c.members.length,
    }));
    return reply.send(result);
  });

  // Get single club
  app.get("/:id", async (req, reply) => {
    const { id } = req.params as { id: string };
    const club   = clubs.find(c => c.id === id);
    if (!club) return reply.status(404).send({ error: "Clube não encontrado" });
    return reply.send(enrichClub(club));
  });

  // Create club
  app.post("/", async (req, reply) => {
    const user = resolveUser(req.headers.authorization);
    if (!user) return reply.status(401).send({ error: "Não autenticado" });

    const { name, description, type, password } = req.body as {
      name: string; description: string; type: "public"|"private"|"invite"; password?: string;
    };
    if (!name) return reply.status(400).send({ error: "Nome obrigatório" });

    const code: string = Math.random().toString(36).slice(2,8).toUpperCase();
    const club: Club = {
      id: `c${Date.now()}`, name, description: description ?? "",
      ownerId: user.id, inviteCode: code,
      type: type ?? "invite", password,
      members: [{ userId: user.id, role: "admin", points: 0, rank: 1, joinedAt: new Date().toISOString() }],
      chat: [],
      scoringRules: DEFAULT_RULES,
      createdAt: new Date().toISOString(),
    };
    clubs.push(club);
    return reply.status(201).send(enrichClub(club));
  });

  // Join club by invite code
  app.post("/join", async (req, reply) => {
    const user = resolveUser(req.headers.authorization);
    if (!user) return reply.status(401).send({ error: "Não autenticado" });

    const { inviteCode, password } = req.body as { inviteCode: string; password?: string };
    const club = clubs.find(c => c.inviteCode === inviteCode.toUpperCase());
    if (!club) return reply.status(404).send({ error: "Código inválido" });
    if (club.type === "private" && club.password !== password)
      return reply.status(403).send({ error: "Senha incorreta" });
    if (club.members.some(m => m.userId === user.id))
      return reply.status(409).send({ error: "Você já é membro" });

    club.members.push({ userId: user.id, role: "member", points: 0, rank: club.members.length + 1, joinedAt: new Date().toISOString() });
    return reply.send(enrichClub(club));
  });

  // Send chat message
  app.post("/:id/chat", async (req, reply) => {
    const user   = resolveUser(req.headers.authorization);
    if (!user) return reply.status(401).send({ error: "Não autenticado" });
    const { id } = req.params as { id: string };
    const club   = clubs.find(c => c.id === id);
    if (!club) return reply.status(404).send({ error: "Clube não encontrado" });
    if (!club.members.some(m => m.userId === user.id))
      return reply.status(403).send({ error: "Você não é membro" });

    const { content } = req.body as { content: string };
    if (!content?.trim()) return reply.status(400).send({ error: "Mensagem vazia" });

    const msg: ChatMessage = {
      id: `msg${Date.now()}`, userId: user.id,
      content: content.slice(0, 500),
      reactions: {},
      createdAt: new Date().toISOString(),
    };
    club.chat.push(msg);
    return reply.status(201).send({ ...msg, user: { displayName: user.displayName, avatarInitials: user.avatarInitials, avatarColor: user.avatarColor } });
  });

  // React to chat message
  app.post("/:id/chat/:msgId/react", async (req, reply) => {
    const { id, msgId } = req.params as { id: string; msgId: string };
    const { emoji }     = req.body as { emoji: string };
    const club = clubs.find(c => c.id === id);
    const msg  = club?.chat.find(m => m.id === msgId);
    if (!msg) return reply.status(404).send({ error: "Mensagem não encontrada" });
    msg.reactions[emoji] = (msg.reactions[emoji] ?? 0) + 1;
    return reply.send(msg.reactions);
  });
}

function enrichClub(c: Club) {
  return {
    ...c,
    members: c.members.map(m => {
      const u = users.find(u => u.id === m.userId);
      return { ...m, displayName: u?.displayName, avatarInitials: u?.avatarInitials, avatarColor: u?.avatarColor };
    }),
    chat: c.chat.map(msg => {
      const u = users.find(u => u.id === msg.userId);
      return { ...msg, user: { displayName: u?.displayName, avatarInitials: u?.avatarInitials, avatarColor: u?.avatarColor } };
    }),
  };
}

function resolveUser(auth?: string) {
  const token = auth?.startsWith("Bearer ") ? auth.slice(7) : (auth ?? "");
  return getUserFromToken(token);
}
