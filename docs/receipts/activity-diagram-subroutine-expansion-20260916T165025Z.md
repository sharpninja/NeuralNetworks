# Activity-diagram subroutine expansion receipt

UTC: 2026-09-16T16:50:25Z

## Change

Replaced every public-diagram node that displayed a BASIC SYS invocation with the activities performed by the selected machine-language entry and its subroutine chain. Redundant tail-call nodes in those public diagrams were removed.

Examples now expand:

- BP initialization into parameter parsing, BASIC storage creation, bias setup, weight randomization, and relative-offset caching.
- BP recognition into input conversion, hidden and output activation, error calculation, and result handling.
- BP training entries into forward propagation, delta calculation, momentum updates, epoch accumulation, and epsilon termination.
- CL initialization into storage creation, random cluster weights, normalization, and offset caching.
- CL recognition into pattern import, activation calculation, winner selection, and one-hot output.
- CL learning into PAT initialization, shuffling, classification, winner-only weight updates, and the 400-pass BASIC loop.
- BP and CL save/load entries into their full channel, serialization, recreation, and restoration activities.

## Current artifacts

- `docs/Diagrams/BP-ML-Activity-Diagrams.md`
  - Lines: 745
  - SHA-256: `955A522497C17832849442E44A261C310F92F8C73E95008B85D58EBE60530F17`
- `docs/Diagrams/CL-ML-Activity-Diagrams.md`
  - Lines: 624
  - SHA-256: `F378473DE074DC74F4CD7FEDAEE0E88C8F9AE8466AF24A13F6D08A65359C4236`

These hashes supersede the diagram hashes in `ml-activity-diagrams-20260916T163941Z.md`.

## Validation

- BP source labels: 50
- BP diagram headings and Mermaid blocks: 50
- CL source labels: 43
- CL diagram headings and Mermaid blocks: 43
- SYS invocation nodes remaining in either diagram document: 0
- Missing functions: 0
- Extra functions: 0
- Duplicate functions: 0
- Relative links checked: 112
- Source line anchors checked: 107
- Structural Mermaid issues: 0
- `git diff --check`: passed with no output

## Independent review gate

- Request: `docs/receipts/hv/20260916T165025Z-activity-diagram-subroutine-expansion.request.jsonl`
- Response: `docs/receipts/hv/20260916T165025Z-activity-diagram-subroutine-expansion.response.jsonl`
- Overall verdict: `DISAGREE`
- PASS: 0
- FAIL: 1
- UNKNOWN: 1
- Accuracy: 0 percent
- Completeness: 0 percent

The hostile-review tool failed before a reviewer ran. The zero scores record an unavailable independent assessment, not an observed defect in the revised diagrams.

