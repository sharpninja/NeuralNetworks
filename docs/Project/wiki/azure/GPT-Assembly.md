# Commented ca65 disassembly

[BP.ML.s](BP.ML.s) and [CL.ML.s](CL.ML.s) reconstruct Kevin E. Martin's two C64 neural-network engines from the original magazine-disk PRGs in [../Neural-Networks-C64](../Neural-Networks-C64/). Both assemble and link to exactly those files, including the two-byte `$C000` load-address header.

The symbols and comments are newly reconstructed, not the author's original assembly source. Public SYS interfaces and neural-network terminology come from the articles. Internal formulas and routine roles are inferred from the disassembly and the C64 BASIC ROM routines it calls. Each instruction retains its original address and bytes as a comment.

## Build and verify

Install the [cc65 toolchain](https://cc65.github.io/) and PowerShell 7, with `ca65` and `ld65` available on PATH. From the repository root:

```powershell
pwsh -NoProfile -NonInteractive -File ./gpt/asm/Build.ps1
```

The script assembles both sources, links using [c64-ml.cfg](c64-ml.cfg), and compares every resulting byte with the corresponding original PRG. A tool error, length mismatch, or byte difference fails the build. Object files, listings, maps, and PRGs go into the ignored `gpt/asm/build/` directory. `-OutputDirectory`, `-Ca65`, and `-Ld65` accept alternative paths.

Verified on September 16, 2026 with ca65/ld65 V2.18, Git b67b6d3: **2/2 assemblies and byte comparisons passed**.

- `BP.ML.prg`: 4,097 file bytes; 4,095 payload bytes at `$C000-$CFFE`. SHA-256 `571ef6326bc83e39fefd4d9c446405a4510b2d9f9d9279c77ba23ba4f6bf4274`.
- `CL.ML.prg`: 2,448 file bytes; 2,446 payload bytes at `$C000-$C98D`. SHA-256 `b436bac31257da8f9508c3908a7e9d4baba0c7c3d1876ba67d0927b72a4d56cb`.

The [listing errata](../Neural-Networks-C64-Errata.md) explains the three final zero bytes present in print but absent from these original disk files. They are intentionally not appended. No emulation or physical C64 execution test is claimed. Byte equality verifies reconstruction, not every inferred comment or the author's algorithm.

## Reading the sources

Both engines begin with an eight-slot SYS jump table. Six commands are documented in the articles:

- `49152` (`$C000`): initialize the network and BASIC storage.
- `49155` (`$C003`): recognize an input string and leave results in BASIC arrays.
- `49164` (`$C00C`): learn, using a convergence tolerance in BP or a trial count in CL.
- `49167` (`$C00F`): define a training pattern, including a teacher string for BP.
- `49170` / `49173` (`$C012` / `$C015`): save / load a network snapshot on device 8.

BP also exposes a single-pattern training entry at `$C006` and an epoch entry at `$C009`. These roles are inferred from the binary; the article does not document them. CL has `NOP,NOP,RTS` stubs in those two slots.

BP comments cover bias elements, sigmoid activation, half squared error, output and hidden deltas, and momentum updates. The observed code updates W2 before calculating the hidden deltas that read W2; the annotation preserves that order. CL comments cover normalized random weights, winner selection, shuffled pattern presentation through `PAT()`, and the winner-only weight update toward the normalized input vector.

The engines use the C64 BASIC ROM's five-byte floating-point representation. The named workspace locations include dimensions, pattern indices, array offsets, scratch floats, and disk I/O storage. After initialization, cached array addresses are relative to BASIC's `ARYTAB`, while scalar addresses are relative to `VARTAB`. The indexing helpers account for five-byte elements and BASIC's allocated index-zero entries.

Embedded DIM expressions and variable-name strings are data, not instructions. BP's data begins at `$CF2E`; CL's begins at `$C935`. The zero/one constants and unused trailing names are retained verbatim. Immediate low/high pointer bytes are kept literal, so these are fixed-address reconstructions, not relocatable engines. The two programs share memory and cannot be resident together.

Save/load routines write sequential network snapshots containing dimensions, parameters, and selected arrays. Those snapshots are a different format from the engine PRGs. Input parsers require the expected string length and treat ASCII `1` as one and other characters as zero; the articles instruct the user to supply binary strings.

## Sources and disassembly metadata

- [Combined searchable articles](../Future-Computing-Neural-Networks-Parts-1-2-3-OCR.pdf): February 1990, printed pp. 34-39 for BP; March 1990, printed pp. 42-46 for CL. January provides the series introduction.
- [Original extracted programs and provenance](../Neural-Networks-C64/README.txt).
- [C64 ROM disassembly](https://github.com/mist64/c64ref/blob/main/src/c64disasm/c64disasm_en.txt), used to identify BASIC floating-point, parser, and KERNAL calls.
- [Official da65 documentation](https://cc65.github.io/doc/da65.html).

[BP.ML.info](BP.ML.info) and [CL.ML.info](CL.ML.info) retain the da65 symbols, explanatory comments, and data ranges. They skip the original PRG's two-byte header. For example, from this directory, the following creates a raw annotated payload listing in the build directory after running the build once:

```powershell
da65 -i BP.ML.info -o build/BP.ML.da65.s ../Neural-Networks-C64/BP.ML.prg
```

That generated listing does not include the committed source's PRG header segment, origin declaration, or payload-length assertion. Build the committed `.s` files to reproduce the complete PRGs.
