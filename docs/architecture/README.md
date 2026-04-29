# Premium Predictor — Architecture Overview

## Stack Decision Summary

| Layer | Technology | Rationale |
|---|---|---|
| API | Node.js + TypeScript (Fastify) | Native WebSocket support for live scores; strong typing; ecosystem maturity |
| Data Pipeline | Python + FastAPI + APScheduler | Best-in-class HTTP libraries (httpx/tenacity); async ETL patterns |
| Mobile | Flutter | Single codebase; 60fps animations; best haptic API |
| Database | PostgreSQL 15 | JSONB for flexible rules; partitioned audit log; window functions for rankings |
| Cache | Redis 7 (Sorted Sets) | O(log N) leaderboard at any scale; Pub/Sub for live score push |
| Infra | Docker Compose (dev) → K8s (prod) | Identical services; horizontal scaling on match-day spikes |

---

## Data Flow — Match Lifecycle

```
API-Football (external)
        │
        ▼  every 60s (live) / 15min (upcoming) / 6h (scheduled)
  [Data Pipeline — Python]
        │  RawMatch → DomainMatch (status guard + score guard)
        ▼
  PostgreSQL (matches table)
        │  NOTIFY via pg_notify OR message queue
        ▼
  [Backend API — Node.js]
        │  1. Settle pending bets for finished matches
        │  2. Award points → UPDATE users SET total_points, accuracy_pct
        │  3. ZADD to Redis Sorted Sets (global + group rankings)
        ▼
  WebSocket broadcast → Flutter clients (live score + ranking update)
```

---

## Caching Strategy

### Redis Sorted Set — Rankings

```
Key:   ranking:global:0
       ranking:group:<group_uuid>
       ranking:competition:<comp_uuid>

Score: points × 1_000_000 + round(accuracy_pct × 100)
       → Preserves tiebreaks without a second sort key
```

- **Reads** (leaderboard page, "my rank" widget): Redis only — zero DB queries
- **Writes** (bet settlement): atomic `ZADD` after each match finishes
- **Cold start / Redis flush**: `seedRanking()` bootstraps from DB in one query

### Redis Pub/Sub — Live Score Push

```
Channel:  match:live:<match_uuid>
Payload:  { homeScore, awayScore, minute, status }
```

Backend publishes on every pipeline sync; WebSocket gateway subscribes and fans out to connected clients watching that match.

### HTTP Response Cache (Nginx)

| Endpoint | Cache-Control | Rationale |
|---|---|---|
| `GET /competitions` | `max-age=3600` | Low churn |
| `GET /matches?status=scheduled` | `max-age=300` | Changes only on pipeline sync |
| `GET /matches/:id` (live) | `no-store` | Must be fresh |
| `GET /rankings/global` | `max-age=10` | Near-real-time feel |

---

## Database ERD — Entity Relationships

```
users ──< bets >── matches ──< head_to_head_stats
  │                  │
  │              competitions
  │                  │
  └──< group_members >── groups ──< messages
  │
  └──< user_badges >── badges
  └──< user_challenges >── challenges
  └── notifications
```

---

## Scoring Rules (configurable per group)

Default stored in `groups.scoring_rules` JSONB:

```json
{
  "exact_score":        10,
  "correct_outcome":     5,
  "correct_goals_home":  2,
  "correct_goals_away":  2
}
```

Maximum per match: **19 points** (exact score = outcome + both goals + exact bonus).

---

## Scalability Playbook — Match-Day Spikes

1. **Data Pipeline**: runs as a single stateless pod; APScheduler in-process.  
   Scale: add replicas only if collecting 50+ leagues simultaneously.

2. **API layer**: stateless Fastify pods behind Nginx.  
   Scale: horizontal auto-scaling on CPU > 60% (K8s HPA).

3. **WebSocket gateway**: sticky sessions via Nginx `ip_hash`.  
   Scale: Redis Pub/Sub ensures all pod instances receive the same live event.

4. **Bet settlement**: runs as a background worker triggered by a Redis queue message.  
   Scale: scale worker pods independently; idempotent by `bet.id`.

5. **DB**: read replicas for ranking queries; primary for writes only.  
   PgBouncer as connection pooler in front of both.
