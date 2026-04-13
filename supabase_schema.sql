-- ============================================================================
-- Focus Fighters — Supabase schema (ff_ tables)
-- Run this in a NEW Supabase project via SQL Editor.
-- Requires: Auth → Anonymous Sign-Ins enabled, Realtime enabled on public.
-- ============================================================================

-- ---------- EXTENSIONS ------------------------------------------------------
create extension if not exists "pgcrypto";

-- ============================================================================
-- ff_profiles
-- ============================================================================
create table if not exists public.ff_profiles (
  id            uuid primary key references auth.users(id) on delete cascade,
  display_name  text not null default 'Warrior',
  avatar_emoji  text default '🧙',
  photo_url     text,
  email         text,
  is_guest      boolean not null default false,
  xp            integer not null default 0,
  coins         integer not null default 0,
  level         integer not null default 1,
  xp_to_next    integer not null default 100,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);
create index if not exists ff_profiles_email_idx on public.ff_profiles (lower(email));

-- ============================================================================
-- ff_rooms
-- ============================================================================
create table if not exists public.ff_rooms (
  id          uuid primary key default gen_random_uuid(),
  code        text unique not null,
  name        text not null default 'Study Session',
  host_id     uuid not null references public.ff_profiles(id) on delete cascade,
  boss        text default '🐲',
  duration    integer not null default 25,
  status      text not null default 'waiting' check (status in ('waiting','active','finished')),
  started_at  timestamptz,
  created_at  timestamptz not null default now()
);
create index if not exists ff_rooms_host_idx on public.ff_rooms (host_id);
create index if not exists ff_rooms_code_idx on public.ff_rooms (code);

-- ============================================================================
-- ff_room_members
-- ============================================================================
create table if not exists public.ff_room_members (
  id            uuid primary key default gen_random_uuid(),
  room_id       uuid not null references public.ff_rooms(id) on delete cascade,
  user_id       uuid not null references public.ff_profiles(id) on delete cascade,
  display_name  text not null default 'Warrior',
  avatar_emoji  text default '🧙',
  photo_url     text,
  device        text default 'desktop',
  status        text not null default 'focused',
  joined_at     timestamptz not null default now(),
  unique (room_id, user_id)
);
create index if not exists ff_room_members_room_idx on public.ff_room_members (room_id);
create index if not exists ff_room_members_user_idx on public.ff_room_members (user_id);

-- ============================================================================
-- ff_friends
-- ============================================================================
create table if not exists public.ff_friends (
  id            uuid primary key default gen_random_uuid(),
  requester_id  uuid not null references public.ff_profiles(id) on delete cascade,
  addressee_id  uuid not null references public.ff_profiles(id) on delete cascade,
  status        text not null default 'pending' check (status in ('pending','accepted','blocked')),
  created_at    timestamptz not null default now(),
  check (requester_id <> addressee_id),
  unique (requester_id, addressee_id)
);
create index if not exists ff_friends_req_idx on public.ff_friends (requester_id);
create index if not exists ff_friends_addr_idx on public.ff_friends (addressee_id);

-- ============================================================================
-- ff_invites
-- ============================================================================
create table if not exists public.ff_invites (
  id          uuid primary key default gen_random_uuid(),
  room_id     uuid not null references public.ff_rooms(id) on delete cascade,
  from_id     uuid not null references public.ff_profiles(id) on delete cascade,
  to_id       uuid not null references public.ff_profiles(id) on delete cascade,
  room_code   text not null,
  room_name   text,
  status      text not null default 'pending' check (status in ('pending','accepted','declined')),
  created_at  timestamptz not null default now()
);
create index if not exists ff_invites_to_idx   on public.ff_invites (to_id, status);
create index if not exists ff_invites_from_idx on public.ff_invites (from_id);
create index if not exists ff_invites_room_idx on public.ff_invites (room_id);

-- ============================================================================
-- REALTIME — add tables to the supabase_realtime publication
-- ============================================================================
do $$
begin
  if not exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    create publication supabase_realtime;
  end if;
end$$;

alter publication supabase_realtime add table public.ff_rooms;
alter publication supabase_realtime add table public.ff_room_members;
alter publication supabase_realtime add table public.ff_friends;
alter publication supabase_realtime add table public.ff_invites;

alter table public.ff_rooms         replica identity full;
alter table public.ff_room_members  replica identity full;
alter table public.ff_friends       replica identity full;
alter table public.ff_invites       replica identity full;

-- ============================================================================
-- ROW LEVEL SECURITY
-- ============================================================================
alter table public.ff_profiles     enable row level security;
alter table public.ff_rooms        enable row level security;
alter table public.ff_room_members enable row level security;
alter table public.ff_friends      enable row level security;
alter table public.ff_invites      enable row level security;

-- ---------- ff_profiles -----------------------------------------------------
-- Anyone signed in can read profiles (needed for friend search, room member
-- hydration, invite sender cards). Writes restricted to the owning user.
drop policy if exists "ff_profiles_select_all"   on public.ff_profiles;
drop policy if exists "ff_profiles_insert_self"  on public.ff_profiles;
drop policy if exists "ff_profiles_update_self"  on public.ff_profiles;
drop policy if exists "ff_profiles_delete_self"  on public.ff_profiles;

create policy "ff_profiles_select_all"
  on public.ff_profiles for select
  to authenticated
  using (true);

create policy "ff_profiles_insert_self"
  on public.ff_profiles for insert
  to authenticated
  with check (auth.uid() = id);

create policy "ff_profiles_update_self"
  on public.ff_profiles for update
  to authenticated
  using (auth.uid() = id)
  with check (auth.uid() = id);

create policy "ff_profiles_delete_self"
  on public.ff_profiles for delete
  to authenticated
  using (auth.uid() = id);

-- ---------- ff_rooms --------------------------------------------------------
drop policy if exists "ff_rooms_select_all"    on public.ff_rooms;
drop policy if exists "ff_rooms_insert_host"   on public.ff_rooms;
drop policy if exists "ff_rooms_update_host"   on public.ff_rooms;
drop policy if exists "ff_rooms_delete_host"   on public.ff_rooms;

create policy "ff_rooms_select_all"
  on public.ff_rooms for select
  to authenticated
  using (true);

create policy "ff_rooms_insert_host"
  on public.ff_rooms for insert
  to authenticated
  with check (auth.uid() = host_id);

create policy "ff_rooms_update_host"
  on public.ff_rooms for update
  to authenticated
  using (auth.uid() = host_id)
  with check (auth.uid() = host_id);

create policy "ff_rooms_delete_host"
  on public.ff_rooms for delete
  to authenticated
  using (auth.uid() = host_id);

-- ---------- ff_room_members -------------------------------------------------
-- Any signed-in user can see members (joiners need to list everyone in their
-- room). Users can only insert/update/delete their OWN membership row.
drop policy if exists "ff_room_members_select_all"  on public.ff_room_members;
drop policy if exists "ff_room_members_insert_self" on public.ff_room_members;
drop policy if exists "ff_room_members_update_self" on public.ff_room_members;
drop policy if exists "ff_room_members_delete_self" on public.ff_room_members;

create policy "ff_room_members_select_all"
  on public.ff_room_members for select
  to authenticated
  using (true);

create policy "ff_room_members_insert_self"
  on public.ff_room_members for insert
  to authenticated
  with check (auth.uid() = user_id);

create policy "ff_room_members_update_self"
  on public.ff_room_members for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "ff_room_members_delete_self"
  on public.ff_room_members for delete
  to authenticated
  using (
    auth.uid() = user_id
    or exists (
      select 1 from public.ff_rooms r
      where r.id = room_id and r.host_id = auth.uid()
    )
  );

-- ---------- ff_friends ------------------------------------------------------
drop policy if exists "ff_friends_select_involved" on public.ff_friends;
drop policy if exists "ff_friends_insert_self"    on public.ff_friends;
drop policy if exists "ff_friends_update_involved" on public.ff_friends;
drop policy if exists "ff_friends_delete_involved" on public.ff_friends;

create policy "ff_friends_select_involved"
  on public.ff_friends for select
  to authenticated
  using (auth.uid() = requester_id or auth.uid() = addressee_id);

create policy "ff_friends_insert_self"
  on public.ff_friends for insert
  to authenticated
  with check (auth.uid() = requester_id);

create policy "ff_friends_update_involved"
  on public.ff_friends for update
  to authenticated
  using (auth.uid() = requester_id or auth.uid() = addressee_id)
  with check (auth.uid() = requester_id or auth.uid() = addressee_id);

create policy "ff_friends_delete_involved"
  on public.ff_friends for delete
  to authenticated
  using (auth.uid() = requester_id or auth.uid() = addressee_id);

-- ---------- ff_invites ------------------------------------------------------
drop policy if exists "ff_invites_select_involved" on public.ff_invites;
drop policy if exists "ff_invites_insert_from"     on public.ff_invites;
drop policy if exists "ff_invites_update_involved" on public.ff_invites;
drop policy if exists "ff_invites_delete_involved" on public.ff_invites;

create policy "ff_invites_select_involved"
  on public.ff_invites for select
  to authenticated
  using (auth.uid() = from_id or auth.uid() = to_id);

create policy "ff_invites_insert_from"
  on public.ff_invites for insert
  to authenticated
  with check (auth.uid() = from_id);

create policy "ff_invites_update_involved"
  on public.ff_invites for update
  to authenticated
  using (auth.uid() = from_id or auth.uid() = to_id)
  with check (auth.uid() = from_id or auth.uid() = to_id);

create policy "ff_invites_delete_involved"
  on public.ff_invites for delete
  to authenticated
  using (auth.uid() = from_id or auth.uid() = to_id);

-- ============================================================================
-- STORAGE — avatars bucket (used by uploadAvatar in AuthContext.jsx)
-- ============================================================================
insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do nothing;

drop policy if exists "avatars_read_public"    on storage.objects;
drop policy if exists "avatars_write_own"      on storage.objects;
drop policy if exists "avatars_update_own"     on storage.objects;
drop policy if exists "avatars_delete_own"     on storage.objects;

create policy "avatars_read_public"
  on storage.objects for select
  using (bucket_id = 'avatars');

create policy "avatars_write_own"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "avatars_update_own"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "avatars_delete_own"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
