-- Playa production core schema.
-- Apply this file to the live Supabase project used by the iOS app.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  name text,
  username text unique,
  avatar_url text,
  bio text,
  city text default 'Алматы',
  language text not null default 'ru' check (language in ('ru', 'kk', 'en')),
  onboarded boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.events (
  id uuid primary key default gen_random_uuid(),
  creator_id uuid references public.profiles(id) on delete set null,
  title text not null,
  description text,
  category text,
  location text,
  image_url text,
  starts_at timestamptz,
  price_value integer not null default 0,
  status text not null default 'published' check (status in ('draft', 'published', 'cancelled')),
  created_at timestamptz not null default now()
);

create table if not exists public.posts (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references public.profiles(id) on delete cascade,
  text text not null,
  image_url text,
  event_id uuid references public.events(id) on delete set null,
  likes_count integer not null default 0,
  comments_count integer not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.post_likes (
  post_id uuid not null references public.posts(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (post_id, user_id)
);

create table if not exists public.post_comments (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.posts(id) on delete cascade,
  author_id uuid not null references public.profiles(id) on delete cascade,
  text text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.saved_events (
  event_id uuid not null references public.events(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (event_id, user_id)
);

create table if not exists public.event_members (
  event_id uuid not null references public.events(id) on delete cascade,
  profile_id uuid not null references public.profiles(id) on delete cascade,
  role text not null default 'member',
  created_at timestamptz not null default now(),
  primary key (event_id, profile_id)
);

create table if not exists public.event_messages (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.events(id) on delete cascade,
  sender_id uuid not null references public.profiles(id) on delete cascade,
  text text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.chats (
  id uuid primary key default gen_random_uuid(),
  user1_id uuid not null references public.profiles(id) on delete cascade,
  user2_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  check (user1_id <> user2_id)
);

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  chat_id uuid not null references public.chats(id) on delete cascade,
  sender_id uuid not null references public.profiles(id) on delete cascade,
  text text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.stars_wallets (
  profile_id uuid primary key references public.profiles(id) on delete cascade,
  balance integer not null default 0 check (balance >= 0),
  updated_at timestamptz not null default now()
);

create table if not exists public.stars_transactions (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  stars integer not null,
  kind text not null check (kind in ('purchase', 'ticket', 'refund', 'adjustment')),
  event_id uuid references public.events(id) on delete set null,
  created_at timestamptz not null default now()
);

create table if not exists public.tickets (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.events(id) on delete cascade,
  profile_id uuid not null references public.profiles(id) on delete cascade,
  stars_paid integer not null default 0,
  qr_code text not null default encode(gen_random_bytes(18), 'hex'),
  created_at timestamptz not null default now(),
  unique (event_id, profile_id)
);

create table if not exists public.subscriptions (
  profile_id uuid primary key references public.profiles(id) on delete cascade,
  tier text not null default 'free' check (tier in ('free', 'plus', 'organizer')),
  status text not null default 'active' check (status in ('active', 'paused', 'cancelled')),
  renews_at timestamptz,
  updated_at timestamptz not null default now()
);

create table if not exists public.user_settings (
  profile_id uuid primary key references public.profiles(id) on delete cascade,
  language text not null default 'ru' check (language in ('ru', 'kk', 'en')),
  chat_notifications boolean not null default true,
  event_reminders boolean not null default true,
  recommendations boolean not null default true,
  updated_at timestamptz not null default now()
);

create index if not exists events_starts_at_idx on public.events(starts_at);
create index if not exists posts_created_at_idx on public.posts(created_at desc);
create index if not exists messages_chat_created_idx on public.messages(chat_id, created_at);
create index if not exists event_messages_event_created_idx on public.event_messages(event_id, created_at);

alter table public.profiles enable row level security;
alter table public.events enable row level security;
alter table public.posts enable row level security;
alter table public.post_likes enable row level security;
alter table public.post_comments enable row level security;
alter table public.saved_events enable row level security;
alter table public.event_members enable row level security;
alter table public.event_messages enable row level security;
alter table public.chats enable row level security;
alter table public.messages enable row level security;
alter table public.stars_wallets enable row level security;
alter table public.stars_transactions enable row level security;
alter table public.tickets enable row level security;
alter table public.subscriptions enable row level security;
alter table public.user_settings enable row level security;

drop policy if exists profiles_read on public.profiles;
create policy profiles_read on public.profiles for select using (true);
drop policy if exists profiles_insert_own on public.profiles;
create policy profiles_insert_own on public.profiles for insert with check (auth.uid() = id);
drop policy if exists profiles_update_own on public.profiles;
create policy profiles_update_own on public.profiles for update using (auth.uid() = id) with check (auth.uid() = id);

drop policy if exists events_read on public.events;
create policy events_read on public.events for select using (status = 'published' or creator_id = auth.uid());
drop policy if exists events_insert_own on public.events;
create policy events_insert_own on public.events for insert with check (auth.uid() = creator_id);
drop policy if exists events_update_own on public.events;
create policy events_update_own on public.events for update using (auth.uid() = creator_id) with check (auth.uid() = creator_id);

drop policy if exists posts_read on public.posts;
create policy posts_read on public.posts for select using (true);
drop policy if exists posts_insert_own on public.posts;
create policy posts_insert_own on public.posts for insert with check (auth.uid() = author_id);
drop policy if exists posts_update_own on public.posts;
create policy posts_update_own on public.posts for update using (auth.uid() = author_id) with check (auth.uid() = author_id);

drop policy if exists post_likes_read on public.post_likes;
create policy post_likes_read on public.post_likes for select using (true);
drop policy if exists post_likes_insert_own on public.post_likes;
create policy post_likes_insert_own on public.post_likes for insert with check (auth.uid() = user_id);
drop policy if exists post_likes_delete_own on public.post_likes;
create policy post_likes_delete_own on public.post_likes for delete using (auth.uid() = user_id);

drop policy if exists post_comments_read on public.post_comments;
create policy post_comments_read on public.post_comments for select using (true);
drop policy if exists post_comments_insert_own on public.post_comments;
create policy post_comments_insert_own on public.post_comments for insert with check (auth.uid() = author_id);
drop policy if exists post_comments_delete_own on public.post_comments;
create policy post_comments_delete_own on public.post_comments for delete using (auth.uid() = author_id);

drop policy if exists saved_events_own on public.saved_events;
create policy saved_events_own on public.saved_events for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists event_members_own on public.event_members;
create policy event_members_own on public.event_members for all using (auth.uid() = profile_id) with check (auth.uid() = profile_id);

drop policy if exists event_messages_members on public.event_messages;
create policy event_messages_members on public.event_messages for select using (
  exists (
    select 1 from public.event_members em
    where em.event_id = event_messages.event_id and em.profile_id = auth.uid()
  )
);
drop policy if exists event_messages_insert_own on public.event_messages;
create policy event_messages_insert_own on public.event_messages for insert with check (auth.uid() = sender_id);

drop policy if exists chats_participants on public.chats;
create policy chats_participants on public.chats for all using (auth.uid() in (user1_id, user2_id)) with check (auth.uid() in (user1_id, user2_id));

drop policy if exists messages_participants on public.messages;
create policy messages_participants on public.messages for select using (
  exists (
    select 1 from public.chats c
    where c.id = messages.chat_id and auth.uid() in (c.user1_id, c.user2_id)
  )
);
drop policy if exists messages_insert_sender on public.messages;
create policy messages_insert_sender on public.messages for insert with check (auth.uid() = sender_id);

drop policy if exists stars_wallets_own on public.stars_wallets;
create policy stars_wallets_own on public.stars_wallets for select using (auth.uid() = profile_id);
drop policy if exists stars_transactions_own on public.stars_transactions;
create policy stars_transactions_own on public.stars_transactions for select using (auth.uid() = profile_id);
drop policy if exists tickets_own on public.tickets;
create policy tickets_own on public.tickets for select using (auth.uid() = profile_id);
drop policy if exists subscriptions_own on public.subscriptions;
create policy subscriptions_own on public.subscriptions for select using (auth.uid() = profile_id);
drop policy if exists user_settings_own on public.user_settings;
create policy user_settings_own on public.user_settings for all using (auth.uid() = profile_id) with check (auth.uid() = profile_id);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public, auth
as $$
begin
  insert into public.profiles(id, email, name, username)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'full_name', split_part(coalesce(new.email, 'Playa User'), '@', 1)),
    lower(regexp_replace(split_part(coalesce(new.email, 'user-' || new.id::text), '@', 1), '[^a-zA-Z0-9_]+', '', 'g')) || '-' || left(new.id::text, 6)
  )
  on conflict (id) do nothing;

  insert into public.stars_wallets(profile_id) values (new.id) on conflict do nothing;
  insert into public.subscriptions(profile_id) values (new.id) on conflict do nothing;
  insert into public.user_settings(profile_id) values (new.id) on conflict do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

create or replace function public.delete_own_account()
returns void
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  uid uuid := auth.uid();
begin
  if uid is null then
    raise exception 'not authenticated';
  end if;

  begin delete from public.content_reports where reporter_id = uid; exception when undefined_table then null; end;
  begin delete from public.user_settings where profile_id = uid; exception when undefined_table then null; end;
  begin delete from public.subscriptions where profile_id = uid; exception when undefined_table then null; end;
  begin delete from public.tickets where profile_id = uid; exception when undefined_table then null; end;
  begin delete from public.stars_transactions where profile_id = uid; exception when undefined_table then null; end;
  begin delete from public.stars_wallets where profile_id = uid; exception when undefined_table then null; end;
  begin delete from public.messages where sender_id = uid; exception when undefined_table then null; end;
  begin delete from public.chats where user1_id = uid or user2_id = uid; exception when undefined_table then null; end;
  begin delete from public.event_messages where sender_id = uid; exception when undefined_table then null; end;
  begin delete from public.event_members where profile_id = uid; exception when undefined_table then null; end;
  begin delete from public.saved_events where user_id = uid; exception when undefined_table then null; end;
  begin delete from public.post_comments where author_id = uid; exception when undefined_table then null; end;
  begin delete from public.post_likes where user_id = uid; exception when undefined_table then null; end;
  begin delete from public.posts where author_id = uid; exception when undefined_table then null; end;
  begin delete from public.events where creator_id = uid; exception when undefined_table then null; end;
  begin delete from public.profiles where id = uid; exception when undefined_table then null; end;

  delete from auth.users where id = uid;
end;
$$;

grant execute on function public.delete_own_account() to authenticated;
