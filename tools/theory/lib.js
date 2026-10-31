// Shared helpers for the driving theory translation tools.
//
// All theory texts live in ONE file: tools/private/theory_all.json (not in git).
// Each text is a flat entry:
//   { id, src, ti, en, no, ti_google, status }
//   id        "f003.q", "f003.o1", "f003.ex"  free question 3 (question, option 1, explanation)
//             "p120.q" …                         paid question 120
//             "s.curveR"                         name of a traffic sign
//   ti        the Tigrinya text the app shows
//   en, no    English / Norwegian meaning (for the reviewer and as fallback)
//   ti_google Google's Tigrinya suggestion (never shown in the app)
//   status    "machine" (not checked yet) or "reviewed" (checked by a Tigrinya speaker)
const fs = require('fs');
const path = require('path');

const ROOT = path.join(__dirname, '..', '..');
const PRIVATE = path.join(ROOT, 'tools', 'private');
const DATA = path.join(PRIVATE, 'theory_all.json');
const PAID = path.join(PRIVATE, 'theory_pro.json');
const GAME = path.join(ROOT, 'public', 'games', 'life-tools', 'index.html');
const GLOSSARY = path.join(ROOT, 'tools', 'tigrinja_glossary.json');

// ── the game page: free questions (const Q=[…]) and sign names (const SIGNS=[…]) ──
function freeBlock(html) {
  const a = html.indexOf('const Q=[');
  const b = html.indexOf('\n];', a);
  if (a < 0 || b < 0) throw new Error('const Q=[ … ] not found in the game page');
  return { start: a + 'const Q='.length, end: b + 2 };   // the [ … ] part
}
function readFree(html) {
  const { start, end } = freeBlock(html);
  return JSON.parse(html.slice(start, end));
}
const SIGN_LINE = /^( \["(\w+)","\w+",.*,")([^"]*)(","\w+"\],?\s*)$/;
function readSigns(html) {
  const out = [];
  for (const l of html.split('\n')) {
    const m = SIGN_LINE.exec(l);
    if (m) out.push({ code: m[2], name: m[3] });
  }
  return out;
}

// ── data file ──
function load() {
  if (!fs.existsSync(DATA)) return [];
  return JSON.parse(fs.readFileSync(DATA, 'utf8'));
}
function save(items) {
  fs.mkdirSync(PRIVATE, { recursive: true });
  if (fs.existsSync(DATA)) fs.copyFileSync(DATA, DATA + '.bak');
  fs.writeFileSync(DATA, JSON.stringify(items, null, 1));
}

// question entries → [question, [options], correct, explanation] (with fallback ti → en)
function shown(e) { return (e && (e.ti || e.en || e.no)) || ''; }
function questions(items, prefix) {
  const by = new Map(items.map(e => [e.id, e]));
  const nums = [...new Set(items.filter(e => e.id.startsWith(prefix)).map(e => e.id.split('.')[0]))];
  return nums.map(n => {
    const meta = by.get(n + '.q');
    const opts = [0, 1, 2, 3].map(i => by.get(`${n}.o${i}`)).filter(Boolean).map(shown);
    return [shown(meta), opts, meta.correct, shown(by.get(n + '.ex'))];
  });
}

// ── glossary: fixed traffic terms ──
function glossary() {
  if (!fs.existsSync(GLOSSARY)) return [];
  const g = JSON.parse(fs.readFileSync(GLOSSARY, 'utf8'));
  return Object.entries(g).map(([no, v]) => ({ no, en: (v && v.en) || '', ti: (v && v.ti) || '' }));
}

// ── CSV (Excel friendly: UTF-8 with BOM, ; or , separated, quotes) ──
function csvLine(cells) {
  return cells.map(c => `"${String(c ?? '').replace(/"/g, '""')}"`).join(',');
}
function parseCsv(text) {
  text = text.replace(/^﻿/, '');
  const sep = (text.split('\n')[0].match(/;/g) || []).length > (text.split('\n')[0].match(/,/g) || []).length ? ';' : ',';
  const rows = []; let row = [], cell = '', q = false;
  for (let i = 0; i < text.length; i++) {
    const ch = text[i];
    if (q) {
      if (ch === '"' && text[i + 1] === '"') { cell += '"'; i++; }
      else if (ch === '"') q = false;
      else cell += ch;
    } else if (ch === '"') q = true;
    else if (ch === sep) { row.push(cell); cell = ''; }
    else if (ch === '\n' || ch === '\r') {
      if (ch === '\r' && text[i + 1] === '\n') i++;
      row.push(cell); rows.push(row); row = []; cell = '';
    } else cell += ch;
  }
  if (cell || row.length) { row.push(cell); rows.push(row); }
  return rows.filter(r => r.some(c => c.trim()));
}

module.exports = { ROOT, PRIVATE, DATA, PAID, GAME, GLOSSARY, freeBlock, readFree, readSigns, SIGN_LINE, load, save, questions, glossary, csvLine, parseCsv, shown };
