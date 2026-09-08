# V8.1 Icon Reduction Audit

## Counting scope

The primary comparison uses the static rendered state of the eight V8.1 checkpoint screens at 844 × 390. It counts visible icon/pictogram instances, including repeated helper images, but excludes the AHDASH logo, team color dots, text glyphs, progress lines, and off-screen/conditional branches. The broad source inventory is retained separately in `docs/v8-1-icon-inventory-raw.txt` (462 matching source lines); that number is intentionally not presented as a visible UI count.

## Checkpoint result

- Total visible generic/system icon instances before: **41**.
- Generic/system icon instances removed: **31**.
- Utility icon instances intentionally retained: **10**.
- Custom AHDASH pictogram instances added in the checkpoint states: **12**.
- Total visible utility + pictogram instances after: **22**.
- Net visible reduction: **19 instances / 46.3%**.
- Unique custom PNG pictograms in the master set: **15**.

The Helpers screen keeps six visible feature marks because five distinct helpers plus the focused helper preview are functional game choices. Its total instance count stays level, but all six generic helper icons are replaced by the AHDASH family and the persistent neon circles are removed.

## Screen-by-screen checkpoint audit

| Screen | Before | Removed | Utility retained | Pictograms added | After | Why |
|---|---:|---:|---:|---:|---:|---|
| Party Result | 5 | 5 | 0 | 1 | 1 | Home/rematch/new-game buttons are clear as text; generic medal/star is replaced by one victory mark. |
| Tournament Hub | 4 | 3 | 1 | 1 | Back remains familiar; medal/background icon and button icon are removed; one tournament identity remains. |
| Tournament Create | 3 | 2 | 1 | 1 | Back remains; generic tournament and progression arrow are replaced by one small tournament mark and text CTA. |
| Tournament Draw | 3 | 2 | 1 | 1 | Back remains; duplicated shuffle icons collapse into one branded draw image and a text-only action. |
| Tournament Champion | 4 | 3 | 1 | 1 | Back remains; medal, completion icon, and record icon are removed; champion mark is the single gold hero. |
| Helpers | 8 | 6 | 2 | 6 | Back/selected confirmation stay functional; five helper choices and the focused preview use custom marks with no permanent circle badge. |
| Premium | 11 | 9 | 2 | 1 | Back/restore remain utilities; six benefit icons, status icon, CTA icon, and generic hero are replaced by structured text plus one Premium mark. |
| Notifications | 3 | 1 | 2 | 0 | Back/refresh stay; the duplicated empty-state bell is removed because the text is sufficient. |
| **Total** | **41** | **31** | **10** | **12** | **22** | **46.3% fewer visible marks overall.** |

## Supporting-screen cleanup

| Area | Change |
|---|---|
| How To Play | Four generic step icons replaced by categories/teams/question/win pictograms; FAQ and navigation actions use text where sufficient. |
| Onboarding | Generic stadium and football CTA icons removed; three educational pictograms carry the steps in standard Ink. |
| Saved Party Games | Empty football icon replaced by `emptyGames`; clear CTAs are text-only. |
| Friends | Generic user-plus empty-state card replaced by `emptyFriends`; search-empty state uses text only. |
| Settings | Category rail, switches, notification preferences, theme segments, support rows, and decorative contrast hero rely on text/spacing/switches instead of repeated icons. Back and row chevrons remain utilities. |
| Profile | Metadata/check/favorite and clear text-action icons removed. Back, refresh, and settings remain because they are compact familiar actions. |
| Tournament bracket | Generic team/check icons removed from every bracket row; winner state uses weight and a controlled line, while connector lines carry progression. |

## Utility symbols deliberately retained

- Back/chevron: navigation direction and compact hierarchy.
- Refresh: explicit retry/update action in Premium, Notifications, and Profile.
- Search: familiar input/action affordance in social discovery.
- Close/reject: destructive or dismissive quick action.
- Settings: compact Profile toolbar route.
- Favorite, volume, timer, and play/pause: only where they remain real game shortcuts or state controls.
- Add/remove: only in compact list management where the text is not already the full affordance.

These remain Flutter utility symbols; custom raster pictograms are not used for navigation.

## Visual inspection conclusion

- Generic medal/trophy/shuffle/bell hero imagery is absent from the checkpoint screens.
- Every AHDASH pictogram is one color at render time and has a true transparent background.
- Light and Dark use the same geometry with token tinting.
- Gold appears on Result, Champion, and Premium identity only.
- Selected Helpers use controlled success green; normal helpers use Ink/warm inverse and consumed helpers use muted color.
- Hero images remain smaller than the winner/champion names and do not compete with the primary text.

