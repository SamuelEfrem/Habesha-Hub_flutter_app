// Sends one test message ("notice") to the owner of a business, to test push + Profile → Messages.
//   node tools/test_notice.js "Test Hostel"
const path = require('path');
const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
initializeApp({ credential: cert(require(path.join(__dirname, '..', 'serviceAccountKey.json'))) });
const db = getFirestore();
(async () => {
  const name = process.argv[2] || 'Test Hostel';
  const q = await db.collection('businesses').where('name', '==', name).limit(1).get();
  if (q.empty) throw new Error(`No business named "${name}"`);
  const b = q.docs[0];
  const toUid = b.data().ownerId;
  if (!toUid) throw new Error('That business has no ownerId');
  const prev = await db.collection('notices').where('toUid', '==', toUid).get();
  console.log(`Owner ${toUid.slice(0, 6)}… has ${prev.size} message(s) already`);
  await db.collection('notices').add({
    toUid, kind: 'fix', title: 'Please fix before approval', refType: 'business', refId: b.id, refName: name,
    body: 'TEST: Please add a clear photo. · በጃኹም ንጹር ስእሊ ወስኹ።', read: false, createdAt: FieldValue.serverTimestamp(),
  });
  console.log('Sent.');
  process.exit(0);
})().catch(e => { console.error(e.message); process.exit(1); });
