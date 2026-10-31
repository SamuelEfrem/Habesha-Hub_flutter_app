// Step 3 — a review file for a native Tigrinya speaker (opens in Excel / Google Sheets)
//   node tools/theory/export_review.js            → tools/private/theory_review.csv
//   node tools/theory/export_review.js --todo     only texts that are not reviewed yet
// The reviewer writes the right Tigrinya in "tigrinya_corrected" (or leaves it empty when
// "tigrinya" is already right) and writes "reviewed" in "status" for every row they checked.
const fs = require('fs');
const path = require('path');
const L = require('./lib');

const onlyTodo = process.argv.includes('--todo');
const items = L.load().filter(e => !onlyTodo || e.status !== 'reviewed');
const out = path.join(L.PRIVATE, 'theory_review.csv');
const head = ['id', 'norwegian', 'english', 'tigrinya', 'tigrinya_google_suggestion', 'tigrinya_corrected', 'status'];
const lines = [L.csvLine(head)];
for (const e of items) {
  if (/^\s*[\[{]/.test(e.ti)) continue;  // sign pictures used as answers: nothing to read
  lines.push(L.csvLine([e.id, e.no, e.en, e.ti, e.ti_google, '', e.status]));
}
fs.writeFileSync(out, '﻿' + lines.join('\r\n'));
console.log(`✅ ${lines.length - 1} rows → ${path.relative(L.ROOT, out)}`);
