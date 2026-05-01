import { FastifyInstance } from "fastify";
import { supabase } from "../../../shared/database/supabase";

export async function notificationRoutes(app: FastifyInstance) {

  app.get("/", async (req, reply) => {
    const user = await resolveUser(req.headers.authorization);
    if (!user) return reply.status(401).send({ error: "Não autenticado" });

    const { data, error } = await supabase
      .from("notifications")
      .select("*")
      .eq("user_id", user.id)
      .order("created_at", { ascending: false })
      .limit(50);

    if (error) return reply.status(500).send({ error: error.message });

    return reply.send((data ?? []).map(n => ({
      id:        n.id,
      userId:    n.user_id,
      type:      n.type,
      title:     n.title,
      body:      n.body,
      read:      n.read,
      matchId:   n.match_id,
      createdAt: n.created_at,
    })));
  });

  app.post("/read-all", async (req, reply) => {
    const user = await resolveUser(req.headers.authorization);
    if (!user) return reply.status(401).send({ error: "Não autenticado" });

    await supabase
      .from("notifications")
      .update({ read: true })
      .eq("user_id", user.id)
      .eq("read", false);

    return reply.send({ ok: true });
  });
}

async function resolveUser(auth?: string) {
  const token = auth?.startsWith("Bearer ") ? auth.slice(7) : (auth ?? "");
  if (!token) return null;
  const { data: { user } } = await supabase.auth.getUser(token);
  return user ?? null;
}
