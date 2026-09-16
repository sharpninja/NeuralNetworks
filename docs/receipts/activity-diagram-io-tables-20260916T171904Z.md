# Activity-diagram input/output table receipt

UTC: 2026-09-16T17:19:04Z

## Change

Added a two-column inputs-and-outputs table to every BP.ML and CL.ML activity-diagram section. Each table appears after the **Work performed:** description and before the Mermaid diagram.

The tables document BASIC-call arguments for public vectors and the shared zero-page state, BASIC arrays, floating-point accumulator, or KERNAL channel preconditions used by internal routines. Outputs include returned state and observable side effects.

## Current artifacts

- `docs/Diagrams/BP-ML-Activity-Diagrams.md`
  - Functions: 50
  - Input/output tables: 50
  - Mermaid blocks: 50
  - Lines: 1045
  - SHA-256: `A3BFF6745EE79C02D46E2B8F82056A3BCFDF347ADC93142AC16A5A81A1299DA2`
- `docs/Diagrams/CL-ML-Activity-Diagrams.md`
  - Functions: 43
  - Input/output tables: 43
  - Mermaid blocks: 43
  - Lines: 882
  - SHA-256: `A8B08200F046F07F434A42F02CE6CE415F763E7F07F11AC61CFF8DEEE9B6B6FF`

These hashes supersede the diagram hashes in `activity-diagram-work-descriptions-20260916T170710Z.md`.

## Validation

- Function sections checked: 93
- Work descriptions found: 93
- Input/output tables found: 93
- Populated input/output rows found: 93
- Mermaid blocks found: 93
- Sections with missing, duplicate, malformed, or misplaced tables: 0
- Local links checked: 112
- Missing local links: 0
- SYS 491xx invocation nodes remaining: 0
- Trailing-whitespace lines: 0
- `git diff --check`: passed with no output

## Independent review gate

- Request: `docs/receipts/hv/20260916T171904Z-activity-diagram-io-tables.request.jsonl`
- Response: `docs/receipts/hv/20260916T171904Z-activity-diagram-io-tables.response.jsonl`
- Overall verdict: `DISAGREE`
- PASS: 0
- FAIL: 1
- UNKNOWN: 1
- Accuracy: 0 percent
- Completeness: 0 percent

The hostile-review tool failed before a reviewer ran. The zero scores record an unavailable independent assessment, not an observed defect in the tables or diagrams.
