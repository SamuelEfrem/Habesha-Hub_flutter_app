// ═══════════════════════════════════════════════════════════
// Lager koder som låser opp betalt innhold (én kode = én bruker).
// Koden låses til den første kontoen (og telefonnummeret) som bruker den.
//
// Kjør:  node tools/make_codes.js 10              (10 koder for teori)
//        node tools/make_codes.js 5 lang_pro      (5 koder for språk)
// Kodene skrives ut — send dem til kundene på WhatsApp.
// ═══════════════════════════════════════════════════════════
const path = require('path');
const crypto = require('crypto');
const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
initializeApp({ credential: cert(require(path.join(__dirname, '..', 'serviceAccountKey.json'))) });

const COUNT = Math.min(parseInt(process.argv[2] || '10', 10), 100);
const PRODUCT = process.argv[3] || 'theory_pro';
const CHARS = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';   // no 0/O or 1/I
const newCode = () => 'HH' + Array.from(crypto.randomBytes(6), b => CHARS[b % CHARS.length]).join('');

(async () => {
  if (!['theory_pro', 'lang_pro'].includes(PRODUCT)) throw new Error('product must be theory_pro or lang_pro');
  const db = getFirestore();
  const made = [];
  while (made.length < COUNT) {
    const code = newCode();
    const ref = db.collection('unlock_codes').doc(code);
    // create() fails if the code already exists → never two equal codes
    try {
      await ref.create({ product: PRODUCT, phone: '', used: false, createdAt: FieldValue.serverTimestamp(), batch: 'tools/make_codes' });
      made.push(code);
    } catch (_) {}
  }
  console.log(`${made.length} koder for ${PRODUCT} (én bruker hver):\n`);
  made.forEach((c, i) => console.log(`${String(i + 1).padStart(2)}. ${c}`));
  process.exit(0);
})().catch(e => { console.error('❌', e.message); process.exit(1); });
