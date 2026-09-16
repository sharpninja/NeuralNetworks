# Machine-language data-structure mapping receipt

UTC: 2026-09-16T18:12:14Z

## Correction

The previous activity documents reduced all fixed machine-language state to one generic `ML workspace` row. That row has been removed. The documentation now maps the actual fields, addresses, widths, representations, lifetimes, overlays, gaps, and relationships used by BP.ML and CL.ML.

## Artifacts

- `docs/ML-DATA-STRUCTURES.md`
  - Dedicated 225-line reference for BASIC model data, fixed RAM workspaces, serialized layouts, embedded payload data, shared C64 structures, and Mermaid data models.
  - SHA-256: `CF0D4E81E41DDD0DC207AF100A88BC924AD18E06A574279896E76803C40ACD16`
- `docs/Diagrams/BP-ML-Activity-Diagrams.md`
  - Embedded BP model table, 31-field workspace map, serialized layout summary, and workspace-aware data model.
  - SHA-256: `7A6E00BD24194E822743920A91DA71DE23117B435D3315BB1DD44F2E490BCF62`
- `docs/Diagrams/CL-ML-Activity-Diagrams.md`
  - Embedded CL model table, 19-field workspace map, serialized layout summary, counter defect semantics, and workspace-aware data model.
  - SHA-256: `95589D7B76335BB88B9E32EEF1096514CF7A47CC3E3AEB540AEECAE2DF1E7B25`
- `README.md` and `docs/Diagrams/README.md`
  - Added navigation to the data-structure reference.

## Source-derived mapping checks

- BP activity document: 31 workspace rows expected, 31 found, 0 address or width mismatches.
- CL activity document: 19 workspace rows expected, 19 found, 0 address or width mismatches.
- Combined reference BP section: 31 expected, 31 found, 0 mismatches.
- Combined reference CL section: 19 expected, 19 found, 0 mismatches.
- Workspace addresses were compared to the CA65 equates.
- Range ends were checked from each documented field width.
- Generic `ML workspace` rows remaining: 0.

## Regression checks

- Function sections: 93.
- Per-function `Data structures used` lists: 93.
- Activity nodes: 651.
- Activity-node access-map mismatches: 0.
- Local links checked: 169.
- Source line anchors checked: 119.
- Heading anchors checked: 5.
- Link problems: 0.
- Trailing-whitespace lines: 0.
- `git diff --check`: exit 0.
- Mermaid CLI renderer: unavailable, so rendered-diagram validation was not run.

## Independent hostile review

- OverallVerdict: `DISAGREE`
- PASS / FAIL / UNKNOWN: 0 / 1 / 1
- Accuracy: 0 percent
- Completeness: 0 percent
- FAIL `HV-TOOL-001`: The hostile review service rejected the submission with `An error occurred invoking 'hostile_review_submit'.`
- UNKNOWN `HV-RESULT-001`: No independent reviewer examined the data-structure maps or semantic claims.
- Request JSONL: `docs/receipts/hv/20260916T181214Z-ml-data-structures-map.request.jsonl`
- Response JSONL: `docs/receipts/hv/20260916T181214Z-ml-data-structures-map.response.jsonl`
- MCP session log: `Codex-20260916T155204Z-neural-requirements` / `req-20260916T180012Z-ml-data-structures`, turn 45115, status `failed`; full verdict body persisted.
