import { FastifyInstance } from "fastify";
import { supabase } from "../../../shared/database/supabase";

export async function authRoutes(app: FastifyInstance) {

  // Login
  app.post("/login", async (req, reply) => {
    const { email, password } = req.body as { email: string; password: string };
    if (!email || !password)
      return reply.status(400).send({ error: "Email e senha são obrigatórios" });

    const { data, error } = await supabase.auth.signInWithPassword({ email, password });
    if (error || !data.user)
      return reply.status(401).send({ error: "Email ou senha incorretos" });

    const profile = await getProfile(data.user.id);
    if (!profile) return reply.status(500).send({ error: "Perfil não encontrado" });

    return reply.send({ token: data.session.access_token, user: profile });
  });

  // Register
  app.post("/register", async (req, reply) => {
    const { username, email, displayName, password } = req.body as {
      username: string; email: string; displayName: string; password: string;
    };
    if (!username || !email || !password || !displayName)
      return reply.status(400).send({ error: "Todos os campos são obrigatórios" });
    if (password.length < 6)
      return reply.status(400).send({ error: "Senha deve ter pelo menos 6 caracteres" });

    // Check username uniqueness first
    const { data: existing } = await supabase
      .from("users").select("id").eq("username", username).maybeSingle();
    if (existing) return reply.status(409).send({ error: "Username já em uso" });

    const { data, error } = await supabase.auth.signUp({
      email, password,
      options: { data: { display_name: displayName, username } },
    });
    if (error) {
      if (error.message.includes("already registered"))
        return reply.status(409).send({ error: "Email já cadastrado" });
      return reply.status(400).send({ error: error.message });
    }
    if (!data.user) return reply.status(500).send({ error: "Erro ao criar conta" });

    // Profile is created by DB trigger — wait a moment then fetch
    await new Promise(r => setTimeout(r, 300));
    const profile = await getProfile(data.user.id);

    return reply.status(201).send({
      token: data.session?.access_token ?? "",
      user: profile,
    });
  });

  // Me (validate token)
  app.get("/me", async (req, reply) => {
    const token = extractToken(req.headers.authorization);
    if (!token) return reply.status(401).send({ error: "Token ausente" });

    const { data: { user }, error } = await supabase.auth.getUser(token);
    if (error || !user) return reply.status(401).send({ error: "Sessão inválida" });

    const profile = await getProfile(user.id);
    if (!profile) return reply.status(404).send({ error: "Perfil não encontrado" });
    return reply.send(profile);
  });

  // Logout
  app.post("/logout", async (req, reply) => {
    const token = extractToken(req.headers.authorization);
    if (token) await supabase.auth.admin.signOut(token).catch(() => {});
    return reply.send({ ok: true });
  });

  // Demo login
  app.post("/demo", async (_req, reply) => {
    const email = process.env.DEMO_EMAIL ?? "demo@bolao.com";
    const pass  = process.env.DEMO_PASSWORD ?? "demo123456";

    const { data, error } = await supabase.auth.signInWithPassword({ email, password: pass });
    if (error || !data.user) {
      // Try to create demo account if it doesn't exist
      const { data: reg } = await supabase.auth.signUp({
        email, password: pass,
        options: { data: { display_name: "Demo", username: "demo" } },
      });
      if (reg?.session) {
        await new Promise(r => setTimeout(r, 300));
        const profile = await getProfile(reg.user!.id);
        return reply.send({ token: reg.session.access_token, user: profile });
      }
      return reply.status(500).send({ error: "Conta demo não disponível" });
    }
    const profile = await getProfile(data.user.id);
    return reply.send({ token: data.session.access_token, user: profile });
  });
}

async function getProfile(userId: string) {
  const { data } = await supabase
    .from("users")
    .select("*")
    .eq("id", userId)
    .maybeSingle();
  if (!data) return null;
  return {
    id:              data.id,
    username:        data.username,
    displayName:     data.display_name,
    email:           data.email,
    avatarInitials:  data.avatar_initials,
    avatarColor:     data.avatar_color,
    points:          data.points,
    accuracy:        data.accuracy,
    streak:          data.streak,
    rank:            data.rank,
    level:           data.level,
    xp:              data.xp,
    betsTotal:       data.bets_total,
    betsCorrect:     data.bets_correct,
    betsExact:       data.bets_exact,
    badges:          data.badges,
    rankVariation:   data.rank_variation,
  };
}

function extractToken(auth?: string): string {
  return auth?.startsWith("Bearer ") ? auth.slice(7) : (auth ?? "");
}
