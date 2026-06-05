"""ts6 — compact 14<->6 timestamp codec (Python). import ts6; ts6.encode/decode.
ts6 version: 2.1F4uWV
MIT licensed. (C) 2026 smisco / info@smisco.biz . No warranty.
Pure string transform: no timezone, no calendar validation (SPEC)."""

ALPHABET = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
EPOCH = 2025

def _digits(s):
    # ASCII digits only — avoids str.isdigit() accepting Unicode digit forms.
    return len(s) > 0 and all("0" <= c <= "9" for c in s)

def _b62(n):
    if n == 0:
        return "0"
    out = ""
    while n > 0:
        out = ALPHABET[n % 62] + out
        n //= 62
    return out

def _idx(c):
    return ALPHABET.index(c) if c in ALPHABET else -1

def encode(s):
    if len(s) != 14:
        return "-"
    y, mo, d, h, mi, se = s[0:4], s[4:6], s[6:8], s[8:10], s[10:12], s[12:14]
    out = []
    out.append(_b62(int(y) - EPOCH) if _digits(y) and int(y) >= EPOCH else "-")
    out.append(ALPHABET[int(mo) + 9] if _digits(mo) and 1 <= int(mo) <= 12 else "-")
    out.append(ALPHABET[int(d)]      if _digits(d)  and 1 <= int(d)  <= 31 else "-")
    out.append(ALPHABET[int(h) + 36] if _digits(h)  and 0 <= int(h)  <= 23 else "-")
    out.append(ALPHABET[int(mi)]     if _digits(mi) and 0 <= int(mi) <= 59 else "-")
    out.append(ALPHABET[int(se)]     if _digits(se) and 0 <= int(se) <= 59 else "-")
    return "".join(out)

def decode(s):
    W = len(s) - 5
    if W < 1:
        return "-"
    yf, rest = s[0:W], s[W:]
    out = []
    if all(c in ALPHABET for c in yf):
        val = 0
        for c in yf:
            val = val * 62 + ALPHABET.index(c)
        out.append("%04d" % (val + EPOCH))
    else:
        out.append("-")
    mo = _idx(rest[0]); out.append("%02d" % (mo - 9)  if 10 <= mo <= 21 else "-")
    da = _idx(rest[1]); out.append("%02d" % da         if 1  <= da <= 31 else "-")
    ho = _idx(rest[2]); out.append("%02d" % (ho - 36) if 36 <= ho <= 59 else "-")
    mn = _idx(rest[3]); out.append("%02d" % mn         if 0  <= mn <= 59 else "-")
    sc = _idx(rest[4]); out.append("%02d" % sc         if 0  <= sc <= 59 else "-")
    return "".join(out)
