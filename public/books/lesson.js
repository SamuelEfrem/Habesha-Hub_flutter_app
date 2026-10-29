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
        <div class="btnrow"><button class="btn btn-ghost btn-small" data-clear>${esc(t('clear'))}</button>
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
    let target = null;
    const ask = () => {
      target = letters[Math.floor(Math.random() * letters.length)];
      const others = letters.filter(x => x.l !== target.l).sort(() => Math.random() - .5).slice(0, 3);
      g.querySelector('.ql').textContent = target.l;
      const box = g.querySelector('.opts');
      box.innerHTML = [target, ...others].sort(() => Math.random() - .5)
        .map(o => `<button class="tap opt" data-v="${esc(o.l)}">${esc(o.l)}</button>`).join('');
      box.querySelectorAll('.opt').forEach(b => b.onclick = () => {
        if (b.dataset.v === target.l) {
          b.classList.add('right'); chime(880, .18); setTimeout(() => chime(1175, .3), 150);
          g.querySelector('.stars').textContent += '⭐'; confetti(); ctx.onStar && ctx.onStar();
          setTimeout(ask, 900);
        } else { b.classList.remove('wrong'); void b.offsetWidth; b.classList.add('wrong'); chime(220, .3); }
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
    (document.fonts ? document.fonts.load(`700 100px 'Noto Sans Ethiopic'`, L) : Promise.resolve()).then(guide, guide);
    let drawing = false;
    const pos = e => { const r = c.getBoundingClientRect(); return [(e.clientX - r.left) * c.width / r.width, (e.clientY - r.top) * c.height / r.height]; };
    c.addEventListener('pointerdown', e => { drawing = true; c.setPointerCapture(e.pointerId); const [px, py] = pos(e); x.beginPath(); x.moveTo(px, py); });
    c.addEventListener('pointermove', e => {
      if (!drawing) return; const [px, py] = pos(e);
      x.lineTo(px, py); x.strokeStyle = '#0E7A48'; x.lineWidth = 26; x.lineCap = 'round'; x.lineJoin = 'round'; x.stroke();
    });
    c.addEventListener('pointerup', () => { drawing = false; });
    tr.querySelector('[data-clear]').onclick = guide;
    tr.querySelector('[data-done]').onclick = () => { chime(880, .18); setTimeout(() => chime(1175, .3), 150); confetti(); ctx.onStar && ctx.onStar(); setTimeout(guide, 900); };
  });

  return { stop() { playingAll = false; if (current) current.pause(); } };
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
