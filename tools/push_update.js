// One push to everyone: "New version of Habesha Hub – update now", in the user's app language
// (topics news_en / news_ti / news_am, which every app version already listens to).
// Send it once, AFTER both stores have published the version.
//   node tools/push_update.js 2.3.3          → shows the texts, sends nothing
//   node tools/push_update.js 2.3.3 --send   → sends
const path = require('path');
const { initializeApp, cert } = require('firebase-admin/app');
const { getMessaging } = require('firebase-admin/messaging');
initializeApp({ credential: cert(require(path.join(__dirname, '..', 'serviceAccountKey.json'))) });

const version = process.argv[2];
const SEND = process.argv.includes('--send');
if (!/^\d+\.\d+\.\d+$/.test(version || '')) {
  console.log('Use: node tools/push_update.js 2.3.3 [--send]');
  process.exit(1);
}
const MSG = {
  news_en: { title: `🎉 Habesha Hub ${version} is here`, body: 'New: Habesha Hub Services by region, small & home businesses, a cleaner home screen and more. Update now.' },
  news_ti: { title: `🎉 Habesha Hub ${version} መጺኡ`, body: 'ሓድሽ፦ ሓበሻ ሃብ ኣገልግሎታት ብዞባ፡ ናእሽቱን ናይ ገዛን ንግድታት፡ ፕሪሚየም ንንግድታትን ሓድሽ መልክዕን። ሕጂ ኣሐድሱ።' },
  news_am: { title: `🎉 Habesha Hub ${version} ደርሷል`, body: 'አዲስ፦ ሐበሻ ሀብ አገልግሎቶች በክልል፣ አነስተኛና የቤት ንግዶች፣ ፕሪሚየም ለንግዶችና አዲስ መልክ። አሁን ያዘምኑ።' },
};

(async () => {
  for (const [topic, notification] of Object.entries(MSG)) {
    console.log(`${topic}: ${notification.title} — ${notification.body}`);
    if (!SEND) continue;
    await getMessaging().send({
      topic, notification,
      data: { type: 'app_update', version },
      android: { priority: 'high' },
      apns: { payload: { aps: { sound: 'default' } } },
    });
  }
  console.log(SEND ? '\nSent to everyone.' : '\nNothing sent. Add --send to send.');
  process.exit(0);
})().catch(e => { console.error(e.message); process.exit(1); });
