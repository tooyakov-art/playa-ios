-- Playa build 14 release hardening.
-- Apply after 003_playa_core_schema.sql and 002_content_reports.sql.

create table if not exists public.blocked_users (
  blocker_id uuid not null references public.profiles(id) on delete cascade,
  blocked_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id),
  check (blocker_id <> blocked_id)
);

alter table public.blocked_users enable row level security;

revoke all on public.profiles from anon, authenticated;
grant select (id, name, username, avatar_url, bio, city, language, onboarded, created_at, updated_at)
  on public.profiles to anon, authenticated;
grant insert (id, email, name, username, avatar_url, bio, city, language, onboarded)
  on public.profiles to authenticated;
grant update (name, username, avatar_url, bio, city, language, onboarded, updated_at)
  on public.profiles to authenticated;

grant select on public.events, public.posts, public.post_comments to anon, authenticated;
grant insert, update on public.events to authenticated;
grant insert, update, delete on public.posts to authenticated;
grant insert, delete on public.post_likes to authenticated;
grant select, insert, delete on public.post_likes to authenticated;
grant select, insert, delete on public.saved_events to authenticated;
grant select, insert, delete on public.event_members to authenticated;
grant select, insert on public.event_messages to authenticated;
grant select, insert on public.chats to authenticated;
grant select, insert on public.messages to authenticated;
grant select on public.stars_wallets, public.stars_transactions, public.tickets, public.subscriptions to authenticated;
grant select, insert, update on public.user_settings to authenticated;

revoke all on public.content_reports from anon;
grant insert on public.content_reports to authenticated;

grant select, insert, delete on public.blocked_users to authenticated;

drop policy if exists blocked_users_own_select on public.blocked_users;
create policy blocked_users_own_select on public.blocked_users
  for select to authenticated using (auth.uid() = blocker_id);

drop policy if exists blocked_users_insert_own on public.blocked_users;
create policy blocked_users_insert_own on public.blocked_users
  for insert to authenticated with check (auth.uid() = blocker_id);

drop policy if exists blocked_users_delete_own on public.blocked_users;
create policy blocked_users_delete_own on public.blocked_users
  for delete to authenticated using (auth.uid() = blocker_id);

drop policy if exists event_messages_insert_own on public.event_messages;
create policy event_messages_insert_own on public.event_messages for insert to authenticated with check (
  auth.uid() = sender_id
  and exists (
    select 1 from public.event_members em
    where em.event_id = event_messages.event_id and em.profile_id = auth.uid()
  )
);

drop policy if exists messages_insert_sender on public.messages;
create policy messages_insert_sender on public.messages for insert to authenticated with check (
  auth.uid() = sender_id
  and exists (
    select 1 from public.chats c
    where c.id = messages.chat_id and auth.uid() in (c.user1_id, c.user2_id)
  )
);

drop policy if exists "content_reports_insert_own" on public.content_reports;
create policy "content_reports_insert_own" on public.content_reports
  for insert to authenticated with check (auth.uid() = reporter_id);

drop policy if exists "content_reports_read_none" on public.content_reports;
create policy "content_reports_read_none" on public.content_reports
  for select using (false);

revoke execute on function public.delete_own_account() from public, anon;
grant execute on function public.delete_own_account() to authenticated;
