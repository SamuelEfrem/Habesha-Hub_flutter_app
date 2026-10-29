// Yosiefsbook — renders one interactive lesson (HTML, not PDF) and makes it come alive:
// tap to hear the author's voice, "play all", find-the-letter game, finger tracing, stars.
import { esc } from './common.js';
import { tableHtml } from './wb.js';

/* A lesson = { title, titleTi, blocks: [...] }. Block types:
   text     { ti, en }
   letters  { items:[{k, l, r, a}] }          l = letter, r = romanization, a = has audio
   words    { items:[{k, w, hl, m, e, a}] }   w = word, hl = letters to highlight, m = meaning, e = emoji
   sentence { k, ti, en, a }
   game     { }                               "find the letter" from the lesson's letters
   trace    { l }                             write the letter with a finger
   picture  { k, cap, write }                 uploaded picture (write = children can write on it)
   heading  { ti }                            chapter title from the book
   table    { title, cols, rows, ar, w, cells } exercise table from the book, with boxes to write in
   wline    { label }                         a line to write on (name, school) */

export const BLOCK_TYPES = ['letters', 'words', 'sentence', 'text', 'game', 'trace', 'picture', 'heading', 'table', 'wline'];

function hl(word, part) {
  const w = esc(word || '');
  if (!part) return w;
  const i = (word || '').indexOf(part);
  if (i < 0) return w;
  return esc(word.slice(0, i)) + '<i>' + esc(part) + '</i>' + esc(word.slice(i + part.length));
}

/**
 * root   – element to render into
 * lesson – lesson data
 * ctx    – { t(key), audioUrl(k) → Promise<url>, imgUrl(k) → Promise<url>, onStar(), editable }
 */
export function renderLesson(root, lesson, ctx) {
  const t = ctx.t;
  const blocks = lesson.blocks || [];
  const letters = blocks.filter(b => b.type === 'letters').flatMap(b => b.items || []).filter(x => x.l);
  let html = `<div class="lhead"><h1>${esc(lesson.titleTi || lesson.title || '')}</h1>
    ${lesson.titleTi && lesson.title ? `<p class="lsub">${esc(lesson.title)}</p>` : ''}
    <button class="btn btn-gold" data-playall>▶ ${esc(t('playAll'))}</button></div>`;
  let n = 0;
  blocks.forEach((b, bi) => {
    const head = (label) => `<h2><span class="n">${++n}</span>${esc(label)}</h2>`;
    if (b.type === 'text') {
      html += `<section class="lpanel ltext"><div class="stripe"></div>
        ${b.ti ? `<p class="ti">${esc(b.ti).replace(/\n/g, '<br>')}</p>` : ''}${b.en ? `<p class="en">${esc(b.en).replace(/\n/g, '<br>')}</p>` : ''}</section>`;
      n++; return;
    }
    if (b.type === 'letters' && (b.items || []).length) {
      const [first, ...rest] = b.items;
      html += `<section class="lpanel"><div class="stripe"></div>${head(t('bLetters'))}
        <div class="lbig">
          <button class="tap mother ${first.a ? 'has' : ''}" data-k="${esc(first.k)}" aria-label="${esc(first.l)}">${esc(first.l)}</button>
          <div class="lforms">${b.items.map(x => `<button class="tap lform ${x.a ? 'has' : ''}" data-k="${esc(x.k)}" aria-label="${esc(x.l)}"><b>${esc(x.l)}</b>${x.r ? `<small>${esc(x.r)}</small>` : ''}</button>`).join('')}</div>
        </div></section>`;
      return;
    }
    if (b.type === 'words' && (b.items || []).length) {
      html += `<section class="lpanel"><div class="stripe"></div>${head(t('bWords'))}
        <div class="lwords">${b.items.map(x => `<button class="tap lword ${x.a ? 'has' : ''}" data-k="${esc(x.k)}">
          ${x.img ? `<img data-img="${esc(x.img)}" alt="">` : `<span class="emo">${esc(x.e || '')}</span>`}
          <b>${hl(x.w, x.hl)}</b>${x.m ? `<small>${esc(x.m)}</small>` : ''}</button>`).join('')}</div></section>`;
      return;
    }
    if (b.type === 'sentence' && b.ti) {
      html += `<section class="lpanel"><div class="stripe"></div>${head(t('bSentence'))}
        <button class="tap lsentence ${b.a ? 'has' : ''}" data-k="${esc(b.k)}"><b>${esc(b.ti)}</b>${b.en ? `<small>${esc(b.en)}</small>` : ''}</button></section>`;
      return;
    }
    if (b.type === 'game' && letters.length >= 2) {
      html += `<section class="lpanel"><div class="stripe"></div>${head(t('bGame'))}
        <div class="lgame" data-game="${bi}"><p class="q">${esc(t('find'))} <b class="ql"></b> <button class="ic" data-hear aria-label="${esc(t('listen'))}">🔊</button></p>
        <div class="opts"></div><div class="stars" aria-live="polite"></div></div></section>`;
      return;
    }
    if (b.type === 'trace' && b.l) {
      html += `<section class="lpanel"><div class="stripe"></div>${head(t('bTrace'))}
        <div class="ltrace" data-l="${esc(b.l)}"><canvas width="560" height="560" aria-label="${esc(t('bTrace'))} ${esc(b.l)}"></canvas>
        <div class="btnrow"><button class="btn btn-ghost btn-small" data-erase aria-pressed="false">🧽 ${esc(t('eraser'))}</button>
        <button class="btn btn-ghost btn-small" data-clear>${esc(t('clear'))}</button>
        <button class="btn btn-gold btn-small" data-done>✓ ${esc(t('done'))}</button></div></div></section>`;
      return;
    }
    if (b.type === 'picture' && b.k) {
      html += b.write
        ? `<section class="lpanel lpic"><div class="wr wpic" data-b="${bi}"><img data-img="${esc(b.k)}" alt="${esc(b.cap || '')}"><canvas class="ink" aria-hidden="true"></canvas></div>${b.cap ? `<p class="en">${esc(b.cap)}</p>` : ''}</section>`
        : `<section class="lpanel lpic"><div class="stripe"></div><img data-img="${esc(b.k)}" alt="${esc(b.cap || '')}">${b.cap ? `<p class="en">${esc(b.cap)}</p>` : ''}</section>`;
      return;
    }
    if (b.type === 'heading' && b.ti) {
      html += `<section class="lpanel lheading"><h1>${esc(b.ti)}</h1></section>`;
      return;
    }
    if (b.type === 'table' && (b.cells || b.cj)) {
      const tb = b.cells ? b : { ...b, cells: JSON.parse(b.cj) };      // stored packed (Firestore has no lists in lists)
      html += `<section class="lpanel lex"><div class="stripe"></div>${head(b.title || t('bWrite'))}${tableHtml(tb, bi)}</section>`;
      return;
    }
    if (b.type === 'wline') {
      html += `<section class="lpanel"><div class="lline wr" data-b="${bi}"><span>${esc(b.label || '')}</span><i></i><canvas class="ink" aria-hidden="true"></canvas></div></section>`;
      return;
    }
  });
  root.innerHTML = html;

  // pictures
  root.querySelectorAll('img[data-img]').forEach(async im => { try { im.src = await ctx.imgUrl(im.dataset.img); } catch (e) {} });
  root.querySelectorAll('.ltable img[data-k]').forEach(async im => { try { im.src = await ctx.imgUrl(im.dataset.k); } catch (e) {} });

  // sound
  const audioKeys = new Set();
  blocks.forEach(b => { (b.items || []).forEach(x => x.a && audioKeys.add(x.k)); if (b.a) audioKeys.add(b.k); });
  let current = null;
  const play = k => new Promise(async res => {
    if (current) { current.pause(); current = null; }
    if (!audioKeys.has(k)) { chime(); setTimeout(res, 420); return; }
    try { const a = new Audio(await ctx.audioUrl(k)); current = a; a.onended = a.onerror = () => res(); await a.play(); }
    catch (e) { res(); }
  });
  const bounce = el => { el.classList.remove('playing'); void el.offsetWidth; el.classList.add('playing'); };
  root.querySelectorAll('.tap[data-k]').forEach(el => el.addEventListener('click', () => { bounce(el); play(el.dataset.k); }));
  let playingAll = false;
  root.querySelector('[data-playall]').onclick = async e => {
    if (playingAll) { playingAll = false; return; }
    playingAll = true; e.target.classList.add('on');
    for (const el of root.querySelectorAll('.tap[data-k]')) {
      if (!playingAll) break;
      if (!audioKeys.has(el.dataset.k)) continue;
      if (ctx.reveal) ctx.reveal(el); else el.scrollIntoView({ behavior: 'smooth', block: 'center' });
      bounce(el);
      await play(el.dataset.k); await new Promise(r => setTimeout(r, 300));
    }
    playingAll = false; e.target.classList.remove('on');
  };

  // game
  root.querySelectorAll('.lgame').forEach(g => {
    let target = null, misses = 0;
    const ask = () => {
      target = letters[Math.floor(Math.random() * letters.length)];
      const others = letters.filter(x => x.l !== target.l).sort(() => Math.random() - .5).slice(0, 3);
      g.querySelector('.ql').textContent = target.l;
      const box = g.querySelector('.opts');
      box.innerHTML = [target, ...others].sort(() => Math.random() - .5)
        .map(o => `<button class="tap opt" data-v="${esc(o.l)}">${esc(o.l)}</button>`).join('');
      box.querySelectorAll('.opt').forEach(b => b.onclick = () => {
        if (b.dataset.v === target.l) {
          b.classList.add('right'); praise(misses ? 'good' : 'great'); misses = 0;
          g.querySelector('.stars').textContent += '⭐'; confetti(); ctx.onStar && ctx.onStar();
          setTimeout(ask, 1300);
        } else { b.classList.remove('wrong'); void b.offsetWidth; b.classList.add('wrong'); misses++; praise('again'); }
      });
    };
    g.querySelector('[data-hear]').onclick = () => target && play(target.k);
    ask();
  });

  // tracing
  root.querySelectorAll('.ltrace').forEach(tr => {
    const c = tr.querySelector('canvas'), x = c.getContext('2d'), L = tr.dataset.l;
    const guide = () => {
      x.clearRect(0, 0, c.width, c.height);
      x.fillStyle = '#fff'; x.fillRect(0, 0, c.width, c.height);
      x.strokeStyle = '#e6dcc4'; x.setLineDash([10, 10]); x.lineWidth = 2;
      x.beginPath(); x.moveTo(0, c.height * .78); x.lineTo(c.width, c.height * .78); x.stroke(); x.setLineDash([]);
      x.font = `700 ${Math.round(c.height * .68)}px 'Noto Sans Ethiopic', sans-serif`;
      x.textAlign = 'center'; x.textBaseline = 'alphabetic'; x.fillStyle = 'rgba(212,175,55,.28)';
      x.fillText(L, c.width / 2, c.height * .76);
    };
    // what the child wrote is kept as strokes, so the eraser removes writing but never the guide letter
    let strokes = [], drawing = null, erasing = false;
    const redraw = () => {
      guide();
      x.strokeStyle = '#0E7A48'; x.lineWidth = 26; x.lineCap = 'round'; x.lineJoin = 'round';
      for (const st of strokes) { x.beginPath(); x.moveTo(st[0], st[1]); for (let i = 2; i < st.length; i += 2) x.lineTo(st[i], st[i + 1]); if (st.length === 2) x.lineTo(st[0] + .1, st[1]); x.stroke(); }
    };
    (document.fonts ? document.fonts.load(`700 100px 'Noto Sans Ethiopic'`, L) : Promise.resolve()).then(redraw, redraw);
    const pos = e => { const r = c.getBoundingClientRect(); return [(e.clientX - r.left) * c.width / r.width, (e.clientY - r.top) * c.height / r.height]; };
    const rub = (px, py) => {
      const before = strokes.length;
      strokes = strokes.filter(st => { for (let i = 0; i < st.length; i += 2) if (Math.hypot(st[i] - px, st[i + 1] - py) < 34) return false; return true; });
      if (strokes.length !== before) redraw();
    };
    c.addEventListener('pointerdown', e => {
      c.setPointerCapture(e.pointerId); const [px, py] = pos(e);
      if (erasing) { drawing = 'erase'; rub(px, py); return; }
      drawing = [px, py]; strokes.push(drawing); redraw();
    });
    c.addEventListener('pointermove', e => {
      if (!drawing) return; const [px, py] = pos(e);
      if (drawing === 'erase') { rub(px, py); return; }
      drawing.push(px, py);
      x.strokeStyle = '#0E7A48'; x.lineWidth = 26; x.lineCap = 'round'; x.lineJoin = 'round';
      x.beginPath(); x.moveTo(drawing[drawing.length - 4], drawing[drawing.length - 3]); x.lineTo(px, py); x.stroke();
    });
    c.addEventListener('pointerup', () => { drawing = null; });
    const eb = tr.querySelector('[data-erase]');
    eb.onclick = () => { erasing = !erasing; eb.classList.toggle('on', erasing); eb.setAttribute('aria-pressed', erasing ? 'true' : 'false'); };
    tr.querySelector('[data-clear]').onclick = () => { strokes = []; redraw(); };
    tr.querySelector('[data-done]').onclick = () => {
      const r = checkTrace(L, strokes, c.width, c.height);
      if (r !== 'great' && r !== 'good') { praise('again', r === 'outside' ? 'ደጊምካ ፈትን – ኣብ ልዕሊ ፊደል ጽሓፍ' : 'ደጊምካ ፈትን – ምሉእ ፊደል ጽሓፍ'); return; }
      praise(r); confetti(); ctx.onStar && ctx.onStar();
      setTimeout(() => { strokes = []; redraw(); }, 1400);
    };
  });

  return { stop() { playingAll = false; if (current) current.pause(); } };
}

/**
 * How well did the child write over the guide letter?
 * covered: how much of the letter has writing on or next to it; inside: how much of the writing is on the letter.
 * → 'great' | 'good' | 'short' (not the whole letter) | 'outside' (writing beside the letter)
 */
function checkTrace(L, strokes, W, H) {
  const n = strokes.reduce((a, st) => a + st.length / 2, 0);
  if (n < 4) return 'short';
  const S = 140, k = S / W;
  const mask = (draw) => { const c = document.createElement('canvas'); c.width = c.height = S; const x = c.getContext('2d'); draw(x); return x.getImageData(0, 0, S, S).data; };
  const letter = (x, grow) => {
    x.font = `700 ${Math.round(H * .68 * k)}px 'Noto Sans Ethiopic', sans-serif`;
    x.textAlign = 'center'; x.textBaseline = 'alphabetic'; x.fillStyle = x.strokeStyle = '#000';
    x.fillText(L, S / 2, H * .76 * k);
    if (grow) { x.lineWidth = grow * k; x.lineJoin = 'round'; x.strokeText(L, S / 2, H * .76 * k); }
  };
  const lines = (x, w) => {
    x.strokeStyle = '#000'; x.lineWidth = w * k; x.lineCap = 'round'; x.lineJoin = 'round';
    for (const st of strokes) { x.beginPath(); x.moveTo(st[0] * k, st[1] * k); for (let i = 2; i < st.length; i += 2) x.lineTo(st[i] * k, st[i + 1] * k); if (st.length === 2) x.lineTo(st[0] * k + .1, st[1] * k); x.stroke(); }
  };
  const Lm = mask(x => letter(x, 0)), Lw = mask(x => letter(x, 44)), Sm = mask(x => lines(x, 26)), Sw = mask(x => lines(x, 70));
  let lp = 0, lc = 0, sp = 0, si = 0;
  for (let i = 3; i < Lm.length; i += 4) {
    if (Lm[i] > 100) { lp++; if (Sw[i] > 100) lc++; }
    if (Sm[i] > 100) { sp++; if (Lw[i] > 100) si++; }
  }
  if (!lp || !sp) return 'short';
  const covered = lc / lp, inside = si / sp;
  if (inside < .72) return 'outside';
  if (covered < .7) return 'short';
  return covered >= .86 && inside >= .86 ? 'great' : 'good';
}

// Tigrinya praise for the child, with clapping. Words as written in Tigrinya.
const PRAISE = {
  great: ['ብጣዕሚ ጽቡቕ!', 'ኣዝዩ ጽቡቕ!', 'ጎበዝ!'],
  good: ['ጽቡቕ!', 'ሓቂ ኢኻ!'],
  again: ['ደጊምካ ፈትን!', 'ጌጋ እዩ – ደጊምካ ፈትን']
};
export function praise(kind, text) {
  const list = PRAISE[kind] || PRAISE.good, word = text || list[Math.floor(Math.random() * list.length)];
  document.querySelectorAll('.praise').forEach(p => p.remove());
  const d = document.createElement('div');
  d.className = 'praise ' + kind; d.setAttribute('role', 'status');
  d.textContent = (kind === 'again' ? '🙂 ' : kind === 'great' ? '🌟 ' : '👏 ') + word;
  document.body.appendChild(d);
  setTimeout(() => d.remove(), 1600);
  if (kind === 'again') { chime(330, .22); setTimeout(() => chime(262, .3), 180); }
  else { clap(kind === 'great' ? 8 : 4); setTimeout(() => chime(1175, .3), 60); }
}
/** clapping hands, made with short bursts of noise */
export function clap(times = 5) {
  try {
    actx = actx || new (window.AudioContext || window.webkitAudioContext)();
    const len = Math.floor(actx.sampleRate * .06), buf = actx.createBuffer(1, len, actx.sampleRate), d = buf.getChannelData(0);
    for (let i = 0; i < len; i++) d[i] = (Math.random() * 2 - 1) * Math.pow(1 - i / len, 4);
    for (let k = 0; k < times; k++) {
      const src = actx.createBufferSource(), f = actx.createBiquadFilter(), g = actx.createGain();
      src.buffer = buf; f.type = 'bandpass'; f.frequency.value = 1100 + Math.random() * 900; f.Q.value = .8;
      g.gain.value = .9; src.connect(f).connect(g).connect(actx.destination);
      src.start(actx.currentTime + k * (.11 + Math.random() * .05));
    }
  } catch (e) {}
}

let actx = null;
export function chime(freq = 660, dur = .25) {
  try {
    actx = actx || new (window.AudioContext || window.webkitAudioContext)();
    const o = actx.createOscillator(), g = actx.createGain();
    o.type = 'sine'; o.frequency.value = freq;
    g.gain.setValueAtTime(.0001, actx.currentTime);
    g.gain.exponentialRampToValueAtTime(.22, actx.currentTime + .02);
    g.gain.exponentialRampToValueAtTime(.0001, actx.currentTime + dur);
    o.connect(g).connect(actx.destination); o.start(); o.stop(actx.currentTime + dur);
  } catch (e) {}
}
export function confetti() {
  if (matchMedia('(prefers-reduced-motion: reduce)').matches) return;
  const colors = ['#0E7A48', '#D4A017', '#C8102E', '#F2D06B'];
  for (let i = 0; i < 36; i++) {
    const c = document.createElement('div'); c.className = 'confetti';
    c.style.left = Math.random() * 100 + 'vw'; c.style.background = colors[i % 4];
    c.style.animationDuration = 1.2 + Math.random() * 1.4 + 's';
    document.body.appendChild(c); setTimeout(() => c.remove(), 3000);
  }
}
