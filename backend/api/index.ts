import Fastify from "fastify";
import cors from "@fastify/cors";
import { IncomingMessage, ServerResponse } from "http";

import { matchRoutes }        from "../src/modules/matches/controllers/match.controller";
import { worldCupRoutes }     from "../src/modules/matches/controllers/worldcup.controller";
import { betRoutes }          from "../src/modules/bets/controllers/bet.controller";
import { rankingRoutes }      from "../src/modules/rankings/controllers/ranking.controller";
import { authRoutes }         from "../src/modules/auth/controllers/auth.controller";
import { groupRoutes }        from "../src/modules/groups/controllers/group.controller";
import { notificationRoutes } from "../src/modules/users/controllers/notification.controller";
import { seedDatabase }       from "../src/shared/database/seed";

const app = Fastify({ logger: false });

let ready = false;

async function build() {
  if (ready) return app;

  await app.register(cors, { origin: true });

  await app.register(authRoutes,         { prefix: "/api/auth"         });
  await app.register(matchRoutes,        { prefix: "/api/matches"       });
  await app.register(worldCupRoutes,     { prefix: "/api/worldcup"      });
  await app.register(betRoutes,          { prefix: "/api/bets"          });
  await app.register(rankingRoutes,      { prefix: "/api/rankings"      });
  await app.register(groupRoutes,        { prefix: "/api/clubs"         });
  await app.register(notificationRoutes, { prefix: "/api/notifications" });

  await seedDatabase();
  await app.ready();

  ready = true;
  return app;
}

export default async function handler(req: IncomingMessage, res: ServerResponse) {
  const instance = await build();
  instance.server.emit("request", req, res);
}
