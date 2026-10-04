create table if not exists public.meetings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(user_id) on delete cascade,
  title text not null,
  started_at timestamptz not null,
  ended_at timestamptz,
  status text not null default 'recording' check (status in ('recording','processing','complete','failed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists meetings_user_idx on public.meetings(user_id, started_at desc);
alter table public.meetings enable row level security;
create policy "meeting owner access" on public.meetings for all using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);

create table if not exists public.meeting_transcript_segments (
  id uuid primary key default gen_random_uuid(),
  meeting_id uuid not null references public.meetings(id) on delete cascade,
  speaker_id text,
  start_ms bigint not null,
  end_ms bigint not null,
  text text not null,
  created_at timestamptz not null default now()
);
create index if not exists meeting_segments_idx on public.meeting_transcript_segments(meeting_id, start_ms);
alter table public.meeting_transcript_segments enable row level security;
create policy "meeting segment owner access" on public.meeting_transcript_segments for all
using (exists (select 1 from public.meetings m where m.id=meeting_id and m.user_id=(select auth.uid())))
with check (exists (select 1 from public.meetings m where m.id=meeting_id and m.user_id=(select auth.uid())));

create table if not exists public.meeting_summaries (
  id uuid primary key default gen_random_uuid(),
  meeting_id uuid not null unique references public.meetings(id) on delete cascade,
  summary text not null default '',
  decisions jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.meeting_summaries enable row level security;
create policy "meeting summary owner access" on public.meeting_summaries for all
using (exists (select 1 from public.meetings m where m.id=meeting_id and m.user_id=(select auth.uid())))
with check (exists (select 1 from public.meetings m where m.id=meeting_id and m.user_id=(select auth.uid())));

create table if not exists public.meeting_action_items (
  id uuid primary key default gen_random_uuid(),
  meeting_id uuid not null references public.meetings(id) on delete cascade,
  task text not null,
  owner text,
  due_at timestamptz,
  evidence_segment_ids jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.meeting_action_items enable row level security;
create policy "meeting action owner access" on public.meeting_action_items for all
using (exists (select 1 from public.meetings m where m.id=meeting_id and m.user_id=(select auth.uid())))
with check (exists (select 1 from public.meetings m where m.id=meeting_id and m.user_id=(select auth.uid())));

create table if not exists public.billing_events (
  id uuid primary key default gen_random_uuid(),
  provider text not null,
  event_id text not null,
  event_type text not null,
  user_id uuid references public.profiles(user_id) on delete set null,
  payload jsonb not null default '{}'::jsonb,
  processed_at timestamptz,
  created_at timestamptz not null default now(),
  unique(provider,event_id)
);
alter table public.billing_events enable row level security;
create policy "billing event owner read" on public.billing_events for select using ((select auth.uid()) = user_id);
revoke insert, update, delete on public.billing_events from authenticated;
