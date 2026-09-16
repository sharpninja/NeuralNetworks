# ML activity-diagram receipt

UTC: 2026-09-16T16:39:41Z

## Request

Create Mermaid activity diagrams for each function in the combined machine-language files, using the BASIC demonstrations as caller context for public entry points.

## Outputs

- `docs/Diagrams/README.md`
  - Lines: 27
  - SHA-256: `537D20EF49DF3880A4463A08DACCEB346474DE11A983F5445227B2960BA237C0`
- `docs/Diagrams/BP-ML-Activity-Diagrams.md`
  - Lines: 719
  - SHA-256: `E96FE2C59E70E9DE4155E870E0EC125583960190B9007D778EA9C7175D9A3605`
- `docs/Diagrams/CL-ML-Activity-Diagrams.md`
  - Lines: 602
  - SHA-256: `BEEF09A7C21E876C8C38F02F30D9AC87D7E4803F22E1D552D0C8F8186E88EBE6`
- `README.md` links the diagram index.
- `combined/asm/README.md` links the diagram index and explains that the BASIC callers drive the public-vector diagrams.

## Coverage

The inventory includes named semantic labels before each source file's `DimExpressions` data table and excludes equates, `PayloadStart`, generated `Lxxxx` labels, and data labels.

- BP source labels: 50
- BP diagram headings: 50
- BP Mermaid blocks: 50
- BP directed edges: 294
- BP missing, extra, or duplicate headings: 0
- CL source labels: 43
- CL diagram headings: 43
- CL Mermaid blocks: 43
- CL directed edges: 233
- CL missing, extra, or duplicate headings: 0
- Total functions and diagrams: 93

## BASIC caller evidence

Executable SYS statements that target the documented ML jump table:

- `XOR.bas`: 10 statements
- `ENCODE.bas`: 10 statements
- `DIPOLE.bas`: 26 statements

The DIPOLE learning diagram represents the BASIC loop that calls `SYS 49164,1` 400 times. Recognition and save/load in DIPOLE are identified as REM-documented interfaces because the executable body does not call them.

## Validation

- Diagram inventory comparison: passed.
- Mermaid fence and `flowchart TD` declaration counts: passed, 93 of each.
- Mermaid line structure: passed, zero blank diagram lines, missing directed edges, unbalanced quotes, or malformed empty edge labels.
- Relative links checked: 119.
- Source line anchors checked: 107.
- Missing link targets or out-of-range anchors: 0.
- `git diff --check`: passed with no output.

The Mermaid CLI is not installed on this host, so this receipt records structural syntax validation rather than rendered SVG validation. Full neural-network behavior remains outside this documentation-only change.

## Independent review gate

- Request jsonl: `docs/receipts/hv/20260916T164023Z-ml-activity-diagrams.request.jsonl`
- Response jsonl: `docs/receipts/hv/20260916T164023Z-ml-activity-diagrams.response.jsonl`
- Overall verdict: `DISAGREE`
- PASS: 0
- FAIL: 1
- UNKNOWN: 1
- Accuracy score: 0 percent
- Completeness score: 0 percent

The hostile-review tool failed before a reviewer ran. The zero scores record an unavailable independent assessment, not a confirmed diagram defect. MCP session-log writes also failed at the subscriber commit boundary, so the review body could not be stored there.

