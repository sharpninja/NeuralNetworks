# COMPUTE!'s Gazette neural-network type-ins as C64 PRG files

Source: official COMPUTE!'s Gazette companion disks
  February 1990  (archive.org antic-magazine-disks / 1990-02.d64)
  March 1990     (archive.org antic-magazine-disks / 1990-03.d64)

Kevin E. Martin, Future Computing series, Gazette Jan–Mar 1990.

REM lines were added 2026-09-16 to document the SYS interface. The
original executable lines were not changed.

## Files

| File | Kind | Load | Size | Issue |
|---|---|---|---|---|
| XOR.prg | BASIC demo + REMs | $0801 | 1323 | Feb 1990 Part 2 |
| ENCODE.prg | BASIC demo + REMs | $0801 | 1642 | Feb 1990 Part 2 |
| DIPOLE.prg | BASIC demo + REMs | $0801 | 2339 | Mar 1990 Part 3 |
| CL.ML.prg | ML engine | $C000 | 2447 | Mar 1990 Part 3 |
| BP.ML.prg | ML engine | $C000 | 4097 | Feb 1990 Part 2 |

## How to run (VICE / real 64)

Put the matching pair on one disk:

  XOR.prg + BP.ML.prg      (rename to BP.ML)
  ENCODE.prg + BP.ML.prg
  DIPOLE.prg + CL.ML.prg   (rename to CL.ML)

Or use Gazette_NN_1990.d64, which already has all five under those names.

LOAD "DIPOLE",8
RUN

DIPOLE / XOR / ENCODE auto-LOAD the ML file from device 8 if the signature
bytes are missing:

  BP.ML  : PEEK(49153)=24 and PEEK(49157)=196
  CL.ML  : PEEK(49153)=24 and PEEK(49157)=194

CL.ML.prg from the March disk matches those PEEKs and the printed first
MLX line (C000:4C 18 C0 4C 47 C2 …).

## BP.ML.prg (added 2026-09-16)

This is the intact Alt / Gaz-Type copy (not the broken 762-byte file on
the common 1990-02.d64). Load $C000, start 4C 18 C0 4C 4D C4, PEEKs
24 / 196. Commented CA65 listing: ../ca65/BP.ML.s.

January 1990 Part 1 had no type-in.

Extracted 2026-09-16.
