import "dotenv/config";
import Fastify from "fastify";
import cors from "@fastify/cors";
import staticFiles from "@fastify/static";
import path from "path";

import { matchRoutes }        from "./modules/matches/controllers/match.controller";
import { worldCupRoutes }     from "./modules/matches/controllers/worldcup.controller";
import { betRoutes }          from "./modules/bets/controllers/bet.controller";
import { rankingRoutes }      from "./modules/rankings/controllers/ranking.controller";
import { authRoutes }         from "./modules/auth/controllers/auth.controller";
import { groupRoutes }        from "./modules/groups/controllers/group.controller";
import { notificationRoutes } from "./modules/users/controllers/notification.controller";
import { seedDatabase }       from "./shared/database/seed";

const app = Fastify({ logger: { level: "warn" } });

async function bootstrap() {
  await app.register(cors, { origin: true });

  await app.register(staticFiles, {
    root: path.join(__dirname, "..", "public"),
    prefix: "/",
  });

  await app.register(authRoutes,         { prefix: "/api/auth"          });
  await app.register(matchRoutes,        { prefix: "/api/matches"        });
  await app.register(worldCupRoutes,     { prefix: "/api/worldcup"       });
  await app.register(betRoutes,          { prefix: "/api/bets"           });
  await app.register(rankingRoutes,      { prefix: "/api/rankings"       });
  await app.register(groupRoutes,        { prefix: "/api/clubs"          });
  await app.register(notificationRoutes, { prefix: "/api/notifications"  });

  await seedDatabase();

  const port = Number(process.env.PORT ?? 3000);
  await app.listen({ port, host: "0.0.0.0" });
  console.log(`\n  ⚽  Premium Predictor  →  http://localhost:${port}\n`);
}

bootstrap().catch(err => { console.error(err); process.exit(1); });
