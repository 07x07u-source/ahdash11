# Firebase Production Audit

Status: **LOCAL CONFIG PRESENT; EXTERNAL PRODUCTION PROVENANCE VERIFICATION REQUIRED**

- `mobile/android/app/google-services.json` exists and contains a client for `com.ahdash.eleven`.
- Required Firebase project metadata, Android app metadata, API-key metadata, and FCM sender metadata are present.
- Google Services and Crashlytics Gradle plugins are applied when the file exists.
- Flutter bootstrap initializes Firebase, Analytics, Crashlytics, and Firebase Messaging when `FIREBASE_ENABLED=true`.
- The FCM background handler and notification service are present.

The protected Codemagic `FIREBASE_ANDROID_CONFIG` cannot be compared locally, and no Firebase Console access was used. Therefore the local file cannot be conclusively declared to be the intended Production Firebase project from repository evidence alone.

Required external evidence: `FIREBASE_PRODUCTION_PROJECT_VERIFICATION_REQUIRED`.

No Firebase file was replaced or fabricated.
