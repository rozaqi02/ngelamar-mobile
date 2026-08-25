-- Security and delivery hardening. Run after 202608230003_cloud_admin_platform.sql.

-- A user can reserve at most ten AI requests per UTC day. The reservation is
-- atomic, so concurrent Edge Function calls cannot all pass a stale count.
create table if not exists public.ai_request_quotas (
  user_id uuid not null references auth.users(id) on delete cascade,
  quota_day date not null,
  request_count integer not null default 0 check (request_count between 0 and 10),
  primary key (user_id, quota_day)
);

alter table public.ai_request_quotas enable row level security;
revoke all on table public.ai_request_quotas from anon, authenticated;
grant all on table public.ai_request_quotas to service_role;

create or replace function public.claim_ai_request_slot()
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'Sesi pengguna tidak valid.';
  end if;

  insert into public.ai_request_quotas (user_id, quota_day, request_count)
  values (auth.uid(), current_date, 1)
  on conflict (user_id, quota_day) do update
  set request_count = public.ai_request_quotas.request_count + 1
  where public.ai_request_quotas.request_count < 10;

  return found;
end;
$$;

revoke all on function public.claim_ai_request_slot() from public, anon;
grant execute on function public.claim_ai_request_slot() to authenticated;

-- A weekly digest needs a stable delivery key, otherwise cron retries create
-- duplicate messages for every active user.
alter table public.notification_inbox
  add column if not exists delivery_key text;

create unique index if not exists notification_inbox_user_delivery_key_idx
  on public.notification_inbox (user_id, delivery_key);

-- Limit JSON supplied by untrusted clients through PostgREST as well as the app.
alter table public.user_feedback
  drop constraint if exists user_feedback_device_context_size;
alter table public.user_feedback
  add constraint user_feedback_device_context_size
  check (octet_length(device_context::text) <= 4096);
