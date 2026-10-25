// ═══════════════════════════════════════════════════════════
// Gjør alle tjenesteytere om til ENGELSK (navn + beskrivelse)
// og legger til TIGRINYA og AMHARISK oversettelse.
// Firestore-ID oppdateres også (f.eks. "Decoration 1 (ekte navn)").
//
// Kjør:  node tools/translate_services.js
// Trygt å kjøre flere ganger.
// ═══════════════════════════════════════════════════════════
const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const serviceAccount = require(require('path').join(__dirname, '..', 'serviceAccountKey.json'));
initializeApp({ credential: cert(serviceAccount) });
const db = getFirestore();

// old/English name → English name + description, Tigrinya, Amharic
const P = [
 { old:['Cameraman 1'], en:'Cameraman 1', ti:'ካሜራማን 1', am:'ካሜራማን 1',
   d_en:'Professional photographer specialising in weddings and family events. Edited photos delivered within 7 days.',
   d_ti:'ኣብ መርዓን ስድራቤታዊ በዓላትን ዝተወሰነ ሞያዊ ፎቶግራፈር። ዝተሰርሑ ስእልታት ኣብ ውሽጢ 7 መዓልቲ ይረክብ።',
   d_am:'በሠርግ እና በቤተሰብ ዝግጅቶች ላይ የተሰማራ ባለሙያ ፎቶግራፈር። የተስተካከሉ ፎቶዎች በ7 ቀናት ውስጥ ይደርሳሉ።' },
 { old:['Cameraman 2'], en:'Cameraman 2', ti:'ካሜራማን 2', am:'ካሜራማን 2',
   d_en:'Specialist in traditional Habesha ceremonies. Drone footage available. Experience from over 200 events.',
   d_ti:'ኣብ ባህላዊ ስነ-ስርዓታት ሓበሻ ክኢላ። ብድሮን ምቕራጽ ይከኣል። ካብ 200 ንላዕሊ ኣጋጣሚታት ተሞክሮ።',
   d_am:'በባህላዊ የሀበሻ ሥነ-ሥርዓቶች ላይ ልዩ ባለሙያ። በድሮን መቅረጽ ይቻላል። ከ200 በላይ ዝግጅቶች ልምድ።' },
 { old:['Cameraman 3'], en:'Cameraman 3', ti:'ካሜራማን 3', am:'ካሜራማን 3',
   d_en:'Studio and outdoor photography. Packages for individuals and groups. Fast delivery.',
   d_ti:'ናይ ስቱድዮን ናይ ደገን ስእሊ። ንውልቀሰባትን ጉጅለታትን ዝኸውን ጥቕሊ። ቅልጡፍ ምርካብ።',
   d_am:'የስቱዲዮ እና የውጪ ፎቶግራፍ። ለግለሰቦች እና ለቡድኖች ፓኬጆች። ፈጣን አቅርቦት።' },
 { old:['Dekorasjon 1','Decoration 1'], en:'Decoration 1', ti:'ምስላም 1', am:'ማስዋቢያ 1',
   d_en:'Complete decoration service for weddings, birthdays and cultural events. Includes flowers and lighting.',
   d_ti:'ምሉእ ኣገልግሎት ምስላም ንመርዓ፡ ልደትን ባህላዊ በዓላትን። ዕንባባታትን መብራህትን የጠቓልል።',
   d_am:'ለሠርግ፣ ለልደት እና ለባህላዊ ዝግጅቶች የተሟላ የማስዋቢያ አገልግሎት። አበቦችን እና መብራቶችን ያካትታል።' },
 { old:['Dekorasjon 2','Decoration 2'], en:'Decoration 2', ti:'ምስላም 2', am:'ማስዋቢያ 2',
   d_en:'Traditional Habesha decoration in Scandinavia. Specialised in coffee ceremonies and cultural celebrations.',
   d_ti:'ባህላዊ ምስላም ሓበሻ ኣብ ስካንዲናቭያ። ኣብ ስነ-ስርዓት ቡንን ባህላዊ በዓላትን ዝተወሰነ።',
   d_am:'በስካንዲኔቪያ ባህላዊ የሀበሻ ማስዋቢያ። በቡና ሥነ-ሥርዓት እና በባህላዊ በዓላት ላይ የተሰማራ።' },
 { old:['Guesthouse 1'], en:'Guesthouse 1', ti:'መዕረፊ ኣጋይሽ 1', am:'የእንግዳ ማረፊያ 1',
   d_en:'Cosy guesthouse in central Kampala. Breakfast included. Free WiFi. Close to shopping and transport. Max 4 guests.',
   d_ti:'ኣብ ማእከል ካምፓላ ዝርከብ ምቹእ መዕረፊ ኣጋይሽ። ቁርሲ ሓዊሱ። ነጻ WiFi። ቀረባ ናብ ዕዳጋን መጓዓዝያን። ዝለዓለ 4 ጋሻ።',
   d_am:'በካምፓላ መሃል የሚገኝ ምቹ የእንግዳ ማረፊያ። ቁርስ ተካትቷል። ነፃ WiFi። ለገበያ እና ለትራንስፖርት ቅርብ። ቢበዛ 4 እንግዶች።' },
 { old:['Guesthouse 2'], en:'Guesthouse 2', ti:'መዕረፊ ኣጋይሽ 2', am:'የእንግዳ ማረፊያ 2',
   d_en:'Quiet guesthouse near Entebbe airport. Perfect for transit guests. Free transfer when booking more than 2 nights.',
   d_ti:'ኣብ ጥቓ መዕርፎ ነፈርቲ ኤንተበ ዝርከብ ህዱእ መዕረፊ ኣጋይሽ። ንተሓላለፍቲ ጋሻ ዝሰማማዕ። ልዕሊ 2 ለይቲ ምስ ተሓዝኩም ነጻ መጓዓዝያ።',
   d_am:'በኢንቴቤ አውሮፕላን ማረፊያ አቅራቢያ ጸጥ ያለ የእንግዳ ማረፊያ። ለትራንዚት እንግዶች ተስማሚ። ከ2 ምሽት በላይ ሲያዙ ነፃ ማጓጓዣ።' },
 { old:['Guesthouse 3'], en:'Guesthouse 3', ti:'መዕረፊ ኣጋይሽ 3', am:'የእንግዳ ማረፊያ 3',
   d_en:'Modern rooms in the heart of Addis. Habesha breakfast served daily. Close to cultural sights and restaurants.',
   d_ti:'ኣብ ልቢ ኣዲስ ዘመናዊ ክፍልታት። መዓልታዊ ቁርሲ ሓበሻ ይቐርብ። ቀረባ ናብ ባህላዊ ቦታታትን ቤት መግብታትን።',
   d_am:'በአዲስ ልብ ዘመናዊ ክፍሎች። የሀበሻ ቁርስ በየቀኑ ይቀርባል። ለባህላዊ መስህቦች እና ምግብ ቤቶች ቅርብ።' },
 { old:['Transport 1'], en:'Transport 1', ti:'መጓዓዝያ 1', am:'ትራንስፖርት 1',
   d_en:'Reliable private driver for airport transfers, shopping and trips in and around Kampala. Comfortable SUV.',
   d_ti:'ንመዕርፎ ነፈርቲ፡ ዕዳጋን ጉዕዞታት ኣብ ካምፓላን ከባቢኣን እሙን ብሕታዊ መራሕ መኪና። ምቹእ SUV።',
   d_am:'ለአውሮፕላን ማረፊያ ማጓጓዣ፣ ለገበያ እና በካምፓላና አካባቢው ለጉዞ አስተማማኝ የግል ሹፌር። ምቹ SUV።' },
 { old:['Transport 2'], en:'Transport 2', ti:'መጓዓዝያ 2', am:'ትራንስፖርት 2',
   d_en:'Minibus for groups of up to 12 people. Event transport, wedding convoys and airport transfers.',
   d_ti:'ንክሳብ 12 ሰባት ዝኸውን ሚኒባስ። መጓዓዝያ ኣጋጣሚታት፡ ናይ መርዓ ኮንቮይን መዕርፎ ነፈርትን።',
   d_am:'እስከ 12 ሰዎች ለሚይዙ ቡድኖች ሚኒባስ። የዝግጅት ትራንስፖርት፣ የሠርግ ኮንቮይ እና የአውሮፕላን ማረፊያ ማጓጓዣ።' },
 { old:['Habesha Klær 1','Habesha Clothing 1'], en:'Habesha Clothing 1', ti:'ክዳን ሓበሻ 1', am:'የሀበሻ ልብስ 1',
   d_en:'Tailor-made traditional Habesha dresses (kemis) and menswear. International delivery. Order 3 weeks in advance.',
   d_ti:'ብዓቐን ዝተሰፍየ ባህላዊ ክዳን ሓበሻ (ቀሚሽ) ናይ ደቂ ተባዕትዮን። ዓለምለኻዊ ምብጻሕ። 3 ሰሙን ኣቐዲምኩም ኣዝዙ።',
   d_am:'በልክ የተሰፉ ባህላዊ የሀበሻ ቀሚሶች እና የወንዶች ልብሶች። ዓለም አቀፍ አቅርቦት። ከ3 ሳምንት በፊት ይዘዙ።' },
 { old:['Habesha Klær 2','Habesha Clothing 2'], en:'Habesha Clothing 2', ti:'ክዳን ሓበሻ 2', am:'የሀበሻ ልብስ 2',
   d_en:'Habesha clothing imported directly from Addis and Asmara. In stock in Oslo. Wedding packages available.',
   d_ti:'ብቐጥታ ካብ ኣዲስን ኣስመራን ዝመጽእ ክዳን ሓበሻ። ኣብ ኦስሎ ይርከብ። ጥቕሊ መርዓ ኣሎ።',
   d_am:'በቀጥታ ከአዲስ እና ከአስመራ የመጣ የሀበሻ ልብስ። በኦስሎ ይገኛል። የሠርግ ፓኬጆች አሉ።' },
 { old:['Hawala 1'], en:'Hawala 1', ti:'ሓዋላ 1', am:'ሐዋላ 1',
   d_en:'Fast money transfer to Ethiopia and Eritrea. Received within 24 hours. Competitive rate. Contact for today’s rate.',
   d_ti:'ቅልጡፍ ምልኣኽ ገንዘብ ናብ ኢትዮጵያን ኤርትራን። ኣብ ውሽጢ 24 ሰዓት ይበጽሕ። ተወዳዳሪ ዋጋ። ንናይ ሎሚ ዋጋ ተወከሱ።',
   d_am:'ወደ ኢትዮጵያ እና ኤርትራ ፈጣን ገንዘብ ማስተላለፍ። በ24 ሰዓት ውስጥ ይደርሳል። ተወዳዳሪ ምንዛሬ። ለዛሬው ዋጋ ያግኙን።' },
 { old:['Fly & Visa 1','Flight & Visa 1'], en:'Flight & Visa 1', ti:'በረራን ቪዛን 1', am:'በረራ እና ቪዛ 1',
   d_en:'Help with visa applications for Ethiopia and Eritrea. Cheapest flights from Norway to the Horn of Africa.',
   d_ti:'ሓገዝ ኣብ ምሕታት ቪዛ ንኢትዮጵያን ኤርትራን። ካብ ኖርወይ ናብ ቀርኒ ኣፍሪቃ ዝሓሰረ ትኬት ነፈርቲ።',
   d_am:'ለኢትዮጵያ እና ለኤርትራ የቪዛ ማመልከቻ እገዛ። ከኖርዌይ ወደ አፍሪካ ቀንድ ርካሽ የአውሮፕላን ትኬቶች።' },
];
const CITY = { 'Addis Abeba': 'Addis Ababa' };

const docName = (pub, real) => {
  const c = v => (v || '').replace(/\//g, '-').replace(/\s+/g, ' ').trim();
  return c(real) ? `${c(pub)} (${c(real)})` : c(pub);
};

async function freeId(base, ignore) {
  const col = db.collection('anonymous_services');
  let id = base, i = 2;
  while (id !== ignore && (await col.doc(id).get()).exists) id = `${base} ${i++}`;
  return id;
}

async function run() {
  const col = db.collection('anonymous_services');
  const snap = await col.get();
  let done = 0; const unknown = [];
  for (const doc of snap.docs) {
    const d = doc.data();
    const name = (d.publicName || '').trim();
    const p = P.find(x => x.old.some(o => o.toLowerCase() === name.toLowerCase()));
    if (!p) { unknown.push(`${doc.id}  (publicName: "${name}")`); continue; }

    const upd = {
      ...d,
      publicName: p.en,
      description: p.d_en,
      city: CITY[d.city] || d.city || '',
      translations: {
        Tigrinya: { publicName: p.ti, description: p.d_ti },
        Amharic:  { publicName: p.am, description: p.d_am },
      },
    };
    delete upd.price;   // prices are no longer shown

    // readable ID from the new English name
    const want = docName(p.en, d.realName);
    let id = doc.id;
    if (doc.id !== want && !doc.id.startsWith(want + ' ')) id = await freeId(want, doc.id);

    if (id === doc.id) {
      await doc.ref.set(upd);
    } else {
      const batch = db.batch();
      batch.set(col.doc(id), upd);
      const bookings = await db.collection('service_bookings').where('serviceId', '==', doc.id).get();
      bookings.forEach(b => batch.update(b.ref, { serviceId: id, serviceName: p.en }));
      batch.delete(doc.ref);
      await batch.commit();
    }
    console.log(`✅ ${name.padEnd(18)} → ${p.en.padEnd(20)} ID: ${id}`);
    done++;
  }
  console.log(`\n🎉 ${done} tjenesteytere oppdatert.`);
  if (unknown.length) {
    console.log('\n⚠️  Disse kjente jeg ikke igjen (ikke endret) — rediger dem i admin-panelet:');
    unknown.forEach(u => console.log('   ' + u));
  }
  process.exit(0);
}
run().catch(e => { console.error('❌', e.message || e); process.exit(1); });
