import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { readdir, readFile } from 'node:fs/promises';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = fileURLToPath(new URL('../..', import.meta.url));
const migrations = join(root, 'supabase', 'migrations');
const read = (path) => readFile(join(root, path), 'utf8');
const gameplay = await read('supabase/migrations/20260902000100_gameplay_depth_v1.sql');
const tournament = await read('supabase/migrations/20260905000100_tournament_bracket_safety_v2.sql');
const vouchers = await read('supabase/migrations/20260907000100_premium_vouchers_v1.sql');
const tournamentRegistrationFix = await read('supabase/migrations/20260908000100_fix_review_tournament_registration_enum.sql');
const premiumDomain = await read('mobile/lib/features/premium/domain/premium_access.dart');
const premiumProvider = await read('mobile/lib/features/premium/presentation/premium_access_provider.dart');
const app = await read('mobile/lib/app.dart');
const adminRoute = await read('admin/src/app/api/premium-vouchers/route.ts');
const adminDisableRoute = await read('admin/src/app/api/premium-vouchers/[id]/disable/route.ts');
const adminSchema = await read('admin/src/lib/premium-vouchers/schema.ts');

let count = 0;
function check(name, condition) {
  assert.equal(Boolean(condition), true, name);
  console.log(`PASS ${++count}: ${name}`);
}

const migrationFiles = (await readdir(migrations)).filter((name) => name.endsWith('.sql')).sort();
check('repository contains the expected 27 migration files', migrationFiles.length === 27);
check('gameplay migration retains documented hash', createHash('sha256').update(gameplay).digest('hex').toUpperCase() === 'C4968EA1824A3D9BBE942BABD3DE27F0F3267AF88DD834A4458861424267CCD1');
check('tournament safety migration retains documented hash', createHash('sha256').update(tournament).digest('hex').toUpperCase() === 'E4422D46197D187B50F544A2828667B3492F96F3C55BE7786420CCB122559E14');
check('voucher migration retains reviewed hash', createHash('sha256').update(vouchers).digest('hex').toUpperCase() === '0F292A2403902B38C240A26195645EB170C7E7A9DEF69F19E9FDE9D1812FCAFC');
check('Tournament registration enum fix retains reviewed hash', createHash('sha256').update(tournamentRegistrationFix).digest('hex').toUpperCase() === '16DB50AF51B41CE18542E92408404B8E7E477F80005A796A357DDE0DAB2949F2');

check('party pack requires an active authenticated user', gameplay.includes('caller := public.require_active_user()'));
check('party pack excludes competitive questions', gameplay.includes('and not q.competitive_eligible'));
check('party pack enforces media rights', gameplay.includes("q.media_rights_status in ('original', 'generated', 'licensed')"));
check('party pack function uses a fixed search path', /get_party_question_pack[\s\S]*?set search_path = pg_catalog, public/.test(gameplay));
check('gift redemption is rate limited server-side', gameplay.includes("'redeem_gift_code', 12, interval '1 hour'"));
check('gift redemption locks the secret row', /gift_codes as gift_code[\s\S]*?for update/.test(gameplay));
check('gift hashes are shape constrained and unique', gameplay.includes('code_hash text not null unique') && gameplay.includes('gift_codes_hash_shape'));
check('gift inventory writes are server-side', /redeem_gift_code[\s\S]*?insert into public\.user_inventory/.test(gameplay));
check('gameplay migration has no score or session-authority table grant', !/grant\s+(?:insert|update|delete)[^;]*public\.(?:matches|match_answers|match_players)/i.test(gameplay));

check('legacy destructive bracket writer is revoked', tournament.includes('revoke execute on function public.save_tournament_bracket'));
check('legacy weak result writer is revoked', tournament.includes('revoke execute on function public.confirm_tournament_match_result'));
check('safe bracket writer authenticates and checks ownership', tournament.includes('caller := public.require_active_user()') && tournament.includes('organizer_id = caller.id'));
check('safe bracket writer serializes on the tournament row', /from public\.tournaments[\s\S]*?organizer_id = caller\.id[\s\S]*?for update/.test(tournament));
check('safe bracket writer never deletes tournament players', !tournament.includes('delete from public.tournament_players'));
check('safe bracket writer never deletes tournament teams', !tournament.includes('delete from public.tournament_teams'));
check('safe bracket rejects missing approved teams', tournament.includes('Approved teams are missing from the bracket'));
check('safe bracket rejects confirmed graph replacement', tournament.includes('Confirmed matches prevent bracket replacement'));
check('safe bracket exact retry is idempotent', tournament.includes("target.status in ('live', 'completed')") && tournament.includes('return true'));
check('result confirmation locks tournament and match rows', (tournament.match(/for update;/g) ?? []).length >= 4);
check('result confirmation rejects conflicting retry', tournament.includes('Result conflicts with confirmed match'));
check('result confirmation protects dependent matches', tournament.includes('Dependent match already started'));
check('v2 tournament functions use fixed search paths', (tournament.match(/set search_path = pg_catalog, public/g) ?? []).length === 2);
check('only authenticated callers receive v2 execute', /grant execute on function public\.save_tournament_bracket_v2[\s\S]*?to authenticated/.test(tournament));

check('voucher generator uses 12 cryptographic random bytes', vouchers.includes('extensions.gen_random_bytes(12)'));
check('voucher generator contains no timestamp-derived secret material', !/compact_code\s*:=.*(?:clock_timestamp|now\(\))/i.test(vouchers));
check('voucher storage contains only a SHA-256 hash column', vouchers.includes('code_hash text not null unique') && vouchers.includes("'sha256'"));
check('voucher raw code is only returned by the creation RPC', (vouchers.match(/'code', display_code/g) ?? []).length === 1);
check('voucher audit payload never contains the raw code', !/audit_logs[\s\S]{0,500}'code'/i.test(vouchers));
check('voucher tables have RLS enabled', (vouchers.match(/enable row level security/g) ?? []).length === 2);
check('ordinary roles have all direct voucher table access revoked', vouchers.includes('revoke all on public.premium_vouchers from public, anon, authenticated'));
check('ordinary roles have all direct promo table access revoked', vouchers.includes('revoke all on public.premium_promotional_entitlements from public, anon, authenticated'));
check('redemption requires the active-user helper', /redeem_premium_voucher[\s\S]*?caller := public\.require_active_user\(\)/.test(vouchers));
check('redemption rate limit is 8 per account per hour', vouchers.includes("'redeem_premium_voucher', 8, interval '1 hour'"));
check('redemption locks the voucher row', /premium_vouchers as candidate[\s\S]*?for update/.test(vouchers));
check('redemption uses a compare-and-set guard', /where id = voucher\.id[\s\S]*?and redeemed_at is null/.test(vouchers));
check('one entitlement per voucher is enforced', vouchers.includes('voucher_id uuid not null unique'));
check('monthly duration is one PostgreSQL month', vouchers.includes("interval '1 month'"));
check('annual duration is one PostgreSQL year', vouchers.includes("interval '1 year'"));
check('server clock controls redemption and expiration', (vouchers.match(/clock_timestamp\(\)/g) ?? []).length >= 8);
check('both server feature gates default false', vouchers.includes("'premium_vouchers.enabled'") && vouchers.includes("'premium_vouchers.policy_approved'") && (vouchers.match(/'false'::jsonb/g) ?? []).length >= 2);
check('missing server feature flags fail closed', (vouchers.match(/coalesce\([\s\S]*?, false\)/g) ?? []).length >= 1);
check('voucher creation checks database admin role', /admin_create_premium_vouchers[\s\S]*?public\.has_role\('admin'\)/.test(vouchers));
check('voucher listing checks database admin role', /admin_list_premium_vouchers[\s\S]*?public\.has_role\('admin'\)/.test(vouchers));
check('voucher disabling checks database admin role', /admin_disable_premium_voucher[\s\S]*?public\.has_role\('admin'\)/.test(vouchers));
check('all voucher functions have explicit search paths', (vouchers.match(/set search_path = pg_catalog(?:, public)?(?:, extensions)?/g) ?? []).length === 8);
check('pending migrations contain no dynamic SQL EXECUTE statement', !/^\s*execute\s/m.test(`${gameplay}\n${tournament}\n${vouchers}`));

check('admin create API checks admin role', adminRoute.includes('authorizeAdminApi("admin")'));
check('admin disable API checks admin role', adminDisableRoute.includes('authorizeAdminApi("admin")'));
check('admin production action gate needs explicit policy approval', adminSchema.includes('enabled && (!production || approved)'));
check('admin create route never logs raw vouchers', !/console\.(?:log|debug|error)/.test(adminRoute));
check('client promo access validates server expiration', premiumDomain.includes('expiry.isAfter(instant.toUtc())'));
check('client promo access fails closed without expires_at', premiumDomain.includes('expiry != null'));
check('client schedules entitlement invalidation at expiry', premiumProvider.includes('Timer(remaining, ref.invalidateSelf)'));
check('app refreshes entitlement truth on resume', app.includes('ref.invalidate(premiumAccessProvider)'));

console.log(`${count}/${count} static security gate checks passed.`);
