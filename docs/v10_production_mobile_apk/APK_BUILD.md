# Release APK Build

Status: **NOT BUILT**

The Production validator failed before any Flutter APK build because required real configuration is unavailable. No `flutter build apk` command was executed in this phase.

Guarded sanitized command for a future approved run:

```powershell
powershell -File scripts/build-production-apk.ps1 -EnvironmentFile <secure-production-env-file>
```

The wrapper validates first, then would execute:

```text
flutter build apk --release --dart-define-from-file=<secure-production-env-file>
```

An older `mobile/build/app/outputs/flutter-apk/app-release.apk` already exists from prior work and predates this audit. It was not created, modified, verified, or accepted as a Production deliverable here. Do not use it for this gate.

APK path: N/A  
APK size: N/A  
APK metadata/signature verification: NOT RUN because no current Production APK exists.

No AAB was built and nothing was uploaded or published.
