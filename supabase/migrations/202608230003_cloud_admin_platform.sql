-- Ngelamar Cloud Platform
-- Profiles, optional cloud backup, remote config, private analytics, feedback,
-- in-app notification inbox, referral/template scaffolding, and admin audit.
-- Run after 202608230001 and 202608230002.

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  email text,
  avatar_url text,
  is_onboarding_complete boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.user_preferences (
  user_id uuid primary key references auth.users(id) on delete cascade,
  payload jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

create table if not exists public.cloud_backups (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  object_path text not null unique,
  bytes bigint not null check (bytes > 0 and bytes <= 104857600),
  app_version text not null,
  created_at timestamptz not null default now()
);

create index if not exists cloud_backups_user_created_idx
  on public.cloud_backups (user_id, created_at desc);

create table if not exists public.user_documents (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  kind text not null check (kind in ('cv')),
  object_path text not null unique,
  file_name text not null,
  bytes bigint not null check (bytes > 0 and bytes <= 20971520),
  updated_at timestamptz not null default now(),
  unique (user_id, kind)
);

create table if not exists public.career_templates (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  kind text not null check (kind in ('follow_up', 'interview_note', 'cover_letter')),
  title text not null check (char_length(title) between 1 and 80),
  body text not null check (char_length(body) between 1 and 5000),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.app_events (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null check (name ~ '^[a-z0-9_]{1,64}$'),
  properties jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists app_events_name_created_idx
  on public.app_events (name, created_at desc);
create index if not exists app_events_user_created_idx
  on public.app_events (user_id, created_at desc);

create table if not exists public.remote_config (
  key text primary key check (key ~ '^[a-z0-9_]{1,80}$'),
  value jsonb not null,
  description text,
  is_enabled boolean not null default true,
  updated_at timestamptz not null default now(),
  updated_by uuid references auth.users(id) on delete set null
);

insert into public.remote_config (key, value, description)
values
  ('app_announcement', '{"enabled":false,"title":"","message":"","action_url":""}'::jsonb, 'Pengumuman yang tampil di aplikasi'),
  ('minimum_supported_version', '{"version":"2.20.0","store_url":""}'::jsonb, 'Versi minimum aplikasi yang disarankan'),
  ('portal_catalog', '{"enabled":true}'::jsonb, 'Flag katalog portal bawaan aplikasi')
on conflict (key) do nothing;

create table if not exists public.user_feedback (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  category text not null check (category in ('feedback', 'bug', 'feature_request', 'support')),
  message text not null check (char_length(message) between 5 and 3000),
  app_version text,
  device_context jsonb not null default '{}'::jsonb,
  status text not null default 'new' check (status in ('new', 'reviewing', 'resolved', 'closed')),
  admin_note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists user_feedback_status_created_idx
  on public.user_feedback (status, created_at desc);

create table if not exists public.notification_inbox (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  title text not null check (char_length(title) between 1 and 120),
  body text not null check (char_length(body) between 1 and 1000),
  type text not null default 'announcement' check (type in ('announcement', 'reminder', 'pro', 'system')),
  action_url text,
  created_at timestamptz not null default now(),
  expires_at timestamptz
);

create index if not exists notification_inbox_user_created_idx
  on public.notification_inbox (user_id, created_at desc);

create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  role text not null default 'admin' check (role in ('admin', 'owner')),
  created_at timestamptz not null default now()
);

create table if not exists public.admin_audit_logs (
  id bigint generated always as identity primary key,
  actor_id uuid references auth.users(id) on delete set null,
  action text not null,
  target_type text not null,
  target_id text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.referral_codes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  code text not null unique check (code ~ '^[A-Z0-9]{6,16}$'),
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.referral_redemptions (
  id uuid primary key default gen_random_uuid(),
  referral_code_id uuid not null references public.referral_codes(id) on delete cascade,
  referee_id uuid not null unique references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at before update on public.profiles
for each row execute function public.set_updated_at();
drop trigger if exists user_preferences_set_updated_at on public.user_preferences;
create trigger user_preferences_set_updated_at before update on public.user_preferences
for each row execute function public.set_updated_at();
drop trigger if exists career_templates_set_updated_at on public.career_templates;
create trigger career_templates_set_updated_at before update on public.career_templates
for each row execute function public.set_updated_at();
drop trigger if exists remote_config_set_updated_at on public.remote_config;
create trigger remote_config_set_updated_at before update on public.remote_config
for each row execute function public.set_updated_at();
drop trigger if exists user_feedback_set_updated_at on public.user_feedback;
create trigger user_feedback_set_updated_at before update on public.user_feedback
for each row execute function public.set_updated_at();
drop trigger if exists user_documents_set_updated_at on public.user_documents;
create trigger user_documents_set_updated_at before update on public.user_documents
for each row execute function public.set_updated_at();

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, display_name, email, avatar_url)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', new.raw_user_meta_data ->> 'name'),
    new.email,
    new.raw_user_meta_data ->> 'avatar_url'
  ) on conflict (id) do update
  set display_name = coalesce(public.profiles.display_name, excluded.display_name),
      email = coalesce(excluded.email, public.profiles.email),
      avatar_url = coalesce(public.profiles.avatar_url, excluded.avatar_url);
  return new;
end;
$$;

drop trigger if exists on_auth_user_created_profile on auth.users;
create trigger on_auth_user_created_profile
  after insert on auth.users
  for each row execute function public.handle_new_user();

create or replace function public.ensure_my_profile()
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'Sesi pengguna tidak valid.';
  end if;
  insert into public.profiles (id)
  values (auth.uid())
  on conflict (id) do nothing;
end;
$$;

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.admin_users where user_id = auth.uid()
  );
$$;

create or replace function public.redeem_referral(p_code text)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_code_id uuid;
begin
  if auth.uid() is null then
    raise exception 'Sesi pengguna tidak valid.';
  end if;
  select id into v_code_id
  from public.referral_codes
  where code = upper(trim(p_code)) and active = true;
  if v_code_id is null then
    return false;
  end if;
  insert into public.referral_redemptions (referral_code_id, referee_id)
  values (v_code_id, auth.uid())
  on conflict (referee_id) do nothing;
  return found;
end;
$$;

alter table public.profiles enable row level security;
alter table public.user_preferences enable row level security;
alter table public.cloud_backups enable row level security;
alter table public.user_documents enable row level security;
alter table public.career_templates enable row level security;
alter table public.app_events enable row level security;
alter table public.remote_config enable row level security;
alter table public.user_feedback enable row level security;
alter table public.notification_inbox enable row level security;
alter table public.admin_users enable row level security;
alter table public.admin_audit_logs enable row level security;
alter table public.referral_codes enable row level security;
alter table public.referral_redemptions enable row level security;

revoke all on table public.profiles, public.user_preferences, public.cloud_backups,
  public.user_documents, public.career_templates, public.app_events,
  public.remote_config, public.user_feedback, public.notification_inbox,
  public.admin_users, public.admin_audit_logs, public.referral_codes,
  public.referral_redemptions from anon;
grant select, insert, update, delete on table public.profiles, public.user_preferences,
  public.cloud_backups, public.user_documents, public.career_templates,
  public.user_feedback to authenticated;
grant insert on table public.app_events to authenticated;
grant select on table public.remote_config, public.notification_inbox,
  public.referral_codes to authenticated;
grant execute on function public.ensure_my_profile(), public.redeem_referral(text) to authenticated;
revoke all on function public.is_admin() from public, anon;
grant execute on function public.is_admin() to authenticated;

-- Service role is used only by the Vercel admin API and Edge Functions.
grant all on table public.profiles, public.user_preferences, public.cloud_backups,
  public.user_documents, public.career_templates, public.app_events,
  public.remote_config, public.user_feedback, public.notification_inbox,
  public.admin_users, public.admin_audit_logs, public.referral_codes,
  public.referral_redemptions to service_role;

create policy "Users manage own profile" on public.profiles for all to authenticated
  using ((select auth.uid()) = id) with check ((select auth.uid()) = id);
create policy "Users manage own preferences" on public.user_preferences for all to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy "Users manage own cloud backups" on public.cloud_backups for all to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy "Users manage own documents" on public.user_documents for all to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy "Users manage own templates" on public.career_templates for all to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy "Users record own private events" on public.app_events for insert to authenticated
  with check ((select auth.uid()) = user_id);
create policy "Authenticated users read enabled remote config" on public.remote_config for select to authenticated
  using (is_enabled = true);
create policy "Users create own feedback" on public.user_feedback for insert to authenticated
  with check ((select auth.uid()) = user_id);
create policy "Users read own feedback" on public.user_feedback for select to authenticated
  using ((select auth.uid()) = user_id);
create policy "Users read own or broadcast inbox" on public.notification_inbox for select to authenticated
  using (user_id is null or user_id = (select auth.uid()));
create policy "Users read own referral codes" on public.referral_codes for select to authenticated
  using ((select auth.uid()) = user_id);

-- Private Storage buckets. Object names must start with auth.uid()/.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('cloud-backups', 'cloud-backups', false, 104857600, array['application/zip']),
  ('user-documents', 'user-documents', false, 20971520, array['application/pdf'])
on conflict (id) do update
set public = false,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Users manage own cloud backups objects" on storage.objects;
create policy "Users manage own cloud backups objects" on storage.objects for all to authenticated
  using (
    bucket_id = 'cloud-backups'
    and (storage.foldername(name))[1] = (select auth.uid()::text)
  ) with check (
    bucket_id = 'cloud-backups'
    and (storage.foldername(name))[1] = (select auth.uid()::text)
  );

drop policy if exists "Users manage own documents objects" on storage.objects;
create policy "Users manage own documents objects" on storage.objects for all to authenticated
  using (
    bucket_id = 'user-documents'
    and (storage.foldername(name))[1] = (select auth.uid()::text)
  ) with check (
    bucket_id = 'user-documents'
    and (storage.foldername(name))[1] = (select auth.uid()::text)
  );

-- Bootstrap the first owner manually from SQL Editor after your Google login:
-- insert into public.admin_users (user_id, role)
-- values ('<AUTH_USER_UUID>', 'owner')
-- on conflict (user_id) do update set role = excluded.role;
