const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const serviceAccount = require('C:/Users/samue/Desktop/habesha-hub-7bd1d-firebase-adminsdk-fbsvc-783a8d4517.json');

initializeApp({ credential: cert(serviceAccount) });
const db = getFirestore();

const countryMap = {
  'Norge': 'Norway',
  'Sverige': 'Sweden',
  'Danmark': 'Denmark',
  'Tyskland': 'Germany',
  'Nederland': 'Netherlands',
  'Frankrike': 'France',
  'Belgia': 'Belgium',
  'Sveits': 'Switzerland',
  'Italia': 'Italy',
  'Amerika': 'Americas',
  'Sør-Sudan': 'South Sudan',
};

async function updateCountries() {
  const snap = await db.collection('businesses').get();
  let updated = 0;
  let skipped = 0;

  for (const doc of snap.docs) {
    const data = doc.data();
    const oldCountry = data.country;
    const newCountry = countryMap[oldCountry];

    if (newCountry && newCountry !== oldCountry) {
      await db.collection('businesses').doc(doc.id).update({ country: newCountry });
      console.log(`✅ ${data.name}: ${oldCountry} → ${newCountry}`);
      updated++;
    } else {
      skipped++;
    }
  }

  console.log(`\nDone! Updated: ${updated} | Skipped: ${skipped}`);
  process.exit(0);
}

updateCountries();
