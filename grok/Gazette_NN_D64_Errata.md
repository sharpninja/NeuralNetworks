# Errata: `Gazette_NN_1990.d64` vs. printed type-ins

**Disk:** `/home/workdir/artifacts/Gazette_NN_1990.d64`  
**Print source:** Kevin E. Martin, “Future Computing: Neural Networks,” *COMPUTE!’s Gazette*  
Feb 1990 (Issue 80) pp. 37–39 and Mar 1990 (Issue 81) pp. 43–46.  
**Method:** Detokenized the four PRGs on the D64 and compared them to the printed Program listings on the magazine pages (not to the PDF’s OCR text layer, which is unusable for hex columns).

The BASIC and `CL.ML` files on the D64 started as the official Gazette Disk binaries, not re-typings of the magazine OCR. They are the right programs. Differences below are disk-vs-print, not “the D64 is corrupt.”

**Added 2026-09-16:** XOR, ENCODE, and DIPOLE now contain extra `REM` lines documenting the SYS interface and the training sets. Original executable lines are byte-identical to the Gazette Disk versions. The new REMs are not in the printed type-ins.

---

## Disk directory

| File    | Blocks | Load   | On disk? | Printed as        | Verdict |
|---------|--------|--------|----------|-------------------|---------|
| XOR     | 6      | $0801  | yes      | Program 2, Feb 39 | Match + added REMs |
| ENCODE  | 7      | $0801  | yes      | Program 3, Feb 39 | Match + added REMs |
| DIPOLE  | 10     | $0801  | yes      | Dipole, Mar 45–46 | Match + added REMs |
| CL.ML   | 10     | $C000  | yes      | Program 1, Mar    | Match with notes |
| BP.ML   | 17     | $C000  | yes      | Program 1, Feb 37–39 | Match (user-supplied Alt binary) |

`BP.ML` is required by XOR and ENCODE (`LOAD"BP.ML",8,1`). It is on this D64 as of 2026-09-16: the 4097-byte Alt / Gaz-Type file the user supplied (`BP.ML.prg`). Round-trip extract matches that PRG. PEEKs 24 / 196 and first bytes `4C 18 C0 4C 4D C4` match the print.

---

## Cosmetic difference in all three BASIC programs

Printed line 20 (XOR, ENCODE, and Dipole — same line on the page):

```basic
20 PRINT"{CLR}{5}{N}":POKE53280,0:POKE53281,11
```

D64 tokenized bytes inside the string: `$93 $98 $0E`.

| Printed | Meaning | CHR$ | D64 byte | D64 meaning |
|---------|---------|------|----------|-------------|
| `{CLR}` | clear screen | 147 | $93 | same |
| `{5}`   | white       | 5   | **$98** | **gray 2** (CHR$(152)) |
| `{N}`   | lowercase charset | 14 | $0E | same |

Border/background POKEs match the print (`53280,0` / `53281,11`). Only the text color differs. The programs run the same; the title text is medium-gray on the disk versions instead of white.

Gazette `{5}` is white (see “How to Type In COMPUTE!’s Gazette Programs” in the same issues). This looks like a disk-production substitution, not a later corruption of the D64.

---

## XOR (Feb 1990, p. 39) — Program 2

Logic, SYS addresses, training pairs, and PEEK gate match the print.

```
30 IF PEEK(49153)<>24 OR PEEK(49157)<>196 THEN LOAD"BP.ML",8,1
50 SYS 49152,2,2,1,4,0.25,0.9,0.02
60–90 training pairs: 00→0, 10→1, 01→1, 11→0
```

Other print-vs-disk items that are **not** errors:

- Line 10 copyright REM is present on both (print wraps it with `{SPACE}` before `ALL`; the PRG is one REM line).
- Underlined capitals in the print (`LEARNING`, `PATTERNS`, `THE`, `TIME`, `RESULTS`) are SHIFT-letter PETSCII. The PRG stores them as high-bit letters (`$CC`/`$D0`/…). Same program.
- Print uses `SYS 49152` on some lines and `SYS49155` (no space) on others. The PRG follows that.
- Proofreader codes (`HR`, `GP`, `OQ`, …) exist only in the magazine. They are not stored in a PRG.

No other line-content mismatch found.

---

## ENCODE (Feb 1990, p. 39) — Program 3

Same line-20 color note. Everything else matches the print:

```
30 PEEK gate and LOAD"BP.ML",8,1   same as XOR
40 X=RND(-11111)
50 SYS 49152,4,2,4,4,0.25,0.9,0.02
60–90 pairs: 1000→0010, 0100→0001, 0010→1000, 0001→0100
```

Header spacing (`{3 SPACES}LAYER` / `{4 SPACES}ONE` / `{8 SPACES}TWO{8 SPACES}THREE`) matches the detokenized PRG. Seed on disk is `-11111`, not the OCR-garbled `-mil` / `-1111`.

---

## DIPOLE (Mar 1990, pp. 45–46)

Same line-20 color note. PEEK gate and filename match the print:

```
30 IF PEEK(49153)<>24 OR PEEK(49157)<>194 THEN LOAD"CL.ML",8,1
40 X=RND(-33333)
60 SYS 49152,16,2,24,0.1
```

All 24 dipole patterns on the D64 match the printed strings (adjacent horizontal pairs on lines 80–190, adjacent vertical pairs on lines 200–310). Control codes `{CLR}` (line 320) and `{HOME}` (line 360) match (`$93`, `$13`). Learning loop is `FOR I=1 TO 400` with `SYS 49164,1`. Weight print-scaling is `INT(W1(n,J)*1000000)` as printed.

No other BASIC mismatch found.

---

## CL.ML (Mar 1990 MLX)

Print: start `C000`, end `C98F`. Save name `CL.ML`.

| Check | Print / article | D64 `CL.ML` |
|-------|-----------------|-------------|
| Load address | `$C000` | `$C000` |
| First bytes | `4C 18 C0 …` (JMP $C018) | `4C 18 C0 4C 47 C2 …` |
| `PEEK(49153)` | 24 | `$C001 = $18 = 24` |
| `PEEK(49157)` | 194 | `$C005 = $C2 = 194` |
| Last address | `$C98F` | **`$C98C`** |
| Payload size | 2448 bytes (`$C000–$C98F`) | **2445 bytes** |

The official disk file is **3 bytes shorter** than the published MLX range. The missing bytes are at `$C98D–$C98F` and, from the last printed MLX line, are trailing `$00 $00 $00` after the embedded `TE` marker (variable-name table at the end of the blob). The PEEK signature DIPOLE uses is intact. No evidence the missing tail is live code.

Do **not** judge `CL.ML` against the PDF OCR hex. That layer bleeds across the three MLX columns and substitutes digits (`0`/`8`/`B`/`D`, `C0`/`CD`, etc.).

---

## BP.ML (Feb 1990 MLX) — now on the D64

Print: start `C000`, end `CFFF`, save name `BP.ML`.

XOR/ENCODE gate:

```
PEEK(49153)=24 AND PEEK(49157)=196
```

so a correct `BP.ML` must begin `4C 18 C0 ?? ?? C4 …` (`$C001 = $18 = 24`, `$C005 = $C4 = 196`).

### Two circulating disk images

| Source | `BP.ML` size | First bytes | Verdict |
|--------|--------------|-------------|---------|
| Common `1990-02.d64` (Archive.org disk collections, discmaster #7249) | 762 bytes | `2C 39 31 …` | **Corrupt.** Directory claims 17 blocks; sector chain is broken (`bad ts 75/1`). Payload is leftover text, not the $C000 binary. |
| Feb 1990 **Alt** / Gaz-Type `feb90.d64` / `FEB90.D64` (discmaster #7179; also inside `ftp.elysium.pl` type-in/90 and `arnold.c64.org` Gaz-Type `feb90.zip`) | **4097 bytes** | `00 C0 4C 18 C0 4C 4D C4 …` | **Good.** Matches print start + PEEK gate. |

Verified-good file:

| | |
|---|---|
| Size | 4097 bytes (2-byte load + payload) |
| Load | `$C000` |
| First bytes | `4C 18 C0 4C 4D C4 …` |
| `PEEK(49153)` | 24 |
| `PEEK(49157)` | 196 |
| b3sum | `91cf867714f902c711103dbc5fa23792160f13b7249b3e69afe88e470ea64686` |
| View | https://discmaster.textfiles.com/view/7179/1990-02.d64/bp.ml |

**On this D64 (2026-09-16):** the user-supplied `BP.ML.prg` (4097 bytes, 17 blocks). Round-trip extract matches the PRG. Jump table:

`$C018` init, `$C44D` recognize, `$C6FE` / `$CA4B` undocumented, `$CAB0` learn, `$CB04` set pair, `$CBF7` save, `$CD63` load.

Payload ends at `$CFFE` (printed MLX end `CFFF`); last published byte is the `$00` after `TE`. Full CA65 listing: `ca65/BP.ML.s`.

---

## What the PDF OCR is not

The searchable text in `Compute_Gazette_Neural_Networks_1990.pdf` is the Internet Archive OCR carried through from the magazine scans. On listing pages it:

- reads MLX columns left-to-right across the page instead of down each column
- invents hex (`la` for `18`, `Sil` for `8B`, `OL96` for `<>196`, and so on)

That OCR was **not** used to build this D64. Do not “fix” the PRGs from the PDF text layer.

---

## Summary

| Item | Status |
|------|--------|
| XOR / ENCODE / DIPOLE logic, DATA, SYS calls, PEEK gates | Accurate to the type-ins |
| Line 20 text color `{5}` vs CHR$(152) | Cosmetic discrepancy on all three BASIC files |
| `CL.ML` identity and PEEK signature | Accurate |
| `CL.ML` length | 3 trailing `$00` bytes short of printed end `C98F` |
| `BP.ML` | On the disk. 4097-byte Alt/Gaz-Type binary the user supplied. Load `$C000`, start `4C 18 C0 4C 4D C4`, PEEKs 24 / 196. Payload `$C000–$CFFE` vs printed end `CFFF`. |

No other functional discrepancy was found between the files on `Gazette_NN_1990.d64` and the printed listings.

---

## Added REM lines (not in the print)

Inserted after the copyright REM. Executable lines were not edited.

**XOR** 11–16, 35, 45, 55, 95, 165 — BP SYS map, 2-2-1 shape, XOR pairs, `O3` rounding.

**ENCODE** 11–16, 35, 45, 55, 95, 175 — same SYS map, 4-2-4 shape, one-hot pairs, article train time.

**DIPOLE** 11–17, 35, 45, 65, 75, 195, 315, 325 — CL SYS map, 4×4 grid, horizontal vs vertical dipoles, 400-pass display.
