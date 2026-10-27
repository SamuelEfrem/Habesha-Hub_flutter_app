// ═══════════════════════════════════════════════════════════
// Finner GPS-posisjon for bedrifter som mangler den (lat/lng mangler
// eller er 0,0) — ellers vises de aldri i "nær meg".
// Slår opp adressen hos OpenStreetMap (Nominatim, maks 1 per sekund).
//
// Kjør:
//   node tools/fix_positions.js           (viser bare hva som blir funnet)
//   node tools/fix_positions.js --write   (lagrer lat/lng i Firestore)
// ═══════════════════════════════════════════════════════════
const path = require('path');
const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
initializeApp({ credential: cert(require(path.join(__dirname, '..', 'serviceAccountKey.json'))) });

const WRITE = process.argv.includes('--write');
const UA = 'habesha-hub-import/1.0 (samuelefriem@gmail.com)';
const sleep = ms => new Promise(r => setTimeout(r, ms));
const COUNTRY_FIX = { UK: 'United Kingdom', USA: 'United States' };

async function search(q) {
  await sleep(1100);
  const r = await fetch(`https://nominatim.openstreetmap.org/search?format=jsonv2&limit=1&q=${encodeURIComponent(q)}`,
    { headers: { 'user-agent': UA } });
  if (!r.ok) return null;
  const [hit] = await r.json();
  return hit ? { lat: +hit.lat, lng: +hit.lon, what: hit.display_name } : null;
}

(async () => {
  const db = getFirestore();
  const snap = await db.collection('businesses').get();
  const missing = snap.docs.filter(d => {
    const { lat, lng } = d.data();
    return typeof lat !== 'number' || typeof lng !== 'number' || (lat === 0 && lng === 0);
  });
  console.log(`${missing.length} bedrifter uten GPS-posisjon\n`);
  let found = 0, cityOnly = 0;
  const notFound = [];
  for (const d of missing) {
    const b = d.data();
    const country = COUNTRY_FIX[b.country] || b.country || '';
    const address = String(b.address || '').trim();
    // 1) full address  2) address + country  3) name + address (for "Stockholm" only)
    let hit = null, how = '';
    if (address) {
      hit = await search(address.toLowerCase().includes(country.toLowerCase()) ? address : `${address}, ${country}`);
      how = 'adresse';
    }
    if (!hit && b.name && address) { hit = await search(`${b.name}, ${address}`); how = 'navn+adresse'; }
    if (!hit) { notFound.push(`${b.name} | "${address}" | ${country}`); continue; }
    found++;
    // Address is only a city (no digits) → position is the city centre, not the door
    if (!/\d/.test(address)) cityOnly++;
    console.log(`✔ ${b.name.padEnd(34).slice(0, 34)} ${hit.lat.toFixed(4)},${hit.lng.toFixed(4)}  ← ${how}: ${hit.what.slice(0, 70)}`);
    if (WRITE) await d.ref.update({ lat: hit.lat, lng: hit.lng, positionFrom: 'nominatim' });
  }
  console.log(`\n${found} funnet (${cityOnly} av dem bare bysentrum), ${notFound.length} ikke funnet`);
  if (notFound.length) console.log('Ikke funnet:\n  ' + notFound.join('\n  '));
  if (!WRITE) console.log('\nℹ️  Ingenting lagret. Kjør med --write for å lagre.');
  process.exit(0);
})().catch(e => { console.error('❌', e.message); process.exit(1); });
