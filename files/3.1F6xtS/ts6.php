<?php
// ts6 — compact 14<->6 timestamp codec (PHP, procedural). require this file.
// ts6 version: 3.1F6xtS
// MIT licensed. (C) 2026 smisco / info@smisco.biz . No warranty.
// Pure string transform: no timezone, no calendar validation (SPEC).
const TS6_ALPHABET = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
const TS6_EPOCH = 2025;

function ts6__digits($s) { return $s !== '' && ctype_digit($s); } // ASCII digits only

function ts6__b62($n) {
    if ($n === 0) return '0';
    $out = '';
    while ($n > 0) { $out = TS6_ALPHABET[$n % 62] . $out; $n = intdiv($n, 62); }
    return $out;
}

function ts6__index($c) {
    $p = strpos(TS6_ALPHABET, $c);
    return $p === false ? -1 : $p;
}

function ts6_encode($s) {
    if (strlen($s) !== 14) return '-';
    $y  = substr($s, 0, 4);  $mo = substr($s, 4, 2);  $d  = substr($s, 6, 2);
    $h  = substr($s, 8, 2);  $mi = substr($s, 10, 2); $se = substr($s, 12, 2);
    $out  = (ts6__digits($y)  && (int)$y  >= TS6_EPOCH)             ? ts6__b62((int)$y - TS6_EPOCH) : '-';
    $out .= (ts6__digits($mo) && (int)$mo >= 1 && (int)$mo <= 12)   ? TS6_ALPHABET[(int)$mo + 9]    : '-';
    $out .= (ts6__digits($d)  && (int)$d  >= 1 && (int)$d  <= 31)   ? TS6_ALPHABET[(int)$d]         : '-';
    $out .= (ts6__digits($h)  && (int)$h  >= 0 && (int)$h  <= 23)   ? TS6_ALPHABET[(int)$h + 36]    : '-';
    $out .= (ts6__digits($mi) && (int)$mi >= 0 && (int)$mi <= 59)   ? TS6_ALPHABET[(int)$mi]        : '-';
    $out .= (ts6__digits($se) && (int)$se >= 0 && (int)$se <= 59)   ? TS6_ALPHABET[(int)$se]        : '-';
    return $out;
}

function ts6_decode($s) {
    $W = strlen($s) - 5;
    if ($W < 1) return '-';
    $yf = substr($s, 0, $W);
    $rest = substr($s, $W);
    $ok = true;
    for ($i = 0; $i < $W; $i++) { if (ts6__index($yf[$i]) < 0) { $ok = false; break; } }
    if ($ok) {
        $val = 0;
        for ($i = 0; $i < $W; $i++) { $val = $val * 62 + ts6__index($yf[$i]); }
        $out = sprintf('%04d', $val + TS6_EPOCH);
    } else { $out = '-'; }
    $mo = ts6__index($rest[0]); $out .= ($mo >= 10 && $mo <= 21) ? sprintf('%02d', $mo - 9)  : '-';
    $da = ts6__index($rest[1]); $out .= ($da >= 1  && $da <= 31) ? sprintf('%02d', $da)       : '-';
    $ho = ts6__index($rest[2]); $out .= ($ho >= 36 && $ho <= 59) ? sprintf('%02d', $ho - 36) : '-';
    $mn = ts6__index($rest[3]); $out .= ($mn >= 0  && $mn <= 59) ? sprintf('%02d', $mn)       : '-';
    $sc = ts6__index($rest[4]); $out .= ($sc >= 0  && $sc <= 59) ? sprintf('%02d', $sc)       : '-';
    return $out;
}
