# Errata and verification notes

Added September 16, 2026. A condensed version is appended as page 15 of the [combined PDF](Neural-Networks-Articles-OCR.pdf). The first 14 pages remain the original scanned article pages with OCR.

## Confirmed printed-code bug: CL.ML trial counter

The March 1990 listing on printed page 45 contains a decrement error in the `SYS 49164,n` trial loop at `$C606-$C62B`. For a positive count above 255 whose low byte is nonzero, the loop executes 256 fewer passes than requested. Counts of 1 through 255 and positive multiples of 256 behave as requested; zero returns without a pass.

Examples observed with the original counter instructions:

- 257 requested: 1 pass executed.
- 400 requested: 144 passes executed.
- 511 requested: 255 passes executed.
- 512 requested: 512 passes executed.
- 513 requested: 257 passes executed.
- 1,000 requested: 744 passes executed.

When the low byte reaches zero, the code decrements a nonzero high byte and exits immediately if it becomes zero. For a mixed high/low count, that exit omits the final block of 256 passes. The printed rows `$C600-$C628` were visually checked against the scan and agree with the disk bytes. This is an original code defect, not an OCR or merge error.

The [12-case counter probe](verification/Check-Counter.ps1) executes the engine's counter in cc65 sim65. It enters at `$C606`, after BASIC argument conversion, with the argument's high and low bytes supplied in A and Y. The expensive epoch body is replaced by an incrementing call counter; the RUN/STOP call is redirected to a no-key stub. Every other byte of `$C606-$C62B`, including the arithmetic and branches, is checked against the original. [Recorded output](verification/counter-results.txt) includes both correct boundary cases and the defective cases. This probe does not execute BASIC argument parsing or full neural-network training.

Workaround for 400 passes:

```basic
FOR I=1 TO 400
SYS 49164,1
NEXT I
```

The published DIPOLE demonstration already calls `SYS 49164,1` inside its own loop. The combined engine remains byte-identical to the original disk file. No machine-code patch has been applied.

## Original disk lengths versus the printed MLX ranges

- `BP.ML`: printed `$C000-$CFFF`; original disk payload `$C000-$CFFE`. The zero at `$CFFF` is absent. PRG size including load header: 4,097 bytes.
- `CL.ML`: printed `$C000-$C98F`; original disk payload `$C000-$C98D`. The zeros at `$C98E-$C98F` are absent. PRG size including load header: 2,448 bytes.

These are omissions in archived disk files, not incorrect printed hex. The combined PRGs preserve the original disk lengths. The three zeros were supplied only in a temporary buffer for the published-checksum comparison. They are not appended to the engines.

Grok's shorter loose CL copy and the additional D64 extraction truncations are described in the [merge report](MERGE-REPORT.md). They are not inherited by the newly built combined D64.

## Printed line 20 has the correct color byte

The bracketed 5 in the magazine means Commodore-key plus 5, giving gray 2, PETSCII `$98` (152). It does not mean white or character code 5. February's printed page 72, "How to Type In COMPUTE!'s Gazette Programs," distinguishes this key notation from `{WHT}` (CTRL-2).

The original `$93 $98 $0E` string yields the printed Automatic Proofreader code `GP`; changing `$98` to `$05` yields `MQ`. No color correction is needed. The earlier Grok color note is incorrect.

## OCR and checksum limits

The PDF retains visible scans, but its searchable text contains recognition errors in the dense BASIC and hexadecimal listings. Use the visible page or verified PRGs when exact bytes matter.

The [BASIC audit](verification/BASIC-Checks.csv) contains 131 matching original line checksums. The [MLX audit](verification/MLX-Checks.csv) contains 818 matching rows with the final-zero comparison padding disclosed. These eight-bit checksums can collide. They do not prove algorithmic correctness, as the trial-counter defect demonstrates, or establish an exhaustive independent transcription of every printed byte.
