// Viser alle leverandører (publicName) i Firestore, så du vet hvilket navn
// du skal bruke med sync_bunny.js.
//
// Kjør:   node tools/list_services.js
// Filter: node tools/list_services.js flight
const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const serviceAccount = require(require('path').join(__dirname, '..', 'serviceAccountKey.json'));
initializeApp({ credential: cert(serviceAccount) });

(async () => {
  const filter = (process.argv[2] || '').toLowerCase();
  const snap = await getFirestore().collection('anonymous_services').get();
  const rows = snap.docs.map(d => {
    const x = d.data();
    const imgs = Array.isArray(x.sampleImages) ? x.sampleImages.length : 0;
    const vids = Array.isArray(x.sampleVideoUrls) ? x.sampleVideoUrls.length : 0;
    return { name: x.publicName || '(uten navn)', cat: x.category || '', country: x.country || '', imgs, vids };
  }).filter(r => !filter || `${r.name} ${r.cat} ${r.country}`.toLowerCase().includes(filter))
    .sort((a, b) => a.cat.localeCompare(b.cat) || a.name.localeCompare(b.name));

  console.log(`\n${rows.length} leverandører:\n`);
  for (const r of rows) {
    console.log(`  "${r.name}"   [${r.cat}${r.country ? ' · ' + r.country : ''}]   📷 ${r.imgs}  🎬 ${r.vids}`);
  }
  console.log('\nBruk navnet i anførselstegn, f.eks.:');
  console.log('  node tools/sync_bunny.js "Navn her" --folder="Mappe i Bunny"\n');
  process.exit(0);
})().catch(e => { console.error('❌', e.message); process.exit(1); });
