-- Android FCM registration. The raw token is required only by the server-side
-- sender; RLS prevents one user from reading or changing another user's token.
create table if not exists public.device_push_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  token text not null check (char_length(token) between 30 and 4096),
  platform text not null default 'android' check (platform in ('android')),
  enabled boolean not null default true,
  created_at timestamptz not null default now(),
  last_seen_at timestamptz not null default now(),
  unique (user_id, token)
);

create index if not exists device_push_tokens_enabled_user_idx
  on public.device_push_tokens (user_id, last_seen_at desc)
  where enabled = true;

alter table public.device_push_tokens enable row level security;

revoke all on table public.device_push_tokens from anon;
grant select, insert, update, delete on table public.device_push_tokens to authenticated;
grant all on table public.device_push_tokens to service_role;

drop policy if exists "Users manage own push tokens" on public.device_push_tokens;
create policy "Users manage own push tokens"
  on public.device_push_tokens
  for all
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);
