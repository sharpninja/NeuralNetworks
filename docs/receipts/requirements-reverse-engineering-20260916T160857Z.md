# Reverse-Engineering Receipt

TimestampUtc: 2026-09-16T16:08:57Z

## Scope

Reverse-engineer the combined C64 neural-network code into functional requirements, technical requirements, test requirements, traceability mappings, and use cases without changing product code.

## MCP records

- Functional requirements: 13
- Technical requirements: 14
- Test requirements: 12
- FR mappings: 13
- Acceptance criteria: 78 total, 0 marked satisfied
- Requirement statuses: all `in_progress`
- Use cases: 9, IDs UC-110 through UC-118
- Use-case approval statuses: all `Draft`
- Use-case product key: `prod-c64-neural-networks`
- Use-case coverage: 9 of 9 use cases linked; 13 of 13 FRs linked; no coverage gaps
- Mapping integrity: every FR, TR, and TEST has traceability coverage; zero missing referenced IDs

## Generated documents

- `docs/Project/Functional-Requirements.md`: SHA-256 `D3D592630BE054C5931DB33A3BFF02994F103ACBF60646E2F6840E7566258208`
- `docs/Project/Technical-Requirements.md`: SHA-256 `62183FE2C07C9446346E711A565177AFC9CA57EB97D845047C1C38EE81254AD6`
- `docs/Project/Testing-Requirements.md`: SHA-256 `BD089D44697E506BD49F465772F2C4B0C21CBAE305532DBAB46FB917FFD4F04C`
- `docs/Project/TR-per-FR-Mapping.md`: SHA-256 `BCB5F476370040D240590DD9FD1307C1A9F81E02404EA913141A50A0306AC887`
- `docs/Project/Requirements-Matrix.md`: SHA-256 `1FA06DCD3B7DF9D3184BF378F8F1351E4E1CC19126C62846391BAB9716C57333`
- `docs/Project/Use-Cases.md`: SHA-256 `5CDAA349FB743FC4EC7A3DCDA1ADFFA278763CED08E20139EC57305D9823894F`

## Current validation

- `combined/asm/Build.ps1`: BP.ML identical, 4097 bytes, SHA-256 `571ef6326bc83e39fefd4d9c446405a4510b2d9f9d9279c77ba23ba4f6bf4274`; CL.ML identical, 2448 bytes, SHA-256 `b436bac31257da8f9508c3908a7e9d4baba0c7c3d1876ba67d0927b72a4d56cb`.
- `combined/verification/Check-Counter.ps1`: all 12 characterized cases matched, including 400 requested producing 144 passes.
- `combined/verification/Verify-Archive.ps1`: five D64 entries identical; XOR, ENCODE, and DIPOLE BASIC structure and source round trips verified; 131 original BASIC lines preserved; 36 REM lines added; 131 BASIC checks matched; 818 MLX checks matched; 36 manifest entries verified.

## Limits and blocker

Full neural-network execution on an emulator or physical C64 remains untested and is captured by `TEST-NN-012`. All acceptance criteria remain unsatisfied and all use cases remain Draft.

Two calls to `hostile_review_submit` and one call to `hostile_review_query` failed with the generic MCP invocation error and no request ID. Independent hostile validation is unavailable and is not claimed. Triage report `triage-report-2230222b0b5848089bd283937fbbce54`, group `triage-group-03198a0a98c0628a`, status `collecting`.
