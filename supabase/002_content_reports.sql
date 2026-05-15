-- Playa iOS App Store UGC safety: user reports

create table if not exists public.content_reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references public.profiles(id) on delete cascade,
  content_type text not null check (content_type in ('post', 'comment', 'message', 'event_message', 'profile')),
  content_id text not null,
  reason text not null default 'User report',
  created_at timestamptz not null default now()
);

create index if not exists content_reports_content_idx on public.content_reports(content_type, content_id);
create index if not exists content_reports_reporter_idx on public.content_reports(reporter_id, created_at desc);

alter table public.content_reports enable row level security;

drop policy if exists "content_reports_insert_own" on public.content_reports;
create policy "content_reports_insert_own" on public.content_reports
  for insert with check (auth.uid() = reporter_id);

drop policy if exists "content_reports_read_none" on public.content_reports;
create policy "content_reports_read_none" on public.content_reports
  for select using (false);
