# مصفوفة QA — أحدعش | 11

الحالة الابتدائية: automated baseline فقط. كل صف Manual يبقى `Pending real device` حتى يختبره صاحب المشروع؛ منع Emulator لا يبرر ادعاء النجاح.

## أبعاد العرض والوصول

| device size | theme | text scale | reduced motion | network | auth | game type | format | expected result | automated/manual | actual status |
|---|---|---:|---|---|---|---|---|---|---|---|
| 360×800 | Light | 1.0 | off | online | signed in | Classic | online solo | CTA/HUD/question/answers بلا overflow | Widget + Manual | Automated layout pass؛ device pending |
| 360×800 | Dark | 1.6 | on | online | signed in | Classic | online solo | vertical answers، no particles/shake | Widget + Manual | Automated large-text/reduced-motion pass؛ device pending |
| 390×844 | Light | 2.0 | on | online | signed in | True/False | quick play | large buttons/readable/no clipped CTA | Unit/Widget + Manual | Contract/timer pass؛ exact device flow pending |
| 412×915 | Dark | 1.0 | off | online | signed in | Speed | quick play | dominant server timer/fast transitions | Unit/Widget + Manual | Contract/timer pass؛ device pending |
| 360×800 | Light | 1.6 | on | offline | signed in | Classic | Practice | explicit unranked/no rewards and safe local pause | Widget + Manual | Automated pass؛ background device pending |
| 390×844 | System | 1.0 | off | lost mid-question | signed in | Classic | 1v1 | input lock/reconnecting/recover authoritative | Unit + Manual | Planned |
| 412×915 | Dark | 1.0 | off | online | signed out | N/A | deep link | safe auth routing, no protected data | Widget + Manual | Planned |

## Gameplay contracts

| scenario | expected | automated | status |
|---|---|---|---|
| double tap | request واحد، state locks before await | unit/widget | Passed |
| retry after unknown response | نفس idempotency key، server returns previous result | unit/SQL/Edge | Passed contract/parser؛ real PostgreSQL integration pending |
| stale response | لا يغير السؤال الحالي | unit | Planned |
| timeout no answer | server records wrong + full duration; tie-break fair | SQL regression | Parser/definition check passed؛ pgTAP execution pending |
| client clock shifted | server offset/deadline remains authoritative | fake-clock unit | Passed online controller؛ challenge device pending |
| background/screen lock | resume fetches authoritative state | unit + real device | Planned |
| disconnect/reconnect | no duplicate listener/request/reward | unit + real device | Planned |
| dispose while request active | late result ignored and resources removed | unit/flame_test | Passed |
| correct/wrong/timeout | visual cue only after server verdict; not color only | widget/flame/manual | Passed automated؛ manual pending |
| finish rewards | values from server ledger; pending shown honestly | SQL/integration/manual | Planned |

## Product flows

| flow | cases | expected | automated/manual | status |
|---|---|---|---|---|
| Fresh install/auth | email create/login, Google release config | no secret print; correct routing | Manual | Pending real device |
| Onboarding | full/skip league/skip club/exit-resume | Player11 persists؛ football choice explicitly later | Widget + Manual | Player11/finish pass؛ interruption pending device |
| Home | loading/data/empty/offline/error | primary play CTA visible | Widget + Manual | Automated pass؛ live data pending |
| Play Hub | enabled/coming soon/large text | no broken route, type/format distinction | Widget | Passed |
| Game Setup | practice/1v1/2v2/team | progressive options and explicit cost/reward | Widget + Manual | Planned |
| League/Club picker | Arabic/English/aliases/no-logo-rights | normalized search + procedural fallback | Unit/Widget + Manual | Owner-state unit pass؛ live catalog/device pending |
| Social | friends/team/challenge/MVP/blocked | membership/permissions from server | Unit + Manual | Idempotency unit/parser pass؛ live permissions pending |
| Settings | light/dark/system, sound/haptics/reduced motion/promotions | persistence; promotions default off | Unit/Widget + Manual | Defaults/Player11 pass؛ device pending |
| Notifications | permission/token/deep links | contextual permission and safe allowlist | Manual | Pending real device |
| Wallet/Premium/Ads | success/cancel/error/restore | no pay-to-win/no ad during sensitive play | Manual | Pending real device |
| Logout/Delete | confirms and cleans session safely | formal Arabic/no accidental deletion | Manual | Pending real device |

## Accessibility

- TalkBack labels/actions for every answer, navigation item, timer/score state.
- verdict uses text+icon+shape، not color only.
- ≥48dp interactive targets.
- Arabic/English/numbers directionality explicitly tested.
- large question wrapping without tiny font fallback.
- reduced motion removes particles/camera shake/large transitions but retains state feedback.

## Performance/memory

- static checks: no full GameWidget rebuild per tick، bounded particles، decode size، dispose listeners/timers.
- APK/assets size measured at release.
- Real-device frame time/ANR/memory/startup remain manual/profile QA. لا 60fps claim قبل القياس.

## Command evidence — final Party round

| command | exit_code | passed | failed | skipped | duration/status |
|---|---:|---:|---:|---:|---|
| `dart format lib test` | 0 | 152 files | 0 changed | 0 | passed |
| `flutter analyze --fatal-infos` | 0 | N/A | 0 issues | 0 | 76.7s |
| targeted Party engine/controller | 0 | 12 | 0 | 0 | 11 engine + 1 controller |
| Party Goldens | 0 | 100 | 0 | 0 | 10 screens × 5 sizes × Light/Dark |
| final `flutter test` | 0 | 297 | 0 | 0 | 66s |
| Admin lint + typecheck | 0 | N/A | 0 | 0 | passed؛ بلا warnings أو type errors |
| Admin `npm test` | 0 | 48 | 0 | 0 | 10 test files passed |
| Admin `npm run build` | 0 | 17 pages | 0 | 0 | Next production build passed |
| final PostgreSQL parser | 0 | 20 migrations / 124 functions | 0 | 0 | PostgreSQL grammar passed |
| `npx supabase db push --dry-run` | 0 | 1 pending migration | 0 | 0 | dry run only؛ no remote mutation |
| `npx supabase db lint --linked --level warning` | 0 | N/A | 0 errors | 0 | 11 pre-existing remote warnings؛ new migration not pushed |
| `npx supabase db lint --local` | unavailable | N/A | N/A | N/A | local PostgreSQL/Docker was not running on `127.0.0.1:54322` |
| Edge Functions | N/A | N/A | N/A | N/A | unchanged in this round |
| release APK build | 0 | 1 APK | 0 | 0 | 87.33 MiB؛ signed v2؛ no install/emulator |

## Release artifact

- المسار: `C:\dev\ahdash11\mobile\build\app\outputs\flutter-apk\app-release.apk`
- الحجم: `91,574,482 bytes` (`87.33 MiB`).
- SHA-256: `CC2ED3B6D3D49A52417E225BEC0628A74BBF769266F7365B9B8C60FC2AD376F8`
- Package: `com.ahdash.eleven`
- الإصدار: `versionCode 1`، `versionName 0.1.0`.
- التوقيع: `apksigner` verified؛ v2=true؛ Android OAuth SHA-1 مطابق للإعداد الحالي.
- Google/Firebase/FCM resources موجودة داخل Release، لكن runtime/device flows ما زالت Manual Pending.
- تم البناء باستخدام `--dart-define-from-file=.env` وإعدادات التوقيع الموجودة دون عرض أسرارها.
- التقرير التفصيلي: `docs/ahdash-party-game-release-report.md`.
