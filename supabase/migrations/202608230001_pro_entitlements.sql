create extension if not exists pgcrypto with schema extensions;

create table if not exists public.pro_activation_codes (
  id uuid primary key default gen_random_uuid(),
  code_hash text not null unique,
  plan text not null check (plan in ('monthly', 'yearly')),
  duration_days integer not null check (duration_days between 1 and 3650),
  valid_until timestamptz,
  max_redemptions integer not null default 1 check (max_redemptions > 0),
  redemption_count integer not null default 0 check (redemption_count >= 0),
  active boolean not null default true,
  created_at timestamptz not null default now(),
  last_redeemed_at timestamptz
);

create table if not exists public.pro_entitlements (
  user_id uuid primary key references auth.users(id) on delete cascade,
  plan text not null check (plan in ('monthly', 'yearly')),
  active boolean not null default true,
  starts_at timestamptz not null default now(),
  expires_at timestamptz not null,
  activation_code_id uuid references public.pro_activation_codes(id),
  updated_at timestamptz not null default now()
);

create table if not exists public.pro_activation_attempts (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  attempted_at timestamptz not null default now()
);

create index if not exists pro_activation_attempts_user_time_idx
  on public.pro_activation_attempts (user_id, attempted_at desc);

alter table public.pro_activation_codes enable row level security;
alter table public.pro_entitlements enable row level security;
alter table public.pro_activation_attempts enable row level security;

revoke all on table public.pro_activation_codes from anon, authenticated;
revoke all on table public.pro_entitlements from anon, authenticated;
revoke all on table public.pro_activation_attempts from anon, authenticated;
grant select on table public.pro_entitlements to authenticated;
grant all on table public.pro_activation_codes to service_role;
grant all on table public.pro_entitlements to service_role;
grant all on table public.pro_activation_attempts to service_role;

drop policy if exists "Users can read their own PRO entitlement"
  on public.pro_entitlements;
create policy "Users can read their own PRO entitlement"
  on public.pro_entitlements
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

create or replace function public.activate_pro(
  p_code text,
  p_requested_plan text
)
returns table (
  is_valid boolean,
  plan text,
  expires_at timestamptz,
  message text
)
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_code public.pro_activation_codes%rowtype;
  v_expires_at timestamptz;
begin
  if v_user_id is null then
    return query select false, null::text, null::timestamptz,
      'Sesi pengguna tidak valid.'::text;
    return;
  end if;

  if p_requested_plan not in ('monthly', 'yearly') then
    return query select false, null::text, null::timestamptz,
      'Paket aktivasi tidak valid.'::text;
    return;
  end if;

  if (
    select count(*)
    from public.pro_activation_attempts as a
    where a.user_id = v_user_id
      and a.attempted_at > now() - interval '15 minutes'
  ) >= 10 then
    return query select false, null::text, null::timestamptz,
      'Terlalu banyak percobaan. Coba lagi 15 menit lagi.'::text;
    return;
  end if;

  insert into public.pro_activation_attempts (user_id)
  values (v_user_id);

  select c.*
  into v_code
  from public.pro_activation_codes as c
  where c.code_hash = encode(
    extensions.digest(upper(trim(p_code)), 'sha256'),
    'hex'
  )
    and c.active = true
    and c.redemption_count < c.max_redemptions
    and (c.valid_until is null or c.valid_until > now())
  for update;

  if not found then
    return query select false, null::text, null::timestamptz,
      'Kode tidak valid, kedaluwarsa, atau sudah digunakan.'::text;
    return;
  end if;

  if v_code.plan <> p_requested_plan then
    return query select false, v_code.plan, null::timestamptz,
      'Kode ini dibuat untuk paket yang berbeda.'::text;
    return;
  end if;

  v_expires_at := now() + make_interval(days => v_code.duration_days);

  insert into public.pro_entitlements (
    user_id,
    plan,
    active,
    starts_at,
    expires_at,
    activation_code_id,
    updated_at
  ) values (
    v_user_id,
    v_code.plan,
    true,
    now(),
    v_expires_at,
    v_code.id,
    now()
  )
  on conflict (user_id) do update
  set plan = excluded.plan,
      active = true,
      starts_at = excluded.starts_at,
      expires_at = excluded.expires_at,
      activation_code_id = excluded.activation_code_id,
      updated_at = now();

  update public.pro_activation_codes
  set redemption_count = redemption_count + 1,
      last_redeemed_at = now(),
      active = (redemption_count + 1) < max_redemptions
  where id = v_code.id;

  return query select true, v_code.plan, v_expires_at,
    'PRO berhasil diaktifkan.'::text;
end;
$$;

revoke all on function public.activate_pro(text, text) from public, anon;
grant execute on function public.activate_pro(text, text) to authenticated;

create or replace function public.deactivate_my_pro()
returns void
language sql
security definer
set search_path = ''
as $$
  update public.pro_entitlements
  set active = false,
      updated_at = now()
  where user_id = auth.uid();
$$;

revoke all on function public.deactivate_my_pro() from public, anon;
grant execute on function public.deactivate_my_pro() to authenticated;

-- Example: create a one-time 30-day code from the SQL Editor.
-- Replace the sample value before running it.
-- insert into public.pro_activation_codes (code_hash, plan, duration_days)
-- values (
--   encode(extensions.digest(upper(trim('1234567890')), 'sha256'), 'hex'),
--   'monthly',
--   30
-- );
