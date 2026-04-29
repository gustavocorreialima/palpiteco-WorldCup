-- =============================================================================
-- PREMIUM PREDICTOR — DATABASE SCHEMA
-- PostgreSQL 15+  |  Clean Architecture  |  Optimized for real-time rankings
-- =============================================================================

-- ---------------------------------------------------------------------------
-- EXTENSIONS
-- ---------------------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";     -- fuzzy search on team names
CREATE EXTENSION IF NOT EXISTS "btree_gist";  -- exclusion constraints on schedules

-- ---------------------------------------------------------------------------
-- ENUMS
-- ---------------------------------------------------------------------------
CREATE TYPE user_status        AS ENUM ('active', 'suspended', 'pending_verification');
CREATE TYPE match_status       AS ENUM ('scheduled', 'live', 'finished', 'postponed', 'cancelled');
CREATE TYPE bet_status         AS ENUM ('pending', 'won', 'lost', 'void');
CREATE TYPE group_visibility   AS ENUM ('public', 'private', 'invite_only');
CREATE TYPE badge_category     AS ENUM ('accuracy', 'streak', 'social', 'milestone', 'seasonal');
CREATE TYPE data_source        AS ENUM ('sportmonks', 'api_football', 'manual', 'crowdsource');
CREATE TYPE report_status      AS ENUM ('open', 'investigating', 'resolved', 'rejected');

-- =============================================================================
-- CORE ENTITIES
-- =============================================================================

-- ---------------------------------------------------------------------------
-- USERS
-- ---------------------------------------------------------------------------
CREATE TABLE users (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username            VARCHAR(30)  NOT NULL UNIQUE,
    email               VARCHAR(255) NOT NULL UNIQUE,
    password_hash       TEXT         NOT NULL,
    avatar_url          TEXT,
    display_name        VARCHAR(60),
    bio                 VARCHAR(160),
    status              user_status  NOT NULL DEFAULT 'pending_verification',
    -- Gamification
    total_points        INTEGER      NOT NULL DEFAULT 0,
    level               SMALLINT     NOT NULL DEFAULT 1,
    xp                  INTEGER      NOT NULL DEFAULT 0,
    streak_current      SMALLINT     NOT NULL DEFAULT 0,
    streak_best         SMALLINT     NOT NULL DEFAULT 0,
    -- Accuracy metrics (denormalised for fast ranking queries)
    bets_total          INTEGER      NOT NULL DEFAULT 0,
    bets_correct        INTEGER      NOT NULL DEFAULT 0,
    bets_exact_score    INTEGER      NOT NULL DEFAULT 0,
    accuracy_pct        NUMERIC(5,2) NOT NULL DEFAULT 0.00,
    -- Timestamps
    created_at          TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    last_seen_at        TIMESTAMPTZ
);

CREATE INDEX idx_users_points     ON users (total_points DESC);
CREATE INDEX idx_users_accuracy   ON users (accuracy_pct DESC);
CREATE INDEX idx_users_username   ON users USING gin (username gin_trgm_ops);

-- ---------------------------------------------------------------------------
-- COMPETITIONS  (leagues / cups)
-- ---------------------------------------------------------------------------
CREATE TABLE competitions (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    external_id     INTEGER      UNIQUE,              -- Sportmonks / API-Football ID
    name            VARCHAR(100) NOT NULL,
    short_name      VARCHAR(20),
    logo_url        TEXT,
    country_code    CHAR(2),
    season_year     SMALLINT     NOT NULL,
    is_active       BOOLEAN      NOT NULL DEFAULT TRUE,
    data_source     data_source  NOT NULL DEFAULT 'api_football',
    synced_at       TIMESTAMPTZ,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_competitions_active ON competitions (is_active) WHERE is_active = TRUE;

-- ---------------------------------------------------------------------------
-- TEAMS
-- ---------------------------------------------------------------------------
CREATE TABLE teams (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    external_id     INTEGER      UNIQUE,
    name            VARCHAR(100) NOT NULL,
    short_name      VARCHAR(20),
    logo_url        TEXT,
    country_code    CHAR(2),
    venue_name      VARCHAR(100),
    data_source     data_source  NOT NULL DEFAULT 'api_football',
    synced_at       TIMESTAMPTZ,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_teams_name ON teams USING gin (name gin_trgm_ops);

-- ---------------------------------------------------------------------------
-- MATCHES
-- ---------------------------------------------------------------------------
CREATE TABLE matches (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    external_id         INTEGER      UNIQUE,
    competition_id      UUID         NOT NULL REFERENCES competitions(id),
    home_team_id        UUID         NOT NULL REFERENCES teams(id),
    away_team_id        UUID         NOT NULL REFERENCES teams(id),
    round               VARCHAR(30),
    kickoff_at          TIMESTAMPTZ  NOT NULL,
    status              match_status NOT NULL DEFAULT 'scheduled',
    -- Scores (NULL until played)
    home_score_ft       SMALLINT,
    away_score_ft       SMALLINT,
    home_score_ht       SMALLINT,
    away_score_ht       SMALLINT,
    -- Metadata for Expert Panel
    venue_name          VARCHAR(100),
    referee_name        VARCHAR(80),
    -- Data integrity
    data_source         data_source  NOT NULL DEFAULT 'api_football',
    data_version        INTEGER      NOT NULL DEFAULT 1,   -- bump on each sync
    synced_at           TIMESTAMPTZ,
    created_at          TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ  NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_teams_differ CHECK (home_team_id <> away_team_id)
);

CREATE INDEX idx_matches_kickoff    ON matches (kickoff_at);
CREATE INDEX idx_matches_status     ON matches (status);
CREATE INDEX idx_matches_comp       ON matches (competition_id, kickoff_at DESC);
CREATE INDEX idx_matches_live       ON matches (status) WHERE status = 'live';

-- ---------------------------------------------------------------------------
-- HEAD-TO-HEAD STATS  (pre-computed, refreshed by data pipeline)
-- ---------------------------------------------------------------------------
CREATE TABLE head_to_head_stats (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    team_a_id       UUID         NOT NULL REFERENCES teams(id),
    team_b_id       UUID         NOT NULL REFERENCES teams(id),
    last_n_matches  SMALLINT     NOT NULL DEFAULT 10,
    team_a_wins     SMALLINT     NOT NULL DEFAULT 0,
    draws           SMALLINT     NOT NULL DEFAULT 0,
    team_b_wins     SMALLINT     NOT NULL DEFAULT 0,
    team_a_goals    SMALLINT     NOT NULL DEFAULT 0,
    team_b_goals    SMALLINT     NOT NULL DEFAULT 0,
    computed_at     TIMESTAMPTZ  NOT NULL DEFAULT NOW(),

    UNIQUE (team_a_id, team_b_id, last_n_matches)
);

-- =============================================================================
-- BETTING SYSTEM
-- =============================================================================

-- ---------------------------------------------------------------------------
-- BETS
-- ---------------------------------------------------------------------------
CREATE TABLE bets (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id             UUID         NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    match_id            UUID         NOT NULL REFERENCES matches(id),
    group_id            UUID,                                        -- FK added after groups table
    -- Prediction
    predicted_home      SMALLINT     NOT NULL,
    predicted_away      SMALLINT     NOT NULL,
    -- Result
    status              bet_status   NOT NULL DEFAULT 'pending',
    points_awarded      SMALLINT,
    -- Scoring breakdown
    is_exact_score      BOOLEAN,
    is_correct_outcome  BOOLEAN,
    is_correct_goals    BOOLEAN,
    -- Timing
    submitted_at        TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    locked_at           TIMESTAMPTZ,                                 -- set when match goes live
    updated_at          TIMESTAMPTZ  NOT NULL DEFAULT NOW(),

    UNIQUE (user_id, match_id, group_id)
);

CREATE INDEX idx_bets_user      ON bets (user_id, submitted_at DESC);
CREATE INDEX idx_bets_match     ON bets (match_id, status);
CREATE INDEX idx_bets_pending   ON bets (status) WHERE status = 'pending';

-- =============================================================================
-- GROUPS / BOLÕES
-- =============================================================================

CREATE TABLE groups (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name            VARCHAR(80)      NOT NULL,
    description     VARCHAR(300),
    avatar_url      TEXT,
    invite_code     VARCHAR(12)      NOT NULL UNIQUE DEFAULT upper(substr(md5(random()::text), 1, 8)),
    owner_id        UUID             NOT NULL REFERENCES users(id),
    visibility      group_visibility NOT NULL DEFAULT 'invite_only',
    competition_id  UUID             REFERENCES competitions(id),
    max_members     SMALLINT         NOT NULL DEFAULT 50,
    -- Scoring rules (JSONB for flexibility without schema churn)
    scoring_rules   JSONB            NOT NULL DEFAULT '{
        "exact_score": 10,
        "correct_outcome": 5,
        "correct_goals_home": 2,
        "correct_goals_away": 2
    }'::jsonb,
    is_active       BOOLEAN          NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ      NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ      NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_groups_owner      ON groups (owner_id);
CREATE INDEX idx_groups_invite     ON groups (invite_code);
CREATE INDEX idx_groups_active     ON groups (is_active) WHERE is_active = TRUE;

-- Now add the FK from bets to groups
ALTER TABLE bets ADD CONSTRAINT fk_bets_group
    FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE SET NULL;

-- ---------------------------------------------------------------------------
-- GROUP MEMBERSHIPS
-- ---------------------------------------------------------------------------
CREATE TABLE group_members (
    group_id        UUID        NOT NULL REFERENCES groups(id)  ON DELETE CASCADE,
    user_id         UUID        NOT NULL REFERENCES users(id)   ON DELETE CASCADE,
    joined_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    is_admin        BOOLEAN     NOT NULL DEFAULT FALSE,
    -- Denormalised per-group score (updated by trigger)
    group_points    INTEGER     NOT NULL DEFAULT 0,
    group_rank      INTEGER,

    PRIMARY KEY (group_id, user_id)
);

CREATE INDEX idx_group_members_user ON group_members (user_id);
CREATE INDEX idx_group_members_rank ON group_members (group_id, group_points DESC);

-- =============================================================================
-- GAMIFICATION
-- =============================================================================

-- ---------------------------------------------------------------------------
-- BADGES CATALOGUE
-- ---------------------------------------------------------------------------
CREATE TABLE badges (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    slug            VARCHAR(50)    NOT NULL UNIQUE,
    name            VARCHAR(60)    NOT NULL,
    description     VARCHAR(200),
    icon_url        TEXT,
    category        badge_category NOT NULL,
    -- Unlock condition stored as JSONB rule evaluated server-side
    unlock_rule     JSONB          NOT NULL DEFAULT '{}'::jsonb,
    xp_reward       SMALLINT       NOT NULL DEFAULT 0,
    is_active       BOOLEAN        NOT NULL DEFAULT TRUE
);

-- ---------------------------------------------------------------------------
-- USER BADGES
-- ---------------------------------------------------------------------------
CREATE TABLE user_badges (
    user_id         UUID        NOT NULL REFERENCES users(id)   ON DELETE CASCADE,
    badge_id        UUID        NOT NULL REFERENCES badges(id),
    awarded_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    notified        BOOLEAN     NOT NULL DEFAULT FALSE,

    PRIMARY KEY (user_id, badge_id)
);

-- ---------------------------------------------------------------------------
-- DAILY / FLASH CHALLENGES
-- ---------------------------------------------------------------------------
CREATE TABLE challenges (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title           VARCHAR(100) NOT NULL,
    description     VARCHAR(300),
    starts_at       TIMESTAMPTZ  NOT NULL,
    ends_at         TIMESTAMPTZ  NOT NULL,
    xp_reward       SMALLINT     NOT NULL DEFAULT 50,
    -- Rule evaluated server-side (e.g. {"type": "bet_n_matches", "n": 3})
    completion_rule JSONB        NOT NULL DEFAULT '{}'::jsonb,
    is_active       BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE user_challenges (
    user_id         UUID        NOT NULL REFERENCES users(id)  ON DELETE CASCADE,
    challenge_id    UUID        NOT NULL REFERENCES challenges(id),
    progress        JSONB       NOT NULL DEFAULT '{}'::jsonb,
    completed_at    TIMESTAMPTZ,
    rewarded        BOOLEAN     NOT NULL DEFAULT FALSE,

    PRIMARY KEY (user_id, challenge_id)
);

-- =============================================================================
-- SOCIAL
-- =============================================================================

-- ---------------------------------------------------------------------------
-- FRIENDSHIPS
-- ---------------------------------------------------------------------------
CREATE TABLE friendships (
    requester_id    UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    addressee_id    UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    accepted_at     TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    PRIMARY KEY (requester_id, addressee_id),
    CONSTRAINT chk_no_self_friend CHECK (requester_id <> addressee_id)
);

-- ---------------------------------------------------------------------------
-- GROUP CHAT MESSAGES
-- ---------------------------------------------------------------------------
CREATE TABLE messages (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    group_id        UUID        NOT NULL REFERENCES groups(id)  ON DELETE CASCADE,
    user_id         UUID        NOT NULL REFERENCES users(id)   ON DELETE SET NULL,
    content         TEXT        NOT NULL CHECK (char_length(content) <= 500),
    -- Emoji reactions stored as {emoji: count}
    reactions       JSONB       NOT NULL DEFAULT '{}'::jsonb,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    edited_at       TIMESTAMPTZ,
    deleted_at      TIMESTAMPTZ
);

CREATE INDEX idx_messages_group ON messages (group_id, created_at DESC);

-- =============================================================================
-- DATA INTEGRITY / CROWDSOURCE PIPELINE
-- =============================================================================

CREATE TABLE data_reports (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reporter_id     UUID        NOT NULL REFERENCES users(id),
    match_id        UUID        NOT NULL REFERENCES matches(id),
    field_name      VARCHAR(50) NOT NULL,   -- e.g. 'home_score_ft', 'kickoff_at'
    reported_value  TEXT        NOT NULL,
    current_value   TEXT,
    reason          VARCHAR(300),
    status          report_status NOT NULL DEFAULT 'open',
    resolved_by     UUID        REFERENCES users(id),
    resolved_at     TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_reports_open  ON data_reports (status) WHERE status = 'open';
CREATE INDEX idx_reports_match ON data_reports (match_id);

-- =============================================================================
-- NOTIFICATIONS
-- =============================================================================

CREATE TABLE notifications (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type            VARCHAR(40) NOT NULL,   -- 'bet_result', 'badge_earned', 'friend_request', etc.
    payload         JSONB       NOT NULL DEFAULT '{}'::jsonb,
    read_at         TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_notifications_user_unread ON notifications (user_id, created_at DESC)
    WHERE read_at IS NULL;

-- =============================================================================
-- AUDIT / EVENT LOG  (append-only, partitioned by month)
-- =============================================================================

CREATE TABLE audit_log (
    id              BIGSERIAL,
    entity_type     VARCHAR(40)  NOT NULL,
    entity_id       UUID         NOT NULL,
    action          VARCHAR(30)  NOT NULL,  -- 'INSERT', 'UPDATE', 'DELETE'
    actor_id        UUID,
    old_data        JSONB,
    new_data        JSONB,
    ip_address      INET,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW()
) PARTITION BY RANGE (created_at);

CREATE TABLE audit_log_2026_01 PARTITION OF audit_log
    FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');
CREATE TABLE audit_log_2026_02 PARTITION OF audit_log
    FOR VALUES FROM ('2026-02-01') TO ('2026-03-01');
CREATE TABLE audit_log_2026_03 PARTITION OF audit_log
    FOR VALUES FROM ('2026-03-01') TO ('2026-04-01');
CREATE TABLE audit_log_2026_04 PARTITION OF audit_log
    FOR VALUES FROM ('2026-04-01') TO ('2026-05-01');
CREATE TABLE audit_log_2026_05 PARTITION OF audit_log
    FOR VALUES FROM ('2026-05-01') TO ('2026-06-01');
CREATE TABLE audit_log_2026_06 PARTITION OF audit_log
    FOR VALUES FROM ('2026-06-01') TO ('2026-07-01');

-- =============================================================================
-- TRIGGERS — updated_at auto-maintenance
-- =============================================================================

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END;
$$;

CREATE TRIGGER trg_users_updated_at
    BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_matches_updated_at
    BEFORE UPDATE ON matches FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_bets_updated_at
    BEFORE UPDATE ON bets FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_groups_updated_at
    BEFORE UPDATE ON groups FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- =============================================================================
-- VIEWS — pre-joined for common API queries
-- =============================================================================

CREATE VIEW v_match_card AS
SELECT
    m.id,
    m.kickoff_at,
    m.status,
    m.home_score_ft,
    m.away_score_ft,
    m.round,
    ht.id          AS home_team_id,
    ht.name        AS home_team_name,
    ht.short_name  AS home_team_short,
    ht.logo_url    AS home_team_logo,
    at.id          AS away_team_id,
    at.name        AS away_team_name,
    at.short_name  AS away_team_short,
    at.logo_url    AS away_team_logo,
    c.id           AS competition_id,
    c.name         AS competition_name,
    c.logo_url     AS competition_logo,
    h2h.team_a_wins,
    h2h.draws,
    h2h.team_b_wins,
    h2h.team_a_goals,
    h2h.team_b_goals
FROM matches m
JOIN teams ht          ON ht.id = m.home_team_id
JOIN teams at          ON at.id = m.away_team_id
JOIN competitions c    ON c.id  = m.competition_id
LEFT JOIN head_to_head_stats h2h
    ON (h2h.team_a_id = m.home_team_id AND h2h.team_b_id = m.away_team_id)
    OR (h2h.team_a_id = m.away_team_id AND h2h.team_b_id = m.home_team_id);

CREATE VIEW v_global_ranking AS
SELECT
    id,
    username,
    display_name,
    avatar_url,
    level,
    total_points,
    bets_total,
    accuracy_pct,
    streak_current,
    RANK() OVER (ORDER BY total_points DESC, accuracy_pct DESC) AS global_rank
FROM users
WHERE status = 'active';
