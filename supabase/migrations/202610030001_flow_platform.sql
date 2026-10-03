create extension if not exists pgcrypto;

create table if not exists public.user_dictionary_entries (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(user_id) on delete cascade,
  trigger text not null, replacement text, pronunciation_hint text, category text, is_enabled boolean not null default true,
  version bigint not null default 1, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create index if not exists user_dictionary_entries_user_idx on public.user_dictionary_entries(user_id, updated_at desc);
alter table public.user_dictionary_entries enable row level security;
create policy "dictionary owner access" on public.user_dictionary_entries for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create table if not exists public.user_snippets (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(user_id) on delete cascade,
  trigger text not null, expansion text not null, category text, variables jsonb not null default '[]'::jsonb,
  is_enabled boolean not null default true, version bigint not null default 1,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create index if not exists user_snippets_user_idx on public.user_snippets(user_id, updated_at desc);
alter table public.user_snippets enable row level security;
create policy "snippet owner access" on public.user_snippets for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create table if not exists public.user_styles (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(user_id) on delete cascade,
  name text not null, description text not null default '', capitalization text not null default 'preserve',
  punctuation text not null default 'standard', verbosity text not null default 'standard', tone text not null default 'neutral',
  custom_instructions text not null default '', version bigint not null default 1,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
alter table public.user_styles enable row level security;
create policy "style owner access" on public.user_styles for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create table if not exists public.device_sessions (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(user_id) on delete cascade,
  device_id text not null, platform text not null, last_seen_at timestamptz not null default now(), app_version text,
  created_at timestamptz not null default now(), unique(user_id, device_id)
);
alter table public.device_sessions enable row level security;
create policy "device session owner access" on public.device_sessions for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create table if not exists public.sync_revisions (
  id bigint generated always as identity primary key, user_id uuid not null references public.profiles(user_id) on delete cascade,
  device_id text not null, entity_type text not null, entity_id uuid not null, entity_version bigint not null,
  operation text not null check (operation in ('upsert','delete')), payload jsonb, created_at timestamptz not null default now()
);
create index if not exists sync_revisions_cursor_idx on public.sync_revisions(user_id, id);
alter table public.sync_revisions enable row level security;
create policy "sync owner access" on public.sync_revisions for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create table if not exists public.usage_records (
  id uuid primary key default gen_random_uuid(), user_id uuid references public.profiles(user_id) on delete set null,
  device_id text, operation text not null, units integer not null check (units >= 0),
  idempotency_key text not null unique, metadata jsonb not null default '{}'::jsonb, created_at timestamptz not null default now()
);
create index if not exists usage_records_user_idx on public.usage_records(user_id, created_at desc);
alter table public.usage_records enable row level security;
create policy "usage owner read" on public.usage_records for select using (auth.uid() = user_id);

create table if not exists public.entitlements (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(user_id) on delete cascade,
  key text not null, value jsonb not null, source text not null, valid_from timestamptz not null default now(),
  valid_until timestamptz, updated_at timestamptz not null default now(), unique(user_id, key)
);
create index if not exists entitlements_user_idx on public.entitlements(user_id);
alter table public.entitlements enable row level security;
create policy "entitlement owner read" on public.entitlements for select using (auth.uid() = user_id);

create table if not exists public.verification_events (
  id uuid primary key default gen_random_uuid(), user_id uuid references public.profiles(user_id) on delete set null,
  action_type text not null, expected_outcome jsonb not null, observed_state jsonb not null, passed boolean not null,
  evidence jsonb not null default '[]'::jsonb, violations jsonb not null default '[]'::jsonb,
  metadata jsonb not null default '{}'::jsonb, created_at timestamptz not null default now()
);
create index if not exists verification_events_user_idx on public.verification_events(user_id, created_at desc);
alter table public.verification_events enable row level security;
create policy "verification owner read" on public.verification_events for select using (auth.uid() = user_id);

revoke insert, update, delete on public.usage_records from authenticated;
revoke insert, update, delete on public.entitlements from authenticated;
revoke insert, update, delete on public.verification_events from authenticated;
