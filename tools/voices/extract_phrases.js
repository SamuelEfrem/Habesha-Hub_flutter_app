// Lists every phrase in Life Tools (topic_index → Tigrinya, Amharic) for voice generation / recording.
//   node tools/voices/extract_phrases.js  → tools/voices/phrases.json
const fs = require('fs'), path = require('path');
const html = fs.readFileSync(path.join(__dirname, '../../public/games/life-tools/index.html'), 'utf8');
const a = html.indexOf('const PTOPICS=['), b = html.indexOf('\n];', a);
const PTOPICS = new Function('return ' + html.slice(a + 'const PTOPICS='.length, b + 2))();
const out = [];
for (const t of PTOPICS) {
  t.rows.trim().split('\n').forEach((row, i) => {
    const c = row.split('|');
    out.push({ id: `${t.k}_${i}`, topic: t.k, ti: (c[0] || '').trim(), am: (c[1] || '').trim(), en: (c[5] || '').trim(), no: (c[2] || '').trim() });
  });
}
fs.writeFileSync(path.join(__dirname, 'phrases.json'), JSON.stringify(out, null, 1));
console.log(out.length, 'phrases in', PTOPICS.length, 'topics:', PTOPICS.map(t => t.k).join(', '));
