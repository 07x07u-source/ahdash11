#!/usr/bin/env python3
"""Build the AHDASH 11 V10 visual atlas from exact logical-pixel renders.

This script only copies existing lossless PNG renders and makes pixel crops.
It never resizes or annotates a source image.
"""

from __future__ import annotations

import csv
import hashlib
import html
import json
import shutil
from collections import Counter, defaultdict
from dataclasses import dataclass
from pathlib import Path

from PIL import Image


PROJECT = Path(r"C:\dev\ahdash11")
MOBILE = PROJECT / "mobile"
SOURCE = PROJECT / "tmp" / "v10_atlas_source"
OUTPUT = PROJECT / "docs" / "v10_complete_ui_atlas"
EXPECTED_OUTPUT = Path(r"C:\dev\ahdash11\docs\v10_complete_ui_atlas")

PHASE_A = MOBILE / "test" / "visual" / "goldens" / "v10_phase_a"
AUTH_REPAIR = MOBILE / "test" / "visual" / "goldens" / "auth_ux_repair"
RESPONSIVE = SOURCE / "responsive"
HOME = SOURCE / "home"
AUTH_STATES = SOURCE / "auth_states"
STATES = SOURCE / "states"
BEFORE_AFTER = PROJECT / "docs" / "v10_ui_refinement" / "before_after"

FOLDERS = [
    "00_index",
    "01_launch_onboarding",
    "02_auth",
    "03_home",
    "04_categories",
    "05_party_setup",
    "06_party_gameplay",
    "07_saved_games",
    "08_tournament",
    "09_solo",
    "10_team_challenge",
    "11_ranking",
    "12_friends",
    "13_blocked_players",
    "14_team_detail",
    "15_profile",
    "16_notifications",
    "17_settings",
    "18_report",
    "19_football_preferences",
    "20_premium",
    "21_guest",
    "22_empty_states",
    "23_loading_states",
    "24_error_states",
    "25_keyboard",
    "26_compact",
    "27_components",
    "28_detail_crops",
    "29_before_after_if_available",
]

EXPECTED_SCREENS = [
    "01 Launch",
    "02 Onboarding",
    "03 Sign In",
    "04 Create Account",
    "05 Home",
    "06 Category Selection",
    "07 Category Detail",
    "08 Team Setup",
    "09 Team Splitter",
    "10 Helpers",
    "11 Ready",
    "12 Game Board",
    "13 Text Question",
    "14 Image Question",
    "15 Answer Reveal",
    "16 Final Result",
    "17 How to Play",
    "18 Saved Party Games",
    "19 Tournament Hub",
    "20 Create Tournament",
    "21 Tournament Teams",
    "22 Tournament Draw",
    "23 Tournament Bracket",
    "26 Tournament Match",
    "27 Tournament Champion",
    "28 Match Setup",
    "29 Solo Setup",
    "33 Team Challenge",
    "34 Ranking",
    "35 Friends",
    "36 Blocked Players",
    "37 Team Detail",
    "38 Profile",
    "39 Notifications",
    "40 Settings",
    "41 Report a Problem",
    "42 Football Preferences",
    "43 Premium",
]

INTENTIONALLY_MISSING_STATES = [
    "Category Selection: separate 0-selected, partial-selected, no-results, loading, and error frames are not exposed by the current deterministic screenshot harness.",
    "Category Detail: dedicated media-fallback and variable-metadata frames are not exposed.",
    "Team Setup: separate empty/default, validation, and optional-distribution frames are not exposed.",
    "Team Splitter: separate no-player and manual-allocation frames are not exposed; current automatic populated state is captured.",
    "Helpers: individual available/selected/consumed frames for all five helpers are not exposed separately; the three-selected summary is captured.",
    "Game Board: dedicated fresh, near-complete, completed-cell, and helper-active frames are not exposed separately.",
    "Questions: dedicated two-chances, call-friend, helper-active, and media-fallback frames are not exposed separately.",
    "Answer Reveal: Team A award, Team B award, and no-score frames are not exposed separately.",
    "Final Result: winner-B and tie frames are not exposed separately.",
    "Saved Games: one-game, resume-error, and loading frames are not exposed; empty and multiple-game fixture frames are captured.",
    "Tournament Hub: empty, loading, and error frames are not exposed.",
    "Create Tournament / Teams: dedicated filled-form and validation frames are not exposed; keyboard and current form/stage are captured.",
    "Tournament Draw / Bracket: distinct pre-draw, post-draw, and completed-bracket frames are not all exposed; draw, initial, semifinal, and final-stage frames are captured.",
    "Tournament Match: a separate completed-match frame is not exposed.",
    "Solo: only the real current limited state is captured; gameplay was not invented.",
    "Team Challenge: separate loading, unavailable, and error frames are not exposed by the visual harness.",
    "Friends: add-success, add-error, pending/duplicate, and menu-dialog frames are behavior-tested but not exposed as stable screenshots.",
    "Blocked Players: confirmation and post-unblock success frames are not exposed; populated, empty, and error frames are captured.",
    "Profile: partial, edit, validation, and save-loading frames are not exposed; normal and guest-gate frames are captured.",
    "Notifications: read/unread distinction and permission denied/granted frames are not exposed; populated, empty, loading, and error frames are captured.",
    "Settings: guest-specific settings and logout-confirmation frames are not exposed as stable screenshots.",
    "Report a Problem: filled, validation, submitting, success, and failure frames are behavior-tested but not exposed as stable screenshots.",
    "Football Preferences: separate empty, save-loading, and error frames are not exposed; selected/search keyboard state is captured.",
    "Premium: active entitlement, purchase/restore progress, success, failure, and a visually distinct unavailable frame are not exposed. The current inactive package list with monthly selection and one loading frame are captured; the harness outputs labeled packages-fixture and unavailable were byte-identical to loading, so they were not misrepresented as distinct states.",
    "Component atlas: no stable confirmation dialog screenshot exists, so a Dialog crop was not fabricated.",
]


@dataclass
class Record:
    feature: str
    screen: str
    state: str
    variant: str
    width: int
    height: int
    text_scale: str
    keyboard: bool
    fixture: bool
    filename: str
    sha256: str
    notes: str
    kind: str


records: list[Record] = []
seen_hashes: dict[str, str] = {}
deduplicated: list[dict[str, str]] = []


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def _reset_output() -> None:
    if OUTPUT.resolve() != EXPECTED_OUTPUT.resolve():
        raise RuntimeError(f"Refusing to reset unexpected output path: {OUTPUT}")
    if OUTPUT.exists():
        shutil.rmtree(OUTPUT)
    for folder in FOLDERS:
        (OUTPUT / folder).mkdir(parents=True, exist_ok=True)


def _register(
    path: Path,
    *,
    feature: str,
    screen: str,
    state: str,
    variant: str,
    text_scale: str,
    keyboard: bool,
    fixture: bool,
    notes: str,
    kind: str,
) -> bool:
    with Image.open(path) as image:
        image.verify()
    with Image.open(path) as image:
        width, height = image.size
        if image.format != "PNG" or width <= 0 or height <= 0:
            raise RuntimeError(f"Invalid PNG output: {path}")
    digest = _sha256(path)
    relative = path.relative_to(OUTPUT).as_posix()
    if digest in seen_hashes:
        duplicate_of = seen_hashes[digest]
        path.unlink()
        deduplicated.append({"skipped": relative, "duplicate_of": duplicate_of})
        return False
    seen_hashes[digest] = relative
    records.append(
        Record(
            feature=feature,
            screen=screen,
            state=state,
            variant=variant,
            width=width,
            height=height,
            text_scale=text_scale,
            keyboard=keyboard,
            fixture=fixture,
            filename=relative,
            sha256=digest,
            notes=notes,
            kind=kind,
        )
    )
    return True


def add_full(
    source: Path,
    destination: str,
    *,
    feature: str,
    screen: str,
    state: str,
    variant: str = "Primary",
    text_scale: str = "1.0",
    keyboard: bool = False,
    fixture: bool = False,
    notes: str = "Exact logical-pixel Flutter render; copied losslessly.",
    kind: str = "full",
) -> None:
    if not source.is_file():
        raise FileNotFoundError(source)
    target = OUTPUT / destination
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(source, target)
    _register(
        target,
        feature=feature,
        screen=screen,
        state=state,
        variant=variant,
        text_scale=text_scale,
        keyboard=keyboard,
        fixture=fixture,
        notes=notes,
        kind=kind,
    )


def add_crop(
    source_relative: str,
    destination: str,
    box: tuple[int, int, int, int],
    *,
    feature: str,
    screen: str,
    state: str,
    kind: str,
    fixture: bool,
    notes: str,
) -> None:
    source = OUTPUT / source_relative
    if not source.is_file():
        raise FileNotFoundError(source)
    target = OUTPUT / destination
    target.parent.mkdir(parents=True, exist_ok=True)
    with Image.open(source) as image:
        left, top, right, bottom = box
        left = max(0, min(left, image.width - 1))
        top = max(0, min(top, image.height - 1))
        right = max(left + 1, min(right, image.width))
        bottom = max(top + 1, min(bottom, image.height))
        image.crop((left, top, right, bottom)).save(target, "PNG")
    _register(
        target,
        feature=feature,
        screen=screen,
        state=state,
        variant="Component crop" if kind == "component" else "Detail crop",
        text_scale="1.0",
        keyboard=False,
        fixture=fixture,
        notes=f"{notes} Exact crop {box} from {source_relative}; no resize or annotation.",
        kind=kind,
    )


def responsive(group: str, stem: str, size: str = "390x844", scale: str = "1.0") -> Path:
    return RESPONSIVE / group / f"{stem}_{size}_scale{scale}.png"


def home(stem: str, size: str = "390x844", scale: str = "1.0") -> Path:
    return HOME / f"{stem}_{size}_scale{scale}.png"


def _add_primary_screens() -> None:
    add_full(PHASE_A / "launch_390x844.png", "01_launch_onboarding/01_launch_primary_390x844.png", feature="Launch & Onboarding", screen="01 Launch", state="Default")
    for step in range(1, 5):
        add_full(PHASE_A / f"onboarding{step}_390x844.png", f"01_launch_onboarding/02_onboarding_step_{step}_primary_390x844.png", feature="Launch & Onboarding", screen="02 Onboarding", state=f"Step {step}")

    add_full(AUTH_REPAIR / "03_sign_in_primary_390x844.png", "02_auth/03_sign_in_empty_primary_390x844.png", feature="Authentication", screen="03 Sign In", state="Empty / Google available / password hidden")
    add_full(AUTH_REPAIR / "04_create_account_primary_390x844.png", "02_auth/04_create_account_empty_primary_390x844.png", feature="Authentication", screen="04 Create Account", state="Empty / social auth / password hidden")
    add_full(home("home_account"), "03_home/05_home_signed_in_primary_390x844.png", feature="Home", screen="05 Home", state="Signed in", fixture=True)

    party = [
        ("06_categories", "04_categories/06_category_selection_six_selected_primary_390x844.png", "Categories", "06 Category Selection", "Six selected"),
        ("07_detail", "04_categories/07_category_detail_populated_primary_390x844.png", "Categories", "07 Category Detail", "Populated"),
        ("08_teams", "05_party_setup/08_team_setup_populated_primary_390x844.png", "Party Setup", "08 Team Setup", "Populated"),
        ("09_splitter", "05_party_setup/09_team_splitter_automatic_primary_390x844.png", "Party Setup", "09 Team Splitter", "Automatic populated"),
        ("10_helpers", "05_party_setup/10_helpers_three_selected_primary_390x844.png", "Party Setup", "10 Helpers", "Three selected"),
        ("11_ready", "05_party_setup/11_ready_full_summary_primary_390x844.png", "Party Setup", "11 Ready", "Full summary"),
        ("12_board", "06_party_gameplay/12_game_board_mid_game_primary_390x844.png", "Party Gameplay", "12 Game Board", "Mid-game"),
        ("13_text", "06_party_gameplay/13_text_question_timer_active_primary_390x844.png", "Party Gameplay", "13 Text Question", "Timer active"),
        ("14_image", "06_party_gameplay/14_image_question_loaded_primary_390x844.png", "Party Gameplay", "14 Image Question", "Loaded image"),
        ("15_reveal", "06_party_gameplay/15_answer_reveal_scoring_primary_390x844.png", "Party Gameplay", "15 Answer Reveal", "Correct answer and scoring"),
        ("16_result", "06_party_gameplay/16_final_result_winner_a_primary_390x844.png", "Party Gameplay", "16 Final Result", "Winner A"),
    ]
    for stem, dest, feature, screen, state in party:
        add_full(responsive("party", stem), dest, feature=feature, screen=screen, state=state, fixture=True)

    account = [
        ("howTo", "07_saved_games/17_how_to_play_primary_390x844.png", "Saved Games & Help", "17 How to Play", "Default"),
        ("savedGames", "07_saved_games/18_saved_party_games_primary_390x844.png", "Saved Games & Help", "18 Saved Party Games", "Current list"),
        ("matchSetup", "09_solo/28_match_setup_primary_390x844.png", "Solo", "28 Match Setup", "Default"),
        ("solo", "09_solo/29_solo_setup_limited_primary_390x844.png", "Solo", "29 Solo Setup", "Limited"),
        ("teamChallenge", "10_team_challenge/33_team_challenge_primary_390x844.png", "Team Challenge", "33 Team Challenge", "Current availability"),
        ("ranking", "11_ranking/34_ranking_primary_390x844.png", "Ranking", "34 Ranking", "Current"),
        ("friends", "12_friends/35_friends_primary_390x844.png", "Friends", "35 Friends", "Search idle"),
        ("blocked", "13_blocked_players/36_blocked_players_primary_390x844.png", "Blocked Players", "36 Blocked Players", "Current"),
        ("teamDetail", "14_team_detail/37_team_detail_primary_390x844.png", "Team Detail", "37 Team Detail", "Current"),
        ("profile", "15_profile/38_profile_primary_390x844.png", "Profile", "38 Profile", "Normal"),
        ("notifications", "16_notifications/39_notifications_primary_390x844.png", "Notifications", "39 Notifications", "Current"),
        ("settings", "17_settings/40_settings_signed_in_primary_390x844.png", "Settings", "40 Settings", "Signed in"),
        ("report", "18_report/41_report_problem_empty_primary_390x844.png", "Report", "41 Report a Problem", "Empty form"),
        ("football", "19_football_preferences/42_football_preferences_selected_primary_390x844.png", "Football Preferences", "42 Football Preferences", "Selected"),
        ("premium", "20_premium/43_premium_inactive_primary_390x844.png", "Premium", "43 Premium", "Inactive entitlement / packages available / monthly selected"),
    ]
    for stem, dest, feature, screen, state in account:
        add_full(responsive("account", stem), dest, feature=feature, screen=screen, state=state, fixture=True)

    tournament = [
        ("hub", "08_tournament/19_tournament_hub_populated_primary_390x844.png", "Tournament", "19 Tournament Hub", "Populated"),
        ("create", "08_tournament/20_create_tournament_form_primary_390x844.png", "Tournament", "20 Create Tournament", "Form"),
        ("teams", "08_tournament/21_tournament_teams_populated_primary_390x844.png", "Tournament", "21 Tournament Teams", "Populated"),
        ("draw", "08_tournament/22_tournament_draw_primary_390x844.png", "Tournament", "22 Tournament Draw", "Draw"),
        ("bracket", "08_tournament/23_tournament_bracket_initial_primary_390x844.png", "Tournament", "23 Tournament Bracket", "Initial"),
        ("semifinal", "08_tournament/23_tournament_bracket_semifinals_primary_390x844.png", "Tournament", "23 Tournament Bracket", "Semifinals"),
        ("finalMatch", "08_tournament/23_tournament_bracket_final_primary_390x844.png", "Tournament", "23 Tournament Bracket", "Final stage"),
        ("match", "08_tournament/26_tournament_match_active_primary_390x844.png", "Tournament", "26 Tournament Match", "Active"),
        ("champion", "08_tournament/27_tournament_champion_primary_390x844.png", "Tournament", "27 Tournament Champion", "Champion"),
    ]
    for stem, dest, feature, screen, state in tournament:
        add_full(responsive("tournament", stem), dest, feature=feature, screen=screen, state=state, fixture=True)


def _add_compact_screens() -> None:
    add_full(PHASE_A / "launch_360x800.png", "26_compact/01_launch_compact_360x800.png", feature="Launch & Onboarding", screen="01 Launch", state="Default", variant="Compact")
    for step in range(1, 5):
        add_full(PHASE_A / f"onboarding{step}_360x800.png", f"26_compact/02_onboarding_step_{step}_compact_360x800.png", feature="Launch & Onboarding", screen="02 Onboarding", state=f"Step {step}", variant="Compact")
    add_full(AUTH_REPAIR / "03_sign_in_compact_360x800.png", "26_compact/03_sign_in_compact_360x800.png", feature="Authentication", screen="03 Sign In", state="Empty", variant="Compact")
    add_full(AUTH_REPAIR / "04_create_account_compact_360x800.png", "26_compact/04_create_account_compact_360x800.png", feature="Authentication", screen="04 Create Account", state="Empty", variant="Compact")
    add_full(home("home_account", "360x800"), "26_compact/05_home_signed_in_compact_360x800.png", feature="Home", screen="05 Home", state="Signed in", variant="Compact", fixture=True)

    maps = [
        ("party", "06_categories", "06_category_selection_compact_360x800.png", "Categories", "06 Category Selection"),
        ("party", "07_detail", "07_category_detail_compact_360x800.png", "Categories", "07 Category Detail"),
        ("party", "08_teams", "08_team_setup_compact_360x800.png", "Party Setup", "08 Team Setup"),
        ("party", "09_splitter", "09_team_splitter_compact_360x800.png", "Party Setup", "09 Team Splitter"),
        ("party", "10_helpers", "10_helpers_compact_360x800.png", "Party Setup", "10 Helpers"),
        ("party", "11_ready", "11_ready_compact_360x800.png", "Party Setup", "11 Ready"),
        ("party", "12_board", "12_game_board_compact_360x800.png", "Party Gameplay", "12 Game Board"),
        ("party", "13_text", "13_text_question_compact_360x800.png", "Party Gameplay", "13 Text Question"),
        ("party", "14_image", "14_image_question_compact_360x800.png", "Party Gameplay", "14 Image Question"),
        ("party", "15_reveal", "15_answer_reveal_compact_360x800.png", "Party Gameplay", "15 Answer Reveal"),
        ("party", "16_result", "16_final_result_compact_360x800.png", "Party Gameplay", "16 Final Result"),
        ("account", "howTo", "17_how_to_play_compact_360x800.png", "Saved Games & Help", "17 How to Play"),
        ("account", "savedGames", "18_saved_games_compact_360x800.png", "Saved Games & Help", "18 Saved Party Games"),
        ("tournament", "hub", "19_tournament_hub_compact_360x800.png", "Tournament", "19 Tournament Hub"),
        ("tournament", "create", "20_create_tournament_compact_360x800.png", "Tournament", "20 Create Tournament"),
        ("tournament", "teams", "21_tournament_teams_compact_360x800.png", "Tournament", "21 Tournament Teams"),
        ("tournament", "draw", "22_tournament_draw_compact_360x800.png", "Tournament", "22 Tournament Draw"),
        ("tournament", "bracket", "23_tournament_bracket_compact_360x800.png", "Tournament", "23 Tournament Bracket"),
        ("tournament", "match", "26_tournament_match_compact_360x800.png", "Tournament", "26 Tournament Match"),
        ("tournament", "champion", "27_tournament_champion_compact_360x800.png", "Tournament", "27 Tournament Champion"),
        ("account", "matchSetup", "28_match_setup_compact_360x800.png", "Solo", "28 Match Setup"),
        ("account", "solo", "29_solo_setup_compact_360x800.png", "Solo", "29 Solo Setup"),
        ("account", "teamChallenge", "33_team_challenge_compact_360x800.png", "Team Challenge", "33 Team Challenge"),
        ("account", "ranking", "34_ranking_compact_360x800.png", "Ranking", "34 Ranking"),
        ("account", "friends", "35_friends_compact_360x800.png", "Friends", "35 Friends"),
        ("account", "blocked", "36_blocked_players_compact_360x800.png", "Blocked Players", "36 Blocked Players"),
        ("account", "teamDetail", "37_team_detail_compact_360x800.png", "Team Detail", "37 Team Detail"),
        ("account", "profile", "38_profile_compact_360x800.png", "Profile", "38 Profile"),
        ("account", "notifications", "39_notifications_compact_360x800.png", "Notifications", "39 Notifications"),
        ("account", "settings", "40_settings_compact_360x800.png", "Settings", "40 Settings"),
        ("account", "report", "41_report_compact_360x800.png", "Report", "41 Report a Problem"),
        ("account", "football", "42_football_preferences_compact_360x800.png", "Football Preferences", "42 Football Preferences"),
        ("account", "premium", "43_premium_compact_360x800.png", "Premium", "43 Premium"),
    ]
    for group, stem, name, feature, screen in maps:
        add_full(responsive(group, stem, "360x800"), f"26_compact/{name}", feature=feature, screen=screen, state="Representative", variant="Compact", fixture=True)


def _add_keyboard_and_scale() -> None:
    keyboards = [
        (AUTH_REPAIR / "03_sign_in_keyboard_390x844.png", "03_sign_in_keyboard_390x844.png", "Authentication", "03 Sign In", True),
        (AUTH_REPAIR / "04_create_account_keyboard_390x844.png", "04_create_account_keyboard_390x844.png", "Authentication", "04 Create Account", True),
        (responsive("party", "06_search_keyboard"), "06_category_search_keyboard_390x844.png", "Categories", "06 Category Selection", True),
        (responsive("party", "08_teams_keyboard"), "08_team_setup_keyboard_390x844.png", "Party Setup", "08 Team Setup", True),
        (responsive("party", "09_splitter_keyboard"), "09_team_splitter_keyboard_390x844.png", "Party Setup", "09 Team Splitter", True),
        (responsive("tournament", "create_keyboard"), "20_create_tournament_keyboard_390x844.png", "Tournament", "20 Create Tournament", True),
        (responsive("account", "friendsKeyboard"), "35_friends_search_keyboard_390x844.png", "Friends", "35 Friends", True),
        (responsive("account", "reportKeyboard"), "41_report_problem_keyboard_390x844.png", "Report", "41 Report a Problem", True),
        (responsive("account", "footballKeyboard"), "42_football_preferences_keyboard_390x844.png", "Football Preferences", "42 Football Preferences", True),
    ]
    for source, name, feature, screen, fixture in keyboards:
        add_full(source, f"25_keyboard/{name}", feature=feature, screen=screen, state="Focused field / keyboard open", variant="Keyboard", keyboard=True, fixture=fixture)

    scales = [
        (AUTH_STATES / "auth_sign_in_text_scale_1.3_390x844.png", "02_auth/03_sign_in_text_scale_1.3_390x844.png", "Authentication", "03 Sign In", True),
        (AUTH_STATES / "auth_create_account_text_scale_1.3_390x844.png", "02_auth/04_create_account_text_scale_1.3_390x844.png", "Authentication", "04 Create Account", True),
        (home("home_account", scale="1.3"), "03_home/05_home_signed_in_text_scale_1.3_390x844.png", "Home", "05 Home", True),
        (responsive("party", "06_categories", scale="1.3"), "04_categories/06_category_selection_text_scale_1.3_390x844.png", "Categories", "06 Category Selection", True),
        (responsive("party", "08_teams", scale="1.3"), "05_party_setup/08_team_setup_text_scale_1.3_390x844.png", "Party Setup", "08 Team Setup", True),
        (responsive("party", "12_board", scale="1.3"), "06_party_gameplay/12_game_board_text_scale_1.3_390x844.png", "Party Gameplay", "12 Game Board", True),
        (responsive("tournament", "bracket", scale="1.3"), "08_tournament/23_tournament_bracket_text_scale_1.3_390x844.png", "Tournament", "23 Tournament Bracket", True),
        (responsive("account", "friends", scale="1.3"), "12_friends/35_friends_text_scale_1.3_390x844.png", "Friends", "35 Friends", True),
        (responsive("account", "settings", scale="1.3"), "17_settings/40_settings_text_scale_1.3_390x844.png", "Settings", "40 Settings", True),
        (responsive("account", "premium", scale="1.3"), "20_premium/43_premium_text_scale_1.3_390x844.png", "Premium", "43 Premium", True),
    ]
    for source, dest, feature, screen, fixture in scales:
        add_full(source, dest, feature=feature, screen=screen, state="Representative", variant="Text scale", text_scale="1.3", fixture=fixture)


def _add_responsive_representatives() -> None:
    cases = [
        ("home", "home_account", "03_home", "05_home_signed_in", "Home", "05 Home"),
        ("party", "12_board", "06_party_gameplay", "12_game_board_mid_game", "Party Gameplay", "12 Game Board"),
        ("account", "friends", "12_friends", "35_friends", "Friends", "35 Friends"),
        ("account", "settings", "17_settings", "40_settings", "Settings", "40 Settings"),
        ("account", "premium", "20_premium", "43_premium", "Premium", "43 Premium"),
    ]
    for group, stem, folder, prefix, feature, screen in cases:
        for size in ("393x852", "412x915", "430x932"):
            source = home(stem, size) if group == "home" else responsive(group, stem, size)
            add_full(source, f"{folder}/{prefix}_responsive_{size}.png", feature=feature, screen=screen, state="Representative", variant=f"Responsive {size}", fixture=True)


def _add_state_screens() -> None:
    feature_states = [
        ("friends/friends_populated_fixture_390x844.png", "12_friends/35_friends_populated_fixture_primary_390x844.png", "Friends", "35 Friends", "Populated"),
        ("friends/friends_search_results_fixture_390x844.png", "12_friends/35_friends_search_results_fixture_primary_390x844.png", "Friends", "35 Friends", "Search results"),
        ("friends/friends_search_no_results_390x844.png", "12_friends/35_friends_search_no_results_primary_390x844.png", "Friends", "35 Friends", "Search no results"),
        ("blocked/blocked_players_fixture_390x844.png", "13_blocked_players/36_blocked_players_populated_fixture_primary_390x844.png", "Blocked Players", "36 Blocked Players", "Populated"),
        ("party/saved_games_multiple_fixture_390x844.png", "07_saved_games/18_saved_games_multiple_fixture_primary_390x844.png", "Saved Games & Help", "18 Saved Party Games", "Multiple games"),
        ("ranking/ranking_populated_fixture_390x844.png", "11_ranking/34_ranking_populated_fixture_primary_390x844.png", "Ranking", "34 Ranking", "Populated"),
        ("notifications/notifications_populated_fixture_390x844.png", "16_notifications/39_notifications_populated_fixture_primary_390x844.png", "Notifications", "39 Notifications", "Populated"),
    ]
    for source, dest, feature, screen, state in feature_states:
        add_full(STATES / source, dest, feature=feature, screen=screen, state=state, fixture=True)

    empty_states = [
        ("friends/friends_empty_390x844.png", "35_friends_empty_primary_390x844.png", "Friends", "35 Friends"),
        ("blocked/blocked_players_empty_390x844.png", "36_blocked_players_empty_primary_390x844.png", "Blocked Players", "36 Blocked Players"),
        ("empty_states/ranking_empty_390x844.png", "34_ranking_empty_primary_390x844.png", "Ranking", "34 Ranking"),
        ("empty_states/saved_games_empty_390x844.png", "18_saved_games_empty_primary_390x844.png", "Saved Games & Help", "18 Saved Party Games"),
        ("empty_states/notifications_empty_390x844.png", "39_notifications_empty_primary_390x844.png", "Notifications", "39 Notifications"),
    ]
    for source, name, feature, screen in empty_states:
        add_full(STATES / source, f"22_empty_states/{name}", feature=feature, screen=screen, state="Empty", fixture=True)

    loading_states = [
        (STATES / "loading/friends_loading_390x844.png", "35_friends_loading_primary_390x844.png", "Friends", "35 Friends"),
        (STATES / "loading/notifications_loading_390x844.png", "39_notifications_loading_primary_390x844.png", "Notifications", "39 Notifications"),
        (STATES / "loading/ranking_loading_390x844.png", "34_ranking_loading_primary_390x844.png", "Ranking", "34 Ranking"),
        (STATES / "premium/premium_loading_390x844.png", "43_premium_loading_primary_390x844.png", "Premium", "43 Premium"),
        (AUTH_STATES / "auth_sign_in_submitting_fixture_390x844.png", "03_sign_in_submitting_primary_390x844.png", "Authentication", "03 Sign In"),
        (AUTH_STATES / "auth_google_loading_fixture_390x844.png", "03_google_auth_loading_primary_390x844.png", "Authentication", "03 Sign In"),
    ]
    for source, name, feature, screen in loading_states:
        add_full(source, f"23_loading_states/{name}", feature=feature, screen=screen, state="Loading / submitting", fixture=True)

    error_states = [
        (STATES / "errors/friends_error_390x844.png", "35_friends_error_primary_390x844.png", "Friends", "35 Friends"),
        (STATES / "errors/blocked_players_error_390x844.png", "36_blocked_players_error_primary_390x844.png", "Blocked Players", "36 Blocked Players"),
        (STATES / "errors/notifications_error_390x844.png", "39_notifications_error_primary_390x844.png", "Notifications", "39 Notifications"),
        (STATES / "errors/ranking_error_390x844.png", "34_ranking_error_primary_390x844.png", "Ranking", "34 Ranking"),
        (AUTH_STATES / "auth_google_failure_fixture_390x844.png", "03_google_auth_failure_primary_390x844.png", "Authentication", "03 Sign In"),
    ]
    for source, name, feature, screen in error_states:
        add_full(source, f"24_error_states/{name}", feature=feature, screen=screen, state="Error", fixture=True)

    auth_states = [
        ("auth_signIn_validation_390x844.png", "03_sign_in_validation_errors_primary_390x844.png", "03 Sign In", "Validation errors", True),
        ("auth_createAccount_validation_390x844.png", "04_create_account_validation_errors_primary_390x844.png", "04 Create Account", "Validation errors", True),
        ("auth_sign_in_password_visible_390x844.png", "03_sign_in_password_visible_primary_390x844.png", "03 Sign In", "Password visible / filled", True),
        ("auth_create_account_filled_fixture_390x844.png", "04_create_account_filled_fixture_primary_390x844.png", "04 Create Account", "Filled form", True),
    ]
    for source, name, screen, state, fixture in auth_states:
        add_full(AUTH_STATES / source, f"02_auth/{name}", feature="Authentication", screen=screen, state=state, fixture=fixture)


def _add_guest_states() -> None:
    add_full(home("home_guest"), "21_guest/05_home_guest_primary_390x844.png", feature="Guest", screen="05 Home", state="Guest", fixture=True)
    add_full(home("home_guest", "360x800"), "21_guest/05_home_guest_compact_360x800.png", feature="Guest", screen="05 Home", state="Guest", variant="Compact", fixture=True)
    add_full(home("guest_auth_gate"), "21_guest/global_guest_auth_gate_primary_390x844.png", feature="Guest", screen="Auth Gate", state="Generic protected action", fixture=True)
    guest_states = [
        ("guest/guest_friends_auth_gate_390x844.png", "35_friends_guest_auth_gate_primary_390x844.png", "35 Friends"),
        ("guest/guest_blocked_players_auth_gate_390x844.png", "36_blocked_players_guest_auth_gate_primary_390x844.png", "36 Blocked Players"),
        ("guest/guest_team_challenge_auth_gate_390x844.png", "33_team_challenge_guest_auth_gate_primary_390x844.png", "33 Team Challenge"),
        ("guest/guest_profile_auth_gate_390x844.png", "38_profile_guest_auth_gate_primary_390x844.png", "38 Profile"),
    ]
    for source, name, screen in guest_states:
        add_full(STATES / source, f"21_guest/{name}", feature="Guest", screen=screen, state="Guest restricted / Auth Gate", fixture=True)


def _add_before_after() -> None:
    for source_name, screen in [
        ("account_review.png", "Account surfaces"),
        ("home_before_after.png", "05 Home"),
        ("party_review.png", "Party flow"),
        ("tournament_review.png", "Tournament flow"),
    ]:
        source = BEFORE_AFTER / source_name
        if source.is_file():
            add_full(source, f"29_before_after_if_available/{source_name}", feature="Prior visual review", screen=screen, state="Before / after evidence", variant="Existing review artifact", fixture=False, notes="Existing visual comparison artifact copied losslessly; not a newly rendered product state.", kind="before_after")


def _add_detail_crops() -> None:
    crops = [
        ("02_auth/03_sign_in_empty_primary_390x844.png", "detail__signin__brand_header.png", (0, 0, 390, 150), "Authentication", "03 Sign In", "Brand header", False),
        ("02_auth/03_sign_in_empty_primary_390x844.png", "detail__signin__social_auth.png", (18, 120, 372, 294), "Authentication", "03 Sign In", "Social auth actions", False),
        ("02_auth/03_sign_in_empty_primary_390x844.png", "detail__signin__email_password_fields.png", (20, 270, 370, 510), "Authentication", "03 Sign In", "Email and password fields", False),
        ("02_auth/03_sign_in_empty_primary_390x844.png", "detail__signin__primary_cta.png", (20, 500, 370, 635), "Authentication", "03 Sign In", "Primary CTA", False),
        ("02_auth/03_sign_in_empty_primary_390x844.png", "detail__signin__account_guest_actions.png", (20, 610, 370, 815), "Authentication", "03 Sign In", "Account switch and Guest actions", False),
        ("02_auth/04_create_account_empty_primary_390x844.png", "detail__create_account__footer_legal.png", (18, 620, 372, 844), "Authentication", "04 Create Account", "Footer and legal area", False),
        ("03_home/05_home_signed_in_primary_390x844.png", "detail__home__header.png", (0, 0, 390, 170), "Home", "05 Home", "Header", True),
        ("03_home/05_home_signed_in_primary_390x844.png", "detail__home__party_hero.png", (12, 120, 378, 410), "Home", "05 Home", "Party primary hero", True),
        ("03_home/05_home_signed_in_primary_390x844.png", "detail__home__secondary_modes.png", (12, 380, 378, 690), "Home", "05 Home", "Tournament, Solo, and Team Challenge", True),
        ("03_home/05_home_signed_in_primary_390x844.png", "detail__home__discovery_links.png", (12, 650, 378, 844), "Home", "05 Home", "Saved games and discovery links", True),
        ("04_categories/06_category_selection_six_selected_primary_390x844.png", "detail__categories__search_header.png", (0, 0, 390, 220), "Categories", "06 Category Selection", "Search and header", True),
        ("04_categories/06_category_selection_six_selected_primary_390x844.png", "detail__categories__cards_selected.png", (12, 180, 378, 640), "Categories", "06 Category Selection", "Category cards and selection", True),
        ("04_categories/06_category_selection_six_selected_primary_390x844.png", "detail__categories__counter_cta.png", (12, 610, 378, 844), "Categories", "06 Category Selection", "Selection counter and CTA", True),
        ("04_categories/07_category_detail_populated_primary_390x844.png", "detail__category_detail__media_metadata.png", (12, 110, 378, 610), "Categories", "07 Category Detail", "Media and metadata", True),
        ("04_categories/07_category_detail_populated_primary_390x844.png", "detail__category_detail__cta.png", (12, 590, 378, 844), "Categories", "07 Category Detail", "CTA area", True),
        ("05_party_setup/08_team_setup_populated_primary_390x844.png", "detail__team_setup__teams_vs_colors.png", (12, 110, 378, 650), "Party Setup", "08 Team Setup", "Team A, VS, Team B, and colors", True),
        ("05_party_setup/08_team_setup_populated_primary_390x844.png", "detail__team_setup__distribution_cta.png", (16, 620, 374, 844), "Party Setup", "08 Team Setup", "Distribution control and CTA", True),
        ("05_party_setup/09_team_splitter_automatic_primary_390x844.png", "detail__team_splitter__player_chips.png", (12, 140, 378, 650), "Party Setup", "09 Team Splitter", "Player chips and automatic allocation", True),
        ("05_party_setup/09_team_splitter_automatic_primary_390x844.png", "detail__team_splitter__cta.png", (16, 640, 374, 844), "Party Setup", "09 Team Splitter", "Primary CTA", True),
        ("05_party_setup/10_helpers_three_selected_primary_390x844.png", "detail__helpers__cards_three_selected.png", (10, 120, 380, 685), "Party Setup", "10 Helpers", "Helper cards, icons, descriptions, and selection", True),
        ("05_party_setup/10_helpers_three_selected_primary_390x844.png", "detail__helpers__selection_cta.png", (14, 650, 376, 844), "Party Setup", "10 Helpers", "Selection summary and CTA", True),
        ("05_party_setup/11_ready_full_summary_primary_390x844.png", "detail__ready__teams.png", (12, 100, 378, 300), "Party Setup", "11 Ready", "Teams summary", True),
        ("05_party_setup/11_ready_full_summary_primary_390x844.png", "detail__ready__categories_helpers.png", (12, 270, 378, 690), "Party Setup", "11 Ready", "Categories and helpers summary", True),
        ("05_party_setup/11_ready_full_summary_primary_390x844.png", "detail__ready__start_cta.png", (14, 650, 376, 844), "Party Setup", "11 Ready", "Start CTA", True),
        ("06_party_gameplay/12_game_board_mid_game_primary_390x844.png", "detail__board__score_turn.png", (0, 0, 390, 195), "Party Gameplay", "12 Game Board", "Scoreboard and turn indicator", True),
        ("06_party_gameplay/12_game_board_mid_game_primary_390x844.png", "detail__board__category_question_cells.png", (12, 165, 378, 675), "Party Gameplay", "12 Game Board", "Category headers and question cells", True),
        ("06_party_gameplay/12_game_board_mid_game_primary_390x844.png", "detail__board__helper_strip.png", (12, 640, 378, 844), "Party Gameplay", "12 Game Board", "Helper strip", True),
        ("06_party_gameplay/13_text_question_timer_active_primary_390x844.png", "detail__text_question__header_timer.png", (0, 0, 390, 225), "Party Gameplay", "13 Text Question", "Category, score, turn, and timer", True),
        ("06_party_gameplay/13_text_question_timer_active_primary_390x844.png", "detail__text_question__question.png", (12, 190, 378, 585), "Party Gameplay", "13 Text Question", "Question text", True),
        ("06_party_gameplay/13_text_question_timer_active_primary_390x844.png", "detail__text_question__helpers_reveal_cta.png", (12, 545, 378, 844), "Party Gameplay", "13 Text Question", "Helper controls and reveal CTA", True),
        ("06_party_gameplay/14_image_question_loaded_primary_390x844.png", "detail__image_question__media.png", (12, 175, 378, 610), "Party Gameplay", "14 Image Question", "Loaded image and question", True),
        ("06_party_gameplay/15_answer_reveal_scoring_primary_390x844.png", "detail__answer_reveal__answer.png", (12, 170, 378, 570), "Party Gameplay", "15 Answer Reveal", "Correct answer", True),
        ("06_party_gameplay/15_answer_reveal_scoring_primary_390x844.png", "detail__answer_reveal__scoring_next.png", (12, 520, 378, 844), "Party Gameplay", "15 Answer Reveal", "Scoring controls and next CTA", True),
        ("06_party_gameplay/16_final_result_winner_a_primary_390x844.png", "detail__final_result__winner_score.png", (12, 100, 378, 585), "Party Gameplay", "16 Final Result", "Winning team and final score", True),
        ("06_party_gameplay/16_final_result_winner_a_primary_390x844.png", "detail__final_result__actions.png", (12, 540, 378, 830), "Party Gameplay", "16 Final Result", "Primary and secondary actions", True),
        ("07_saved_games/18_saved_games_multiple_fixture_primary_390x844.png", "detail__saved_games__session_card.png", (12, 150, 378, 640), "Saved Games & Help", "18 Saved Party Games", "Session card, scores, metadata, and resume action", True),
        ("22_empty_states/18_saved_games_empty_primary_390x844.png", "detail__saved_games__empty_state.png", (20, 210, 370, 680), "Saved Games & Help", "18 Saved Party Games", "Empty state", True),
        ("08_tournament/19_tournament_hub_populated_primary_390x844.png", "detail__tournament__hub_card.png", (12, 140, 378, 590), "Tournament", "19 Tournament Hub", "Tournament card", True),
        ("08_tournament/23_tournament_bracket_initial_primary_390x844.png", "detail__tournament__bracket_nodes_connectors.png", (5, 120, 385, 715), "Tournament", "23 Tournament Bracket", "Bracket nodes and connectors", True),
        ("08_tournament/26_tournament_match_active_primary_390x844.png", "detail__tournament__match_card.png", (12, 135, 378, 650), "Tournament", "26 Tournament Match", "Active match card", True),
        ("08_tournament/27_tournament_champion_primary_390x844.png", "detail__tournament__champion_actions.png", (12, 120, 378, 800), "Tournament", "27 Tournament Champion", "Champion state and CTAs", True),
        ("12_friends/35_friends_search_results_fixture_primary_390x844.png", "detail__friends__search_results.png", (12, 110, 378, 650), "Friends", "35 Friends", "Search field, result row, avatar, relationship, and action", True),
        ("13_blocked_players/36_blocked_players_populated_fixture_primary_390x844.png", "detail__blocked_players__row_action.png", (12, 145, 378, 560), "Blocked Players", "36 Blocked Players", "Blocked row and unblock action", True),
        ("14_team_detail/37_team_detail_primary_390x844.png", "detail__team_detail__identity_members_actions.png", (10, 80, 380, 730), "Team Detail", "37 Team Detail", "Header, identity, members, and actions", True),
        ("15_profile/38_profile_primary_390x844.png", "detail__profile__avatar_identity.png", (12, 80, 378, 390), "Profile", "38 Profile", "Player 11 avatar and identity", True),
        ("15_profile/38_profile_primary_390x844.png", "detail__profile__fields_controls.png", (12, 350, 378, 760), "Profile", "38 Profile", "Identity fields and controls", True),
        ("16_notifications/39_notifications_populated_fixture_primary_390x844.png", "detail__notifications__row.png", (12, 130, 378, 580), "Notifications", "39 Notifications", "Notification rows", True),
        ("17_settings/40_settings_signed_in_primary_390x844.png", "detail__settings__account_rows.png", (12, 100, 378, 475), "Settings", "40 Settings", "Account settings rows", True),
        ("17_settings/40_settings_signed_in_primary_390x844.png", "detail__settings__legal_logout.png", (12, 430, 378, 810), "Settings", "40 Settings", "Legal links and logout", True),
        ("18_report/41_report_problem_empty_primary_390x844.png", "detail__report__form_fields.png", (12, 130, 378, 610), "Report", "41 Report a Problem", "Form fields", True),
        ("18_report/41_report_problem_empty_primary_390x844.png", "detail__report__cta.png", (16, 580, 374, 820), "Report", "41 Report a Problem", "Submission CTA", True),
        ("19_football_preferences/42_football_preferences_selected_primary_390x844.png", "detail__football__search_preferences.png", (12, 110, 378, 650), "Football Preferences", "42 Football Preferences", "Search and selected preference cards", True),
        ("19_football_preferences/42_football_preferences_selected_primary_390x844.png", "detail__football__save_cta.png", (16, 500, 374, 635), "Football Preferences", "42 Football Preferences", "Save CTA", True),
        ("20_premium/43_premium_inactive_primary_390x844.png", "detail__premium__hero_benefits.png", (0, 0, 390, 310), "Premium", "43 Premium", "Premium hero and benefits", True),
        ("20_premium/43_premium_inactive_primary_390x844.png", "detail__premium__packages_prices.png", (12, 300, 378, 500), "Premium", "43 Premium", "Package selector and dynamic fixture prices", True),
        ("20_premium/43_premium_inactive_primary_390x844.png", "detail__premium__subscribe_restore.png", (12, 430, 378, 820), "Premium", "43 Premium", "Subscribe and Restore Purchases actions", True),
    ]
    for source, name, box, feature, screen, state, fixture in crops:
        add_crop(source, f"28_detail_crops/{name}", box, feature=feature, screen=screen, state=state, kind="detail", fixture=fixture, notes="Major-screen detail.")


def _add_component_crops() -> None:
    crops = [
        ("03_home/05_home_signed_in_primary_390x844.png", "component__primary_button.png", (22, 300, 368, 390), "Home", "05 Home", "Primary Button"),
        ("02_auth/03_sign_in_empty_primary_390x844.png", "component__secondary_button.png", (25, 620, 365, 700), "Authentication", "03 Sign In", "Secondary Button"),
        ("06_party_gameplay/16_final_result_winner_a_primary_390x844.png", "component__text_button.png", (110, 745, 280, 825), "Party Gameplay", "16 Final Result", "Text Button"),
        ("13_blocked_players/36_blocked_players_populated_fixture_primary_390x844.png", "component__destructive_button.png", (20, 130, 155, 220), "Blocked Players", "36 Blocked Players", "Destructive Button"),
        ("06_party_gameplay/15_answer_reveal_scoring_primary_390x844.png", "component__disabled_button.png", (18, 735, 372, 815), "Party Gameplay", "15 Answer Reveal", "Disabled Button"),
        ("23_loading_states/03_sign_in_submitting_primary_390x844.png", "component__loading_button.png", (22, 480, 368, 565), "Authentication", "03 Sign In", "Loading Button"),
        ("02_auth/04_create_account_empty_primary_390x844.png", "component__text_field.png", (22, 275, 368, 385), "Authentication", "04 Create Account", "Text Field"),
        ("25_keyboard/03_sign_in_keyboard_390x844.png", "component__focused_field.png", (22, 45, 368, 145), "Authentication", "03 Sign In", "Focused Field"),
        ("02_auth/03_sign_in_validation_errors_primary_390x844.png", "component__error_field.png", (20, 260, 370, 430), "Authentication", "03 Sign In", "Error Field"),
        ("02_auth/03_sign_in_password_visible_primary_390x844.png", "component__password_field.png", (20, 365, 370, 505), "Authentication", "03 Sign In", "Password Field"),
        ("25_keyboard/35_friends_search_keyboard_390x844.png", "component__search_field.png", (16, 90, 374, 230), "Friends", "35 Friends", "Search Field"),
        ("03_home/05_home_signed_in_primary_390x844.png", "component__mode_card.png", (12, 365, 378, 540), "Home", "05 Home", "Mode Card"),
        ("04_categories/06_category_selection_six_selected_primary_390x844.png", "component__category_card_selected.png", (20, 225, 190, 455), "Categories", "06 Category Selection", "Category Card"),
        ("05_party_setup/10_helpers_three_selected_primary_390x844.png", "component__helper_card_selected.png", (12, 190, 378, 330), "Party Setup", "10 Helpers", "Helper Card"),
        ("12_friends/35_friends_populated_fixture_primary_390x844.png", "component__friend_row_avatar_action.png", (14, 170, 376, 345), "Friends", "35 Friends", "Friend Row"),
        ("13_blocked_players/36_blocked_players_populated_fixture_primary_390x844.png", "component__blocked_row.png", (12, 175, 378, 365), "Blocked Players", "36 Blocked Players", "Blocked Row"),
        ("07_saved_games/18_saved_games_multiple_fixture_primary_390x844.png", "component__saved_game_card.png", (12, 170, 378, 430), "Saved Games & Help", "18 Saved Party Games", "Saved Game Card"),
        ("08_tournament/26_tournament_match_active_primary_390x844.png", "component__tournament_match_card.png", (12, 190, 378, 440), "Tournament", "26 Tournament Match", "Tournament Match Card"),
        ("20_premium/43_premium_inactive_primary_390x844.png", "component__premium_package_card.png", (15, 300, 375, 455), "Premium", "43 Premium", "Premium Package Card"),
        ("17_settings/40_settings_signed_in_primary_390x844.png", "component__page_header.png", (0, 0, 390, 145), "Settings", "40 Settings", "Page Header"),
        ("17_settings/40_settings_signed_in_primary_390x844.png", "component__section_header.png", (12, 125, 378, 225), "Settings", "40 Settings", "Section Header"),
        ("22_empty_states/35_friends_empty_primary_390x844.png", "component__empty_state.png", (35, 230, 355, 585), "Friends", "35 Friends", "Empty State"),
        ("24_error_states/35_friends_error_primary_390x844.png", "component__error_state.png", (35, 220, 355, 600), "Friends", "35 Friends", "Error State"),
        ("23_loading_states/39_notifications_loading_primary_390x844.png", "component__loading_state.png", (60, 220, 330, 590), "Notifications", "39 Notifications", "Loading State"),
        ("21_guest/global_guest_auth_gate_primary_390x844.png", "component__auth_gate.png", (22, 175, 368, 700), "Guest", "Auth Gate", "Auth Gate"),
        ("03_home/05_home_signed_in_primary_390x844.png", "component__status_chip.png", (205, 575, 365, 642), "Home", "05 Home", "Status Chip"),
        ("15_profile/38_profile_primary_390x844.png", "component__player_11_avatar.png", (118, 90, 272, 255), "Profile", "38 Profile", "Player 11 avatar"),
        ("06_party_gameplay/12_game_board_mid_game_primary_390x844.png", "component__score.png", (55, 65, 335, 165), "Party Gameplay", "12 Game Board", "Score component"),
        ("06_party_gameplay/13_text_question_timer_active_primary_390x844.png", "component__timer.png", (125, 115, 265, 225), "Party Gameplay", "13 Text Question", "Timer"),
        ("06_party_gameplay/12_game_board_mid_game_primary_390x844.png", "component__question_cell.png", (25, 245, 140, 365), "Party Gameplay", "12 Game Board", "Question cell"),
    ]
    for source, name, box, feature, screen, state in crops:
        fixture = not source.startswith("02_auth/")
        if source in {
            "02_auth/03_sign_in_password_visible_primary_390x844.png",
            "25_keyboard/03_sign_in_keyboard_390x844.png",
        }:
            fixture = True
        add_crop(source, f"27_components/{name}", box, feature=feature, screen=screen, state=state, kind="component", fixture=fixture, notes="Reusable component with surrounding spacing context.")


def _write_manifest() -> None:
    manifest = OUTPUT / "SCREENSHOT_MANIFEST.csv"
    with manifest.open("w", newline="", encoding="utf-8-sig") as stream:
        writer = csv.writer(stream)
        writer.writerow(["ID", "Feature", "Screen", "State", "Variant", "Width", "Height", "TextScale", "Keyboard", "Fixture", "Filename", "SHA256", "Notes"])
        for index, item in enumerate(records, start=1):
            writer.writerow([
                f"AHDASH-V10-{index:04d}", item.feature, item.screen, item.state,
                item.variant, item.width, item.height, item.text_scale,
                "Yes" if item.keyboard else "No", "TEST-ONLY" if item.fixture else "No",
                item.filename, item.sha256, item.notes,
            ])


def _summary() -> dict[str, object]:
    captured = sorted({r.screen for r in records if r.screen in EXPECTED_SCREENS})
    missing = [screen for screen in EXPECTED_SCREENS if screen not in captured]
    folders = Counter(Path(r.filename).parts[0] for r in records)
    kinds = Counter(r.kind for r in records)
    return {
        "total": len(records),
        "full_screen": kinds["full"],
        "detail_crops": kinds["detail"],
        "component_crops": kinds["component"],
        "before_after": kinds["before_after"],
        "primary": sum(1 for r in records if r.kind == "full" and r.variant == "Primary"),
        "compact": folders["26_compact"] + sum(1 for r in records if r.filename.startswith("21_guest/") and r.variant == "Compact"),
        "keyboard": folders["25_keyboard"],
        "guest": folders["21_guest"],
        "empty": folders["22_empty_states"],
        "loading": folders["23_loading_states"],
        "error": folders["24_error_states"],
        "expected_screens": len(EXPECTED_SCREENS),
        "captured_screens": len(captured),
        "missing_screens": missing,
        "missing_states": len(INTENTIONALLY_MISSING_STATES),
        "deduplicated": len(deduplicated),
        "folder_counts": dict(sorted(folders.items())),
    }


def _write_docs(summary: dict[str, object]) -> None:
    (OUTPUT / "00_index" / "README.md").write_text(
        "# Atlas index\n\nOpen `../INDEX.html` for the offline visual browser.\n",
        encoding="utf-8",
    )
    readme = f"""# AHDASH | 11 — Complete UI Screenshot Atlas

This atlas documents the current active V10 Flutter UI using exact logical-pixel, lossless PNG renders. Images were copied without resizing; detail and component images are direct crops from those renders.

## Summary

- Active screens expected: {summary['expected_screens']}
- Active screens represented: {summary['captured_screens']}
- Total PNG files: {summary['total']}
- Full-screen renders: {summary['full_screen']}
- Detail crops: {summary['detail_crops']}
- Component crops: {summary['component_crops']}
- Keyboard renders: {summary['keyboard']}
- Compact renders: {summary['compact']}

Use [INDEX.html](INDEX.html) for visual browsing, [SCREENSHOT_MANIFEST.csv](SCREENSHOT_MANIFEST.csv) for per-file provenance and SHA-256, and [COVERAGE.md](COVERAGE.md) for known state-level gaps.

## Product truth

Fixture-backed images are explicitly marked `TEST-ONLY` in the manifest. No fixture data was added to production code. Online screens 30–32 remain deferred. No APK, AAB, release, signing, Supabase deployment, or migration is part of this atlas.
"""
    (OUTPUT / "README.md").write_text(readme, encoding="utf-8")

    missing_screen_text = "None." if not summary["missing_screens"] else "\n".join(f"- {screen}" for screen in summary["missing_screens"])
    missing_states = "\n".join(f"- {item}" for item in INTENTIONALLY_MISSING_STATES)
    coverage = f"""# Coverage

## Counts

| Metric | Count |
|---|---:|
| Expected active screens | {summary['expected_screens']} |
| Captured active screens | {summary['captured_screens']} |
| Total PNG files | {summary['total']} |
| Full-screen screenshots | {summary['full_screen']} |
| Primary full-screen screenshots | {summary['primary']} |
| Compact screenshots | {summary['compact']} |
| Keyboard screenshots | {summary['keyboard']} |
| Guest screenshots | {summary['guest']} |
| Empty-state screenshots | {summary['empty']} |
| Loading-state screenshots | {summary['loading']} |
| Error-state screenshots | {summary['error']} |
| Detail crops | {summary['detail_crops']} |
| Component crops | {summary['component_crops']} |
| Existing before/after artifacts | {summary['before_after']} |
| Byte-identical planned outputs deduplicated | {summary['deduplicated']} |

## Missing active screens

{missing_screen_text}

Online Lobby (30), Online Match (31), and Private Room (32) are intentionally deferred and are not counted as active expected screens.

## State-level gaps and intentional skips

Screen coverage is complete, but interaction-state coverage is not 100%. The following states were not fabricated merely to increase the screenshot count:

{missing_states}

All missing mutation-specific states remain covered by the existing behavioral test suite where applicable; production behavior was not changed for documentation.
"""
    (OUTPUT / "COVERAGE.md").write_text(coverage, encoding="utf-8")

    issues = """# Visual issues

No severe visual defect blocked generation of the atlas.

The atlas records documentation gaps in `COVERAGE.md`; those gaps are not asserted to be visual defects. No broad redesign or product-behavior change was performed during this task.
"""
    (OUTPUT / "VISUAL_ISSUES.md").write_text(issues, encoding="utf-8")

    if deduplicated:
        lines = ["# Deduplicated planned outputs", "", "Byte-identical files were omitted so the delivered atlas contains no duplicate PNG payloads.", ""]
        lines.extend(f"- `{item['skipped']}` duplicates `{item['duplicate_of']}`." for item in deduplicated)
        (OUTPUT / "00_index" / "DEDUPLICATED.md").write_text("\n".join(lines) + "\n", encoding="utf-8")


def _write_html() -> None:
    grouped: dict[str, list[Record]] = defaultdict(list)
    for item in records:
        grouped[Path(item.filename).parts[0]].append(item)
    sections = []
    for folder in FOLDERS:
        items = grouped.get(folder, [])
        if not items:
            continue
        cards = []
        for item in items:
            safe_file = html.escape(item.filename, quote=True)
            title = html.escape(f"{item.screen} — {item.state}")
            meta = html.escape(f"{item.variant} · {item.width}×{item.height} · text {item.text_scale} · {'TEST-ONLY fixture' if item.fixture else 'no fixture'}")
            cards.append(f'<article class="card"><a href="{safe_file}"><img loading="lazy" src="{safe_file}" alt="{title}"></a><h3>{title}</h3><p>{meta}</p><code>{safe_file}</code></article>')
        sections.append(f'<section id="{folder}"><h2>{html.escape(folder)} <span>{len(items)}</span></h2><div class="grid">{"".join(cards)}</div></section>')
    page = f"""<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>AHDASH 11 — V10 Complete UI Atlas</title>
<style>
:root{{--bg:#0b1018;--panel:#151d29;--line:#273447;--text:#eef4ff;--muted:#9fb0c8;--accent:#70d6b1}}
*{{box-sizing:border-box}} body{{margin:0;background:var(--bg);color:var(--text);font:14px/1.5 system-ui,sans-serif}}
header{{position:sticky;top:0;z-index:2;background:#0b1018f2;border-bottom:1px solid var(--line);padding:18px 24px}}
header h1{{margin:0;font-size:22px}} header p{{margin:4px 0 0;color:var(--muted)}}
main{{padding:20px}} section{{margin:0 0 36px}} h2{{border-bottom:1px solid var(--line);padding-bottom:8px}} h2 span{{color:var(--accent);font-size:13px}}
.grid{{display:grid;grid-template-columns:repeat(auto-fill,minmax(220px,1fr));gap:16px}} .card{{background:var(--panel);border:1px solid var(--line);border-radius:14px;padding:12px;min-width:0}}
.card img{{display:block;width:100%;height:330px;object-fit:contain;background:#070b11;border-radius:9px}} .card h3{{font-size:14px;margin:10px 0 4px}} .card p{{color:var(--muted);margin:0 0 8px;font-size:12px}}
.card code{{display:block;color:#bdd0e9;font-size:10px;overflow-wrap:anywhere}} a{{color:inherit}}
</style>
</head>
<body><header><h1>AHDASH | 11 — V10 Complete UI Atlas</h1><p>{len(records)} verified, unique PNG files · offline index · exact renders and crops</p></header><main>{''.join(sections)}</main></body></html>
"""
    (OUTPUT / "INDEX.html").write_text(page, encoding="utf-8")


def _verify(summary: dict[str, object]) -> None:
    pngs = sorted(OUTPUT.rglob("*.png"))
    if len(pngs) != len(records):
        raise RuntimeError(f"PNG/manifest mismatch: {len(pngs)} files vs {len(records)} records")
    if len(seen_hashes) != len(records):
        raise RuntimeError("Duplicate hashes remain in output")
    record_by_filename = {item.filename: item for item in records}
    for path in pngs:
        relative = path.relative_to(OUTPUT).as_posix()
        item = record_by_filename.get(relative)
        if item is None:
            raise RuntimeError(f"PNG without manifest record: {relative}")
        with Image.open(path) as image:
            image.verify()
        with Image.open(path) as image:
            if image.size != (item.width, item.height):
                raise RuntimeError(f"Dimension mismatch: {relative}")
        if _sha256(path) != item.sha256:
            raise RuntimeError(f"SHA mismatch: {relative}")
    if summary["missing_screens"]:
        raise RuntimeError(f"Missing expected screens: {summary['missing_screens']}")
    missing_folders = [folder for folder in FOLDERS if not (OUTPUT / folder).is_dir()]
    if missing_folders:
        raise RuntimeError(f"Missing required folders: {missing_folders}")


def main() -> None:
    _reset_output()
    _add_primary_screens()
    _add_compact_screens()
    _add_keyboard_and_scale()
    _add_responsive_representatives()
    _add_state_screens()
    _add_guest_states()
    _add_before_after()
    _add_detail_crops()
    _add_component_crops()
    summary = _summary()
    _write_manifest()
    _write_docs(summary)
    _write_html()
    _verify(summary)
    (OUTPUT / "00_index" / "BUILD_SUMMARY.json").write_text(json.dumps(summary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(summary, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
