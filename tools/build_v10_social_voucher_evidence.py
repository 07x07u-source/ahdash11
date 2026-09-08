"""Build the local Phase V10 social/voucher visual review pack.

The inputs are deterministic screenshots captured from current Flutter widgets
and the local Next.js development-only review surface. No Figma reference or
archived golden is modified by this script.
"""

from __future__ import annotations

from pathlib import Path
from shutil import copy2

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "tmp" / "v10_social_voucher_review"
OUTPUT = ROOT / "docs" / "v10_social_voucher_refinement"
MOBILE_GOLDENS = ROOT / "mobile" / "test" / "visual" / "goldens"


COPY_MAP = {
    "friends/friends_primary_390x844.png": "social/friends_primary_390x844.png",
    "friends/friends_compact_360x800.png": "social/friends_compact_360x800.png",
    "empty_states/friends_empty_390x844.png": "social/friends_empty_390x844.png",
    "loading/friends_loading_390x844.png": "social/friends_loading_390x844.png",
    "errors/friends_error_390x844.png": "social/friends_error_390x844.png",
    "add_friend/friends_search_390x844.png": "social/friends_search_results_390x844.png",
    "add_friend/friends_search_keyboard_390x844.png": "social/friends_search_keyboard_390x844.png",
    "add_friend/friends_search_results_390x844.png": "social/friends_search_results_390x844.png",
    "add_friend/friends_no_results_390x844.png": "social/friends_no_results_390x844.png",
    "add_friend/add_friend_available_390x844.png": "social/add_friend_available_390x844.png",
    "add_friend/friend_added_390x844.png": "social/friend_added_390x844.png",
    "add_friend/already_friend_390x844.png": "social/already_friend_390x844.png",
    "loading/friends_search_loading_390x844.png": "social/friends_search_loading_390x844.png",
    "errors/friends_search_error_390x844.png": "social/friends_search_error_390x844.png",
    "blocked/block_confirmation_390x844.png": "social/block_confirmation_390x844.png",
    "blocked/blocked_players_populated_390x844.png": "social/blocked_players_populated_390x844.png",
    "blocked/blocked_players_empty_390x844.png": "social/blocked_players_empty_390x844.png",
    "blocked/unblock_state_390x844.png": "social/unblock_state_390x844.png",
    "empty_states/blocked_players_empty_390x844.png": "social/blocked_players_empty_390x844.png",
    "team_detail/team_detail_390x844.png": "social/team_detail_390x844.png",
    "ranking/ranking_390x844.png": "social/ranking_390x844.png",
    "profile/profile_social_connection_390x844.png": "social/profile_social_connection_390x844.png",
    "premium_voucher/premium_voucher_entry_390x844.png": "voucher/premium_voucher_entry_390x844.png",
    "premium_voucher/voucher_form_390x844.png": "voucher/voucher_form_390x844.png",
    "premium_voucher/voucher_typing_390x844.png": "voucher/voucher_typing_390x844.png",
    "premium_voucher/voucher_validating_390x844.png": "voucher/voucher_validating_390x844.png",
    "premium_voucher/voucher_invalid_390x844.png": "voucher/voucher_invalid_390x844.png",
    "premium_voucher/voucher_used_390x844.png": "voucher/voucher_used_390x844.png",
    "premium_voucher/voucher_success_monthly_390x844.png": "voucher/voucher_success_monthly_390x844.png",
    "premium_voucher/voucher_success_annual_390x844.png": "voucher/voucher_success_annual_390x844.png",
    "premium_voucher/premium_active_via_voucher_390x844.png": "voucher/premium_active_via_voucher_390x844.png",
    "premium_voucher/voucher_auth_gate_guest_390x844.png": "voucher/voucher_auth_gate_guest_390x844.png",
    "loading/voucher_validating_390x844.png": "voucher/voucher_validating_390x844.png",
    "errors/voucher_invalid_390x844.png": "voucher/voucher_invalid_390x844.png",
    "errors/voucher_used_390x844.png": "voucher/voucher_used_390x844.png",
    "admin_vouchers/voucher_management_1440x1800.png": "admin/voucher_management_1440x1800.png",
    "admin_vouchers/create_voucher_monthly_1440x1800.png": "admin/create_voucher_monthly_1440x1800.png",
    "admin_vouchers/create_voucher_annual_1440x1800.png": "admin/create_voucher_annual_1440x1800.png",
    "admin_vouchers/voucher_created_copy_code_1440x1800.png": "admin/voucher_created_copy_code_1440x1800.png",
}


CROPS = {
    "details/friend_row_detail.png": ("social/friends_search_results_390x844.png", (16, 402, 374, 518)),
    "details/search_detail.png": ("social/friends_search_results_390x844.png", (12, 294, 378, 592)),
    "details/add_action_detail.png": ("social/friends_search_results_390x844.png", (16, 402, 374, 510)),
    "details/voucher_field_button_detail.png": ("voucher/voucher_form_390x844.png", (14, 310, 376, 586)),
    "admin_vouchers/create_monthly_detail.png": ("admin/create_voucher_monthly_1440x1800.png", (735, 292, 1110, 800)),
    "admin_vouchers/create_annual_detail.png": ("admin/create_voucher_annual_1440x1800.png", (735, 292, 1110, 800)),
    "admin_vouchers/unused_voucher_table.png": ("admin/voucher_management_1440x1800.png", (20, 315, 740, 520)),
    "admin_vouchers/redeemed_voucher_table.png": ("admin/voucher_management_1440x1800.png", (20, 392, 740, 600)),
    "admin_vouchers/disabled_state.png": ("admin/voucher_management_1440x1800.png", (20, 468, 740, 670)),
    "admin_vouchers/admin_voucher_detail.png": ("admin/voucher_created_copy_code_1440x1800.png", (18, 188, 1110, 1065)),
}


BEFORE_AFTER = {
    "friends": (
        MOBILE_GOLDENS / "v10_phase_d" / "friends_390x844.png",
        SOURCE / "social" / "friends_primary_390x844.png",
    ),
    "blocked": (
        MOBILE_GOLDENS / "v10_phase_d" / "blocked_390x844.png",
        SOURCE / "social" / "blocked_players_populated_390x844.png",
    ),
    "team_detail": (
        MOBILE_GOLDENS / "v10_phase_d" / "teamDetail_390x844.png",
        SOURCE / "social" / "team_detail_390x844.png",
    ),
    "ranking": (
        MOBILE_GOLDENS / "v10_phase_d" / "ranking_390x844.png",
        SOURCE / "social" / "ranking_390x844.png",
    ),
    "profile": (
        MOBILE_GOLDENS / "v10_phase_e" / "profile_390x844.png",
        SOURCE / "social" / "profile_social_connection_390x844.png",
    ),
    "premium_voucher": (
        MOBILE_GOLDENS / "v10_phase_e" / "premium_390x844.png",
        SOURCE / "voucher" / "premium_voucher_entry_390x844.png",
    ),
}


def copy_inputs() -> None:
    for destination, source in COPY_MAP.items():
        source_path = SOURCE / source
        if not source_path.is_file():
            raise FileNotFoundError(source_path)
        destination_path = OUTPUT / destination
        destination_path.parent.mkdir(parents=True, exist_ok=True)
        copy2(source_path, destination_path)


def create_crops() -> None:
    for destination, (source, box) in CROPS.items():
        destination_path = OUTPUT / destination
        destination_path.parent.mkdir(parents=True, exist_ok=True)
        with Image.open(SOURCE / source) as image:
            image.crop(box).save(destination_path)


def create_before_after() -> None:
    folder = OUTPUT / "before_after"
    folder.mkdir(parents=True, exist_ok=True)
    font = ImageFont.load_default(size=18)
    for name, (before_path, after_path) in BEFORE_AFTER.items():
        if not before_path.is_file() or not after_path.is_file():
            raise FileNotFoundError(f"Missing comparison input for {name}")
        with Image.open(before_path).convert("RGB") as before, Image.open(
            after_path
        ).convert("RGB") as after:
            width = before.width + after.width
            height = max(before.height, after.height) + 42
            sheet = Image.new("RGB", (width, height), "#f8f4ec")
            sheet.paste(before, (0, 42))
            sheet.paste(after, (before.width, 42))
            draw = ImageDraw.Draw(sheet)
            draw.text((16, 12), "BEFORE", fill="#191714", font=font)
            draw.text((before.width + 16, 12), "AFTER", fill="#191714", font=font)
            sheet.save(folder / f"{name}_before_after.png")


def main() -> None:
    for folder in [
        "friends",
        "add_friend",
        "blocked",
        "team_detail",
        "ranking",
        "profile",
        "premium_voucher",
        "admin_vouchers",
        "details",
        "empty_states",
        "errors",
        "loading",
        "before_after",
    ]:
        (OUTPUT / folder).mkdir(parents=True, exist_ok=True)
    copy_inputs()
    create_crops()
    create_before_after()
    print(f"Built {len(list(OUTPUT.rglob('*.png')))} PNG evidence files in {OUTPUT}")


if __name__ == "__main__":
    main()
