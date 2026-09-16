# Neural Networks on the Commodore 64

Kevin E. Martin's three-part **Future Computing: Neural Networks** series from *COMPUTE!'s Gazette*, January-March 1990. This archive brings together the articles, searchable scans, original magazine-disk programs, and a comparison with the printed type-ins.

## Repository layout

- [gpt/](gpt/): Codex's fresh-OCR PDF, unchanged original-disk programs, five-file D64, checksum audit, and commented ca65 sources.
- [grok/](grok/): Grok's PDF, D64, PRG ZIP and loose files, errata, and ca65 sources. Its BASIC files include added explanatory REM lines.

The root README is the shared index. Each collection keeps its own artifacts and provenance. See the [current verification notes](gpt/VERIFICATION.md) for differences between the collections, including shortened files in the Grok D64.

## Read the articles

[Download the combined searchable PDF](gpt/Future-Computing-Neural-Networks-Parts-1-2-3-OCR.pdf) (14 pages, approximately 34 MiB). It includes all three articles and their program listings, with fresh OCR and navigation bookmarks. January's intervening full-page advertisement is omitted.

- **Part 1:** January 1990, issue 79, printed pages 23, 24, and 26. Introduction and linear associators. No accompanying type-in program.
- **Part 2:** February 1990, issue 80, printed pages 34-39. Backpropagation, with `BP.ML`, `XOR`, and `ENCODE`.
- **Part 3:** March 1990, issue 81, printed pages 42-46. Competitive learning, with `CL.ML` and `DIPOLE`.

The PDF preserves the scanned page appearance. OCR is useful for searching and reading, but the dense hexadecimal listings contain recognition errors. Use the extracted programs below for loading into a C64.

## Run the programs

[Download Neural-Networks-C64.d64](gpt/Neural-Networks-C64.d64). This standard 35-track disk image contains all five programs, extracted unchanged from archived magazine disks:

- `XOR`: BASIC exclusive-OR demonstration; uses `BP.ML`.
- `ENCODE`: BASIC encoding demonstration; uses `BP.ML`.
- `DIPOLE`: BASIC graph-partitioning demonstration; uses `CL.ML`.
- `BP.ML`: backpropagation engine, loaded at `$C000`.
- `CL.ML`: competitive-learning engine, loaded at `$C000`.

Mount the D64 as device 8 in a C64 emulator or a compatible disk device. Load one demonstration and run it:

```basic
LOAD"XOR",8
RUN
```

Replace `XOR` with `ENCODE` or `DIPOLE` to run another example. The BASIC programs load their companion machine-language engine automatically. Run one example at a time; the engines use the same memory area.

The [individual PRG files](gpt/Neural-Networks-C64/) are also included, with their original load-address headers. When importing them into another C64 disk, use the names above without the host `.prg` suffix. See the [program README](gpt/Neural-Networks-C64/README.txt) for loading and source details, and [SHA256SUMS.txt](gpt/Neural-Networks-C64/SHA256SUMS.txt) for individual file hashes.

## Read and rebuild the assembly

[BP.ML.s](gpt/asm/BP.ML.s) and [CL.ML.s](gpt/asm/CL.ML.s) contain commented ca65 reconstructions, including named SYS entry points, BASIC workspace and ROM calls, learning formulas, disk routines, and embedded data. Comments use the articles and disassembly as context and distinguish reconstructed interpretation from original source.

Both sources rebuild byte for byte to the archived PRGs. With PowerShell 7 and the cc65 toolchain on PATH, run:

```powershell
pwsh -NoProfile -NonInteractive -File ./gpt/asm/Build.ps1
```

See the [assembly README](gpt/asm/README.md) for tool versions, hashes, source references, and verification limits.

## Verification and known differences

The [disk-versus-listing errata](gpt/Neural-Networks-C64-Errata.md) records the exact addresses, file sizes, method, sources, and limits of the comparison performed on September 16, 2026.

- All five files in the compiled D64 match their source magazine-disk files byte for byte.
- All **131 BASIC line checksums** match the printed Automatic Proofreader codes. [Per-line results](gpt/Neural-Networks-C64-BASIC-Checks.csv).
- All **818 MLX row checksums** match after supplying the three absent final zero bytes in the comparison buffer only. [Per-address results](gpt/Neural-Networks-C64-MLX-Checks.csv).
- The original `BP.ML` omits the printed zero at `$CFFF`. The original `CL.ML` omits the printed zeros at `$C98E` and `$C98F`. The programs and D64 retain those original lengths; they have not been patched.

The printed checksums are eight-bit values and can collide. The audit is not an exhaustive independent transcription of every printed byte, and the programs have not been execution-tested as part of this archive preparation. The runtime effect of the absent trailing zeros remains untested.

SHA-256 of the complete five-file D64:

```text
fc73b0d8580569dd71aa240511011861cba4fdcc15636f90e4d615e33d20a183
```

## Grok collection

Grok's independently prepared artifacts remain together:

- [Compute_Gazette_Neural_Networks_1990.pdf](grok/Compute_Gazette_Neural_Networks_1990.pdf): a smaller 15-page compilation, comprising a cover page and the same 14 magazine pages, with the source OCR text layer.
- [Gazette_NN_1990.d64](grok/Gazette_NN_1990.d64): five directory entries, including `BP.ML`; the three BASIC programs contain added REM comments. Current extraction shows each disk file is one byte shorter than its corresponding loose PRG.
- [PRG ZIP](grok/Gazette_NN_C64_PRGs.zip) and [loose PRGs](grok/c64_prgs/): five programs; the ZIP matches the loose files. Grok's loose `CL.ML` is one trailing zero shorter than the original disk extraction in `gpt/`.
- [Grok ca65 sources](grok/ca65/README.md).
- [Grok errata](grok/Gazette_NN_D64_Errata.md): preserved as supplied. Read the [current comparison and corrections](gpt/VERIFICATION.md) alongside it, particularly the line-20 color notation and D64 length claims.

Use **gpt/Neural-Networks-C64.d64** for the unchanged original-disk program collection.

## Sources and credits

Articles and neural-network programs: **Kevin E. Martin**, *COMPUTE!'s Gazette*, issues 79-81 (1990), COMPUTE! Publications. Original copyright notices remain in the programs and scans.

Magazine scans were obtained from the Internet Archive. Original disk images are preserved in the [COMPUTE!'s Gazette disk collection at DLH's Commodore Archive](https://commodore.bombjack.org/commodore/magazines-disk/compute-gazette/compute-gazette-disk.htm):

- February: `1990-02-good.d64`.
- March: `1990-03.d64` inside `Compute!'s_Gazette_Disks_(04-21-2024).zip`.

The earlier compilation was assembled by Grok. The five-file disk, separate PRGs, fresh-OCR PDF, and checksum audit were prepared with Codex. VICE `c1541` 3.10 was used for disk extraction and inspection.
