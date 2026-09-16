# Merge and cross-check report

September 16, 2026. Source repository snapshot: commit `3554e8f`, with all 34 selected source-collection files recorded in [SOURCE-SHA256.csv](verification/SOURCE-SHA256.csv). The `grok/` and `gpt/` collections remain unchanged. This folder is the reconciled edition.

## Selection and merge decisions

- **Articles:** retain the 14 scanned pages and fresh OCR from GPT, then append one errata page. Grok's smaller PDF contains the same magazine pages plus a cover; its alternative compression and OCR remain available in the source collection rather than duplicated here.
- **BASIC programs:** retain Grok's 36 explanatory REM additions and all 131 original line bodies. Refine seven added REM lines: XOR line 15; ENCODE lines 15 and 95; DIPOLE lines 15, 65, 315 and 325. These clarify the BP `TE <= EP` stopping condition, CL's trial-count defect, which weight columns are normalized, the article's "over 60 minutes" wording, and readable approximation wording. Executable lines and the original copyright REM remain unchanged. Rebuild all next-line pointers after the comment edits.
- **Machine-language PRGs:** retain the original-disk GPT extractions, also matching Grok's BP copy. CL retains the final zero missing from Grok's loose copy. The original engine code, including the newly identified trial-counter bug, is preserved.
- **D64:** create a new image with VICE c1541 from the five selected PRGs. Do not copy Grok's shortened disk entries. Extract and compare all five complete files after writing.
- **Assembly:** retain GPT's more extensive byte-verified reconstruction, cross-check its code against Grok's independent disassembly, add the demo signatures, and annotate the newly confirmed CL defect. Retain a complete target-neutral build and linker configuration.
- **Evidence:** include original BASIC PRGs, readable annotated BASIC, original listing-check CSVs, complete source hashes, file hashes, reproducible archive checks, and a focused counter probe.

## Corrections established by the cross-check

### 1. Original CL trial-counter bug missed in the prior GPT audit

The previous audit established checksum and binary agreement but did not inspect this loop's behavior. It therefore missed a real bug shared by print and the disk: some positive counts above 256 execute 256 fewer passes. In the focused 6502 probe, 400 requested passes produce 144. Six of the twelve boundary cases expose the defect; the other six establish correct zero, small-count and exact-multiple behavior. See [ERRATA.md](ERRATA.md) and [counter-results.txt](verification/counter-results.txt).

Printed March page 45 rows `$C600-$C628` were visually compared with the engine. The probe enters the original loop at `$C606`, supplying already-converted argument bytes. Only training and RUN/STOP are substituted; the remaining counter instructions are checked against the embedded original. This is targeted execution evidence, not a test of the entire C64 program. DIPOLE's original loop uses one pass per call and avoids the defect.

### 2. Grok's documented build remaps embedded strings

Both Grok sources compile with the documented `ca65 -t c64` command. However, that target's character mapping changes 58 BP data bytes and 30 CL data bytes. The first differences are `$CF2E` and `$C935`, where the embedded BASIC strings begin. In addition, the named `c64-asm.cfg` linker configuration is absent from Grok's folder.

Using a scratch linker configuration and target-neutral `ca65 --cpu 6502` reproduces both Grok payloads exactly. Both independent instruction streams agree with the selected originals. Grok's CL payload is one trailing zero shorter. The merged build includes the proper PRG header and configuration and reproduces BP's 4,097 bytes and CL's 2,448 bytes exactly.

### 3. Grok's D64 is shorter than its loose files

The inspected Grok D64 SHA-256 is `941ee1608c1c6c8183bb6602f18d6713589e97f983642447e6f927dffa804c9b`. Fresh VICE extraction produced BP 4,096 bytes, CL 2,446, XOR 1,322, ENCODE 1,641 and DIPOLE 2,338. Each is one byte shorter than the corresponding Grok loose file; all shared bytes match. CL loses the final `E` in its already shortened trailing `TE` string. The five-file directory and correct PEEK signatures do not establish complete-file equality.

The Grok ZIP SHA-256 is `4f14da5c924be7e85f0e7ff94dbbeaa5d5ba98e18c2734015ba33c087c052095`; its six non-directory entries match the five loose PRGs and README. The loose BASIC files have valid pointers and terminators. They are the basis for the merged annotations.

### 4. Grok's color interpretation is incorrect

The printed key notation means Commodore-5, gray 2 (`$98`), rather than white (`$05`). The original line-20 checksum agrees with print. The merged edition retains the correct color and explains the notation in the PDF and errata.

### 5. Several Grok assembly comments were not adopted

The CL save routine writes dimensions, RA, W1 and IN; it does not serialize O2 or PAT. Cluster weights are randomized and normalized, rather than all being initialized to `1/P1`. The matrix helper accounts for allocated zero indices; the claimed `(x-1)`/`(y-1)` formula is not the observed implementation. BP's embedded `O1(0)` text is absent from its DIM list and does not establish a created scratch array. The merged comments retain the instruction-derived descriptions.

## Checks and limits

- Re-extracted both source D64s; all five GPT files match their loose originals, while all five Grok entries exhibit the lengths described above.
- Recomputed the original listing checks: 131/131 BASIC lines and 818/818 MLX rows match, using three temporary final zeros only for the MLX comparison. This does not prove every printed byte or the algorithm because the checksums are eight-bit values.
- Rebuilt GPT and merged ca65 sources: both engine PRGs match their originals byte for byte. Independently rebuilt Grok's payloads using target-neutral assembly and compared their shared bytes.
- Checked BASIC line pointers, ordering and end markers in both input collections and the merged programs. Compared every original line body and all added line types. Retokenized the three merged `.bas` files and compared the resulting PRGs byte for byte.
- Checked the original OCR PDF's 14 pages, text coverage, three article bookmarks and rendered page appearance. The merged PDF adds one errata page and bookmark; the first 14 pages' rendered images and extracted text are unchanged. The added page was rendered and visually inspected.
- Ran the twelve-case original-counter characterization under sim65. This reproduces the known defect rather than correcting it. Full neural-network execution on a C64 emulator or physical C64 remains untested.

The final archive verification checks exact D64 extraction, BASIC structure and source round trips, preserved original line contents, recorded checksum audit consistency, and the complete [SHA-256 manifest](SHA256SUMS.txt). The scripts and receipts are in [verification/](verification/).

No independent adversarial review was available, and no such review is claimed. No source collections were rewritten, and no commit or push was performed for this merge.
