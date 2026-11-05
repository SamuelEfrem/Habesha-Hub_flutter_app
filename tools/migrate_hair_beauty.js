// "Barber" is now shown as "Hair & beauty" with sub-categories.
// The stored category stays 'Barber' (older app versions keep showing these places);
// this gives every existing one the sub-category 'barber', and moves any 'Hair & beauty' / 'Frisør'
// written by hand back to 'Barber'. Never deletes, never touches other fields.
//   node tools/migrate_hair_beauty.js          (shows the changes, saves nothing)
//   node tools/migrate_hair_beauty.js --write  (saves)
const path = require('path');
const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
initializeApp({ credential: cert(require(path.join(__dirname, '..', 'serviceAccountKey.json'))) });

const WRITE = process.argv.includes('--write');
const OLD = ['Barber', 'Hair & beauty', 'Hair & Beauty', 'Frisør', 'frisør', 'barber'];

(async () => {
  const db = getFirestore();
  const docs = (await db.collection('businesses').where('category', 'in', OLD).get()).docs;
  const changes = [];
  for (const d of docs) {
    const b = d.data(), set = {};
    if (b.category !== 'Barber') set.category = 'Barber';
    if (!b.subcategory) {
      // a guess from the name; the owner can change it in the app
      const n = `${b.name || ''} ${b.description || ''}`.toLowerCase();
      const barber = /barber/.test(n);
      const salon = /salon|saloon|hair|frisør|beauty|ladies|afro/.test(n);
      set.subcategory = salon && !barber ? 'salon' : 'barber';
      if (/ladies|women|damer/.test(n) && !b.forWho) set.forWho = 'women';
    }
    if (Object.keys(set).length) changes.push([d, set]);
  }
  console.log(`${docs.length} Hair & beauty places · ${changes.length} get changes\n`);
  for (const [d, set] of changes.slice(0, 15)) {
    console.log(`  ${(d.data().name || d.id).slice(0, 34).padEnd(34)} ${(d.data().country || '?').padEnd(12)} ${JSON.stringify(set)}`);
  }
  if (changes.length > 15) console.log(`  … and ${changes.length - 15} more`);
  if (!WRITE) { console.log('\nNothing saved. Run with --write to save.'); process.exit(0); }
  for (let i = 0; i < changes.length; i += 400) {
    const batch = db.batch();
    changes.slice(i, i + 400).forEach(([d, set]) => batch.update(d.ref, set));
    await batch.commit();
  }
  console.log(`\nDone: ${changes.length} updated.`);
  process.exit(0);
})().catch(e => { console.error(e.message); process.exit(1); });
