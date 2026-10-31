// Step 1 — collect every driving theory text into tools/private/theory_all.json
//   free questions + sign names from the game page, paid questions from tools/private/theory_pro.json
// Run again any time: existing English/Norwegian/Google/status are kept, new texts are added.
//   node tools/theory/extract.js
const fs = require('fs');
const L = require('./lib');

const html = fs.readFileSync(L.GAME, 'utf8');
const free = L.readFree(html);
const paid = JSON.parse(fs.readFileSync(L.PAID, 'utf8'));
const signs = L.readSigns(html);

const old = new Map(L.load().map(e => [e.id, e]));
const items = [];
const add = (id, src, ti, extra = {}) => {
  const prev = old.get(id);
  // a reviewed text stays as reviewed; otherwise the current game text is the Tigrinya
  items.push(Object.assign({ id, src, ti, en: '', no: '', ti_google: '', status: 'machine' }, prev || {}, extra,
    prev && prev.status === 'reviewed' ? {} : { ti }));
};
const addQ = (prefix, list, src) => list.forEach(([q, o, c, ex], i) => {
  const n = `${prefix}${String(i + 1).padStart(3, '0')}`;
  add(`${n}.q`, src, q, { correct: c });
  o.forEach((opt, k) => add(`${n}.o${k}`, src, typeof opt === 'string' ? opt : JSON.stringify(opt)));
  add(`${n}.ex`, src, ex || '');
});
addQ('f', free, 'free');
addQ('p', paid, 'paid');
signs.forEach(s => add(`s.${s.code}`, 'sign', s.name));

L.save(items);
const chars = items.reduce((n, e) => n + (e.ti || '').length, 0);
console.log(`✅ ${items.length} texts (${free.length} free questions, ${paid.length} paid, ${signs.length} signs) → tools/private/theory_all.json`);
console.log(`   ${chars} Tigrinya characters · reviewed: ${items.filter(e => e.status === 'reviewed').length}`);
