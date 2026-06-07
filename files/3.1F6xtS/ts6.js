// ts6 — compact 14<->6 timestamp codec (JavaScript, ESM + browser).
// ts6 version: 3.1F6xtS
// MIT licensed. (C) 2026 smisco / info@smisco.biz . No warranty.
// Pure string transform: no timezone, no calendar validation (SPEC).
// Browser: load with <script type="module"> — sets globalThis.ts6.
const ALPHABET = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
const EPOCH = 2025;
const _digits = (s) => s.length > 0 && /^[0-9]+$/.test(s); // ASCII digits only
const _idx = (c) => (ALPHABET.includes(c) ? ALPHABET.indexOf(c) : -1);
const _pad = (n, w) => { let s = String(n); while (s.length < w) s = "0" + s; return s; };
const _b62 = (n) => {
  if (n === 0) return "0";
  let o = "";
  while (n > 0) { o = ALPHABET[n % 62] + o; n = Math.floor(n / 62); }
  return o;
};

function encode(s) {
  if (s.length !== 14) return "-";
  const y = s.slice(0, 4), mo = s.slice(4, 6), d = s.slice(6, 8),
        h = s.slice(8, 10), mi = s.slice(10, 12), se = s.slice(12, 14);
  let o = "";
  o += (_digits(y)  && +y  >= EPOCH)              ? _b62(+y - EPOCH)    : "-";
  o += (_digits(mo) && +mo >= 1  && +mo <= 12)    ? ALPHABET[+mo + 9]   : "-";
  o += (_digits(d)  && +d  >= 1  && +d  <= 31)    ? ALPHABET[+d]        : "-";
  o += (_digits(h)  && +h  >= 0  && +h  <= 23)    ? ALPHABET[+h + 36]   : "-";
  o += (_digits(mi) && +mi >= 0  && +mi <= 59)    ? ALPHABET[+mi]       : "-";
  o += (_digits(se) && +se >= 0  && +se <= 59)    ? ALPHABET[+se]       : "-";
  return o;
}

function decode(s) {
  const W = s.length - 5;
  if (W < 1) return "-";
  const yf = s.slice(0, W), rest = s.slice(W);
  let o = "";
  if ([...yf].every((c) => ALPHABET.includes(c))) {
    let val = 0;
    for (const c of yf) val = val * 62 + ALPHABET.indexOf(c);
    o += _pad(val + EPOCH, 4);
  } else { o += "-"; }
  const mo = _idx(rest[0]); o += (mo >= 10 && mo <= 21) ? _pad(mo - 9, 2)  : "-";
  const da = _idx(rest[1]); o += (da >= 1  && da <= 31) ? _pad(da, 2)       : "-";
  const ho = _idx(rest[2]); o += (ho >= 36 && ho <= 59) ? _pad(ho - 36, 2) : "-";
  const mn = _idx(rest[3]); o += (mn >= 0  && mn <= 59) ? _pad(mn, 2)       : "-";
  const sc = _idx(rest[4]); o += (sc >= 0  && sc <= 59) ? _pad(sc, 2)       : "-";
  return o;
}

const ts6 = { encode, decode };
if (typeof globalThis !== "undefined") globalThis.ts6 = ts6;
export default ts6;
export { encode, decode };
