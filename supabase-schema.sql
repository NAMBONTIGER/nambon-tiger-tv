-- Nambon Tiger TV backend schema for Supabase (free tier).
-- Run this in Supabase SQL Editor after creating a project.
create extension if not exists pgcrypto;

create table if not exists public.site_stats (
  id integer primary key check (id = 1),
  followers integer not null default 102 check (followers >= 0),
  updated_at timestamptz not null default now()
);
insert into public.site_stats (id, followers) values (1, 102) on conflict (id) do nothing;

create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create table if not exists public.contact_messages (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(name) between 1 and 100),
  reply_to text check (reply_to is null or char_length(reply_to) <= 160),
  message text not null check (char_length(message) between 1 and 3000),
  created_at timestamptz not null default now()
);

create table if not exists public.advertisements (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(name) between 1 and 100),
  contact text not null check (char_length(contact) between 1 and 160),
  content text not null check (char_length(content) between 1 and 2000),
  link text check (link is null or (char_length(link) <= 500 and link ~ '^https://')),
  package text not null check (package in ('Sponsored post','Shoutout','Post + shoutout')),
  status text not null default 'pending' check (status in ('pending','approved','rejected')),
  created_at timestamptz not null default now()
);

alter table public.site_stats enable row level security;
alter table public.admin_users enable row level security;
alter table public.contact_messages enable row level security;
alter table public.advertisements enable row level security;

drop policy if exists "public can read follower count" on public.site_stats;
create policy "public can read follower count" on public.site_stats for select to anon, authenticated using (true);
drop policy if exists "owner can update follower count" on public.site_stats;
create policy "owner can update follower count" on public.site_stats for update to authenticated using (exists (select 1 from public.admin_users a where a.user_id = auth.uid())) with check (exists (select 1 from public.admin_users a where a.user_id = auth.uid()));
drop policy if exists "owner can insert follower count" on public.site_stats;
create policy "owner can insert follower count" on public.site_stats for insert to authenticated with check (id = 1 and exists (select 1 from public.admin_users a where a.user_id = auth.uid()));

drop policy if exists "owner can see own admin role" on public.admin_users;
create policy "owner can see own admin role" on public.admin_users for select to authenticated using (user_id = auth.uid());

-- Anyone may submit. No public read/update/delete policy exists for messages.
drop policy if exists "public can submit contact messages" on public.contact_messages;
create policy "public can submit contact messages" on public.contact_messages for insert to anon, authenticated with check (true);
drop policy if exists "owner can read contact messages" on public.contact_messages;
create policy "owner can read contact messages" on public.contact_messages for select to authenticated using (exists (select 1 from public.admin_users a where a.user_id = auth.uid()));

drop policy if exists "public can read approved ads" on public.advertisements;
create policy "public can read approved ads" on public.advertisements for select to anon, authenticated using (status = 'approved' or exists (select 1 from public.admin_users a where a.user_id = auth.uid()));
drop policy if exists "public can submit pending ads" on public.advertisements;
create policy "public can submit pending ads" on public.advertisements for insert to anon, authenticated with check (status = 'pending');
drop policy if exists "owner can update ad status" on public.advertisements;
create policy "owner can update ad status" on public.advertisements for update to authenticated using (exists (select 1 from public.admin_users a where a.user_id = auth.uid())) with check (exists (select 1 from public.admin_users a where a.user_id = auth.uid()));

grant select on public.site_stats to anon, authenticated;
grant insert, update on public.site_stats to authenticated;
grant select on public.admin_users to authenticated;
grant insert on public.contact_messages to anon, authenticated;
grant select on public.contact_messages to authenticated;
grant select, insert, update on public.advertisements to anon, authenticated;

-- Owner setup after applying this file:
-- 1. Create the owner's user in Supabase Authentication > Users (disable public sign-ups).
-- 2. Copy that user's UUID and run:
--    insert into public.admin_users (user_id) values ('OWNER_AUTH_USER_UUID');
-- 3. Add the site's project URL and publishable/anon key in README setup instructions.
-- Never put a service_role key in this public GitHub Pages repository.
