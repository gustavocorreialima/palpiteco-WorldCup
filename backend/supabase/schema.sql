-- ============================================================
-- BOLÃO 2026 — Supabase Schema
-- Execute this in: Supabase Dashboard → SQL Editor → New query
-- ============================================================

-- Enable UUID extension
create extension if not exists "pgcrypto";

-- ────────────────────────────────────────────
-- USERS (mirrors auth.users via trigger)
-- ────────────────────────────────────────────
create table if not exists public.users (
  id            uuid primary key default gen_random_uuid(),
  username      text unique not null,
  display_name  text not null,
  email         text unique not null,
  avatar_initials text not null default 'U',
  avatar_color    text not null default '#3A86FF',
  points        integer not null default 0,
  accuracy      numeric(5,2) not null default 0,
  streak        integer not null default 0,
  rank          integer not null default 0,
  level         integer not null default 1,
  xp            integer not null default 0,
  bets_total    integer not null default 0,
  bets_correct  integer not null default 0,
  bets_exact    integer not null default 0,
  badges        text[] not null default '{}',
  rank_variation integer not null default 0,
  created_at    timestamptz not null default now()
);

-- ────────────────────────────────────────────
-- CLUBS (grupos)
-- ────────────────────────────────────────────
create table if not exists public.clubs (
  id            uuid primary key default gen_random_uuid(),
  name          text not null,
  description   text not null default '',
  owner_id      uuid not null references public.users(id) on delete cascade,
  invite_code   text unique not null,
  type          text not null default 'invite' check (type in ('public','private','invite')),
  password      text,
  scoring_rules jsonb not null default '{
    "exactScore": 10,
    "correctOutcome": 5,
    "correctDraw": 7,
    "goalDiff": 3,
    "streakBonus": 2,
    "finalMultiplier": 2
  }',
  created_at    timestamptz not null default now()
);

-- ────────────────────────────────────────────
-- CLUB MEMBERS
-- ────────────────────────────────────────────
create table if not exists public.club_members (
  id         uuid primary key default gen_random_uuid(),
  club_id    uuid not null references public.clubs(id) on delete cascade,
  user_id    uuid not null references public.users(id) on delete cascade,
  role       text not null default 'member' check (role in ('admin','member')),
  points     integer not null default 0,
  rank       integer not null default 0,
  joined_at  timestamptz not null default now(),
  unique(club_id, user_id)
);

-- ────────────────────────────────────────────
-- CHAT MESSAGES
-- ────────────────────────────────────────────
create table if not exists public.chat_messages (
  id         uuid primary key default gen_random_uuid(),
  club_id    uuid not null references public.clubs(id) on delete cascade,
  user_id    uuid not null references public.users(id) on delete cascade,
  content    text not null check (char_length(content) <= 500),
  reactions  jsonb not null default '{}',
  created_at timestamptz not null default now()
);

-- ────────────────────────────────────────────
-- BETS (palpites)
-- ────────────────────────────────────────────
create table if not exists public.bets (
  id               uuid primary key default gen_random_uuid(),
  user_id          uuid not null references public.users(id) on delete cascade,
  match_id         text not null,
  group_id         uuid references public.clubs(id) on delete set null,
  predicted_home   integer not null check (predicted_home >= 0 and predicted_home <= 20),
  predicted_away   integer not null check (predicted_away >= 0 and predicted_away <= 20),
  points           integer,
  status           text not null default 'pending' check (status in ('pending','won','lost')),
  is_exact         boolean,
  is_correct_outcome boolean,
  submitted_at     timestamptz not null default now(),
  locked_at        timestamptz,
  unique(user_id, match_id)
);

-- ────────────────────────────────────────────
-- BET EDIT HISTORY (audit trail)
-- ────────────────────────────────────────────
create table if not exists public.bet_edits (
  id             uuid primary key default gen_random_uuid(),
  bet_id         uuid not null references public.bets(id) on delete cascade,
  predicted_home integer not null,
  predicted_away integer not null,
  edited_at      timestamptz not null default now()
);

-- ────────────────────────────────────────────
-- NOTIFICATIONS
-- ────────────────────────────────────────────
create table if not exists public.notifications (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.users(id) on delete cascade,
  type       text not null,
  title      text not null,
  body       text not null,
  read       boolean not null default false,
  match_id   text,
  created_at timestamptz not null default now()
);

-- ────────────────────────────────────────────
-- INDEXES (performance)
-- ────────────────────────────────────────────
create index if not exists idx_bets_user       on public.bets(user_id);
create index if not exists idx_bets_match      on public.bets(match_id);
create index if not exists idx_bets_status     on public.bets(status);
create index if not exists idx_club_members_club on public.club_members(club_id);
create index if not exists idx_club_members_user on public.club_members(user_id);
create index if not exists idx_chat_club       on public.chat_messages(club_id, created_at desc);
create index if not exists idx_notif_user      on public.notifications(user_id, created_at desc);
create index if not exists idx_users_points    on public.users(points desc);

-- ────────────────────────────────────────────
-- ROW LEVEL SECURITY
-- ────────────────────────────────────────────
alter table public.users          enable row level security;
alter table public.clubs          enable row level security;
alter table public.club_members   enable row level security;
alter table public.chat_messages  enable row level security;
alter table public.bets           enable row level security;
alter table public.bet_edits      enable row level security;
alter table public.notifications  enable row level security;

-- Users: anyone can read, only self can update
create policy "users_read_all"   on public.users for select using (true);
create policy "users_update_own" on public.users for update using (auth.uid() = id);
create policy "users_insert_own" on public.users for insert with check (auth.uid() = id);

-- Clubs: anyone can read public/invite clubs
create policy "clubs_read_all"   on public.clubs for select using (true);
create policy "clubs_insert_auth" on public.clubs for insert with check (auth.uid() is not null);
create policy "clubs_update_owner" on public.clubs for update using (auth.uid() = owner_id);
create policy "clubs_delete_owner" on public.clubs for delete using (auth.uid() = owner_id);

-- Club members: readable by all, insert own, delete own (leave)
create policy "members_read_all"   on public.club_members for select using (true);
create policy "members_insert_auth" on public.club_members for insert with check (auth.uid() is not null);
create policy "members_delete_own"  on public.club_members for delete using (auth.uid() = user_id);
create policy "members_update_admin" on public.club_members for update using (
  exists(select 1 from public.club_members cm where cm.club_id = club_members.club_id and cm.user_id = auth.uid() and cm.role = 'admin')
);

-- Chat: readable by members, writable by members
create policy "chat_read_members" on public.chat_messages for select using (
  exists(select 1 from public.club_members cm where cm.club_id = chat_messages.club_id and cm.user_id = auth.uid())
);
create policy "chat_insert_members" on public.chat_messages for insert with check (
  auth.uid() = user_id and
  exists(select 1 from public.club_members cm where cm.club_id = chat_messages.club_id and cm.user_id = auth.uid())
);
create policy "chat_update_reactions" on public.chat_messages for update using (
  exists(select 1 from public.club_members cm where cm.club_id = chat_messages.club_id and cm.user_id = auth.uid())
);

-- Bets: only own bets
create policy "bets_own"   on public.bets for all using (auth.uid() = user_id);
create policy "bet_edits_own" on public.bet_edits for select using (
  exists(select 1 from public.bets b where b.id = bet_edits.bet_id and b.user_id = auth.uid())
);

-- Notifications: only own
create policy "notifs_own" on public.notifications for all using (auth.uid() = user_id);

-- ────────────────────────────────────────────
-- FUNCTION: auto-create user profile on signup
-- ────────────────────────────────────────────
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  _initials text;
  _colors   text[] := array['#2ECC71','#3498DB','#9B59B6','#E74C3C','#F39C12','#1ABC9C','#E67E22','#16a34a'];
  _color    text;
  _username text;
  _display  text;
begin
  _display  := coalesce(new.raw_user_meta_data->>'display_name', split_part(new.email, '@', 1));
  _username := coalesce(new.raw_user_meta_data->>'username', split_part(new.email, '@', 1));
  _initials := upper(left(_display, 1));
  if position(' ' in _display) > 0 then
    _initials := upper(left(_display, 1) || substr(_display, position(' ' in _display)+1, 1));
  end if;
  _color := _colors[1 + floor(random() * array_length(_colors, 1))::int];

  insert into public.users (id, username, display_name, email, avatar_initials, avatar_color)
  values (new.id, _username, _display, new.email, _initials, _color)
  on conflict (id) do nothing;
  return new;
end;
$$;

-- Trigger: fires on every new Supabase Auth user
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ────────────────────────────────────────────
-- DEMO USER (optional seed)
-- Insert after running schema — only if you want a demo account
-- ────────────────────────────────────────────
-- insert into auth.users (id, email, encrypted_password, email_confirmed_at, raw_user_meta_data)
-- values (
--   '00000000-0000-0000-0000-000000000001',
--   'demo@bolao.com',
--   crypt('demo123', gen_salt('bf')),
--   now(),
--   '{"display_name":"Demo","username":"demo"}'::jsonb
-- );
