-- Bound xAI ephemeral-token issuance across serverless instances.
-- The client can never read or write this table directly; it can only invoke
-- the SECURITY DEFINER function with its own authenticated Supabase JWT.

create table if not exists public.xai_voice_session_issuances (
    id bigint generated always as identity primary key,
    user_id uuid not null references auth.users(id) on delete cascade,
    issued_at timestamptz not null default now()
);

create index if not exists xai_voice_session_issuances_user_issued_at_idx
    on public.xai_voice_session_issuances (user_id, issued_at desc);

alter table public.xai_voice_session_issuances enable row level security;

revoke all on table public.xai_voice_session_issuances from anon, authenticated;

create or replace function public.reserve_xai_voice_session_issuance()
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    requesting_user_id uuid := auth.uid();
    recent_issuances integer;
begin
    if requesting_user_id is null then
        raise exception using errcode = '42501', message = 'UNAUTHENTICATED';
    end if;

    -- Serialize concurrent requests for the same user before checking the quota.
    perform pg_advisory_xact_lock(hashtextextended(requesting_user_id::text, 0));

    delete from public.xai_voice_session_issuances
    where issued_at < now() - interval '24 hours';

    select count(*)
      into recent_issuances
      from public.xai_voice_session_issuances
     where user_id = requesting_user_id
       and issued_at >= now() - interval '1 minute';

    if recent_issuances >= 6 then
        raise exception using errcode = 'P0001', message = 'RATE_LIMITED';
    end if;

    insert into public.xai_voice_session_issuances (user_id)
    values (requesting_user_id);
end;
$$;

revoke all on function public.reserve_xai_voice_session_issuance() from public, anon;
grant execute on function public.reserve_xai_voice_session_issuance() to authenticated;
