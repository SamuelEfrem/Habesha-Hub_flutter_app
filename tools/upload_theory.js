// ═══════════════════════════════════════════════════════════
// Laster opp de betalte teori-spørsmålene (tools/private/theory_pro.json)
// til Firestore "theory_pro". Bare brukere som har låst opp med kode
// (redeemCode) kan lese dem — de ligger IKKE i nettsiden.
//
// Filen tools/private/ er ikke i git (repoet er offentlig) — ta backup!
//
// Format i filen: [spørsmål, [4 svar], riktigIndeks, forklaring]
// Kjør:  node tools/upload_theory.js
// ═══════════════════════════════════════════════════════════
const path = require('path');
const fs = require('fs');
const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
initializeApp({ credential: cert(require(path.join(__dirname, '..', 'serviceAccountKey.json'))) });

const FILE = path.join(__dirname, 'private', 'theory_pro.json');
const CHUNK = 100;   // spørsmål per dokument (godt under Firestore sin 1 MB-grense)

(async () => {
  const list = JSON.parse(fs.readFileSync(FILE, 'utf8'));
  // Firestore can't store arrays inside arrays → objects
  const qs = list.map(([q, o, c, ex]) => ({ q, o, c, ex }));
  const db = getFirestore();
  const old = await db.collection('theory_pro').get();
  const batch = db.batch();
  old.docs.forEach(d => batch.delete(d.ref));
  let n = 0;
  for (let i = 0; i < qs.length; i += CHUNK, n++) {
    batch.set(db.collection('theory_pro').doc(`rules_${n}`), { questions: qs.slice(i, i + CHUNK), order: n });
  }
  await batch.commit();
  console.log(`✅ ${qs.length} betalte spørsmål lastet opp i ${n} dokumenter (theory_pro/rules_0 …)`);
  process.exit(0);
})().catch(e => { console.error('❌', e.message); process.exit(1); });
