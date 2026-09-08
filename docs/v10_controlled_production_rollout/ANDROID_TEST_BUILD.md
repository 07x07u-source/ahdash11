# Android Production-mode test build

Status: **BLOCKED — NOT BUILT**.

The historical local command is `flutter build apk --release --dart-define-from-file=.env`, and release signing material is present: `key.properties`, all four required properties, the referenced keystore file, and `google-services.json` exist.

The available Mobile `.env` is not a valid representation of the intended Production configuration:

- `APP_ENV=development` rather than Production.
- `ADMOB_ENABLED=false`; Production AdMob unit identifiers are unavailable locally.
- `REVENUECAT_ANDROID_API_KEY` is absent/empty.
- Production Privacy Policy and Terms URLs are unavailable locally.
- No `.env.production` alternative or process-level Production variables are present.

The Codemagic Production definition expects these values from protected CI environment variables. They were not retrieved, invented, or copied into the repository. Building with the local `.env` would produce a signed Release binary in Development mode and would not satisfy the requested Production-mode artifact.

- APK produced: no
- AAB produced/submitted: no
- Store publication: no
