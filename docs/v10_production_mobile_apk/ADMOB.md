# AdMob Production Audit

Status: **BLOCKED**

Missing or invalid exact variables:

- `ADMOB_ENABLED` — currently false; Production requires true.
- `ADMOB_ANDROID_APP_ID` — missing.
- `ADMOB_REWARDED_ANDROID_ID` — missing.
- `ADMOB_INTERSTITIAL_ANDROID_ID` — missing.
- `ADMOB_INTERSTITIAL_EVERY_MATCHES` — not explicitly supplied for Production.

The application has rewarded and interstitial Android integrations. Non-Production may use Google's test IDs, but Production getters return no fallback IDs. The new validator and Android Release configuration also reject missing IDs and Google's test publisher ID.

Ad display remains governed by the central `PremiumAccessResolution.adsAllowed` truth, so active Premium subscribers bypass ads.

No AdMob IDs were invented and no AdMob service configuration was deployed.
