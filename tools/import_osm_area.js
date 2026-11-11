// ═══════════════════════════════════════════════════════════
// Imports businesses for whole areas from OpenStreetMap (in Ethiopia every
// place is Habesha, so no name filter is needed):
//   tigray  – every named restaurant, café, bar, hotel, shop, hair salon,
//             clinic, hospital, pharmacy and church in Tigray
//   addis   – only the big and known places in Addis Ababa: hotels and
//             supermarkets with stars / website / phone / brand, malls,
//             department stores, hospitals, and restaurants, cafés and bars
//             with a website, phone, brand or Wikipedia entry
//
// Run:
//   node tools/import_osm_area.js tigray addis            (only shows what would be added)
//   node tools/import_osm_area.js tigray addis --write    (saves in Firestore)
//
// Safe to run again: every place gets id "osm_<type>_<id>" and is updated, not
// duplicated. A place that is already in the app (same name within 2 km) is
// skipped. Places an owner has claimed, or the admin has rejected, are never touched.
// The address is the street from OpenStreetMap, or "near <town>" (no slow lookups).
// Data © OpenStreetMap contributors (ODbL).
// ═══════════════════════════════════════════════════════════
const path = require('path');
const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

const args = process.argv.slice(2);
const WRITE = args.includes('--write');
const UA = 'habesha-hub-import/1.0 (support@habesha-hub.no)';
const sleep = ms => new Promise(r => setTimeout(r, ms));

const AREAS = {
  tigray: {
    label: 'Tigray',
    area: '["boundary"="administrative"]["name:en"~"^Tigray"]',
    body: `
      nwr(area.a)["name"]["amenity"~"^(restaurant|cafe|fast_food|bar|pub|nightclub|clinic|hospital|doctors|dentist|pharmacy|place_of_worship)$"];
      nwr(area.a)["name"]["shop"];
      nwr(area.a)["name"]["tourism"~"^(hotel|guest_house|hostel|motel)$"];`,
    keep: () => true,
    towns: [['Mekelle', 13.4967, 39.4753], ['Adigrat', 14.2770, 39.4620], ['Aksum', 14.1211, 38.7239], ['Shire', 14.1000, 38.2833],
      ['Adwa', 14.1667, 38.9000], ['Wukro', 13.7833, 39.6000], ['Alamata', 12.4167, 39.5500], ['Maychew', 12.7833, 39.5333],
      ['Humera', 14.2950, 36.6167], ['Abiy Addi', 13.6200, 39.0000], ['Korem', 12.5050, 39.5228], ['Hawzen', 13.9750, 39.4300],
      ['Sheraro', 14.4000, 37.7667], ['Enticho', 14.2667, 39.1500], ['Zalambessa', 14.5167, 39.3833], ['Adi Remets', 13.8667, 37.4000]],
  },
  eritrea: {
    label: 'Eritrea',
    country: 'Eritrea',
    area: '["boundary"="administrative"]["admin_level"="2"]["name:en"="Eritrea"]',
    body: `
      nwr(area.a)["name"]["amenity"~"^(restaurant|cafe|fast_food|bar|pub|nightclub|clinic|hospital|doctors|dentist|pharmacy|place_of_worship)$"];
      nwr(area.a)["name"]["shop"];
      nwr(area.a)["name"]["tourism"~"^(hotel|guest_house|hostel|motel)$"];`,
    keep: () => true,
    towns: [['Asmara', 15.3229, 38.9251], ['Keren', 15.7778, 38.4511], ['Massawa', 15.6097, 39.4500], ['Mendefera', 14.8872, 38.8153],
      ['Barentu', 15.1058, 37.5907], ['Assab', 13.0092, 42.7394], ['Dekemhare', 15.0700, 39.0475], ['Adi Keyh', 14.8444, 39.3767],
      ['Agordat', 15.5486, 37.8867], ['Nakfa', 16.6639, 38.4761], ['Ghinda', 15.4500, 39.0833], ['Senafe', 14.7000, 39.4167],
      ['Adi Quala', 14.6333, 38.8333], ['Tesseney', 15.1100, 36.6575], ['Segeneiti', 15.0333, 39.3167], ['Afabet', 16.1933, 38.6950]],
  },
  addis: {
    label: 'Addis Ababa',
    area: '["boundary"="administrative"]["name:en"="Addis Ababa"]',
    body: `
      nwr(area.a)["name"]["tourism"="hotel"];
      nwr(area.a)["name"]["shop"~"^(mall|supermarket|department_store)$"];
      nwr(area.a)["name"]["amenity"="hospital"];
      nwr(area.a)["name"]["amenity"~"^(restaurant|cafe|bar|nightclub)$"];`,
    // only the big and known ones
    keep: t => {
      const known = !!(t.website || t['contact:website'] || t.wikidata || t.brand || t.stars || t.phone || t['contact:phone']);
      if (t.shop === 'mall' || t.shop === 'department_store' || t.amenity === 'hospital') return true;
      if (t.tourism === 'hotel') return !!(t.stars || t.website || t['contact:website'] || t.wikidata || t.brand);
      return known;
    },
    towns: [['Addis Ababa', 9.0108, 38.7613]],
  },
};

async function overpass(a) {
  const q = `[out:json][timeout:300];area${a.area}->.a;(${a.body});out center tags;`;
  for (let i = 0; i < 4; i++) {
    const ep = ['https://overpass-api.de/api/interpreter', 'https://overpass.private.coffee/api/interpreter'][i % 2];
    try {
      const r = await fetch(ep, { method: 'POST', body: 'data=' + encodeURIComponent(q),
        headers: { 'content-type': 'application/x-www-form-urlencoded', 'user-agent': UA } });
      if (r.ok) return (await r.json()).elements;
      console.log(`   ⏳ ${new URL(ep).host} answered ${r.status}, trying again …`);
    } catch (e) { console.log(`   ⏳ ${e.message}, trying again …`); }
    await sleep(15000 * (i + 1));
  }
  throw new Error('OpenStreetMap does not answer – try again later');
}

function category(t) {
  const a = t.amenity, s = t.shop;
  if (['restaurant', 'fast_food', 'food_court'].includes(a)) return 'Restaurant';
  if (a === 'cafe' || s === 'coffee') return 'Cafe';
  if (['bar', 'pub', 'nightclub'].includes(a)) return 'Club';
  if (['clinic', 'doctors', 'dentist', 'pharmacy', 'hospital'].includes(a)) return 'Clinic';
  if (['hairdresser', 'beauty'].includes(s)) return 'Barber';
  if (['hotel', 'guest_house', 'hostel', 'motel'].includes(t.tourism)) return 'Hotel';
  if (a === 'place_of_worship') return t.religion === 'christian' ? 'Church' : 'Other';
  if (s) return 'Shop';
  return 'Other';
}

const WHAT = { Restaurant: 'Restaurant', Cafe: 'Café', Club: 'Bar', Clinic: 'Clinic', Barber: 'Hair salon',
  Hotel: 'Hotel', Shop: 'Shop', Church: 'Church', Other: 'Place' };
function description(t, cat, town) {
  if (t.description) return t.description;
  if (t.amenity === 'hospital') return `Hospital in ${town}`;
  if (t.shop === 'mall') return `Shopping mall in ${town}`;
  if (t.shop === 'supermarket') return `Supermarket in ${town}`;
  if (cat === 'Church') return /orthodox|tewahedo/i.test(`${t.denomination} ${t.name}`) || !t.denomination ? `Orthodox Tewahedo church in ${town}` : `Church in ${town}`;
  if (t.amenity === 'place_of_worship' && t.religion === 'muslim') return `Mosque in ${town}`;
  return `${WHAT[cat]}${t.stars ? ` (${t.stars}★)` : ''} in ${town}`;
}

function km(aLat, aLng, bLat, bLng) {
  const r = Math.PI / 180, dLat = (bLat - aLat) * r, dLng = (bLng - aLng) * r;
  const x = Math.sin(dLat / 2) ** 2 + Math.cos(aLat * r) * Math.cos(bLat * r) * Math.sin(dLng / 2) ** 2;
  return 12742 * Math.asin(Math.sqrt(x));
}
const nearestTown = (towns, lat, lng) => towns.reduce((b, t) => km(lat, lng, t[1], t[2]) < km(lat, lng, b[1], b[2]) ? t : b)[0];
const norm = s => (s || '').toLowerCase().normalize('NFD').replace(/[̀-ͯ]/g, '')
  .replace(/\b(restaurant|cafe|kafe|bar|hotel|the|and|&)\b/g, '').replace(/[^a-z0-9ሀ-፿]/g, '');

const SHORT = { Mo: 'Man', Tu: 'Tir', We: 'Ons', Th: 'Tor', Fr: 'Fre', Sa: 'Lør', Su: 'Søn' };
const DAYS = { Mo: 'Mandag', Tu: 'Tirsdag', We: 'Onsdag', Th: 'Torsdag', Fr: 'Fredag', Sa: 'Lørdag', Su: 'Søndag' };
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

(async () => {
  const want = args.filter(a => AREAS[a]);
  if (!want.length) { console.log('Use: node tools/import_osm_area.js tigray addis [--write]'); process.exit(1); }

  initializeApp({ credential: cert(require(path.join(__dirname, '..', 'serviceAccountKey.json'))) });
  const db = getFirestore();
  const existing = (await db.collection('businesses').get()).docs;
  const already = new Set(existing.map(d => d.id));
  const mine = existing.filter(d => !d.id.startsWith('osm_')).map(d => d.data());
  const locked = new Set(existing.filter(d => d.data().ownerId || d.data().status === 'rejected').map(d => d.id));

  const docs = [], skipped = [];
  for (const key of want) {
    const A = AREAS[key];
    console.log(`🌍 ${A.label}: asking OpenStreetMap …`);
    const els = await overpass(A);
    const seen = new Set();
    let n = 0;
    for (const e of els) {
      const t = e.tags || {}, lat = e.lat ?? e.center?.lat, lng = e.lon ?? e.center?.lon;
      const id = `osm_${e.type}_${e.id}`;
      if (lat == null || lng == null || seen.has(id) || locked.has(id) || !A.keep(t)) continue;
      seen.add(id);
      const name = (t['name:en'] || t.name || '').trim();
      if (!name || /^(church|mosque|hotel|cafe|restaurant|shop|bar)$/i.test(name)) continue;
      if (mine.find(b => km(lat, lng, b.lat || 0, b.lng || 0) < 2 && norm(b.name) && norm(b.name) === norm(name))) {
        skipped.push(name); continue;
      }
      const cat = category(t), town = t['addr:city'] || nearestTown(A.towns, lat, lng);
      const street = [t['addr:street'], t['addr:housenumber']].filter(Boolean).join(' ');
      docs.push({ id, area: key, data: {
        name, category: cat, description: description(t, cat, town),
        address: street ? `${street}, ${town}` : town, lat, lng, country: 'Ethiopia',
        phone: t.phone || t['contact:phone'] || '', website: t.website || t['contact:website'] || null,
        imageUrl: '', rating: 0, ratingCount: 0, isOpen: false, isPremium: false, pdfMenuUrl: null,
        openingHours: hours(t.opening_hours), galleryImages: [], promoVideoUrl: null,
        ownerId: '', ownerEmail: '', ownerName: '', status: 'approved',
        source: 'osm', osmId: `${e.type}/${e.id}`, importRegion: key,
      }});
      n++;
    }
    console.log(`   ✔ ${n} places`);
  }

  const count = (list, k) => list.reduce((m, d) => (m[d.data[k]] = (m[d.data[k]] || 0) + 1, m), {});
  for (const key of want) {
    const list = docs.filter(d => d.area === key);
    console.log(`\n${AREAS[key].label}: ${list.length} places`);
    console.log('   Categories:', count(list, 'category'));
    const towns = {};
    for (const d of list) { const tn = d.data.address.split(', ').pop(); towns[tn] = (towns[tn] || 0) + 1; }
    console.log('   Towns:', Object.entries(towns).sort((a, b) => b[1] - a[1]).slice(0, 10).map(([k, v]) => `${k} ${v}`).join(', '));
    console.log('   Examples:', list.filter((_, i) => i % Math.max(1, Math.floor(list.length / 10)) === 0).slice(0, 10)
      .map(d => `${d.data.name} (${d.data.category})`).join(' | '));
  }
  const fresh = docs.filter(d => !already.has(d.id)).length;
  console.log(`\n✅ ${docs.length} in total: ${fresh} new, ${docs.length - fresh} already imported (only OSM data refreshed), ${skipped.length} already in the app (skipped)`);

  if (!WRITE) { console.log('\nℹ️  Nothing saved. Run again with --write to save.'); process.exit(0); }
  const OSM_FIELDS = ['name', 'category', 'address', 'lat', 'lng', 'country', 'phone', 'website', 'openingHours', 'osmId'];
  for (let i = 0; i < docs.length; i += 400) {
    const batch = db.batch();
    for (const d of docs.slice(i, i + 400)) {
      const ref = db.collection('businesses').doc(d.id);
      if (already.has(d.id)) batch.update(ref, Object.fromEntries(OSM_FIELDS.map(k => [k, d.data[k]])));
      else batch.set(ref, d.data);
    }
    await batch.commit();
    console.log(`   💾 ${Math.min(i + 400, docs.length)}/${docs.length} saved`);
  }
  console.log('\n🎉 Done! They are live in the app now (Explore → Ethiopia).');
  process.exit(0);
})().catch(e => { console.error('❌', e.message || e); process.exit(1); });
