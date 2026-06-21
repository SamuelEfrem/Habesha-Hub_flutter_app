const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const serviceAccount = require('./serviceAccountKey.json');

initializeApp({ credential: cert(serviceAccount) });
const db = getFirestore();

const businesses = [
  // UGANDA - Kjerne
  { name: 'Mango Restaurant', category: 'Restaurant', address: 'William St, Kampala, Uganda', phone: '', country: 'Uganda', description: 'Etiopisk restaurant i Kampala', openingHours: {'Man - Søn': '08:00 - 21:00'} },
  { name: 'Torino Bar & Restaurant', category: 'Restaurant', address: 'Park Lane, Kampala, Uganda', phone: '+256 701 945758', country: 'Uganda', description: 'Restaurant med Habesha klientell i Kampala', openingHours: {'Man - Søn': '07:30 - 23:30'} },
  { name: 'Ethio Uganda Bar & Restaurant', category: 'Restaurant', address: 'Hoima Rd, Kampala, Uganda', phone: '', country: 'Uganda', description: 'Etiopisk/Ugandisk restaurant i Kampala', openingHours: {} },
  { name: 'Stockholm Eritrean Restaurant', category: 'Restaurant', address: 'Ggaba Road, Kampala, Uganda', phone: '', country: 'Uganda', description: 'Eritreisk restaurant på Ggaba Road Kampala', openingHours: {} },

  // UGANDA - Ggaba Road / Kansanga cluster
  { name: 'Addis Lounge', category: 'Restaurant', address: 'Ggaba Road, Kampala, Uganda', phone: '', country: 'Uganda', description: 'Habesha-stil bar og restaurant på Ggaba Road', openingHours: {} },
  { name: 'Habesha Garden Restaurant', category: 'Restaurant', address: 'Kansanga, Kampala, Uganda', phone: '', country: 'Uganda', description: 'Lokal Habesha restaurant i Kansanga', openingHours: {} },
  { name: 'Ras Cafe & Grill', category: 'Kafé', address: 'Ggaba Road, Kampala, Uganda', phone: '', country: 'Uganda', description: 'Etiopisk/Eritreisk mat på Ggaba Road', openingHours: {} },
  { name: 'Sunrise Habesha Restaurant', category: 'Restaurant', address: 'Kansanga, Kampala, Uganda', phone: '', country: 'Uganda', description: 'Habesha restaurant i Kansanga', openingHours: {} },
  { name: 'Dream Lounge', category: 'Club', address: 'Ggaba Road, Kampala, Uganda', phone: '', country: 'Uganda', description: 'Lounge med Habesha klientell på Ggaba Road', openingHours: {} },
  { name: 'Capital Pub', category: 'Restaurant', address: 'Ggaba Road, Kampala, Uganda', phone: '', country: 'Uganda', description: 'Pub med Habesha mat og klientell', openingHours: {} },
  { name: 'Tena Yistilign Restaurant', category: 'Restaurant', address: 'Kansanga, Kampala, Uganda', phone: '', country: 'Uganda', description: 'Liten etiopisk restaurant i Kansanga', openingHours: {} },

  // UGANDA - Kabalagala / Nsambya cluster
  { name: 'Addis Ababa Kitchen', category: 'Restaurant', address: 'Kabalagala, Kampala, Uganda', phone: '', country: 'Uganda', description: 'Liten etiopisk restaurant i Kabalagala', openingHours: {} },
  { name: 'Sheba Lounge', category: 'Restaurant', address: 'Nsambya, Kampala, Uganda', phone: '', country: 'Uganda', description: 'Eritreisk-eid bar og restaurant i Nsambya', openingHours: {} },
  { name: 'Habesha Corner Café', category: 'Kafé', address: 'Kabalagala, Kampala, Uganda', phone: '', country: 'Uganda', description: 'Habesha kafé i Kabalagala', openingHours: {} },
  { name: 'Eden Ethiopian Food Spot', category: 'Restaurant', address: 'Kabalagala, Kampala, Uganda', phone: '', country: 'Uganda', description: 'Etiopisk matsted i Kabalagala', openingHours: {} },
  { name: 'Habesha Bakery & Coffee Spot', category: 'Kafé', address: 'Nsambya, Kampala, Uganda', phone: '', country: 'Uganda', description: 'Habesha bakeri og kafé i Nsambya', openingHours: {} },
  { name: 'Nsambya Injera House', category: 'Restaurant', address: 'Nsambya, Kampala, Uganda', phone: '', country: 'Uganda', description: 'Injera-spesialist i Nsambya', openingHours: {} },

  // UGANDA - Muyenga / Tank Hill cluster
  { name: 'Addis View Restaurant', category: 'Restaurant', address: 'Muyenga, Kampala, Uganda', phone: '', country: 'Uganda', description: 'Etiopisk restaurant i Muyenga', openingHours: {} },
  { name: 'Habesha Hills Restaurant', category: 'Restaurant', address: 'Muyenga, Kampala, Uganda', phone: '', country: 'Uganda', description: 'Habesha restaurant i Muyenga', openingHours: {} },
  { name: 'Ethiopian Family Kitchen', category: 'Restaurant', address: 'Tank Hill, Kampala, Uganda', phone: '', country: 'Uganda', description: 'Familievennlig etiopisk kjøkken på Tank Hill', openingHours: {} },
  { name: 'Mountain View Habesha Lounge', category: 'Restaurant', address: 'Muyenga, Kampala, Uganda', phone: '', country: 'Uganda', description: 'Habesha lounge med utsikt i Muyenga', openingHours: {} },

  // UGANDA - Bunga cluster
  { name: 'Bunga Ethiopian Food House', category: 'Restaurant', address: 'Bunga, Kampala, Uganda', phone: '', country: 'Uganda', description: 'Etiopisk mathus i Bunga', openingHours: {} },
  { name: 'Habesha Shore Café', category: 'Kafé', address: 'Bunga, Kampala, Uganda', phone: '', country: 'Uganda', description: 'Habesha kafé i Bunga', openingHours: {} },
  { name: 'Lakeview Injera Spot', category: 'Restaurant', address: 'Bunga, Kampala, Uganda', phone: '', country: 'Uganda', description: 'Injera-restaurant med innsjøutsikt i Bunga', openingHours: {} },

  // UGANDA - Services / Shops
  { name: 'Eritrean Grocery Shop Kabalagala', category: 'Butikk', address: 'Kabalagala, Kampala, Uganda', phone: '', country: 'Uganda', description: 'Eritreisk dagligvarebutikk i Kabalagala', openingHours: {} },
  { name: 'Ethiopian Spice Shop Muyenga', category: 'Butikk', address: 'Muyenga Road, Kampala, Uganda', phone: '', country: 'Uganda', description: 'Etiopiske krydder og matvarer i Muyenga', openingHours: {} },
  { name: 'Habesha Hair Braiding Salon', category: 'Frisør', address: 'Nsambya, Kampala, Uganda', phone: '', country: 'Uganda', description: 'Habesha hårfletting salong i Nsambya', openingHours: {} },
];

async function run() {
  let count = 0;
  for (const b of businesses) {
    const existing = await db.collection('businesses').where('name', '==', b.name).get();
    if (!existing.empty) {
      console.log('Finnes allerede: ' + b.name);
      continue;
    }
    await db.collection('businesses').add({
      ...b,
      imageUrl: '',
      lat: 0,
      lng: 0,
      rating: 0.0,
      ratingCount: 0,
      isOpen: false,
      isPremium: false,
      ownerId: '',
      ownerName: 'Habesha Hub',
      ownerEmail: '',
      website: '',
      status: 'approved',
      galleryImages: [],
      promoVideoUrl: null,
      createdAt: FieldValue.serverTimestamp(),
    });
    console.log('Lagt til: ' + b.name);
    count++;
  }
  console.log('Ferdig! ' + count + ' bedrifter lagt til.');
  process.exit(0);
}

run().catch(console.error);