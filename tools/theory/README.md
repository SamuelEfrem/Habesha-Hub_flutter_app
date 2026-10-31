# Driving theory translations (Tigrinya)

All theory texts (295 questions, answers, explanations, 67 sign names) are kept in
`tools/private/theory_all.json` (not in git). Every text has `ti`, `en`, `no`,
`ti_google` (a suggestion only) and `status` (`machine` or `reviewed`).
The game only shows stored texts — no live translation and no API key in the app.
If a Tigrinya text is empty, English is shown.

| Step | Command |
|---|---|
| 1. Collect all texts | `node tools/theory/extract.js` |
| 2. See the cost first | `node tools/theory/translate.js --to en --dry-run` |
| 3. English + Norwegian meaning for the reviewer | `node tools/theory/translate.js --to en` and `--to no` |
| 4. Google's Tigrinya suggestion (optional) | `node tools/theory/translate.js --to ti` |
| 5. Review file for a Tigrinya speaker | `node tools/theory/export_review.js` → `tools/private/theory_review.csv` |
| 6. Read the corrected file back | `node tools/theory/import_review.js` |
| 7. Put the texts into the game | `node tools/theory/publish.js`, then `node tools/upload_theory.js` and `firebase deploy --only hosting` |

Login for Google Translate: a service account with the role *Cloud Translation API User*,
saved in `tools/private/` and pointed to with `GOOGLE_TRANSLATE_CREDENTIALS`. Never commit it.
Fixed traffic terms: fill in the `ti` values in `tools/tigrinja_glossary.json`.
Texts marked `reviewed` are never machine translated again.
