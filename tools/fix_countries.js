// ═══════════════════════════════════════════════════════════
// Retter landnavn og kategorier på bedrifter til engelsk, slik at
// Utforsk og filtrene finner dem (f.eks. "Norge" → "Norway").
// Kjør:  node tools/fix_countries.js        (trygt å kjøre flere ganger)
// ═══════════════════════════════════════════════════════════
const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
initializeApp({ credential: cert(require(require('path').join(__dirname, '..', 'serviceAccountKey.json'))) });
const db = getFirestore();

const COUNTRY = {
  'norge': 'Norway', 'sverige': 'Sweden', 'danmark': 'Denmark', 'tyskland': 'Germany',
  'nederland': 'Netherlands', 'frankrike': 'France', 'belgia': 'Belgium', 'sveits': 'Switzerland',
  'italia': 'Italy', 'etiopia': 'Ethiopia', 'storbritannia': 'UK', 'england': 'UK',
  'united kingdom': 'UK', 'united states': 'USA', 'sør-sudan': 'South Sudan', 'egypt': 'Egypt',
};
const CATEGORY = { 'butikk': 'Shop', 'kafé': 'Cafe', 'kafe': 'Cafe', 'frisør': 'Barber', 'klinikk': 'Clinic', 'annet': 'Other' };
const CITY = { 'Addis Abeba': 'Addis Ababa', 'København': 'Copenhagen' };

(async () => {
  const snap = await db.collection('businesses').get();
  let n = 0;
  for (const doc of snap.docs) {
    const d = doc.data(), upd = {};
    const c = (d.country || '').trim();
    if (COUNTRY[c.toLowerCase()] && COUNTRY[c.toLowerCase()] !== c) upd.country = COUNTRY[c.toLowerCase()];
    const k = (d.category || '').trim();
    if (CATEGORY[k.toLowerCase()]) upd.category = CATEGORY[k.toLowerCase()];
    if (CITY[d.city]) upd.city = CITY[d.city];
    if (Object.keys(upd).length) {
      await doc.ref.update(upd);
      console.log(`✅ ${d.name || doc.id}:`, upd);
      n++;
    }
  }
  console.log(`\n🎉 ${n} av ${snap.size} bedrifter oppdatert.`);
  process.exit(0);
})().catch(e => { console.error('❌', e.message || e); process.exit(1); });
