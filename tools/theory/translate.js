// Step 2 — machine translation with Google Cloud Translation v3.
//   --to en   Tigrinya → English   (fills empty "en": what each text means, for the reviewer)
//   --to no   Tigrinya → Norwegian (fills empty "no")
//   --to ti   English → Tigrinya   (fills "ti_google": a SUGGESTION, the app keeps showing "ti")
//   --dry-run only counts characters and shows the cost, sends nothing
//   --force   also redo texts that already have a value
// Texts with status "reviewed" are always skipped.
//
// Login (never put the key in this file or in git):
//   set GOOGLE_TRANSLATE_CREDENTIALS=C:\path\to\translate-service-account.json
//   (a service account with the role "Cloud Translation API User"; keep the file in tools/private/)
//   optional: set GOOGLE_TRANSLATE_PROJECT=habesha-hub-7bd1d
//
// Examples:
//   node tools/theory/translate.js --to en --dry-run
//   node tools/theory/translate.js --to en
//   node tools/theory/translate.js --to ti
const fs = require('fs');
const path = require('path');
const L = require('./lib');

const arg = n => process.argv.includes(n);
const val = n => { const i = process.argv.indexOf(n); return i > 0 ? process.argv[i + 1] : ''; };
const TO = val('--to');
if (!['en', 'no', 'ti'].includes(TO)) { console.log('Use --to en | --to no | --to ti  (add --dry-run to see the cost first)'); process.exit(1); }
const FROM = TO === 'ti' ? 'en' : 'ti';
const FIELD = TO === 'ti' ? 'ti_google' : TO;
const DRY = arg('--dry-run'), FORCE = arg('--force');

const items = L.load();
if (!items.length) { console.log('Run node tools/theory/extract.js first.'); process.exit(1); }

// numbers, km/h, sign codes, {placeholders}, JSON sign options: never translated
const KEEP = /(\{[^}]+\}|\b\d+([.,]\d+)?\s*(km\/h|km|m|%|kr|t|kg|‰)?\b|\b[A-Z]{1,3}\d+[a-z]?\b)/g;
const isData = s => /^\s*[\[{]/.test(s) || !/[\p{L}]/u.test(s);   // option is a sign picture / only numbers

const todo = items.filter(e => e.status !== 'reviewed' && e[FROM] && !isData(e[FROM]) && (FORCE || !e[FIELD]));
const chars = todo.reduce((n, e) => n + e[FROM].length, 0);
const all = items.reduce((n, e) => n + (e[FROM] || '').length, 0);
console.log(`${todo.length} texts to translate ${FROM} → ${TO} · ${chars.toLocaleString()} characters (all texts: ${all.toLocaleString()})`);
console.log(`Cost: Google gives 500,000 characters free each month, then about 20 USD per 1,000,000.`);
console.log(`      This run ≈ ${(chars / 1e6 * 20).toFixed(2)} USD before the free part → most likely 0 USD.`);
if (DRY || !todo.length) process.exit(0);

// fixed traffic terms (tools/tigrinja_glossary.json): English term → fixed Tigrinya, untouched by Google
const terms = L.glossary().filter(t => t.en && t.ti);
const esc = s => s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
const unesc = s => s.replace(/<[^>]+>/g, '').replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/&quot;/g, '"').replace(/&#39;/g, "'").replace(/&amp;/g, '&');
function protect(text) {
  let h = esc(text).replace(KEEP, m => `<span translate="no">${m}</span>`);
  if (TO === 'ti') {
    for (const t of terms) {
      const re = new RegExp(`\\b${t.en.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}\\b`, 'gi');
      h = h.replace(re, `<span translate="no">${esc(t.ti)}</span>`);
    }
  }
  return h;
}

(async () => {
  const credFile = process.env.GOOGLE_TRANSLATE_CREDENTIALS || process.env.GOOGLE_APPLICATION_CREDENTIALS;
  if (!credFile || !fs.existsSync(credFile)) {
    console.log('Set GOOGLE_TRANSLATE_CREDENTIALS to the translation service account file first (see the top of this script).');
    process.exit(1);
  }
  const { GoogleAuth } = require(path.join(L.ROOT, 'node_modules', 'google-auth-library'));
  const auth = new GoogleAuth({ keyFile: credFile, scopes: ['https://www.googleapis.com/auth/cloud-translation'] });
  const project = process.env.GOOGLE_TRANSLATE_PROJECT || await auth.getProjectId();
  const client = await auth.getClient();
  const url = `https://translation.googleapis.com/v3/projects/${project}/locations/global:translateText`;

  let done = 0;
  for (let i = 0; i < todo.length; i += 40) {
    const batch = todo.slice(i, i + 40);
    const r = await client.request({
      url, method: 'POST',
      data: { sourceLanguageCode: FROM, targetLanguageCode: TO, mimeType: 'text/html', contents: batch.map(e => protect(e[FROM])) },
    });
    r.data.translations.forEach((t, k) => { batch[k][FIELD] = unesc(t.translatedText).replace(/\s+/g, ' ').trim(); });
    done += batch.length;
    L.save(items);   // saved after every batch, so nothing is lost if it stops
    process.stdout.write(`\r${done}/${todo.length}`);
  }
  console.log(`\n✅ ${done} texts → field "${FIELD}" in tools/private/theory_all.json`);
})().catch(e => {
  // never print credentials; Google's error message is enough
  console.error('❌', e.response?.data?.error?.message || e.message);
  process.exit(1);
});
