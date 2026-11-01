const { onDocumentCreated, onDocumentUpdated, onDocumentWritten } = require('firebase-functions/v2/firestore');
const { setGlobalOptions } = require('firebase-functions/v2');
const { onRequest, onCall, HttpsError } = require('firebase-functions/v2/https');
const { defineSecret }     = require('firebase-functions/params');
const { initializeApp }     = require('firebase-admin/app');

// Firestore database is in europe-west1 → functions must run in the same region
setGlobalOptions({ region: 'europe-west1' });
const { getMessaging }      = require('firebase-admin/messaging');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { getAuth }           = require('firebase-admin/auth');
const { getStorage, getDownloadURL } = require('firebase-admin/storage');

initializeApp();

// Samuel sin UID — henter FCM token fra Firestore
const SAMUEL_UID = 'W3z67R3wiXUVvcPFDS0oxgfaDlj1';

exports.notifyBooking = onDocumentCreated(
  'service_bookings/{bookingId}',
  async (event) => {
    const data = event.data?.data();
    if (!data) return;

    const db = getFirestore();
    const userDoc = await db.collection('users').doc(SAMUEL_UID).get();
    const token   = userDoc.data()?.fcmToken;

    if (!token) {
      console.log('❌ Samuel has no FCM token in Firestore');
      return;
    }

    const svcName  = data.serviceName || 'Ukjent tjeneste';
    const email    = data.userEmail   || 'ukjent';
    const dateRaw  = data.date        || '';
    const notes    = data.notes       || '';
    const wa       = data.whatsapp    || '';
    const dateStr  = dateRaw ? new Date(dateRaw).toLocaleDateString('no-NO') : '';

    const message = {
      token,
      notification: {
        title: `📅 Ny booking — ${svcName}`,
        body:  `${email}${wa ? ' • WhatsApp ' + wa : ''} • ${dateStr}${notes ? '\n' + notes : ''}`,
      },
      android: { priority: 'high' },
      apns:    { payload: { aps: { sound: 'default', badge: 1 } } },
    };

    await getMessaging().send(message);
    console.log(`✅ Varsel sendt til Samuel for booking: ${svcName}`);
  }
);


// ═══════════════════════════════════════════════════════════
// notifyCustomer — push to the CUSTOMER when admin confirms,
// marks as paid, or cancels a booking. Text in the customer's language.
// ═══════════════════════════════════════════════════════════
const TXT = {
  English: {
    confirmed: (s, a, m, n, c) => ({ title: `✅ Booking confirmed — ${s}`,
      body: `${a ? 'Amount: ' + a + '. ' : ''}${m ? 'Pay with ' + m + (n ? ' to ' + n : '') + '. ' : ''}Reference: ${c}. See your receipt in the app.` }),
    paid:      (s, a, m, n, c) => ({ title: `💵 Payment received — ${s}`, body: `Thank you! Booking ${c} is paid.` }),
    cancelled: (s, a, m, n, c) => ({ title: `❌ Booking cancelled — ${s}`, body: `Booking ${c} was cancelled. Contact Habesha Hub for questions.` }),
  },
  Tigrinya: {
    confirmed: (s, a, m, n, c) => ({ title: `✅ ቡኪንግ ጸዲቑ — ${s}`,
      body: `${a ? 'መጠን: ' + a + '። ' : ''}${m ? 'ብ ' + m + (n ? ' ናብ ' + n : '') + ' ክፈሉ። ' : ''}መወከሲ: ${c}። ቅብሊትኩም ኣብ ኣፕ ርኣዩ።` }),
    paid:      (s, a, m, n, c) => ({ title: `💵 ክፍሊት ተቐቢልና — ${s}`, body: `የቐንየልና! ቡኪንግ ${c} ተኸፊሉ።` }),
    cancelled: (s, a, m, n, c) => ({ title: `❌ ቡኪንግ ተሰሪዙ — ${s}`, body: `ቡኪንግ ${c} ተሰሪዙ። ንሕቶ Habesha Hub ተወከሱ።` }),
  },
  Amharic: {
    confirmed: (s, a, m, n, c) => ({ title: `✅ ቦታ ማስያዣ ጸድቋል — ${s}`,
      body: `${a ? 'መጠን: ' + a + '። ' : ''}${m ? 'በ ' + m + (n ? ' ወደ ' + n : '') + ' ይክፈሉ። ' : ''}ማጣቀሻ: ${c}። ደረሰኝዎን በመተግበሪያው ይመልከቱ።` }),
    paid:      (s, a, m, n, c) => ({ title: `💵 ክፍያ ደርሷል — ${s}`, body: `እናመሰግናለን! ቦታ ማስያዣ ${c} ተከፍሏል።` }),
    cancelled: (s, a, m, n, c) => ({ title: `❌ ቦታ ማስያዣ ተሰርዟል — ${s}`, body: `ቦታ ማስያዣ ${c} ተሰርዟል። ለጥያቄ Habesha Hubን ያግኙ።` }),
  },
};

exports.notifyCustomer = onDocumentUpdated(
  'service_bookings/{bookingId}',
  async (event) => {
    const before = event.data?.before?.data() || {};
    const after  = event.data?.after?.data()  || {};
    let kind = null;
    if (before.status !== 'confirmed' && after.status === 'confirmed') kind = 'confirmed';
    else if (before.paid !== true && after.paid === true)              kind = 'paid';
    else if (before.status !== 'cancelled' && after.status === 'cancelled') kind = 'cancelled';
    if (!kind || !after.userId) return;

    const db = getFirestore();
    const userDoc = await db.collection('users').doc(after.userId).get();
    const token = userDoc.data()?.fcmToken;
    if (!token) { console.log(`❌ Customer ${after.userId} has no FCM token`); return; }

    const t = (TXT[after.lang] || TXT.English)[kind];
    const amount = after.amount ? `${after.amount} ${after.currency || ''}`.trim() : '';
    const code = after.bookingCode || event.params.bookingId;
    const msg = t(after.serviceName || 'Habesha Hub', amount, after.paymentMethod || '', after.paymentNumber || '', code);

    await getMessaging().send({
      token,
      notification: msg,
      data: { type: 'booking', bookingId: event.params.bookingId },
      android: { priority: 'high' },
      apns: { payload: { aps: { sound: 'default' } } },
    });
    console.log(`✅ ${kind} notification sent to customer for ${code}`);
  }
);


// ═══════════════════════════════════════════════════════════
// aiChat — the app talks to Gemini THROUGH this function, so the
// Gemini API key never ships inside the app.
//   Key is stored in Secret Manager:
//   firebase functions:secrets:set GEMINI_KEY
// ═══════════════════════════════════════════════════════════
const GEMINI_KEY   = defineSecret('GEMINI_KEY');
const GEMINI_MODEL = 'gemini-3.5-flash';   // writes better Tigrinya than flash-lite

// strip BOM, quotes, spaces and line breaks that sneak in from Notepad / copy-paste
const cleanKey = () => GEMINI_KEY.value().replace(/^\uFEFF/, '').replace(/["'\s]/g, '');

let ctxCache = { at: 0, text: '' };
const CAT = { photographer: 'Photographer', decoration: 'Decoration & Events', flight_visa: 'Flight & Visa',
  transport: 'Transport', clothing: 'Clothing', accommodation: 'Accommodation', hawala: 'Hawala / Money Transfer' };
const COUNTRY = { UG: 'Uganda', ET: 'Ethiopia', ER: 'Eritrea', KE: 'Kenya', SS: 'South Sudan', NO: 'Norway',
  SE: 'Sweden', GB: 'United Kingdom', US: 'United States', CA: 'Canada' };
const cut = (v, n) => String(v || '').replace(/\s+/g, ' ').trim().slice(0, n);

// Everything the assistant may recommend: businesses, Habesha Hub services and marketplace items
async function appContext() {
  if (Date.now() - ctxCache.at < 10 * 60 * 1000 && ctxCache.text) return ctxCache.text;
  const db = getFirestore();
  const [biz, svc, mkt] = await Promise.all([
    db.collection('businesses').where('status', '==', 'approved').get(),
    db.collection('anonymous_services').where('available', '==', true).get(),
    db.collection('marketplace').orderBy('createdAt', 'desc').limit(60).get().catch(() => ({ docs: [] })),
  ]);
  const businesses = biz.docs.map(d => { const b = d.data();
    return `- ${cut(b.name, 60)} | ${b.category || ''} | ${cut(b.address, 80)} | ${b.country || ''} | phone ${b.phone || '-'}`; });
  const services = svc.docs.map(d => { const v = d.data();
    const t = v.translations || {};
    return `- ${cut(v.publicName, 40)} (Tigrinya: ${cut(t.Tigrinya?.publicName, 40)}, Amharic: ${cut(t.Amharic?.publicName, 40)})` +
      ` | ${CAT[v.category] || v.category || ''} | ${cut(v.city, 30)}, ${COUNTRY[v.country] || v.country || ''}` +
      ` | ${(v.sampleImages || []).length} photos, ${(v.sampleVideoUrls || []).length} videos | ${cut(v.description, 220)}`; });
  const market = mkt.docs.map(d => { const m = d.data();
    return `- ${cut(m.title, 60)} | ${m.category || ''} | ${cut(m.price, 20)} | ${cut(m.city, 30)}`; });
  const text =
    `HABESHA HUB SERVICES (booked inside the app: Services tab → country → category → provider → "Book Now". ` +
    `Providers are anonymous; Habesha Hub contacts the customer on WhatsApp and the customer gets a receipt with payment info. ` +
    `Never invent phone numbers for these):\n${services.join('\n') || '- none yet'}\n\n` +
    `BUSINESSES (customers can call them directly):\n${businesses.join('\n') || '- none yet'}\n\n` +
    `MARKETPLACE (second-hand items, Marketplace on the Home tab; contact the seller there):\n${market.join('\n') || '- none yet'}`;
  ctxCache = { at: Date.now(), text };
  return text;
}

// How the app works — so the assistant can guide people (also older people) step by step
const APP_GUIDE = `HOW HABESHA HUB WORKS (use this to explain where things are; keep steps short and simple):
- Top of the Home screen: the language button (EN / ትግ / አማ) and the light/dark button.
- Home: search field, the green "near me" button (needs location), 4 round buttons: Services, Market, Send money, Games. Below: Habesha businesses near you (tap one for address, call, directions, opening hours, chat, booking).
- Bottom menu: Home, Explore (businesses by country), Habesha AI (this chat), Hab Tok (short videos from service providers), Profile.
- Services: choose a country, then a category (photographer, decoration & events, flight & visa, transport, clothing, accommodation, send money home), then a provider, then "Book now". Habesha Hub contacts the customer on WhatsApp and the customer gets a receipt with payment info.
- Market: buy and sell second-hand things. Categories include Habesha clothes (zuria, habesha kemis, netela, gabi, men's suit, kids), clothes, electronics, furniture, food, books, jobs, housing, events. A listing can be For sale, Swap, For rent (price per day) or Free. Habesha clothes have size, occasion (wedding, church, holiday, graduation, mels) and condition (new, worn once, used). To sell yourself: Market, then the green "+ Sell" button. Every new listing is checked by Habesha Hub before it is shown. The seller can mark it Sold / Rented out. The share button gives a link for WhatsApp.
- Home shops (ቤት ዕዳጋ): small sellers who sell from home (spices, injera, coffee & incense, Habesha clothes, beauty, crafts). Home screen > the round "Home shops" button. Customers see shops near them, open a shop, see its products and prices, and press "Order on WhatsApp" or call; they pay the seller directly and the address is shared only after they agree. To open your own shop: Home shops > the green "Open your shop" button (log in first), add a photo, shop name, category, area (never a street address), WhatsApp number, pickup/delivery and products with photo and price, then "Send for approval". Habesha Hub checks every shop before it is shown. The owner can later edit it, choose "Available now" or "Order 1 day before", or pause it. Selling food regularly from home in Norway needs registration with Mattilsynet. This is different from registering a business (restaurants, shops with an address), which is under Profile > Register your business.
- Send money: shows trusted partners (Remitly, Dahabshiil and others). Habesha Hub does not send money itself.
- Games: Habesha Games (racing 3D, Dama, Genna, riddles; play the computer, a friend or online) and Life Tools (driving theory class B in Tigrinya with 500 questions, practical driving test with a voice teacher, languages, newcomer guides, Ge'ez calendar). The full driving course is unlocked with a code bought on WhatsApp; the code works for one phone number, verified by SMS.
- Profile: log in or create an account (email, Google or Apple), nickname, my bookings, my favourites, register your business, share the app, help & support, delete account.
- Businesses can register for free under Profile > Register your business; after approval they can edit their own page.
- Help: WhatsApp +47 973 74 482 or the website habesha-hub.no.`;

// Max questions per person, so nobody can run up the Google bill
const AI_PER_HOUR = 20, AI_PER_DAY = 60;
const LIMIT_TXT = {
  English: 'You have asked many questions in a short time. Please wait a little and try again later. 🙏',
  Tigrinya: 'ኣብ ሓጺር ግዜ ብዙሕ ሕቶታት ሓቲትካ። በጃኻ ቁሩብ ተጸበ እሞ ደሓር ደጊምካ ፈትን። 🙏',
  Amharic: 'በአጭር ጊዜ ብዙ ጥያቄዎችን ጠይቀዋል። እባክዎ ትንሽ ይጠብቁና ቆይተው እንደገና ይሞክሩ። 🙏',
};
const REPEAT_TXT = {
  English: 'You sent the same message several times. Please write a new question.',
  Tigrinya: 'ተመሳሳሊ መልእኽቲ ብዙሕ ግዜ ሰዲድካ። በጃኻ ሓድሽ ሕቶ ጽሓፍ።',
  Amharic: 'ተመሳሳይ መልእክት ብዙ ጊዜ ልከዋል። እባክዎ አዲስ ጥያቄ ይጻፉ።',
};

/** Counts questions per user (or per IP for old app versions). Returns 'ok', 'limit' or 'repeat'. */
async function aiQuota(key, text, isAdminUser) {
  if (isAdminUser) return 'ok';
  const ref = getFirestore().collection('ai_usage').doc(key.replace(/[\/.#$\[\]]/g, '_').slice(0, 120));
  const now = Date.now(), hour = Math.floor(now / 3600000), day = new Date(now).toISOString().slice(0, 10);
  let verdict = 'ok', firstHitToday = false;
  await getFirestore().runTransaction(async tx => {
    const u = (await tx.get(ref)).data() || {};
    const h = u.hour === hour ? (u.h || 0) : 0, d = u.day === day ? (u.d || 0) : 0;
    const same = text && u.last === text ? (u.rep || 0) + 1 : 0;
    if (h >= AI_PER_HOUR || d >= AI_PER_DAY) {
      verdict = 'limit';
      firstHitToday = u.limitDay !== day;
      tx.set(ref, { limitDay: day, blocked: (u.blocked || 0) + 1, lastAt: now }, { merge: true });
      return;
    }
    if (same >= 2) { verdict = 'repeat'; tx.set(ref, { rep: same, lastAt: now }, { merge: true }); return; }
    tx.set(ref, { hour, h: h + 1, day, d: d + 1, last: text || '', rep: same, lastAt: now }, { merge: true });
  });
  if (verdict === 'limit' && firstHitToday) {
    pushAdmin('🤖 AI limit reached', `${key} asked more than ${AI_PER_HOUR}/hour or ${AI_PER_DAY}/day`).catch(() => {});
  }
  return verdict;
}

// The assistant can post a market listing for the user (waits for approval like every listing)
const LISTING_TOOL = {
  name: 'create_listing',
  description: 'Post a listing in the Habesha Hub Market for the user. Only call this after the user has confirmed ' +
    'all the details you summarised for them. The listing waits for approval by Habesha Hub before it is shown.',
  parameters: {
    type: 'OBJECT',
    properties: {
      title: { type: 'STRING', description: 'Short title, e.g. "Green zuria, size M"' },
      description: { type: 'STRING' },
      category: { type: 'STRING', enum: ['Habesha', 'Clothes', 'Electronics', 'Furniture', 'Food', 'Books', 'Jobs', 'Housing', 'Events', 'Other'] },
      deal: { type: 'STRING', enum: ['sell', 'swap', 'rent', 'free'] },
      price: { type: 'STRING', description: 'Price with currency, e.g. "500 kr". Per day when deal is rent. Empty when free.' },
      city: { type: 'STRING' },
      phone: { type: 'STRING', description: 'Phone number buyers can call or WhatsApp' },
      sellerName: { type: 'STRING', description: 'Name shown to buyers' },
      garment: { type: 'STRING', enum: ['zuria', 'kemis', 'netela', 'gabi', 'suit', 'kids'] },
      size: { type: 'STRING', enum: ['XS', 'S', 'M', 'L', 'XL', 'XXL'] },
      occasion: { type: 'STRING', enum: ['wedding', 'church', 'holiday', 'graduation', 'mels'] },
      condition: { type: 'STRING', enum: ['new', 'once', 'used'] },
    },
    required: ['title', 'category', 'deal', 'city', 'phone', 'sellerName'],
  },
};

async function createListingFor(user, args, photos) {
  if (!user) return { ok: false, reason: 'login', message: 'The user is not logged in. Ask them to log in first (Profile > Log in), then try again.' };
  if (user.firebase?.sign_in_provider === 'anonymous') return { ok: false, reason: 'login', message: 'The user is a guest. Ask them to log in or create an account first (Profile > Log in).' };
  const db = getFirestore();
  // max 5 listings per day through the assistant
  const today = new Date().toISOString().slice(0, 10);
  const recent = await db.collection('marketplace').where('userId', '==', user.uid).where('viaAi', '==', today).get();
  if (recent.size >= 5) return { ok: false, reason: 'limit', message: 'Too many listings today through the assistant. Try again tomorrow or use the + Sell button.' };
  const bucket = getStorage().bucket();
  const urls = [];
  for (let i = 0; i < Math.min(photos.length, 8); i++) {
    const f = bucket.file(`marketplace/${user.uid}/ai_${Date.now()}_${i}.jpg`);
    await f.save(Buffer.from(photos[i], 'base64'), { contentType: 'image/jpeg', resumable: false });
    urls.push(await getDownloadURL(f));
  }
  const s = v => String(v || '').trim().slice(0, 600);
  const habesha = args.category === 'Habesha';
  const ref = await db.collection('marketplace').add({
    title: s(args.title).slice(0, 120), description: s(args.description),
    category: s(args.category) || 'Other', deal: ['sell', 'swap', 'rent', 'free'].includes(args.deal) ? args.deal : 'sell',
    price: args.deal === 'free' ? '' : s(args.price).slice(0, 40), city: s(args.city).slice(0, 60),
    sellerPhone: s(args.phone).slice(0, 30), sellerName: s(args.sellerName).slice(0, 60),
    garment: habesha ? s(args.garment) : '', size: habesha ? s(args.size) : '',
    occasion: habesha ? s(args.occasion) : '', condition: habesha ? s(args.condition) : '',
    imageUrl: urls[0] || '', extraImages: urls.slice(1), userId: user.uid, status: 'available',
    approved: false, viaAi: today, createdAt: FieldValue.serverTimestamp(), updatedAt: FieldValue.serverTimestamp(),
  });
  return { ok: true, id: ref.id, photos: urls.length, message: 'Posted. It now waits for approval by Habesha Hub.' };
}

exports.aiChat = onRequest(
  { secrets: [GEMINI_KEY], cors: true, invoker: 'public', maxInstances: 5, timeoutSeconds: 90, memory: '512MiB' },
  async (req, res) => {
    if (req.method !== 'POST') { res.status(405).send('POST only'); return; }
    try {
      const body = req.body || {};
      const text = String(body.text || '').slice(0, 1000).trim();
      const audio = typeof body.audio === 'string' && body.audio.length < 2_000_000 ? body.audio : '';
      const audioMime = /^audio\/[a-z0-9.+-]+$/.test(body.audioMime || '') ? body.audioMime : 'audio/wav';
      const photos = (Array.isArray(body.photos) ? body.photos : []).filter(p => typeof p === 'string' && p.length < 1_500_000).slice(0, 4);
      const newPhotos = Math.max(0, Math.min(photos.length, Number(body.newPhotos) || 0));
      if (!text && !audio && !newPhotos) { res.status(400).json({ error: 'empty' }); return; }
      const lang = ['Tigrinya', 'Amharic'].includes(body.lang) ? body.lang : 'English';

      // who is asking (the app sends its Firebase login token; old versions do not)
      let user = null;
      const m = /^Bearer (.+)$/.exec(req.get('Authorization') || '');
      if (m) user = await getAuth().verifyIdToken(m[1]).catch(() => null);
      const ip = String(req.get('x-forwarded-for') || req.ip || '').split(',')[0].trim();
      const quota = await aiQuota(user ? 'u_' + user.uid : 'ip_' + ip, audio ? '' : text, user?.uid === SAMUEL_UID);
      if (quota !== 'ok') {
        res.status(429).json({ reply: (quota === 'limit' ? LIMIT_TXT : REPEAT_TXT)[lang], limited: true });
        return;
      }

      const history = (Array.isArray(body.history) ? body.history : []).slice(-20).map(h => ({
        role: h.role === 'model' ? 'model' : 'user',
        parts: [{ text: String(h.text || '').slice(0, 2000) || '…' }],
      }));
      const langInstruction = lang === 'Tigrinya'
        ? 'You MUST respond ONLY in Tigrinya (ትግርኛ), as spoken in Eritrea, with correct Ge\'ez spelling. Keep it short; short lists are fine. Names may stay as written.'
        : lang === 'Amharic'
          ? 'You MUST respond ONLY in Amharic (አማርኛ) with correct Ge\'ez spelling. Keep it short; short lists are fine. Names may stay as written.'
          : 'Respond in English. Keep it concise.';
      const loggedIn = user && user.firebase?.sign_in_provider !== 'anonymous';
      const system = `${langInstruction}\n\n` +
        `You are Habesha AI, the friendly assistant inside Habesha Hub, a community app for the Ethiopian & Eritrean diaspora. ` +
        `Many users are older people who do not know apps well: use simple words and one step at a time. ` +
        `Help users find services, businesses and market items, and explain how the app works. ` +
        `Only recommend things from the lists below; never invent phone numbers, prices or places. ` +
        `When the user asks for a type of service, list ALL matching providers (name, city, country, short description), then explain how to book. ` +
        `If nothing matches, say so and suggest the closest options.\n` +
        `PHOTOS: the user may attach photos. Describe what you see when it helps and answer questions about them.\n` +
        `VOICE: when the user's message is a voice recording, START your reply with one line "🎤 " followed by exactly what they said (in their language), then an empty line, then your answer.\n` +
        `SELLING FOR THE USER: if the user wants to sell, swap, rent out or give away something (often with a photo), help them post it in the Market. ` +
        `Ask, one or two questions at a time, for what is missing: what it is, Habesha clothes or other category, sell / swap / rent / free, ` +
        `price (with currency; per day for rent), size, occasion and condition for Habesha clothes, city, phone number for buyers, and the name shown to buyers. ` +
        `Do NOT ask for an email address; the listing is linked to their account. ` +
        `Then show a short summary and ask "Shall I post it?". Only after they say yes, call create_listing. ` +
        `After posting, tell them it is sent and waits for approval by Habesha Hub, and that they can see it in Market. ` +
        (loggedIn ? 'The user is logged in.' : 'The user is NOT logged in: before collecting details for a listing, tell them to log in first (Profile > Log in) and come back.') +
        `\nFORMAT: plain text only. No HTML and no Markdown (no **, no <b>). Short lines and simple numbered steps are fine. ` +
        `Write Tigrinya and Amharic words only in Ge'ez letters; never mix Latin, Arabic or Cyrillic letters into a word.` +
        `\nIf someone only writes nonsense or tries to misuse the chat, answer very briefly and ask how you can help with Habesha Hub.\n\n` +
        `${APP_GUIDE}\n\n${await appContext()}\n\nBe friendly and concise.`;

      // the current turn: text, voice and the photos attached in this chat
      const parts = [];
      if (photos.length) parts.push({ text: `[${photos.length} photo(s) the user attached in this chat, newest last]` });
      photos.forEach(p => parts.push({ inline_data: { mime_type: 'image/jpeg', data: p } }));
      if (audio) parts.push({ inline_data: { mime_type: audioMime, data: audio } }, { text: '[This is a voice message from the user.]' });
      if (text) parts.push({ text });
      if (!text && !audio) parts.push({ text: '[The user sent a photo without text. Say briefly what you see and ask how you can help, e.g. sell it in the Market.]' });
      const contents = [...history, { role: 'user', parts }];

      const gemini = async () => {
        const r = await fetch(
          `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${encodeURIComponent(cleanKey())}`,
          {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
              system_instruction: { parts: [{ text: system }] },
              contents,
              tools: [{ function_declarations: [LISTING_TOOL] }],
              generationConfig: { maxOutputTokens: 2048, temperature: 0.4, thinkingConfig: { thinkingLevel: 'low' } },
            }),
          });
        const data = await r.json();
        if (!r.ok) throw Object.assign(new Error(data?.error?.message || 'ai'), { status: r.status, data });
        return data?.candidates?.[0]?.content || { parts: [] };
      };

      let content = await gemini(), posted = null, action = null;
      for (let step = 0; step < 2; step++) {
        const call = (content.parts || []).find(p => p.functionCall)?.functionCall;
        if (!call || call.name !== 'create_listing') break;
        const result = await createListingFor(user, call.args || {}, photos).catch(e => ({ ok: false, message: String(e.message || e) }));
        if (result.ok) posted = result.id; else if (result.reason === 'login') action = 'login';
        contents.push(content, { role: 'user', parts: [{ functionResponse: { name: 'create_listing', response: result } }] });
        content = await gemini();
      }
      // plain text for the app: drop HTML/Markdown and stray Arabic/Cyrillic marks next to Ge'ez letters
      const reply = (content.parts || []).filter(p => !p.thought).map(p => p.text || '').join('')
        .replace(/<\/?[a-z][^>]*>/gi, '').replace(/\*\*|__/g, '')
        .replace(/[Ѐ-ӿ؀-ۿ]+(?=[ሀ-፿])|(?<=[ሀ-፿])[Ѐ-ӿ؀-ۿ]+/g, '')
        .trim();
      res.json({ reply, posted, action });
    } catch (e) {
      console.error('aiChat', e.status || '', e.message, e.data ? JSON.stringify(e.data).slice(0, 500) : '');
      res.status(e.status ? 502 : 500).json({ error: e.status ? 'ai' : 'server', message: String(e.message || e) });
    }
  }
);


// ═══════════════════════════════════════════════════════════
// updateProviderRating — keeps ratingAvg / ratingCount on the provider
// ═══════════════════════════════════════════════════════════
exports.updateProviderRating = onDocumentWritten(
  'anonymous_services/{providerId}/reviews/{reviewId}',
  async (event) => {
    const ref = getFirestore().collection('anonymous_services').doc(event.params.providerId);
    const snap = await ref.collection('reviews').get();
    const ratings = snap.docs.map(d => Number(d.data().rating) || 0).filter(r => r >= 1 && r <= 5);
    const avg = ratings.length ? ratings.reduce((a, b) => a + b, 0) / ratings.length : 0;
    const prov = await ref.get();
    if (!prov.exists) return;
    await ref.update({ ratingAvg: Math.round(avg * 10) / 10, ratingCount: ratings.length });
  }
);

// ═══════════════════════════════════════════════════════════
// providerPage — public share page:  https://habesha-hub.no/p/cameraman-1
// Shows name, photo, description (with link preview tags) + download buttons.
// The document ID (contains the real name) is never shown.
// ═══════════════════════════════════════════════════════════
const esc = s => String(s || '').replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
const slugOf = s => String(s || '').toLowerCase().replace(/æ/g, 'ae').replace(/ø/g, 'o').replace(/å/g, 'a')
  .replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '');

exports.providerPage = onRequest({ invoker: 'public', maxInstances: 5 }, async (req, res) => {
  const slug = decodeURIComponent((req.path || '').split('/').filter(Boolean).pop() || '').toLowerCase();
  const snap = await getFirestore().collection('anonymous_services').where('available', '==', true).get();
  const doc = snap.docs.find(d => slugOf(d.data().publicName) === slug);
  res.set('Cache-Control', 'public, max-age=300');
  if (!doc) { res.status(404).send('<h1>Not found</h1><p><a href="https://habesha-hub.no">Habesha Hub</a></p>'); return; }
  const v = doc.data();
  const imgs = Array.isArray(v.sampleImages) ? v.sampleImages.filter(Boolean) : [];
  const vids = Array.isArray(v.sampleVideoUrls) ? v.sampleVideoUrls.filter(Boolean) : [];
  const thumb = imgs[0] || (vids[0] ? String(vids[0]).replace(/playlist\.m3u8$/, 'thumbnail.jpg') : 'https://habesha-hub.no/icon.png');
  const ti = v.translations?.Tigrinya || {}, am = v.translations?.Amharic || {};
  const stars = v.ratingCount ? `★ ${Number(v.ratingAvg || 0).toFixed(1)} (${v.ratingCount})` : '';
  const gallery = imgs.slice(0, 9).map(u => `<img src="${esc(u)}" loading="lazy" alt="">`).join('');
  res.send(`<!doctype html><html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>${esc(v.publicName)} – Habesha Hub</title>
<meta property="og:title" content="${esc(v.publicName)} – Habesha Hub">
<meta property="og:description" content="${esc(v.description)}">
<meta property="og:image" content="${esc(thumb)}">
<meta property="og:type" content="website">
<meta name="twitter:card" content="summary_large_image">
<style>
body{margin:0;font-family:system-ui,Arial,sans-serif;background:#131313;color:#eee}
.wrap{max-width:640px;margin:0 auto;padding:20px}
.hero{width:100%;aspect-ratio:4/3;object-fit:cover;border-radius:16px;background:#222}
h1{color:#D4AF37;margin:16px 0 4px}.muted{color:#aaa}.alt{color:#ccc;font-size:15px}
.grid{display:grid;grid-template-columns:repeat(3,1fr);gap:4px;margin:16px 0}
.grid img{width:100%;aspect-ratio:1;object-fit:cover;border-radius:6px}
.btn{display:block;text-align:center;background:#D4AF37;color:#1A1200;font-weight:700;padding:14px;border-radius:12px;text-decoration:none;margin:10px 0}
.btn2{background:transparent;color:#D4AF37;border:1px solid #D4AF37}
</style></head><body><div class="wrap">
<img class="hero" src="${esc(thumb)}" alt="">
<h1>${esc(v.publicName)}</h1>
<div class="muted">${esc(v.city)} ${stars ? '· ' + esc(stars) : ''} · ${imgs.length} photos · ${vids.length} videos</div>
<p>${esc(v.description)}</p>
${ti.description ? `<p class="alt">${esc(ti.publicName)} — ${esc(ti.description)}</p>` : ''}
${am.description ? `<p class="alt">${esc(am.publicName)} — ${esc(am.description)}</p>` : ''}
<div class="grid">${gallery}</div>
<a class="btn" href="https://habesha-hub.no/download.html">📲 Get the Habesha Hub app to book</a>
<a class="btn btn2" href="https://habesha-hub.no">habesha-hub.no</a>
<p class="muted" style="font-size:13px">In the app: Services → ${esc(v.publicName)} → Book Now</p>
</div></body></html>`);
});

// ═══════════════════════════════════════════════════════════
// Push to everyone when a NEW provider or NEW videos are added.
// Users are subscribed to topic news_en / news_ti / news_am (by app language).
// ═══════════════════════════════════════════════════════════
const NEWS = {
  news_en: { prov: n => ({ title: '✨ New on Habesha Hub', body: `${n} just joined. Have a look!` }),
             vid:  n => ({ title: `🎬 New video from ${n}`, body: 'Watch it now in Hab Tok.' }) },
  news_ti: { prov: n => ({ title: '✨ ሓድሽ ኣብ Habesha Hub', body: `${n} ተጸንቢሩ። ርኣዩ!` }),
             vid:  n => ({ title: `🎬 ሓድሽ ቪድዮ ካብ ${n}`, body: 'ሕጂ ኣብ Hab Tok ርኣዩ።' }) },
  news_am: { prov: n => ({ title: '✨ አዲስ በHabesha Hub', body: `${n} ተቀላቅሏል። ይመልከቱ!` }),
             vid:  n => ({ title: `🎬 አዲስ ቪዲዮ ከ${n}`, body: 'አሁን በHab Tok ይመልከቱ።' }) },
};
const nameFor = (v, topic) => topic === 'news_ti' ? (v.translations?.Tigrinya?.publicName || v.publicName)
  : topic === 'news_am' ? (v.translations?.Amharic?.publicName || v.publicName) : v.publicName;

async function sendNews(kind, v) {
  for (const topic of Object.keys(NEWS)) {
    await getMessaging().send({
      topic,
      notification: NEWS[topic][kind](nameFor(v, topic) || 'Habesha Hub'),
      data: { type: kind === 'prov' ? 'new_provider' : 'new_video' },
      android: { priority: 'high' },
    }).catch(e => console.error('news push failed', topic, e.message));
  }
}

exports.notifyNewProvider = onDocumentCreated('anonymous_services/{id}', async (event) => {
  const v = event.data?.data();
  if (!v || v.available === false) return;
  // a renamed provider is copied to a new ID — only announce truly new ones
  const created = v.createdAt?.toDate ? v.createdAt.toDate() : null;
  if (created && Date.now() - created.getTime() > 10 * 60 * 1000) return;
  await sendNews('prov', v);
});

exports.notifyNewVideo = onDocumentUpdated('anonymous_services/{id}', async (event) => {
  const before = event.data?.before?.data() || {};
  const after  = event.data?.after?.data()  || {};
  if (after.available === false) return;
  const nb = Array.isArray(before.sampleVideoUrls) ? before.sampleVideoUrls.length : (before.sampleVideoUrl ? 1 : 0);
  const na = Array.isArray(after.sampleVideoUrls) ? after.sampleVideoUrls.length : 0;
  if (na > nb) await sendNews('vid', after);
});


// ═══════════════════════════════════════════════════════════
// Marketplace moderation
//  • notifyNewListing  — push to admin when a listing waits for approval
//  • notifyListingApproved — push to the seller when it goes live
// ═══════════════════════════════════════════════════════════
async function tokenOf(uid) {
  if (!uid) return null;
  const d = await getFirestore().collection('users').doc(uid).get();
  return d.data()?.fcmToken || null;
}

exports.notifyNewListing = onDocumentWritten('marketplace/{id}', async (event) => {
  const after  = event.data?.after?.data();
  const before = event.data?.before?.data();
  if (!after || after.approved !== false) return;
  if (before && before.approved === false) return;   // already waiting — don't spam
  const token = await tokenOf(SAMUEL_UID);
  if (!token) return;
  await getMessaging().send({
    token,
    notification: { title: '🛒 New listing waiting for approval', body: `${after.title || 'Listing'}${after.city ? ' • ' + after.city : ''}` },
    android: { priority: 'high' },
    apns: { payload: { aps: { sound: 'default' } } },
  }).catch(e => console.error('notifyNewListing', e.message));
});

exports.notifyListingApproved = onDocumentUpdated('marketplace/{id}', async (event) => {
  const before = event.data?.before?.data();
  const after  = event.data?.after?.data();
  if (!before || !after || before.approved !== false || after.approved !== true) return;
  const token = await tokenOf(after.userId);
  if (!token) return;
  await getMessaging().send({
    token,
    notification: { title: '✅ Your listing is live', body: `${after.title || 'Your listing'} is now visible in the Habesha Hub marketplace.` },
    apns: { payload: { aps: { sound: 'default' } } },
  }).catch(e => console.error('notifyListingApproved', e.message));
});


// ═══════════════════════════════════════════════════════════
// countVideoLikes — keeps video_likes/{videoKey}.count in sync
// when a user likes / unlikes a Hab Tok video.
// ═══════════════════════════════════════════════════════════
exports.countVideoLikes = onDocumentWritten('video_likes/{videoKey}/users/{uid}', async (event) => {
  const before = event.data?.before?.exists;
  const after  = event.data?.after?.exists;
  if (before === after) return;
  const { FieldValue } = require('firebase-admin/firestore');
  const delta = after ? 1 : -1;
  const data = event.data?.after?.data() || event.data?.before?.data() || {};
  await getFirestore().collection('video_likes').doc(event.params.videoKey).set({
    count: FieldValue.increment(delta),
    serviceId: data.serviceId || null,
    updatedAt: FieldValue.serverTimestamp(),
  }, { merge: true });
});


// ═══════════════════════════════════════════════════════════
// businessPage — public share page:  https://habesha-hub.no/b/<businessId>
// Link preview (WhatsApp/Facebook) + directions, call and download buttons.
// ═══════════════════════════════════════════════════════════
const CAT_EMOJI = { Restaurant: '🍽️', Cafe: '☕', Shop: '🛍️', Barber: '💇', Club: '🎵', Clinic: '🏥', Hotel: '🏨' };

exports.businessPage = onRequest({ invoker: 'public', maxInstances: 5 }, async (req, res) => {
  const id = decodeURIComponent((req.path || '').split('/').filter(Boolean).pop() || '');
  const doc = id && !id.includes('/') ? await getFirestore().collection('businesses').doc(id).get() : null;
  const v = doc?.exists ? doc.data() : null;
  res.set('Cache-Control', 'public, max-age=300');
  if (!v || (v.status && v.status !== 'approved')) {
    res.status(404).send('<h1>Not found</h1><p><a href="https://habesha-hub.no">Habesha Hub</a></p>');
    return;
  }
  const emoji = CAT_EMOJI[v.category] || '📍';
  const img = v.imageUrl || 'https://habesha-hub.no/icon.png';
  const desc = v.description || `${v.category || 'Business'} · ${v.address || ''}`;
  const stars = v.ratingCount ? `★ ${Number(v.rating || 0).toFixed(1)} (${v.ratingCount})` : '';
  const maps = `https://www.google.com/maps/dir/?api=1&destination=${v.lat},${v.lng}`;
  res.send(`<!doctype html><html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>${esc(v.name)} – Habesha Hub</title>
<meta property="og:title" content="${esc(emoji + ' ' + v.name)} – Habesha Hub">
<meta property="og:description" content="${esc(desc)}">
<meta property="og:image" content="${esc(img)}">
<meta property="og:type" content="website">
<meta name="twitter:card" content="summary_large_image">
<style>
body{margin:0;font-family:system-ui,Arial,sans-serif;background:#131313;color:#eee}
.wrap{max-width:640px;margin:0 auto;padding:20px}
.hero{width:100%;aspect-ratio:16/9;object-fit:cover;border-radius:16px;background:#222}
.ph{width:100%;aspect-ratio:16/9;border-radius:16px;background:#2a2a2a;display:flex;align-items:center;justify-content:center;font-size:64px}
h1{color:#D4AF37;margin:16px 0 4px}.muted{color:#aaa}
.btn{display:block;text-align:center;background:#D4AF37;color:#1A1200;font-weight:700;padding:14px;border-radius:12px;text-decoration:none;margin:10px 0}
.btn2{background:transparent;color:#D4AF37;border:1px solid #D4AF37}
.row{display:flex;gap:10px}.row .btn{flex:1}
</style></head><body><div class="wrap">
${v.imageUrl ? `<img class="hero" src="${esc(img)}" alt="">` : `<div class="ph">${emoji}</div>`}
<h1>${esc(v.name)}</h1>
<div class="muted">${esc(v.category)}${v.country ? ' · ' + esc(v.country) : ''}${stars ? ' · ' + esc(stars) : ''}</div>
<p>📍 ${esc(v.address)}</p>
${v.description ? `<p>${esc(v.description)}</p>` : ''}
<div class="row">
<a class="btn" href="${esc(maps)}">🧭 Directions</a>
${v.phone ? `<a class="btn btn2" href="tel:${esc(String(v.phone).replace(/\s/g, ''))}">📞 Call</a>` : ''}
</div>
<a class="btn" href="https://habesha-hub.no/download.html">📲 Find more Habesha places in the app</a>
${v.source === 'osm' ? '<p class="muted" style="font-size:12px">Data © OpenStreetMap contributors</p>' : ''}
</div></body></html>`);
});



// ═══════════════════════════════════════════════════════════
// listingPage — habesha-hub.no/m/<id>: a marketplace listing shared on
// WhatsApp, TikTok or Facebook (photos, price, details, contact, get the app)
// ═══════════════════════════════════════════════════════════
const DEAL = { sell: 'For sale', swap: 'Swap', rent: 'For rent', free: 'Free' };
const DONE = { sell: 'Sold', swap: 'Swapped', rent: 'Rented out', free: 'Given away' };
const GARMENT = { zuria: 'Zuria · ዙርያ', kemis: 'Habesha kemis', netela: 'Netela · ነጸላ', gabi: 'Gabi · ጋቢ', suit: "Men's suit", kids: 'Kids' };
const OCCASION = { wedding: 'Wedding', church: 'Church', holiday: 'Holiday', graduation: 'Graduation', mels: 'Mels' };
const CONDITION = { new: 'New', once: 'Worn once', used: 'Used' };
exports.listingPage = onRequest({ invoker: 'public', maxInstances: 5 }, async (req, res) => {
  const id = decodeURIComponent((req.path || '').split('/').filter(Boolean).pop() || '');
  const doc = id && !id.includes('/') ? await getFirestore().collection('marketplace').doc(id).get() : null;
  const v = doc?.exists ? doc.data() : null;
  res.set('Cache-Control', 'public, max-age=300');
  if (!v || v.approved === false) {
    res.status(404).send('<h1>Not found</h1><p><a href="https://habesha-hub.no">Habesha Hub</a></p>');
    return;
  }
  const deal = DEAL[v.deal] ? v.deal : 'sell';
  const imgs = [].concat(v.imageUrl || [], v.extraImages || []).filter(Boolean).slice(0, 8);
  const price = deal === 'free' ? 'Free' : (v.price ? String(v.price) + (deal === 'rent' ? ' / day' : '') : '');
  const facts = [DEAL[deal], GARMENT[v.garment], v.size ? 'Size ' + v.size : '', OCCASION[v.occasion], CONDITION[v.condition]].filter(Boolean);
  const done = v.status === 'done';
  const phone = String(v.sellerPhone || '').replace(/[^\d+]/g, '');
  const wa = phone ? 'https://wa.me/' + phone.replace(/^\+/, '').replace(/^00/, '') + '?text=' +
    encodeURIComponent(`Hi! Is "${v.title || ''}" still available? (Habesha Hub)`) : '';
  const desc = [price, facts.join(' · '), v.city].filter(Boolean).join(' · ');
  res.send(`<!doctype html><html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>${esc(v.title)} – Habesha Hub</title>
<meta property="og:title" content="${esc((done ? DONE[deal] + ': ' : '') + v.title)} – Habesha Hub">
<meta property="og:description" content="${esc(desc)}">
<meta property="og:image" content="${esc(imgs[0] || 'https://habesha-hub.no/img/og.jpg')}">
<meta property="og:type" content="website">
<meta name="twitter:card" content="summary_large_image">
<meta name="theme-color" content="#FFFFFF">
<style>
:root{--bg:#fff;--card:#F4F1EC;--text:#1B1B1B;--sub:#5E5A54;--g:#1E7B4F;--tint:#E3F1E9}
@media(prefers-color-scheme:dark){:root{--bg:#121212;--card:#1F1F1F;--text:#F3EFE8;--sub:#A8A196;--g:#4FC48A;--tint:#173628}}
body{margin:0;font-family:Manrope,system-ui,'Noto Sans Ethiopic',sans-serif;background:var(--bg);color:var(--text)}
.wrap{max-width:640px;margin:0 auto;padding:16px}
.top{display:flex;align-items:center;gap:10px;font-weight:800;text-decoration:none;color:var(--text);margin-bottom:12px}
.top img{width:34px;height:34px;border-radius:9px}
.pics{display:flex;gap:8px;overflow-x:auto;scroll-snap-type:x mandatory;border-radius:20px}
.pics img{flex:0 0 100%;width:100%;aspect-ratio:4/5;object-fit:cover;scroll-snap-align:center;border-radius:20px;background:var(--card)}
.ph{aspect-ratio:4/3;border-radius:20px;background:var(--card);display:flex;align-items:center;justify-content:center;font-size:64px}
.stripe{display:grid;grid-template-columns:repeat(4,1fr);height:4px;margin:10px 0 0;border-radius:2px;overflow:hidden}
.stripe i:nth-child(1){background:#1E7B4F}.stripe i:nth-child(2){background:#E8B12E}.stripe i:nth-child(3){background:#C8341E}.stripe i:nth-child(4){background:#2A5DB0}
h1{margin:14px 0 6px;font-size:26px;letter-spacing:-.5px}
.price{display:inline-block;background:var(--g);color:var(--bg);font-weight:800;padding:6px 14px;border-radius:100px;margin-right:8px}
.done{display:inline-block;background:var(--text);color:var(--bg);font-weight:800;padding:6px 14px;border-radius:100px;margin:4px 0}
.facts{display:flex;flex-wrap:wrap;gap:6px;margin:12px 0}.facts span{background:var(--tint);padding:5px 12px;border-radius:100px;font-weight:600;font-size:14px}
.muted{color:var(--sub)}p{line-height:1.55;white-space:pre-line}
.btn{display:block;text-align:center;background:var(--g);color:var(--bg);font-weight:800;padding:15px;border-radius:100px;text-decoration:none;margin:10px 0}
.btn2{background:var(--card);color:var(--text)}
</style></head><body><div class="wrap">
<a class="top" href="https://habesha-hub.no"><img src="https://habesha-hub.no/img/icon-192.png" alt="">Habesha Hub · Market</a>
${imgs.length ? `<div class="pics">${imgs.map(u => `<img src="${esc(u)}" alt="">`).join('')}</div>` : '<div class="ph">🛍️</div>'}
${imgs.length > 1 ? `<div class="muted" style="font-size:13px;margin-top:6px">← ${imgs.length} photos →</div>` : ''}
<div class="stripe"><i></i><i></i><i></i><i></i></div>
<h1>${esc(v.title)}</h1>
${done ? `<div class="done">${esc(DONE[deal])}</div>` : ''}
<div>${price ? `<span class="price">${esc(price)}</span>` : ''}${v.city ? `<span class="muted">📍 ${esc(v.city)}</span>` : ''}</div>
<div class="facts">${facts.map(f => `<span>${esc(f)}</span>`).join('')}</div>
${v.description ? `<p>${esc(v.description)}</p>` : ''}
${v.sellerName ? `<div class="muted">👤 ${esc(v.sellerName)}</div>` : ''}
${!done && wa ? `<a class="btn" href="${esc(wa)}">💬 WhatsApp the seller</a>` : ''}
${!done && phone ? `<a class="btn btn2" href="tel:${esc(phone)}">📞 Call</a>` : ''}
<a class="btn ${!done && phone ? 'btn2' : ''}" href="https://habesha-hub.no/download.html">📲 See more zuria and Habesha items in the app</a>
</div></body></html>`);
});
// ═══════════════════════════════════════════════════════════
// Community help (claims / suggestions / reports)
//  • notifyAdminCommunity — push to admin when something new arrives
//  • notifyClaimApproved  — push to the owner when the claim is accepted
// ═══════════════════════════════════════════════════════════
async function pushAdmin(title, body) {
  const token = await tokenOf(SAMUEL_UID);
  if (!token) return;
  await getMessaging().send({
    token,
    notification: { title, body },
    android: { priority: 'high' },
    apns: { payload: { aps: { sound: 'default' } } },
  }).catch(e => console.error('pushAdmin', e.message));
}

exports.notifyNewClaim = onDocumentCreated('claims/{id}', async (event) => {
  const c = event.data?.data();
  if (c) await pushAdmin('🏪 New business claim', `${c.name || 'Someone'} claims ${c.businessName || 'a business'}`);
});

exports.notifyNewSuggestion = onDocumentCreated('suggestions/{id}', async (event) => {
  const s = event.data?.data();
  if (s) await pushAdmin('➕ New business suggested', `${s.name || 'A business'} · ${s.country || ''}`);
});

exports.notifyNewReport = onDocumentCreated('reports/{id}', async (event) => {
  const r = event.data?.data();
  if (r) await pushAdmin('🚩 Business reported', `${r.businessName || 'A business'}: ${r.reason || ''}`);
});

exports.notifyClaimApproved = onDocumentUpdated('claims/{id}', async (event) => {
  const before = event.data?.before?.data();
  const after  = event.data?.after?.data();
  if (!before || !after || before.status === 'approved' || after.status !== 'approved') return;
  const token = await tokenOf(after.userId);
  if (!token) return;
  await getMessaging().send({
    token,
    notification: { title: '✅ Your business is yours', body: `You can now edit ${after.businessName || 'your business'} — add photos, hours and your menu.` },
    apns: { payload: { aps: { sound: 'default' } } },
  }).catch(e => console.error('notifyClaimApproved', e.message));
});


// ═══════════════════════════════════════════════════════════
// redeemCode — unlock paid content (e.g. 450 extra driving theory
// questions) with a code the admin sends on WhatsApp.
// unlock_codes/{CODE} = { product, phone, used, createdAt }
// A code works ONCE and only for the phone number it was made for:
// the user must be signed in with that (SMS-verified) number.
// ═══════════════════════════════════════════════════════════
const { FieldValue: UnlockFV } = require('firebase-admin/firestore');
const PRODUCTS = ['theory_pro', 'lang_pro'];
const digits = s => String(s || '').replace(/[^\d]/g, '');
// Same number written as +4741234567, 004741234567 or 41234567 (Norway)
const samePhone = (a, b) => {
  const x = digits(a).replace(/^00/, ''), y = digits(b).replace(/^00/, '');
  return x === y || x.endsWith(y) && y.length >= 8 || y.endsWith(x) && x.length >= 8;
};

exports.redeemCode = onCall({ maxInstances: 5 }, async (req) => {
  const uid = req.auth?.uid;
  const phone = req.auth?.token?.phone_number || null;
  if (!uid) throw new HttpsError('unauthenticated', 'login');
  // Letters, digits and ! # @ $ % & ? + (no * _ ~ — WhatsApp turns them into formatting)
  const code = String(req.data?.code || '').trim().toUpperCase().replace(/[^A-Z0-9!#@$%&?+]/g, '');
  if (code.length < 6) throw new HttpsError('invalid-argument', 'code');

  const db = getFirestore();
  const codeRef = db.collection('unlock_codes').doc(code);
  return db.runTransaction(async (tx) => {
    const snap = await tx.get(codeRef);
    if (!snap.exists) throw new HttpsError('not-found', 'code');
    const c = snap.data();
    // Master key: reusable, unlocks everything, every use is counted
    if (c.master === true) {
      tx.update(codeRef, { uses: UnlockFV.increment(1), lastUsedBy: uid, lastUsedPhone: phone, lastUsedAt: UnlockFV.serverTimestamp() });
      tx.set(db.collection('users').doc(uid),
        { unlocks: Object.fromEntries(PRODUCTS.map(p => [p, true])) }, { merge: true });
      return { product: 'all' };
    }
    if (!PRODUCTS.includes(c.product)) throw new HttpsError('not-found', 'code');
    // Code made for a phone number → the user must have verified that number
    if (c.phone) {
      if (!phone) throw new HttpsError('failed-precondition', 'phone');
      if (!samePhone(c.phone, phone)) throw new HttpsError('permission-denied', 'other-phone');
    }
    // One code = one user: the first account that uses it keeps it
    if (c.used && c.usedBy !== uid) throw new HttpsError('already-exists', 'used');
    tx.update(codeRef, { used: true, usedBy: uid, usedPhone: phone, usedAt: UnlockFV.serverTimestamp() });
    tx.set(db.collection('users').doc(uid),
      { unlocks: { [c.product]: true }, ...(phone ? { unlockPhone: phone } : {}) }, { merge: true });
    return { product: c.product };
  });
});


// ═══════════════════════════════════════════════════════════
// verifyPurchase — unlock after a Google Play / App Store purchase.
// The app sends the purchase; we ask Google/Apple if it is real, then
// set users/{uid}.unlocks[product]. One purchase unlocks ONE account
// (purchases/{id} remembers who used it).
//
// Setup (once):
//  Android: Play Console → Setup → API access → link the Google Cloud
//           project, grant the Cloud Functions service account
//           "View financial data" + "Manage orders".
//  iOS:     App Store Connect → Users and Access → Integrations →
//           In-App Purchase → create a key, then in Google Cloud Secret
//           Manager create APPSTORE_KEY_ID, APPSTORE_ISSUER_ID and
//           APPSTORE_KEY_P8 (the .p8 file text).
// ═══════════════════════════════════════════════════════════
const crypto = require('crypto');
const { GoogleAuth } = require('google-auth-library');
const ANDROID_PACKAGE = 'no.habesha.hub';
const IOS_BUNDLES = ['no.habesha.hub', 'com.example.habeshaHub'];
const PROJECT = 'habesha-hub-7bd1d';

async function googleToken(scope) {
  const client = await new GoogleAuth({ scopes: [scope] }).getClient();
  return (await client.getAccessToken()).token;
}

async function androidPurchaseOk(productId, token) {
  const t = await googleToken('https://www.googleapis.com/auth/androidpublisher');
  const url = `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${ANDROID_PACKAGE}` +
    `/purchases/products/${encodeURIComponent(productId)}/tokens/${encodeURIComponent(token)}`;
  const r = await fetch(url, { headers: { Authorization: `Bearer ${t}` } });
  if (!r.ok) { console.error('androidpublisher', r.status, await r.text()); return null; }
  const p = await r.json();
  return p.purchaseState === 0 ? { id: 'a_' + (p.orderId || crypto.createHash('sha256').update(token).digest('hex')) } : null;
}

async function secret(name) {
  const t = await googleToken('https://www.googleapis.com/auth/cloud-platform');
  const r = await fetch(`https://secretmanager.googleapis.com/v1/projects/${PROJECT}/secrets/${name}/versions/latest:access`,
    { headers: { Authorization: `Bearer ${t}` } });
  if (!r.ok) return null;
  return Buffer.from((await r.json()).payload.data, 'base64').toString('utf8');
}

const b64url = b => Buffer.from(b).toString('base64').replace(/=+$/, '').replace(/\+/g, '-').replace(/\//g, '_');
async function iosPurchaseOk(productId, transactionId) {
  const [kid, iss, p8] = await Promise.all([secret('APPSTORE_KEY_ID'), secret('APPSTORE_ISSUER_ID'), secret('APPSTORE_KEY_P8')]);
  if (!kid || !iss || !p8) throw new HttpsError('failed-precondition', 'ios-not-configured');
  const now = Math.floor(Date.now() / 1000);
  for (const bid of IOS_BUNDLES) {
    const head = b64url(JSON.stringify({ alg: 'ES256', kid, typ: 'JWT' }));
    const body = b64url(JSON.stringify({ iss, iat: now, exp: now + 600, aud: 'appstoreconnect-v1', bid }));
    const sig = crypto.sign('sha256', Buffer.from(`${head}.${body}`), { key: p8, dsaEncoding: 'ieee-p1363' });
    const jwt = `${head}.${body}.${b64url(sig)}`;
    for (const host of ['api.storekit.itunes.apple.com', 'api.storekit-sandbox.itunes.apple.com']) {
      const r = await fetch(`https://${host}/inApps/v1/transactions/${encodeURIComponent(transactionId)}`,
        { headers: { Authorization: `Bearer ${jwt}` } });
      if (!r.ok) continue;
      const signed = (await r.json()).signedTransactionInfo;
      // Came straight from Apple over HTTPS → read the payload
      const info = JSON.parse(Buffer.from(signed.split('.')[1], 'base64').toString('utf8'));
      if (info.productId === productId && IOS_BUNDLES.includes(info.bundleId) && !info.revocationDate) {
        return { id: 'i_' + (info.originalTransactionId || info.transactionId) };
      }
      return null;
    }
  }
  return null;
}

exports.verifyPurchase = onCall({ maxInstances: 5 }, async (req) => {
  const uid = req.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'login');
  const { platform, productId, token, transactionId } = req.data || {};
  if (!PRODUCTS.includes(productId)) throw new HttpsError('invalid-argument', 'product');

  let ok = null;
  if (platform === 'android' && typeof token === 'string') ok = await androidPurchaseOk(productId, token);
  else if (platform === 'ios' && typeof transactionId === 'string') ok = await iosPurchaseOk(productId, transactionId);
  else throw new HttpsError('invalid-argument', 'platform');
  if (!ok) throw new HttpsError('permission-denied', 'not-paid');

  const db = getFirestore();
  const ref = db.collection('purchases').doc(ok.id);
  await db.runTransaction(async (tx) => {
    const s = await tx.get(ref);
    if (s.exists && s.data().uid !== uid) throw new HttpsError('already-exists', 'used');
    if (!s.exists) tx.set(ref, { uid, productId, platform, at: UnlockFV.serverTimestamp() });
    tx.set(db.collection('users').doc(uid), { unlocks: { [productId]: true } }, { merge: true });
  });
  return { product: productId };
});
