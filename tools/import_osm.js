// ═══════════════════════════════════════════════════════════
// Henter habesha-bedrifter fra hele verden (OpenStreetMap) og legger
// dem inn i Firestore "businesses" — med adresse og GPS-posisjon.
//
//   Finner: alt merket cuisine=ethiopian/eritrean, pluss butikker,
//           kafeer, frisører osv. med habesha-navn (Habesha, Addis,
//           Asmara, Abyssinia, Ethiopian, Eritrean, Äthiopisch, Etiopisk …)
//           i ~55 land (navnesøk hos OpenStreetMap Nominatim, 1 per sekund —
//           første gang tar det ca. 15–20 minutter)
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
const ENDPOINTS = ['https://overpass-api.de/api/interpreter', 'https://overpass.private.coffee/api/interpreter'];
const sleep = ms => new Promise(r => setTimeout(r, ms));

// Places tagged cuisine=ethiopian/eritrean: one small Overpass query
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

// Shops, barbers, cafés … with a Habesha name: Nominatim name search per
// country (a worldwide Overpass name scan is too heavy for the free servers).
// Nominatim rules: max 1 request per second, a real User-Agent.
const WORDS = ['habesha', 'abesha', 'ethiopian', 'ethiopia', 'eritrean', 'eritrea',
  'abyssinia', 'addis', 'asmara', 'injera', 'lalibela', 'axum'];
const LOCAL_WORDS = {
  de: ['äthiopisch', 'eritreisch', 'habescha'], at: ['äthiopisch', 'eritreisch', 'habescha'],
  ch: ['äthiopisch', 'eritreisch', 'éthiopien', 'érythréen'], fr: ['éthiopien', 'érythréen'],
  be: ['éthiopien', 'érythréen', 'ethiopisch'], nl: ['ethiopisch', 'eritrees'],
  lu: ['éthiopien'], ca: ['éthiopien', 'érythréen'], it: ['etiope', 'eritreo', 'etiopico'],
  no: ['etiopisk', 'eritreisk'], se: ['etiopisk', 'eritreansk'], dk: ['etiopisk', 'eritreisk'],
  fi: ['etiopialainen'], es: ['etíope'], pt: ['etíope'],
};
const COUNTRIES = ['us', 'ca', 'gb', 'ie', 'de', 'at', 'ch', 'fr', 'be', 'nl', 'lu', 'it', 'es', 'pt',
  'no', 'se', 'dk', 'fi', 'is', 'pl', 'cz', 'gr', 'au', 'nz', 'za', 'ke', 'ug', 'tz', 'rw', 'ss',
  'sd', 'dj', 'so', 'eg', 'ng', 'gh', 'il', 'lb', 'jo', 'sa', 'ae', 'qa', 'kw', 'bh', 'om', 'tr',
  'cn', 'in', 'th', 'my', 'jp', 'kr', 'br', 'mx', 'ar',
  'et', 'er'];
const NAME_KINDS = {
  amenity: ['restaurant', 'cafe', 'fast_food', 'bar', 'pub', 'nightclub', 'clinic', 'doctors',
    'dentist', 'pharmacy', 'money_transfer', 'bureau_de_change', 'ice_cream'],
  tourism: ['hotel', 'guest_house', 'hostel', 'motel', 'apartment'],
  shop: null, craft: null,                         // null = every type
};

async function nominatimSearch(word, cc) {
  const out = [];
  let exclude = [];
  for (let page = 0; page < 4; page++) {            // max 4 × 40 hits per word + country
    await sleep(1100);
    const url = `https://nominatim.openstreetmap.org/search?format=jsonv2&addressdetails=1&extratags=1` +
      `&limit=40&countrycodes=${cc}&q=${encodeURIComponent(word)}` +
      (exclude.length ? `&exclude_place_ids=${exclude.join(',')}` : '');
    let r;
    for (let tryNo = 0; tryNo < 3; tryNo++) {
      try { r = await fetch(url, { headers: { 'user-agent': UA }, signal: AbortSignal.timeout(30000) }); break; }
      catch (_) { await sleep(5000); }
    }
    if (!r || !r.ok) throw new Error(`Nominatim ${r ? r.status : 'svarer ikke'}`);
    const hits = await r.json();
    out.push(...hits);
    if (hits.length < 40) break;
    exclude = [...exclude, ...hits.map(h => h.place_id)];
  }
  return out;
}

// Nominatim answer → same shape as an Overpass element, so the rest works the same
function toElement(h) {
  const a = h.address || {}, x = h.extratags || {};
  return {
    type: h.osm_type, id: h.osm_id, lat: +h.lat, lon: +h.lon,
    tags: {
      ...x,
      name: h.name,
      [h.category]: h.type,
      'addr:street': a.road || a.pedestrian || a.square,
      'addr:housenumber': a.house_number,
      'addr:postcode': a.postcode,
      'addr:city': a.city || a.town || a.village || a.suburb,
    },
  };
}

// Name matches that are not Habesha businesses (checked by hand)
const NOT_HABESHA = /ambassador|embassy|ambassade|Addis Car|Addis Informatique|Maison Addis|Addis Matome|Addis Medical|Addis Ababa Courts|Addis Abeba\[r\]|Lalibela par|^Asmara$ .*interior/i;

function isHabeshaBusiness(h, word) {
  if (!h.name || !h.name.toLowerCase().includes(word.toLowerCase())) return false;
  if (NOT_HABESHA.test(h.name) || (h.name === 'Asmara' && h.type === 'interior_decoration')) return false;
  if (!(h.category in NAME_KINDS)) return false;
  const kinds = NAME_KINDS[h.category];
  return kinds === null || kinds.includes(h.type);
}

// Every finished search is saved in .osm-cache.json, so if one fails the
// next run only asks for what is missing. --fresh starts over.
const OSM_CACHE = path.join(__dirname, '..', '.osm-cache.json');
async function loadOsm() {
  let done = {};
  if (!has('fresh')) try { done = JSON.parse(fs.readFileSync(OSM_CACHE, 'utf8')); } catch (_) {}
  const save = () => fs.writeFileSync(OSM_CACHE, JSON.stringify(done));
  const failed = [];

  const CUISINE = 'Etiopisk/eritreisk mat';
  if (done[CUISINE]) console.log(`   ✔ ${CUISINE}: ${done[CUISINE].length} (lagret fra før)`);
  else {
    try { done[CUISINE] = await overpass(`nwr["cuisine"~"ethiopian|eritrean",i];`); save(); console.log(`   ✔ ${CUISINE}: ${done[CUISINE].length}`); }
    catch (e) { failed.push(CUISINE); console.log(`   ✖ ${CUISINE}: ${e.message}`); }
  }

  let searches = 0, found = 0;
  for (const cc of COUNTRIES) {
    // In Ethiopia/Eritrea almost every name contains "Addis", "Ethiopia" … — only clear Habesha words there
    // In Ethiopia/Eritrea almost every name says "Addis"/"Ethiopia"; in France, Ghana and
    // South Africa "Addis" is an ordinary name → skip those words there
    const words = (cc === 'et' || cc === 'er') ? ['habesha', 'injera']
      : [...WORDS, ...(LOCAL_WORDS[cc] || [])].filter(w => !(w === 'addis' && ['fr', 'gh', 'za'].includes(cc)));
    let inCountry = 0;
    for (const w of words) {
      const key = `Navn: ${cc} ${w}`;
      if (!done[key]) {
        try {
          done[key] = (await nominatimSearch(w, cc)).filter(h => isHabeshaBusiness(h, w)).map(toElement);
          save();
          searches++;
        } catch (e) { failed.push(key); continue; }
      }
      inCountry += done[key].length;
    }
    found += inCountry;
    console.log(`   ✔ ${cc.toUpperCase()}: ${inCountry} treff`);
  }
  console.log(`   (${searches} nye søk, ${found} navnetreff totalt)`);
  if (failed.length) console.log(`\n⚠️  ${failed.length} søk feilet — kjør på nytt senere for å hente dem: ${failed.slice(0, 10).join(', ')}`);

  const all = new Map();
  for (const [key, els] of Object.entries(done)) {
    if (/^Navn: -?\d/.test(key)) continue;          // old grid searches (replaced)
    if (/^Navn: (fr|gh|za) addis$/.test(key)) continue;
    for (const e of els) {
      const t = e.tags || {};
      if (key.startsWith('Navn: ') && (NOT_HABESHA.test(t.name || '') ||
          (t.name === 'Asmara' && t.shop === 'interior_decoration'))) continue;
      all.set(`${e.type}_${e.id}`, e);
    }
  }
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
  if (s === 'travel_agency') return 'Other';
  if (t.craft === 'caterer') return 'Restaurant';
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

  const docs = [], skipped = [], dupIds = [];
  let lookups = 0;
  for (const e of els) {
    const t = e.tags, lat = e.lat ?? e.center?.lat, lng = e.lon ?? e.center?.lon;
    if (lat == null || lng == null) continue;
    const id = `osm_${e.type}_${e.id}`;
    if (claimed.has(id)) continue;
    // Same name within 2 km (some old entries only have the city as position)
    const dup = mine.find(b => km(lat, lng, b.lat || 0, b.lng || 0) < 2 && norm(b.name) && norm(b.name) === norm(t.name));
    if (dup) { skipped.push(`${t.name}  (finnes allerede)`); dupIds.push(id); continue; }
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

  const already = new Set(existing.map(d => d.id));
  const fresh = docs.filter(d => !already.has(d.id)).length;
  // Imported earlier, but the same place is now also in the app as a real entry → hide the copy
  const hideDups = dupIds.filter(id => already.has(id) &&
    existing.find(d => d.id === id).data().status !== 'rejected');
  console.log(`\n   ${fresh} nye, ${docs.length - fresh} finnes fra før (bare OSM-data oppdateres), ${hideDups.length} dubletter skjules`);

  if (!has('write')) { console.log('\nℹ️  Ingenting lagret. Kjør med --write for å lagre i Firestore.'); process.exit(0); }
  // Already imported: refresh only what comes from OpenStreetMap —
  // never reset ratings, photos, status or premium.
  const OSM_FIELDS = ['name', 'category', 'address', 'lat', 'lng', 'country', 'phone', 'website', 'openingHours', 'osmId'];
  for (let i = 0; i < docs.length; i += 400) {
    const batch = db.batch();
    for (const d of docs.slice(i, i + 400)) {
      const ref = db.collection('businesses').doc(d.id);
      if (already.has(d.id)) batch.update(ref, Object.fromEntries(OSM_FIELDS.map(k => [k, d.data[k]])));
      else batch.set(ref, d.data);
    }
    await batch.commit();
    console.log(`   💾 ${Math.min(i + 400, docs.length)}/${docs.length} lagret`);
  }
  if (hideDups.length) {
    const batch = db.batch();
    for (const id of hideDups) batch.update(db.collection('businesses').doc(id), { status: 'rejected', hiddenReason: 'duplicate' });
    await batch.commit();
    console.log(`   🙈 ${hideDups.length} dubletter skjult`);
  }
  console.log('\n🎉 Ferdig!');
  process.exit(0);
}
run().catch(e => { console.error('❌', e.message || e); process.exit(1); });
