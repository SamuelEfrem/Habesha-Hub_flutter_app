// Tells the apps which version is the newest (shows "New version available").
// Run it AFTER the store has approved and published the version.
//   node tools/set_app_version.js android 2.3.4          → friendly message to older Android versions
//   node tools/set_app_version.js ios 2.3.4              → the same for iPhone
//   node tools/set_app_version.js android 2.3.4 2.3.0    → also: versions older than 2.3.0 MUST update
//   node tools/set_app_version.js show                   → shows what is set now
const path = require('path');
const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
initializeApp({ credential: cert(require(path.join(__dirname, '..', 'serviceAccountKey.json'))) });
const ref = getFirestore().collection('app_config').doc('app_version');
const ok = v => /^\d+\.\d+\.\d+$/.test(v);

(async () => {
  const [platform, latest, min] = process.argv.slice(2);
  if (platform === 'show' || !platform) {
    console.log(JSON.stringify((await ref.get()).data() || {}, null, 2));
    process.exit(0);
  }
  if (!['android', 'ios'].includes(platform) || !ok(latest || '') || (min && !ok(min))) {
    console.log('Use: node tools/set_app_version.js android|ios 2.3.4 [min]');
    process.exit(1);
  }
  const value = { latest };
  if (min) value.min = min;
  await ref.set({ [platform]: value }, { merge: true });
  console.log('Set', platform, value);
  process.exit(0);
})().catch(e => { console.error(e.message); process.exit(1); });
