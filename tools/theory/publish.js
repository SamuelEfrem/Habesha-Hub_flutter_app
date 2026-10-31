// Step 5 — put the stored texts back where the game reads them (no live translation anywhere)
//   free questions + sign names → public/games/life-tools/index.html
//   paid questions              → tools/private/theory_pro.json  (then: node tools/upload_theory.js)
// The game shows "ti"; if a Tigrinya text is empty it shows English instead.
// Backups: tools/private/life-tools-index.html.bak and tools/private/theory_pro.json.bak
//   node tools/theory/publish.js
const fs = require('fs');
const L = require('./lib');

const items = L.load();
if (!items.length) { console.log('Run node tools/theory/extract.js first.'); process.exit(1); }
const by = new Map(items.map(e => [e.id, e]));

// keep the sign-picture answers as they were (they are JSON, not text)
const opt = s => (/^\s*[\[{]/.test(s) ? JSON.parse(s) : s);
const fix = list => list.map(([q, o, c, ex]) => [q, o.map(opt), c, ex]);

// free questions + sign names in the game page
let html = fs.readFileSync(L.GAME, 'utf8');
fs.writeFileSync(require('path').join(L.PRIVATE, 'life-tools-index.html.bak'), html);  // not in public/ (would be published)
const free = fix(L.questions(items, 'f'));
const { start, end } = L.freeBlock(html);
html = html.slice(0, start) + '[\n' + free.map(q => JSON.stringify(q)).join(',\n') + '\n]' + html.slice(end);
let signs = 0;
html = html.split('\n').map(l => {
  const m = L.SIGN_LINE.exec(l);
  if (!m) return l;
  const e = by.get('s.' + m[2]);
  const name = L.shown(e).replace(/"/g, '\\"');
  if (!e || !name) return l;
  signs++;
  return m[1] + name + m[4];
}).join('\n');
fs.writeFileSync(L.GAME, html);

// paid questions
const paid = fix(L.questions(items, 'p'));
if (fs.existsSync(L.PAID)) fs.copyFileSync(L.PAID, L.PAID + '.bak');
fs.writeFileSync(L.PAID, JSON.stringify(paid, null, 1));

const rev = items.filter(e => e.status === 'reviewed').length;
console.log(`✅ ${free.length} free questions and ${signs} sign names → game page · ${paid.length} paid questions → tools/private/theory_pro.json`);
console.log(`   ${rev} of ${items.length} texts reviewed. Next: node tools/upload_theory.js  and  firebase deploy --only hosting`);
