; Combined edition: GPT reconstruction cross-checked against Grok assembly.
; XOR/ENCODE check PEEK(49153)=24 and PEEK(49157)=196.
; BP.ML - annotated reconstruction for ca65, 2026-09-16.
; Original neural-network engine: Kevin E. Martin / COMPUTE! Publications, 1990.
; Context: Future Computing: Neural Networks, February 1990, printed pp.34-39.
; Symbols and explanatory comments are reconstructed, not original author source.
; Instruction comments preserve original addresses and bytes for scan comparison.
; ABI descriptions come from the article. Internal routine roles/formulas are
; inferred from the instructions and BASIC ROM calls; no runtime test is claimed.
; Fixed-address reconstruction: embedded pointer immediates require origin $C000.
; Five-byte BASIC floats and allocated array index zero are intentional.
; Original publisher-disk length is retained; missing printed tail zeros are not added.
; See README.md for build verification, sources, workspace conventions and limits.

.segment "LOADADDR"
.word $C000
.segment "CODE"
.org $C000
PayloadStart:

        .setcpu "6502"

; ----------------------------------------------------------------------------
BASIC_INDEX     := $0022                        ; BASIC indirect work pointer.
BASIC_VARTAB    := $002D                        ; Start of BASIC scalar variables.
BASIC_ARYTAB    := $002F                        ; Start of BASIC arrays.
BASIC_STREND    := $0031                        ; End of BASIC arrays.
BASIC_FRETOP    := $0033                        ; Bottom of string storage.
BASIC_MEMSIZ    := $0037                        ; BASIC memory ceiling.
BASIC_TXTPTR    := $007A                        ; BASIC parser position; temporarily redirected to embedded names.
BASIC_PRINT_BUFFER:= $0100                      ; ASCII number buffer used by the BASIC ROM.
SavedTextPtr    := $02A7                        ; Saved caller parser position.
InputCount      := $02A9                        ; P1: number of input processing elements.
HiddenCount     := $02AA                        ; P2: hidden processing elements.
OutputCount     := $02AB                        ; P3: output processing elements.
PatternCount    := $02AC                        ; NP: number of training patterns.
RateOffset      := $02AD                        ; RA: relative to BASIC_VARTAB after initialization.
EpsilonOffset   := $02AF                        ; EP: stopping tolerance, relative to BASIC_VARTAB.
MomentumOffset  := $02B1                        ; MO: learning momentum, relative to BASIC_VARTAB.
O2Offset        := $02B3                        ; O2(0), relative to BASIC_ARYTAB after initialization.
O3Offset        := $02B5                        ; O3(0), relative to BASIC_ARYTAB.
E2Offset        := $02B7                        ; E2(0): hidden-layer deltas, relative to BASIC_ARYTAB.
E3Offset        := $02B9                        ; E3(0): output-layer deltas, relative to BASIC_ARYTAB.
PatternIndex    := $02BB                        ; Training pattern number; zero selects recognition scratch input.
W1Offset        := $02BF                        ; W1(0,0): input-to-hidden weights, relative to BASIC_ARYTAB.
W2Offset        := $02C1                        ; W2(0,0): hidden-to-output weights, relative to BASIC_ARYTAB.
M1Offset        := $02C3                        ; M1(0,0): previous W1 changes, relative to BASIC_ARYTAB.
M2Offset        := $02C5                        ; M2(0,0): previous W2 changes, relative to BASIC_ARYTAB.
TeacherOffset   := $02C7                        ; T(0,0), relative to BASIC_ARYTAB.
InputOffset     := $02C9                        ; IN(0,0), relative to BASIC_ARYTAB.
ErrorOffset     := $02CB                        ; E(0): per-pattern half squared error, relative to BASIC_ARYTAB.
WorkFloat       := $02CD                        ; Temporary five-byte float; also reused as pointer/count scratch.
TotalErrorOffset:= $02D2                        ; TE scalar, relative to BASIC_VARTAB.
TotalErrorPtr   := $02D4                        ; Absolute pointer to TE while training.
EpsilonPtr      := $02D6                        ; Absolute pointer to EP while training.
ErrorScratch    := $02D8                        ; Temporary teacher-output difference before squaring.
FilenameBuffer  := $02DD                        ; Up to 20 filename characters followed by comma and R or W.
ElementPtr      := $0334                        ; Absolute address of a BASIC five-byte array element.
IndexI          := $0336                        ; Outer loop index; reused by I/O loops.
IndexJ          := $0338                        ; Inner loop index; reused by I/O loops.
ShowError       := $03FC                        ; Nonzero enables printing of TE after each complete training pass.
MatrixBound     := $03FD                        ; First BASIC dimension upper bound, not element count.
BASIC_READY     := $A474                        ; Return to READY.
BASIC_RESET_STACK:= $A67A                       ; Reset BASIC stack.
BASIC_BREAK     := $A838                        ; BASIC break handling.
BASIC_PRINT_STRING:= $AB24                      ; Print string.
BASIC_EVAL_NUMBER:= $AD8A                       ; Evaluate numeric expression.
BASIC_REQUIRE_STRING:= $AD8F                    ; Require string value.
BASIC_EVAL      := $AD9E                        ; Evaluate expression.
BASIC_COMMA     := $AEFD                        ; Consume required comma.
BASIC_DIM       := $B081                        ; Dimension arrays.
BASIC_VARIABLE  := $B08B                        ; Find/create variable.
BASIC_TO_WORD   := $B1AA                        ; Convert FAC to integer.
BASIC_BAD_QUANTITY:= $B248                      ; Illegal quantity error.
BASIC_STRING_DATA:= $B6A6                       ; String length/pointer.
BASIC_GET_BYTE  := $B79E                        ; Parse byte into X.
BASIC_FAC_TO_BYTE:= $B7A1                       ; Convert FAC to byte.
FP_MEM_MINUS_FAC:= $B850                        ; FAC = memory minus FAC.
FP_ARG_MINUS_FAC:= $B853                        ; FAC = ARG minus FAC.
FP_ADD_MEM      := $B867                        ; FAC += memory.
FP_ADD_ARG      := $B86A                        ; FAC += ARG.
FP_MUL_MEM      := $BA28                        ; FAC *= memory.
FP_LOAD_ARG     := $BA8C                        ; Load ARG from memory.
FP_TIMES_TEN    := $BAE2                        ; FAC *= 10.
FP_MEM_DIV_FAC  := $BB0F                        ; FAC = memory / FAC.
FP_LOAD         := $BBA2                        ; Load FAC from memory.
FP_STORE        := $BBD4                        ; Store FAC at X/Y.
FP_ARG_TO_FAC   := $BBFC                        ; Copy ARG into FAC.
FP_FAC_TO_ARG   := $BC0C                        ; Copy rounded FAC into ARG.
FP_FROM_BYTE    := $BC3C                        ; Convert A to FAC.
FP_COMPARE      := $BC5B                        ; Compare FAC with memory.
FP_INT          := $BCCC                        ; Integer part of FAC.
FP_FORMAT       := $BDDD                        ; Format FAC as ASCII.
FP_EXP          := $BFED                        ; Exponential of FAC.
FP_RND          := $E097                        ; BASIC random function.
K_SETLFS        := $FFBA                        ; Set file/device/channel.
K_SETNAM        := $FFBD                        ; Set filename.
K_OPEN          := $FFC0                        ; Open file.
K_CLOSE         := $FFC3                        ; Close file.
K_CHKIN         := $FFC6                        ; Select input.
K_CHKOUT        := $FFC9                        ; Select output.
K_CLRCHN        := $FFCC                        ; Restore default channels.
K_CHRIN         := $FFCF                        ; Read byte.
K_CHROUT        := $FFD2                        ; Write byte.
K_STOP          := $FFE1                        ; Poll RUN/STOP.
K_CLALL         := $FFE7                        ; Close all channels.
; ----------------------------------------------------------------------------
; SYS 49152,p1,p2,p3,np,rate,momentum,epsilon. Article: February pp.35-36.
BP_Init:
        jmp     InitializeNetwork               ; C000 4C 18 C0

; ----------------------------------------------------------------------------
; SYS 49155,pattern. Results are left in O2() and O3(). February p.36.
BP_Recognize:
        jmp     RecognizeString                 ; C003 4C 4D C4

; ----------------------------------------------------------------------------
; Extra vector, not described in the article: parse a stored pattern number and train it.
BP_TrainPattern:
        jmp     TrainSelectedPattern            ; C006 4C FE C6

; ----------------------------------------------------------------------------
; Extra vector, not described in the article: one complete training pass and TE update.
BP_TrainEpoch:
        jmp     TrainEpoch                      ; C009 4C 4B CA

; ----------------------------------------------------------------------------
; SYS 49164,show_error. Repeat training passes until TE <= EP or RUN/STOP.
BP_Learn:
        jmp     LearnUntilTolerance             ; C00C 4C B0 CA

; ----------------------------------------------------------------------------
; SYS 49167,number,input_string,teacher_string. February p.36.
BP_DefinePair:
        jmp     DefineTrainingPair              ; C00F 4C 04 CB

; ----------------------------------------------------------------------------
; SYS 49170,filename. Save dimensions, parameters, weights, momentum and patterns.
BP_Save:
        jmp     SaveNetwork                     ; C012 4C F7 CB

; ----------------------------------------------------------------------------
; SYS 49173,filename. Recreate BASIC storage, then restore the saved network.
BP_Load:
        jmp     LoadNetwork                     ; C015 4C 63 CD

; ----------------------------------------------------------------------------
; Parse four byte-sized dimensions. Store rate, momentum and epsilon through BASIC scalar lookup.
InitializeNetwork:
        jsr     BASIC_COMMA                     ; C018 20 FD AE
        jsr     BASIC_GET_BYTE                  ; C01B 20 9E B7
        stx     InputCount                      ; C01E 8E A9 02
        jsr     BASIC_COMMA                     ; C021 20 FD AE
        jsr     BASIC_GET_BYTE                  ; C024 20 9E B7
        stx     HiddenCount                     ; C027 8E AA 02
        jsr     BASIC_COMMA                     ; C02A 20 FD AE
        jsr     BASIC_GET_BYTE                  ; C02D 20 9E B7
        stx     OutputCount                     ; C030 8E AB 02
        jsr     BASIC_COMMA                     ; C033 20 FD AE
        jsr     BASIC_GET_BYTE                  ; C036 20 9E B7
        stx     PatternCount                    ; C039 8E AC 02
        jsr     BASIC_COMMA                     ; C03C 20 FD AE
        lda     BASIC_TXTPTR                    ; C03F A5 7A
        sta     SavedTextPtr                    ; C041 8D A7 02
        lda     BASIC_TXTPTR+1                  ; C044 A5 7B
        sta     SavedTextPtr+1                  ; C046 8D A8 02
        lda     #$8B                            ; C049 A9 8B
        sta     BASIC_TXTPTR                    ; C04B 85 7A
        lda     #$CF                            ; C04D A9 CF
        sta     BASIC_TXTPTR+1                  ; C04F 85 7B
        jsr     BASIC_VARIABLE                  ; C051 20 8B B0
        sta     RateOffset                      ; C054 8D AD 02
        sty     RateOffset+1                    ; C057 8C AE 02
        lda     SavedTextPtr                    ; C05A AD A7 02
        sta     BASIC_TXTPTR                    ; C05D 85 7A
        lda     SavedTextPtr+1                  ; C05F AD A8 02
        sta     BASIC_TXTPTR+1                  ; C062 85 7B
        jsr     BASIC_EVAL_NUMBER               ; C064 20 8A AD
        ldx     RateOffset                      ; C067 AE AD 02
        ldy     RateOffset+1                    ; C06A AC AE 02
        jsr     FP_STORE                        ; C06D 20 D4 BB
        jsr     BASIC_COMMA                     ; C070 20 FD AE
        lda     BASIC_TXTPTR                    ; C073 A5 7A
        sta     SavedTextPtr                    ; C075 8D A7 02
        lda     BASIC_TXTPTR+1                  ; C078 A5 7B
        sta     SavedTextPtr+1                  ; C07A 8D A8 02
        lda     #$8E                            ; C07D A9 8E
        sta     BASIC_TXTPTR                    ; C07F 85 7A
        lda     #$CF                            ; C081 A9 CF
        sta     BASIC_TXTPTR+1                  ; C083 85 7B
        jsr     BASIC_VARIABLE                  ; C085 20 8B B0
        sta     MomentumOffset                  ; C088 8D B1 02
        sty     MomentumOffset+1                ; C08B 8C B2 02
        lda     SavedTextPtr                    ; C08E AD A7 02
        sta     BASIC_TXTPTR                    ; C091 85 7A
        lda     SavedTextPtr+1                  ; C093 AD A8 02
        sta     BASIC_TXTPTR+1                  ; C096 85 7B
        jsr     BASIC_EVAL_NUMBER               ; C098 20 8A AD
        ldx     MomentumOffset                  ; C09B AE B1 02
        ldy     MomentumOffset+1                ; C09E AC B2 02
        jsr     FP_STORE                        ; C0A1 20 D4 BB
        jsr     BASIC_COMMA                     ; C0A4 20 FD AE
        lda     BASIC_TXTPTR                    ; C0A7 A5 7A
        sta     SavedTextPtr                    ; C0A9 8D A7 02
        lda     BASIC_TXTPTR+1                  ; C0AC A5 7B
        sta     SavedTextPtr+1                  ; C0AE 8D A8 02
        lda     #$91                            ; C0B1 A9 91
        sta     BASIC_TXTPTR                    ; C0B3 85 7A
        lda     #$CF                            ; C0B5 A9 CF
        sta     BASIC_TXTPTR+1                  ; C0B7 85 7B
        jsr     BASIC_VARIABLE                  ; C0B9 20 8B B0
        sta     EpsilonOffset                   ; C0BC 8D AF 02
        sty     EpsilonOffset+1                 ; C0BF 8C B0 02
        lda     SavedTextPtr                    ; C0C2 AD A7 02
        sta     BASIC_TXTPTR                    ; C0C5 85 7A
        lda     SavedTextPtr+1                  ; C0C7 AD A8 02
        sta     BASIC_TXTPTR+1                  ; C0CA 85 7B
        jsr     BASIC_EVAL_NUMBER               ; C0CC 20 8A AD
        ldx     EpsilonOffset                   ; C0CF AE AF 02
        ldy     EpsilonOffset+1                 ; C0D2 AC B0 02
        jsr     FP_STORE                        ; C0D5 20 D4 BB
        lda     BASIC_TXTPTR                    ; C0D8 A5 7A
        sta     SavedTextPtr                    ; C0DA 8D A7 02
        lda     BASIC_TXTPTR+1                  ; C0DD A5 7B
        sta     SavedTextPtr+1                  ; C0DF 8D A8 02
; Create P1/P2/P3/NP/TE and DIM eleven arrays using the embedded expression list.
CreateBasicStorage:
        lda     #$94                            ; C0E2 A9 94
        sta     BASIC_TXTPTR                    ; C0E4 85 7A
        lda     #$CF                            ; C0E6 A9 CF
        sta     BASIC_TXTPTR+1                  ; C0E8 85 7B
        jsr     BASIC_VARIABLE                  ; C0EA 20 8B B0
        pha                                     ; C0ED 48
        tya                                     ; C0EE 98
        pha                                     ; C0EF 48
        lda     InputCount                      ; C0F0 AD A9 02
        jsr     FP_FROM_BYTE                    ; C0F3 20 3C BC
        pla                                     ; C0F6 68
        tay                                     ; C0F7 A8
        pla                                     ; C0F8 68
        tax                                     ; C0F9 AA
        jsr     FP_STORE                        ; C0FA 20 D4 BB
        lda     #$97                            ; C0FD A9 97
        sta     BASIC_TXTPTR                    ; C0FF 85 7A
        lda     #$CF                            ; C101 A9 CF
        sta     BASIC_TXTPTR+1                  ; C103 85 7B
        jsr     BASIC_VARIABLE                  ; C105 20 8B B0
        pha                                     ; C108 48
        tya                                     ; C109 98
        pha                                     ; C10A 48
        lda     HiddenCount                     ; C10B AD AA 02
        jsr     FP_FROM_BYTE                    ; C10E 20 3C BC
        pla                                     ; C111 68
        tay                                     ; C112 A8
        pla                                     ; C113 68
        tax                                     ; C114 AA
        jsr     FP_STORE                        ; C115 20 D4 BB
        lda     #$9A                            ; C118 A9 9A
        sta     BASIC_TXTPTR                    ; C11A 85 7A
        lda     #$CF                            ; C11C A9 CF
        sta     BASIC_TXTPTR+1                  ; C11E 85 7B
        jsr     BASIC_VARIABLE                  ; C120 20 8B B0
        pha                                     ; C123 48
        tya                                     ; C124 98
        pha                                     ; C125 48
        lda     OutputCount                     ; C126 AD AB 02
        jsr     FP_FROM_BYTE                    ; C129 20 3C BC
        pla                                     ; C12C 68
        tay                                     ; C12D A8
        pla                                     ; C12E 68
        tax                                     ; C12F AA
        jsr     FP_STORE                        ; C130 20 D4 BB
        lda     #$9D                            ; C133 A9 9D
        sta     BASIC_TXTPTR                    ; C135 85 7A
        lda     #$CF                            ; C137 A9 CF
        sta     BASIC_TXTPTR+1                  ; C139 85 7B
        jsr     BASIC_VARIABLE                  ; C13B 20 8B B0
        pha                                     ; C13E 48
        tya                                     ; C13F 98
        pha                                     ; C140 48
        lda     PatternCount                    ; C141 AD AC 02
        jsr     FP_FROM_BYTE                    ; C144 20 3C BC
        pla                                     ; C147 68
        tay                                     ; C148 A8
        pla                                     ; C149 68
        tax                                     ; C14A AA
        jsr     FP_STORE                        ; C14B 20 D4 BB
        lda     #$FC                            ; C14E A9 FC
        sta     BASIC_TXTPTR                    ; C150 85 7A
        lda     #$CF                            ; C152 A9 CF
        sta     BASIC_TXTPTR+1                  ; C154 85 7B
        jsr     BASIC_VARIABLE                  ; C156 20 8B B0
        sta     TotalErrorOffset                ; C159 8D D2 02
        sty     TotalErrorOffset+1              ; C15C 8C D3 02
        lda     #$2E                            ; C15F A9 2E
        sta     BASIC_TXTPTR                    ; C161 85 7A
        lda     #$CF                            ; C163 A9 CF
        sta     BASIC_TXTPTR+1                  ; C165 85 7B
        lda     DimExpressions                  ; C167 AD 2E CF
        jsr     BASIC_DIM                       ; C16A 20 81 B0
        lda     #$A6                            ; C16D A9 A6
        sta     BASIC_TXTPTR                    ; C16F 85 7A
        lda     #$CF                            ; C171 A9 CF
        sta     BASIC_TXTPTR+1                  ; C173 85 7B
        jsr     BASIC_VARIABLE                  ; C175 20 8B B0
        sta     O2Offset                        ; C178 8D B3 02
        sty     O2Offset+1                      ; C17B 8C B4 02
; O2(0)=1 and O3(0)=1. BASIC arrays include index zero; active PEs start at index one.
SetHiddenBias:
        lda     #$01                            ; C17E A9 01
        jsr     FP_FROM_BYTE                    ; C180 20 3C BC
        ldx     O2Offset                        ; C183 AE B3 02
        ldy     O2Offset+1                      ; C186 AC B4 02
        jsr     FP_STORE                        ; C189 20 D4 BB
        lda     #$AC                            ; C18C A9 AC
        sta     BASIC_TXTPTR                    ; C18E 85 7A
        lda     #$CF                            ; C190 A9 CF
        sta     BASIC_TXTPTR+1                  ; C192 85 7B
        jsr     BASIC_VARIABLE                  ; C194 20 8B B0
        sta     O3Offset                        ; C197 8D B5 02
        sty     O3Offset+1                      ; C19A 8C B6 02
        lda     #$01                            ; C19D A9 01
        jsr     FP_FROM_BYTE                    ; C19F 20 3C BC
        ldx     O3Offset                        ; C1A2 AE B5 02
        ldy     O3Offset+1                      ; C1A5 AC B6 02
        jsr     FP_STORE                        ; C1A8 20 D4 BB
        lda     #$00                            ; C1AB A9 00
        sta     IndexI                          ; C1AD 8D 36 03
        lda     #$B2                            ; C1B0 A9 B2
        sta     BASIC_TXTPTR                    ; C1B2 85 7A
        lda     #$CF                            ; C1B4 A9 CF
        sta     BASIC_TXTPTR+1                  ; C1B6 85 7B
        jsr     BASIC_VARIABLE                  ; C1B8 20 8B B0
        sta     InputOffset                     ; C1BB 8D C9 02
        sta     ElementPtr                      ; C1BE 8D 34 03
        sty     InputOffset+1                   ; C1C1 8C CA 02
        sty     ElementPtr+1                    ; C1C4 8C 35 03
; Set IN(0,pattern)=1, including scratch pattern zero, for bias-weight multiplication.
SetInputBiases:
        lda     #$01                            ; C1C7 A9 01
        jsr     FP_FROM_BYTE                    ; C1C9 20 3C BC
        ldy     ElementPtr+1                    ; C1CC AC 35 03
        ldx     ElementPtr                      ; C1CF AE 34 03
        jsr     FP_STORE                        ; C1D2 20 D4 BB
        inc     IndexI                          ; C1D5 EE 36 03
        lda     PatternCount                    ; C1D8 AD AC 02
        cmp     IndexI                          ; C1DB CD 36 03
        bcc     InitializeW1                    ; C1DE 90 23
        lda     #$00                            ; C1E0 A9 00
        sta     IndexJ                          ; C1E2 8D 38 03
LC1E5:
        lda     ElementPtr                      ; C1E5 AD 34 03
        clc                                     ; C1E8 18
        adc     #$05                            ; C1E9 69 05
        sta     ElementPtr                      ; C1EB 8D 34 03
        lda     ElementPtr+1                    ; C1EE AD 35 03
        adc     #$00                            ; C1F1 69 00
        sta     ElementPtr+1                    ; C1F3 8D 35 03
        inc     IndexJ                          ; C1F6 EE 38 03
        lda     InputCount                      ; C1F9 AD A9 02
        cmp     IndexJ                          ; C1FC CD 38 03
        bcs     LC1E5                           ; C1FF B0 E4
        bcc     SetInputBiases                  ; C201 90 C4
; Initialize all allocated W1 entries, including index-zero slots.
InitializeW1:
        lda     #$00                            ; C203 A9 00
        sta     IndexI                          ; C205 8D 36 03
        sta     IndexJ                          ; C208 8D 38 03
        lda     #$BA                            ; C20B A9 BA
        sta     BASIC_TXTPTR                    ; C20D 85 7A
        lda     #$CF                            ; C20F A9 CF
        sta     BASIC_TXTPTR+1                  ; C211 85 7B
        jsr     BASIC_VARIABLE                  ; C213 20 8B B0
        sta     W1Offset                        ; C216 8D BF 02
        sta     ElementPtr                      ; C219 8D 34 03
        sty     W1Offset+1                      ; C21C 8C C0 02
        sty     ElementPtr+1                    ; C21F 8C 35 03
; Observed formula: 10*RND(1)-5, using BASIC five-byte floating point.
RandomizeW1Element:
        lda     #$01                            ; C222 A9 01
        jsr     FP_FROM_BYTE                    ; C224 20 3C BC
        jsr     FP_RND                          ; C227 20 97 E0
        jsr     FP_TIMES_TEN                    ; C22A 20 E2 BA
        jsr     FP_FAC_TO_ARG                   ; C22D 20 0C BC
        lda     #$05                            ; C230 A9 05
        jsr     FP_FROM_BYTE                    ; C232 20 3C BC
        jsr     FP_ARG_MINUS_FAC                ; C235 20 53 B8
        ldy     ElementPtr+1                    ; C238 AC 35 03
        ldx     ElementPtr                      ; C23B AE 34 03
        jsr     FP_STORE                        ; C23E 20 D4 BB
        inc     IndexI                          ; C241 EE 36 03
        lda     ElementPtr                      ; C244 AD 34 03
        clc                                     ; C247 18
        adc     #$05                            ; C248 69 05
        sta     ElementPtr                      ; C24A 8D 34 03
        lda     ElementPtr+1                    ; C24D AD 35 03
        adc     #$00                            ; C250 69 00
        sta     ElementPtr+1                    ; C252 8D 35 03
        lda     HiddenCount                     ; C255 AD AA 02
        cmp     IndexI                          ; C258 CD 36 03
        bcs     RandomizeW1Element              ; C25B B0 C5
        inc     IndexJ                          ; C25D EE 38 03
        lda     InputCount                      ; C260 AD A9 02
        cmp     IndexJ                          ; C263 CD 38 03
        bcc     InitializeW2                    ; C266 90 08
        lda     #$00                            ; C268 A9 00
        sta     IndexI                          ; C26A 8D 36 03
        jmp     RandomizeW1Element              ; C26D 4C 22 C2

; ----------------------------------------------------------------------------
; Initialize the second weight matrix with the same random distribution.
InitializeW2:
        lda     #$00                            ; C270 A9 00
        sta     IndexI                          ; C272 8D 36 03
        sta     IndexJ                          ; C275 8D 38 03
        lda     #$C2                            ; C278 A9 C2
        sta     BASIC_TXTPTR                    ; C27A 85 7A
        lda     #$CF                            ; C27C A9 CF
        sta     BASIC_TXTPTR+1                  ; C27E 85 7B
        jsr     BASIC_VARIABLE                  ; C280 20 8B B0
        sta     W2Offset                        ; C283 8D C1 02
        sta     ElementPtr                      ; C286 8D 34 03
        sty     W2Offset+1                      ; C289 8C C2 02
        sty     ElementPtr+1                    ; C28C 8C 35 03
LC28F:
        lda     #$01                            ; C28F A9 01
        jsr     FP_FROM_BYTE                    ; C291 20 3C BC
        jsr     FP_RND                          ; C294 20 97 E0
        jsr     FP_TIMES_TEN                    ; C297 20 E2 BA
        jsr     FP_FAC_TO_ARG                   ; C29A 20 0C BC
        lda     #$05                            ; C29D A9 05
        jsr     FP_FROM_BYTE                    ; C29F 20 3C BC
        jsr     FP_ARG_MINUS_FAC                ; C2A2 20 53 B8
        ldy     ElementPtr+1                    ; C2A5 AC 35 03
        ldx     ElementPtr                      ; C2A8 AE 34 03
        jsr     FP_STORE                        ; C2AB 20 D4 BB
        inc     IndexI                          ; C2AE EE 36 03
        lda     ElementPtr                      ; C2B1 AD 34 03
        clc                                     ; C2B4 18
        adc     #$05                            ; C2B5 69 05
        sta     ElementPtr                      ; C2B7 8D 34 03
        lda     ElementPtr+1                    ; C2BA AD 35 03
        adc     #$00                            ; C2BD 69 00
        sta     ElementPtr+1                    ; C2BF 8D 35 03
        lda     OutputCount                     ; C2C2 AD AB 02
        cmp     IndexI                          ; C2C5 CD 36 03
        bcs     LC28F                           ; C2C8 B0 C5
        inc     IndexJ                          ; C2CA EE 38 03
        lda     HiddenCount                     ; C2CD AD AA 02
        cmp     IndexJ                          ; C2D0 CD 38 03
        bcc     FindRemainingArrays             ; C2D3 90 08
        lda     #$00                            ; C2D5 A9 00
        sta     IndexI                          ; C2D7 8D 36 03
        jmp     LC28F                           ; C2DA 4C 8F C2

; ----------------------------------------------------------------------------
; Cache the error, teacher and momentum array addresses after DIM.
FindRemainingArrays:
        lda     #$CA                            ; C2DD A9 CA
        sta     BASIC_TXTPTR                    ; C2DF 85 7A
        lda     #$CF                            ; C2E1 A9 CF
        sta     BASIC_TXTPTR+1                  ; C2E3 85 7B
        jsr     BASIC_VARIABLE                  ; C2E5 20 8B B0
        sta     E2Offset                        ; C2E8 8D B7 02
        sty     E2Offset+1                      ; C2EB 8C B8 02
        lda     #$D0                            ; C2EE A9 D0
        sta     BASIC_TXTPTR                    ; C2F0 85 7A
        lda     #$CF                            ; C2F2 A9 CF
        sta     BASIC_TXTPTR+1                  ; C2F4 85 7B
        jsr     BASIC_VARIABLE                  ; C2F6 20 8B B0
        sta     E3Offset                        ; C2F9 8D B9 02
        sty     E3Offset+1                      ; C2FC 8C BA 02
        lda     #$D6                            ; C2FF A9 D6
        sta     BASIC_TXTPTR                    ; C301 85 7A
        lda     #$CF                            ; C303 A9 CF
        sta     BASIC_TXTPTR+1                  ; C305 85 7B
        jsr     BASIC_VARIABLE                  ; C307 20 8B B0
        sta     TeacherOffset                   ; C30A 8D C7 02
        sty     TeacherOffset+1                 ; C30D 8C C8 02
        lda     #$DD                            ; C310 A9 DD
        sta     BASIC_TXTPTR                    ; C312 85 7A
        lda     #$CF                            ; C314 A9 CF
        sta     BASIC_TXTPTR+1                  ; C316 85 7B
        jsr     BASIC_VARIABLE                  ; C318 20 8B B0
        sta     M1Offset                        ; C31B 8D C3 02
        sty     M1Offset+1                      ; C31E 8C C4 02
        lda     #$E5                            ; C321 A9 E5
        sta     BASIC_TXTPTR                    ; C323 85 7A
        lda     #$CF                            ; C325 A9 CF
        sta     BASIC_TXTPTR+1                  ; C327 85 7B
        jsr     BASIC_VARIABLE                  ; C329 20 8B B0
        sta     M2Offset                        ; C32C 8D C5 02
        sty     M2Offset+1                      ; C32F 8C C6 02
        lda     #$ED                            ; C332 A9 ED
        sta     BASIC_TXTPTR                    ; C334 85 7A
        lda     #$CF                            ; C336 A9 CF
        sta     BASIC_TXTPTR+1                  ; C338 85 7B
        jsr     BASIC_VARIABLE                  ; C33A 20 8B B0
        sta     ErrorOffset                     ; C33D 8D CB 02
        sty     ErrorOffset+1                   ; C340 8C CC 02
; Convert cached array pointers to ARYTAB-relative offsets and scalar pointers to VARTAB-relative offsets.
MakeOffsetsRelative:
        lda     O2Offset                        ; C343 AD B3 02
        sec                                     ; C346 38
        sbc     BASIC_ARYTAB                    ; C347 E5 2F
        sta     O2Offset                        ; C349 8D B3 02
        lda     O2Offset+1                      ; C34C AD B4 02
        sbc     BASIC_ARYTAB+1                  ; C34F E5 30
        sta     O2Offset+1                      ; C351 8D B4 02
        lda     O3Offset                        ; C354 AD B5 02
        sec                                     ; C357 38
        sbc     BASIC_ARYTAB                    ; C358 E5 2F
        sta     O3Offset                        ; C35A 8D B5 02
        lda     O3Offset+1                      ; C35D AD B6 02
        sbc     BASIC_ARYTAB+1                  ; C360 E5 30
        sta     O3Offset+1                      ; C362 8D B6 02
        lda     E2Offset                        ; C365 AD B7 02
        sec                                     ; C368 38
        sbc     BASIC_ARYTAB                    ; C369 E5 2F
        sta     E2Offset                        ; C36B 8D B7 02
        lda     E2Offset+1                      ; C36E AD B8 02
        sbc     BASIC_ARYTAB+1                  ; C371 E5 30
        sta     E2Offset+1                      ; C373 8D B8 02
        lda     E3Offset                        ; C376 AD B9 02
        sec                                     ; C379 38
        sbc     BASIC_ARYTAB                    ; C37A E5 2F
        sta     E3Offset                        ; C37C 8D B9 02
        lda     E3Offset+1                      ; C37F AD BA 02
        sbc     BASIC_ARYTAB+1                  ; C382 E5 30
        sta     E3Offset+1                      ; C384 8D BA 02
        lda     W1Offset                        ; C387 AD BF 02
        sec                                     ; C38A 38
        sbc     BASIC_ARYTAB                    ; C38B E5 2F
        sta     W1Offset                        ; C38D 8D BF 02
        lda     W1Offset+1                      ; C390 AD C0 02
        sbc     BASIC_ARYTAB+1                  ; C393 E5 30
        sta     W1Offset+1                      ; C395 8D C0 02
        lda     W2Offset                        ; C398 AD C1 02
        sec                                     ; C39B 38
        sbc     BASIC_ARYTAB                    ; C39C E5 2F
        sta     W2Offset                        ; C39E 8D C1 02
        lda     W2Offset+1                      ; C3A1 AD C2 02
        sbc     BASIC_ARYTAB+1                  ; C3A4 E5 30
        sta     W2Offset+1                      ; C3A6 8D C2 02
        lda     M1Offset                        ; C3A9 AD C3 02
        sec                                     ; C3AC 38
        sbc     BASIC_ARYTAB                    ; C3AD E5 2F
        sta     M1Offset                        ; C3AF 8D C3 02
        lda     M1Offset+1                      ; C3B2 AD C4 02
        sbc     BASIC_ARYTAB+1                  ; C3B5 E5 30
        sta     M1Offset+1                      ; C3B7 8D C4 02
        lda     M2Offset                        ; C3BA AD C5 02
        sec                                     ; C3BD 38
        sbc     BASIC_ARYTAB                    ; C3BE E5 2F
        sta     M2Offset                        ; C3C0 8D C5 02
        lda     M2Offset+1                      ; C3C3 AD C6 02
        sbc     BASIC_ARYTAB+1                  ; C3C6 E5 30
        sta     M2Offset+1                      ; C3C8 8D C6 02
        lda     TeacherOffset                   ; C3CB AD C7 02
        sec                                     ; C3CE 38
        sbc     BASIC_ARYTAB                    ; C3CF E5 2F
        sta     TeacherOffset                   ; C3D1 8D C7 02
        lda     TeacherOffset+1                 ; C3D4 AD C8 02
        sbc     BASIC_ARYTAB+1                  ; C3D7 E5 30
        sta     TeacherOffset+1                 ; C3D9 8D C8 02
        lda     InputOffset                     ; C3DC AD C9 02
        sec                                     ; C3DF 38
        sbc     BASIC_ARYTAB                    ; C3E0 E5 2F
        sta     InputOffset                     ; C3E2 8D C9 02
        lda     InputOffset+1                   ; C3E5 AD CA 02
        sbc     BASIC_ARYTAB+1                  ; C3E8 E5 30
        sta     InputOffset+1                   ; C3EA 8D CA 02
        lda     ErrorOffset                     ; C3ED AD CB 02
        sec                                     ; C3F0 38
        sbc     BASIC_ARYTAB                    ; C3F1 E5 2F
        sta     ErrorOffset                     ; C3F3 8D CB 02
        lda     ErrorOffset+1                   ; C3F6 AD CC 02
        sbc     BASIC_ARYTAB+1                  ; C3F9 E5 30
        sta     ErrorOffset+1                   ; C3FB 8D CC 02
        lda     RateOffset                      ; C3FE AD AD 02
        sec                                     ; C401 38
        sbc     BASIC_VARTAB                    ; C402 E5 2D
        sta     RateOffset                      ; C404 8D AD 02
        lda     RateOffset+1                    ; C407 AD AE 02
        sbc     BASIC_VARTAB+1                  ; C40A E5 2E
        sta     RateOffset+1                    ; C40C 8D AE 02
        lda     MomentumOffset                  ; C40F AD B1 02
        sec                                     ; C412 38
        sbc     BASIC_VARTAB                    ; C413 E5 2D
        sta     MomentumOffset                  ; C415 8D B1 02
        lda     MomentumOffset+1                ; C418 AD B2 02
        sbc     BASIC_VARTAB+1                  ; C41B E5 2E
        sta     MomentumOffset+1                ; C41D 8D B2 02
        lda     EpsilonOffset                   ; C420 AD AF 02
        sec                                     ; C423 38
        sbc     BASIC_VARTAB                    ; C424 E5 2D
        sta     EpsilonOffset                   ; C426 8D AF 02
        lda     EpsilonOffset+1                 ; C429 AD B0 02
        sbc     BASIC_VARTAB+1                  ; C42C E5 2E
        sta     EpsilonOffset+1                 ; C42E 8D B0 02
        lda     TotalErrorOffset                ; C431 AD D2 02
        sec                                     ; C434 38
        sbc     BASIC_VARTAB                    ; C435 E5 2D
        sta     TotalErrorOffset                ; C437 8D D2 02
        lda     TotalErrorOffset+1              ; C43A AD D3 02
        sbc     BASIC_VARTAB+1                  ; C43D E5 2E
        sta     TotalErrorOffset+1              ; C43F 8D D3 02
        lda     SavedTextPtr                    ; C442 AD A7 02
        sta     BASIC_TXTPTR                    ; C445 85 7A
        lda     SavedTextPtr+1                  ; C447 AD A8 02
        sta     BASIC_TXTPTR+1                  ; C44A 85 7B
        rts                                     ; C44C 60

; ----------------------------------------------------------------------------
; Import the supplied string into IN(:,0), then perform the forward pass on scratch pattern zero.
RecognizeString:
        lda     #$00                            ; C44D A9 00
        sta     PatternIndex                    ; C44F 8D BB 02
        jsr     ReadInputString                 ; C452 20 1C CB
        beq     ForwardPass                     ; C455 F0 18
; Parse and range-check an existing pattern number in 1..NP.
SelectStoredPattern:
        jsr     BASIC_COMMA                     ; C457 20 FD AE
        jsr     BASIC_GET_BYTE                  ; C45A 20 9E B7
        stx     PatternIndex                    ; C45D 8E BB 02
        cpx     #$00                            ; C460 E0 00
        beq     LC46C                           ; C462 F0 08
        lda     PatternCount                    ; C464 AD AC 02
        cmp     PatternIndex                    ; C467 CD BB 02
        bcs     ForwardPass                     ; C46A B0 03
LC46C:
        jmp     BASIC_BAD_QUANTITY              ; C46C 4C 48 B2

; ----------------------------------------------------------------------------
; Compute hidden outputs, output outputs, and E(pattern). Training also enters here directly.
ForwardPass:
        lda     #$01                            ; C46F A9 01
        sta     IndexI                          ; C471 8D 36 03
; Accumulate W1(hidden,input)*IN(input,pattern), including input zero for bias.
HiddenNeuron:
        lda     #$00                            ; C474 A9 00
        sta     IndexJ                          ; C476 8D 38 03
        jsr     FP_FROM_BYTE                    ; C479 20 3C BC
LC47C:
        ldx     #$CD                            ; C47C A2 CD
        ldy     #$02                            ; C47E A0 02
        jsr     FP_STORE                        ; C480 20 D4 BB
        lda     W1Offset                        ; C483 AD BF 02
        clc                                     ; C486 18
        adc     BASIC_ARYTAB                    ; C487 65 2F
        sta     ElementPtr                      ; C489 8D 34 03
        lda     W1Offset+1                      ; C48C AD C0 02
        adc     BASIC_ARYTAB+1                  ; C48F 65 30
        sta     ElementPtr+1                    ; C491 8D 35 03
        ldx     IndexJ                          ; C494 AE 38 03
        ldy     IndexI                          ; C497 AC 36 03
        lda     HiddenCount                     ; C49A AD AA 02
        jsr     IndexMatrix                     ; C49D 20 AA C6
        lda     ElementPtr                      ; C4A0 AD 34 03
        ldy     ElementPtr+1                    ; C4A3 AC 35 03
        jsr     FP_LOAD                         ; C4A6 20 A2 BB
        lda     InputOffset                     ; C4A9 AD C9 02
        clc                                     ; C4AC 18
        adc     BASIC_ARYTAB                    ; C4AD 65 2F
        sta     ElementPtr                      ; C4AF 8D 34 03
        lda     InputOffset+1                   ; C4B2 AD CA 02
        adc     BASIC_ARYTAB+1                  ; C4B5 65 30
        sta     ElementPtr+1                    ; C4B7 8D 35 03
        ldx     PatternIndex                    ; C4BA AE BB 02
        ldy     IndexJ                          ; C4BD AC 38 03
        lda     InputCount                      ; C4C0 AD A9 02
        jsr     IndexMatrix                     ; C4C3 20 AA C6
        lda     ElementPtr                      ; C4C6 AD 34 03
        ldy     ElementPtr+1                    ; C4C9 AC 35 03
        jsr     FP_MUL_MEM                      ; C4CC 20 28 BA
        lda     #$CD                            ; C4CF A9 CD
        ldy     #$02                            ; C4D1 A0 02
        jsr     FP_ADD_MEM                      ; C4D3 20 67 B8
        inc     IndexJ                          ; C4D6 EE 38 03
        lda     InputCount                      ; C4D9 AD A9 02
        cmp     IndexJ                          ; C4DC CD 38 03
        bcs     LC47C                           ; C4DF B0 9B
; Compute 1/(1+EXP(-sum)) with the embedded floating-point zero and one constants.
HiddenSigmoid:
        lda     #$F2                            ; C4E1 A9 F2
        ldy     #$CF                            ; C4E3 A0 CF
        jsr     FP_MEM_MINUS_FAC                ; C4E5 20 50 B8
        jsr     FP_EXP                          ; C4E8 20 ED BF
        jsr     FP_FAC_TO_ARG                   ; C4EB 20 0C BC
        lda     #$01                            ; C4EE A9 01
        jsr     FP_FROM_BYTE                    ; C4F0 20 3C BC
        jsr     FP_ADD_ARG                      ; C4F3 20 6A B8
        lda     #$F7                            ; C4F6 A9 F7
        ldy     #$CF                            ; C4F8 A0 CF
        jsr     FP_MEM_DIV_FAC                  ; C4FA 20 0F BB
        lda     O2Offset                        ; C4FD AD B3 02
        clc                                     ; C500 18
        adc     BASIC_ARYTAB                    ; C501 65 2F
        sta     ElementPtr                      ; C503 8D 34 03
        lda     O2Offset+1                      ; C506 AD B4 02
        adc     BASIC_ARYTAB+1                  ; C509 65 30
        sta     ElementPtr+1                    ; C50B 8D 35 03
        lda     IndexI                          ; C50E AD 36 03
        jsr     IndexVector                     ; C511 20 90 C6
        ldx     ElementPtr                      ; C514 AE 34 03
        ldy     ElementPtr+1                    ; C517 AC 35 03
        jsr     FP_STORE                        ; C51A 20 D4 BB
        inc     IndexI                          ; C51D EE 36 03
        lda     HiddenCount                     ; C520 AD AA 02
        cmp     IndexI                          ; C523 CD 36 03
        bcc     OutputLayer                     ; C526 90 03
        jmp     HiddenNeuron                    ; C528 4C 74 C4

; ----------------------------------------------------------------------------
; Repeat the weighted sum and sigmoid using W2 and O2, including O2(0)=1.
OutputLayer:
        lda     #$01                            ; C52B A9 01
        sta     IndexI                          ; C52D 8D 36 03
LC530:
        lda     #$00                            ; C530 A9 00
        sta     IndexJ                          ; C532 8D 38 03
        jsr     FP_FROM_BYTE                    ; C535 20 3C BC
LC538:
        ldx     #$CD                            ; C538 A2 CD
        ldy     #$02                            ; C53A A0 02
        jsr     FP_STORE                        ; C53C 20 D4 BB
        lda     W2Offset                        ; C53F AD C1 02
        clc                                     ; C542 18
        adc     BASIC_ARYTAB                    ; C543 65 2F
        sta     ElementPtr                      ; C545 8D 34 03
        lda     W2Offset+1                      ; C548 AD C2 02
        adc     BASIC_ARYTAB+1                  ; C54B 65 30
        sta     ElementPtr+1                    ; C54D 8D 35 03
        ldx     IndexJ                          ; C550 AE 38 03
        ldy     IndexI                          ; C553 AC 36 03
        lda     OutputCount                     ; C556 AD AB 02
        jsr     IndexMatrix                     ; C559 20 AA C6
        lda     ElementPtr                      ; C55C AD 34 03
        ldy     ElementPtr+1                    ; C55F AC 35 03
        jsr     FP_LOAD                         ; C562 20 A2 BB
        lda     O2Offset                        ; C565 AD B3 02
        clc                                     ; C568 18
        adc     BASIC_ARYTAB                    ; C569 65 2F
        sta     ElementPtr                      ; C56B 8D 34 03
        lda     O2Offset+1                      ; C56E AD B4 02
        adc     BASIC_ARYTAB+1                  ; C571 65 30
        sta     ElementPtr+1                    ; C573 8D 35 03
        lda     IndexJ                          ; C576 AD 38 03
        jsr     IndexVector                     ; C579 20 90 C6
        lda     ElementPtr                      ; C57C AD 34 03
        ldy     ElementPtr+1                    ; C57F AC 35 03
        jsr     FP_MUL_MEM                      ; C582 20 28 BA
        lda     #$CD                            ; C585 A9 CD
        ldy     #$02                            ; C587 A0 02
        jsr     FP_ADD_MEM                      ; C589 20 67 B8
        inc     IndexJ                          ; C58C EE 38 03
        lda     HiddenCount                     ; C58F AD AA 02
        cmp     IndexJ                          ; C592 CD 38 03
        bcs     LC538                           ; C595 B0 A1
        lda     #$F2                            ; C597 A9 F2
        ldy     #$CF                            ; C599 A0 CF
        jsr     FP_MEM_MINUS_FAC                ; C59B 20 50 B8
        jsr     FP_EXP                          ; C59E 20 ED BF
        jsr     FP_FAC_TO_ARG                   ; C5A1 20 0C BC
        lda     #$01                            ; C5A4 A9 01
        jsr     FP_FROM_BYTE                    ; C5A6 20 3C BC
        jsr     FP_ADD_ARG                      ; C5A9 20 6A B8
        lda     #$F7                            ; C5AC A9 F7
        ldy     #$CF                            ; C5AE A0 CF
        jsr     FP_MEM_DIV_FAC                  ; C5B0 20 0F BB
        lda     O3Offset                        ; C5B3 AD B5 02
        clc                                     ; C5B6 18
        adc     BASIC_ARYTAB                    ; C5B7 65 2F
        sta     ElementPtr                      ; C5B9 8D 34 03
        lda     O3Offset+1                      ; C5BC AD B6 02
        adc     BASIC_ARYTAB+1                  ; C5BF 65 30
        sta     ElementPtr+1                    ; C5C1 8D 35 03
        lda     IndexI                          ; C5C4 AD 36 03
        jsr     IndexVector                     ; C5C7 20 90 C6
        ldx     ElementPtr                      ; C5CA AE 34 03
        ldy     ElementPtr+1                    ; C5CD AC 35 03
        jsr     FP_STORE                        ; C5D0 20 D4 BB
        inc     IndexI                          ; C5D3 EE 36 03
        lda     OutputCount                     ; C5D6 AD AB 02
        cmp     IndexI                          ; C5D9 CD 36 03
        bcc     PatternSquaredError             ; C5DC 90 03
        jmp     LC530                           ; C5DE 4C 30 C5

; ----------------------------------------------------------------------------
; E(pattern)=sum((T(output,pattern)-O3(output))^2)/2. Recognition uses scratch teacher column zero.
PatternSquaredError:
        lda     #$00                            ; C5E1 A9 00
        jsr     FP_FROM_BYTE                    ; C5E3 20 3C BC
        lda     #$01                            ; C5E6 A9 01
        sta     IndexI                          ; C5E8 8D 36 03
LC5EB:
        ldx     #$CD                            ; C5EB A2 CD
        ldy     #$02                            ; C5ED A0 02
        jsr     FP_STORE                        ; C5EF 20 D4 BB
        lda     O3Offset                        ; C5F2 AD B5 02
        clc                                     ; C5F5 18
        adc     BASIC_ARYTAB                    ; C5F6 65 2F
        sta     ElementPtr                      ; C5F8 8D 34 03
        lda     O3Offset+1                      ; C5FB AD B6 02
        adc     BASIC_ARYTAB+1                  ; C5FE 65 30
        sta     ElementPtr+1                    ; C600 8D 35 03
        lda     IndexI                          ; C603 AD 36 03
        jsr     IndexVector                     ; C606 20 90 C6
        lda     ElementPtr                      ; C609 AD 34 03
        ldy     ElementPtr+1                    ; C60C AC 35 03
        jsr     FP_LOAD                         ; C60F 20 A2 BB
        lda     TeacherOffset                   ; C612 AD C7 02
        clc                                     ; C615 18
        adc     BASIC_ARYTAB                    ; C616 65 2F
        sta     ElementPtr                      ; C618 8D 34 03
        lda     TeacherOffset+1                 ; C61B AD C8 02
        adc     BASIC_ARYTAB+1                  ; C61E 65 30
        sta     ElementPtr+1                    ; C620 8D 35 03
        lda     OutputCount                     ; C623 AD AB 02
        ldy     IndexI                          ; C626 AC 36 03
        ldx     PatternIndex                    ; C629 AE BB 02
        jsr     IndexMatrix                     ; C62C 20 AA C6
        lda     ElementPtr                      ; C62F AD 34 03
        ldy     ElementPtr+1                    ; C632 AC 35 03
        jsr     FP_MEM_MINUS_FAC                ; C635 20 50 B8
        ldx     #$D8                            ; C638 A2 D8
        ldy     #$02                            ; C63A A0 02
        jsr     FP_STORE                        ; C63C 20 D4 BB
        lda     #$D8                            ; C63F A9 D8
        ldy     #$02                            ; C641 A0 02
        jsr     FP_MUL_MEM                      ; C643 20 28 BA
        lda     #$CD                            ; C646 A9 CD
        ldy     #$02                            ; C648 A0 02
        jsr     FP_ADD_MEM                      ; C64A 20 67 B8
        inc     IndexI                          ; C64D EE 36 03
        lda     OutputCount                     ; C650 AD AB 02
        cmp     IndexI                          ; C653 CD 36 03
        bcs     LC5EB                           ; C656 B0 93
        lda     ErrorOffset                     ; C658 AD CB 02
        clc                                     ; C65B 18
        adc     BASIC_ARYTAB                    ; C65C 65 2F
        sta     ElementPtr                      ; C65E 8D 34 03
        lda     ErrorOffset+1                   ; C661 AD CC 02
        adc     BASIC_ARYTAB+1                  ; C664 65 30
        sta     ElementPtr+1                    ; C666 8D 35 03
        lda     PatternIndex                    ; C669 AD BB 02
        jsr     IndexVector                     ; C66C 20 90 C6
        ldx     ElementPtr                      ; C66F AE 34 03
        ldy     ElementPtr+1                    ; C672 AC 35 03
        jsr     FP_STORE                        ; C675 20 D4 BB
        lda     #$02                            ; C678 A9 02
        jsr     FP_FROM_BYTE                    ; C67A 20 3C BC
        lda     ElementPtr                      ; C67D AD 34 03
        ldy     ElementPtr+1                    ; C680 AC 35 03
        jsr     FP_MEM_DIV_FAC                  ; C683 20 0F BB
        ldx     ElementPtr                      ; C686 AE 34 03
        ldy     ElementPtr+1                    ; C689 AC 35 03
        jsr     FP_STORE                        ; C68C 20 D4 BB
        rts                                     ; C68F 60

; ----------------------------------------------------------------------------
; Add 5*A to ElementPtr. BASIC floating-point array elements occupy five bytes.
IndexVector:
        tax                                     ; C690 AA
        inx                                     ; C691 E8
LC692:
        dex                                     ; C692 CA
        beq     LC6A9                           ; C693 F0 14
        lda     ElementPtr                      ; C695 AD 34 03
        clc                                     ; C698 18
        adc     #$05                            ; C699 69 05
        sta     ElementPtr                      ; C69B 8D 34 03
        lda     ElementPtr+1                    ; C69E AD 35 03
        adc     #$00                            ; C6A1 69 00
        sta     ElementPtr+1                    ; C6A3 8D 35 03
        jmp     LC692                           ; C6A6 4C 92 C6

; ----------------------------------------------------------------------------
LC6A9:
        rts                                     ; C6A9 60

; ----------------------------------------------------------------------------
; Add 5*(X*(A+1)+Y) to ElementPtr. A is the first dimension upper bound; zero is allocated.
IndexMatrix:
        sta     MatrixBound                     ; C6AA 8D FD 03
        tya                                     ; C6AD 98
        pha                                     ; C6AE 48
        inx                                     ; C6AF E8
LC6B0:
        dex                                     ; C6B0 CA
        beq     LC6DF                           ; C6B1 F0 2C
        ldy     MatrixBound                     ; C6B3 AC FD 03
        iny                                     ; C6B6 C8
        lda     ElementPtr                      ; C6B7 AD 34 03
        clc                                     ; C6BA 18
        adc     #$05                            ; C6BB 69 05
        sta     ElementPtr                      ; C6BD 8D 34 03
        lda     ElementPtr+1                    ; C6C0 AD 35 03
        adc     #$00                            ; C6C3 69 00
        sta     ElementPtr+1                    ; C6C5 8D 35 03
LC6C8:
        dey                                     ; C6C8 88
        beq     LC6B0                           ; C6C9 F0 E5
        lda     ElementPtr                      ; C6CB AD 34 03
        clc                                     ; C6CE 18
        adc     #$05                            ; C6CF 69 05
        sta     ElementPtr                      ; C6D1 8D 34 03
        lda     ElementPtr+1                    ; C6D4 AD 35 03
        adc     #$00                            ; C6D7 69 00
        sta     ElementPtr+1                    ; C6D9 8D 35 03
        jmp     LC6C8                           ; C6DC 4C C8 C6

; ----------------------------------------------------------------------------
LC6DF:
        pla                                     ; C6DF 68
        jmp     IndexVector                     ; C6E0 4C 90 C6

; ----------------------------------------------------------------------------
; Format FAC in BASIC_PRINT_BUFFER and send it through BASIC string output.
PrintFloat:
        jsr     FP_FORMAT                       ; C6E3 20 DD BD
        ldy     #$FF                            ; C6E6 A0 FF
LC6E8:
        iny                                     ; C6E8 C8
        lda     BASIC_PRINT_BUFFER,y            ; C6E9 B9 00 01
        bne     LC6E8                           ; C6EC D0 FA
        iny                                     ; C6EE C8
        tya                                     ; C6EF 98
        pha                                     ; C6F0 48
        lda     #$00                            ; C6F1 A9 00
        sta     BASIC_INDEX                     ; C6F3 85 22
        lda     #$01                            ; C6F5 A9 01
        sta     BASIC_INDEX+1                   ; C6F7 85 23
        pla                                     ; C6F9 68
        jsr     BASIC_PRINT_STRING              ; C6FA 20 24 AB
        rts                                     ; C6FD 60

; ----------------------------------------------------------------------------
; Parse stored pattern, run the forward pass, then adjust weights.
TrainSelectedPattern:
        jsr     SelectStoredPattern             ; C6FE 20 57 C4
        jmp     OutputDeltaLoop                 ; C701 4C 07 C7

; ----------------------------------------------------------------------------
; Internal entry: PatternIndex is already set by the epoch loop.
TrainCurrentPattern:
        jsr     ForwardPass                     ; C704 20 6F C4
; E3(k)=(T(k,p)-O3(k))*O3(k)*(1-O3(k)). Process each output neuron.
OutputDeltaLoop:
        lda     #$01                            ; C707 A9 01
        sta     IndexI                          ; C709 8D 36 03
LC70C:
        lda     TeacherOffset                   ; C70C AD C7 02
        clc                                     ; C70F 18
        adc     BASIC_ARYTAB                    ; C710 65 2F
        sta     ElementPtr                      ; C712 8D 34 03
        lda     TeacherOffset+1                 ; C715 AD C8 02
        adc     BASIC_ARYTAB+1                  ; C718 65 30
        sta     ElementPtr+1                    ; C71A 8D 35 03
        lda     OutputCount                     ; C71D AD AB 02
        ldy     IndexI                          ; C720 AC 36 03
        ldx     PatternIndex                    ; C723 AE BB 02
        jsr     IndexMatrix                     ; C726 20 AA C6
        lda     ElementPtr                      ; C729 AD 34 03
        ldy     ElementPtr+1                    ; C72C AC 35 03
        jsr     FP_LOAD_ARG                     ; C72F 20 8C BA
        lda     O3Offset                        ; C732 AD B5 02
        clc                                     ; C735 18
        adc     BASIC_ARYTAB                    ; C736 65 2F
        sta     ElementPtr                      ; C738 8D 34 03
        lda     O3Offset+1                      ; C73B AD B6 02
        adc     BASIC_ARYTAB+1                  ; C73E 65 30
        sta     ElementPtr+1                    ; C740 8D 35 03
        lda     IndexI                          ; C743 AD 36 03
        jsr     IndexVector                     ; C746 20 90 C6
        lda     ElementPtr                      ; C749 AD 34 03
        ldy     ElementPtr+1                    ; C74C AC 35 03
        jsr     FP_LOAD                         ; C74F 20 A2 BB
        jsr     FP_ARG_MINUS_FAC                ; C752 20 53 B8
        lda     ElementPtr                      ; C755 AD 34 03
        ldy     ElementPtr+1                    ; C758 AC 35 03
        jsr     FP_MUL_MEM                      ; C75B 20 28 BA
        ldx     #$CD                            ; C75E A2 CD
        ldy     #$02                            ; C760 A0 02
        jsr     FP_STORE                        ; C762 20 D4 BB
        lda     ElementPtr                      ; C765 AD 34 03
        ldy     ElementPtr+1                    ; C768 AC 35 03
        jsr     FP_LOAD                         ; C76B 20 A2 BB
        lda     #$F7                            ; C76E A9 F7
        ldy     #$CF                            ; C770 A0 CF
        jsr     FP_MEM_MINUS_FAC                ; C772 20 50 B8
        lda     #$CD                            ; C775 A9 CD
        ldy     #$02                            ; C777 A0 02
        jsr     FP_MUL_MEM                      ; C779 20 28 BA
        lda     E3Offset                        ; C77C AD B9 02
        clc                                     ; C77F 18
        adc     BASIC_ARYTAB                    ; C780 65 2F
        sta     ElementPtr                      ; C782 8D 34 03
        lda     E3Offset+1                      ; C785 AD BA 02
        adc     BASIC_ARYTAB+1                  ; C788 65 30
        sta     ElementPtr+1                    ; C78A 8D 35 03
        lda     IndexI                          ; C78D AD 36 03
        jsr     IndexVector                     ; C790 20 90 C6
        ldx     ElementPtr                      ; C793 AE 34 03
        ldy     ElementPtr+1                    ; C796 AC 35 03
        jsr     FP_STORE                        ; C799 20 D4 BB
        lda     #$00                            ; C79C A9 00
        sta     IndexJ                          ; C79E 8D 38 03
; M2(k,j)=rate*E3(k)*O2(j)+momentum*M2(k,j); then W2(k,j)+=M2(k,j), including bias j=0.
UpdateW2:
        lda     RateOffset                      ; C7A1 AD AD 02
        clc                                     ; C7A4 18
        adc     BASIC_VARTAB                    ; C7A5 65 2D
        pha                                     ; C7A7 48
        lda     RateOffset+1                    ; C7A8 AD AE 02
        adc     BASIC_VARTAB+1                  ; C7AB 65 2E
        tay                                     ; C7AD A8
        pla                                     ; C7AE 68
        jsr     FP_LOAD                         ; C7AF 20 A2 BB
        lda     E3Offset                        ; C7B2 AD B9 02
        clc                                     ; C7B5 18
        adc     BASIC_ARYTAB                    ; C7B6 65 2F
        sta     ElementPtr                      ; C7B8 8D 34 03
        lda     E3Offset+1                      ; C7BB AD BA 02
        adc     BASIC_ARYTAB+1                  ; C7BE 65 30
        sta     ElementPtr+1                    ; C7C0 8D 35 03
        lda     IndexI                          ; C7C3 AD 36 03
        jsr     IndexVector                     ; C7C6 20 90 C6
        lda     ElementPtr                      ; C7C9 AD 34 03
        ldy     ElementPtr+1                    ; C7CC AC 35 03
        jsr     FP_MUL_MEM                      ; C7CF 20 28 BA
        lda     O2Offset                        ; C7D2 AD B3 02
        clc                                     ; C7D5 18
        adc     BASIC_ARYTAB                    ; C7D6 65 2F
        sta     ElementPtr                      ; C7D8 8D 34 03
        lda     O2Offset+1                      ; C7DB AD B4 02
        adc     BASIC_ARYTAB+1                  ; C7DE 65 30
        sta     ElementPtr+1                    ; C7E0 8D 35 03
        lda     IndexJ                          ; C7E3 AD 38 03
        jsr     IndexVector                     ; C7E6 20 90 C6
        lda     ElementPtr                      ; C7E9 AD 34 03
        ldy     ElementPtr+1                    ; C7EC AC 35 03
        jsr     FP_MUL_MEM                      ; C7EF 20 28 BA
        ldx     #$CD                            ; C7F2 A2 CD
        ldy     #$02                            ; C7F4 A0 02
        jsr     FP_STORE                        ; C7F6 20 D4 BB
        lda     MomentumOffset                  ; C7F9 AD B1 02
        clc                                     ; C7FC 18
        adc     BASIC_VARTAB                    ; C7FD 65 2D
        pha                                     ; C7FF 48
        lda     MomentumOffset+1                ; C800 AD B2 02
        adc     BASIC_VARTAB+1                  ; C803 65 2E
        tay                                     ; C805 A8
        pla                                     ; C806 68
        jsr     FP_LOAD                         ; C807 20 A2 BB
        lda     M2Offset                        ; C80A AD C5 02
        clc                                     ; C80D 18
        adc     BASIC_ARYTAB                    ; C80E 65 2F
        sta     ElementPtr                      ; C810 8D 34 03
        lda     M2Offset+1                      ; C813 AD C6 02
        adc     BASIC_ARYTAB+1                  ; C816 65 30
        sta     ElementPtr+1                    ; C818 8D 35 03
        lda     OutputCount                     ; C81B AD AB 02
        ldy     IndexI                          ; C81E AC 36 03
        ldx     IndexJ                          ; C821 AE 38 03
        jsr     IndexMatrix                     ; C824 20 AA C6
        lda     ElementPtr                      ; C827 AD 34 03
        ldy     ElementPtr+1                    ; C82A AC 35 03
        jsr     FP_MUL_MEM                      ; C82D 20 28 BA
        lda     #$CD                            ; C830 A9 CD
        ldy     #$02                            ; C832 A0 02
        jsr     FP_ADD_MEM                      ; C834 20 67 B8
        ldx     ElementPtr                      ; C837 AE 34 03
        ldy     ElementPtr+1                    ; C83A AC 35 03
        jsr     FP_STORE                        ; C83D 20 D4 BB
        lda     W2Offset                        ; C840 AD C1 02
        clc                                     ; C843 18
        adc     BASIC_ARYTAB                    ; C844 65 2F
        sta     ElementPtr                      ; C846 8D 34 03
        lda     W2Offset+1                      ; C849 AD C2 02
        adc     BASIC_ARYTAB+1                  ; C84C 65 30
        sta     ElementPtr+1                    ; C84E 8D 35 03
        lda     OutputCount                     ; C851 AD AB 02
        ldy     IndexI                          ; C854 AC 36 03
        ldx     IndexJ                          ; C857 AE 38 03
        jsr     IndexMatrix                     ; C85A 20 AA C6
        lda     ElementPtr                      ; C85D AD 34 03
        ldy     ElementPtr+1                    ; C860 AC 35 03
        jsr     FP_ADD_MEM                      ; C863 20 67 B8
        ldx     ElementPtr                      ; C866 AE 34 03
        ldy     ElementPtr+1                    ; C869 AC 35 03
        jsr     FP_STORE                        ; C86C 20 D4 BB
        inc     IndexJ                          ; C86F EE 38 03
        lda     HiddenCount                     ; C872 AD AA 02
        cmp     IndexJ                          ; C875 CD 38 03
        bcc     LC87D                           ; C878 90 03
        jmp     UpdateW2                        ; C87A 4C A1 C7

; ----------------------------------------------------------------------------
LC87D:
        inc     IndexI                          ; C87D EE 36 03
        lda     OutputCount                     ; C880 AD AB 02
        cmp     IndexI                          ; C883 CD 36 03
        bcc     HiddenDeltaLoop                 ; C886 90 03
        jmp     LC70C                           ; C888 4C 0C C7

; ----------------------------------------------------------------------------
; E2(j)=O2(j)*(1-O2(j))*sum(E3(k)*W2(k,j)). Uses W2 as currently stored after its updates.
HiddenDeltaLoop:
        lda     #$01                            ; C88B A9 01
        sta     IndexI                          ; C88D 8D 36 03
LC890:
        lda     #$00                            ; C890 A9 00
        ldy     #$05                            ; C892 A0 05
LC894:
        sta     ErrorOffset+1,y                 ; C894 99 CC 02
        dey                                     ; C897 88
        bne     LC894                           ; C898 D0 FA
        lda     #$01                            ; C89A A9 01
        sta     IndexJ                          ; C89C 8D 38 03
LC89F:
        lda     E3Offset                        ; C89F AD B9 02
        clc                                     ; C8A2 18
        adc     BASIC_ARYTAB                    ; C8A3 65 2F
        sta     ElementPtr                      ; C8A5 8D 34 03
        lda     E3Offset+1                      ; C8A8 AD BA 02
        adc     BASIC_ARYTAB+1                  ; C8AB 65 30
        sta     ElementPtr+1                    ; C8AD 8D 35 03
        lda     IndexJ                          ; C8B0 AD 38 03
        jsr     IndexVector                     ; C8B3 20 90 C6
        lda     ElementPtr                      ; C8B6 AD 34 03
        ldy     ElementPtr+1                    ; C8B9 AC 35 03
        jsr     FP_LOAD                         ; C8BC 20 A2 BB
        lda     W2Offset                        ; C8BF AD C1 02
        clc                                     ; C8C2 18
        adc     BASIC_ARYTAB                    ; C8C3 65 2F
        sta     ElementPtr                      ; C8C5 8D 34 03
        lda     W2Offset+1                      ; C8C8 AD C2 02
        adc     BASIC_ARYTAB+1                  ; C8CB 65 30
        sta     ElementPtr+1                    ; C8CD 8D 35 03
        lda     OutputCount                     ; C8D0 AD AB 02
        ldy     IndexJ                          ; C8D3 AC 38 03
        ldx     IndexI                          ; C8D6 AE 36 03
        jsr     IndexMatrix                     ; C8D9 20 AA C6
        lda     ElementPtr                      ; C8DC AD 34 03
        ldy     ElementPtr+1                    ; C8DF AC 35 03
        jsr     FP_MUL_MEM                      ; C8E2 20 28 BA
        lda     #$CD                            ; C8E5 A9 CD
        ldy     #$02                            ; C8E7 A0 02
        jsr     FP_ADD_MEM                      ; C8E9 20 67 B8
        ldx     #$CD                            ; C8EC A2 CD
        ldy     #$02                            ; C8EE A0 02
        jsr     FP_STORE                        ; C8F0 20 D4 BB
        inc     IndexJ                          ; C8F3 EE 38 03
        lda     OutputCount                     ; C8F6 AD AB 02
        cmp     IndexJ                          ; C8F9 CD 38 03
        bcs     LC89F                           ; C8FC B0 A1
        lda     O2Offset                        ; C8FE AD B3 02
        clc                                     ; C901 18
        adc     BASIC_ARYTAB                    ; C902 65 2F
        sta     ElementPtr                      ; C904 8D 34 03
        lda     O2Offset+1                      ; C907 AD B4 02
        adc     BASIC_ARYTAB+1                  ; C90A 65 30
        sta     ElementPtr+1                    ; C90C 8D 35 03
        lda     IndexI                          ; C90F AD 36 03
        jsr     IndexVector                     ; C912 20 90 C6
        lda     ElementPtr                      ; C915 AD 34 03
        ldy     ElementPtr+1                    ; C918 AC 35 03
        jsr     FP_LOAD                         ; C91B 20 A2 BB
        lda     #$F7                            ; C91E A9 F7
        ldy     #$CF                            ; C920 A0 CF
        jsr     FP_MEM_MINUS_FAC                ; C922 20 50 B8
        lda     ElementPtr                      ; C925 AD 34 03
        ldy     ElementPtr+1                    ; C928 AC 35 03
        jsr     FP_MUL_MEM                      ; C92B 20 28 BA
        lda     #$CD                            ; C92E A9 CD
        ldy     #$02                            ; C930 A0 02
        jsr     FP_MUL_MEM                      ; C932 20 28 BA
        lda     E2Offset                        ; C935 AD B7 02
        clc                                     ; C938 18
        adc     BASIC_ARYTAB                    ; C939 65 2F
        sta     ElementPtr                      ; C93B 8D 34 03
        lda     E2Offset+1                      ; C93E AD B8 02
        adc     BASIC_ARYTAB+1                  ; C941 65 30
        sta     ElementPtr+1                    ; C943 8D 35 03
        lda     IndexI                          ; C946 AD 36 03
        jsr     IndexVector                     ; C949 20 90 C6
        ldx     ElementPtr                      ; C94C AE 34 03
        ldy     ElementPtr+1                    ; C94F AC 35 03
        jsr     FP_STORE                        ; C952 20 D4 BB
        lda     #$00                            ; C955 A9 00
        sta     IndexJ                          ; C957 8D 38 03
; M1(j,i)=rate*E2(j)*IN(i,p)+momentum*M1(j,i); then W1(j,i)+=M1(j,i), including bias i=0.
UpdateW1:
        lda     RateOffset                      ; C95A AD AD 02
        clc                                     ; C95D 18
        adc     BASIC_VARTAB                    ; C95E 65 2D
        pha                                     ; C960 48
        lda     RateOffset+1                    ; C961 AD AE 02
        adc     BASIC_VARTAB+1                  ; C964 65 2E
        tay                                     ; C966 A8
        pla                                     ; C967 68
        jsr     FP_LOAD                         ; C968 20 A2 BB
        lda     E2Offset                        ; C96B AD B7 02
        clc                                     ; C96E 18
        adc     BASIC_ARYTAB                    ; C96F 65 2F
        sta     ElementPtr                      ; C971 8D 34 03
        lda     E2Offset+1                      ; C974 AD B8 02
        adc     BASIC_ARYTAB+1                  ; C977 65 30
        sta     ElementPtr+1                    ; C979 8D 35 03
        lda     IndexI                          ; C97C AD 36 03
        jsr     IndexVector                     ; C97F 20 90 C6
        lda     ElementPtr                      ; C982 AD 34 03
        ldy     ElementPtr+1                    ; C985 AC 35 03
        jsr     FP_MUL_MEM                      ; C988 20 28 BA
        lda     InputOffset                     ; C98B AD C9 02
        clc                                     ; C98E 18
        adc     BASIC_ARYTAB                    ; C98F 65 2F
        sta     ElementPtr                      ; C991 8D 34 03
        lda     InputOffset+1                   ; C994 AD CA 02
        adc     BASIC_ARYTAB+1                  ; C997 65 30
        sta     ElementPtr+1                    ; C999 8D 35 03
        lda     InputCount                      ; C99C AD A9 02
        ldy     IndexJ                          ; C99F AC 38 03
        ldx     PatternIndex                    ; C9A2 AE BB 02
        jsr     IndexMatrix                     ; C9A5 20 AA C6
        lda     ElementPtr                      ; C9A8 AD 34 03
        ldy     ElementPtr+1                    ; C9AB AC 35 03
        jsr     FP_MUL_MEM                      ; C9AE 20 28 BA
        ldx     #$CD                            ; C9B1 A2 CD
        ldy     #$02                            ; C9B3 A0 02
        jsr     FP_STORE                        ; C9B5 20 D4 BB
        lda     MomentumOffset                  ; C9B8 AD B1 02
        clc                                     ; C9BB 18
        adc     BASIC_VARTAB                    ; C9BC 65 2D
        pha                                     ; C9BE 48
        lda     MomentumOffset+1                ; C9BF AD B2 02
        adc     BASIC_VARTAB+1                  ; C9C2 65 2E
        tay                                     ; C9C4 A8
        pla                                     ; C9C5 68
        jsr     FP_LOAD                         ; C9C6 20 A2 BB
        lda     M1Offset                        ; C9C9 AD C3 02
        clc                                     ; C9CC 18
        adc     BASIC_ARYTAB                    ; C9CD 65 2F
        sta     ElementPtr                      ; C9CF 8D 34 03
        lda     M1Offset+1                      ; C9D2 AD C4 02
        adc     BASIC_ARYTAB+1                  ; C9D5 65 30
        sta     ElementPtr+1                    ; C9D7 8D 35 03
        lda     HiddenCount                     ; C9DA AD AA 02
        ldy     IndexI                          ; C9DD AC 36 03
        ldx     IndexJ                          ; C9E0 AE 38 03
        jsr     IndexMatrix                     ; C9E3 20 AA C6
        lda     ElementPtr                      ; C9E6 AD 34 03
        ldy     ElementPtr+1                    ; C9E9 AC 35 03
        jsr     FP_MUL_MEM                      ; C9EC 20 28 BA
        lda     #$CD                            ; C9EF A9 CD
        ldy     #$02                            ; C9F1 A0 02
        jsr     FP_ADD_MEM                      ; C9F3 20 67 B8
        ldx     ElementPtr                      ; C9F6 AE 34 03
        ldy     ElementPtr+1                    ; C9F9 AC 35 03
        jsr     FP_STORE                        ; C9FC 20 D4 BB
        lda     W1Offset                        ; C9FF AD BF 02
        clc                                     ; CA02 18
        adc     BASIC_ARYTAB                    ; CA03 65 2F
        sta     ElementPtr                      ; CA05 8D 34 03
        lda     W1Offset+1                      ; CA08 AD C0 02
        adc     BASIC_ARYTAB+1                  ; CA0B 65 30
        sta     ElementPtr+1                    ; CA0D 8D 35 03
        lda     HiddenCount                     ; CA10 AD AA 02
        ldy     IndexI                          ; CA13 AC 36 03
        ldx     IndexJ                          ; CA16 AE 38 03
        jsr     IndexMatrix                     ; CA19 20 AA C6
        lda     ElementPtr                      ; CA1C AD 34 03
        ldy     ElementPtr+1                    ; CA1F AC 35 03
        jsr     FP_ADD_MEM                      ; CA22 20 67 B8
        ldx     ElementPtr                      ; CA25 AE 34 03
        ldy     ElementPtr+1                    ; CA28 AC 35 03
        jsr     FP_STORE                        ; CA2B 20 D4 BB
        inc     IndexJ                          ; CA2E EE 38 03
        lda     InputCount                      ; CA31 AD A9 02
        cmp     IndexJ                          ; CA34 CD 38 03
        bcc     LCA3C                           ; CA37 90 03
        jmp     UpdateW1                        ; CA39 4C 5A C9

; ----------------------------------------------------------------------------
LCA3C:
        inc     IndexI                          ; CA3C EE 36 03
        lda     HiddenCount                     ; CA3F AD AA 02
        cmp     IndexI                          ; CA42 CD 36 03
        bcc     LCA4A                           ; CA45 90 03
        jmp     LC890                           ; CA47 4C 90 C8

; ----------------------------------------------------------------------------
LCA4A:
        rts                                     ; CA4A 60

; ----------------------------------------------------------------------------
; Clear TE, train patterns 1..NP in order, and accumulate their pre-update E(pattern) values.
TrainEpoch:
        lda     #$00                            ; CA4B A9 00
        jsr     FP_FROM_BYTE                    ; CA4D 20 3C BC
        lda     TotalErrorOffset                ; CA50 AD D2 02
        clc                                     ; CA53 18
        adc     BASIC_VARTAB                    ; CA54 65 2D
        sta     TotalErrorPtr                   ; CA56 8D D4 02
        lda     TotalErrorOffset+1              ; CA59 AD D3 02
        adc     BASIC_VARTAB+1                  ; CA5C 65 2E
        sta     TotalErrorPtr+1                 ; CA5E 8D D5 02
        ldx     TotalErrorPtr                   ; CA61 AE D4 02
        ldy     TotalErrorPtr+1                 ; CA64 AC D5 02
        jsr     FP_STORE                        ; CA67 20 D4 BB
        lda     #$01                            ; CA6A A9 01
        sta     PatternIndex                    ; CA6C 8D BB 02
LCA6F:
        jsr     TrainCurrentPattern             ; CA6F 20 04 C7
        lda     ErrorOffset                     ; CA72 AD CB 02
        clc                                     ; CA75 18
        adc     BASIC_ARYTAB                    ; CA76 65 2F
        sta     ElementPtr                      ; CA78 8D 34 03
        lda     ErrorOffset+1                   ; CA7B AD CC 02
        adc     BASIC_ARYTAB+1                  ; CA7E 65 30
        sta     ElementPtr+1                    ; CA80 8D 35 03
        lda     PatternIndex                    ; CA83 AD BB 02
        jsr     IndexVector                     ; CA86 20 90 C6
        lda     ElementPtr                      ; CA89 AD 34 03
        ldy     ElementPtr+1                    ; CA8C AC 35 03
        jsr     FP_LOAD                         ; CA8F 20 A2 BB
        lda     TotalErrorPtr                   ; CA92 AD D4 02
        ldy     TotalErrorPtr+1                 ; CA95 AC D5 02
        jsr     FP_ADD_MEM                      ; CA98 20 67 B8
        ldx     TotalErrorPtr                   ; CA9B AE D4 02
        ldy     TotalErrorPtr+1                 ; CA9E AC D5 02
        jsr     FP_STORE                        ; CAA1 20 D4 BB
        inc     PatternIndex                    ; CAA4 EE BB 02
        lda     PatternCount                    ; CAA7 AD AC 02
        cmp     PatternIndex                    ; CAAA CD BB 02
        bcs     LCA6F                           ; CAAD B0 C0
        rts                                     ; CAAF 60

; ----------------------------------------------------------------------------
; Parse show-error flag and cache the EP address. The article uses this entry for complete learning.
LearnUntilTolerance:
        jsr     BASIC_COMMA                     ; CAB0 20 FD AE
        jsr     BASIC_GET_BYTE                  ; CAB3 20 9E B7
        stx     ShowError                       ; CAB6 8E FC 03
        lda     EpsilonOffset                   ; CAB9 AD AF 02
        clc                                     ; CABC 18
        adc     BASIC_VARTAB                    ; CABD 65 2D
        sta     EpsilonPtr                      ; CABF 8D D6 02
        lda     EpsilonOffset+1                 ; CAC2 AD B0 02
        adc     BASIC_VARTAB+1                  ; CAC5 65 2E
        sta     EpsilonPtr+1                    ; CAC7 8D D7 02
; One epoch, RUN/STOP poll, optional TE print, and comparison with epsilon.
LearningPass:
        jsr     TrainEpoch                      ; CACA 20 4B CA
        jsr     K_STOP                          ; CACD 20 E1 FF
        beq     LCAFF                           ; CAD0 F0 2D
        lda     ShowError                       ; CAD2 AD FC 03
        beq     LCAE8                           ; CAD5 F0 11
        lda     TotalErrorPtr                   ; CAD7 AD D4 02
        ldy     TotalErrorPtr+1                 ; CADA AC D5 02
        jsr     FP_LOAD                         ; CADD 20 A2 BB
        jsr     PrintFloat                      ; CAE0 20 E3 C6
        lda     #$0D                            ; CAE3 A9 0D
        jsr     K_CHROUT                        ; CAE5 20 D2 FF
LCAE8:
        lda     TotalErrorPtr                   ; CAE8 AD D4 02
        ldy     TotalErrorPtr+1                 ; CAEB AC D5 02
        jsr     FP_LOAD                         ; CAEE 20 A2 BB
        lda     EpsilonPtr                      ; CAF1 AD D6 02
        ldy     EpsilonPtr+1                    ; CAF4 AC D7 02
        jsr     FP_COMPARE                      ; CAF7 20 5B BC
        cmp     #$01                            ; CAFA C9 01
        beq     LearningPass                    ; CAFC F0 CC
        rts                                     ; CAFE 60

; ----------------------------------------------------------------------------
LCAFF:
        ldy     #$00                            ; CAFF A0 00
        jmp     BASIC_BREAK                     ; CB01 4C 38 A8

; ----------------------------------------------------------------------------
; Validate pattern number, import input and teacher strings into the corresponding BASIC arrays.
DefineTrainingPair:
        jsr     BASIC_COMMA                     ; CB04 20 FD AE
        jsr     BASIC_GET_BYTE                  ; CB07 20 9E B7
        stx     PatternIndex                    ; CB0A 8E BB 02
        cpx     #$00                            ; CB0D E0 00
        beq     LCB19                           ; CB0F F0 08
        lda     PatternCount                    ; CB11 AD AC 02
        cmp     PatternIndex                    ; CB14 CD BB 02
        bcs     ReadInputString                 ; CB17 B0 03
LCB19:
        jmp     BASIC_BAD_QUANTITY              ; CB19 4C 48 B2

; ----------------------------------------------------------------------------
; Require length P1. Each ASCII 1 becomes numeric one; every other character becomes zero.
ReadInputString:
        jsr     BASIC_COMMA                     ; CB1C 20 FD AE
        jsr     BASIC_EVAL                      ; CB1F 20 9E AD
        jsr     BASIC_REQUIRE_STRING            ; CB22 20 8F AD
        jsr     BASIC_STRING_DATA               ; CB25 20 A6 B6
        cmp     InputCount                      ; CB28 CD A9 02
        bne     LCB19                           ; CB2B D0 EC
        stx     WorkFloat                       ; CB2D 8E CD 02
        sty     WorkFloat+1                     ; CB30 8C CE 02
        lda     #$00                            ; CB33 A9 00
        sta     IndexI                          ; CB35 8D 36 03
LCB38:
        ldx     #$01                            ; CB38 A2 01
        ldy     IndexI                          ; CB3A AC 36 03
        lda     WorkFloat                       ; CB3D AD CD 02
        sta     BASIC_INDEX                     ; CB40 85 22
        lda     WorkFloat+1                     ; CB42 AD CE 02
        sta     BASIC_INDEX+1                   ; CB45 85 23
        lda     (BASIC_INDEX),y                 ; CB47 B1 22
        cmp     #$31                            ; CB49 C9 31
        beq     LCB4F                           ; CB4B F0 02
        ldx     #$00                            ; CB4D A2 00
LCB4F:
        txa                                     ; CB4F 8A
        jsr     FP_FROM_BYTE                    ; CB50 20 3C BC
        lda     InputOffset                     ; CB53 AD C9 02
        clc                                     ; CB56 18
        adc     BASIC_ARYTAB                    ; CB57 65 2F
        sta     ElementPtr                      ; CB59 8D 34 03
        lda     InputOffset+1                   ; CB5C AD CA 02
        adc     BASIC_ARYTAB+1                  ; CB5F 65 30
        sta     ElementPtr+1                    ; CB61 8D 35 03
        lda     InputCount                      ; CB64 AD A9 02
        ldy     IndexI                          ; CB67 AC 36 03
        iny                                     ; CB6A C8
        ldx     PatternIndex                    ; CB6B AE BB 02
        jsr     IndexMatrix                     ; CB6E 20 AA C6
        ldx     ElementPtr                      ; CB71 AE 34 03
        ldy     ElementPtr+1                    ; CB74 AC 35 03
        jsr     FP_STORE                        ; CB77 20 D4 BB
        inc     IndexI                          ; CB7A EE 36 03
        lda     InputCount                      ; CB7D AD A9 02
        cmp     IndexI                          ; CB80 CD 36 03
        bne     LCB38                           ; CB83 D0 B3
        lda     PatternIndex                    ; CB85 AD BB 02
        beq     LCBF3                           ; CB88 F0 69
; Require length P3. The implementation uses the same ASCII-1 test as the input parser.
ReadTeacherString:
        jsr     BASIC_COMMA                     ; CB8A 20 FD AE
        jsr     BASIC_EVAL                      ; CB8D 20 9E AD
        jsr     BASIC_REQUIRE_STRING            ; CB90 20 8F AD
        jsr     BASIC_STRING_DATA               ; CB93 20 A6 B6
        cmp     OutputCount                     ; CB96 CD AB 02
        bne     LCBF4                           ; CB99 D0 59
        stx     WorkFloat                       ; CB9B 8E CD 02
        sty     WorkFloat+1                     ; CB9E 8C CE 02
        lda     #$00                            ; CBA1 A9 00
        sta     IndexI                          ; CBA3 8D 36 03
LCBA6:
        ldx     #$01                            ; CBA6 A2 01
        ldy     IndexI                          ; CBA8 AC 36 03
        lda     WorkFloat                       ; CBAB AD CD 02
        sta     BASIC_INDEX                     ; CBAE 85 22
        lda     WorkFloat+1                     ; CBB0 AD CE 02
        sta     BASIC_INDEX+1                   ; CBB3 85 23
        lda     (BASIC_INDEX),y                 ; CBB5 B1 22
        cmp     #$31                            ; CBB7 C9 31
        beq     LCBBD                           ; CBB9 F0 02
        ldx     #$00                            ; CBBB A2 00
LCBBD:
        txa                                     ; CBBD 8A
        jsr     FP_FROM_BYTE                    ; CBBE 20 3C BC
        lda     TeacherOffset                   ; CBC1 AD C7 02
        clc                                     ; CBC4 18
        adc     BASIC_ARYTAB                    ; CBC5 65 2F
        sta     ElementPtr                      ; CBC7 8D 34 03
        lda     TeacherOffset+1                 ; CBCA AD C8 02
        adc     BASIC_ARYTAB+1                  ; CBCD 65 30
        sta     ElementPtr+1                    ; CBCF 8D 35 03
        lda     OutputCount                     ; CBD2 AD AB 02
        ldy     IndexI                          ; CBD5 AC 36 03
        iny                                     ; CBD8 C8
        ldx     PatternIndex                    ; CBD9 AE BB 02
        jsr     IndexMatrix                     ; CBDC 20 AA C6
        ldx     ElementPtr                      ; CBDF AE 34 03
        ldy     ElementPtr+1                    ; CBE2 AC 35 03
        jsr     FP_STORE                        ; CBE5 20 D4 BB
        inc     IndexI                          ; CBE8 EE 36 03
        lda     OutputCount                     ; CBEB AD AB 02
        cmp     IndexI                          ; CBEE CD 36 03
        bne     LCBA6                           ; CBF1 D0 B3
LCBF3:
        rts                                     ; CBF3 60

; ----------------------------------------------------------------------------
LCBF4:
        jmp     BASIC_BAD_QUANTITY              ; CBF4 4C 48 B2

; ----------------------------------------------------------------------------
; Sequential disk file on device 8; logical file 1, secondary address 2. Append comma-W to the name.
SaveNetwork:
        jsr     OpenStatusChannel               ; CBF7 20 0E CF
        jsr     BASIC_COMMA                     ; CBFA 20 FD AE
        jsr     BASIC_EVAL                      ; CBFD 20 9E AD
        jsr     BASIC_REQUIRE_STRING            ; CC00 20 8F AD
        jsr     BASIC_STRING_DATA               ; CC03 20 A6 B6
        sta     IndexI                          ; CC06 8D 36 03
        ldy     #$00                            ; CC09 A0 00
LCC0B:
        lda     (BASIC_INDEX),y                 ; CC0B B1 22
        sta     FilenameBuffer,y                ; CC0D 99 DD 02
        iny                                     ; CC10 C8
        cpy     IndexI                          ; CC11 CC 36 03
        beq     LCC1A                           ; CC14 F0 04
        cpy     #$14                            ; CC16 C0 14
        bne     LCC0B                           ; CC18 D0 F1
LCC1A:
        lda     #$2C                            ; CC1A A9 2C
        sta     FilenameBuffer,y                ; CC1C 99 DD 02
        iny                                     ; CC1F C8
        lda     #$57                            ; CC20 A9 57
        sta     FilenameBuffer,y                ; CC22 99 DD 02
        iny                                     ; CC25 C8
        tya                                     ; CC26 98
        ldx     #$DD                            ; CC27 A2 DD
        ldy     #$02                            ; CC29 A0 02
        jsr     K_SETNAM                        ; CC2B 20 BD FF
        lda     #$01                            ; CC2E A9 01
        ldx     #$08                            ; CC30 A2 08
        ldy     #$02                            ; CC32 A0 02
        jsr     K_SETLFS                        ; CC34 20 BA FF
        jsr     K_OPEN                          ; CC37 20 C0 FF
        ldx     #$0F                            ; CC3A A2 0F
        jsr     K_CHKIN                         ; CC3C 20 C6 FF
        jsr     K_CHRIN                         ; CC3F 20 CF FF
        cmp     #$30                            ; CC42 C9 30
        beq     WriteNetworkBody                ; CC44 F0 03
        jmp     DiskError                       ; CC46 4C 4D CD

; ----------------------------------------------------------------------------
; Write P1/P2/P3/NP, RA/MO/EP, then W1/W2/M1/M2/IN/T. This is not a PRG save.
WriteNetworkBody:
        jsr     K_CLRCHN                        ; CC49 20 CC FF
        ldx     #$01                            ; CC4C A2 01
        jsr     K_CHKOUT                        ; CC4E 20 C9 FF
        lda     InputCount                      ; CC51 AD A9 02
        jsr     K_CHROUT                        ; CC54 20 D2 FF
        lda     HiddenCount                     ; CC57 AD AA 02
        jsr     K_CHROUT                        ; CC5A 20 D2 FF
        lda     OutputCount                     ; CC5D AD AB 02
        jsr     K_CHROUT                        ; CC60 20 D2 FF
        lda     PatternCount                    ; CC63 AD AC 02
        jsr     K_CHROUT                        ; CC66 20 D2 FF
        ldx     RateOffset                      ; CC69 AE AD 02
        ldy     RateOffset+1                    ; CC6C AC AE 02
        jsr     WriteScalar                     ; CC6F 20 F9 CC
        ldx     MomentumOffset                  ; CC72 AE B1 02
        ldy     MomentumOffset+1                ; CC75 AC B2 02
        jsr     WriteScalar                     ; CC78 20 F9 CC
        ldx     EpsilonOffset                   ; CC7B AE AF 02
        ldy     EpsilonOffset+1                 ; CC7E AC B0 02
        jsr     WriteScalar                     ; CC81 20 F9 CC
        lda     W1Offset                        ; CC84 AD BF 02
        sta     BASIC_INDEX                     ; CC87 85 22
        lda     W1Offset+1                      ; CC89 AD C0 02
        sta     BASIC_INDEX+1                   ; CC8C 85 23
        ldy     HiddenCount                     ; CC8E AC AA 02
        ldx     InputCount                      ; CC91 AE A9 02
        jsr     WriteMatrix                     ; CC94 20 11 CD
        lda     W2Offset                        ; CC97 AD C1 02
        sta     BASIC_INDEX                     ; CC9A 85 22
        lda     W2Offset+1                      ; CC9C AD C2 02
        sta     BASIC_INDEX+1                   ; CC9F 85 23
        ldy     OutputCount                     ; CCA1 AC AB 02
        ldx     HiddenCount                     ; CCA4 AE AA 02
        jsr     WriteMatrix                     ; CCA7 20 11 CD
        lda     M1Offset                        ; CCAA AD C3 02
        sta     BASIC_INDEX                     ; CCAD 85 22
        lda     M1Offset+1                      ; CCAF AD C4 02
        sta     BASIC_INDEX+1                   ; CCB2 85 23
        ldy     HiddenCount                     ; CCB4 AC AA 02
        ldx     InputCount                      ; CCB7 AE A9 02
        jsr     WriteMatrix                     ; CCBA 20 11 CD
        lda     M2Offset                        ; CCBD AD C5 02
        sta     BASIC_INDEX                     ; CCC0 85 22
        lda     M2Offset+1                      ; CCC2 AD C6 02
        sta     BASIC_INDEX+1                   ; CCC5 85 23
        ldy     OutputCount                     ; CCC7 AC AB 02
        ldx     HiddenCount                     ; CCCA AE AA 02
        jsr     WriteMatrix                     ; CCCD 20 11 CD
        lda     InputOffset                     ; CCD0 AD C9 02
        sta     BASIC_INDEX                     ; CCD3 85 22
        lda     InputOffset+1                   ; CCD5 AD CA 02
        sta     BASIC_INDEX+1                   ; CCD8 85 23
        ldy     InputCount                      ; CCDA AC A9 02
        ldx     PatternCount                    ; CCDD AE AC 02
        jsr     WriteMatrix                     ; CCE0 20 11 CD
        lda     TeacherOffset                   ; CCE3 AD C7 02
        sta     BASIC_INDEX                     ; CCE6 85 22
        lda     TeacherOffset+1                 ; CCE8 AD C8 02
        sta     BASIC_INDEX+1                   ; CCEB 85 23
        ldy     OutputCount                     ; CCED AC AB 02
        ldx     PatternCount                    ; CCF0 AE AC 02
        jsr     WriteMatrix                     ; CCF3 20 11 CD
        jmp     CloseNetworkFiles               ; CCF6 4C 20 CF

; ----------------------------------------------------------------------------
; Resolve VARTAB-relative scalar offset and write its five stored bytes.
WriteScalar:
        txa                                     ; CCF9 8A
        clc                                     ; CCFA 18
        adc     BASIC_VARTAB                    ; CCFB 65 2D
        sta     BASIC_INDEX                     ; CCFD 85 22
        tya                                     ; CCFF 98
        adc     BASIC_VARTAB+1                  ; CD00 65 2E
        sta     BASIC_INDEX+1                   ; CD02 85 23
        ldy     #$00                            ; CD04 A0 00
LCD06:
        lda     (BASIC_INDEX),y                 ; CD06 B1 22
        jsr     K_CHROUT                        ; CD08 20 D2 FF
        iny                                     ; CD0B C8
        cpy     #$05                            ; CD0C C0 05
        bne     LCD06                           ; CD0E D0 F6
        rts                                     ; CD10 60

; ----------------------------------------------------------------------------
; Resolve ARYTAB-relative matrix offset; write (bound1+1)*(bound2+1) five-byte elements.
WriteMatrix:
        lda     BASIC_ARYTAB                    ; CD11 A5 2F
        clc                                     ; CD13 18
        adc     BASIC_INDEX                     ; CD14 65 22
        sta     BASIC_INDEX                     ; CD16 85 22
        lda     BASIC_ARYTAB+1                  ; CD18 A5 30
        adc     BASIC_INDEX+1                   ; CD1A 65 23
        sta     BASIC_INDEX+1                   ; CD1C 85 23
        iny                                     ; CD1E C8
        sty     IndexI                          ; CD1F 8C 36 03
        sty     WorkFloat                       ; CD22 8C CD 02
        inx                                     ; CD25 E8
        stx     IndexJ                          ; CD26 8E 38 03
        ldy     #$00                            ; CD29 A0 00
        ldx     #$05                            ; CD2B A2 05
LCD2D:
        lda     (BASIC_INDEX),y                 ; CD2D B1 22
        jsr     K_CHROUT                        ; CD2F 20 D2 FF
        iny                                     ; CD32 C8
        bne     LCD37                           ; CD33 D0 02
        inc     BASIC_INDEX+1                   ; CD35 E6 23
LCD37:
        dex                                     ; CD37 CA
        bne     LCD2D                           ; CD38 D0 F3
        ldx     #$05                            ; CD3A A2 05
        dec     IndexI                          ; CD3C CE 36 03
        bne     LCD2D                           ; CD3F D0 EC
        lda     WorkFloat                       ; CD41 AD CD 02
        sta     IndexI                          ; CD44 8D 36 03
        dec     IndexJ                          ; CD47 CE 38 03
        bne     LCD2D                           ; CD4A D0 E1
        rts                                     ; CD4C 60

; ----------------------------------------------------------------------------
; Print drive status through carriage return, close channels, reset BASIC stack, return to READY.
DiskError:
        jsr     K_CHROUT                        ; CD4D 20 D2 FF
        jsr     K_CHRIN                         ; CD50 20 CF FF
        cmp     #$0D                            ; CD53 C9 0D
        bne     DiskError                       ; CD55 D0 F6
        jsr     K_CHROUT                        ; CD57 20 D2 FF
        jsr     K_CLALL                         ; CD5A 20 E7 FF
        jsr     BASIC_RESET_STACK               ; CD5D 20 7A A6
        jmp     BASIC_READY                     ; CD60 4C 74 A4

; ----------------------------------------------------------------------------
; Append comma-R, read dimensions, rebuild BASIC storage, then read parameters and matrices.
LoadNetwork:
        jsr     OpenStatusChannel               ; CD63 20 0E CF
        jsr     BASIC_COMMA                     ; CD66 20 FD AE
        jsr     BASIC_EVAL                      ; CD69 20 9E AD
        jsr     BASIC_REQUIRE_STRING            ; CD6C 20 8F AD
        jsr     BASIC_STRING_DATA               ; CD6F 20 A6 B6
        sta     IndexI                          ; CD72 8D 36 03
        ldy     #$00                            ; CD75 A0 00
LCD77:
        lda     (BASIC_INDEX),y                 ; CD77 B1 22
        sta     FilenameBuffer,y                ; CD79 99 DD 02
        iny                                     ; CD7C C8
        cpy     IndexI                          ; CD7D CC 36 03
        beq     LCD86                           ; CD80 F0 04
        cpy     #$14                            ; CD82 C0 14
        bne     LCD77                           ; CD84 D0 F1
LCD86:
        lda     #$2C                            ; CD86 A9 2C
        sta     FilenameBuffer,y                ; CD88 99 DD 02
        iny                                     ; CD8B C8
        lda     #$52                            ; CD8C A9 52
        sta     FilenameBuffer,y                ; CD8E 99 DD 02
        iny                                     ; CD91 C8
        tya                                     ; CD92 98
        ldx     #$DD                            ; CD93 A2 DD
        ldy     #$02                            ; CD95 A0 02
        jsr     K_SETNAM                        ; CD97 20 BD FF
        lda     #$01                            ; CD9A A9 01
        ldx     #$08                            ; CD9C A2 08
        ldy     #$02                            ; CD9E A0 02
        jsr     K_SETLFS                        ; CDA0 20 BA FF
        jsr     K_OPEN                          ; CDA3 20 C0 FF
        ldx     #$0F                            ; CDA6 A2 0F
        jsr     K_CHKIN                         ; CDA8 20 C6 FF
        jsr     K_CHRIN                         ; CDAB 20 CF FF
        cmp     #$30                            ; CDAE C9 30
        bne     DiskError                       ; CDB0 D0 9B
        jsr     K_CLRCHN                        ; CDB2 20 CC FF
        ldx     #$01                            ; CDB5 A2 01
        jsr     K_CHKIN                         ; CDB7 20 C6 FF
        jsr     K_CHRIN                         ; CDBA 20 CF FF
        sta     InputCount                      ; CDBD 8D A9 02
        jsr     K_CHRIN                         ; CDC0 20 CF FF
        sta     HiddenCount                     ; CDC3 8D AA 02
        jsr     K_CHRIN                         ; CDC6 20 CF FF
        sta     OutputCount                     ; CDC9 8D AB 02
        jsr     K_CHRIN                         ; CDCC 20 CF FF
        sta     PatternCount                    ; CDCF 8D AC 02
        jsr     RecreateForLoad                 ; CDD2 20 B9 CE
        ldx     RateOffset                      ; CDD5 AE AD 02
        ldy     RateOffset+1                    ; CDD8 AC AE 02
        jsr     ReadScalar                      ; CDDB 20 65 CE
        ldx     MomentumOffset                  ; CDDE AE B1 02
        ldy     MomentumOffset+1                ; CDE1 AC B2 02
        jsr     ReadScalar                      ; CDE4 20 65 CE
        ldx     EpsilonOffset                   ; CDE7 AE AF 02
        ldy     EpsilonOffset+1                 ; CDEA AC B0 02
        jsr     ReadScalar                      ; CDED 20 65 CE
        lda     W1Offset                        ; CDF0 AD BF 02
        sta     BASIC_INDEX                     ; CDF3 85 22
        lda     W1Offset+1                      ; CDF5 AD C0 02
        sta     BASIC_INDEX+1                   ; CDF8 85 23
        ldy     HiddenCount                     ; CDFA AC AA 02
        ldx     InputCount                      ; CDFD AE A9 02
        jsr     ReadMatrix                      ; CE00 20 7D CE
        lda     W2Offset                        ; CE03 AD C1 02
        sta     BASIC_INDEX                     ; CE06 85 22
        lda     W2Offset+1                      ; CE08 AD C2 02
        sta     BASIC_INDEX+1                   ; CE0B 85 23
        ldy     OutputCount                     ; CE0D AC AB 02
        ldx     HiddenCount                     ; CE10 AE AA 02
        jsr     ReadMatrix                      ; CE13 20 7D CE
        lda     M1Offset                        ; CE16 AD C3 02
        sta     BASIC_INDEX                     ; CE19 85 22
        lda     M1Offset+1                      ; CE1B AD C4 02
        sta     BASIC_INDEX+1                   ; CE1E 85 23
        ldy     HiddenCount                     ; CE20 AC AA 02
        ldx     InputCount                      ; CE23 AE A9 02
        jsr     ReadMatrix                      ; CE26 20 7D CE
        lda     M2Offset                        ; CE29 AD C5 02
        sta     BASIC_INDEX                     ; CE2C 85 22
        lda     M2Offset+1                      ; CE2E AD C6 02
        sta     BASIC_INDEX+1                   ; CE31 85 23
        ldy     OutputCount                     ; CE33 AC AB 02
        ldx     HiddenCount                     ; CE36 AE AA 02
        jsr     ReadMatrix                      ; CE39 20 7D CE
        lda     InputOffset                     ; CE3C AD C9 02
        sta     BASIC_INDEX                     ; CE3F 85 22
        lda     InputOffset+1                   ; CE41 AD CA 02
        sta     BASIC_INDEX+1                   ; CE44 85 23
        ldy     InputCount                      ; CE46 AC A9 02
        ldx     PatternCount                    ; CE49 AE AC 02
        jsr     ReadMatrix                      ; CE4C 20 7D CE
        lda     TeacherOffset                   ; CE4F AD C7 02
        sta     BASIC_INDEX                     ; CE52 85 22
        lda     TeacherOffset+1                 ; CE54 AD C8 02
        sta     BASIC_INDEX+1                   ; CE57 85 23
        ldy     OutputCount                     ; CE59 AC AB 02
        ldx     PatternCount                    ; CE5C AE AC 02
        jsr     ReadMatrix                      ; CE5F 20 7D CE
        jmp     CloseNetworkFiles               ; CE62 4C 20 CF

; ----------------------------------------------------------------------------
; Read five bytes into a VARTAB-relative scalar.
ReadScalar:
        txa                                     ; CE65 8A
        clc                                     ; CE66 18
        adc     BASIC_VARTAB                    ; CE67 65 2D
        sta     BASIC_INDEX                     ; CE69 85 22
        tya                                     ; CE6B 98
        adc     BASIC_VARTAB+1                  ; CE6C 65 2E
        sta     BASIC_INDEX+1                   ; CE6E 85 23
        ldy     #$00                            ; CE70 A0 00
LCE72:
        jsr     K_CHRIN                         ; CE72 20 CF FF
        sta     (BASIC_INDEX),y                 ; CE75 91 22
        iny                                     ; CE77 C8
        cpy     #$05                            ; CE78 C0 05
        bne     LCE72                           ; CE7A D0 F6
        rts                                     ; CE7C 60

; ----------------------------------------------------------------------------
; Read all matrix elements including allocated row/column zero.
ReadMatrix:
        lda     BASIC_ARYTAB                    ; CE7D A5 2F
        clc                                     ; CE7F 18
        adc     BASIC_INDEX                     ; CE80 65 22
        sta     BASIC_INDEX                     ; CE82 85 22
        lda     BASIC_ARYTAB+1                  ; CE84 A5 30
        adc     BASIC_INDEX+1                   ; CE86 65 23
        sta     BASIC_INDEX+1                   ; CE88 85 23
        iny                                     ; CE8A C8
        sty     IndexI                          ; CE8B 8C 36 03
        sty     WorkFloat                       ; CE8E 8C CD 02
        inx                                     ; CE91 E8
        stx     IndexJ                          ; CE92 8E 38 03
        ldy     #$00                            ; CE95 A0 00
        ldx     #$05                            ; CE97 A2 05
LCE99:
        jsr     K_CHRIN                         ; CE99 20 CF FF
        sta     (BASIC_INDEX),y                 ; CE9C 91 22
        iny                                     ; CE9E C8
        bne     LCEA3                           ; CE9F D0 02
        inc     BASIC_INDEX+1                   ; CEA1 E6 23
LCEA3:
        dex                                     ; CEA3 CA
        bne     LCE99                           ; CEA4 D0 F3
        ldx     #$05                            ; CEA6 A2 05
        dec     IndexI                          ; CEA8 CE 36 03
        bne     LCE99                           ; CEAB D0 EC
        lda     WorkFloat                       ; CEAD AD CD 02
        sta     IndexI                          ; CEB0 8D 36 03
        dec     IndexJ                          ; CEB3 CE 38 03
        bne     LCE99                           ; CEB6 D0 E1
        rts                                     ; CEB8 60

; ----------------------------------------------------------------------------
; Reset BASIC array/string boundaries and recreate the network using saved dimensions.
RecreateForLoad:
        lda     BASIC_MEMSIZ                    ; CEB9 A5 37
        ldy     BASIC_MEMSIZ+1                  ; CEBB A4 38
        sta     BASIC_FRETOP                    ; CEBD 85 33
        sty     BASIC_FRETOP+1                  ; CEBF 84 34
        lda     BASIC_VARTAB                    ; CEC1 A5 2D
        ldy     BASIC_VARTAB+1                  ; CEC3 A4 2E
        sta     BASIC_ARYTAB                    ; CEC5 85 2F
        sty     BASIC_ARYTAB+1                  ; CEC7 84 30
        sta     BASIC_STREND                    ; CEC9 85 31
        sty     BASIC_STREND+1                  ; CECB 84 32
        lda     BASIC_TXTPTR                    ; CECD A5 7A
        sta     SavedTextPtr                    ; CECF 8D A7 02
        lda     BASIC_TXTPTR+1                  ; CED2 A5 7B
        sta     SavedTextPtr+1                  ; CED4 8D A8 02
        lda     #$8B                            ; CED7 A9 8B
        sta     BASIC_TXTPTR                    ; CED9 85 7A
        lda     #$CF                            ; CEDB A9 CF
        sta     BASIC_TXTPTR+1                  ; CEDD 85 7B
        jsr     BASIC_VARIABLE                  ; CEDF 20 8B B0
        sta     RateOffset                      ; CEE2 8D AD 02
        sty     RateOffset+1                    ; CEE5 8C AE 02
        lda     #$8E                            ; CEE8 A9 8E
        sta     BASIC_TXTPTR                    ; CEEA 85 7A
        lda     #$CF                            ; CEEC A9 CF
        sta     BASIC_TXTPTR+1                  ; CEEE 85 7B
        jsr     BASIC_VARIABLE                  ; CEF0 20 8B B0
        sta     MomentumOffset                  ; CEF3 8D B1 02
        sty     MomentumOffset+1                ; CEF6 8C B2 02
        lda     #$91                            ; CEF9 A9 91
        sta     BASIC_TXTPTR                    ; CEFB 85 7A
        lda     #$CF                            ; CEFD A9 CF
        sta     BASIC_TXTPTR+1                  ; CEFF 85 7B
        jsr     BASIC_VARIABLE                  ; CF01 20 8B B0
        sta     EpsilonOffset                   ; CF04 8D AF 02
        sty     EpsilonOffset+1                 ; CF07 8C B0 02
        jsr     CreateBasicStorage              ; CF0A 20 E2 C0
        rts                                     ; CF0D 60

; ----------------------------------------------------------------------------
; Open logical file 15 on device 8, secondary address 15.
OpenStatusChannel:
        lda     #$00                            ; CF0E A9 00
        jsr     K_SETNAM                        ; CF10 20 BD FF
        lda     #$0F                            ; CF13 A9 0F
        ldx     #$08                            ; CF15 A2 08
        ldy     #$0F                            ; CF17 A0 0F
        jsr     K_SETLFS                        ; CF19 20 BA FF
        jsr     K_OPEN                          ; CF1C 20 C0 FF
        rts                                     ; CF1F 60

; ----------------------------------------------------------------------------
; Restore default channels and close logical files 1 and 15.
CloseNetworkFiles:
        jsr     K_CLRCHN                        ; CF20 20 CC FF
        lda     #$01                            ; CF23 A9 01
        jsr     K_CLOSE                         ; CF25 20 C3 FF
        lda     #$0F                            ; CF28 A9 0F
        jsr     K_CLOSE                         ; CF2A 20 C3 FF
        rts                                     ; CF2D 60

; ----------------------------------------------------------------------------
; BASIC DIM argument text, not executable 6502 instructions.
DimExpressions:
        .byte   "O2(P2),O3(P3),E2(P2),E3(P3),W1("; CF2E 4F 32 28 50 32 29 2C 4F
                                                ; CF36 33 28 50 33 29 2C 45 32
                                                ; CF3E 28 50 32 29 2C 45 33 28
                                                ; CF46 50 33 29 2C 57 31 28
        .byte   "P2,P1),W2(P3,P2),M1(P2,P1),M2(P"; CF4D 50 32 2C 50 31 29 2C 57
                                                ; CF55 32 28 50 33 2C 50 32 29
                                                ; CF5D 2C 4D 31 28 50 32 2C 50
                                                ; CF65 31 29 2C 4D 32 28 50
        .byte   "3,P2),T(P3,NP),IN(P1,NP),E(NP)"; CF6C 33 2C 50 32 29 2C 54 28
                                                ; CF74 50 33 2C 4E 50 29 2C 49
                                                ; CF7C 4E 28 50 31 2C 4E 50 29
                                                ; CF84 2C 45 28 4E 50 29
        .byte   $00                             ; CF8A 00
; BASIC stores only the first two characters of a variable name: RA is RATE.
NameRate:
        .byte   "RA"                            ; CF8B 52 41
        .byte   $00                             ; CF8D 00
; MO is MOMENTUM.
NameMomentum:
        .byte   "MO"                            ; CF8E 4D 4F
        .byte   $00                             ; CF90 00
; EP is EPSILON.
NameEpsilon:
        .byte   "EP"                            ; CF91 45 50
        .byte   $00                             ; CF93 00
; Input dimension.
NameP1:
        .byte   "P1"                            ; CF94 50 31
        .byte   $00                             ; CF96 00
; Hidden dimension.
NameP2:
        .byte   "P2"                            ; CF97 50 32
        .byte   $00                             ; CF99 00
; Output dimension.
NameP3:
        .byte   "P3"                            ; CF9A 50 33
        .byte   $00                             ; CF9C 00
; Pattern count.
NameNP:
        .byte   "NP"                            ; CF9D 4E 50
        .byte   $00                             ; CF9F 00
; Embedded O1(0) text retained from the binary; not part of the DIM list.
NameO1Unused:
        .byte   "O1(0)"                         ; CFA0 4F 31 28 30 29
        .byte   $00                             ; CFA5 00
; Lookup text for hidden outputs, starting at index zero.
NameO2:
        .byte   "O2(0)"                         ; CFA6 4F 32 28 30 29
        .byte   $00                             ; CFAB 00
; Lookup text for output outputs.
NameO3:
        .byte   "O3(0)"                         ; CFAC 4F 33 28 30 29
        .byte   $00                             ; CFB1 00
; Lookup text for IN(0,0).
NameInput:
        .byte   "IN(0,0)"                       ; CFB2 49 4E 28 30 2C 30 29
        .byte   $00                             ; CFB9 00
; Lookup text for W1(0,0).
NameW1:
        .byte   "W1(0,0)"                       ; CFBA 57 31 28 30 2C 30 29
        .byte   $00                             ; CFC1 00
; Lookup text for W2(0,0).
NameW2:
        .byte   "W2(0,0)"                       ; CFC2 57 32 28 30 2C 30 29
        .byte   $00                             ; CFC9 00
; Lookup text for hidden deltas.
NameE2:
        .byte   "E2(0)"                         ; CFCA 45 32 28 30 29
        .byte   $00                             ; CFCF 00
; Lookup text for output deltas.
NameE3:
        .byte   "E3(0)"                         ; CFD0 45 33 28 30 29
        .byte   $00                             ; CFD5 00
; Lookup text for teacher patterns.
NameTeacher:
        .byte   "T(0,0)"                        ; CFD6 54 28 30 2C 30 29
        .byte   $00                             ; CFDC 00
; Lookup text for prior W1 changes.
NameM1:
        .byte   "M1(0,0)"                       ; CFDD 4D 31 28 30 2C 30 29
        .byte   $00                             ; CFE4 00
; Lookup text for prior W2 changes.
NameM2:
        .byte   "M2(0,0)"                       ; CFE5 4D 32 28 30 2C 30 29
        .byte   $00                             ; CFEC 00
; Lookup text for per-pattern error.
NameError:
        .byte   "E(0)"                          ; CFED 45 28 30 29
        .byte   $00                             ; CFF1 00
; ----------------------------------------------------------------------------
; Commodore five-byte floating-point zero.
FloatZero:
        .byte   $00,$00,$00,$00,$00             ; CFF2 00 00 00 00 00
; Commodore five-byte floating-point one: exponent byte $81, zero mantissa/sign bytes.
FloatOne:
        .byte   $81,$00,$00,$00,$00             ; CFF7 81 00 00 00 00
; ----------------------------------------------------------------------------
; Null-terminated TE name. The original file stops at $CFFE; printed $CFFF is absent.
NameTotalError:
        .byte   "TE"                            ; CFFC 54 45
        .byte   $00                             ; CFFE 00

PayloadEnd:
.assert PayloadEnd-PayloadStart = 4095, error, "Original payload length changed"

