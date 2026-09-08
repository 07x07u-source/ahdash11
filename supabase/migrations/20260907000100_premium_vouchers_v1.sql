-- Premium promotional vouchers (local implementation only).
-- Redemption remains disabled until BOTH server flags are explicitly enabled
-- after store-policy review:
--   premium_vouchers.enabled
--   premium_vouchers.policy_approved

create type public.premium_voucher_type as enum ('monthly_promo', 'annual_promo');

create table public.premium_vouchers (
  id uuid primary key default gen_random_uuid(),
  code_hash text not null unique,
  voucher_type public.premium_voucher_type not null,
  created_by uuid not null references public.profiles(id) on delete restrict,
  created_at timestamptz not null default clock_timestamp(),
  redemption_deadline timestamptz not null default (clock_timestamp() + interval '6 months'),
  redeemed_at timestamptz,
  redeemed_by uuid references public.profiles(id) on delete restrict,
  promo_expires_at timestamptz,
  disabled_at timestamptz,
  disabled_by uuid references public.profiles(id) on delete restrict,
  internal_note text,
  constraint premium_vouchers_hash_shape check (code_hash ~ '^[0-9a-f]{64}$'),
  constraint premium_vouchers_note_length check (
    internal_note is null or char_length(internal_note) <= 500
  ),
  constraint premium_vouchers_redemption_shape check (
    (redeemed_at is null and redeemed_by is null and promo_expires_at is null)
    or
    (redeemed_at is not null and redeemed_by is not null and promo_expires_at > redeemed_at)
  ),
  constraint premium_vouchers_disable_shape check (
    (disabled_at is null and disabled_by is null)
    or (disabled_at is not null and disabled_by is not null)
  )
);

create table public.premium_promotional_entitlements (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  voucher_id uuid not null unique references public.premium_vouchers(id) on delete restrict,
  entitlement_id text not null default 'premium' check (entitlement_id = 'premium'),
  starts_at timestamptz not null,
  expires_at timestamptz not null,
  revoked_at timestamptz,
  created_at timestamptz not null default clock_timestamp(),
  constraint premium_promotional_entitlements_window check (expires_at > starts_at)
);

create index premium_vouchers_status_idx
  on public.premium_vouchers(redeemed_at, disabled_at, redemption_deadline desc);
create index premium_promotional_entitlements_active_idx
  on public.premium_promotional_entitlements(user_id, expires_at desc)
  where revoked_at is null;

alter table public.premium_vouchers enable row level security;
alter table public.premium_promotional_entitlements enable row level security;

-- Secrets and entitlement rows are RPC-only. Even administrators do not read
-- the voucher table directly, which prevents accidental raw-secret expansion.
revoke all on public.premium_vouchers from public, anon, authenticated;
revoke all on public.premium_promotional_entitlements from public, anon, authenticated;

insert into public.game_settings(key, value, description_ar, is_public, validation)
values
  (
    'premium_vouchers.enabled',
    'false'::jsonb,
    'تفعيل استرداد قسائم Premium المخصصة',
    false,
    '{"type":"boolean"}'::jsonb
  ),
  (
    'premium_vouchers.policy_approved',
    'false'::jsonb,
    'اعتماد مراجعة سياسات متاجر قسائم Premium',
    false,
    '{"type":"boolean"}'::jsonb
  )
on conflict (key) do nothing;

create or replace function public.premium_voucher_runtime_enabled()
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public
as $$
  select
    coalesce((select value #>> '{}' from public.game_settings where key = 'premium_vouchers.enabled')::boolean, false)
    and
    coalesce((select value #>> '{}' from public.game_settings where key = 'premium_vouchers.policy_approved')::boolean, false);
$$;

create or replace function public.normalize_premium_voucher_code(p_code text)
returns text
language sql
immutable
parallel safe
set search_path = pg_catalog
as $$
  select upper(regexp_replace(btrim(coalesce(p_code, '')), '[^A-Za-z0-9]', '', 'g'));
$$;

create or replace function public.premium_voucher_code_hash(p_code text)
returns text
language sql
immutable
parallel safe
set search_path = pg_catalog, extensions
as $$
  select encode(
    extensions.digest(convert_to(public.normalize_premium_voucher_code(p_code), 'UTF8'), 'sha256'),
    'hex'
  );
$$;

create or replace function public.get_my_premium_access()
returns jsonb
language plpgsql
stable
security definer
set search_path = pg_catalog, public
as $$
declare
  caller_id uuid := auth.uid();
  promo_expiry timestamptz;
begin
  if caller_id is null then
    raise exception using errcode = '28000', message = 'Authentication required';
  end if;

  select max(entitlement.expires_at) into promo_expiry
  from public.premium_promotional_entitlements as entitlement
  where entitlement.user_id = caller_id
    and entitlement.revoked_at is null
    and entitlement.starts_at <= clock_timestamp()
    and entitlement.expires_at > clock_timestamp();

  return jsonb_build_object(
    'active', promo_expiry is not null,
    'source', case when promo_expiry is null then 'none' else 'voucher' end,
    'expires_at', promo_expiry
  );
end;
$$;

create or replace function public.redeem_premium_voucher(p_code text)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, extensions
as $$
declare
  caller public.profiles%rowtype;
  normalized_code text;
  voucher public.premium_vouchers%rowtype;
  redeemed_at_value timestamptz;
  expires_at_value timestamptz;
begin
  caller := public.require_active_user();
  perform public.assert_rate_limit(caller.id::text, 'redeem_premium_voucher', 8, interval '1 hour');

  if not public.premium_voucher_runtime_enabled() then
    return jsonb_build_object('status', 'disabled');
  end if;

  normalized_code := public.normalize_premium_voucher_code(p_code);
  if char_length(normalized_code) <> 24 then
    return jsonb_build_object('status', 'invalid');
  end if;

  select candidate.* into voucher
  from public.premium_vouchers as candidate
  where candidate.code_hash = public.premium_voucher_code_hash(normalized_code)
  for update;

  if not found then
    return jsonb_build_object('status', 'invalid');
  end if;
  if voucher.disabled_at is not null then
    return jsonb_build_object('status', 'disabled');
  end if;
  if voucher.redeemed_at is not null then
    return jsonb_build_object('status', 'used');
  end if;
  if voucher.redemption_deadline <= clock_timestamp() then
    return jsonb_build_object('status', 'expired');
  end if;

  redeemed_at_value := clock_timestamp();
  expires_at_value := case voucher.voucher_type
    when 'monthly_promo' then redeemed_at_value + interval '1 month'
    when 'annual_promo' then redeemed_at_value + interval '1 year'
  end;

  update public.premium_vouchers
  set redeemed_at = redeemed_at_value,
      redeemed_by = caller.id,
      promo_expires_at = expires_at_value
  where id = voucher.id
    and redeemed_at is null;

  if not found then
    return jsonb_build_object('status', 'used');
  end if;

  insert into public.premium_promotional_entitlements(
    user_id, voucher_id, starts_at, expires_at
  ) values (
    caller.id, voucher.id, redeemed_at_value, expires_at_value
  );

  insert into public.audit_logs(
    actor_user_id, action, entity_type, entity_id, new_data
  ) values (
    caller.id,
    'premium_voucher_redeemed',
    'premium_voucher',
    voucher.id::text,
    jsonb_build_object('voucher_type', voucher.voucher_type, 'expires_at', expires_at_value)
  );

  return jsonb_build_object(
    'status', 'redeemed',
    'voucher_type', voucher.voucher_type,
    'redeemed_at', redeemed_at_value,
    'expires_at', expires_at_value
  );
end;
$$;

create or replace function public.admin_create_premium_vouchers(
  p_voucher_type public.premium_voucher_type,
  p_quantity integer default 1,
  p_internal_note text default null
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, extensions
as $$
declare
  caller_id uuid := auth.uid();
  item_index integer;
  compact_code text;
  display_code text;
  voucher_id uuid;
  created_codes jsonb := '[]'::jsonb;
begin
  if caller_id is null or not public.has_role('admin') then
    raise exception using errcode = '42501', message = 'Admin role required';
  end if;
  if not public.premium_voucher_runtime_enabled() then
    raise exception using errcode = '55000', message = 'Premium vouchers are disabled';
  end if;
  if p_quantity not between 1 and 50 then
    raise exception using errcode = '22023', message = 'Quantity must be between 1 and 50';
  end if;
  if p_internal_note is not null and char_length(p_internal_note) > 500 then
    raise exception using errcode = '22023', message = 'Internal note is too long';
  end if;

  for item_index in 1..p_quantity loop
    loop
      -- 12 random bytes produce a case-insensitive 24-character secret (96 bits).
      compact_code := upper(encode(extensions.gen_random_bytes(12), 'hex'));
      display_code := concat_ws('-',
        substring(compact_code from 1 for 4),
        substring(compact_code from 5 for 4),
        substring(compact_code from 9 for 4),
        substring(compact_code from 13 for 4),
        substring(compact_code from 17 for 4),
        substring(compact_code from 21 for 4)
      );
      begin
        insert into public.premium_vouchers(
          code_hash, voucher_type, created_by, internal_note
        ) values (
          public.premium_voucher_code_hash(display_code),
          p_voucher_type,
          caller_id,
          nullif(btrim(p_internal_note), '')
        ) returning id into voucher_id;
        exit;
      exception when unique_violation then
        -- An astronomically unlikely collision is regenerated server-side.
      end;
    end loop;

    created_codes := created_codes || jsonb_build_array(jsonb_build_object(
      'id', voucher_id,
      'code', display_code,
      'voucher_type', p_voucher_type
    ));
  end loop;

  insert into public.audit_logs(actor_user_id, action, entity_type, new_data)
  values (
    caller_id,
    'premium_vouchers_created',
    'premium_voucher',
    jsonb_build_object('voucher_type', p_voucher_type, 'quantity', p_quantity)
  );

  -- Raw codes are returned exactly once and are never persisted or audited.
  return created_codes;
end;
$$;

create or replace function public.admin_list_premium_vouchers(p_limit integer default 100)
returns jsonb
language plpgsql
stable
security definer
set search_path = pg_catalog, public
as $$
declare
  caller_id uuid := auth.uid();
  result jsonb;
begin
  if caller_id is null or not public.has_role('admin') then
    raise exception using errcode = '42501', message = 'Admin role required';
  end if;
  if p_limit not between 1 and 250 then
    raise exception using errcode = '22023', message = 'Limit is out of range';
  end if;

  select coalesce(jsonb_agg(to_jsonb(rows) order by rows.created_at desc), '[]'::jsonb)
  into result
  from (
    select
      voucher.id,
      voucher.voucher_type,
      case
        when voucher.disabled_at is not null then 'disabled'
        when voucher.redeemed_at is not null then 'redeemed'
        when voucher.redemption_deadline <= clock_timestamp() then 'expired'
        else 'unused'
      end as status,
      voucher.created_at,
      voucher.redemption_deadline,
      voucher.redeemed_at,
      voucher.promo_expires_at,
      voucher.internal_note,
      case when voucher.redeemed_by is null then null else coalesce(profile.username, profile.display_name, voucher.redeemed_by::text) end as redeemed_by
    from public.premium_vouchers as voucher
    left join public.profiles as profile on profile.id = voucher.redeemed_by
    order by voucher.created_at desc
    limit p_limit
  ) as rows;
  return result;
end;
$$;

create or replace function public.admin_disable_premium_voucher(p_voucher_id uuid)
returns boolean
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  caller_id uuid := auth.uid();
begin
  if caller_id is null or not public.has_role('admin') then
    raise exception using errcode = '42501', message = 'Admin role required';
  end if;

  update public.premium_vouchers
  set disabled_at = clock_timestamp(), disabled_by = caller_id
  where id = p_voucher_id
    and redeemed_at is null
    and disabled_at is null;

  if not found then return false; end if;
  insert into public.audit_logs(actor_user_id, action, entity_type, entity_id)
  values (caller_id, 'premium_voucher_disabled', 'premium_voucher', p_voucher_id::text);
  return true;
end;
$$;

revoke all on function public.premium_voucher_runtime_enabled() from public, anon, authenticated;
revoke all on function public.normalize_premium_voucher_code(text) from public, anon, authenticated;
revoke all on function public.premium_voucher_code_hash(text) from public, anon, authenticated;
revoke all on function public.get_my_premium_access() from public, anon, authenticated;
revoke all on function public.redeem_premium_voucher(text) from public, anon, authenticated;
revoke all on function public.admin_create_premium_vouchers(public.premium_voucher_type, integer, text) from public, anon, authenticated;
revoke all on function public.admin_list_premium_vouchers(integer) from public, anon, authenticated;
revoke all on function public.admin_disable_premium_voucher(uuid) from public, anon, authenticated;

grant execute on function public.get_my_premium_access() to authenticated;
grant execute on function public.redeem_premium_voucher(text) to authenticated;
grant execute on function public.admin_create_premium_vouchers(public.premium_voucher_type, integer, text) to authenticated;
grant execute on function public.admin_list_premium_vouchers(integer) to authenticated;
grant execute on function public.admin_disable_premium_voucher(uuid) to authenticated;

comment on table public.premium_vouchers is
  'One-time promotional Premium vouchers. Only SHA-256 code hashes are stored.';
comment on table public.premium_promotional_entitlements is
  'Non-recurring Premium grants created atomically by voucher redemption.';
