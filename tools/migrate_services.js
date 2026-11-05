// Gir alle tjenester i anonymous_services gruppe, underkategori og status for den nye katalogen.
//   node tools/migrate_services.js          (viser endringene, lagrer ingenting)
//   node tools/migrate_services.js --write  (lagrer)
// Sletter aldri. Endrer aldri `category` (eldre app-versjoner bruker den), bare legger til felt
// og retter små feil i bynavn (f.eks. "kampala" → "Kampala").
const path = require('path');
const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const serviceAccount = require(path.join(__dirname, '..', 'serviceAccountKey.json'));

const WRITE = process.argv.includes('--write');
const MAP = {
  photographer: ['weddings', 'photo_video'], decoration: ['weddings', 'decoration'], clothing: ['weddings', 'dresses'],
  accommodation: ['travel', 'hotels'], transport: ['travel', 'drivers'], flight_visa: ['travel', 'visa'],
  money_transfer: ['money_transfer', ''], hawala: ['money_transfer', ''], music: ['music', null],
};
const COUNTRY_OF_CITY = { kampala: 'UG', entebbe: 'UG', 'addis ababa': 'ET', asmara: 'ER', oslo: 'NO', nairobi: 'KE', juba: 'SS', stockholm: 'SE', london: 'GB' };
const niceCity = c => (c === c.toLowerCase() ? c.replace(/(^|\s)\p{L}/gu, m => m.toUpperCase()) : c).trim();

(async () => {
  initializeApp({ credential: cert(serviceAccount) });
  const db = getFirestore();
  const docs = (await db.collection('anonymous_services').get()).docs;
  const changes = [];
  for (const d of docs) {
    const v = d.data(), set = {};
    const m = MAP[v.category];
    if (!v.group) {
      if (m) set.group = m[0];
      else console.log(`  ? ${d.id}: ukjent kategori "${v.category}" – ikke endret`);
    }
    if (m && m[1] !== null && v.subcategory == null) set.subcategory = m[1];
    if (!v.status) set.status = v.available === false ? 'pending' : 'approved';
    if (!v.contactMode) set.contactMode = 'habesha';   // eldre tjenester bookes fortsatt via Habesha Hub
    if (typeof v.city === 'string' && niceCity(v.city) !== v.city) set.city = niceCity(v.city);
    const cc = COUNTRY_OF_CITY[(v.city || '').toLowerCase().trim()];
    if (!v.country && cc) set.country = cc;
    if (Object.keys(set).length) changes.push([d, set]);
  }
  console.log(`${docs.length} tjenester · ${changes.length} får endringer\n`);
  for (const [d, set] of changes) console.log(`  ${(d.data().publicName || d.id).padEnd(28)} ${d.data().country || '?'}/${d.data().city || '?'}  ${JSON.stringify(set)}`);
  if (!WRITE) { console.log('\nIngenting lagret. Kjør med --write for å lagre.'); process.exit(0); }
  const batch = db.batch();
  changes.forEach(([d, set]) => batch.update(d.ref, set));
  if (changes.length) await batch.commit();
  console.log(`\nFerdig: ${changes.length} oppdatert.`);
  process.exit(0);
})().catch(e => { console.error(e.message); process.exit(1); });
