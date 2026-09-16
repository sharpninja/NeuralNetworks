# Technical Requirements (MCP Server)

## TR-MCP-TRIAGE-004

**TR-MCP-TRIAGE-004** — Placeholder requirement backfilled for TODO link TR-MCP-TRIAGE-004.
**Status:** pending
Scope: layer-1+

## TR-NN-ABI-001

**Fixed SYS jump-table ABI** — Both engines shall load at $C000 and preserve the public vector layout at 49152, 49155, 49158, 49161, 49164, 49167, 49170, and 49173.
**Covered by:** FR: FR-NN-001, FR-NN-002, FR-NN-003, FR-NN-004, FR-NN-005, FR-NN-006, FR-NN-007, FR-NN-008, FR-NN-009, FR-NN-010, FR-NN-011, FR-NN-012; TEST: TEST-NN-001, TEST-NN-012, TEST-NN-002, TEST-NN-003, TEST-NN-004, TEST-NN-005, TEST-NN-006, TEST-NN-007, TEST-NN-008
**Status:** in_progress
Scope: layer-1+
**Acceptance Criteria:**
- [ ] Initialization, recognition, learning, pattern definition, save, and load remain at the documented SYS addresses.
- [ ] BP retains train-pattern and train-epoch vectors at 49158 and 49161; CL retains NOP,NOP,RTS compatibility slots at those addresses.

## TR-NN-ARCHIVE-001

**Combined archive integrity and provenance** — The combined edition shall retain complete PRGs, an exact five-file D64, readable BASIC, OCR articles with errata, source provenance, and reproducible verification receipts.
**Covered by:** FR: FR-NN-013; TEST: TEST-NN-009, TEST-NN-010, TEST-NN-011
**Status:** in_progress
Scope: layer-1+
**Acceptance Criteria:**
- [ ] D64 extraction, BASIC detokenize-retokenize round trips, 131 BASIC listing checks, and 818 MLX row checks match recorded evidence.
- [ ] The PDF has 15 pages and four bookmarks, preserves the first 14 pages, and includes the documented errata page.

## TR-NN-BPALG-001

**Back-propagation forward and error algorithm** — BP shall compute hidden and output activations with the logistic sigmoid and calculate per-pattern half squared error.
**Covered by:** FR: FR-NN-004, FR-NN-005, FR-NN-012; TEST: TEST-NN-003, TEST-NN-004, TEST-NN-012, TEST-NN-001, TEST-NN-006, TEST-NN-007
**Status:** in_progress
Scope: layer-1+
**Acceptance Criteria:**
- [ ] Hidden and output sums include their corresponding index-zero bias weight and apply 1/(1+exp(-sum)).
- [ ] E(pattern) equals one half of the sum of squared teacher-minus-output differences.

## TR-NN-BPARCH-001

**Back-propagation storage model** — BP shall maintain P1, P2, P3, NP, RA, MO, EP, TE and the O2, O3, E2, E3, W1, W2, M1, M2, T, IN, and E arrays with index-zero bias and scratch storage.
**Covered by:** FR: FR-NN-002, FR-NN-003, FR-NN-006, FR-NN-012; TEST: TEST-NN-001, TEST-NN-002, TEST-NN-012, TEST-NN-005, TEST-NN-003, TEST-NN-004, TEST-NN-006, TEST-NN-007
**Status:** in_progress
Scope: layer-1+
**Acceptance Criteria:**
- [ ] O2(0), O3(0), and IN(0,pattern) are initialized to one for bias multiplication.
- [ ] W1 and W2 allocated entries initialize from 10*RND(1)-5 and momentum arrays are retained separately.

## TR-NN-BPUPDATE-001

**Back-propagation delta and momentum update** — BP shall calculate output and hidden deltas and update both weight matrices using learning rate plus momentum.
**Covered by:** FR: FR-NN-004, FR-NN-012; TEST: TEST-NN-003, TEST-NN-004, TEST-NN-012, TEST-NN-001, TEST-NN-006, TEST-NN-007
**Status:** in_progress
Scope: layer-1+
**Acceptance Criteria:**
- [ ] E3 equals (teacher-output)*output*(1-output), and M2 equals RA*E3*O2 + MO*M2 before W2 is incremented.
- [ ] E2 uses currently stored, already-updated W2 values, and M1 equals RA*E2*IN + MO*M1 before W1 is incremented.

## TR-NN-BUILD-001

**Byte-reproducible ca65 reconstruction** — The machine-language sources shall assemble and link at fixed origin $C000 with target-neutral 6502 settings to reproduce the selected original PRGs byte for byte.
**Covered by:** FR: FR-NN-013; TEST: TEST-NN-009, TEST-NN-010, TEST-NN-011
**Status:** in_progress
Scope: layer-1+
**Acceptance Criteria:**
- [ ] Build output including two-byte load headers equals BP.ML.prg at 4097 bytes and CL.ML.prg at 2448 bytes.
- [ ] Assembly avoids target character remapping that would alter embedded BASIC strings.

## TR-NN-CLALG-001

**Competitive winner selection** — CL shall compute one dot product per cluster, select the greatest activation, and expose the result as a one-hot O2 vector.
**Covered by:** FR: FR-NN-009, FR-NN-010, FR-NN-012; TEST: TEST-NN-006, TEST-NN-007, TEST-NN-012, TEST-NN-001, TEST-NN-003, TEST-NN-004
**Status:** in_progress
Scope: layer-1+
**Acceptance Criteria:**
- [ ] The activation sum covers input indices 1 through P1 and does not use a bias term.
- [ ] The first cluster wins ties and only the winning O2 element is one at return.

## TR-NN-CLARCH-001

**Competitive-learning storage and initialization** — CL shall maintain P1, P2, NP, RA and O2, W1, IN, and PAT arrays, with positive randomized cluster weights normalized across active input columns.
**Covered by:** FR: FR-NN-007, FR-NN-008, FR-NN-011, FR-NN-012; TEST: TEST-NN-001, TEST-NN-006, TEST-NN-012, TEST-NN-008, TEST-NN-003, TEST-NN-004, TEST-NN-007
**Status:** in_progress
Scope: layer-1+
**Acceptance Criteria:**
- [ ] W1(cluster,0) is zero and W1(cluster,1..P1) initializes from positive RND values.
- [ ] Each cluster row is divided by its own initial sum and PAT is retained as transient order storage.

## TR-NN-CLTRAIN-001

**Competitive training, shuffle, and counter semantics** — CL shall shuffle pattern presentation on every pass, update only the winning cluster toward the normalized pattern, poll RUN/STOP, and preserve the original 16-bit counter behavior including its documented defect.
**Covered by:** FR: FR-NN-009, FR-NN-012; TEST: TEST-NN-006, TEST-NN-007, TEST-NN-012, TEST-NN-001, TEST-NN-003, TEST-NN-004
**Status:** in_progress
Scope: layer-1+
**Acceptance Criteria:**
- [ ] PAT is initialized to 1..NP and shuffled by the observed Fisher-Yates style swap before patterns are presented.
- [ ] The counter characterization reproduces the exact expected passes for all twelve recorded cases, including 400 requested producing 144.

## TR-NN-COMPAT-001

**Engine identification and coexistence constraint** — Demos shall identify the loaded engine by the established PEEK signatures and shall treat BP.ML and CL.ML as mutually exclusive because both occupy $C000.
**Covered by:** FR: FR-NN-001, FR-NN-012, FR-NN-013; TEST: TEST-NN-001, TEST-NN-012, TEST-NN-003, TEST-NN-004, TEST-NN-006, TEST-NN-007, TEST-NN-009, TEST-NN-010, TEST-NN-011
**Status:** in_progress
Scope: layer-1+
**Acceptance Criteria:**
- [ ] BP is recognized by PEEK(49153)=24 and PEEK(49157)=196; CL is recognized by PEEK(49153)=24 and PEEK(49157)=194.
- [ ] Switching engine families reloads the required engine before invoking its ABI.

## TR-NN-DATA-001

**BASIC numeric and array representation** — Network values shall use BASIC five-byte floating-point storage and the array index-zero elements allocated by BASIC.
**Covered by:** FR: FR-NN-002, FR-NN-003, FR-NN-007, FR-NN-008; TEST: TEST-NN-001, TEST-NN-002, TEST-NN-012, TEST-NN-006
**Status:** in_progress
Scope: layer-1+
**Acceptance Criteria:**
- [ ] Vector indexing advances by five bytes and matrix indexing includes allocated row or column zero.
- [ ] Dimension and pattern arguments parsed as bytes remain within the BASIC ROM byte-conversion domain.

## TR-NN-PARSER-001

**Pattern string validation and conversion** — Both engines shall require pattern strings of exactly P1 characters, and BP teacher strings of exactly P3 characters, converting ASCII 1 to numeric one and all other characters to numeric zero.
**Covered by:** FR: FR-NN-003, FR-NN-005, FR-NN-008, FR-NN-010, FR-NN-012; TEST: TEST-NN-002, TEST-NN-012, TEST-NN-003, TEST-NN-004, TEST-NN-006, TEST-NN-001, TEST-NN-007
**Status:** in_progress
Scope: layer-1+
**Acceptance Criteria:**
- [ ] Out-of-range stored pattern numbers and wrong-length strings raise BASIC illegal quantity handling.
- [ ] Recognition uses pattern column zero while stored definitions use columns 1 through NP.

## TR-NN-PLATFORM-001

**C64 BASIC V2 and KERNAL integration** — The engines shall execute as 6502 code integrated with Commodore 64 BASIC V2 parser, variable, array, floating-point, and KERNAL I/O routines.
**Covered by:** FR: FR-NN-001, FR-NN-002, FR-NN-004, FR-NN-006, FR-NN-007, FR-NN-009, FR-NN-011, FR-NN-012; TEST: TEST-NN-001, TEST-NN-012, TEST-NN-002, TEST-NN-003, TEST-NN-004, TEST-NN-005, TEST-NN-006, TEST-NN-007, TEST-NN-008
**Status:** in_progress
Scope: layer-1+
**Acceptance Criteria:**
- [ ] BASIC arguments are parsed through the BASIC V2 ROM entry points and results reside in BASIC scalars and arrays.
- [ ] RUN/STOP and sequential device I/O use the documented C64 KERNAL entry points.

## TR-NN-STORAGE-001

**Sequential network-file formats** — Save and load shall use device 8 sequential files with logical file 1, secondary address 2, and drive status on logical file 15.
**Covered by:** FR: FR-NN-006, FR-NN-011; TEST: TEST-NN-005, TEST-NN-012, TEST-NN-008
**Status:** in_progress
Scope: layer-1+
**Acceptance Criteria:**
- [ ] BP serialization order is P1,P2,P3,NP, RA,MO,EP, W1,W2,M1,M2,IN,T including allocated zero indices.
- [ ] CL serialization order is P1,P2,NP, RA,W1,IN including allocated zero indices; O2 and PAT are not serialized.

