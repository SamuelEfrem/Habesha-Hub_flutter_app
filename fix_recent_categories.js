const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const serviceAccount = require('C:/Users/samue/Desktop/habesha-hub-7bd1d-firebase-adminsdk-fbsvc-783a8d4517.json');

initializeApp({ credential: cert(serviceAccount) });
const db = getFirestore();

const categoryMap = {
  'Butikk': 'Shop',
  'Kafé': 'Cafe',
  'Kafe': 'Cafe',
  'Frisør': 'Barber',
  'Klinikk': 'Clinic',
  'Fotograf': 'Photographer',
  'Musikk': 'Music',
  'Dekorasjon': 'Decoration',
  'Annet': 'Other',
};

async function fixCategories() {
  const snap = await db.collection('businesses').get();
  let updated = 0;
  let skipped = 0;

  for (const doc of snap.docs) {
    const data = doc.data();
    const oldCat = data.category;
    const newCat = categoryMap[oldCat];

    if (newCat && newCat !== oldCat) {
      await db.collection('businesses').doc(doc.id).update({ category: newCat });
      console.log(`✅ ${data.name}: ${oldCat} → ${newCat}`);
      updated++;
    } else {
      skipped++;
    }
  }

  console.log(`\nDone! Updated: ${updated} | Skipped: ${skipped}`);
  process.exit(0);
}

fixCategories();
