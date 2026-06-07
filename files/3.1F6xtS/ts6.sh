# ts6 — compact 14<->6 timestamp codec (bash). source this file.
# ts6 version: 3.1F6xtS
# MIT licensed. (C) 2026 smisco / info@smisco.biz . No warranty.
# Pure string transform: no timezone, no calendar validation (SPEC).
# Sourceable under strict mode (set -euo pipefail). Defines functions only.
ts6_ALPHABET='0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'
ts6_EPOCH=2025

# index of a single char in the alphabet, or -1 (echoes the result)
ts6__index() {
  local c="$1" pre
  pre="${ts6_ALPHABET%%"$c"*}"
  if [[ "$pre" == "$ts6_ALPHABET" ]]; then printf '%s' -1; else printf '%s' "${#pre}"; fi
}

# base62 of a non-negative integer (echoes; minimal digits, "0" for 0)
ts6__b62() {
  local n="$1" out=''
  if (( n == 0 )); then printf '0'; return; fi
  while (( n > 0 )); do out="${ts6_ALPHABET:n%62:1}${out}"; n=$(( n / 62 )); done
  printf '%s' "$out"
}

ts6_encode() {
  local s="$1"
  if (( ${#s} != 14 )); then printf '%s' '-'; return; fi
  local y="${s:0:4}" mo="${s:4:2}" d="${s:6:2}" h="${s:8:2}" mi="${s:10:2}" se="${s:12:2}"
  local out='' v
  if [[ "$y"  =~ ^[0-9]{4}$ ]] && (( (v=10#$y)  >= 2025 ));            then out+="$(ts6__b62 $(( v - ts6_EPOCH )))"; else out+='-'; fi
  if [[ "$mo" =~ ^[0-9]{2}$ ]] && (( (v=10#$mo) >= 1 && v <= 12 ));    then out+="${ts6_ALPHABET:v+9:1}";  else out+='-'; fi
  if [[ "$d"  =~ ^[0-9]{2}$ ]] && (( (v=10#$d)  >= 1 && v <= 31 ));    then out+="${ts6_ALPHABET:v:1}";    else out+='-'; fi
  if [[ "$h"  =~ ^[0-9]{2}$ ]] && (( (v=10#$h)  >= 0 && v <= 23 ));    then out+="${ts6_ALPHABET:v+36:1}"; else out+='-'; fi
  if [[ "$mi" =~ ^[0-9]{2}$ ]] && (( (v=10#$mi) >= 0 && v <= 59 ));    then out+="${ts6_ALPHABET:v:1}";    else out+='-'; fi
  if [[ "$se" =~ ^[0-9]{2}$ ]] && (( (v=10#$se) >= 0 && v <= 59 ));    then out+="${ts6_ALPHABET:v:1}";    else out+='-'; fi
  printf '%s' "$out"
}

ts6_decode() {
  local s="$1"
  local L=${#s} W
  W=$(( L - 5 ))
  if (( W < 1 )); then printf '%s' '-'; return; fi
  local yf="${s:0:W}" rest="${s:W}" out='' i c idx val bad=0 t
  val=0
  for (( i=0; i<W; i++ )); do
    c="${yf:i:1}"; idx="$(ts6__index "$c")"
    if (( idx < 0 )); then bad=1; break; fi
    val=$(( val * 62 + idx ))
  done
  if (( bad )); then out+='-'; else printf -v t '%04d' $(( val + ts6_EPOCH )); out+="$t"; fi
  c="${rest:0:1}"; idx="$(ts6__index "$c")"; if (( idx >= 10 && idx <= 21 )); then printf -v t '%02d' $(( idx - 9 ));  out+="$t"; else out+='-'; fi
  c="${rest:1:1}"; idx="$(ts6__index "$c")"; if (( idx >= 1  && idx <= 31 )); then printf -v t '%02d' "$idx";          out+="$t"; else out+='-'; fi
  c="${rest:2:1}"; idx="$(ts6__index "$c")"; if (( idx >= 36 && idx <= 59 )); then printf -v t '%02d' $(( idx - 36 )); out+="$t"; else out+='-'; fi
  c="${rest:3:1}"; idx="$(ts6__index "$c")"; if (( idx >= 0  && idx <= 59 )); then printf -v t '%02d' "$idx";          out+="$t"; else out+='-'; fi
  c="${rest:4:1}"; idx="$(ts6__index "$c")"; if (( idx >= 0  && idx <= 59 )); then printf -v t '%02d' "$idx";          out+="$t"; else out+='-'; fi
  printf '%s' "$out"
}
