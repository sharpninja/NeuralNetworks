# Activity-diagram data-structure documentation receipt

UTC: 2026-09-16T17:29:34Z

## Change

Added a **Data structures and model** section to both activity-diagram documents. Each section documents five-byte BASIC numeric storage, inclusive DIM bounds, index-zero conventions, logical array shapes, machine-language workspace state, relative address offsets, and snapshot persistence. Each document also contains a Mermaid data-flow model showing the relationships among configuration, pattern storage, learned parameters, runtime state, and updates.

## Current artifacts

- `docs/Diagrams/BP-ML-Activity-Diagrams.md`
  - Functions: 50
  - Input/output tables: 50
  - Data-structure tables: 1
  - Mermaid blocks: 51, including one data model
  - Lines: 1094
  - SHA-256: `7FEFA20A9D72B79107DC639B8360FAE34A77AB27BCBCE87F165F36FD26BC5A0D`
- `docs/Diagrams/CL-ML-Activity-Diagrams.md`
  - Functions: 43
  - Input/output tables: 43
  - Data-structure tables: 1
  - Mermaid blocks: 44, including one data model
  - Lines: 924
  - SHA-256: `96EBE6211C4D7E8F028B9E6115A381C6E44B26457BF9C76E06F7E64A186268EB`

These hashes supersede the diagram hashes in `activity-diagram-io-tables-20260916T171904Z.md`.

## Source basis

- BP workspace map: `combined/asm/BP.ML.s` line 23.
- BP DIM declarations: `combined/asm/BP.ML.s` lines 1893-1906.
- BP snapshot layout: `combined/asm/BP.ML.s` lines 1539-1602.
- CL workspace map: `combined/asm/CL.ML.s` line 23.
- CL DIM declarations: `combined/asm/CL.ML.s` lines 1252-1258.
- CL snapshot layout: `combined/asm/CL.ML.s` lines 984-1011.

## Validation

- Semantic function sections: 93
- Per-subroutine input/output tables: 93
- Data-structure sections: 2
- Data-structure tables: 2
- Data-model flowcharts: 2
- Total Mermaid blocks: 95
- Local links checked: 118
- Missing local links: 0
- Source line anchors checked: 113
- Invalid source line anchors: 0
- Trailing-whitespace lines: 0
- SYS 491xx invocation nodes remaining: 0
- `git diff --check`: passed with no output
- Mermaid CLI render: not run because `mmdc` is not installed; fence counts and flowchart declarations passed structural checks

## Independent review gate

- Request: `docs/receipts/hv/20260916T172934Z-activity-diagram-data-structures.request.jsonl`
- Response: `docs/receipts/hv/20260916T172934Z-activity-diagram-data-structures.response.jsonl`
- Overall verdict: `DISAGREE`
- PASS: 0
- FAIL: 1
- UNKNOWN: 1
- Accuracy: 0 percent
- Completeness: 0 percent

The hostile-review tool failed before a reviewer ran. The zero scores record an unavailable independent assessment, not an observed defect in the data-structure documentation or diagrams.
