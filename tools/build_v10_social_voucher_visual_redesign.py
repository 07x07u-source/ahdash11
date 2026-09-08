"""Build the final local V10 Social/Voucher visual-redesign review pack.

All inputs are deterministic renders from the current Flutter/Admin code or
the immediately preceding local review pack. The script never edits Goldens.
"""

from __future__ import annotations

import hashlib
import html
from pathlib import Path
from shutil import copy2

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
TMP = ROOT / "tmp" / "v10_social_voucher_visual_redesign"
SOCIAL = TMP / "social" / "social"
VOUCHER = TMP / "social" / "voucher"
PREMIUM = TMP / "premium"
ADVANCED = TMP / "advanced"
ADMIN = TMP / "admin"
PREVIOUS = ROOT / "docs" / "v10_social_voucher_refinement"
PREVIOUS_ADVANCED = ROOT / "docs" / "v10_advanced_visual_refinement"
OUTPUT = ROOT / "docs" / "v10_social_voucher_visual_redesign"


COPY_MAP: dict[str, Path] = {
    "friends/01_friends_primary_390x844.png": SOCIAL / "friends_primary_390x844.png",
    "friends/02_friends_compact_360x800.png": SOCIAL / "friends_compact_360x800.png",
    "friends/03_friends_empty_390x844.png": SOCIAL / "friends_empty_390x844.png",
    "friends/04_friends_loading_390x844.png": SOCIAL / "friends_loading_390x844.png",
    "friends/05_friends_error_390x844.png": SOCIAL / "friends_error_390x844.png",
    "add_friend/01_add_friend_search_390x844.png": SOCIAL / "friends_search_results_390x844.png",
    "add_friend/02_search_keyboard_390x844.png": SOCIAL / "friends_search_keyboard_390x844.png",
    "add_friend/03_search_results_390x844.png": SOCIAL / "friends_search_results_390x844.png",
    "add_friend/04_no_results_390x844.png": SOCIAL / "friends_no_results_390x844.png",
    "add_friend/05_friend_added_390x844.png": SOCIAL / "friend_added_390x844.png",
    "add_friend/06_add_action_available_390x844.png": SOCIAL / "add_friend_available_390x844.png",
    "add_friend/07_already_friend_390x844.png": SOCIAL / "already_friend_390x844.png",
    "add_friend/08_search_loading_390x844.png": SOCIAL / "friends_search_loading_390x844.png",
    "add_friend/09_search_error_390x844.png": SOCIAL / "friends_search_error_390x844.png",
    "blocked/01_block_confirmation_390x844.png": SOCIAL / "block_confirmation_390x844.png",
    "blocked/02_blocked_players_390x844.png": SOCIAL / "blocked_players_populated_390x844.png",
    "blocked/03_blocked_empty_390x844.png": SOCIAL / "blocked_players_empty_390x844.png",
    "blocked/04_unblock_390x844.png": SOCIAL / "unblock_state_390x844.png",
    "team_detail/01_team_detail_390x844.png": SOCIAL / "team_detail_390x844.png",
    "ranking/01_ranking_390x844.png": SOCIAL / "ranking_390x844.png",
    "profile/01_profile_social_390x844.png": SOCIAL / "profile_social_connection_390x844.png",
    "settings/01_settings_signed_in_390x844.png": ADVANCED / "settings" / "settings_signed_in_390x844.png",
    "settings/02_settings_guest_390x844.png": ADVANCED / "settings" / "settings_guest_390x844.png",
    "settings/03_settings_premium_subscriber_390x844.png": ADVANCED / "settings" / "settings_subscriber_390x844.png",
    "settings/04_settings_compact_360x800.png": ADVANCED / "settings" / "settings_compact_360x800.png",
    "settings/05_support_legal_logout_390x844.png": ADVANCED / "settings" / "settings_signed_in_bottom_390x844.png",
    "premium/01_premium_monthly_390x844.png": PREMIUM / "premium_monthly_selected_390x844.png",
    "premium/02_premium_annual_390x844.png": PREMIUM / "premium_annual_selected_390x844.png",
    "premium/03_premium_active_subscriber_390x844.png": PREMIUM / "premium_active_subscriber_390x844.png",
    "premium/04_premium_loading_390x844.png": PREMIUM / "premium_packages_loading_390x844.png",
    "premium/05_premium_unavailable_390x844.png": PREMIUM / "premium_packages_unavailable_390x844.png",
    "premium/06_premium_purchase_loading_390x844.png": PREMIUM / "premium_purchase_loading_390x844.png",
    "premium/07_category_locked_390x844.png": PREMIUM / "premium_category_locked_390x844.png",
    "premium/08_category_unlocked_390x844.png": PREMIUM / "premium_category_unlocked_390x844.png",
    "premium/09_category_gate_390x844.png": PREMIUM / "premium_category_gate_390x844.png",
    "voucher/01_premium_voucher_entry_390x844.png": VOUCHER / "premium_voucher_entry_390x844.png",
    "voucher/02_voucher_form_390x844.png": VOUCHER / "voucher_form_390x844.png",
    "voucher/03_voucher_keyboard_390x844.png": VOUCHER / "voucher_typing_390x844.png",
    "voucher/04_voucher_validating_390x844.png": VOUCHER / "voucher_validating_390x844.png",
    "voucher/05_voucher_invalid_390x844.png": VOUCHER / "voucher_invalid_390x844.png",
    "voucher/06_voucher_used_390x844.png": VOUCHER / "voucher_used_390x844.png",
    "voucher/07_voucher_success_monthly_390x844.png": VOUCHER / "voucher_success_monthly_390x844.png",
    "voucher/08_voucher_success_annual_390x844.png": VOUCHER / "voucher_success_annual_390x844.png",
    "voucher/09_premium_active_via_voucher_390x844.png": VOUCHER / "premium_active_via_voucher_390x844.png",
    "voucher/10_voucher_guest_gate_390x844.png": VOUCHER / "voucher_auth_gate_guest_390x844.png",
    "admin/01_voucher_dashboard_1440x1800.png": ADMIN / "voucher_dashboard_1440x1800.png",
    "admin/02_voucher_creation_1440x1800.png": ADMIN / "create_voucher_monthly_1440x1800.png",
    "admin/03_monthly_selected_1440x1800.png": ADMIN / "create_voucher_monthly_1440x1800.png",
    "admin/04_annual_selected_1440x1800.png": ADMIN / "create_voucher_annual_1440x1800.png",
    "admin/05_code_generated_1440x1800.png": ADMIN / "voucher_created_copy_code_1440x1800.png",
    "admin/06_copy_code_1440x1800.png": ADMIN / "voucher_created_copy_code_1440x1800.png",
    "admin/10_admin_empty_1440x1800.png": ADMIN / "admin_empty_1440x1800.png",
    "guest/01_social_guest_gate_390x844.png": VOUCHER / "voucher_auth_gate_guest_390x844.png",
    "guest/02_settings_guest_390x844.png": ADVANCED / "settings" / "settings_guest_390x844.png",
    "empty_states/01_friends_empty_390x844.png": SOCIAL / "friends_empty_390x844.png",
    "empty_states/02_blocked_empty_390x844.png": SOCIAL / "blocked_players_empty_390x844.png",
    "empty_states/03_editorial_empty_state.png": ADVANCED / "empty_states" / "editorial_empty_state.png",
    "loading/01_friends_loading_390x844.png": SOCIAL / "friends_loading_390x844.png",
    "loading/02_search_loading_390x844.png": SOCIAL / "friends_search_loading_390x844.png",
    "loading/03_voucher_validating_390x844.png": VOUCHER / "voucher_validating_390x844.png",
    "loading/04_premium_loading_390x844.png": PREMIUM / "premium_packages_loading_390x844.png",
    "loading/05_contextual_loading.png": ADVANCED / "loading_states" / "contextual_loading.png",
    "error/01_friends_error_390x844.png": SOCIAL / "friends_error_390x844.png",
    "error/02_search_error_390x844.png": SOCIAL / "friends_search_error_390x844.png",
    "error/03_voucher_invalid_390x844.png": VOUCHER / "voucher_invalid_390x844.png",
    "error/04_voucher_used_390x844.png": VOUCHER / "voucher_used_390x844.png",
    "error/05_premium_unavailable_390x844.png": PREMIUM / "premium_packages_unavailable_390x844.png",
    "error/06_editorial_error_state.png": ADVANCED / "error_states" / "editorial_error_state.png",
    "motion_keyframes/01_reduced_motion_static.png": SOCIAL / "friends_primary_390x844.png",
    "motion_keyframes/02_home_hero_00.png": ADVANCED / "motion_keyframes" / "home_hero_00.png",
    "motion_keyframes/03_home_hero_50.png": ADVANCED / "motion_keyframes" / "home_hero_50.png",
    "motion_keyframes/04_home_hero_100.png": ADVANCED / "motion_keyframes" / "home_hero_100.png",
}


CROPS: dict[str, tuple[Path, tuple[int, int, int, int]]] = {
    "artwork/ahdash_friends_connection.png": (SOCIAL / "friends_primary_390x844.png", (24, 192, 166, 330)),
    "artwork/ahdash_friends_empty.png": (SOCIAL / "friends_empty_390x844.png", (43, 498, 347, 607)),
    "artwork/ahdash_blocked_empty.png": (SOCIAL / "blocked_players_empty_390x844.png", (43, 481, 347, 590)),
    "artwork/ahdash_premium_unlock.png": (PREMIUM / "premium_active_subscriber_390x844.png", (24, 104, 214, 306)),
    "artwork/ahdash_voucher_ticket.png": (VOUCHER / "voucher_form_390x844.png", (24, 127, 207, 329)),
    "artwork/ahdash_voucher_success.png": (VOUCHER / "voucher_success_monthly_390x844.png", (24, 127, 207, 329)),
    "artwork/ahdash_settings_account.png": (ADVANCED / "settings" / "settings_signed_in_390x844.png", (24, 128, 176, 298)),
    "details/01_friends_hero.png": (SOCIAL / "friends_primary_390x844.png", (24, 192, 366, 330)),
    "details/02_search_field.png": (SOCIAL / "friends_search_results_390x844.png", (24, 344, 366, 438)),
    "details/03_friend_row.png": (SOCIAL / "friends_search_results_390x844.png", (24, 492, 366, 566)),
    "details/04_team_identity.png": (SOCIAL / "team_detail_390x844.png", (24, 192, 366, 505)),
    "details/05_ranking_table.png": (SOCIAL / "ranking_390x844.png", (24, 352, 366, 566)),
    "details/06_profile_identity.png": (SOCIAL / "profile_social_connection_390x844.png", (24, 126, 366, 330)),
    "details/07_settings_account.png": (ADVANCED / "settings" / "settings_signed_in_390x844.png", (24, 127, 366, 430)),
    "details/08_settings_premium.png": (ADVANCED / "settings" / "settings_signed_in_390x844.png", (24, 690, 366, 842)),
    "details/09_settings_support_legal.png": (ADVANCED / "settings" / "settings_signed_in_bottom_390x844.png", (24, 250, 366, 650)),
    "details/10_settings_logout.png": (ADVANCED / "settings" / "settings_signed_in_bottom_390x844.png", (24, 650, 366, 842)),
    "details/11_premium_hero.png": (PREMIUM / "premium_monthly_selected_390x844.png", (24, 104, 366, 306)),
    "details/12_premium_benefits.png": (PREMIUM / "premium_monthly_selected_390x844.png", (24, 344, 366, 489)),
    "details/13_premium_plans.png": (PREMIUM / "premium_monthly_selected_390x844.png", (24, 522, 366, 647)),
    "details/14_voucher_field.png": (VOUCHER / "voucher_form_390x844.png", (24, 349, 366, 613)),
    "details/15_voucher_success.png": (VOUCHER / "voucher_success_monthly_390x844.png", (24, 127, 366, 559)),
    "details/16_admin_create.png": (ADMIN / "create_voucher_monthly_1440x1800.png", (975, 395, 1340, 930)),
    "details/17_admin_status_table.png": (ADMIN / "voucher_dashboard_1440x1800.png", (75, 395, 970, 760)),
    "details/18_admin_one_time_code.png": (ADMIN / "voucher_created_copy_code_1440x1800.png", (75, 35, 1340, 465)),
    "admin/07_unused_table_state.png": (ADMIN / "voucher_dashboard_1440x1800.png", (75, 495, 970, 625)),
    "admin/08_redeemed_table_state.png": (ADMIN / "voucher_dashboard_1440x1800.png", (75, 555, 970, 685)),
    "admin/09_disabled_table_state.png": (ADMIN / "voucher_dashboard_1440x1800.png", (75, 670, 970, 805)),
}


DIRECT_ARTWORK = {
    "artwork/ahdash_premium_categories.png": ADVANCED / "artwork" / "premium_unlocked_categories.png",
    "artwork/ahdash_ads_free.png": ADVANCED / "artwork" / "premium_ads_free_flow.png",
}


COMPARISONS: dict[str, tuple[Path, Path]] = {
    "friends": (PREVIOUS / "friends" / "friends_primary_390x844.png", SOCIAL / "friends_primary_390x844.png"),
    "add_friend": (PREVIOUS / "add_friend" / "friends_search_results_390x844.png", SOCIAL / "friends_search_results_390x844.png"),
    "blocked_players": (PREVIOUS / "blocked" / "blocked_players_populated_390x844.png", SOCIAL / "blocked_players_populated_390x844.png"),
    "team_detail": (PREVIOUS / "team_detail" / "team_detail_390x844.png", SOCIAL / "team_detail_390x844.png"),
    "ranking": (PREVIOUS / "ranking" / "ranking_390x844.png", SOCIAL / "ranking_390x844.png"),
    "profile": (PREVIOUS / "profile" / "profile_social_connection_390x844.png", SOCIAL / "profile_social_connection_390x844.png"),
    "settings": (PREVIOUS_ADVANCED / "settings" / "01_settings_signed_in_390x844.png", ADVANCED / "settings" / "settings_signed_in_390x844.png"),
    "premium_voucher": (PREVIOUS / "premium_voucher" / "voucher_form_390x844.png", VOUCHER / "voucher_form_390x844.png"),
    "admin_voucher_dashboard": (PREVIOUS / "admin_vouchers" / "voucher_management_1440x1800.png", ADMIN / "voucher_dashboard_1440x1800.png"),
}


FOLDERS = [
    "friends", "add_friend", "blocked", "team_detail", "ranking", "profile",
    "settings", "premium", "voucher", "admin", "guest", "empty_states",
    "loading", "error", "artwork", "details", "before_after", "motion_keyframes",
]


def ensure_inputs() -> None:
    paths = list(COPY_MAP.values()) + list(DIRECT_ARTWORK.values())
    paths += [source for source, _ in CROPS.values()]
    paths += [item for pair in COMPARISONS.values() for item in pair]
    missing = sorted({path for path in paths if not path.is_file()})
    if missing:
        raise FileNotFoundError("Missing inputs:\n" + "\n".join(map(str, missing)))


def copy_inputs() -> None:
    for relative, source in {**COPY_MAP, **DIRECT_ARTWORK}.items():
        destination = OUTPUT / relative
        destination.parent.mkdir(parents=True, exist_ok=True)
        copy2(source, destination)


def create_crops() -> None:
    for relative, (source, box) in CROPS.items():
        destination = OUTPUT / relative
        destination.parent.mkdir(parents=True, exist_ok=True)
        with Image.open(source).convert("RGB") as image:
            bounded = (
                max(0, box[0]), max(0, box[1]),
                min(image.width, box[2]), min(image.height, box[3]),
            )
            image.crop(bounded).save(destination, optimize=True)


def create_comparisons() -> None:
    folder = OUTPUT / "before_after"
    folder.mkdir(parents=True, exist_ok=True)
    font = ImageFont.load_default(size=18)
    for name, (before_source, after_source) in COMPARISONS.items():
        before_copy = folder / f"{name}_before.png"
        after_copy = folder / f"{name}_after.png"
        copy2(before_source, before_copy)
        copy2(after_source, after_copy)
        with Image.open(before_source).convert("RGB") as before, Image.open(after_source).convert("RGB") as after:
            target_height = max(before.height, after.height)
            before.thumbnail((before.width, target_height))
            after.thumbnail((after.width, target_height))
            label_height = 44
            sheet = Image.new("RGB", (before.width + after.width, target_height + label_height), "#fbf7ef")
            sheet.paste(before, (0, label_height))
            sheet.paste(after, (before.width, label_height))
            draw = ImageDraw.Draw(sheet)
            draw.text((16, 13), "BEFORE", fill="#756e63", font=font)
            draw.text((before.width + 16, 13), "AFTER / AHDASH 11", fill="#191714", font=font)
            draw.line((before.width, 0, before.width, sheet.height), fill="#d3c6b2", width=2)
            sheet.save(folder / f"{name}_before_after.png", optimize=True)


def write_inventory() -> None:
    rows = ["path\twidth\theight\tbytes\tsha256_12"]
    for path in sorted(OUTPUT.rglob("*.png")):
        with Image.open(path) as image:
            width, height = image.size
        digest = hashlib.sha256(path.read_bytes()).hexdigest()[:12]
        rows.append(f"{path.relative_to(OUTPUT).as_posix()}\t{width}\t{height}\t{path.stat().st_size}\t{digest}")
    (OUTPUT / "IMAGE_INVENTORY.tsv").write_text("\n".join(rows) + "\n", encoding="utf-8")


def write_index() -> None:
    groups: list[str] = []
    for folder in FOLDERS:
        files = sorted((OUTPUT / folder).glob("*.png"))
        if not files:
            continue
        cards = "".join(
            f'<a class="card" href="{html.escape(path.relative_to(OUTPUT).as_posix())}">'
            f'<img loading="lazy" src="{html.escape(path.relative_to(OUTPUT).as_posix())}" alt="{html.escape(path.stem)}">'
            f'<span>{html.escape(path.stem.replace("_", " "))}</span></a>'
            for path in files
        )
        groups.append(f'<section id="{folder}"><h2>{folder.replace("_", " ")}</h2><div class="grid">{cards}</div></section>')
    count = len(list(OUTPUT.rglob("*.png")))
    document = f"""<!doctype html>
<html lang="ar" dir="rtl"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>AHDASH 11 — Social + Voucher Visual Redesign</title><style>
:root{{--paper:#fbf7ef;--paper2:#ebdfc9;--ink:#191714;--muted:#756e63;--line:#d3c6b2;--green:#b6ff3b;--gold:#ffc857}}
*{{box-sizing:border-box}}body{{margin:0;background:var(--paper);color:var(--ink);font-family:Arial,"Segoe UI",sans-serif}}
header{{padding:52px clamp(24px,6vw,86px);background:var(--ink);color:var(--paper);border-right:8px solid var(--gold)}}
.eyebrow{{direction:ltr;color:var(--green);font-size:12px;font-weight:900;letter-spacing:.18em}}h1{{font-size:clamp(34px,6vw,70px);line-height:1;margin:18px 0}}header p{{max-width:800px;color:#ddceb5;line-height:1.8}}
nav{{position:sticky;top:0;z-index:5;display:flex;gap:8px;overflow:auto;padding:12px clamp(16px,4vw,56px);background:rgba(251,247,239,.95);border-bottom:1px solid var(--line)}}nav a{{white-space:nowrap;border:1px solid var(--line);border-radius:999px;padding:8px 13px;color:var(--ink);text-decoration:none;font-size:12px;font-weight:800}}
main{{padding:24px clamp(16px,4vw,56px) 80px}}section{{margin-top:42px}}h2{{text-transform:uppercase;direction:ltr;letter-spacing:.12em;font-size:14px;border-right:5px solid var(--green);padding-right:12px}}.grid{{display:grid;grid-template-columns:repeat(auto-fill,minmax(220px,1fr));gap:18px}}
.card{{overflow:hidden;border:1px solid var(--line);border-radius:18px;background:white;color:var(--ink);text-decoration:none;box-shadow:0 8px 26px rgba(25,23,20,.06)}}.card img{{width:100%;height:280px;display:block;object-fit:contain;background:#f4ebdd}}.card span{{display:block;padding:13px;direction:ltr;text-align:left;font-size:12px;font-weight:800;overflow-wrap:anywhere}}
.facts{{display:flex;gap:14px;flex-wrap:wrap;margin-top:24px}}.fact{{border:1px solid #4d493f;background:#24211d;border-radius:14px;padding:14px 18px}}.fact strong{{display:block;color:var(--green);font-size:24px}}footer{{padding:30px;text-align:center;color:var(--muted);border-top:1px solid var(--line)}}
</style></head><body><header><div class="eyebrow">AHDASH / VISUAL REVIEW 11</div><h1>Social + Voucher<br>Visual Redesign</h1><p>حزمة مراجعة محلية ثابتة للرندرات الحالية، تشمل الشاشات والحالات والتفاصيل والأعمال الأصلية ومقارنات قبل/بعد. لا تحتوي على صور stock أو شعارات أندية أو بيانات إنتاج.</p><div class="facts"><div class="fact"><strong>{count}</strong>PNG evidence</div><div class="fact"><strong>18</strong>review sections</div><div class="fact"><strong>0</strong>external dependencies</div></div></header>
<nav>{''.join(f'<a href="#{folder}">{folder.replace("_", " ")}</a>' for folder in FOLDERS)}</nav><main>{''.join(groups)}</main>
<footer>AHDASH | 11 · Local visual review pack · Current code renders</footer></body></html>"""
    (OUTPUT / "INDEX.html").write_text(document, encoding="utf-8")


def main() -> None:
    ensure_inputs()
    for folder in FOLDERS:
        (OUTPUT / folder).mkdir(parents=True, exist_ok=True)
    copy_inputs()
    create_crops()
    create_comparisons()
    write_inventory()
    write_index()
    print(f"Built {len(list(OUTPUT.rglob('*.png')))} PNG evidence files in {OUTPUT}")


if __name__ == "__main__":
    main()
