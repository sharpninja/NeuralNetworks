# Gazette neural-network ML, CA65 sources

Kevin E. Martin, *Future Computing: Neural Networks*, COMPUTE!'s Gazette
January–March 1990. These files are a commented disassembly of the two
machine-language engines that back the type-ins.

| File | What it is | Binary on hand? |
|---|---|---|
| `CL.ML.s` | Full CA65 listing of the March competitive-learning engine | Yes — `../c64_prgs/CL.ML.prg` |
| `BP.ML.s` | Full CA65 listing of the February back-prop engine | Yes — `../c64_prgs/BP.ML.prg` |

## CL.ML.s

Worklist-disassembled from the official March 1990 Gazette Disk PRG
(`$C000–$C98C`, 2445 bytes). Printed MLX ended at `$C98F`; the three
missing bytes are trailing zeros after the `TE` marker (see
`Gazette_NN_D64_Errata.md`).

Comments come from:

- the March article SYS list (`49152` init, `49155` recognize,
  `49164` learn, `49167` store pattern, `49170` save, `49173` load)
- DIPOLE.prg (`SYS 49152,16,2,24,0.1` then 24 dipole strings)
- the embedded PTRGET name table at `$C935`
  (`O2(P2),W1(P2,P1),IN(P1,NP),PAT(NP)` plus scalars `RA P1 P2 NP`)
- the weight-init loop that seeds each `W1` row and divides so the
  row sums to 1 (the “all weights in a row sum to 1” rule in the
  article)

`SYS 49158` and `SYS 49161` are `NOP NOP RTS` stubs. Same eight-slot
table layout as BP.ML; only six commands are published.

Assemble:

```
ca65 -t c64 CL.ML.s -o CL.ML.o
ld65 -C c64-asm.cfg CL.ML.o -o CL.ML.prg
```

`$BC3C` is labeled `FACBYTE` because every call is `LDA #n / JSR $BC3C`
followed by `MOVMF` — FAC := unsigned byte in A. That is an interior
ROM entry, not a published KERNAL name.

## BP.ML.s

Worklist-disassembled from the user-supplied Alt / Gaz-Type `BP.ML.prg`
(4097 bytes, `$C000–$CFFE`). Printed MLX ended at `$CFFF`.

| SYS | Label | Role |
|---|---|---|
| 49152 | `init_network` | `fpe,spe,tpe,np,lr,momen,err` |
| 49155 | `recognize` | forward pass → `O2`, `O3` |
| 49158 / 49161 | undocumented | present in the binary, not in the article |
| 49164 | `learn` | until `te < epsilon`; `se=1` prints `te` |
| 49167 | `setpair` | `pn, ip$, tp$` |
| 49170 / 49173 | `save_net` / `load_net` | SEQ snapshot |

Name table at `$CF2E` matches article Table 1 (`RA MO EP P1–P3 NP`,
`O2 O3 E2 E3 W1 W2 M1 M2 T IN E`) plus an `O1(0)` shell.
