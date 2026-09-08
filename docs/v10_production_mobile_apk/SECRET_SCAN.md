# Secret Scan

Status: **RUNTIME SOURCE PASS; LOCAL HYGIENE WARNING**

Scanned source and configuration references for service-role keys, secret Supabase key prefixes, credential-bearing database URLs, private-key blocks, hardcoded passwords, and raw voucher-code patterns. Generated outputs, dependency directories, binary assets, and expected ignored secret-bearing files were excluded from content output.

Findings:

- No service-role credential use was found in Flutter application source.
- No database password, private-key block, hardcoded Production credential, or raw voucher credential was found in runtime source.
- `mobile/.env`, `admin/.env.local`, Android signing files, and `google-services.json` are ignored by repository rules.
- Local hygiene warning: `admin/.env.local` contains the name of an unused service-role variable. Its value was not read or printed. Remove it and rotate it if it may be real before any staging or sharing.
- Source references to private-key delimiters are parsing/sanitization code, not embedded keys.
- Voucher references use server-side hashes or user input; no runtime raw Production voucher was identified.

The repository's current Git index reports the working content as untracked, so historical committed-state assurance cannot be derived from `git status`. The content scan and ignore checks above are the available local evidence.
