// Yosiefsbook workbook: one book page rebuilt as a web lesson — headings, exercise titles, flowing text,
// responsive tables (cells, colours, photos) and a writing layer on every table and picture.
// Page data = { n, blocks:[ h{lines} | title{spans} | p{lines} | img{k,ar,w} | table{cols,rows,ar,w,cells} ] }
import { esc } from './common.js';

const spans = list => (list || []).map(x => x.c || x.b
  ? `<span style="${x.c ? `color:${x.c};` : ''}${x.b ? 'font-weight:800;' : ''}">${esc(x.t)}</span>` : esc(x.t)).join('');

/** Build the lesson element. imgUrl(k) → Promise<url>. Returns { el, blocks: [elements that take writing] } */
export function buildPage(data, imgUrl) {
  const el = document.createElement('article');
  el.className = 'lesson';
  let ex = 0;
  const html = data.blocks.map((b, bi) => {
    if (b.type === 'h') return `<h2 class="lh">${b.lines.map(spans).join('<br>')}</h2>`;
    if (b.type === 'title') return `<h3 class="ex"><span class="exn">${++ex}</span><span>${spans(b.spans)}</span></h3>`;
    if (b.type === 'p') return `<p class="lp">${b.lines.map(spans).join(' ')}</p>`;
    if (b.type === 'line') return `<div class="lline wr" data-b="${bi}"><span>${esc(b.label)}</span><i></i><canvas class="ink" aria-hidden="true"></canvas></div>`;
    if (b.type === 'img') return `<figure class="lfig wr" data-b="${bi}" style="--w:${Math.max(30, Math.round(b.w * 100))}%">
      <img data-k="${esc(b.k)}" alt="" draggable="false" style="aspect-ratio:${b.ar}"><canvas class="ink" aria-hidden="true"></canvas></figure>`;
    if (b.type === 'table') return tableHtml(b, bi);
    return '';
  }).join('');
  el.innerHTML = html;
  el.querySelectorAll('img[data-k]').forEach(im => imgUrl(im.dataset.k).then(u => { im.src = u; }).catch(() => im.remove()));
  return { el, blocks: [...el.querySelectorAll('.wr')] };
}

/** One exercise table: same rows and columns as the book, cells with letters, colours and photos, and a writing layer. */
export function tableHtml(b, bi) {
  // cell positions as % of the table, from the book's column widths and row heights
  const cx = [0], cy = [0];
  b.cols.forEach(f => cx.push(cx[cx.length - 1] + f * 100));
  b.rows.forEach(f => cy.push(cy[cy.length - 1] + f * 100));
  const cells = b.cells.map(c => {
    const cls = ['cell', c.lines ? 'has' : 'blank', c.al === 'l' ? 'al' : '', c.outline ? 'outline' : '', c.trace ? 'trace' : ''].join(' ');
    const r1 = c.r + (c.rs || 1), c1 = c.c + (c.cs || 1);
    const style = `left:${cx[c.c].toFixed(3)}%;top:${cy[c.r].toFixed(3)}%;width:${(cx[c1] - cx[c.c]).toFixed(3)}%;height:${(cy[r1] - cy[c.r]).toFixed(3)}%;${c.bg ? `background:${c.bg};` : ''}${c.fs ? `font-size:${c.fs}cqw;` : ''}`;
    const img = c.img ? `<img data-k="${esc(c.img)}" alt="" draggable="false" style="aspect-ratio:${c.ar};width:${Math.round((c.fw || .9) * 100)}%">` : '';
    const txt = c.lines ? `<div class="ct">${c.lines.map(spans).join('<br>')}</div>` : '';
    return `<div class="${cls}" style="${style}">${img}${txt}</div>`;
  }).join('');
  return `<div class="ltable wr ${b.thick ? 'thick' : ''}" data-b="${bi}" style="--w:${Math.round(b.w * 100)}%;aspect-ratio:${b.ar}">
    <div class="grid">${cells}</div><canvas class="ink" aria-hidden="true"></canvas></div>`;
}

// ── writing layer ──
// Strokes are stored in block coordinates (0–10000) so they fit any screen, iPad or classroom board.
export function strokePath(ctx, s, W, H) {
  const p = s.p, X = i => p[i] * W / 1e4, Y = i => p[i] * H / 1e4;
  ctx.globalCompositeOperation = s.e ? 'destination-out' : 'source-over';
  ctx.strokeStyle = ctx.fillStyle = s.c || '#1a1a1a';
  ctx.lineWidth = (s.w || 4) * (s.e ? 5 : 1) * W / 1000;
  ctx.lineCap = 'round'; ctx.lineJoin = 'round';
  if (p.length === 2) { ctx.beginPath(); ctx.arc(X(0), Y(1), ctx.lineWidth / 2, 0, 7); ctx.fill(); return; }
  ctx.beginPath(); ctx.moveTo(X(0), Y(1));
  for (let i = 2; i < p.length - 2; i += 2) ctx.quadraticCurveTo(X(i), Y(i + 1), (X(i) + X(i + 2)) / 2, (Y(i + 1) + Y(i + 3)) / 2);
  ctx.lineTo(X(p.length - 2), Y(p.length - 1));
  ctx.stroke();
}

/**
 * Attach pen input to a page's canvas.
 * opts: { strokes:[], pen():{c,w,erase}, canWrite(pointerType) → bool, onStroke(strokes) }
 */
export function attachInk(blockEl, opts) {
  const c = blockEl.querySelector('canvas.ink');
  let drawing = null;
  const paint = () => {
    const ctx = c.getContext('2d'); ctx.clearRect(0, 0, c.width, c.height);
    for (const s of opts.strokes) strokePath(ctx, s, c.width, c.height);
    if (drawing) strokePath(ctx, drawing.s, c.width, c.height);
    ctx.globalCompositeOperation = 'source-over';
  };
  const size = () => {
    const dpr = Math.min(2, devicePixelRatio || 1);
    const w = Math.round(c.clientWidth * dpr), h = Math.round(c.clientHeight * dpr);
    if (w && (c.width !== w || c.height !== h)) { c.width = w; c.height = h; }
    paint();
  };
  const at = e => { const r = c.getBoundingClientRect(); return [Math.round((e.clientX - r.left) / r.width * 1e4), Math.round((e.clientY - r.top) / r.height * 1e4)]; };
  // iPad Safari scrolls with Apple Pencil unless the touch itself is cancelled
  c.addEventListener('touchstart', e => {
    if ([...e.touches].some(t => t.touchType === 'stylus') || opts.canWrite('touch')) e.preventDefault();
  }, { passive: false });
  c.addEventListener('pointerdown', e => {
    if (drawing || !opts.canWrite(e.pointerType)) return;
    e.preventDefault(); c.setPointerCapture(e.pointerId);
    const p = opts.pen();
    drawing = { id: e.pointerId, s: { c: p.c, w: p.w, e: p.erase ? 1 : 0, p: at(e) } };
    paint();
  });
  c.addEventListener('pointermove', e => {
    if (!drawing || drawing.id !== e.pointerId) return;
    for (const ev of (e.getCoalescedEvents ? e.getCoalescedEvents() : [e])) {
      const [x, y] = at(ev), p = drawing.s.p;
      if (Math.abs(x - p[p.length - 2]) + Math.abs(y - p[p.length - 1]) >= 10) p.push(x, y);
    }
    paint();
  });
  const end = e => {
    if (!drawing || drawing.id !== e.pointerId) return;
    opts.strokes.push(drawing.s); drawing = null; paint(); opts.onStroke(opts.strokes);
  };
  c.addEventListener('pointerup', end);
  c.addEventListener('pointercancel', end);
  return { size, paint, setStrokes(s) { opts.strokes = s; paint(); }, get strokes() { return opts.strokes; } };
}
