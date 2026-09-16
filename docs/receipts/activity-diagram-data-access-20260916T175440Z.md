# Activity diagram data-access annotation receipt

UTC: 2026-09-16T17:54:40Z

## Scope

Updated both machine-language activity-diagram documents so every subroutine section lists its data structures immediately after the inputs/outputs table and every Mermaid activity node identifies the exact structures it reads and writes. Control-only nodes state `Data access: none`.

## Files

- `docs/Diagrams/BP-ML-Activity-Diagrams.md`
  - SHA-256: `05466B784327A327B9DEE620FD3E13E96CA2F8084FB1CB3F495E5450A6CF7952`
  - 1,196 lines
- `docs/Diagrams/CL-ML-Activity-Diagrams.md`
  - SHA-256: `6359FB802D86F919F9337CFD166C7A469D39F86DA67C997CEEC9A0A995B4EE05`
  - 1,012 lines

## Results

- Subroutine sections: 93 of 93
- Inputs/outputs table followed by `Data structures used` and then the activity diagram: 93 of 93
- Annotated activity nodes: 651 of 651
- Nodes with explicit `Reads` and `Writes`: 384
- Control-only nodes with `Data access: none`: 267
- Exact annotation mismatches against the node access map: 0
- Unannotated nodes: 0
- `UNMAPPED` markers: 0
- Raw `SYS 491xx` nodes: 0

## CL weight scratch correction

The random-weight path now identifies `W1(0,0)` as the normalization accumulator and `W1(cluster,input)` as the element being written. No stale `W1(cluster,0)` references remain.

## Structural validation

- BP functions, data-structure lists, ordered sections: 50, 50, 50
- CL functions, data-structure lists, ordered sections: 43, 43, 43
- Mermaid blocks: BP 51, CL 44; fences balanced in both files
- Local links: 118 checked, 0 missing
- Source anchors: 113 checked, 0 outside target files
- Trailing-whitespace lines: 0
- `git diff --check`: exit 0
- Mermaid CLI renderer: unavailable, so no rendered-diagram validation was run

## Independent hostile review

- OverallVerdict: `DISAGREE`
- PASS / FAIL / UNKNOWN: 0 / 1 / 1
- Accuracy: 0 percent
- Completeness: 0 percent
- FAIL `HV-TOOL-001`: The hostile review service rejected the submission with `An error occurred invoking 'hostile_review_submit'.`
- UNKNOWN `HV-RESULT-001`: No independent reviewer examined the documentation or validated the implementation claims.
- Request JSONL: `docs/receipts/hv/20260916T175440Z-activity-diagram-data-access.request.jsonl`
- Response JSONL: `docs/receipts/hv/20260916T175440Z-activity-diagram-data-access.response.jsonl`
- MCP session-log persistence: failed because `sessionlog.upsert_turn` rejected the turn with `Invalid session turn planFile/todoId: planFile is omitted.`
