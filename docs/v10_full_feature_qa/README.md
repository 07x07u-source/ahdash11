# V10 Full Feature QA Screenshot Pack

These files are deterministic Flutter test artifacts for the active AHDASH 11 product surfaces. Fixture data is defined only under `mobile/test/`; production widgets continue to use repositories, providers, server data, or local persistence.

- Logical portrait viewports: 360×800, 390×844, 393×852, 412×915, 430×932.
- Text scales: 1.0, 1.2, 1.3.
- PNGs are captured at 2× raster density; filenames describe the logical viewport.
- Input variants use an approximately 300 px keyboard inset.
- `responsive_matrix/` contains the complete 645-case matrix.
- `SCREENSHOTS.json` contains a SHA-256 and byte count for every PNG.
- `full_test.jsonl` is the successful normal full-test protocol log.

Online Lobby, Online Match, and Private Room are intentionally absent because Online 30–32 remains deferred.
