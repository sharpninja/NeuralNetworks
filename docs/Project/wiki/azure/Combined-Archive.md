# Combined C64 neural-network archive

Kevin E. Martin's three-part *Future Computing: Neural Networks* series from *COMPUTE!'s Gazette*, January-March 1990. This edition combines Grok's annotated BASIC demonstrations with the verified original machine-language engines and Codex's searchable articles and commented assembly.

## Read, run, or study

- [Articles with OCR and errata](Neural-Networks-Articles-OCR.pdf): 15 pages, comprising all 14 magazine pages plus a new errata page; four navigation bookmarks.
- [Combined D64](Neural-Networks-C64.d64): five files, with the complete selected PRGs written and extracted again for byte comparison.
- [PRG files](prg/): `XOR`, `ENCODE`, `DIPOLE`, `BP.ML`, and `CL.ML`, including their original C64 load-address headers.
- [Readable BASIC](basic/): detokenized versions of the three annotated programs.
- [Commented ca65 assembly](asm/README.md): both engines, build script, linker configuration, and disassembly metadata.
- [Machine-language data structures](../docs/ML-DATA-STRUCTURES.md): exact BASIC model layouts, fixed RAM workspace maps, serialized file formats, and embedded tables.
- [Activity diagrams](../docs/Diagrams/README.md): descriptions, inputs, outputs, data structures, and control flow for all 93 semantic ML routines.
- [Errata](ERRATA.md): a confirmed bug in the printed CL.ML trial counter, disk-file omissions, and OCR/color notation guidance.
- [Merge and verification report](MERGE-REPORT.md): selection decisions, corrections to prior work, checks, and limits.
- [File hashes](SHA256SUMS.txt), [input provenance](verification/SOURCE-SHA256.csv), and [original BASIC files](original-basic/) retained for comparison.

Mount the D64 as device 8, then run one demonstration:

```basic
LOAD"XOR",8
RUN
```

Replace `XOR` with `ENCODE` or `DIPOLE`. Each demonstration loads its companion engine automatically. Both engines occupy `$C000`, so run one demonstration at a time.

**Known original bug:** `SYS 49164,400` in CL.ML runs only 144 passes. Use repeated `SYS 49164,1` calls. The published DIPOLE program already follows that pattern. The original machine code is preserved, with the bug documented rather than patched.

The BASIC programs retain all 131 original line bodies and add 36 REM lines from Grok's version. Seven added REM lines were refined for accuracy or PETSCII readability. These annotations are not part of the 1990 printed listings. The separately retained original BASIC PRGs support a direct comparison.

## Reproduce the checks

With PowerShell 7 and the cc65 toolchain on PATH:

```powershell
pwsh -NoProfile -NonInteractive -File ./asm/Build.ps1
pwsh -NoProfile -NonInteractive -File ./verification/Check-Counter.ps1
```

The first command rebuilds both engine PRGs and compares every byte with `prg/`. The second characterizes the original CL trial-counter defect using sim65 and controlled substitutes for training and RUN/STOP. It is not a full C64 neural-network execution test.

Use [verification/Verify-Archive.ps1](verification/Verify-Archive.ps1) with VICE `c1541` and `petcat` available on PATH to verify the D64, BASIC pointers and source round trips, retained original line bodies, and checksum manifests.

## Credits

Original articles and programs: Kevin E. Martin, COMPUTE! Publications, 1990. Existing copyright notices remain in the programs and scans. Grok supplied annotated BASIC and independent disassemblies; Codex reconciled the collections, verified the binaries, and prepared this merged edition. The source collections remain separately preserved in the repository.
