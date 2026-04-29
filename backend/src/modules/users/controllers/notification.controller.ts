import { FastifyInstance } from "fastify";
import { notifications, getUserFromToken } from "../../../shared/database/seed";

export async function notificationRoutes(app: FastifyInstance) {
  app.get("/", async (req, reply) => {
    const user = resolveUser(req.headers.authorization);
    if (!user) return reply.status(401).send({ error: "Não autenticado" });
    const userNotes = notifications
      .filter(n => n.userId === user.id)
      .sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());
    return reply.send(userNotes);
  });

  app.post("/read-all", async (req, reply) => {
    const user = resolveUser(req.headers.authorization);
    if (!user) return reply.status(401).send({ error: "Não autenticado" });
    notifications.filter(n => n.userId === user.id).forEach(n => { n.read = true; });
    return reply.send({ ok: true });
  });
}

function resolveUser(auth?: string) {
  const token = auth?.startsWith("Bearer ") ? auth.slice(7) : (auth ?? "");
  return getUserFromToken(token);
}
