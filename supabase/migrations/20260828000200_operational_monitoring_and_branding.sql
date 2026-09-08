-- Operational monitoring, user problem reports, and safe brand controls.
-- This migration is additive. It does not change gameplay authority or scoring.

alter table public.media_assets
  drop constraint if exists media_assets_asset_group_check,
  drop constraint if exists media_assets_path_format;

alter table public.media_assets
  add constraint media_assets_asset_group_check check (
    asset_group in (
      'app-content', 'categories', 'store', 'achievements', 'promotions',
      'onboarding', 'branding', 'app-icons'
    )
  ),
  add constraint media_assets_path_format check (
    storage_path ~ '^(app-content|categories|store|achievements|promotions|onboarding|branding|app-icons)/[a-zA-Z0-9][a-zA-Z0-9/_-]*\.(jpg|jpeg|png|webp)$'
    and storage_path !~ '(^|/)\.\.(/|$)'
  );

drop policy if exists app_content_staff_insert on storage.objects;
drop policy if exists app_content_staff_update on storage.objects;

create policy app_content_staff_insert on storage.objects
for insert to authenticated with check (
  bucket_id = 'app-content'
  and public.has_role('moderator')
  and (storage.foldername(name))[1] in (
    'app-content', 'categories', 'store', 'achievements', 'promotions',
    'onboarding', 'branding', 'app-icons'
  )
);

create policy app_content_staff_update on storage.objects
for update to authenticated using (
  bucket_id = 'app-content' and public.has_role('moderator')
) with check (
  bucket_id = 'app-content'
  and public.has_role('moderator')
  and (storage.foldername(name))[1] in (
    'app-content', 'categories', 'store', 'achievements', 'promotions',
    'onboarding', 'branding', 'app-icons'
  )
);

insert into public.app_content(
  key, section, content_type, label_ar, usage_ar, default_text_ar,
  draft_text_ar, published_text_ar, min_length, max_length, published_at
)
values
  ('branding.logo.primary', 'branding', 'image', 'الشعار الرئيسي', 'الشعار الأساسي داخل التطبيق', null, null, null, 0, 1, now()),
  ('branding.logo.light', 'branding', 'image', 'شعار الخلفيات الفاتحة', 'نسخة الشعار المناسبة للأسطح الفاتحة', null, null, null, 0, 1, now()),
  ('branding.logo.dark', 'branding', 'image', 'شعار الخلفيات الداكنة', 'نسخة الشعار المناسبة للأسطح الداكنة', null, null, null, 0, 1, now()),
  ('branding.logo.mark', 'branding', 'image', 'الشعار المصغر', 'رمز أحدعش في المساحات الصغيرة', null, null, null, 0, 1, now()),
  ('branding.splash.artwork', 'branding', 'image', 'صورة شاشة البداية', 'العمل البصري لشاشة Splash بعد إصدار التطبيق', null, null, null, 0, 1, now()),
  ('branding.login.artwork', 'branding', 'image', 'صورة تسجيل الدخول', 'العمل البصري في شاشة الدخول', null, null, null, 0, 1, now()),
  ('branding.placeholder.default', 'branding', 'image', 'الصورة البديلة العامة', 'Fallback آمن عند تعذر تحميل صورة', null, null, null, 0, 1, now()),
  ('branding.category.fallback', 'branding', 'image', 'صورة التصنيفات البديلة', 'Fallback للتصنيفات التي لا تملك غلافًا', null, null, null, 0, 1, now()),
  ('branding.store.artwork', 'branding', 'image', 'صورة المتجر', 'العمل البصري الافتراضي للمتجر', null, null, null, 0, 1, now()),
  ('branding.premium.artwork', 'branding', 'image', 'صورة Premium', 'العمل البصري الافتراضي لقسم Premium', null, null, null, 0, 1, now()),
  ('branding.appicon.master', 'app_icon', 'image', 'أيقونة التطبيق المصدرية', 'مصدر 1024×1024 للإصدار القادم؛ لا يغيّر الأيقونة المثبتة عن بعد', null, null, null, 0, 1, now()),
  ('promotions.home.image', 'promotions', 'image', 'صورة ترويج الصفحة الرئيسية', 'الصورة الاختيارية للعرض الترويجي في الرئيسية', null, null, null, 0, 1, now()),
  ('promotions.seasonal.image', 'promotions', 'image', 'صورة الحملة الموسمية', 'صورة حملة موسمية غير مرتبطة بحقوق أندية أو لاعبين', null, null, null, 0, 1, now()),
  ('appearance.accent.color', 'appearance', 'text', 'لون التمييز الترويجي', 'لون Hex آمن للأسطح الترويجية فقط؛ النظام الأساسي يبقى داخل التطبيق', '#78B814', '#78B814', '#78B814', 7, 7, now()),
  ('feature.home.promotion', 'feature_controls', 'text', 'عرض الترويج في الرئيسية', 'إظهار أو إخفاء البطاقة الترويجية فقط', 'false', 'false', 'false', 4, 5, now()),
  ('feature.home.seasonal', 'feature_controls', 'text', 'عرض الحملة الموسمية', 'إظهار أو إخفاء الحملة الموسمية فقط', 'false', 'false', 'false', 4, 5, now()),
  ('feature.premium.promotion', 'feature_controls', 'text', 'عرض ترويج Premium', 'إظهار العرض الترويجي دون تغيير الاستحقاقات', 'true', 'true', 'true', 4, 5, now()),
  ('feature.rewarded.cta', 'feature_controls', 'text', 'عرض دعوة الإعلان بمكافأة', 'إظهار الدعوة فقط؛ منح العملات يبقى Server-authoritative', 'false', 'false', 'false', 4, 5, now()),
  ('feature.home.featured', 'feature_controls', 'text', 'عرض التصنيف المميز', 'إظهار قسم اختيار اليوم في الرئيسية', 'true', 'true', 'true', 4, 5, now())
on conflict (key) do nothing;

create or replace function public.validate_managed_app_content_value()
returns trigger
language plpgsql
set search_path = pg_catalog, public
as $$
declare
  candidate text;
begin
  if new.section = 'feature_controls' then
    foreach candidate in array array[new.default_text_ar, new.draft_text_ar, new.published_text_ar]
    loop
      if candidate is not null and candidate not in ('true', 'false') then
        raise exception using errcode = '23514', message = 'Feature controls accept boolean text only';
      end if;
    end loop;
  end if;

  if new.key = 'appearance.accent.color' then
    foreach candidate in array array[new.default_text_ar, new.draft_text_ar, new.published_text_ar]
    loop
      if candidate is not null and candidate !~ '^#[0-9A-Fa-f]{6}$' then
        raise exception using errcode = '23514', message = 'Accent color must be a six-digit hex color';
      end if;
    end loop;
  end if;

  return new;
end;
$$;

create trigger app_content_validate_managed_values
before insert or update of default_text_ar, draft_text_ar, published_text_ar, section
on public.app_content
for each row execute function public.validate_managed_app_content_value();

create table public.app_error_issues (
  id uuid primary key default gen_random_uuid(),
  fingerprint text not null unique check (fingerprint ~ '^[0-9a-f]{64}$'),
  severity text not null check (severity in ('info', 'warning', 'error', 'critical')),
  category text not null check (category in (
    'startup', 'api', 'supabase', 'content', 'matchmaking', 'room', 'wallet',
    'notification', 'image', 'purchase', 'auth', 'offline_sync', 'unexpected_state'
  )),
  feature text not null check (char_length(feature) between 1 and 80),
  title text not null check (char_length(title) between 1 and 160),
  sanitized_message text not null check (char_length(sanitized_message) between 1 and 700),
  sanitized_stack text check (sanitized_stack is null or char_length(sanitized_stack) <= 6000),
  app_version text not null check (char_length(app_version) between 1 and 32),
  build_number text not null default '0' check (char_length(build_number) between 1 and 20),
  platform text not null check (platform in ('android', 'ios', 'web', 'unknown')),
  os_version text check (os_version is null or char_length(os_version) <= 120),
  device_model text check (device_model is null or char_length(device_model) <= 120),
  first_seen timestamptz not null default clock_timestamp(),
  last_seen timestamptz not null default clock_timestamp(),
  occurrence_count bigint not null default 1 check (occurrence_count > 0),
  affected_users_count bigint not null default 1 check (affected_users_count > 0),
  status text not null default 'open' check (status in ('open', 'resolved')),
  resolved_by uuid references public.profiles(id) on delete set null,
  resolved_at timestamptz,
  internal_note text check (internal_note is null or char_length(internal_note) <= 2000),
  updated_at timestamptz not null default now(),
  constraint app_error_issue_resolution check (
    (status = 'open' and resolved_at is null)
    or (status = 'resolved' and resolved_at is not null and resolved_by is not null)
  )
);

create index app_error_issues_queue_idx
  on public.app_error_issues(status, severity, last_seen desc);
create index app_error_issues_version_idx
  on public.app_error_issues(app_version, platform, last_seen desc);
create index app_error_issues_category_idx
  on public.app_error_issues(category, feature, last_seen desc);

create table public.app_error_occurrences (
  id bigint generated always as identity primary key,
  issue_id uuid not null references public.app_error_issues(id) on delete cascade,
  user_id uuid references public.profiles(id) on delete set null,
  session_hash text check (session_hash is null or session_hash ~ '^[0-9a-f]{64}$'),
  screen text check (screen is null or char_length(screen) <= 100),
  network_state text not null default 'unknown' check (
    network_state in ('wifi', 'mobile', 'ethernet', 'vpn', 'offline', 'other', 'unknown')
  ),
  safe_context jsonb not null default '{}'::jsonb check (pg_column_size(safe_context) <= 2048),
  app_version text not null check (char_length(app_version) between 1 and 32),
  build_number text not null default '0' check (char_length(build_number) between 1 and 20),
  platform text not null check (platform in ('android', 'ios', 'web', 'unknown')),
  occurred_at timestamptz not null default clock_timestamp()
);

create index app_error_occurrences_issue_idx
  on public.app_error_occurrences(issue_id, occurred_at desc);
create index app_error_occurrences_rate_idx
  on public.app_error_occurrences(user_id, occurred_at desc)
  where user_id is not null;

create table public.user_problem_reports (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  category text not null check (category in (
    'login', 'gameplay', 'matchmaking', 'room', 'content', 'image', 'wallet',
    'purchase', 'notification', 'performance', 'other'
  )),
  description text check (description is null or char_length(description) <= 1500),
  screen text check (screen is null or char_length(screen) <= 100),
  app_version text not null check (char_length(app_version) between 1 and 32),
  build_number text not null default '0' check (char_length(build_number) between 1 and 20),
  platform text not null check (platform in ('android', 'ios', 'web', 'unknown')),
  status text not null default 'new' check (status in ('new', 'in_review', 'resolved', 'rejected')),
  linked_issue_id uuid references public.app_error_issues(id) on delete set null,
  admin_note text check (admin_note is null or char_length(admin_note) <= 2000),
  reviewed_by uuid references public.profiles(id) on delete set null,
  reviewed_at timestamptz,
  created_at timestamptz not null default clock_timestamp(),
  updated_at timestamptz not null default now(),
  constraint user_problem_report_review check (
    status = 'new' or (reviewed_by is not null and reviewed_at is not null)
  )
);

create index user_problem_reports_queue_idx
  on public.user_problem_reports(status, created_at desc);
create index user_problem_reports_user_rate_idx
  on public.user_problem_reports(user_id, created_at desc);
create index user_problem_reports_issue_idx
  on public.user_problem_reports(linked_issue_id)
  where linked_issue_id is not null;

create trigger app_error_issues_set_updated_at before update on public.app_error_issues
for each row execute function public.set_updated_at();
create trigger user_problem_reports_set_updated_at before update on public.user_problem_reports
for each row execute function public.set_updated_at();

alter table public.app_error_issues enable row level security;
alter table public.app_error_occurrences enable row level security;
alter table public.user_problem_reports enable row level security;

create policy app_error_issues_staff_read on public.app_error_issues
for select to authenticated using (public.has_role('moderator'));
create policy app_error_occurrences_staff_read on public.app_error_occurrences
for select to authenticated using (public.has_role('moderator'));
create policy user_problem_reports_staff_read on public.user_problem_reports
for select to authenticated using (public.has_role('moderator'));

revoke all on public.app_error_issues, public.app_error_occurrences, public.user_problem_reports
from anon, authenticated;
grant select on public.app_error_issues, public.app_error_occurrences, public.user_problem_reports
to authenticated;

create or replace function public.sanitize_app_error_text(p_value text, p_max_length integer default 1000)
returns text
language plpgsql
immutable
set search_path = pg_catalog, public
as $$
declare
  sanitized text;
begin
  if p_value is null then return null; end if;
  if p_max_length not between 1 and 6000 then
    raise exception using errcode = '22023', message = 'Invalid sanitization length';
  end if;

  sanitized := left(p_value, 12000);
  sanitized := regexp_replace(sanitized, 'eyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}', '[redacted-token]', 'g');
  sanitized := regexp_replace(sanitized, '(?i)bearer[[:space:]]+[A-Za-z0-9._~+/-]{8,}={0,2}', 'Bearer [redacted]', 'g');
  sanitized := regexp_replace(sanitized, '(?i)(authorization|access_token|refresh_token|password|secret|private_key)[[:space:]]*[:=][[:space:]]*[^,;[:space:]]+', '\1=[redacted]', 'g');
  sanitized := regexp_replace(sanitized, '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}', '[redacted-email]', 'g');
  sanitized := regexp_replace(sanitized, E'[\\x01-\\x08\\x0B\\x0C\\x0E-\\x1F\\x7F]', ' ', 'g');
  sanitized := btrim(left(sanitized, p_max_length));
  return nullif(sanitized, '');
end;
$$;

create or replace function public.report_app_error(
  p_severity text,
  p_category text,
  p_feature text,
  p_message text,
  p_stack text,
  p_screen text,
  p_app_version text,
  p_build_number text,
  p_platform text,
  p_os_version text,
  p_device_model text,
  p_network_state text,
  p_session_id text,
  p_context jsonb default '{}'::jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, extensions
as $$
declare
  caller_id uuid := auth.uid();
  event_time timestamptz := clock_timestamp();
  clean_feature text;
  clean_message text;
  clean_stack text;
  clean_screen text;
  clean_os text;
  clean_device text;
  safe_context jsonb;
  stack_signature text;
  fingerprint_value text;
  target_issue public.app_error_issues%rowtype;
  already_seen boolean;
  duplicate_recent boolean;
  session_hash_value text;
begin
  if caller_id is null then
    raise exception using errcode = '42501', message = 'Authentication required';
  end if;
  if p_severity not in ('info', 'warning', 'error', 'critical')
     or p_category not in (
       'startup', 'api', 'supabase', 'content', 'matchmaking', 'room', 'wallet',
       'notification', 'image', 'purchase', 'auth', 'offline_sync', 'unexpected_state'
     )
     or p_platform not in ('android', 'ios', 'web', 'unknown') then
    raise exception using errcode = '22023', message = 'Unsupported error classification';
  end if;

  if (
    select count(*) from public.app_error_occurrences
    where user_id = caller_id and occurred_at >= event_time - interval '1 hour'
  ) >= 20 then
    raise exception using errcode = 'P0001', message = 'Error reporting rate limit reached';
  end if;

  clean_feature := public.sanitize_app_error_text(p_feature, 80);
  clean_message := public.sanitize_app_error_text(p_message, 700);
  clean_stack := public.sanitize_app_error_text(p_stack, 6000);
  clean_screen := public.sanitize_app_error_text(p_screen, 100);
  clean_os := public.sanitize_app_error_text(p_os_version, 120);
  clean_device := public.sanitize_app_error_text(p_device_model, 120);
  if clean_feature is null or clean_message is null then
    raise exception using errcode = '22023', message = 'Feature and message are required';
  end if;
  if char_length(coalesce(p_app_version, '')) not between 1 and 32
     or char_length(coalesce(p_build_number, '')) not between 1 and 20 then
    raise exception using errcode = '22023', message = 'Invalid application version';
  end if;

  safe_context := jsonb_strip_nulls(jsonb_build_object(
    'operation', public.sanitize_app_error_text(p_context ->> 'operation', 80),
    'state', public.sanitize_app_error_text(p_context ->> 'state', 80),
    'code', public.sanitize_app_error_text(p_context ->> 'code', 80)
  ));
  stack_signature := split_part(coalesce(clean_stack, ''), E'\n', 1);
  fingerprint_value := encode(extensions.digest(convert_to(
    concat_ws('|', p_category, clean_feature, clean_message, stack_signature, p_app_version, p_platform),
    'UTF8'
  ), 'sha256'), 'hex');
  session_hash_value := case when nullif(btrim(coalesce(p_session_id, '')), '') is null then null else
    encode(extensions.digest(convert_to(caller_id::text || ':' || left(p_session_id, 120), 'UTF8'), 'sha256'), 'hex')
  end;

  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(fingerprint_value, 0));
  select * into target_issue from public.app_error_issues
  where fingerprint = fingerprint_value for update;

  if found then
    select exists (
      select 1 from public.app_error_occurrences
      where issue_id = target_issue.id and user_id = caller_id
    ) into already_seen;
    select exists (
      select 1 from public.app_error_occurrences
      where issue_id = target_issue.id and user_id = caller_id
        and session_hash is not distinct from session_hash_value
        and occurred_at >= event_time - interval '30 seconds'
    ) into duplicate_recent;
    if duplicate_recent then
      return jsonb_build_object('issue_id', target_issue.id, 'accepted', false, 'deduplicated', true);
    end if;

    update public.app_error_issues
    set last_seen = event_time,
        occurrence_count = occurrence_count + 1,
        affected_users_count = affected_users_count + case when already_seen then 0 else 1 end,
        severity = case
          when p_severity = 'critical' then 'critical'
          when p_severity = 'error' and severity in ('info', 'warning') then 'error'
          when p_severity = 'warning' and severity = 'info' then 'warning'
          else severity
        end,
        sanitized_stack = coalesce(clean_stack, sanitized_stack),
        os_version = coalesce(clean_os, os_version),
        device_model = coalesce(clean_device, device_model)
    where id = target_issue.id
    returning * into target_issue;
  else
    insert into public.app_error_issues(
      fingerprint, severity, category, feature, title, sanitized_message,
      sanitized_stack, app_version, build_number, platform, os_version,
      device_model, first_seen, last_seen
    ) values (
      fingerprint_value, p_severity, p_category, clean_feature,
      left(clean_feature || ': ' || clean_message, 160), clean_message,
      clean_stack, p_app_version, p_build_number, p_platform, clean_os,
      clean_device, event_time, event_time
    ) returning * into target_issue;
  end if;

  insert into public.app_error_occurrences(
    issue_id, user_id, session_hash, screen, network_state, safe_context,
    app_version, build_number, platform, occurred_at
  ) values (
    target_issue.id, caller_id, session_hash_value, clean_screen,
    case when p_network_state in ('wifi', 'mobile', 'ethernet', 'vpn', 'offline', 'other') then p_network_state else 'unknown' end,
    safe_context, p_app_version, p_build_number, p_platform, event_time
  );

  return jsonb_build_object('issue_id', target_issue.id, 'accepted', true, 'deduplicated', false);
end;
$$;

create or replace function public.submit_user_problem_report(
  p_category text,
  p_description text,
  p_screen text,
  p_app_version text,
  p_build_number text,
  p_platform text
)
returns uuid
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  caller_id uuid := auth.uid();
  report_id uuid;
  clean_description text;
  clean_screen text;
begin
  if caller_id is null then
    raise exception using errcode = '42501', message = 'Authentication required';
  end if;
  if p_category not in (
    'login', 'gameplay', 'matchmaking', 'room', 'content', 'image', 'wallet',
    'purchase', 'notification', 'performance', 'other'
  ) or p_platform not in ('android', 'ios', 'web', 'unknown') then
    raise exception using errcode = '22023', message = 'Unsupported report classification';
  end if;
  if (
    select count(*) from public.user_problem_reports
    where user_id = caller_id and created_at >= clock_timestamp() - interval '24 hours'
  ) >= 5 then
    raise exception using errcode = 'P0001', message = 'Problem report rate limit reached';
  end if;

  clean_description := public.sanitize_app_error_text(p_description, 1500);
  clean_screen := public.sanitize_app_error_text(p_screen, 100);
  if char_length(coalesce(p_app_version, '')) not between 1 and 32
     or char_length(coalesce(p_build_number, '')) not between 1 and 20 then
    raise exception using errcode = '22023', message = 'Invalid application version';
  end if;

  insert into public.user_problem_reports(
    user_id, category, description, screen, app_version, build_number, platform
  ) values (
    caller_id, p_category, clean_description, clean_screen,
    p_app_version, p_build_number, p_platform
  ) returning id into report_id;

  return report_id;
end;
$$;

create or replace function public.review_app_error_issue(
  p_issue_id uuid,
  p_status text,
  p_internal_note text default null
)
returns public.app_error_issues
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  previous_issue public.app_error_issues%rowtype;
  updated_issue public.app_error_issues%rowtype;
  clean_note text;
begin
  if not public.has_role('admin') then
    raise exception using errcode = '42501', message = 'Administrator permission required';
  end if;
  if p_status not in ('open', 'resolved') then
    raise exception using errcode = '22023', message = 'Invalid issue status';
  end if;
  clean_note := public.sanitize_app_error_text(p_internal_note, 2000);
  select * into previous_issue from public.app_error_issues where id = p_issue_id for update;
  if not found then raise exception using errcode = 'P0002', message = 'Issue not found'; end if;

  update public.app_error_issues
  set status = p_status,
      internal_note = clean_note,
      resolved_by = case when p_status = 'resolved' then auth.uid() else null end,
      resolved_at = case when p_status = 'resolved' then clock_timestamp() else null end
  where id = p_issue_id returning * into updated_issue;

  insert into public.audit_logs(actor_user_id, action, entity_type, entity_id, old_data, new_data)
  values (
    auth.uid(), 'app_error.reviewed', 'app_error_issue', p_issue_id::text,
    jsonb_build_object('status', previous_issue.status, 'note', previous_issue.internal_note),
    jsonb_build_object('status', updated_issue.status, 'note', updated_issue.internal_note)
  );
  return updated_issue;
end;
$$;

create or replace function public.review_user_problem_report(
  p_report_id uuid,
  p_status text,
  p_admin_note text default null,
  p_linked_issue_id uuid default null
)
returns public.user_problem_reports
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  previous_report public.user_problem_reports%rowtype;
  updated_report public.user_problem_reports%rowtype;
  clean_note text;
begin
  if not public.has_role('moderator') then
    raise exception using errcode = '42501', message = 'Moderator permission required';
  end if;
  if p_status not in ('new', 'in_review', 'resolved', 'rejected') then
    raise exception using errcode = '22023', message = 'Invalid report status';
  end if;
  if p_linked_issue_id is not null and not exists (
    select 1 from public.app_error_issues where id = p_linked_issue_id
  ) then
    raise exception using errcode = '23503', message = 'Linked issue not found';
  end if;
  clean_note := public.sanitize_app_error_text(p_admin_note, 2000);
  select * into previous_report from public.user_problem_reports where id = p_report_id for update;
  if not found then raise exception using errcode = 'P0002', message = 'Report not found'; end if;

  update public.user_problem_reports
  set status = p_status,
      admin_note = clean_note,
      linked_issue_id = p_linked_issue_id,
      reviewed_by = case when p_status = 'new' then null else auth.uid() end,
      reviewed_at = case when p_status = 'new' then null else clock_timestamp() end
  where id = p_report_id returning * into updated_report;

  insert into public.audit_logs(actor_user_id, action, entity_type, entity_id, old_data, new_data)
  values (
    auth.uid(), 'user_problem_report.reviewed', 'user_problem_report', p_report_id::text,
    jsonb_build_object('status', previous_report.status, 'linked_issue_id', previous_report.linked_issue_id),
    jsonb_build_object('status', updated_report.status, 'linked_issue_id', updated_report.linked_issue_id)
  );
  return updated_report;
end;
$$;

create or replace function public.get_admin_dashboard_metrics()
returns jsonb
language sql
stable
security definer
set search_path = pg_catalog, public
as $$
  select case when public.has_role('moderator') then jsonb_build_object(
    'users', (select count(*) from public.profiles),
    'active_users_24h', (select count(*) from public.profiles where last_seen_at >= now() - interval '24 hours'),
    'new_users_7d', (select count(*) from public.profiles where created_at >= now() - interval '7 days'),
    'matches', (select count(*) from public.matches),
    'matches_today', (select count(*) from public.matches where created_at >= date_trunc('day', now())),
    'solo_matches', (select count(*) from public.matches where mode = 'solo'),
    'one_v_one_matches', (select count(*) from public.matches where mode in ('quick_1v1', 'friend_1v1')),
    'two_v_two_matches', (select count(*) from public.matches where mode = 'team_2v2'),
    'questions', (select count(*) from public.questions),
    'published_questions', (select count(*) from public.questions where status = 'published'),
    'draft_questions', (select count(*) from public.questions where status = 'draft'),
    'categories', (select count(*) from public.categories where parent_id is null),
    'question_reports_open', (select count(*) from public.question_reports where status in ('open', 'reviewing')),
    'user_reports_open', (select count(*) from public.user_problem_reports where status in ('new', 'in_review')),
    'error_issues_open', (select count(*) from public.app_error_issues where status = 'open'),
    'critical_issues_open', (select count(*) from public.app_error_issues where status = 'open' and severity = 'critical'),
    'coins_circulation', (select coalesce(sum(balance), 0) from public.wallets),
    'wallet_purchases_30d', (select count(*) from public.wallet_transactions where type = 'purchase' and created_at >= now() - interval '30 days'),
    'premium_users', (select count(distinct user_id) from public.subscriptions where status in ('trialing', 'active', 'grace_period')),
    'notifications_sent_7d', (select count(*) from public.notification_deliveries where status = 'sent' and attempted_at >= now() - interval '7 days'),
    'notifications_failed_7d', (select count(*) from public.notification_deliveries where status = 'failed' and attempted_at >= now() - interval '7 days')
  ) else null end;
$$;

revoke all on function public.validate_managed_app_content_value() from public, anon, authenticated;
revoke all on function public.sanitize_app_error_text(text, integer) from public, anon, authenticated;
revoke all on function public.report_app_error(text, text, text, text, text, text, text, text, text, text, text, text, text, jsonb) from public;
revoke all on function public.submit_user_problem_report(text, text, text, text, text, text) from public;
revoke all on function public.review_app_error_issue(uuid, text, text) from public;
revoke all on function public.review_user_problem_report(uuid, text, text, uuid) from public;
revoke all on function public.get_admin_dashboard_metrics() from public;

grant execute on function public.report_app_error(text, text, text, text, text, text, text, text, text, text, text, text, text, jsonb) to authenticated;
grant execute on function public.submit_user_problem_report(text, text, text, text, text, text) to authenticated;
grant execute on function public.review_app_error_issue(uuid, text, text) to authenticated;
grant execute on function public.review_user_problem_report(uuid, text, text, uuid) to authenticated;
grant execute on function public.get_admin_dashboard_metrics() to authenticated;

comment on table public.app_error_issues is
  'Deduplicated, sanitized operational issues reported by authenticated app sessions.';
comment on table public.app_error_occurrences is
  'Rate-limited occurrence timeline with allowlisted context and hashed session identifiers.';
comment on table public.user_problem_reports is
  'Privacy-conscious problem reports submitted by players and reviewed by staff.';
comment on column public.app_content.key is
  'Stable managed content key. Branding app icon assets are build sources and do not change installed launcher icons remotely.';
