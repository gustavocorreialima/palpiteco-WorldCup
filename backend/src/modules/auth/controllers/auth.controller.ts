import { FastifyInstance } from "fastify";
import { users, createSession, getUserFromToken, sessions } from "../../../shared/database/seed";

export async function authRoutes(app: FastifyInstance) {
  // Login
  app.post("/login", async (req, reply) => {
    const { email, password } = req.body as { email: string; password: string };
    const user = users.find(u => u.email === email);

    // Mock: any non-empty password works for demo accounts
    if (!user || !password) {
      return reply.status(401).send({ error: "Email ou senha incorretos" });
    }
    const token = createSession(user.id);
    return reply.send({ token, user: sanitize(user) });
  });

  // Register
  app.post("/register", async (req, reply) => {
    const { username, email, displayName, password } = req.body as {
      username: string; email: string; displayName: string; password: string;
    };
    if (!username || !email || !password || !displayName) {
      return reply.status(400).send({ error: "Todos os campos são obrigatórios" });
    }
    if (users.find(u => u.email === email)) {
      return reply.status(409).send({ error: "Email já cadastrado" });
    }
    if (users.find(u => u.username === username)) {
      return reply.status(409).send({ error: "Username já em uso" });
    }
    const initials = displayName.split(" ").map((w: string) => w[0]).join("").slice(0, 2).toUpperCase();
    const colors   = ["#2ECC71","#3498DB","#9B59B6","#E74C3C","#F39C12","#1ABC9C"];
    const newUser  = {
      id: `u${Date.now()}`, username, displayName, email,
      passwordHash: "$2b$10$demo",
      avatarInitials: initials,
      avatarColor: colors[Math.floor(Math.random() * colors.length)],
      points: 0, accuracy: 0, streak: 0, rank: users.length + 1,
      level: 1, xp: 0,
      betsTotal: 0, betsCorrect: 0, betsExact: 0,
      badges: [], rankVariation: 0,
    };
    users.push(newUser);
    const token = createSession(newUser.id);
    return reply.status(201).send({ token, user: sanitize(newUser) });
  });

  // Me (token validation)
  app.get("/me", async (req, reply) => {
    const token = extractToken(req.headers.authorization);
    const user  = getUserFromToken(token);
    if (!user) return reply.status(401).send({ error: "Sessão inválida" });
    return reply.send(sanitize(user));
  });

  // Logout
  app.post("/logout", async (req, reply) => {
    const token = extractToken(req.headers.authorization);
    sessions.delete(token);
    return reply.send({ ok: true });
  });

  // Demo login (one-click)
  app.post("/demo", async (_req, reply) => {
    const user  = users[0];
    const token = createSession(user.id);
    return reply.send({ token, user: sanitize(user) });
  });
}

function extractToken(auth?: string): string {
  return auth?.startsWith("Bearer ") ? auth.slice(7) : (auth ?? "");
}

function sanitize(u: (typeof users)[0]) {
  const { passwordHash: _ph, ...safe } = u;
  return safe;
}
