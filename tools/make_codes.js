// ═══════════════════════════════════════════════════════════
// Lager koder som låser opp betalt innhold.
//   Vanlig kode: én kode = én bruker (låses til den første som bruker den).
//   Master-nøkkel: kan brukes om igjen, låser opp ALT, telles. Slett den
//   i Admin → Codes hvis den kommer på avveie.
//
// Kjør:  node tools/make_codes.js 10              (10 koder for teori)
//        node tools/make_codes.js 5 lang_pro      (5 koder for språk)
//        node tools/make_codes.js --master        (én master-nøkkel)
// Kodene har spesialtegn (! # @ $ % & ? +) — ikke * _ ~ (WhatsApp-formatering).
// ═══════════════════════════════════════════════════════════
const path = require('path');
const crypto = require('crypto');
const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
initializeApp({ credential: cert(require(path.join(__dirname, '..', 'serviceAccountKey.json'))) });

const args = process.argv.slice(2);
const MASTER = args.includes('--master');
const nums = args.filter(a => !a.startsWith('--'));
const COUNT = MASTER ? 1 : Math.min(parseInt(nums[0] || '10', 10), 100);
const PRODUCT = MASTER ? 'all' : (nums[1] || 'theory_pro');
const CHARS = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';   // no 0/O or 1/I
const SPECIAL = '!#@$%&?+';
const pick = s => s[crypto.randomInt(s.length)];

// HH + letters/digits with special characters mixed in at random places
function newCode(len, specials) {
  const c = Array.from({ length: len - specials }, () => pick(CHARS));
  for (let i = 0; i < specials; i++) c.splice(crypto.randomInt(c.length + 1), 0, pick(SPECIAL));
  return 'HH' + c.join('');
}

(async () => {
  if (!MASTER && !['theory_pro', 'lang_pro'].includes(PRODUCT)) throw new Error('product must be theory_pro or lang_pro');
  const db = getFirestore();
  const made = [];
  while (made.length < COUNT) {
    const code = MASTER ? newCode(12, 4) : newCode(8, 2);
    const data = MASTER
      ? { master: true, product: 'all', uses: 0, createdAt: FieldValue.serverTimestamp(), batch: 'tools/make_codes' }
      : { product: PRODUCT, phone: '', used: false, createdAt: FieldValue.serverTimestamp(), batch: 'tools/make_codes' };
    // create() fails if the code already exists → never two equal codes
    try { await db.collection('unlock_codes').doc(code).create(data); made.push(code); } catch (_) {}
  }
  console.log(MASTER ? '👑 Master-nøkkel (låser opp alt, kan brukes flere ganger):\n'
                     : `${made.length} koder for ${PRODUCT} (én bruker hver):\n`);
  made.forEach((c, i) => console.log(`${String(i + 1).padStart(2)}. ${c}`));
  process.exit(0);
})().catch(e => { console.error('❌', e.message); process.exit(1); });
