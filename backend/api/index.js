"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.default = handler;
const fastify_1 = __importDefault(require("fastify"));
const cors_1 = __importDefault(require("@fastify/cors"));
const match_controller_1 = require("../src/modules/matches/controllers/match.controller");
const worldcup_controller_1 = require("../src/modules/matches/controllers/worldcup.controller");
const bet_controller_1 = require("../src/modules/bets/controllers/bet.controller");
const ranking_controller_1 = require("../src/modules/rankings/controllers/ranking.controller");
const auth_controller_1 = require("../src/modules/auth/controllers/auth.controller");
const group_controller_1 = require("../src/modules/groups/controllers/group.controller");
const notification_controller_1 = require("../src/modules/users/controllers/notification.controller");
const seed_1 = require("../src/shared/database/seed");
const app = (0, fastify_1.default)({ logger: false });
let ready = false;
async function build() {
    if (ready)
        return app;
    await app.register(cors_1.default, { origin: true });
    await app.register(auth_controller_1.authRoutes, { prefix: "/api/auth" });
    await app.register(match_controller_1.matchRoutes, { prefix: "/api/matches" });
    await app.register(worldcup_controller_1.worldCupRoutes, { prefix: "/api/worldcup" });
    await app.register(bet_controller_1.betRoutes, { prefix: "/api/bets" });
    await app.register(ranking_controller_1.rankingRoutes, { prefix: "/api/rankings" });
    await app.register(group_controller_1.groupRoutes, { prefix: "/api/clubs" });
    await app.register(notification_controller_1.notificationRoutes, { prefix: "/api/notifications" });
    await (0, seed_1.seedDatabase)();
    await app.ready();
    ready = true;
    return app;
}
async function handler(req, res) {
    const instance = await build();
    instance.server.emit("request", req, res);
}
