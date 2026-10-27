// ═══════════════════════════════════════════════════════════
// Henter habesha-bedrifter fra hele verden (OpenStreetMap) og legger
// dem inn i Firestore "businesses" — med adresse og GPS-posisjon.
//
//   Finner: alt merket cuisine=ethiopian/eritrean, pluss butikker,
//           kafeer, frisører osv. med habesha-navn (Habesha, Addis Ababa,
//           Asmara, Abyssinia, Ethiopian, Eritrean …)
//
// Kjør:
//   node tools/import_osm.js            (bare viser hva som blir lagt inn)
//   node tools/import_osm.js --write    (lagrer i Firestore)
//
// Valg:
//   --fresh            spør OpenStreetMap på nytt om alt (ellers brukes
//                      lagrede svar i .osm-cache.json, og bare søk som
//                      feilet sist blir prøvd igjen)
//
// Trygt å kjøre flere ganger: hver plass får id "osm_<type>_<id>" og blir
// oppdatert, ikke duplisert. Bedrifter som allerede finnes (samme navn
// innen 2 km) hoppes over. Bedrifter en eier har tatt over (ownerId)
// eller som admin har avvist, blir aldri overskrevet.
//
// Data © OpenStreetMap contributors (ODbL) — appen må vise dette.
// ═══════════════════════════════════════════════════════════
const fs = require('fs');
const path = require('path');
const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const serviceAccount = require(path.join(__dirname, '..', 'serviceAccountKey.json'));

const args  = process.argv.slice(2);
const has   = k => args.includes(`--${k}`);
const opt   = k => { const a = args.find(x => x.startsWith(`--${k}=`)); return a ? a.split('=').slice(1).join('=') : null; };
const UA    = 'habesha-hub-import/1.0 (samuelefriem@gmail.com)';

// ── 1. OpenStreetMap ───────────────────────────────────────
// Habesha words in English, German, French, Italian, Swedish … ("thiopi" =
// Ethiopian/Äthiopisch/Éthiopien, "etiop" = Etiopia/Etiopisk)
const NAMES = 'habesha|habescha|abesha|abyssini|abissini|thiopi|etiop|eritr|erythr|rythr|addis([^o]|$)|asmara|injera|lalibela';
const nameQuery = bbox => `
   nwr["shop"]["name"~"${NAMES}",i](${bbox});
   nwr["amenity"~"^(restaurant|cafe|fast_food|bar|pub|nightclub|clinic|doctors|dentist|pharmacy|money_transfer)$"]["name"~"${NAMES}",i](${bbox});
   nwr["craft"]["name"~"${NAMES}",i](${bbox});
   nwr["tourism"~"^(hotel|guest_house|hostel)$"]["name"~"${NAMES}",i](${bbox});`;
// A name search over a big area is too heavy for the servers → the world in
// 10° × 20° squares (south,west,north,east), one at a time
const REGIONS = {};
for (let s = -50; s < 72; s += 10)
  for (let w = -180; w < 180; w += 20) REGIONS[`${s},${w}`] = `${s},${w},${Math.min(s + 10, 72)},${w + 20}`;
const ENDPOINTS = ['https://overpass-api.de/api/interpreter', 'https://overpass.private.coffee/api/interpreter'];
const sleep = ms => new Promise(r => setTimeout(r, ms));

async function overpass(body) {
  const q = `[out:json][timeout:600];(${body});out center tags;`;
  for (let i = 0; i < 4; i++) {
    const ep = ENDPOINTS[i % ENDPOINTS.length];
    try {
      const r = await fetch(ep, { method: 'POST', body: 'data=' + encodeURIComponent(q),
        headers: { 'content-type': 'application/x-www-form-urlencoded', 'user-agent': UA },
        signal: AbortSignal.timeout(900000) });
      if (r.ok) return (await r.json()).elements;
      console.log(`   ⏳ ${new URL(ep).host} svarte ${r.status}, prøver igjen …`);
    } catch (e) { console.log(`   ⏳ ${new URL(ep).host}: ${e.message}, prøver igjen …`); }
    await sleep(20000 * (i + 1));
  }
  throw new Error('OpenStreetMap svarer ikke — prøv igjen senere');
}

// Every finished search is saved in .osm-cache.json, so if a region fails
// the next run only asks for what is missing. --fresh starts over.
const OSM_CACHE = path.join(__dirname, '..', '.osm-cache.json');
async function loadOsm() {
  let done = {};
  if (!has('fresh')) try { done = JSON.parse(fs.readFileSync(OSM_CACHE, 'utf8')); } catch (_) {}
  const parts = { 'Etiopisk/eritreisk mat': `nwr["cuisine"~"ethiopian|eritrean",i];` };
  for (const [name, bbox] of Object.entries(REGIONS)) parts[`Navn: ${name}`] = nameQuery(bbox);
  const failed = [];
  for (const [name, q] of Object.entries(parts)) {
    if (done[name]) { console.log(`   ✔ ${name}: ${done[name].length} (lagret fra før)`); continue; }
    try {
      done[name] = await overpass(q);
      fs.writeFileSync(OSM_CACHE, JSON.stringify(done));
      console.log(`   ✔ ${name}: ${done[name].length}`);
    } catch (e) { failed.push(name); console.log(`   ✖ ${name}: ${e.message}`); }
  }
  if (failed.length) console.log(`\n⚠️  ${failed.length} søk feilet (${failed.join(', ')}) — kjør på nytt senere for å hente dem.`);
  const all = new Map();
  for (const els of Object.values(done)) for (const e of els) all.set(`${e.type}_${e.id}`, e);
  return [...all.values()];
}

// ── 2. Kategori, land, adresse, åpningstider ──────────────
function category(t) {
  const a = t.amenity, s = t.shop;
  if (['restaurant', 'fast_food', 'food_court'].includes(a)) return 'Restaurant';
  if (a === 'cafe' || s === 'coffee') return 'Cafe';
  if (['bar', 'pub', 'nightclub'].includes(a)) return 'Club';
  if (['clinic', 'doctors', 'dentist', 'pharmacy'].includes(a)) return 'Clinic';
  if (['hairdresser', 'beauty'].includes(s) || t.craft === 'hairdresser') return 'Barber';
  if (['hotel', 'guest_house', 'hostel'].includes(t.tourism)) return 'Hotel';
  if (s) return 'Shop';
  if (t.cuisine) return 'Restaurant';
  return 'Other';
}

// Same short names as the businesses already in Firestore
const COUNTRY_FIX = {
  'United States of America': 'USA', 'United Kingdom': 'UK', 'Russian Federation': 'Russia',
  'United Republic of Tanzania': 'Tanzania', 'State of Palestine': 'Palestine',
  "People's Republic of China": 'China', 'Moldova, Republic of': 'Moldova', "Cote d'Ivoire": 'Ivory Coast',
  'Viet Nam': 'Vietnam', 'Korea, Republic of': 'South Korea', 'Czechia': 'Czech Republic',
};
let whichCountry, iso;
function country(lat, lng) {
  if (!whichCountry) {
    whichCountry = require('which-country');
    iso = require('i18n-iso-countries');
    iso.registerLocale(require('i18n-iso-countries/langs/en.json'));
  }
  const a3 = whichCountry([lng, lat]);
  if (!a3) return '';
  const n = iso.getName(iso.alpha3ToAlpha2(a3), 'en') || '';
  return COUNTRY_FIX[n] || n;
}

function osmAddress(t) {
  const street = [t['addr:street'] || t['addr:place'], t['addr:housenumber']].filter(Boolean).join(' ');
  const city = [t['addr:postcode'], t['addr:city'] || t['addr:town'] || t['addr:suburb']].filter(Boolean).join(' ');
  return [street, city].filter(Boolean).join(', ');
}

// Nominatim: max 1 request per second (their usage policy).
// Answers are saved so a second run doesn't ask again.
const ADDR_CACHE = path.join(__dirname, '..', '.osm-address-cache.json');
let addrCache = {};
try { addrCache = JSON.parse(fs.readFileSync(ADDR_CACHE, 'utf8')); } catch (_) {}
async function reverseAddress(lat, lng) {
  const key = `${lat.toFixed(6)},${lng.toFixed(6)}`;
  if (addrCache[key] != null) return addrCache[key];
  addrCache[key] = await nominatim(lat, lng);
  fs.writeFileSync(ADDR_CACHE, JSON.stringify(addrCache));
  return addrCache[key];
}
async function nominatim(lat, lng) {
  await sleep(1100);
  try {
    const r = await fetch(`https://nominatim.openstreetmap.org/reverse?format=jsonv2&zoom=18&accept-language=en&lat=${lat}&lon=${lng}`,
      { headers: { 'user-agent': UA } });
    if (!r.ok) return '';
    const a = (await r.json()).address || {};
    const street = [a.road || a.pedestrian || a.square, a.house_number].filter(Boolean).join(' ');
    const city = [a.postcode, a.city || a.town || a.village || a.suburb].filter(Boolean).join(' ');
    return [street, city].filter(Boolean).join(', ');
  } catch (_) { return ''; }
}

// "Mo-Fr 09:00-18:00; Sa 10:00-16:00; Su off" → {"Man - Fre": "09:00 - 18:00", …}
// (same Norwegian keys the app already uses). Anything complicated is skipped.
const DAYS = { Mo: 'Mandag', Tu: 'Tirsdag', We: 'Onsdag', Th: 'Torsdag', Fr: 'Fredag', Sa: 'Lørdag', Su: 'Søndag' };
const SHORT = { Mo: 'Man', Tu: 'Tir', We: 'Ons', Th: 'Tor', Fr: 'Fre', Sa: 'Lør', Su: 'Søn' };
function hours(oh) {
  if (!oh) return {};
  if (oh.trim() === '24/7') return { 'Man - Søn': '00:00 - 23:59' };
  const out = {};
  for (const part of oh.split(';').map(s => s.trim()).filter(Boolean)) {
    const m = part.match(/^(Mo|Tu|We|Th|Fr|Sa|Su)(?:-(Mo|Tu|We|Th|Fr|Sa|Su))?\s+(off|closed|(\d{1,2}:\d{2})-(\d{1,2}:\d{2}))$/);
    if (!m) return {};
    const key = m[2] ? `${SHORT[m[1]]} - ${SHORT[m[2]]}` : DAYS[m[1]];
    const pad = s => s.padStart(5, '0');
    out[key] = m[3] === 'off' || m[3] === 'closed' ? 'Stengt' : `${pad(m[4])} - ${pad(m[5] === '24:00' ? '23:59' : m[5])}`;
  }
  return out;
}

function description(t, cat) {
  const c = (t.cuisine || '').toLowerCase();
  const kind = c.includes('eritrean') && !c.includes('ethiopian') ? 'Eritrean'
    : c.includes('ethiopian') && c.includes('eritrean') ? 'Ethiopian & Eritrean' : 'Habesha';
  const what = { Restaurant: 'restaurant', Cafe: 'café', Club: 'bar', Clinic: 'clinic', Barber: 'hair salon',
    Hotel: 'hotel', Shop: 'shop', Other: 'business' }[cat];
  return t.description || `${kind} ${what}`;
}

// ── 3. Dubletter ───────────────────────────────────────────
const norm = s => (s || '').toLowerCase().normalize('NFD').replace(/[̀-ͯ]/g, '')
  .replace(/\b(restaurant|restaurang|ristorante|cafe|kafe|bar|the|and|og|&|ethiopian|eritrean)\b/g, '')
  .replace(/[^a-z0-9]/g, '');
function km(aLat, aLng, bLat, bLng) {
  const r = Math.PI / 180, dLat = (bLat - aLat) * r, dLng = (bLng - aLng) * r;
  const x = Math.sin(dLat / 2) ** 2 + Math.cos(aLat * r) * Math.cos(bLat * r) * Math.sin(dLng / 2) ** 2;
  return 12742 * Math.asin(Math.sqrt(x));
}

// ── 4. Kjør ────────────────────────────────────────────────
async function run() {
  console.log('🌍 Henter fra OpenStreetMap …');
  const els = (await loadOsm()).filter(e => e.tags?.name);
  console.log(`   ${els.length} steder med navn\n`);

  initializeApp({ credential: cert(serviceAccount) });
  const db = getFirestore();
  const existing = (await db.collection('businesses').get()).docs;
  const mine = existing.filter(d => !d.id.startsWith('osm_')).map(d => d.data());
  // Taken over by an owner, or rejected by admin → never touch again
  const claimed = new Set(existing.filter(d => d.id.startsWith('osm_') &&
    (d.data().ownerId || d.data().status === 'rejected')).map(d => d.id));

  const docs = [], skipped = [];
  let lookups = 0;
  for (const e of els) {
    const t = e.tags, lat = e.lat ?? e.center?.lat, lng = e.lon ?? e.center?.lon;
    if (lat == null || lng == null) continue;
    const id = `osm_${e.type}_${e.id}`;
    if (claimed.has(id)) continue;
    // Same name within 2 km (some old entries only have the city as position)
    const dup = mine.find(b => km(lat, lng, b.lat || 0, b.lng || 0) < 2 && norm(b.name) && norm(b.name) === norm(t.name));
    if (dup) { skipped.push(`${t.name}  (finnes allerede)`); continue; }
    const cat = category(t);
    let address = osmAddress(t);
    if (!address) { address = await reverseAddress(lat, lng); lookups++; }
    docs.push({ id, data: {
      name: t.name, category: cat, description: description(t, cat),
      address, lat, lng, country: country(lat, lng),
      phone: t.phone || t['contact:phone'] || '', website: t.website || t['contact:website'] || null,
      imageUrl: '', rating: 0, ratingCount: 0, isOpen: false, isPremium: false, pdfMenuUrl: null,
      openingHours: hours(t.opening_hours), galleryImages: [], promoVideoUrl: null,
      ownerId: '', ownerEmail: '', ownerName: '', status: 'approved',
      source: 'osm', osmId: `${e.type}/${e.id}`,
    }});
    if (docs.length % 100 === 0) console.log(`   … ${docs.length} klare (${lookups} adresser slått opp)`);
  }

  const count = k => docs.reduce((m, d) => (m[d.data[k]] = (m[d.data[k]] || 0) + 1, m), {});
  console.log(`\n✅ ${docs.length} bedrifter klare, ${skipped.length} hoppet over (finnes allerede)`);
  console.log('   Kategorier:', count('category'));
  console.log('   Land:', Object.entries(count('country')).sort((a, b) => b[1] - a[1]).map(([k, v]) => `${k || '?'} ${v}`).join(', '));
  console.log(`   Med adresse: ${docs.filter(d => d.data.address).length}, telefon: ${docs.filter(d => d.data.phone).length}, åpningstider: ${docs.filter(d => Object.keys(d.data.openingHours).length).length}`);
  console.log('\n   Eksempler:');
  for (const d of docs.filter((_, i) => i % Math.max(1, Math.floor(docs.length / 12)) === 0).slice(0, 12))
    console.log(`   • [${d.data.category}] ${d.data.name} — ${d.data.address || '(ingen adresse)'}, ${d.data.country}`);
  if (skipped.length) console.log('\n   Hoppet over:\n   ' + skipped.slice(0, 15).join('\n   '));

  if (!has('write')) { console.log('\nℹ️  Ingenting lagret. Kjør med --write for å lagre i Firestore.'); process.exit(0); }
  for (let i = 0; i < docs.length; i += 400) {
    const batch = db.batch();
    for (const d of docs.slice(i, i + 400)) batch.set(db.collection('businesses').doc(d.id), d.data, { merge: true });
    await batch.commit();
    console.log(`   💾 ${Math.min(i + 400, docs.length)}/${docs.length} lagret`);
  }
  console.log('\n🎉 Ferdig!');
  process.exit(0);
}
run().catch(e => { console.error('❌', e.message || e); process.exit(1); });
