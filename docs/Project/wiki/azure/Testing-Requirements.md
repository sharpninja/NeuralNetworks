# Testing Requirements (MCP Server)

## TEST-NN

### TEST-NN-001

Statically and at runtime verify the load address, jump-table vectors, reserved slots, and BP/CL PEEK signatures.

**Acceptance Criteria:**
- [ ] Disassembly and PRG bytes identify every public vector at its specified address.
- [ ] A C64 runtime reports the documented BP and CL PEEK signatures after each engine loads.

### TEST-NN-002

Exercise BP initialization, array creation, bias state, stored-pair bounds, string lengths, and character conversion.

**Acceptance Criteria:**
- [ ] Valid parameters create the documented scalar and array shapes with required zero-index bias values.
- [ ] Invalid pattern indices or string lengths fail through BASIC illegal quantity, while non-1 characters become zero.

### TEST-NN-003

Execute XOR with BP.ML and verify convergence, reported outputs, deterministic seed behavior, and interruption handling.

**Acceptance Criteria:**
- [ ] Training reaches TE <= .02 and rounded O3 outputs equal 0,1,1,0 for 00,10,01,11.
- [ ] RUN/STOP during learning exits after the current epoch through BASIC break handling.

### TEST-NN-004

Execute ENCODE with BP.ML and verify the hidden two-bit representation and reconstructed four-bit outputs.

**Acceptance Criteria:**
- [ ] Training reaches TE <= .02 for the four configured input and teacher pairs.
- [ ] Each input produces a two-element O2 code and rounded O3 output matching its configured teacher string.

### TEST-NN-005

Save an initialized and trained BP network, disturb or recreate BASIC state, load the file, and compare every serialized value and recognition result.

**Acceptance Criteria:**
- [ ] Saved file bytes follow the documented dimension, scalar, and matrix order including zero indices.
- [ ] After load, dimensions, parameters, weights, momentum, patterns, teachers, and recognition outputs equal the pre-save state.

### TEST-NN-006

Execute DIPOLE with CL.ML and verify normalized initialization, 24 stored patterns, shuffled one-pass training, and two-cluster output.

**Acceptance Criteria:**
- [ ] Each initial cluster row sums approximately to one and each defined dipole stores two active inputs.
- [ ] Four hundred repeated SYS 49164,1 calls complete and produce two distinguishable learned cluster rows with one-hot recognition results.

### TEST-NN-007

Run the focused original-instruction counter probe for zero, byte-boundary, mixed-byte, and exact-multiple counts.

**Acceptance Criteria:**
- [ ] All twelve recorded cases equal the preserved implementation, including 257->1, 400->144, 512->512, and 1000->744.
- [ ] The repeated one-pass workaround executes exactly the requested number of passes.

### TEST-NN-008

Save an initialized and trained CL network, reload it, and compare serialized state and regenerated transient state.

**Acceptance Criteria:**
- [ ] Saved file bytes contain P1,P2,NP,RA,W1,IN in order and omit O2 and PAT.
- [ ] After load, persisted values and classification results match pre-save state and PAT is usable for a new epoch.

### TEST-NN-009

Run the ca65 build and compare each rebuilt PRG with the selected combined PRG.

**Acceptance Criteria:**
- [ ] BP.ML rebuild is exactly 4097 bytes and has the recorded SHA-256.
- [ ] CL.ML rebuild is exactly 2448 bytes and has the recorded SHA-256.

### TEST-NN-010

Run the archive verifier to extract all five D64 entries, validate BASIC structure and round trips, preserve original line bodies, and confirm manifests.

**Acceptance Criteria:**
- [ ] All five D64 entries compare byte for byte with combined/prg and all three BASIC sources retokenize exactly.
- [ ] The audit reports 131 preserved original BASIC line bodies, 36 added REM lines, 131/131 BASIC checks, 818/818 MLX checks, and complete SHA-256 agreement.

### TEST-NN-011

Inspect PDF page count, bookmarks, searchable text, preservation of the fourteen magazine pages, and the appended errata page.

**Acceptance Criteria:**
- [ ] The PDF has 15 pages and four bookmarks and the rendered first fourteen pages match the source edition.
- [ ] Page 15 accurately states the CL counter defect, disk-length omissions, color-byte correction, and OCR/checksum limits without layout defects.

### TEST-NN-012

On a compatible emulator or physical C64, run both engines, all demonstrations, save/load paths, invalid-input cases, and RUN/STOP behavior from the combined D64.

**Acceptance Criteria:**
- [ ] XOR, ENCODE, and DIPOLE complete from the D64 with expected visible results and no unhandled BASIC or drive error.
- [ ] Recognition, save/load, validation errors, engine switching, and RUN/STOP behavior conform to FR-NN-001 through FR-NN-012.
