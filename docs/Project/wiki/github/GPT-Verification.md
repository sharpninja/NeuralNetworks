# Repository verification and collection differences

Inspected September 16, 2026, following separation into `gpt/` and `grok/`. Grok artifacts received a separate update during that work. This report describes the updated files and preserves their provenance; it does not rewrite Grok's binaries or original report.

Repository checks: all 12 original GPT deliverables match the saved output copies by SHA-256; all 40 relative Markdown links resolve; `git diff --check` passes. Both assembly builds and full-byte comparisons pass. No commit or push was performed.

## GPT collection

- The five-file [D64](Neural-Networks-C64.d64) retains SHA-256 `fc73b0d8580569dd71aa240511011861cba4fdcc15636f90e4d615e33d20a183`.
- The PRGs are unchanged extractions from the original magazine disks. The [listing audit](Neural-Networks-C64-Errata.md) records 131 matching BASIC line checksums and 818 matching MLX row checksums, with the three omitted printed zeros supplied only in the comparison buffer.
- The two [ca65 reconstructions](asm/README.md) assemble and link byte for byte to those original PRGs: BP 4,097 bytes and CL 2,448 bytes, including load headers. Run `pwsh -NoProfile -NonInteractive -File ./gpt/asm/Build.ps1` from the repository root to repeat the comparison.
- Instructions, original bytes, jump-table interfaces, BASIC workspace symbols, algorithms, disk routines, and embedded data are annotated. Internal interpretations are identified as reconstructed analysis. Runtime behavior has not been tested in an emulator or on hardware.

## Current Grok artifacts

The [Grok D64](../grok/Gazette_NN_1990.d64) inspected here has SHA-256 `941ee1608c1c6c8183bb6602f18d6713589e97f983642447e6f927dffa804c9b`. VICE c1541 3.10 lists five PRGs and 614 free blocks. The [ZIP](../grok/Gazette_NN_C64_PRGs.zip) has SHA-256 `4f14da5c924be7e85f0e7ff94dbbeaa5d5ba98e18c2734015ba33c087c052095`; all six non-directory entries match their loose files, including the README.

The three loose BASIC PRGs retain every original tokenized line's contents. XOR retains 28/28 original lines and adds 11 REM lines; ENCODE retains 41/41 and adds 11; DIPOLE retains 62/62 and adds 14. No added line starts with a token other than REM. This comparison excludes the next-line addresses, which necessarily change when lines are inserted. These annotated programs differ from the printed listings and the unchanged GPT extractions.

Grok's loose `BP.ML.prg` is byte-identical to the GPT/original disk file. Grok's loose `CL.ML.prg` is 2,447 bytes, matching the first 2,447 bytes of the 2,448-byte original and omitting its final zero at `$C98D`. Thus that loose CL copy is three zeros short of the printed end address, while the original magazine-disk copy in `gpt/` is only two zeros short.

## Grok D64 extraction discrepancies

Reading all five files with VICE c1541 produces files one byte shorter than the loose files. All shared bytes match. Exact lengths include the two-byte PRG load header:

- `BP.ML`: 4,096 bytes on the D64 versus 4,097 loose. The disk omits the loose file's final `$00`, at C64 address `$CFFE`.
- `CL.ML`: 2,446 bytes on the D64 versus 2,447 loose. The disk omits the loose file's final `$45` (the `E` of the embedded `TE` name), at `$C98C`. The original magazine-disk file in `gpt/` is 2,448 bytes.
- `XOR`: 1,322 bytes on the D64 versus 1,323 loose; final `$00` omitted.
- `ENCODE`: 1,641 bytes on the D64 versus 1,642 loose; final `$00` omitted.
- `DIPOLE`: 2,338 bytes on the D64 versus 2,339 loose; final `$00` omitted.

Consequently, the preserved Grok errata's claim that its D64 round-trip matches the loose BP PRG does not hold for this inspected disk hash. Directory block counts and the correct PEEK signatures do not establish full-file equality. The runtime effect of these omissions has not been tested. The GPT D64 remains the byte-preserving original-disk compilation.

Extraction can be repeated with VICE, replacing the destination with a suitable scratch path:

```text
c1541 -attach grok/Gazette_NN_1990.d64 -read bp.ml scratch/BP.ML.prg
```

Repeat for `cl.ml`, `xor`, `encode`, and `dipole`, then compare against `grok/c64_prgs/`. Do not overwrite the loose reference PRGs during extraction.

## Correction to the preserved Grok color note

The line-20 color discrepancy in [Grok's report](../grok/Gazette_NN_D64_Errata.md) comes from misreading the magazine's key notation. The printed bracketed 5 means Commodore-key plus 5, producing gray 2, PETSCII `$98` (152). It does not mean the numeric character code 5 or white. The same issue's "How to Type In COMPUTE!'s Gazette Programs" explains this convention; February printed p. 72 shows the key table. White is separately represented as `{WHT}` with CTRL-2.

The original `$93 $98 $0E` string yields the printed Automatic Proofreader code `GP`. Replacing `$98` with `$05` yields `MQ`. All three original BASIC line-20 checks agree with print, so that color change is not an erratum. The ambiguous braces in a plain-text transcription should not override the rendered magazine notation.

## Limits

Checksums can collide; the listing audit is not an exhaustive independent transcription of every printed byte. Assembly equality does not prove all reconstructed semantic comments. Grok's independent ca65 files are preserved but are not covered by the GPT build verification. No independent adversarial review or runtime validation is claimed.
