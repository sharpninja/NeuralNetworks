# Neural Networks on the Commodore 64

Kevin E. Martin's three-part **Future Computing: Neural Networks** series from *COMPUTE!'s Gazette*, January-March 1990: articles, C64 programs, commented assembly, and verified archival comparisons.

## Start with the combined edition

The [combined/ folder](combined/README.md) merges the verified parts of the Grok and GPT collections:

- [Searchable articles with errata](combined/Neural-Networks-Articles-OCR.pdf): 14 original magazine pages plus an appended errata page, with four navigation bookmarks.
- [Combined five-file D64](combined/Neural-Networks-C64.d64): Grok's annotated BASIC examples, with seven REM refinements, and the full original machine-language engines.
- [Individual PRGs](combined/prg/) and [readable BASIC](combined/basic/).
- [Commented ca65 sources and build instructions](combined/asm/README.md).
- [Errata](combined/ERRATA.md), [merge report](combined/MERGE-REPORT.md), and [SHA-256 hashes](combined/SHA256SUMS.txt).

Mount the D64 as device 8 in a C64 emulator or compatible disk device:

```basic
LOAD"XOR",8
RUN
```

Use `ENCODE` or `DIPOLE` in place of `XOR` for the other examples. Each loads its companion engine automatically. Both engines use `$C000`; run one example at a time.

**Confirmed original bug:** CL.ML's `SYS 49164,400` performs only 144 passes. Use repeated `SYS 49164,1` calls. The printed DIPOLE program already does this. The merged engines preserve the original code, with the defect documented on the new PDF errata page.

## Run with VICE Sharp on Windows

Windows users can install the [VICE Sharp](https://github.com/sharpninja/vice-sharp) desktop emulator with WinGet:

```powershell
winget install --id sharpninja.ViceSharp --exact
```

VICE Sharp does not include Commodore ROM images. Set `VICESHARP_ROM_PATH` to a legally obtained VICE data root containing the `C64\` and `DRIVES\` directories. This PowerShell command saves the setting for future Windows sessions; replace the sample path and restart VICE Sharp afterward:

```powershell
[Environment]::SetEnvironmentVariable(
    'VICESHARP_ROM_PATH',
    'C:\path\to\GTK3VICE-3.8-win64',
    'User')
```

Start **ViceSharp** from the Windows Start menu. To run the combined disk:

- Drag [`combined/Neural-Networks-C64.d64`](combined/Neural-Networks-C64.d64) onto the emulator display. VICE Sharp mounts it as drive 8 and automatically runs the first program, `XOR`.
- To choose an example, use the **Drive 8** Browse button in VICE Sharp's Attach panel to mount the D64 without starting it. At the C64 prompt, enter the `LOAD` and `RUN` commands shown above, using `XOR`, `ENCODE`, or `DIPOLE`.

Keep the D64 mounted while an example runs because each BASIC program loads its companion `BP.ML` or `CL.ML` engine from drive 8.

## Articles

- **Part 1:** January 1990, issue 79, printed pp. 23, 24 and 26. Introduction and linear associators; no type-in program.
- **Part 2:** February 1990, issue 80, printed pp. 34-39. Backpropagation with `BP.ML`, `XOR` and `ENCODE`.
- **Part 3:** March 1990, issue 81, printed pp. 42-46. Competitive learning with `CL.ML` and `DIPOLE`.

The scans retain the original appearance. OCR is useful for searching, but recognition errors remain in the dense program listings. Use the verified PRGs when exact bytes matter.

## Preserved source collections

Both input collections remain intact so the merge can be audited:

- [grok/](grok/): [PDF](grok/Compute_Gazette_Neural_Networks_1990.pdf), [D64](grok/Gazette_NN_1990.d64), [PRG ZIP](grok/Gazette_NN_C64_PRGs.zip), [loose programs](grok/c64_prgs/), [ca65 sources](grok/ca65/README.md), and [original Grok errata](grok/Gazette_NN_D64_Errata.md). The merge report documents its shortened disk entries, assembly build-command issue and comment corrections.
- [gpt/](gpt/): [14-page OCR PDF](gpt/Future-Computing-Neural-Networks-Parts-1-2-3-OCR.pdf), [unaltered original-program D64](gpt/Neural-Networks-C64.d64), [original PRGs](gpt/Neural-Networks-C64/), [ca65 reconstruction](gpt/asm/README.md), and [earlier listing audit](gpt/Neural-Networks-C64-Errata.md). That audit established byte/checksum agreement but missed the CL trial-counter defect found during the merge.

The [combined merge report](combined/MERGE-REPORT.md) is the current cross-check. Older reports describe their own inspected snapshots.

## Reverse-engineered specification

The combined code is traced into durable MCP requirements and draft use cases:

- [Functional requirements](docs/Project/Functional-Requirements.md)
- [Technical requirements](docs/Project/Technical-Requirements.md)
- [Test requirements](docs/Project/Testing-Requirements.md)
- [Traceability matrix](docs/Project/Requirements-Matrix.md)
- [Use cases](docs/Project/Use-Cases.md)
- [Mermaid activity diagrams for all 93 ML functions](docs/Diagrams/README.md)
- [Machine-language data structures, workspace maps, and serialized layouts](docs/ML-DATA-STRUCTURES.md)

All requirement acceptance criteria remain unsatisfied and all use cases remain Draft until the full C64 integration regression is run and reviewed.

## Validation

The original listing audit matched 131 BASIC line checksums and 818 MLX rows, with three missing trailing zero bytes supplied only in the comparison buffer. Checksums can collide and do not establish algorithmic correctness.

The combined archive includes reproducible checks for both assembly builds, all five D64 file extractions, BASIC line pointers and source round trips, all 131 retained original line bodies, and file hashes. Its 12-case sim65 probe isolates the CL counter and reproduces the original bug. Full neural-network execution on an emulator or physical C64 has not been tested.

## Sources and credits

Articles and programs: **Kevin E. Martin**, COMPUTE! Publications, 1990. Original copyright notices remain in the scans and programs.

Magazine scans: Internet Archive's [January](https://archive.org/details/1990-01-computegazette), [February](https://archive.org/details/1990-02-computegazette), and [March](https://archive.org/details/1990-03-computegazette) issues. Original programs: [DLH's COMPUTE!'s Gazette disk archive](https://commodore.bombjack.org/commodore/magazines-disk/compute-gazette/compute-gazette-disk.htm), specifically `1990-02-good.d64` and `1990-03.d64` from `Compute!'s_Gazette_Disks_(04-21-2024).zip`.

Grok prepared an independent compilation, annotated BASIC examples and disassemblies. Codex prepared the fresh OCR and original-disk audit, cross-checked both collections, and assembled the combined edition. VICE c1541/petcat 3.10 and cc65 V2.18 were used for the binary checks.
