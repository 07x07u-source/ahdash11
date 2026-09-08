-- Image-led cosmetic catalog and server-authoritative purchase/equip contracts.
-- This migration intentionally leaves all previously applied migrations unchanged.

with catalog(
  id, sku, name_ar, description_ar, price_coins, category, rarity,
  sort_order, featured, is_new
) as (
  values
    ('11000000-0000-4000-8000-000000000001'::uuid, 'card_tunnel_lime', 'نفق الحسم', 'نفق Lime يفتح بطاقتك على أجواء المباراة.', 420::bigint, 'profileBackground', 'rare', 10, true, false),
    ('11000000-0000-4000-8000-000000000002'::uuid, 'card_night_pitch', 'ملعب الليل', 'ملعب هادئ تحت الكشافات لبطاقة أكثر هيبة.', 520::bigint, 'profileBackground', 'rare', 20, false, true),
    ('11000000-0000-4000-8000-000000000003'::uuid, 'card_gold_stage', 'منصة الذهب', 'إضاءة ذهبية مركزة للحظات المستوى العالي.', 760::bigint, 'profileBackground', 'epic', 30, true, false),
    ('11000000-0000-4000-8000-000000000004'::uuid, 'card_sand_geometry', 'هندسة الاستراحة', 'تكوين دافئ بخطوط اجتماعية وكروية أصلية.', 610::bigint, 'profileBackground', 'epic', 40, false, false),
    ('11000000-0000-4000-8000-000000000005'::uuid, 'frame_tactical', 'إطار التكتيك', 'حواف فحمية مع مسار Lime حاد وواضح.', 350::bigint, 'profileFrame', 'common', 50, false, false),
    ('11000000-0000-4000-8000-000000000006'::uuid, 'frame_gold_step', 'إطار المدرج الذهبي', 'إطار متدرج بلمعة ذهبية هادئة.', 690::bigint, 'profileFrame', 'epic', 60, true, false),
    ('11000000-0000-4000-8000-000000000007'::uuid, 'frame_sand_cut', 'إطار الرمل', 'قصّات هندسية بلون رملي حديث.', 460::bigint, 'profileFrame', 'rare', 70, false, true),
    ('11000000-0000-4000-8000-000000000008'::uuid, 'style_pitch_diagonal', 'ستايل خط الملعب', 'ألواح قطرية مستوحاة من خطوط الملعب.', 390::bigint, 'player11Style', 'rare', 80, false, false),
    ('11000000-0000-4000-8000-000000000009'::uuid, 'style_nocturne_split', 'ستايل ليلة المباراة', 'تقسيم ليلي متوازن بلمسة ذهبية.', 480::bigint, 'player11Style', 'rare', 90, false, true),
    ('11000000-0000-4000-8000-000000000010'::uuid, 'style_desert_blocks', 'ستايل مدرج الصحراء', 'طبقات رملية متدرجة بتكوين مختلف.', 630::bigint, 'player11Style', 'epic', 100, false, false),
    ('11000000-0000-4000-8000-000000000011'::uuid, 'style_stadium_wave', 'ستايل موجة الجمهور', 'موجات Lime متحركة بصريًا حول Player 11.', 820::bigint, 'player11Style', 'legendary', 110, true, false),
    ('11000000-0000-4000-8000-000000000012'::uuid, 'team_tactics', 'راية الخطة', 'نمط تمريرات وخطوط ملعب لفريق الاستراحة.', 440::bigint, 'teamPattern', 'rare', 120, false, false),
    ('11000000-0000-4000-8000-000000000013'::uuid, 'team_sadu_step', 'راية الدرج الرملي', 'هندسة متدرجة مستوحاة برفق من النسيج المحلي.', 580::bigint, 'teamPattern', 'epic', 130, false, true),
    ('11000000-0000-4000-8000-000000000014'::uuid, 'team_stadium_wave', 'راية الموجة', 'موجة كشافات سريعة بهوية فريق واضحة.', 720::bigint, 'teamPattern', 'epic', 140, false, false),
    ('11000000-0000-4000-8000-000000000015'::uuid, 'victory_lime_spiral', 'احتفال الدوامة', 'دوامة Lime ترتفع عند إعلان الفوز.', 850::bigint, 'victoryEffect', 'legendary', 150, true, false),
    ('11000000-0000-4000-8000-000000000016'::uuid, 'victory_gold_prism', 'احتفال المنشور', 'شظايا ضوء ذهبية هندسية بلا ضوضاء.', 920::bigint, 'victoryEffect', 'legendary', 160, false, true),
    ('11000000-0000-4000-8000-000000000017'::uuid, 'nameplate_tactical', 'لوحة صانع اللعب', 'لوحة فحمية طويلة بحافة تكتيكية.', 280::bigint, 'nameplate', 'common', 170, false, false),
    ('11000000-0000-4000-8000-000000000018'::uuid, 'nameplate_majlis_gold', 'لوحة القائد', 'لوحة رملية ذهبية لاسمك داخل الفريق.', 540::bigint, 'nameplate', 'epic', 180, false, false),
    ('11000000-0000-4000-8000-000000000019'::uuid, 'answer_effect_pitch_pulse', 'نبضة الملعب', 'دوائر ملعب تظهر بعد نتيجة الإجابة.', 470::bigint, 'answerEffect', 'rare', 190, false, true),
    ('11000000-0000-4000-8000-000000000020'::uuid, 'lobby_tactical_room', 'غرفة الخطة', 'خلفية تكتيكية هادئة لغرفة الانتظار.', 660::bigint, 'lobbyBackground', 'epic', 200, false, false)
)
insert into public.store_items(
  id, sku, type, name_ar, description_ar, price_coins, consumable,
  ranked_allowed, metadata, sort_order, is_active
)
select
  catalog.id,
  catalog.sku,
  'cosmetic'::public.store_item_type,
  catalog.name_ar,
  catalog.description_ar,
  catalog.price_coins,
  false,
  true,
  jsonb_build_object(
    'category', catalog.category,
    'rarity', catalog.rarity,
    'featured', catalog.featured,
    'new', catalog.is_new,
    'cosmetic_only', true,
    'asset_rights', 'original-generated-safe',
    'image_asset', 'assets/images/store/products/' || catalog.sku || '.webp',
    'preview_asset', 'assets/images/store/products/' || catalog.sku || '.webp'
  ),
  catalog.sort_order,
  true
from catalog
on conflict (sku) do update
set type = excluded.type,
    name_ar = excluded.name_ar,
    description_ar = excluded.description_ar,
    price_coins = excluded.price_coins,
    consumable = false,
    ranked_allowed = true,
    metadata = excluded.metadata,
    sort_order = excluded.sort_order,
    is_active = true,
    updated_at = now();

create table public.store_action_receipts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  action text not null check (action in ('purchase', 'equip')),
  idempotency_key text not null check (char_length(idempotency_key) between 8 and 120),
  request_hash text not null,
  response jsonb not null check (jsonb_typeof(response) = 'object'),
  created_at timestamptz not null default clock_timestamp(),
  unique (user_id, action, idempotency_key)
);

create index store_action_receipts_user_created_idx
  on public.store_action_receipts(user_id, created_at desc);

alter table public.store_action_receipts enable row level security;
revoke all on public.store_action_receipts from public, anon, authenticated;

create or replace function public.purchase_store_item_v2(
  p_store_item_id uuid,
  p_idempotency_key text,
  p_client_sequence bigint default null
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  caller public.profiles%rowtype;
  target_item public.store_items%rowtype;
  target_wallet_id uuid;
  target_balance bigint;
  inventory_id_value uuid;
  inventory_equipped_at timestamptz;
  prior_hash text;
  prior_response jsonb;
  request_hash_value text;
  transaction_row public.wallet_transactions%rowtype;
  response_value jsonb;
begin
  caller := public.require_active_user();
  perform public.assert_rate_limit(caller.id::text, 'purchase_store_item_v2', 20, interval '1 minute');
  if char_length(coalesce(p_idempotency_key, '')) not between 8 and 120 then
    raise exception using errcode = '22023', message = 'A valid idempotency key is required';
  end if;
  if p_client_sequence is not null and p_client_sequence < 0 then
    raise exception using errcode = '22023', message = 'client sequence must be positive';
  end if;

  request_hash_value := md5(p_store_item_id::text);
  select id, balance
  into target_wallet_id, target_balance
  from public.wallets
  where user_id = caller.id
  for update;
  if not found then
    raise exception using errcode = 'P0002', message = 'Wallet not found';
  end if;

  select request_hash, response
  into prior_hash, prior_response
  from public.store_action_receipts
  where user_id = caller.id
    and action = 'purchase'
    and idempotency_key = p_idempotency_key;
  if found then
    if prior_hash <> request_hash_value then
      raise exception using errcode = '22023', message = 'Idempotency key reused for a different request';
    end if;
    return prior_response;
  end if;

  select *
  into target_item
  from public.store_items
  where id = p_store_item_id
  for share;
  if not found
     or not target_item.is_active
     or target_item.type <> 'cosmetic'
     or target_item.consumable
     or target_item.price_coins is null
     or coalesce((target_item.metadata ->> 'cosmetic_only')::boolean, false) is not true
     or (target_item.available_from is not null and target_item.available_from > now())
     or (target_item.available_until is not null and target_item.available_until <= now()) then
    raise exception using errcode = 'P0002', message = 'Cosmetic store item is unavailable';
  end if;

  select id, equipped_at
  into inventory_id_value, inventory_equipped_at
  from public.user_inventory
  where user_id = caller.id
    and store_item_id = target_item.id
    and status = 'active';
  if found then
    response_value := jsonb_build_object(
      'status', 'already_owned',
      'ownership', true,
      'equipped', inventory_equipped_at is not null,
      'inventory_id', inventory_id_value,
      'new_balance', target_balance,
      'transaction_id', null,
      'product', jsonb_build_object(
        'id', target_item.id, 'sku', target_item.sku::text,
        'name_ar', target_item.name_ar, 'category', target_item.metadata ->> 'category'
      )
    );
    insert into public.store_action_receipts(
      user_id, action, idempotency_key, request_hash, response
    ) values (
      caller.id, 'purchase', p_idempotency_key, request_hash_value, response_value
    );
    return response_value;
  end if;

  if target_balance < target_item.price_coins then
    return jsonb_build_object(
      'status', 'insufficient_coins',
      'ownership', false,
      'equipped', false,
      'new_balance', target_balance,
      'required_balance', target_item.price_coins
    );
  end if;

  transaction_row := public.post_wallet_transaction(
    caller.id,
    -target_item.price_coins,
    'spend',
    'store_purchase',
    'store_item',
    target_item.id::text,
    'store-v2:' || p_idempotency_key,
    jsonb_build_object(
      'sku', target_item.sku::text,
      'quantity', 1,
      'client_sequence', p_client_sequence
    ),
    caller.id
  );

  insert into public.user_inventory(
    user_id, store_item_id, status, quantity, acquired_via, source_transaction_id
  ) values (
    caller.id, target_item.id, 'active', 1, 'coins', transaction_row.id
  )
  returning id, equipped_at into inventory_id_value, inventory_equipped_at;

  response_value := jsonb_build_object(
    'status', 'purchased',
    'ownership', true,
    'equipped', false,
    'inventory_id', inventory_id_value,
    'new_balance', transaction_row.balance_after,
    'transaction_id', transaction_row.id,
    'product', jsonb_build_object(
      'id', target_item.id, 'sku', target_item.sku::text,
      'name_ar', target_item.name_ar, 'category', target_item.metadata ->> 'category'
    )
  );
  insert into public.store_action_receipts(
    user_id, action, idempotency_key, request_hash, response
  ) values (
    caller.id, 'purchase', p_idempotency_key, request_hash_value, response_value
  );
  return response_value;
end;
$$;

create or replace function public.equip_store_item_v2(
  p_store_item_id uuid,
  p_idempotency_key text,
  p_client_sequence bigint default null
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  caller public.profiles%rowtype;
  target_item public.store_items%rowtype;
  target_wallet_id uuid;
  target_balance bigint;
  inventory_id_value uuid;
  prior_hash text;
  prior_response jsonb;
  request_hash_value text;
  response_value jsonb;
begin
  caller := public.require_active_user();
  perform public.assert_rate_limit(caller.id::text, 'equip_store_item_v2', 30, interval '1 minute');
  if char_length(coalesce(p_idempotency_key, '')) not between 8 and 120 then
    raise exception using errcode = '22023', message = 'A valid idempotency key is required';
  end if;
  if p_client_sequence is not null and p_client_sequence < 0 then
    raise exception using errcode = '22023', message = 'client sequence must be positive';
  end if;

  request_hash_value := md5(p_store_item_id::text);
  select id, balance
  into target_wallet_id, target_balance
  from public.wallets
  where user_id = caller.id
  for update;
  if not found then
    raise exception using errcode = 'P0002', message = 'Wallet not found';
  end if;

  select request_hash, response
  into prior_hash, prior_response
  from public.store_action_receipts
  where user_id = caller.id
    and action = 'equip'
    and idempotency_key = p_idempotency_key;
  if found then
    if prior_hash <> request_hash_value then
      raise exception using errcode = '22023', message = 'Idempotency key reused for a different request';
    end if;
    return prior_response;
  end if;

  select *
  into target_item
  from public.store_items
  where id = p_store_item_id
    and is_active
    and type = 'cosmetic'
    and coalesce((metadata ->> 'cosmetic_only')::boolean, false) is true
  for share;
  if not found then
    raise exception using errcode = 'P0002', message = 'Cosmetic store item is unavailable';
  end if;

  select id
  into inventory_id_value
  from public.user_inventory
  where user_id = caller.id
    and store_item_id = target_item.id
    and status = 'active'
  for update;
  if not found then
    raise exception using errcode = '42501', message = 'Store item is not owned';
  end if;

  update public.user_inventory as inventory
  set equipped_at = null,
      updated_at = clock_timestamp()
  from public.store_items as item
  where inventory.user_id = caller.id
    and inventory.store_item_id = item.id
    and inventory.status = 'active'
    and inventory.equipped_at is not null
    and item.metadata ->> 'category' = target_item.metadata ->> 'category';

  update public.user_inventory
  set equipped_at = clock_timestamp(),
      updated_at = clock_timestamp()
  where id = inventory_id_value;

  response_value := jsonb_build_object(
    'status', 'equipped',
    'ownership', true,
    'equipped', true,
    'inventory_id', inventory_id_value,
    'new_balance', target_balance,
    'transaction_id', null,
    'product', jsonb_build_object(
      'id', target_item.id, 'sku', target_item.sku::text,
      'name_ar', target_item.name_ar, 'category', target_item.metadata ->> 'category'
    )
  );
  insert into public.store_action_receipts(
    user_id, action, idempotency_key, request_hash, response
  ) values (
    caller.id, 'equip', p_idempotency_key, request_hash_value, response_value
  );
  return response_value;
end;
$$;

revoke all on function public.purchase_store_item_v2(uuid, text, bigint)
  from public, anon;
revoke all on function public.equip_store_item_v2(uuid, text, bigint)
  from public, anon;
grant execute on function public.purchase_store_item_v2(uuid, text, bigint)
  to authenticated;
grant execute on function public.equip_store_item_v2(uuid, text, bigint)
  to authenticated;

comment on function public.purchase_store_item_v2(uuid, text, bigint) is
  'Server-authoritative, idempotent purchase of one non-consumable cosmetic.';
comment on function public.equip_store_item_v2(uuid, text, bigint) is
  'Idempotently equips one owned cosmetic per category.';
