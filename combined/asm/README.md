# Merged annotated ca65 sources

[BP.ML.s](BP.ML.s) and [CL.ML.s](CL.ML.s) reconstruct the original magazine-disk engines at `$C000`. They retain Codex's address/byte comments and named routines, cross-checked against Grok's independent disassemblies and the article interfaces. Public demo signatures are included, and CL's trial-count bug is explicitly annotated. Symbols and explanatory comments are reconstructed, not original author source.

With PowerShell 7 and cc65 on PATH, from this folder:

```powershell
pwsh -NoProfile -NonInteractive -File ./Build.ps1
```

[Build.ps1](Build.ps1) assembles both sources, adds their PRG load headers via [c64-ml.cfg](c64-ml.cfg), and compares every byte with the engines in [../prg](../prg/). Outputs, listings and maps go into the ignored `build/` folder. `-OutputDirectory`, `-Ca65`, and `-Ld65` allow alternative paths. Verified tool version: ca65/ld65 V2.18, Git b67b6d3.

**Use the supplied command. Do not add `-t c64`.** The embedded strings already contain the original byte values. That target's character mapping changes uppercase string bytes; a test of Grok's documented `-t c64` command changed 58 BP data bytes and 30 CL data bytes. The supplied target-neutral build preserves them.

The two engines use BASIC ROM floating-point and parsing routines, five-byte arrays, and relative offsets from BASIC's scalar/array bases. BP annotations explain bias inputs, sigmoid activation, half squared error, deltas, and momentum. CL annotations explain normalization, winner selection, shuffled `PAT()` order, and winner-only updates. Save/load routines and the embedded DIM/name tables are identified separately from code.

[Mermaid activity diagrams](../../docs/Diagrams/README.md) trace every semantic code label. The public-vector diagrams use the executable BASIC demonstrations as caller context.

The absolute origin and literal pointer immediates are intentional. These sources are not relocatable. Do not append printed tail padding silently: see [ERRATA.md](../ERRATA.md). The known CL counter bug is preserved; neither byte equality nor these comments claim that full training was tested.

[BP.ML.info](BP.ML.info) and [CL.ML.info](CL.ML.info) retain da65 labels, comments, and data ranges. For a raw payload listing after creating `build/`:

```powershell
da65 -i BP.ML.info -o build/BP.ML.da65.s ../prg/BP.ML.prg
```

The committed `.s` adds the header segment, fixed origin and payload-length assertion absent from that raw listing.

Context: [combined articles](../Neural-Networks-Articles-OCR.pdf), February printed pp. 34-39 and March pp. 42-46; [C64 ROM disassembly](https://github.com/mist64/c64ref/blob/main/src/c64disasm/c64disasm_en.txt); [official da65 documentation](https://cc65.github.io/doc/da65.html).
