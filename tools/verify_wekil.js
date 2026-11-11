// Confirms the e-mail of a wekil account when the confirmation e-mail never arrives.
// Only works for e-mails the admin has added as wekil in the app (wekils/{email}).
//   node tools/verify_wekil.js samiefr+norge@gmail.com
//   node tools/verify_wekil.js list        → shows all wekils and whether their account is ready
const path = require('path');
const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { getAuth } = require('firebase-admin/auth');
initializeApp({ credential: cert(require(path.join(__dirname, '..', 'serviceAccountKey.json'))) });
const db = getFirestore(), auth = getAuth();

async function status(email) {
  try {
    const u = await auth.getUserByEmail(email);
    return u.emailVerified ? '✅ account ready' : '⏳ account made, e-mail NOT confirmed';
  } catch (e) {
    return '❌ no account yet (make it in the app: Business login → NEW ACCOUNT)';
  }
}

(async () => {
  const arg = (process.argv[2] || '').trim().toLowerCase();
  if (!arg) {
    console.log('Use: node tools/verify_wekil.js samiefr+norge@gmail.com   (or: list)');
    process.exit(1);
  }
  if (arg === 'list') {
    const all = await db.collection('wekils').get();
    if (all.empty) console.log('No wekils yet. Add one in the app: Profile → Wekil → 👤⚙️ → Add wekil');
    for (const d of all.docs) console.log(`${d.data().country || '?'}  ${d.id}  ${await status(d.id)}`);
    process.exit(0);
  }
  const w = await db.collection('wekils').doc(arg).get();
  if (!w.exists) {
    console.log(`❌ ${arg} is not a wekil. Add it first in the app: Profile → Wekil → 👤⚙️ → Add wekil`);
    process.exit(1);
  }
  let u;
  try {
    u = await auth.getUserByEmail(arg);
  } catch (e) {
    console.log(`❌ ${arg} has no account yet. Make it in the app: Business login → NEW ACCOUNT (e-mail + password).`);
    process.exit(1);
  }
  if (u.emailVerified) {
    console.log(`✅ ${arg} is already confirmed. Log in with it in the app.`);
  } else {
    await auth.updateUser(u.uid, { emailVerified: true });
    console.log(`✅ ${arg} (${w.data().country}) is now confirmed. Log out and in again in the app.`);
  }
  process.exit(0);
})();
