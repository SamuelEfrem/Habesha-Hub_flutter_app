// Legger inn Habesha-kirker fra tools/churches.json i `businesses`.
//   node tools/import_churches.js          (viser hva som skjer, lagrer ingenting)
//   node tools/import_churches.js --write  (lagrer i Firestore)
// Sletter aldri. Kirker som finnes fra før får bare merking, og ny beskrivelse hvis ingen eier dem
// (churchCommunity, churchTradition); bilder, eier og vurderinger røres ikke.
const path = require('path'), crypto = require('crypto');
const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const serviceAccount = require(path.join(__dirname, '..', 'serviceAccountKey.json'));
const list = require('./churches.json');

const WRITE = process.argv.includes('--write');
const norm = s => String(s || '').toLowerCase().normalize('NFD').replace(/[^a-z0-9]+/g, '');

(async () => {
  initializeApp({ credential: cert(serviceAccount) });
  const db = getFirestore();
  const live = (await db.collection('businesses').where('category', '==', 'Church').get()).docs;
  const byName = new Map(live.map(d => [norm(d.data().name) + '|' + d.data().country, d]));
  const byOsm = new Map(live.filter(d => d.data().osmId).map(d => [d.data().osmId, d]));

  const add = [], update = [];
  for (const c of list) {
    const old = byName.get(norm(c.name) + '|' + c.country) || (c.osmId && byOsm.get(c.osmId.replace('_', '/')));
    if (old) { update.push([old, c]); continue; }
    add.push(c);
  }
  // already in the app but not in the list: tag them too
  const hit = new Set(update.map(([d]) => d.id));
  const rest = live.filter(d => !hit.has(d.id)).length;

  console.log(`${list.length} i lista · ${add.length} nye · ${update.length} finnes (får merking) · ${rest} andre kirker i appen urørt`);
  const by = {}; add.forEach(c => by[c.country] = (by[c.country] || 0) + 1);
  console.log('Nye per land:', Object.entries(by).sort((a, b) => b[1] - a[1]).map(([k, v]) => `${k} ${v}`).join(', '));
  if (!WRITE) { console.log('\nIngenting lagret. Kjør med --write for å lagre.'); process.exit(0); }

  const ops = [
    ...add.map(c => b => b.set(db.collection('businesses').doc('church_' + crypto.createHash('sha1').update(c.name + c.country + c.address).digest('hex').slice(0, 16)), {
      name: c.name, category: 'Church', description: c.description, address: c.address, lat: c.lat, lng: c.lng, country: c.country,
      phone: c.phone || '', website: c.website || null, imageUrl: '', rating: 0, ratingCount: 0, isOpen: false, isPremium: false,
      pdfMenuUrl: null, openingHours: {}, galleryImages: [], promoVideoUrl: null, ownerId: '', ownerEmail: '', ownerName: '',
      status: 'approved', source: c.source, osmId: c.osmId ? c.osmId.replace('_', '/') : null, churchCommunity: c.community, churchTradition: c.tradition,
    })),
    ...update.map(([d, c]) => b => b.update(d.ref, { ...(d.data().ownerId ? {} : { description: c.description }), churchCommunity: c.community, churchTradition: c.tradition })),
  ];
  for (let i = 0; i < ops.length; i += 400) {
    const batch = db.batch();
    ops.slice(i, i + 400).forEach(f => f(batch));
    await batch.commit();
    console.log(`lagret ${Math.min(i + 400, ops.length)}/${ops.length}`);
  }
  console.log('Ferdig!');
  process.exit(0);
})().catch(e => { console.error(e.message); process.exit(1); });
