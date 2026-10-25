// ═══════════════════════════════════════════════════════════
// Henter ALLE bilder (Bunny Storage) og ALLE videoer (Bunny Stream)
// for én tilbyder og legger dem inn i Firestore — med én kommando.
//
//   Bilder : Storage-zone  → mappe  "cameraman-1"
//   Videoer: Stream-bibliotek → Collection "Cameraman 1"
//
// Nøklene blir bare på PC-en din (ikke i appen).
//
// Første gang spør scriptet deg om nøklene — bare lim dem inn.
// (Du kan også sette dem som før i PowerShell:)
//   $env:BUNNY_ZONE           = "habesha-photos"
//   $env:BUNNY_KEY            = "<Storage → zone → FTP & API Access → Password>"
//   $env:BUNNY_CDN            = "https://habesha-photos.b-cdn.net"
//   $env:BUNNY_STREAM_LIBRARY = "<Stream → bibliotek → API → Library ID (tall)>"
//   $env:BUNNY_STREAM_KEY     = "<Stream → bibliotek → API → API Key>"
//
// Kjør:
//   node tools/sync_bunny.js "Cameraman 1"
//
// Valg:
//   --folder=cameraman-1        (standard: navnet med små bokstaver og bindestrek)
//   --collection="Cameraman 1"  (standard: samme som navnet)
//   --replace                   (erstatt i stedet for å legge til)
//   --photos-only / --videos-only
//   --reset-keys                (spør om alle nøklene på nytt)
// ═══════════════════════════════════════════════════════════
const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const serviceAccount = require(require('path').join(__dirname, '..', 'serviceAccountKey.json'));

const clean = v => (v || '').trim().replace(/^["']|["']$/g, '').trim();
const args  = process.argv.slice(2);
const NAME  = args.find(a => !a.startsWith('--'));
const opt   = k => { const a = args.find(x => x.startsWith(`--${k}=`)); return a ? clean(a.split('=').slice(1).join('=')) : null; };
const has   = k => args.includes(`--${k}`);

if (!NAME) {
  console.log('Bruk:  node tools/sync_bunny.js "Cameraman 1" [--folder=cameraman-1] [--collection="Cameraman 1"] [--replace]');
  process.exit(1);
}

const slug = s => s.toLowerCase().replace(/æ/g,'ae').replace(/ø/g,'o').replace(/å/g,'a')
                   .replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '');
const FOLDER     = opt('folder') || slug(NAME);
const COLLECTION = opt('collection') || NAME;

// ── Keys: asked once, saved in .bunny-keys.json (stays on this PC, ignored by git) ──
const fs = require('fs');
const readline = require('readline');
const KEYFILE = require('path').join(__dirname, '..', '.bunny-keys.json');
let saved = {};
try { saved = JSON.parse(fs.readFileSync(KEYFILE, 'utf8')); } catch (_) {}
if (has('reset-keys')) saved = {};

const looksFake = v => !v || /\s|\(|\)|<|>|passord|password|library id|api key|lim-inn|ditt-|navnet/i.test(v);
function ask(q) {
  const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
  return new Promise(res => rl.question(q, a => { rl.close(); res(clean(a)); }));
}
async function need(name, question, check = v => !looksFake(v)) {
  let v = clean(process.env[name]) || clean(saved[name]);
  while (!check(v)) {
    v = await ask(question);
    if (!check(v)) console.log('   ⚠️  Det ser ikke riktig ut — lim inn selve verdien fra Bunny (uten mellomrom).');
  }
  saved[name] = v;
  return v;
}

let ZONE, KEY, CDN, LIB, SKEY;
let HOST   = clean(process.env.BUNNY_HOST) || 'storage.bunnycdn.com';
async function loadKeys() {
  console.log('🔑 Bunny-nøkler (spørres bare første gang, lagres i .bunny-keys.json på denne PC-en)\n');
  if (!has('videos-only')) {
    ZONE = await need('BUNNY_ZONE', '   Storage zone-navn (f.eks. habesha-photos): ',
      v => /^[a-z0-9-]+$/.test(v || ''));
    KEY  = await need('BUNNY_KEY',  '   Storage → zone → FTP & API Access → Password: ');
    CDN  = (await need('BUNNY_CDN', '   Pull zone-adresse (f.eks. https://habesha-photos.b-cdn.net): ',
      v => /^https:\/\/[a-z0-9.-]+$/i.test((v || '').replace(/\/+$/, '')))).replace(/\/+$/, '');
  }
  if (!has('photos-only')) {
    LIB  = await need('BUNNY_STREAM_LIBRARY', '   Stream → bibliotek → API → Library ID (bare tall): ',
      v => /^\d+$/.test(v || ''));
    SKEY = await need('BUNNY_STREAM_KEY', '   Stream → bibliotek → API → API Key: ');
  }
  fs.writeFileSync(KEYFILE, JSON.stringify(saved, null, 2));
  console.log('');
}
const HOSTS = ['storage.bunnycdn.com','se.storage.bunnycdn.com','uk.storage.bunnycdn.com',
  'ny.storage.bunnycdn.com','la.storage.bunnycdn.com','sg.storage.bunnycdn.com',
  'syd.storage.bunnycdn.com','br.storage.bunnycdn.com','jh.storage.bunnycdn.com'];
const mask = k => k.length > 8 ? `${k.slice(0,4)}…${k.slice(-4)} (${k.length} tegn)` : '(mangler)';

initializeApp({ credential: cert(serviceAccount) });
const db = getFirestore();

// ── PHOTOS (Bunny Storage) ─────────────────────────────────
const IMG = /\.(jpe?g|png|webp|gif)$/i;
async function storageOk() {
  for (const h of [HOST, ...HOSTS.filter(x => x !== HOST)]) {
    const r = await fetch(`https://${h}/${ZONE}/`, { headers: { AccessKey: KEY, accept: 'application/json' } });
    if (r.ok) { HOST = h; return true; }
  }
  return false;
}
async function listFolder(path) {
  const r = await fetch(`https://${HOST}/${ZONE}/${path}/`, { headers: { AccessKey: KEY, accept: 'application/json' } });
  if (r.status === 404) return [];
  if (!r.ok) throw new Error(`Storage ${r.status}: ${await r.text()}`);
  const out = [];
  for (const it of await r.json()) {
    const p = `${path}/${it.ObjectName}`;
    if (it.IsDirectory) out.push(...await listFolder(p));
    else if (IMG.test(it.ObjectName)) out.push(`${CDN}/${p.split('/').map(encodeURIComponent).join('/')}`);
  }
  return out;
}
async function getPhotos() {
  if (!ZONE || !KEY || !CDN) { console.log('⏭️  Hopper over bilder (BUNNY_ZONE/KEY/CDN mangler)'); return null; }
  if (!(await storageOk())) {
    console.error(`❌ Storage: feil zone eller passord.  Zone="${ZONE}"  Passord=${mask(KEY)}`);
    console.error('   Passord = Storage → zone → FTP & API Access → Password');
    delete saved.BUNNY_KEY; fs.writeFileSync(KEYFILE, JSON.stringify(saved, null, 2));
    console.error('   (Du blir spurt om passordet på nytt neste gang.)');
    return null;
  }
  const photos = (await listFolder(FOLDER)).sort();
  console.log(`📷 ${photos.length} bilder i Storage-mappen "${FOLDER}"`);
  return photos;
}

// ── VIDEOS (Bunny Stream) ──────────────────────────────────
let STREAM_HOST = '';
const norm = s => s.toLowerCase().replace(/\s+/g, '');
async function stream(path) {
  const r = await fetch(`https://video.bunnycdn.com/library/${LIB}${path}`,
    { headers: { AccessKey: SKEY, accept: 'application/json' } });
  if (!r.ok) throw new Error(`Stream ${r.status}: ${await r.text()}`);
  return r.json();
}
async function getVideos() {
  if (!LIB || !SKEY) { console.log('⏭️  Hopper over videoer (BUNNY_STREAM_LIBRARY/KEY mangler)'); return null; }
  let cols;
  try {
    cols = await stream('/collections?page=1&itemsPerPage=100');
  } catch (e) {
    console.error(`❌ Stream: feil Library ID eller API Key.  Library="${LIB}"  Key=${mask(SKEY)}`);
    console.error('   Stream → (bibliotek) → API → "Library ID" og "API Key"');
    delete saved.BUNNY_STREAM_KEY; delete saved.BUNNY_STREAM_LIBRARY;
    fs.writeFileSync(KEYFILE, JSON.stringify(saved, null, 2));
    console.error('   (Du blir spurt på nytt neste gang.)');
    return null;
  }
  const col = (cols.items || []).find(c => norm(c.name) === norm(COLLECTION));
  if (!col) {
    console.error(`❌ Fant ingen Stream-collection som heter "${COLLECTION}".`);
    console.error('   Collections som finnes: ' + (cols.items || []).map(c => `"${c.name}"`).join(', '));
    return null;
  }
  const cdnHost = (clean(process.env.BUNNY_STREAM_CDN) || 'vz-69969f12-733.b-cdn.net').replace(/^https?:\/\//, '').replace(/\/+$/, '');
  const videos = [];
  for (let page = 1; ; page++) {
    const res = await stream(`/videos?page=${page}&itemsPerPage=100&collection=${col.guid}&orderBy=date`);
    for (const v of res.items || []) {
      if ([5, 6].includes(v.status)) continue;                    // 5/6 = feilet
      videos.push(`https://${cdnHost}/${v.guid}/playlist.m3u8`);
    }
    if (!res.items || res.items.length < 100) break;
  }
  console.log(`🎬 ${videos.length} videoer i Stream-collection "${col.name}"`);
  STREAM_HOST = cdnHost;
  return videos;
}

// ── SAVE ───────────────────────────────────────────────────
async function run() {
  await loadKeys();
  let photos = has('videos-only') ? null : await getPhotos();
  let videos = has('photos-only') ? null : await getVideos();
  // Safety: an empty folder/collection (or a typo in the name) must not wipe everything
  if (photos && photos.length === 0 && !has('replace')) {
    console.log('⚠️  0 bilder funnet — beholder bildene som er der (bruk --replace for å tømme)');
    photos = null;
  }
  if (videos && videos.length === 0 && !has('replace')) {
    console.log('⚠️  0 videoer funnet — beholder videoene som er der (bruk --replace for å tømme)');
    videos = null;
  }
  if (photos === null && videos === null) process.exit(1);

  const snap = await db.collection('anonymous_services').where('publicName', '==', NAME).get();
  if (snap.empty) { console.error(`❌ "${NAME}" finnes ikke i Firestore (publicName)`); process.exit(1); }

  for (const doc of snap.docs) {
    const d = doc.data();
    const upd = {};
    if (photos) {
      // Mirror Bunny Storage: photos deleted in Bunny disappear from the app.
      // Photos from other places (e.g. uploaded from the phone) are kept.
      const old = Array.isArray(d.sampleImages) ? d.sampleImages : [];
      const keep = has('replace') ? [] : old.filter(u => !String(u).startsWith(CDN + '/'));
      upd.sampleImages = [...new Set([...keep, ...photos])];
      const removed = old.filter(u => !upd.sampleImages.includes(u));
      if (removed.length) console.log(`🗑️  ${removed.length} bilder fjernet (slettet i Bunny)`);
    }
    if (videos) {
      const old = [
        ...(typeof d.sampleVideoUrl === 'string' && d.sampleVideoUrl.trim() ? [d.sampleVideoUrl.trim()] : []),
        ...(Array.isArray(d.sampleVideoUrls) ? d.sampleVideoUrls : []),
      ];
      // Mirror Bunny Stream: videos deleted in Bunny disappear from the app.
      const keep = has('replace') ? [] : old.filter(u => !String(u).includes(STREAM_HOST + '/'));
      upd.sampleVideoUrls = [...new Set([...keep, ...videos])];
      const removed = old.filter(u => !upd.sampleVideoUrls.includes(u));
      if (removed.length) console.log(`🗑️  ${removed.length} videoer fjernet (slettet i Bunny)`);
      upd.sampleVideoUrl = FieldValue.delete();
    }
    await doc.ref.update(upd);
    console.log(`✅ ${doc.id}: ${upd.sampleImages ? upd.sampleImages.length + ' bilder' : ''}` +
      `${upd.sampleImages && upd.sampleVideoUrls ? ', ' : ''}` +
      `${upd.sampleVideoUrls ? upd.sampleVideoUrls.length + ' videoer' : ''}`);
  }
  process.exit(0);
}
run().catch(e => { console.error('❌', e.message || e); process.exit(1); });
