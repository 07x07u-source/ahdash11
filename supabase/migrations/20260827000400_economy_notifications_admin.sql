-- Ledger-backed economy, store, subscriptions, notifications, reports, and import staging.
create table public.wallets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references public.profiles(id) on delete cascade,
  balance bigint not null default 0 check (balance >= 0),
  lifetime_earned bigint not null default 0 check (lifetime_earned >= 0),
  lifetime_spent bigint not null default 0 check (lifetime_spent >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.wallet_transactions (
  id uuid primary key default gen_random_uuid(),
  wallet_id uuid not null references public.wallets(id) on delete cascade,
  amount bigint not null check (amount <> 0),
  type public.wallet_transaction_type not null,
  reason text not null check (char_length(reason) between 1 and 120),
  reference_type text,
  reference_id text,
  idempotency_key text,
  balance_after bigint not null check (balance_after >= 0),
  metadata jsonb not null default '{}'::jsonb check (jsonb_typeof(metadata) = 'object'),
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default clock_timestamp(),
  constraint wallet_transactions_sign_type check (
    (amount > 0 and type in ('earn', 'purchase', 'refund', 'reward', 'admin_adjustment'))
    or (amount < 0 and type in ('spend', 'admin_adjustment'))
  ),
  constraint wallet_transactions_reference_pair check (
    (reference_type is null) = (reference_id is null)
  )
);

create unique index wallet_transactions_idempotency_uidx
  on public.wallet_transactions(wallet_id, idempotency_key)
  where idempotency_key is not null;
create index wallet_transactions_history_idx on public.wallet_transactions(wallet_id, created_at desc);
create index wallet_transactions_reference_idx on public.wallet_transactions(reference_type, reference_id);

create table public.store_items (
  id uuid primary key default gen_random_uuid(),
  sku extensions.citext not null unique,
  type public.store_item_type not null,
  name_ar text not null,
  name_en text,
  description_ar text,
  image_url text,
  price_coins bigint check (price_coins is null or price_coins >= 0),
  revenuecat_product_id text,
  consumable boolean not null default false,
  ranked_allowed boolean not null default true,
  metadata jsonb not null default '{}'::jsonb check (jsonb_typeof(metadata) = 'object'),
  sort_order integer not null default 0,
  is_active boolean not null default true,
  available_from timestamptz,
  available_until timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint store_items_has_price check (price_coins is not null or revenuecat_product_id is not null),
  constraint store_items_availability check (
    available_until is null or available_from is null or available_until > available_from
  )
);

create index store_items_catalog_idx on public.store_items(is_active, type, sort_order);

create table public.user_inventory (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  store_item_id uuid not null references public.store_items(id) on delete restrict,
  status public.inventory_status not null default 'active',
  quantity integer not null default 1 check (quantity >= 0),
  acquired_via text not null check (acquired_via in ('coins', 'purchase', 'reward', 'subscription', 'admin')),
  source_transaction_id uuid references public.wallet_transactions(id) on delete set null,
  equipped_at timestamptz,
  expires_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, store_item_id),
  constraint user_inventory_expiry check (expires_at is null or expires_at > created_at)
);

create index user_inventory_user_status_idx on public.user_inventory(user_id, status);

create table public.subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  provider text not null default 'revenuecat' check (provider = 'revenuecat'),
  entitlement_id text not null,
  product_id text not null,
  original_transaction_id text,
  status public.subscription_status not null,
  platform text check (platform in ('ios', 'android', 'unknown')),
  purchased_at timestamptz,
  current_period_ends_at timestamptz,
  cancelled_at timestamptz,
  raw_event jsonb not null default '{}'::jsonb check (jsonb_typeof(raw_event) = 'object'),
  last_event_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, entitlement_id)
);

create unique index subscriptions_original_tx_uidx
  on public.subscriptions(provider, original_transaction_id)
  where original_transaction_id is not null;
create index subscriptions_active_idx on public.subscriptions(user_id, status, current_period_ends_at desc);

create table public.device_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  token text not null unique,
  platform text not null check (platform in ('ios', 'android', 'web')),
  app_version text,
  locale text not null default 'ar',
  is_active boolean not null default true,
  last_seen_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index device_tokens_active_user_idx on public.device_tokens(user_id) where is_active;

create table public.notification_preferences (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  friend_requests boolean not null default true,
  match_invites boolean not null default true,
  challenges boolean not null default true,
  rewards boolean not null default true,
  season_events boolean not null default true,
  announcements boolean not null default true,
  quiet_hours_start time,
  quiet_hours_end time,
  updated_at timestamptz not null default now(),
  constraint notification_preferences_quiet_pair check (
    (quiet_hours_start is null) = (quiet_hours_end is null)
  )
);

create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  target_user_id uuid references public.profiles(id) on delete cascade,
  type public.notification_type not null,
  title_ar text not null,
  body_ar text not null,
  title_en text,
  body_en text,
  data jsonb not null default '{}'::jsonb check (jsonb_typeof(data) = 'object'),
  audience jsonb not null default '{}'::jsonb check (jsonb_typeof(audience) = 'object'),
  status public.notification_status not null default 'queued',
  scheduled_at timestamptz,
  sent_at timestamptz,
  read_at timestamptz,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint notifications_content_length check (
    char_length(title_ar) between 1 and 120 and char_length(body_ar) between 1 and 1000
  ),
  constraint notifications_broadcast_audience check (
    target_user_id is not null or audience <> '{}'::jsonb
  )
);

create index notifications_user_feed_idx on public.notifications(target_user_id, created_at desc);
create index notifications_queue_idx on public.notifications(status, scheduled_at) where status = 'queued';

create table public.question_reports (
  id uuid primary key default gen_random_uuid(),
  question_id uuid not null references public.questions(id) on delete cascade,
  reporter_id uuid references public.profiles(id) on delete set null,
  match_id uuid references public.matches(id) on delete set null,
  reason public.report_reason not null,
  details text check (details is null or char_length(details) <= 2000),
  status public.report_status not null default 'open',
  resolution_note text,
  resolved_by uuid references public.profiles(id) on delete set null,
  resolved_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint question_reports_resolution check (
    (status not in ('resolved', 'dismissed'))
    or (resolved_at is not null and resolved_by is not null)
  )
);

create unique index question_reports_one_open_per_user_uidx
  on public.question_reports(question_id, reporter_id, reason)
  where status in ('open', 'reviewing') and reporter_id is not null;
create index question_reports_queue_idx on public.question_reports(status, created_at);

create table public.import_batches (
  id uuid primary key default gen_random_uuid(),
  filename text not null,
  source_type public.import_source not null,
  status public.import_batch_status not null default 'uploaded',
  category_hint_id uuid references public.categories(id) on delete set null,
  total_rows integer not null default 0 check (total_rows >= 0),
  valid_rows integer not null default 0 check (valid_rows >= 0),
  invalid_rows integer not null default 0 check (invalid_rows >= 0),
  review_rows integer not null default 0 check (review_rows >= 0),
  duplicate_rows integer not null default 0 check (duplicate_rows >= 0),
  settings jsonb not null default '{}'::jsonb check (jsonb_typeof(settings) = 'object'),
  error_summary jsonb not null default '{}'::jsonb check (jsonb_typeof(error_summary) = 'object'),
  created_by uuid not null references public.profiles(id) on delete restrict,
  committed_by uuid references public.profiles(id) on delete set null,
  committed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint import_batches_count_totals check (
    valid_rows + invalid_rows + review_rows + duplicate_rows <= total_rows
  )
);

create index import_batches_history_idx on public.import_batches(created_by, created_at desc);
create index import_batches_status_idx on public.import_batches(status, created_at);

create table public.import_rows (
  id uuid primary key default gen_random_uuid(),
  batch_id uuid not null references public.import_batches(id) on delete cascade,
  row_number integer not null check (row_number > 0),
  raw_data jsonb not null check (jsonb_typeof(raw_data) = 'object'),
  normalized_data jsonb not null default '{}'::jsonb check (jsonb_typeof(normalized_data) = 'object'),
  status public.import_row_status not null default 'pending',
  errors jsonb not null default '[]'::jsonb check (jsonb_typeof(errors) = 'array'),
  warnings jsonb not null default '[]'::jsonb check (jsonb_typeof(warnings) = 'array'),
  classification jsonb not null default '{}'::jsonb check (jsonb_typeof(classification) = 'object'),
  confidence numeric(5,4) check (confidence is null or confidence between 0 and 1),
  duplicate_question_id uuid references public.questions(id) on delete set null,
  similar_question_ids uuid[] not null default '{}',
  committed_question_id uuid references public.questions(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (batch_id, row_number)
);

create index import_rows_review_idx on public.import_rows(batch_id, status, row_number);
create index import_rows_duplicate_idx on public.import_rows(duplicate_question_id) where duplicate_question_id is not null;

create table public.game_settings (
  key extensions.citext primary key,
  value jsonb not null,
  description_ar text not null,
  is_public boolean not null default false,
  validation jsonb not null default '{}'::jsonb check (jsonb_typeof(validation) = 'object'),
  updated_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint game_settings_key_format check (key::text ~ '^[a-z][a-z0-9_.-]{1,79}$')
);

create table public.account_deletion_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  status public.account_deletion_status not null default 'requested',
  reason text,
  requested_at timestamptz not null default now(),
  processed_at timestamptz,
  error_message text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index account_deletion_one_active_uidx
  on public.account_deletion_requests(user_id)
  where status in ('requested', 'processing');

create table public.audit_logs (
  id bigint generated always as identity primary key,
  actor_user_id uuid references public.profiles(id) on delete set null,
  action text not null,
  entity_type text not null,
  entity_id text,
  old_data jsonb,
  new_data jsonb,
  request_id text,
  ip_address inet,
  created_at timestamptz not null default clock_timestamp()
);

create index audit_logs_entity_idx on public.audit_logs(entity_type, entity_id, created_at desc);
create index audit_logs_actor_idx on public.audit_logs(actor_user_id, created_at desc);

create or replace function public.apply_wallet_balance()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  current_balance bigint;
  next_balance bigint;
begin
  select balance into current_balance
  from public.wallets
  where id = new.wallet_id
  for update;

  if current_balance is null then
    raise exception using errcode = '23503', message = 'Wallet not found';
  end if;

  next_balance := current_balance + new.amount;
  if next_balance < 0 then
    raise exception using errcode = '22003', message = 'Insufficient wallet balance';
  end if;

  update public.wallets
  set balance = next_balance,
      lifetime_earned = lifetime_earned + greatest(new.amount, 0),
      lifetime_spent = lifetime_spent + abs(least(new.amount, 0)),
      updated_at = clock_timestamp()
  where id = new.wallet_id;

  new.balance_after := next_balance;
  return new;
end;
$$;

create trigger wallet_transactions_apply_balance
before insert on public.wallet_transactions
for each row execute function public.apply_wallet_balance();

create or replace function public.after_profile_create_wallet()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
begin
  insert into public.wallets(user_id) values (new.id) on conflict (user_id) do nothing;
  insert into public.notification_preferences(user_id) values (new.id) on conflict do nothing;
  return new;
end;
$$;

create trigger profiles_create_wallet_and_preferences
after insert on public.profiles
for each row execute function public.after_profile_create_wallet();

create trigger wallets_set_updated_at before update on public.wallets
for each row execute function public.set_updated_at();
create trigger store_items_set_updated_at before update on public.store_items
for each row execute function public.set_updated_at();
create trigger user_inventory_set_updated_at before update on public.user_inventory
for each row execute function public.set_updated_at();
create trigger subscriptions_set_updated_at before update on public.subscriptions
for each row execute function public.set_updated_at();
create trigger device_tokens_set_updated_at before update on public.device_tokens
for each row execute function public.set_updated_at();
create trigger notification_preferences_set_updated_at before update on public.notification_preferences
for each row execute function public.set_updated_at();
create trigger notifications_set_updated_at before update on public.notifications
for each row execute function public.set_updated_at();
create trigger question_reports_set_updated_at before update on public.question_reports
for each row execute function public.set_updated_at();
create trigger import_batches_set_updated_at before update on public.import_batches
for each row execute function public.set_updated_at();
create trigger import_rows_set_updated_at before update on public.import_rows
for each row execute function public.set_updated_at();
create trigger game_settings_set_updated_at before update on public.game_settings
for each row execute function public.set_updated_at();
create trigger account_deletion_requests_set_updated_at before update on public.account_deletion_requests
for each row execute function public.set_updated_at();

comment on table public.wallet_transactions is
  'Append-only coin ledger; balance_after is calculated under a row lock by a trigger.';
comment on table public.import_rows is
  'Staging and preview records. raw_data accepts Arabic or canonical headers; normalized_data is canonical.';
