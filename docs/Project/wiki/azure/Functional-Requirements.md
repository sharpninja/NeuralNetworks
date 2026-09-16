# Functional Requirements (MCP Server)

## FR-MCP-TRIAGE-002 FR-MCP-TRIAGE-002

Placeholder requirement backfilled for TODO link FR-MCP-TRIAGE-002.
Scope: layer-1+

## FR-NN-001 Load and select a neural-network demonstration

The archive shall let a C64 operator load XOR, ENCODE, or DIPOLE from device 8 and shall load the required BP.ML or CL.ML engine when the expected memory signature is absent.
Scope: layer-1+
**Acceptance Criteria:**
- [ ] LOAD of XOR, ENCODE, or DIPOLE from device 8 reaches the selected BASIC program.
- [ ] The demo checks its BP or CL signature and loads the corresponding machine-language engine at $C000 when needed.

## FR-NN-002 Initialize a back-propagation network

The BP engine shall initialize a three-layer network from input, hidden, output, pattern-count, learning-rate, momentum, and error-tolerance arguments and expose its BASIC variables and arrays.
Scope: layer-1+
**Acceptance Criteria:**
- [ ] SYS 49152 accepts P1, P2, P3, NP, RA, MO, and EP in the documented order.
- [ ] Initialization creates O2, O3, E2, E3, W1, W2, M1, M2, T, IN, E, and TE storage with bias index zero initialized as required.

## FR-NN-003 Define supervised training pairs

The BP engine shall store an input string and teacher string for a numbered training pattern.
Scope: layer-1+
**Acceptance Criteria:**
- [ ] SYS 49167 accepts only pattern numbers 1 through NP, an input string of length P1, and a teacher string of length P3.
- [ ] Each ASCII 1 is stored as numeric one and every other character is stored as numeric zero.

## FR-NN-004 Train a back-propagation network

The BP engine shall train stored patterns by back propagation with momentum until total error is within epsilon or the operator interrupts learning.
Scope: layer-1+
**Acceptance Criteria:**
- [ ] Each epoch trains patterns 1 through NP in order and updates TE from the pre-update half-squared errors.
- [ ] SYS 49164 repeats epochs while TE is greater than EP, optionally prints TE, and honors RUN/STOP after an epoch.

## FR-NN-005 Recognize a pattern with back propagation

The BP engine shall run a supplied input pattern through the initialized network and expose hidden and output activations to BASIC.
Scope: layer-1+
**Acceptance Criteria:**
- [ ] SYS 49155 accepts an input string whose length equals P1 and places it in scratch pattern column zero.
- [ ] Recognition calculates sigmoid hidden outputs in O2 and sigmoid final outputs in O3 without altering a stored training pair.

## FR-NN-006 Save and restore a back-propagation network

The BP engine shall save a trained network to device 8 and restore it into recreated BASIC storage.
Scope: layer-1+
**Acceptance Criteria:**
- [ ] SYS 49170 writes dimensions, RA, MO, EP, W1, W2, M1, M2, IN, and T as a sequential file on device 8.
- [ ] SYS 49173 recreates storage from saved dimensions and restores all serialized scalar and matrix values.

## FR-NN-007 Initialize a competitive-learning network

The CL engine shall initialize input, cluster, pattern-count, and learning-rate state and expose its BASIC variables and arrays.
Scope: layer-1+
**Acceptance Criteria:**
- [ ] SYS 49152 accepts P1, P2, NP, and RA in the documented order and creates O2, W1, IN, and PAT storage.
- [ ] Each cluster receives positive random input weights normalized so its P1 weights sum approximately to one.

## FR-NN-008 Define unsupervised input patterns

The CL engine shall store a binary input string and its active-input count for a numbered training pattern.
Scope: layer-1+
**Acceptance Criteria:**
- [ ] SYS 49167 accepts only pattern numbers 1 through NP and a string whose length equals P1.
- [ ] The engine stores ASCII 1 as numeric one, every other character as zero, and the number of active inputs in IN(0,pattern).

## FR-NN-009 Train a competitive-learning network

The CL engine shall train for requested passes by shuffling stored patterns, selecting a winning cluster, and moving only the winner toward the normalized input pattern, subject to the preserved trial-counter limitation.
Scope: layer-1+
**Acceptance Criteria:**
- [ ] Each pass shuffles pattern order and updates only the winning cluster by RA times normalized input minus current weight.
- [ ] Counts 0 through 255 and positive multiples of 256 behave as documented; mixed-byte counts above 255 exhibit the preserved 256-pass shortfall and the repeated one-pass workaround remains valid.

## FR-NN-010 Classify a pattern with competitive learning

The CL engine shall classify a supplied pattern by input-weight dot product and expose the selected cluster to BASIC.
Scope: layer-1+
**Acceptance Criteria:**
- [ ] SYS 49155 accepts a string whose length equals P1 and evaluates it as scratch pattern zero.
- [ ] O2 contains numeric one for the winning cluster and zero for other clusters, with the earlier cluster retained when activations tie.

## FR-NN-011 Save and restore a competitive-learning network

The CL engine shall save learned cluster state to device 8 and restore it into recreated BASIC storage.
Scope: layer-1+
**Acceptance Criteria:**
- [ ] SYS 49170 writes P1, P2, NP, RA, W1, and IN as a sequential file on device 8.
- [ ] SYS 49173 restores serialized data and regenerates PAT instead of serializing transient PAT or O2 state.

## FR-NN-012 Demonstrate supervised and competitive learning

The archive shall provide runnable XOR, four-bit encoder, and dipole-clustering demonstrations that exercise the two engines through their public SYS interfaces.
Scope: layer-1+
**Acceptance Criteria:**
- [ ] XOR trains a 2-2-1 network and reports rounded O3 decisions for all four truth-table inputs.
- [ ] ENCODE trains a 4-2-4 network and reports O2 and O3 states; DIPOLE trains two clusters on 24 horizontal and vertical patterns using 400 one-pass calls.

## FR-NN-013 Publish a reproducible combined archive

The repository shall preserve the selected executable, readable source, magazine, errata, provenance, and verification artifacts as one reproducible combined edition.
Scope: layer-1+
**Acceptance Criteria:**
- [ ] The combined D64 contains XOR, ENCODE, DIPOLE, BP.ML, and CL.ML and extraction returns bytes identical to the selected PRGs.
- [ ] The edition includes the 15-page OCR PDF with errata, readable BASIC, byte-reproducible ca65 sources, source provenance, and SHA-256 manifests.

