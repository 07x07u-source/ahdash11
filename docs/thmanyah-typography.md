# Thmanyah Typography Integration

## Source and metadata

Only the user-supplied `Thmanyah-Font-Family.zip` was used. Fifteen original OTF files were inspected: Sans, Serif Display, and Serif Text, each in Light 300, Regular 400, Medium 500, Bold 700, and Black 900. Files were copied without modification, conversion, or renaming.

## Flutter families

- `ThmanyahSans`: UI, Arabic body copy, labels, questions, scores, and controls.
- `ThmanyahSerifDisplay`: editorial tournament/champion moments.
- `ThmanyahSerifText`: restrained editorial copy.

Arabic styles do not use negative letter spacing. Line heights remain generous enough for Arabic marks. The global theme, direct hard-coded display roles, and golden loaders now reference Thmanyah only.

## Packaging and rights guardrails

The OTF data is embedded only in the compiled application bundle. It is not copied into Admin public assets, Storage, an API response, or a downloadable webfont endpoint. No Thmanyah trademark endorsement is implied. Old Tajawal/Noto files were removed from the project and placed in the recoverable local backup `C:\Users\user\Downloads\ahdash11-old-fonts-backup`.

Automated coverage loads all fifteen packaged faces and checks the product family contract.

