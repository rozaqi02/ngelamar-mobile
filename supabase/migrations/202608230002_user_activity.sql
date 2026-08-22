-- Tracks unique anonymous/authenticated installations that open the app.
-- The app cannot read or write this table directly; it can only update the
-- timestamp associated with its own auth.uid() through mark_user_active().

create table if not exists public.user_activity (
  user_id uuid primary key references auth.users(id) on delete cascade,
  first_seen_at timestamptz not null default now(),
  last_seen_at timestamptz not null default now()
);

create index if not exists user_activity_last_seen_at_idx
  on public.user_activity (last_seen_at desc);

alter table public.user_activity enable row level security;

revoke all on table public.user_activity from anon, authenticated;
grant all on table public.user_activity to service_role;

create or replace function public.mark_user_active()
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'Sesi pengguna tidak valid.';
  end if;

  insert into public.user_activity (user_id, first_seen_at, last_seen_at)
  values (auth.uid(), now(), now())
  on conflict (user_id) do update
  set last_seen_at = excluded.last_seen_at;
end;
$$;

revoke all on function public.mark_user_active() from public, anon;
grant execute on function public.mark_user_active() to authenticated;

-- Run these analytics queries manually from SQL Editor (dashboard/admin only):
-- select count(*) as total_pengguna from public.user_activity;
-- select count(*) as pengguna_aktif_24_jam
-- from public.user_activity
-- where last_seen_at > now() - interval '24 hours';
