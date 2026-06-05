# timestamp-six (ts6)

**A compact timestamp codec: 14 characters in, 6 characters out — identical in four languages.**

ts6 converts a `yyyymmddHHMMSS` timestamp (e.g. `20260603104200`) to a 6-character code
(`1F3kg0`) and back, losslessly. The short form exists mainly to **save screen space**
— it fits where a full timestamp won't, which matters most on mobile.

Beyond compactness, the codes are designed to be (in priority order):

1. **Compact** — 6 chars covers every timestamp from 2025 through 2086.
2. **Chronologically sortable** — plain string comparison sorts codes in time order.
3. **URL- and filename-safe** — output is `[A-Za-z0-9]` only (a `-` appears solely on error).
4. **Human-readable** — the month is always an uppercase letter `A`–`L`, the hour always a
   lowercase letter `a`–`x`, so your eye locates them at a glance.

ts6 is a **pure string transform**: no timezone math, no calendar validation, no
configuration. A 14-digit string goes in, a ts6 string comes out — and vice versa. What the
timestamp *means* (which zone, whether the date is real) is the caller's business.

## Quick taste

```
20260603104200   <->   1F3kg0
```

Reading `1F3kg0`: `1` = 2026, `F` = June, `3` = the 3rd, `k` = 10h, `g` = 42m, `0` = 00s.

```text
encode("20260603104200")  ->  "1F3kg0"
decode("1F3kg0")          ->  "20260603104200"
```

## Contents

- [Download](#download)
- [Usage](#usage)
- [The encoding](#the-encoding)
- [Range and the future](#range-and-the-future)
- [Error handling](#error-handling)
- [Versioning](#versioning)
- [Parity guarantee](#parity-guarantee)
- [License](#license)

## Download

Each implementation is a **single drop-in file with no dependencies**. Take only the
language(s) you need.

From the project site, [smisco.biz/ts6/](https://smisco.biz/ts6/):

| What | Link |
|---|---|
| Everything, zipped | [`ts6.zip`](https://smisco.biz/ts6/ts6.zip) |
| Everything, gzipped tarball | [`ts6.tgz`](https://smisco.biz/ts6/ts6.tgz) |
| PHP only | [`ts6.php`](https://smisco.biz/ts6/ts6.php) |
| Python only | [`ts6.py`](https://smisco.biz/ts6/ts6.py) |
| JavaScript only | [`ts6.js`](https://smisco.biz/ts6/ts6.js) |
| bash only | [`ts6.sh`](https://smisco.biz/ts6/ts6.sh) |

Source and issues live on GitHub: **[github.com/grimblefritz/timestamp-six](https://github.com/grimblefritz/timestamp-six)**.

```bash
git clone https://github.com/grimblefritz/timestamp-six.git
```

## Usage

Two functions per language, same verbs everywhere: **`encode`** (14 -> ts6) and
**`decode`** (ts6 -> 14). Procedural, no classes or namespaces.

### PHP — `require`

```php
require 'ts6.php';

echo ts6_encode('20260603104200');  // 1F3kg0
echo ts6_decode('1F3kg0');          // 20260603104200
```

### Python — `import`

```python
import ts6

ts6.encode('20260603104200')  # '1F3kg0'
ts6.decode('1F3kg0')          # '20260603104200'
```

### JavaScript — ESM or browser

```javascript
import ts6 from './ts6.js';            // default export
// or: import { encode, decode } from './ts6.js';

ts6.encode('20260603104200');  // '1F3kg0'
ts6.decode('1F3kg0');          // '20260603104200'
```

In the browser, loading the module also sets `globalThis.ts6`:

```html
<script type="module">
  import ts6 from './ts6.js';
  console.log(ts6.encode('20260603104200'));  // 1F3kg0
</script>
```

### bash — `source`

The functions **echo** the result (no trailing newline); capture with `$( )`. Requires bash
(strict-mode safe: `set -euo pipefail`).

```bash
source ts6.sh

code=$(ts6_encode 20260603104200)   # 1F3kg0
ts=$(ts6_decode 1F3kg0)             # 20260603104200
echo "$code -> $ts"
```

## The encoding

ts6 is a **per-component base62 codec**. The alphabet is 62 symbols in **ASCII order**, so a
naive string sort equals a chronological sort:

```
0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz
index 0......9  10....................35  36...................61
```

Each of the six timestamp components becomes **one base62 digit** via a fixed offset:

| Component | Source range | Offset | Encoded index | Renders as | Notes |
|---|---|---|---|---|---|
| **year** | `yyyy` | `year - 2025` | `0–61` (ts6) | `0-9A-Za-z` | epoch **2025**, so 2026 -> `1` (no leading zero) |
| **month** | `01–12` | `+9` | `10–21` | **`A–L`** | always uppercase (Jan = `A` ... Dec = `L`) |
| **day** | `01–31` | none | `1–31` | `1-9A-V` | raw base62 |
| **hour** | `00–23` | `+36` | `36–59` | **`a–x`** | always lowercase (00h = `a` ... 23h = `x`) |
| **minute** | `00–59` | none | `0–59` | `0-9A-Za-x` | raw base62 |
| **second** | `00–59` | none | `0–59` | `0-9A-Za-x` | raw base62 |

- **Encode**: slice the 14-char input into its six components, apply each offset, index into
  the alphabet, concatenate.
- **Decode**: the inverse — map each character to its alphabet index, remove the offset,
  zero-pad each component to its field width (year -> 4, the rest -> 2), concatenate to 14
  characters.

### Worked example

`2026-06-03 10:42:00` -> `20260603104200`:

| Field | Value | Offset -> index | Char |
|---|---|---|---|
| year | 2026 | 1 | `1` |
| month | 06 | 15 | `F` |
| day | 03 | 3 | `3` |
| hour | 10 | 46 | `k` |
| minute | 42 | 42 | `g` |
| second | 00 | 0 | `0` |

-> **`1F3kg0`**

Sort check: `10:43:00` -> `1F3kh0`, which sorts *after* `1F3kg0`. Correct.

### Why month is `A–L` and hour is `a–x`

It makes a code **self-documenting**. The month is always one of twelve uppercase letters and
the hour always one of twenty-four lowercase letters, so the eye finds them instantly.
Day/minute/second are raw base62 (digit, then upper, then lower as the value climbs). The
offsets that achieve this are trivial and cost nothing.

## Range and the future

**ts6 -> ts7 -> ... -> tsN.** A single year character covers **2025–2086**. When `year - 2025` exceeds 61, the **year field
grows by one base62 digit** — the trailing five characters (month/day/hour/minute/second)
never change — so the format quietly becomes ts7, ts8, and so on. Decoding infers the
year-field width as `length - 5`, so it handles any width without a flag.

| Form | Year digits | Total length | Max year offset | Upper year |
|---|---|---|---|---|
| **ts6** | 1 | 6 | 61 | **2086** |
| **ts7** | 2 | 7 | 3,843 | **5868** |
| **ts8** | 3 | 8 | 238,327 | **240,352** |
| **ts9** | 4 | 9 | 14,776,335 | **14,778,360** |
| **ts10** | 5 | 10 | 916,132,831 | **916,134,856** |

The punchline for posterity: **ts7 alone reaches the year 5868**, so the format sails past the
year 3026 without ever leaving ts7. By ts10 we are at roughly 916 million AD, at which point
the heat death of the sun is the more pressing item in the backlog. This format will not be
what fails you.

**Known limitation — cross-width sort.** Sorting is perfect *within* a single width (all-ts6,
or all-ts7). But because the year field is variable-width, a ts6 code and a ts7 code do not
sort correctly against each other (`z...` sorts after `10...`). Since ts7 only appears after
2086 — by definition someone else's problem — this is documented rather than papered over with
zero-padding, which would break both the no-leading-zero rule and the name "six."

## Error handling

A bad input does **not throw** and does **not silently lie**. It produces a deliberately
broken output that fails loudly downstream, with a `-` (dash) marking each offending position.

**Decode** (each character is one component):

- A character out of range for its position becomes a `-` in that position of the 14-char
  output. "Out of range" means it is not in the 62-symbol alphabet, **or** it decodes to a
  value invalid for that component (month outside `A–L`, day outside 1–31, hour outside
  `a–x`, minute/second value 60–61). Any alphabet character is valid for the year.
- One bad character produces one literal `-`, so the output length goes wrong. **That length
  error is intentional** — it forces a capture/correction instead of passing as a clean
  14-char string.

**Encode** (input is meant to be 14 digits):

- A component out of range (month not 01–12, day not 01–31, hour not 00–23, minute/second not
  00–59, year below 2025, or non-numeric) becomes a `-` in that component's position.
- **Wrong total length** (anything but 14) yields a single `-` for the whole output, because
  the fields cannot be located.

Examples:

```text
encode("20261303104200")  ->  "1-3kg0"          // month 13 out of range
encode("20240101000000")  ->  "-A1a00"          // year 2024 is below the 2025 epoch
encode("2026060310420")   ->  "-"               // 13 chars: wrong length

decode("1F3kg!")          ->  "202606031042-"   // '!' is not in the alphabet
decode("1M3kg0")          ->  "2026-03104200"   // 'M' would be month 13, outside A-L
decode("1F3kg")           ->  "-"               // 5 chars: too short to hold 6 components
```

The bundled parity vector table is the **authoritative definition** of edge-case behavior:
the rules above are the intent; the vectors are the contract.

## Versioning

A release version is `build.ts6` — for example **`7.1Gm4a2`** means the 7th build, released at
the moment `1Gm4a2` decodes to. Two parts:

- **`build`** — a single project-wide counter, bumped once per release.
- **`.ts6`** — `encode()` of the release timestamp (America/New_York). ts6 stamps its own
  releases. (Yes, it dogfoods.)

All four files in a release ship as a set under one identical version, stamped into each
script's header, the `ts6-{version}.txt` marker, and the archive filenames.

## Parity guarantee

The four implementations are not merely "the same idea in four languages" — they are
**byte-identical in both directions for every input**, errors included. They are kept honest
by a single shared vector table (`input -> expected`, with failure cases weighted at least as
heavily as success cases) that all four are tested against. Any change to the algorithm,
alphabet, offsets, or error behavior lands in all four at once or it is a bug. Pick whichever
language fits your stack; the codes are interchangeable.

## License

MIT. Free to use, no warranty.

timestamp-six (C) 2026 smisco / info@smisco.biz
