// Step 4 — read the corrected review file back
//   node tools/theory/import_review.js [path/to/theory_review.csv]
// A row is marked "reviewed" when its status column says reviewed (or ok / ✓),
// or when tigrinja_corrected is filled in. Corrected English/Norwegian are kept too.
const fs = require('fs');
const path = require('path');
const L = require('./lib');

const file = process.argv[2] || path.join(L.PRIVATE, 'theory_review.csv');
const rows = L.parseCsv(fs.readFileSync(file, 'utf8'));
const head = rows.shift().map(h => h.trim().toLowerCase());
const col = n => head.indexOf(n);
for (const need of ['id', 'tigrinya', 'tigrinya_corrected', 'status']) {
  if (col(need) < 0) { console.log(`Column "${need}" is missing in ${file}`); process.exit(1); }
}
const items = L.load();
const by = new Map(items.map(e => [e.id, e]));
let changed = 0, reviewed = 0, unknown = 0;
for (const r of rows) {
  const e = by.get((r[col('id')] || '').trim());
  if (!e) { unknown++; continue; }
  const fixed = (r[col('tigrinya_corrected')] || '').trim();
  const ok = /^(reviewed|ok|✓|yes|ja)$/i.test((r[col('status')] || '').trim());
  if (col('english') >= 0 && r[col('english')]?.trim()) e.en = r[col('english')].trim();
  if (col('norwegian') >= 0 && r[col('norwegian')]?.trim()) e.no = r[col('norwegian')].trim();
  if (fixed && fixed !== e.ti) { e.ti = fixed; changed++; }
  if (fixed || ok) { if (e.status !== 'reviewed') reviewed++; e.status = 'reviewed'; }
}
L.save(items);
console.log(`✅ ${changed} Tigrinya texts corrected · ${reviewed} newly marked reviewed · ${unknown} unknown ids`);
console.log(`   Total reviewed: ${items.filter(e => e.status === 'reviewed').length} of ${items.length}. Next: node tools/theory/publish.js`);
