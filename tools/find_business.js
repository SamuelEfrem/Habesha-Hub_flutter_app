// node tools/find_business.js "text"   → lists businesses whose name contains the text
const path = require('path');
const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
initializeApp({ credential: cert(require(path.join(__dirname, '..', 'serviceAccountKey.json'))) });
(async () => {
  const q = (process.argv[2] || '').toLowerCase();
  const docs = (await getFirestore().collection('businesses').get()).docs;
  for (const d of docs) {
    const b = d.data();
    if ((b.name || '').toLowerCase().includes(q)) console.log(d.id, '|', b.name, '|', b.category, '|', b.city || '', '|', b.status || '');
  }
  process.exit(0);
})().catch(e => { console.error(e.message); process.exit(1); });
