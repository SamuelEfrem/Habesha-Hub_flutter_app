const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const serviceAccount = require('C:/Users/samue/Desktop/habesha-hub-7bd1d-firebase-adminsdk-fbsvc-783a8d4517.json');

initializeApp({ credential: cert(serviceAccount) });
const db = getFirestore();

async function fixIsOpen() {
  const snap = await db.collection('businesses').where('isOpen', '==', false).get();
  console.log(`Found ${snap.size} businesses with isOpen: false`);
  
  let updated = 0;
  for (const doc of snap.docs) {
    await db.collection('businesses').doc(doc.id).update({ isOpen: true });
    console.log(`✅ ${doc.data().name}`);
    updated++;
  }

  console.log(`\nDone! Updated: ${updated}`);
  process.exit(0);
}

fixIsOpen();
