# Google Sign-In Release Audit

Status: **PARTIAL PASS; CONSOLE SHA VERIFICATION REQUIRED**

- Android package is `com.ahdash.eleven`.
- The intended local Release keystore was inspected with `keytool` without printing passwords or fingerprints.
- Both SHA-1 and SHA-256 fingerprints are available from the Release certificate.
- The Release SHA-1 matches an Android OAuth certificate entry in the local `google-services.json`.
- An Android OAuth client is present for the correct package.

SHA-256 registration in the intended Production Firebase/Google Console cannot be proven from `google-services.json`. Required external check:

`GOOGLE_SIGN_IN_RELEASE_SHA_VERIFICATION_REQUIRED`

Specifically, verify both the upload/release SHA-256 and the applicable Play App Signing certificate after Play enrollment. No passwords, private keys, or fingerprint values are recorded here.
