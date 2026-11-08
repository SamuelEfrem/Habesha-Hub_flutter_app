// Push "new version" straight to every saved phone token, shown ONLY on iPhone.
// Why: iPhones on 2.3.3 and older are not on the news_* topics (fixed in 2.3.4), and Android
// already got push_update.js. The message has an alert only in the APNs part; on Android it
// arrives as an empty data message that the app ignores, so nobody gets it twice.
//   node tools/push_update_ios.js 2.3.3          → counts tokens, sends nothing
//   node tools/push_update_ios.js 2.3.3 --send   → sends
const path = require('path');
const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');
initializeApp({ credential: cert(require(path.join(__dirname, '..', 'serviceAccountKey.json'))) });

const version = process.argv[2];
const SEND = process.argv.includes('--send');
if (!/^\d+\.\d+\.\d+$/.test(version || '')) {
  console.log('Use: node tools/push_update_ios.js 2.3.3 [--send]');
  process.exit(1);
}
const title = `🎉 Habesha Hub ${version}`;
const body = 'New version – update in the App Store · ሓድሽ ስሪት – ኣብ App Store ኣሐድሱ · አዲስ ስሪት – በApp Store ያዘምኑ';

(async () => {
  const users = (await getFirestore().collection('users').get()).docs;
  const tokens = new Set();
  for (const u of users) {
    const d = u.data();
    (Array.isArray(d.fcmTokens) ? d.fcmTokens : []).forEach(t => t && tokens.add(t));
    if (d.fcmToken) tokens.add(d.fcmToken);
  }
  const list = [...tokens];
  console.log(`${users.length} users · ${list.length} phone tokens (Android + iPhone; only iPhone shows it)`);
  console.log(`Text: ${title} — ${body}`);
  if (!SEND) { console.log('\nNothing sent. Add --send to send.'); process.exit(0); }
  let ok = 0, bad = 0;
  for (let i = 0; i < list.length; i += 500) {
    const r = await getMessaging().sendEachForMulticast({
      tokens: list.slice(i, i + 500),
      data: { type: 'app_update', version },
      apns: { payload: { aps: { alert: { title, body }, sound: 'default' } } },
    });
    ok += r.successCount; bad += r.failureCount;
  }
  console.log(`\nSent: ${ok} ok, ${bad} old/invalid tokens (phones that removed the app).`);
  process.exit(0);
})().catch(e => { console.error(e.message); process.exit(1); });
