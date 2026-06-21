const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const serviceAccount = require('./serviceAccountKey.json');

initializeApp({ credential: cert(serviceAccount) });
const db = getFirestore();

async function run() {
  const snap = await db.collection('businesses').get();
  for (const doc of snap.docs) {
    const data = doc.data();
    if (data.country) continue;
    const addr = (data.address || '').toLowerCase();
    let country = '';
    if (addr.includes('uganda') || addr.includes('kampala') || addr.includes('entebbe') || addr.includes('jinja')) country = 'Uganda';
    else if (addr.includes('ethiopia') || addr.includes('etiopia') || addr.includes('addis')) country = 'Etiopia';
    else if (addr.includes('eritrea') || addr.includes('asmara')) country = 'Eritrea';
    else if (addr.includes('egypt') || addr.includes('cairo')) country = 'Egypt';
    else if (addr.includes('kenya') || addr.includes('nairobi')) country = 'Kenya';
    else if (addr.includes('norway') || addr.includes('norge') || addr.includes('oslo') || addr.includes('bergen') || addr.includes('stavanger') || addr.includes('trondheim')) country = 'Norge';
    else if (addr.includes('sweden') || addr.includes('sverige') || addr.includes('stockholm')) country = 'Sverige';
    else if (addr.includes('denmark') || addr.includes('copenhagen')) country = 'Danmark';
    else if (addr.includes('london') || addr.includes('uk') || addr.includes('england')) country = 'UK';
    else if (addr.includes('germany') || addr.includes('berlin') || addr.includes('hamburg')) country = 'Tyskland';
    else if (addr.includes('usa') || addr.includes('new york') || addr.includes('washington') || addr.includes('minneapolis')) country = 'USA';
    else if (addr.includes('canada') || addr.includes('toronto') || addr.includes('ottawa')) country = 'Canada';
    
    if (country) {
      await doc.ref.update({ country });
      console.log(doc.id + ' -> ' + country);
    } else {
      console.log('IKKE FUNNET: ' + doc.id + ' addr: ' + data.address);
    }
  }
  console.log('Ferdig!');
  process.exit(0);
}

run().catch(console.error);