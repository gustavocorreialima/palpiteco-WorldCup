import { FastifyInstance } from "fastify";
import { supabase } from "../../../shared/database/supabase";
import { DEFAULT_RULES } from "../../../shared/database/seed";

export async function groupRoutes(app: FastifyInstance) {

  // List all clubs
  app.get("/", async (req, reply) => {
    const user = await resolveUser(req.headers.authorization);

    const { data: clubs, error } = await supabase
      .from("clubs")
      .select(`
        *,
        club_members(user_id, role, points, rank, joined_at,
          users(display_name, avatar_initials, avatar_color)),
        chat_messages(id, user_id, content, reactions, created_at,
          users(display_name, avatar_initials, avatar_color))
      `)
      .order("created_at", { ascending: false });

    if (error) return reply.status(500).send({ error: error.message });

    const result = (clubs ?? []).map(c => ({
      ...toClub(c),
      chat: (c.chat_messages ?? [])
        .sort((a: any, b: any) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime())
        .slice(0, 3)
        .reverse()
        .map(toMsg),
      isMember: user ? (c.club_members ?? []).some((m: any) => m.user_id === user.id) : false,
      memberCount: (c.club_members ?? []).length,
    }));

    return reply.send(result);
  });

  // Get single club
  app.get("/:id", async (req, reply) => {
    const { id } = req.params as { id: string };
    const club = await fetchClub(id);
    if (!club) return reply.status(404).send({ error: "Clube não encontrado" });
    return reply.send(club);
  });

  // Create club
  app.post("/", async (req, reply) => {
    const user = await resolveUser(req.headers.authorization);
    if (!user) return reply.status(401).send({ error: "Não autenticado" });

    const { name, description, type, password } = req.body as {
      name: string; description: string; type: "public"|"private"|"invite"; password?: string;
    };
    if (!name) return reply.status(400).send({ error: "Nome obrigatório" });

    const inviteCode = Math.random().toString(36).slice(2, 8).toUpperCase();

    const { data: club, error } = await supabase
      .from("clubs")
      .insert({
        name,
        description: description ?? "",
        owner_id: user.id,
        invite_code: inviteCode,
        type: type ?? "invite",
        password: password ?? null,
        scoring_rules: DEFAULT_RULES,
      })
      .select()
      .single();

    if (error) return reply.status(500).send({ error: error.message });

    // Add creator as admin member
    await supabase.from("club_members").insert({
      club_id: club.id,
      user_id: user.id,
      role: "admin",
      points: 0,
      rank: 1,
    });

    return reply.status(201).send(await fetchClub(club.id));
  });

  // Join by invite code
  app.post("/join", async (req, reply) => {
    const user = await resolveUser(req.headers.authorization);
    if (!user) return reply.status(401).send({ error: "Não autenticado" });

    const { inviteCode, password } = req.body as { inviteCode: string; password?: string };

    const { data: club, error } = await supabase
      .from("clubs")
      .select("*")
      .eq("invite_code", inviteCode.toUpperCase())
      .maybeSingle();

    if (error || !club) return reply.status(404).send({ error: "Código inválido" });
    if (club.type === "private" && club.password !== password)
      return reply.status(403).send({ error: "Senha incorreta" });

    const { data: existing } = await supabase
      .from("club_members")
      .select("id")
      .eq("club_id", club.id)
      .eq("user_id", user.id)
      .maybeSingle();

    if (existing) return reply.status(409).send({ error: "Você já é membro" });

    const { count } = await supabase
      .from("club_members")
      .select("*", { count: "exact", head: true })
      .eq("club_id", club.id);

    await supabase.from("club_members").insert({
      club_id: club.id,
      user_id: user.id,
      role: "member",
      points: 0,
      rank: (count ?? 0) + 1,
    });

    return reply.send(await fetchClub(club.id));
  });

  // Send chat message
  app.post("/:id/chat", async (req, reply) => {
    const user = await resolveUser(req.headers.authorization);
    if (!user) return reply.status(401).send({ error: "Não autenticado" });

    const { id } = req.params as { id: string };
    const { content } = req.body as { content: string };
    if (!content?.trim()) return reply.status(400).send({ error: "Mensagem vazia" });

    const { data: member } = await supabase
      .from("club_members")
      .select("id")
      .eq("club_id", id)
      .eq("user_id", user.id)
      .maybeSingle();
    if (!member) return reply.status(403).send({ error: "Você não é membro" });

    const { data: msg, error } = await supabase
      .from("chat_messages")
      .insert({
        club_id: id,
        user_id: user.id,
        content: content.trim().slice(0, 500),
        reactions: {},
      })
      .select("*, users(display_name, avatar_initials, avatar_color)")
      .single();

    if (error) return reply.status(500).send({ error: error.message });
    return reply.status(201).send(toMsg(msg));
  });

  // React to message
  app.post("/:id/chat/:msgId/react", async (req, reply) => {
    const { msgId } = req.params as { id: string; msgId: string };
    const { emoji } = req.body as { emoji: string };

    const { data: msg } = await supabase
      .from("chat_messages")
      .select("reactions")
      .eq("id", msgId)
      .maybeSingle();
    if (!msg) return reply.status(404).send({ error: "Mensagem não encontrada" });

    const reactions = { ...msg.reactions, [emoji]: ((msg.reactions as any)[emoji] ?? 0) + 1 };
    await supabase.from("chat_messages").update({ reactions }).eq("id", msgId);
    return reply.send(reactions);
  });

  // Leave club
  app.post("/:id/leave", async (req, reply) => {
    const user = await resolveUser(req.headers.authorization);
    if (!user) return reply.status(401).send({ error: "Não autenticado" });

    const { id } = req.params as { id: string };
    const { data: club } = await supabase.from("clubs").select("owner_id").eq("id", id).maybeSingle();
    if (!club) return reply.status(404).send({ error: "Clube não encontrado" });
    if (club.owner_id === user.id)
      return reply.status(400).send({ error: "Admin não pode sair — encerre o grupo ou transfira a propriedade" });

    await supabase.from("club_members").delete().eq("club_id", id).eq("user_id", user.id);
    return reply.send({ ok: true });
  });

  // Delete club — admin only
  app.delete("/:id", async (req, reply) => {
    const user = await resolveUser(req.headers.authorization);
    if (!user) return reply.status(401).send({ error: "Não autenticado" });

    const { id } = req.params as { id: string };
    const { data: club } = await supabase.from("clubs").select("owner_id").eq("id", id).maybeSingle();
    if (!club) return reply.status(404).send({ error: "Clube não encontrado" });
    if (club.owner_id !== user.id) return reply.status(403).send({ error: "Apenas o admin pode encerrar o grupo" });

    await supabase.from("clubs").delete().eq("id", id);
    return reply.send({ ok: true });
  });

  // Regenerate invite code — admin only
  app.post("/:id/regen-code", async (req, reply) => {
    const user = await resolveUser(req.headers.authorization);
    if (!user) return reply.status(401).send({ error: "Não autenticado" });

    const { id } = req.params as { id: string };
    const { data: club } = await supabase.from("clubs").select("owner_id").eq("id", id).maybeSingle();
    if (!club) return reply.status(404).send({ error: "Clube não encontrado" });
    if (club.owner_id !== user.id) return reply.status(403).send({ error: "Apenas o admin pode gerar novo código" });

    const inviteCode = Math.random().toString(36).slice(2, 8).toUpperCase();
    await supabase.from("clubs").update({ invite_code: inviteCode }).eq("id", id);
    return reply.send({ inviteCode });
  });
}

// ── Helpers ──

async function resolveUser(auth?: string) {
  const token = auth?.startsWith("Bearer ") ? auth.slice(7) : (auth ?? "");
  if (!token) return null;
  const { data: { user } } = await supabase.auth.getUser(token);
  if (!user) return null;
  return user;
}

async function fetchClub(id: string) {
  const { data, error } = await supabase
    .from("clubs")
    .select(`
      *,
      club_members(user_id, role, points, rank, joined_at,
        users(display_name, avatar_initials, avatar_color)),
      chat_messages(id, user_id, content, reactions, created_at,
        users(display_name, avatar_initials, avatar_color))
    `)
    .eq("id", id)
    .maybeSingle();

  if (error || !data) return null;
  return toClub(data);
}

function toClub(c: any) {
  return {
    id:          c.id,
    name:        c.name,
    description: c.description,
    ownerId:     c.owner_id,
    inviteCode:  c.invite_code,
    type:        c.type,
    createdAt:   c.created_at,
    scoringRules: c.scoring_rules,
    members: (c.club_members ?? []).map((m: any) => ({
      userId:      m.user_id,
      role:        m.role,
      points:      m.points,
      rank:        m.rank,
      joinedAt:    m.joined_at,
      displayName: m.users?.display_name,
      avatarInitials: m.users?.avatar_initials,
      avatarColor: m.users?.avatar_color,
    })),
    chat: (c.chat_messages ?? [])
      .sort((a: any, b: any) => new Date(a.created_at).getTime() - new Date(b.created_at).getTime())
      .map(toMsg),
  };
}

function toMsg(m: any) {
  return {
    id:        m.id,
    userId:    m.user_id,
    content:   m.content,
    reactions: m.reactions ?? {},
    createdAt: m.created_at,
    user: {
      displayName:    m.users?.display_name,
      avatarInitials: m.users?.avatar_initials,
      avatarColor:    m.users?.avatar_color,
    },
  };
}
