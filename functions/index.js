const { onDocumentCreated, onDocumentUpdated, onDocumentWritten } = require('firebase-functions/v2/firestore');
const { setGlobalOptions } = require('firebase-functions/v2');
const { onRequest, onCall, HttpsError } = require('firebase-functions/v2/https');
const { defineSecret }     = require('firebase-functions/params');
const { initializeApp }     = require('firebase-admin/app');

// Firestore database is in europe-west1 → functions must run in the same region
setGlobalOptions({ region: 'europe-west1' });
const { getMessaging }      = require('firebase-admin/messaging');
const { getFirestore }      = require('firebase-admin/firestore');

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
const GEMINI_MODEL = 'gemini-3.5-flash-lite';

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

exports.aiChat = onRequest(
  { secrets: [GEMINI_KEY], cors: true, invoker: 'public', maxInstances: 5, timeoutSeconds: 60 },
  async (req, res) => {
    if (req.method !== 'POST') { res.status(405).send('POST only'); return; }
    try {
      const body = req.body || {};
      const text = String(body.text || '').slice(0, 1000).trim();
      if (!text) { res.status(400).json({ error: 'empty' }); return; }
      const lang = ['Tigrinya', 'Amharic'].includes(body.lang) ? body.lang : 'English';
      const history = (Array.isArray(body.history) ? body.history : []).slice(-20).map(m => ({
        role: m.role === 'model' ? 'model' : 'user',
        parts: [{ text: String(m.text || '').slice(0, 2000) }],
      }));

      const langInstruction = lang === 'Tigrinya'
        ? 'You MUST respond ONLY in Tigrinya (ትግርኛ). Keep it short; short lists are fine. Provider names may stay as written.'
        : lang === 'Amharic'
          ? 'You MUST respond ONLY in Amharic (አማርኛ). Keep it short; short lists are fine. Provider names may stay as written.'
          : 'Respond in English. Keep it concise.';
      const system = `${langInstruction}\n\n` +
        `You are the Habesha Hub assistant in a community app for the Ethiopian & Eritrean diaspora. ` +
        `Help users find services (photographers, decoration, guesthouses, transport, clothing, hawala, flight & visa), ` +
        `businesses and marketplace items. Only recommend things from the lists below. ` +
        `When the user asks for a type of service, list ALL matching providers (name, city, country, short description) ` +
        `so they can choose, then explain how to book. If nothing matches, say so and suggest the closest options.\n\n` +
        `${await appContext()}\n\nBe friendly and concise.`;

      const r = await fetch(
        `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${encodeURIComponent(cleanKey())}`,
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            system_instruction: { parts: [{ text: system }] },
            contents: [...history, { role: 'user', parts: [{ text }] }],
            generationConfig: { maxOutputTokens: 700, temperature: 0.5 },
          }),
        });
      const data = await r.json();
      if (!r.ok) {
        console.error('Gemini error', r.status, JSON.stringify(data));
        res.status(502).json({ error: 'ai', status: r.status, message: data?.error?.message || '' });
        return;
      }
      const reply = data?.candidates?.[0]?.content?.parts?.map(p => p.text || '').join('') || '';
      res.json({ reply });
    } catch (e) {
      console.error(e);
      res.status(500).json({ error: 'server', message: String(e && e.message || e) });
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
  const phone = req.auth?.token?.phone_number;
  if (!uid) throw new HttpsError('unauthenticated', 'login');
  if (!phone) throw new HttpsError('failed-precondition', 'phone');      // app asks for SMS verification
  const code = String(req.data?.code || '').trim().toUpperCase().replace(/[^A-Z0-9]/g, '');
  if (code.length < 6) throw new HttpsError('invalid-argument', 'code');

  const db = getFirestore();
  const codeRef = db.collection('unlock_codes').doc(code);
  return db.runTransaction(async (tx) => {
    const snap = await tx.get(codeRef);
    if (!snap.exists) throw new HttpsError('not-found', 'code');
    const c = snap.data();
    if (!PRODUCTS.includes(c.product)) throw new HttpsError('not-found', 'code');
    if (!samePhone(c.phone, phone)) throw new HttpsError('permission-denied', 'other-phone');
    if (c.used && c.usedBy !== uid) throw new HttpsError('already-exists', 'used');
    tx.update(codeRef, { used: true, usedBy: uid, usedAt: UnlockFV.serverTimestamp() });
    tx.set(db.collection('users').doc(uid),
      { unlocks: { [c.product]: true }, unlockPhone: phone }, { merge: true });
    return { product: c.product };
  });
});
