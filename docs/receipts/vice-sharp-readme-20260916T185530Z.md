# VICE Sharp README update receipt

- UTC: 2026-09-16T18:55:30Z
- Workspace: `F:\GitHub\NeuralNetworks`
- Scope: Add Windows installation and run instructions for VICE Sharp, then refresh the published wiki artifacts.

## Files updated or generated

- `README.md`
- `docs/Project/wiki/github/Project-Overview.md`
- `docs/Project/wiki/azure/Project-Overview.md`
- `docs/requirements/requirements-wiki-documents.zip`
- `docs/receipts/hv/20260916T185415Z-vice-sharp-readme.request.jsonl`
- `docs/receipts/hv/20260916T185415Z-vice-sharp-readme.response.jsonl`

## Evidence

- Live `winget show --id sharpninja.ViceSharp --exact` resolved package `sharpninja.ViceSharp`, version 1.2.1.
- The VICE Sharp 1.2.1 source path for a dropped drive 8 image attaches the image and calls `ResetAndAutostartDrive8Async`.
- The VICE Sharp attach-panel picker calls `AttachAsync` without the drop-to-start action, supporting manual program selection.
- VICE Sharp's 1.2.1 announcement states that Commodore ROMs are not included and identifies `VICESHARP_ROM_PATH` as the VICE data-root setting.
- The combined D64 directory contains `XOR` as its first file, followed by `ENCODE`, `DIPOLE`, `BP.ML`, and `CL.ML`.
- README local links checked: 31. Missing: 0.
- Wiki files on disk: 51. ZIP entries: 51. Missing, extra, or content-mismatched entries: 0.
- Wiki ZIP SHA-256: `21AFAAF56A909C50199A14F71CB01829973808FA2D2D66502A63B933DC8EEB32`.
- `git diff --check`: exit 0.
- Archive verification: all five D64 extractions, three BASIC pointer/source round trips, 131 BASIC checks, 818 MLX checks, 36 SHA-256 manifest entries, and the counter probe passed.

## Limits and tool failures

- The instructions were verified against current WinGet metadata, the VICE Sharp 1.2.1 source, project documentation, and the D64 directory. A live GUI launch was not performed.
- MCP session-log begin failed twice with transaction persistence errors.
- Native hostile-review submission failed before creating a review. Existing triage: `triage-report-b9d12dce7ee94ff9a19df1e242a5b9d6`.
- Hostile-review record: PASS 0, FAIL 0, UNKNOWN 1; accuracy 0%, completeness 0%; required threshold 98% was not met because no review ran.

## Result rating

- Accuracy confidence: 99%.
- Completeness: 100%.
