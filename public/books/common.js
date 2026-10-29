// Habesha Books — shared Firebase setup, login by email link, language, helpers
import { initializeApp } from 'https://www.gstatic.com/firebasejs/10.14.1/firebase-app.js';
import {
  getAuth, onAuthStateChanged, sendSignInLinkToEmail, isSignInWithEmailLink,
  signInWithEmailLink, signOut
} from 'https://www.gstatic.com/firebasejs/10.14.1/firebase-auth.js';
import { getFirestore } from 'https://www.gstatic.com/firebasejs/10.14.1/firebase-firestore.js';
import { getStorage } from 'https://www.gstatic.com/firebasejs/10.14.1/firebase-storage.js';

// Public web config (the same one the Flutter web build uses — not a secret)
export const app = initializeApp({
  apiKey: 'AIzaSyD_YioC4U8gGYv4fPVG5_FHCEdRXgJ7SnI',
  authDomain: 'habesha-hub-7bd1d.firebaseapp.com',
  projectId: 'habesha-hub-7bd1d',
  storageBucket: 'habesha-hub-7bd1d.firebasestorage.app',
  messagingSenderId: '308436707340',
  appId: '1:308436707340:web:757a5a02ec6f1ea09ae629'
});
export const auth = getAuth(app);
export const db = getFirestore(app);
export const storage = getStorage(app);

const ADMIN_UID = 'W3z67R3wiXUVvcPFDS0oxgfaDlj1';
const ADMIN_EMAIL = 'samuelefriem@gmail.com';
export const isAdmin = u => !!u && (u.uid === ADMIN_UID || (u.email === ADMIN_EMAIL && u.emailVerified));
export const emailOf = u => (u && u.email ? u.email.toLowerCase() : '');
export const isVerified = u => !!u && !!u.email && u.emailVerified;

// ── tiny storage wrapper (may be blocked in private mode) ──
export const ls = {
  get(k) { try { return localStorage.getItem(k); } catch (e) { return null; } },
  set(k, v) { try { localStorage.setItem(k, v); } catch (e) {} },
  del(k) { try { localStorage.removeItem(k); } catch (e) {} }
};

// ── login with email link (passwordless; proves the email is real) ──
const LS_EMAIL = 'hh_books_email';
export async function sendLoginLink(email) {
  await sendSignInLinkToEmail(auth, email.trim(), {
    url: location.origin + location.pathname,
    handleCodeInApp: true
  });
  ls.set(LS_EMAIL, email.trim());
}
/** If the page was opened from the email link, finish login. askEmail() must return a Promise<string>. */
export async function finishLoginFromLink(askEmail) {
  if (!isSignInWithEmailLink(auth, location.href)) return false;
  let email = ls.get(LS_EMAIL);
  if (!email) email = await askEmail();
  await signInWithEmailLink(auth, email.trim(), location.href);
  ls.del(LS_EMAIL);
  history.replaceState(null, '', location.pathname);
  return true;
}
export const onUser = cb => onAuthStateChanged(auth, cb);
export const logout = () => signOut(auth);

// ── language ──
export const LANGS = ['en', 'ti', 'am'];
export function getLang() {
  const l = ls.get('hh_lang');
  return LANGS.includes(l) ? l : 'en';
}
export function setLang(l) { ls.set('hh_lang', l); document.documentElement.lang = l; }
export function makeT(dict) {
  return k => (dict[getLang()] && dict[getLang()][k]) || dict.en[k] || k;
}
/** Fill elements that have data-t="key" */
export function applyT(t, root = document) {
  root.querySelectorAll('[data-t]').forEach(el => { el.textContent = t(el.dataset.t); });
  root.querySelectorAll('[data-t-ph]').forEach(el => { el.placeholder = t(el.dataset.tPh); });
}
export function langSwitch(container, onChange) {
  const labels = { en: 'EN', ti: 'ትግ', am: 'አማ' };
  container.innerHTML = '';
  LANGS.forEach(l => {
    const b = document.createElement('button');
    b.type = 'button'; b.textContent = labels[l];
    b.setAttribute('aria-label', { en: 'English', ti: 'Tigrinya', am: 'Amharic' }[l]);
    b.className = l === getLang() ? 'on' : '';
    b.onclick = () => { setLang(l); langSwitch(container, onChange); onChange(); };
    container.appendChild(b);
  });
}

// ── helpers ──
export const esc = s => String(s ?? '').replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
export const pad = n => String(n).padStart(3, '0');
export const pagePath = (bookId, n) => `books/${bookId}/pages/${pad(n)}.jpg`;
export const audioPath = (bookId, n) => `books/${bookId}/audio/${pad(n)}`;
export function toast(msg, ms = 3200) {
  const d = document.createElement('div');
  d.className = 'toast'; d.setAttribute('role', 'status'); d.textContent = msg;
  document.body.appendChild(d);
  setTimeout(() => d.remove(), ms);
}
export const EMAIL_RE = /^[^\s@,;<>"']+@[^\s@,;<>"']+\.[a-z]{2,}$/i;

// ── interactive lesson books ──
export const keyAudioPath = (bookId, k) => `books/${bookId}/audio/k_${k}`;
export const keyImgPath = (bookId, k) => `books/${bookId}/img/${k}.jpg`;
export function newKey() {
  const abc = 'abcdefghijkmnpqrstuvwxyz23456789', r = crypto.getRandomValues(new Uint8Array(10));
  return [...r].map(v => abc[v % 32]).join('');
}
