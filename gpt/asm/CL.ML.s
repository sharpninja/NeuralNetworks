; CL.ML - annotated reconstruction for ca65, 2026-09-16.
; Original neural-network engine: Kevin E. Martin / COMPUTE! Publications, 1990.
; Context: Future Computing: Neural Networks, March 1990, printed pp.42-46.
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
OutputCount     := $02AA                        ; P2: competing output neurons/clusters.
PatternCount    := $02AC                        ; NP: number of training patterns.
RateOffset      := $02AD                        ; RA: relative to BASIC_VARTAB after initialization.
O2Offset        := $02B3                        ; O2(0), relative to BASIC_ARYTAB after initialization.
PatternIndex    := $02BB                        ; Training pattern number; zero selects recognition scratch input.
W1Offset        := $02BF                        ; W1(0,0): cluster weights, relative to BASIC_ARYTAB.
InputOffset     := $02C1                        ; IN(0,0), relative to BASIC_ARYTAB.
OrderOffset     := $02C3                        ; PAT(0): pattern presentation order, relative to BASIC_ARYTAB.
Winner          := $02C5                        ; Index of the currently winning output neuron.
OrderIndex      := $02C6                        ; Position in the shuffled PAT() order.
TrialsRemaining := $02C7                        ; Low/high counter used by the SYS 49164 training loop.
WorkFloat       := $02CD                        ; Temporary five-byte float; also reused as pointer/count scratch.
FilenameBuffer  := $02DD                        ; Up to 20 filename characters followed by comma and R or W.
ElementPtr      := $0334                        ; Absolute address of a BASIC five-byte array element.
IndexI          := $0336                        ; Outer loop index; reused by I/O loops.
IndexJ          := $0338                        ; Inner loop index; reused by I/O loops.
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
; SYS 49152,p1,p2,np,rate. Article: March p.43; DIPOLE supplies 16,2,24,0.1.
CL_Init:
        jmp     InitializeNetwork               ; C000 4C 18 C0

; ----------------------------------------------------------------------------
; SYS 49155,pattern. Classification appears in O2(). March p.44.
CL_Recognize:
        jmp     RecognizeString                 ; C003 4C 47 C2

; ----------------------------------------------------------------------------
; Unused compatibility slot containing NOP,NOP,RTS. Preserve all three bytes.
CL_Reserved1:
        nop                                     ; C006 EA
        nop                                     ; C007 EA
        rts                                     ; C008 60

; ----------------------------------------------------------------------------
; Second unused compatibility slot, also NOP,NOP,RTS.
CL_Reserved2:
        nop                                     ; C009 EA
        nop                                     ; C00A EA
        rts                                     ; C00B 60

; ----------------------------------------------------------------------------
; SYS 49164,trials. Train over all patterns for each requested trial. March pp.43-44.
CL_Learn:
        jmp     LearnTrials                     ; C00C 4C FD C5

; ----------------------------------------------------------------------------
; SYS 49167,number,input_string. No teacher pattern: learning is unsupervised.
CL_DefinePattern:
        jmp     DefinePattern                   ; C00F 4C 31 C6

; ----------------------------------------------------------------------------
; SYS 49170,filename. Save dimensions, rate, weights and input patterns. March p.44.
CL_Save:
        jmp     SaveNetwork                     ; C012 4C E8 C6

; ----------------------------------------------------------------------------
; SYS 49173,filename. Rebuild BASIC storage and restore the saved network.
CL_Load:
        jmp     LoadNetwork                     ; C015 4C F0 C7

; ----------------------------------------------------------------------------
; Parse P1/P2/NP byte values and the floating-point learning rate.
InitializeNetwork:
        jsr     BASIC_COMMA                     ; C018 20 FD AE
        jsr     BASIC_GET_BYTE                  ; C01B 20 9E B7
        stx     InputCount                      ; C01E 8E A9 02
        jsr     BASIC_COMMA                     ; C021 20 FD AE
        jsr     BASIC_GET_BYTE                  ; C024 20 9E B7
        stx     OutputCount                     ; C027 8E AA 02
        jsr     BASIC_COMMA                     ; C02A 20 FD AE
        jsr     BASIC_GET_BYTE                  ; C02D 20 9E B7
        stx     PatternCount                    ; C030 8E AC 02
        jsr     BASIC_COMMA                     ; C033 20 FD AE
        lda     BASIC_TXTPTR                    ; C036 A5 7A
        sta     SavedTextPtr                    ; C038 8D A7 02
        lda     BASIC_TXTPTR+1                  ; C03B A5 7B
        sta     SavedTextPtr+1                  ; C03D 8D A8 02
        lda     #$58                            ; C040 A9 58
        sta     BASIC_TXTPTR                    ; C042 85 7A
        lda     #$C9                            ; C044 A9 C9
        sta     BASIC_TXTPTR+1                  ; C046 85 7B
        jsr     BASIC_VARIABLE                  ; C048 20 8B B0
        sta     RateOffset                      ; C04B 8D AD 02
        sty     RateOffset+1                    ; C04E 8C AE 02
        lda     SavedTextPtr                    ; C051 AD A7 02
        sta     BASIC_TXTPTR                    ; C054 85 7A
        lda     SavedTextPtr+1                  ; C056 AD A8 02
        sta     BASIC_TXTPTR+1                  ; C059 85 7B
        jsr     BASIC_EVAL_NUMBER               ; C05B 20 8A AD
        ldx     RateOffset                      ; C05E AE AD 02
        ldy     RateOffset+1                    ; C061 AC AE 02
        jsr     FP_STORE                        ; C064 20 D4 BB
        lda     BASIC_TXTPTR                    ; C067 A5 7A
        sta     SavedTextPtr                    ; C069 8D A7 02
        lda     BASIC_TXTPTR+1                  ; C06C A5 7B
        sta     SavedTextPtr+1                  ; C06E 8D A8 02
; Create scalar dimensions and DIM O2/W1/IN/PAT. PAT is an implementation work array absent from the article table.
CreateBasicStorage:
        lda     #$5B                            ; C071 A9 5B
        sta     BASIC_TXTPTR                    ; C073 85 7A
        lda     #$C9                            ; C075 A9 C9
        sta     BASIC_TXTPTR+1                  ; C077 85 7B
        jsr     BASIC_VARIABLE                  ; C079 20 8B B0
        pha                                     ; C07C 48
        tya                                     ; C07D 98
        pha                                     ; C07E 48
        lda     InputCount                      ; C07F AD A9 02
        jsr     FP_FROM_BYTE                    ; C082 20 3C BC
        pla                                     ; C085 68
        tay                                     ; C086 A8
        pla                                     ; C087 68
        tax                                     ; C088 AA
        jsr     FP_STORE                        ; C089 20 D4 BB
        lda     #$5E                            ; C08C A9 5E
        sta     BASIC_TXTPTR                    ; C08E 85 7A
        lda     #$C9                            ; C090 A9 C9
        sta     BASIC_TXTPTR+1                  ; C092 85 7B
        jsr     BASIC_VARIABLE                  ; C094 20 8B B0
        pha                                     ; C097 48
        tya                                     ; C098 98
        pha                                     ; C099 48
        lda     OutputCount                     ; C09A AD AA 02
        jsr     FP_FROM_BYTE                    ; C09D 20 3C BC
        pla                                     ; C0A0 68
        tay                                     ; C0A1 A8
        pla                                     ; C0A2 68
        tax                                     ; C0A3 AA
        jsr     FP_STORE                        ; C0A4 20 D4 BB
        lda     #$61                            ; C0A7 A9 61
        sta     BASIC_TXTPTR                    ; C0A9 85 7A
        lda     #$C9                            ; C0AB A9 C9
        sta     BASIC_TXTPTR+1                  ; C0AD 85 7B
        jsr     BASIC_VARIABLE                  ; C0AF 20 8B B0
        pha                                     ; C0B2 48
        tya                                     ; C0B3 98
        pha                                     ; C0B4 48
        lda     PatternCount                    ; C0B5 AD AC 02
        jsr     FP_FROM_BYTE                    ; C0B8 20 3C BC
        pla                                     ; C0BB 68
        tay                                     ; C0BC A8
        pla                                     ; C0BD 68
        tax                                     ; C0BE AA
        jsr     FP_STORE                        ; C0BF 20 D4 BB
        lda     #$35                            ; C0C2 A9 35
        sta     BASIC_TXTPTR                    ; C0C4 85 7A
        lda     #$C9                            ; C0C6 A9 C9
        sta     BASIC_TXTPTR+1                  ; C0C8 85 7B
        lda     DimExpressions                  ; C0CA AD 35 C9
        jsr     BASIC_DIM                       ; C0CD 20 81 B0
        lda     #$64                            ; C0D0 A9 64
        sta     BASIC_TXTPTR                    ; C0D2 85 7A
        lda     #$C9                            ; C0D4 A9 C9
        sta     BASIC_TXTPTR+1                  ; C0D6 85 7B
        jsr     BASIC_VARIABLE                  ; C0D8 20 8B B0
        sta     O2Offset                        ; C0DB 8D B3 02
        sty     O2Offset+1                      ; C0DE 8C B4 02
        lda     #$01                            ; C0E1 A9 01
        jsr     FP_FROM_BYTE                    ; C0E3 20 3C BC
        ldx     O2Offset                        ; C0E6 AE B3 02
        ldy     O2Offset+1                      ; C0E9 AC B4 02
        jsr     FP_STORE                        ; C0EC 20 D4 BB
        lda     #$6A                            ; C0EF A9 6A
        sta     BASIC_TXTPTR                    ; C0F1 85 7A
        lda     #$C9                            ; C0F3 A9 C9
        sta     BASIC_TXTPTR+1                  ; C0F5 85 7B
        jsr     BASIC_VARIABLE                  ; C0F7 20 8B B0
        sta     InputOffset                     ; C0FA 8D C1 02
        sty     InputOffset+1                   ; C0FD 8C C2 02
        lda     #$01                            ; C100 A9 01
        sta     IndexI                          ; C102 8D 36 03
        lda     #$00                            ; C105 A9 00
        sta     IndexJ                          ; C107 8D 38 03
        lda     #$72                            ; C10A A9 72
        sta     BASIC_TXTPTR                    ; C10C 85 7A
        lda     #$C9                            ; C10E A9 C9
        sta     BASIC_TXTPTR+1                  ; C110 85 7B
        jsr     BASIC_VARIABLE                  ; C112 20 8B B0
        sta     W1Offset                        ; C115 8D BF 02
        sty     W1Offset+1                      ; C118 8C C0 02
; Use W1(cluster,0) as a sum accumulator; generate random weights for input indices 1..P1.
InitializeClusterWeights:
        lda     IndexJ                          ; C11B AD 38 03
        bne     RandomWeight                    ; C11E D0 11
        lda     #$00                            ; C120 A9 00
        jsr     FP_FROM_BYTE                    ; C122 20 3C BC
        ldy     W1Offset+1                      ; C125 AC C0 02
        ldx     W1Offset                        ; C128 AE BF 02
        jsr     FP_STORE                        ; C12B 20 D4 BB
        jmp     LC175                           ; C12E 4C 75 C1

; ----------------------------------------------------------------------------
; RND(1) supplies a positive initial weight and is added to this cluster's accumulator.
RandomWeight:
        lda     #$01                            ; C131 A9 01
        jsr     FP_FROM_BYTE                    ; C133 20 3C BC
        jsr     FP_RND                          ; C136 20 97 E0
        lda     W1Offset                        ; C139 AD BF 02
        sta     ElementPtr                      ; C13C 8D 34 03
        lda     W1Offset+1                      ; C13F AD C0 02
        sta     ElementPtr+1                    ; C142 8D 35 03
        ldy     IndexI                          ; C145 AC 36 03
        ldx     IndexJ                          ; C148 AE 38 03
        lda     OutputCount                     ; C14B AD AA 02
        jsr     IndexMatrix                     ; C14E 20 92 C3
        ldy     ElementPtr+1                    ; C151 AC 35 03
        ldx     ElementPtr                      ; C154 AE 34 03
        jsr     FP_STORE                        ; C157 20 D4 BB
        lda     W1Offset                        ; C15A AD BF 02
        ldy     W1Offset+1                      ; C15D AC C0 02
        jsr     FP_LOAD                         ; C160 20 A2 BB
        lda     ElementPtr                      ; C163 AD 34 03
        ldy     ElementPtr+1                    ; C166 AC 35 03
        jsr     FP_ADD_MEM                      ; C169 20 67 B8
        ldx     W1Offset                        ; C16C AE BF 02
        ldy     W1Offset+1                      ; C16F AC C0 02
        jsr     FP_STORE                        ; C172 20 D4 BB
LC175:
        inc     IndexJ                          ; C175 EE 38 03
        lda     InputCount                      ; C178 AD A9 02
        cmp     IndexJ                          ; C17B CD 38 03
        bcs     InitializeClusterWeights        ; C17E B0 9B
        lda     #$01                            ; C180 A9 01
        sta     IndexJ                          ; C182 8D 38 03
; Divide each input weight by its cluster's initial sum so the P1 weights sum to approximately one.
NormalizeClusterWeights:
        lda     W1Offset                        ; C185 AD BF 02
        sta     ElementPtr                      ; C188 8D 34 03
        lda     W1Offset+1                      ; C18B AD C0 02
        sta     ElementPtr+1                    ; C18E 8D 35 03
        ldy     IndexI                          ; C191 AC 36 03
        ldx     IndexJ                          ; C194 AE 38 03
        lda     OutputCount                     ; C197 AD AA 02
        jsr     IndexMatrix                     ; C19A 20 92 C3
        lda     W1Offset                        ; C19D AD BF 02
        ldy     W1Offset+1                      ; C1A0 AC C0 02
        jsr     FP_LOAD                         ; C1A3 20 A2 BB
        lda     ElementPtr                      ; C1A6 AD 34 03
        ldy     ElementPtr+1                    ; C1A9 AC 35 03
        jsr     FP_MEM_DIV_FAC                  ; C1AC 20 0F BB
        ldy     ElementPtr+1                    ; C1AF AC 35 03
        ldx     ElementPtr                      ; C1B2 AE 34 03
        jsr     FP_STORE                        ; C1B5 20 D4 BB
        inc     IndexJ                          ; C1B8 EE 38 03
        lda     InputCount                      ; C1BB AD A9 02
        cmp     IndexJ                          ; C1BE CD 38 03
        bcs     NormalizeClusterWeights         ; C1C1 B0 C2
        inc     IndexI                          ; C1C3 EE 36 03
        lda     OutputCount                     ; C1C6 AD AA 02
        cmp     IndexI                          ; C1C9 CD 36 03
        bcc     FindOrderArray                  ; C1CC 90 08
        lda     #$00                            ; C1CE A9 00
        sta     IndexJ                          ; C1D0 8D 38 03
        jmp     InitializeClusterWeights        ; C1D3 4C 1B C1

; ----------------------------------------------------------------------------
; Cache PAT(0), then make array/scalar addresses relative to BASIC storage bases.
FindOrderArray:
        lda     #$7A                            ; C1D6 A9 7A
        sta     BASIC_TXTPTR                    ; C1D8 85 7A
        lda     #$C9                            ; C1DA A9 C9
        sta     BASIC_TXTPTR+1                  ; C1DC 85 7B
        jsr     BASIC_VARIABLE                  ; C1DE 20 8B B0
        sta     OrderOffset                     ; C1E1 8D C3 02
        sty     OrderOffset+1                   ; C1E4 8C C4 02
        lda     O2Offset                        ; C1E7 AD B3 02
        sec                                     ; C1EA 38
        sbc     BASIC_ARYTAB                    ; C1EB E5 2F
        sta     O2Offset                        ; C1ED 8D B3 02
        lda     O2Offset+1                      ; C1F0 AD B4 02
        sbc     BASIC_ARYTAB+1                  ; C1F3 E5 30
        sta     O2Offset+1                      ; C1F5 8D B4 02
        lda     W1Offset                        ; C1F8 AD BF 02
        sec                                     ; C1FB 38
        sbc     BASIC_ARYTAB                    ; C1FC E5 2F
        sta     W1Offset                        ; C1FE 8D BF 02
        lda     W1Offset+1                      ; C201 AD C0 02
        sbc     BASIC_ARYTAB+1                  ; C204 E5 30
        sta     W1Offset+1                      ; C206 8D C0 02
        lda     InputOffset                     ; C209 AD C1 02
        sec                                     ; C20C 38
        sbc     BASIC_ARYTAB                    ; C20D E5 2F
        sta     InputOffset                     ; C20F 8D C1 02
        lda     InputOffset+1                   ; C212 AD C2 02
        sbc     BASIC_ARYTAB+1                  ; C215 E5 30
        sta     InputOffset+1                   ; C217 8D C2 02
        lda     OrderOffset                     ; C21A AD C3 02
        sec                                     ; C21D 38
        sbc     BASIC_ARYTAB                    ; C21E E5 2F
        sta     OrderOffset                     ; C220 8D C3 02
        lda     OrderOffset+1                   ; C223 AD C4 02
        sbc     BASIC_ARYTAB+1                  ; C226 E5 30
        sta     OrderOffset+1                   ; C228 8D C4 02
        lda     RateOffset                      ; C22B AD AD 02
        sec                                     ; C22E 38
        sbc     BASIC_VARTAB                    ; C22F E5 2D
        sta     RateOffset                      ; C231 8D AD 02
        lda     RateOffset+1                    ; C234 AD AE 02
        sbc     BASIC_VARTAB+1                  ; C237 E5 2E
        sta     RateOffset+1                    ; C239 8D AE 02
        lda     SavedTextPtr                    ; C23C AD A7 02
        sta     BASIC_TXTPTR                    ; C23F 85 7A
        lda     SavedTextPtr+1                  ; C241 AD A8 02
        sta     BASIC_TXTPTR+1                  ; C244 85 7B
        rts                                     ; C246 60

; ----------------------------------------------------------------------------
; Import the supplied pattern into IN(:,0), then classify scratch pattern zero.
RecognizeString:
        lda     #$00                            ; C247 A9 00
        sta     PatternIndex                    ; C249 8D BB 02
        jsr     ReadInputString                 ; C24C 20 49 C6
; For each cluster compute the input/weight dot product and retain the largest activation.
ClassifyPattern:
        lda     #$01                            ; C24F A9 01
        sta     IndexI                          ; C251 8D 36 03
        lda     #$00                            ; C254 A9 00
        sta     Winner                          ; C256 8D C5 02
; Start a dot-product sum at zero; CL has no BP-style bias input in this loop.
ClusterActivation:
        lda     #$01                            ; C259 A9 01
        sta     IndexJ                          ; C25B 8D 38 03
        lda     #$00                            ; C25E A9 00
        jsr     FP_FROM_BYTE                    ; C260 20 3C BC
LC263:
        ldx     #$CD                            ; C263 A2 CD
        ldy     #$02                            ; C265 A0 02
        jsr     FP_STORE                        ; C267 20 D4 BB
        lda     W1Offset                        ; C26A AD BF 02
        clc                                     ; C26D 18
        adc     BASIC_ARYTAB                    ; C26E 65 2F
        sta     ElementPtr                      ; C270 8D 34 03
        lda     W1Offset+1                      ; C273 AD C0 02
        adc     BASIC_ARYTAB+1                  ; C276 65 30
        sta     ElementPtr+1                    ; C278 8D 35 03
        ldx     IndexJ                          ; C27B AE 38 03
        ldy     IndexI                          ; C27E AC 36 03
        lda     OutputCount                     ; C281 AD AA 02
        jsr     IndexMatrix                     ; C284 20 92 C3
        lda     ElementPtr                      ; C287 AD 34 03
        ldy     ElementPtr+1                    ; C28A AC 35 03
        jsr     FP_LOAD                         ; C28D 20 A2 BB
        lda     InputOffset                     ; C290 AD C1 02
        clc                                     ; C293 18
        adc     BASIC_ARYTAB                    ; C294 65 2F
        sta     ElementPtr                      ; C296 8D 34 03
        lda     InputOffset+1                   ; C299 AD C2 02
        adc     BASIC_ARYTAB+1                  ; C29C 65 30
        sta     ElementPtr+1                    ; C29E 8D 35 03
        ldx     PatternIndex                    ; C2A1 AE BB 02
        ldy     IndexJ                          ; C2A4 AC 38 03
        lda     InputCount                      ; C2A7 AD A9 02
        jsr     IndexMatrix                     ; C2AA 20 92 C3
        lda     ElementPtr                      ; C2AD AD 34 03
        ldy     ElementPtr+1                    ; C2B0 AC 35 03
        jsr     FP_MUL_MEM                      ; C2B3 20 28 BA
        lda     #$CD                            ; C2B6 A9 CD
        ldy     #$02                            ; C2B8 A0 02
        jsr     FP_ADD_MEM                      ; C2BA 20 67 B8
        inc     IndexJ                          ; C2BD EE 38 03
        lda     InputCount                      ; C2C0 AD A9 02
        cmp     IndexJ                          ; C2C3 CD 38 03
        bcs     LC263                           ; C2C6 B0 9B
; Compare this activation with the current winner; keep the earlier winner when it is strictly larger.
SelectWinner:
        lda     Winner                          ; C2C8 AD C5 02
        bne     LC2D5                           ; C2CB D0 08
        lda     #$01                            ; C2CD A9 01
        sta     Winner                          ; C2CF 8D C5 02
        jmp     StoreClusterOutput              ; C2D2 4C 24 C3

; ----------------------------------------------------------------------------
LC2D5:
        ldx     #$CD                            ; C2D5 A2 CD
        ldy     #$02                            ; C2D7 A0 02
        jsr     FP_STORE                        ; C2D9 20 D4 BB
        lda     O2Offset                        ; C2DC AD B3 02
        clc                                     ; C2DF 18
        adc     BASIC_ARYTAB                    ; C2E0 65 2F
        sta     ElementPtr                      ; C2E2 8D 34 03
        lda     O2Offset+1                      ; C2E5 AD B4 02
        adc     BASIC_ARYTAB+1                  ; C2E8 65 30
        sta     ElementPtr+1                    ; C2EA 8D 35 03
        lda     Winner                          ; C2ED AD C5 02
        jsr     IndexVector                     ; C2F0 20 78 C3
        lda     ElementPtr                      ; C2F3 AD 34 03
        ldy     ElementPtr+1                    ; C2F6 AC 35 03
        jsr     FP_LOAD                         ; C2F9 20 A2 BB
        lda     #$CD                            ; C2FC A9 CD
        ldy     #$02                            ; C2FE A0 02
        jsr     FP_COMPARE                      ; C300 20 5B BC
        pha                                     ; C303 48
        lda     #$00                            ; C304 A9 00
        jsr     FP_FROM_BYTE                    ; C306 20 3C BC
        pla                                     ; C309 68
        cmp     #$01                            ; C30A C9 01
        beq     StoreClusterOutput              ; C30C F0 16
        ldx     ElementPtr                      ; C30E AE 34 03
        ldy     ElementPtr+1                    ; C311 AC 35 03
        jsr     FP_STORE                        ; C314 20 D4 BB
        lda     IndexI                          ; C317 AD 36 03
        sta     Winner                          ; C31A 8D C5 02
        lda     #$CD                            ; C31D A9 CD
        ldy     #$02                            ; C31F A0 02
        jsr     FP_LOAD                         ; C321 20 A2 BB
; Store the current retained activation or zero in O2(cluster).
StoreClusterOutput:
        lda     O2Offset                        ; C324 AD B3 02
        clc                                     ; C327 18
        adc     BASIC_ARYTAB                    ; C328 65 2F
        sta     ElementPtr                      ; C32A 8D 34 03
        lda     O2Offset+1                      ; C32D AD B4 02
        adc     BASIC_ARYTAB+1                  ; C330 65 30
        sta     ElementPtr+1                    ; C332 8D 35 03
        lda     IndexI                          ; C335 AD 36 03
        jsr     IndexVector                     ; C338 20 78 C3
        ldx     ElementPtr                      ; C33B AE 34 03
        ldy     ElementPtr+1                    ; C33E AC 35 03
        jsr     FP_STORE                        ; C341 20 D4 BB
        inc     IndexI                          ; C344 EE 36 03
        lda     OutputCount                     ; C347 AD AA 02
        cmp     IndexI                          ; C34A CD 36 03
        bcc     MarkWinner                      ; C34D 90 03
        jmp     ClusterActivation               ; C34F 4C 59 C2

; ----------------------------------------------------------------------------
; Write numeric one to O2(Winner); losing clusters have been cleared during winner selection.
MarkWinner:
        lda     O2Offset                        ; C352 AD B3 02
        clc                                     ; C355 18
        adc     BASIC_ARYTAB                    ; C356 65 2F
        sta     ElementPtr                      ; C358 8D 34 03
        lda     O2Offset+1                      ; C35B AD B4 02
        adc     BASIC_ARYTAB+1                  ; C35E 65 30
        sta     ElementPtr+1                    ; C360 8D 35 03
        lda     Winner                          ; C363 AD C5 02
        jsr     IndexVector                     ; C366 20 78 C3
        lda     #$01                            ; C369 A9 01
        jsr     FP_FROM_BYTE                    ; C36B 20 3C BC
        ldx     ElementPtr                      ; C36E AE 34 03
        ldy     ElementPtr+1                    ; C371 AC 35 03
        jsr     FP_STORE                        ; C374 20 D4 BB
        rts                                     ; C377 60

; ----------------------------------------------------------------------------
; Add 5*A to ElementPtr for a BASIC floating-point array.
IndexVector:
        tax                                     ; C378 AA
        inx                                     ; C379 E8
LC37A:
        dex                                     ; C37A CA
        beq     LC391                           ; C37B F0 14
        lda     ElementPtr                      ; C37D AD 34 03
        clc                                     ; C380 18
        adc     #$05                            ; C381 69 05
        sta     ElementPtr                      ; C383 8D 34 03
        lda     ElementPtr+1                    ; C386 AD 35 03
        adc     #$00                            ; C389 69 00
        sta     ElementPtr+1                    ; C38B 8D 35 03
        jmp     LC37A                           ; C38E 4C 7A C3

; ----------------------------------------------------------------------------
LC391:
        rts                                     ; C391 60

; ----------------------------------------------------------------------------
; Add 5*(X*(A+1)+Y) to ElementPtr, including BASIC's allocated index-zero elements.
IndexMatrix:
        sta     MatrixBound                     ; C392 8D FD 03
        tya                                     ; C395 98
        pha                                     ; C396 48
        inx                                     ; C397 E8
LC398:
        dex                                     ; C398 CA
        beq     LC3C7                           ; C399 F0 2C
        ldy     MatrixBound                     ; C39B AC FD 03
        iny                                     ; C39E C8
        lda     ElementPtr                      ; C39F AD 34 03
        clc                                     ; C3A2 18
        adc     #$05                            ; C3A3 69 05
        sta     ElementPtr                      ; C3A5 8D 34 03
        lda     ElementPtr+1                    ; C3A8 AD 35 03
        adc     #$00                            ; C3AB 69 00
        sta     ElementPtr+1                    ; C3AD 8D 35 03
LC3B0:
        dey                                     ; C3B0 88
        beq     LC398                           ; C3B1 F0 E5
        lda     ElementPtr                      ; C3B3 AD 34 03
        clc                                     ; C3B6 18
        adc     #$05                            ; C3B7 69 05
        sta     ElementPtr                      ; C3B9 8D 34 03
        lda     ElementPtr+1                    ; C3BC AD 35 03
        adc     #$00                            ; C3BF 69 00
        sta     ElementPtr+1                    ; C3C1 8D 35 03
        jmp     LC3B0                           ; C3C4 4C B0 C3

; ----------------------------------------------------------------------------
LC3C7:
        pla                                     ; C3C7 68
        jmp     IndexVector                     ; C3C8 4C 78 C3

; ----------------------------------------------------------------------------
; Formatting helper retained in this binary; no internal JSR targets it.
PrintFloatUnused:
        jsr     FP_FORMAT                       ; C3CB 20 DD BD
        ldy     #$FF                            ; C3CE A0 FF
LC3D0:
        iny                                     ; C3D0 C8
        lda     BASIC_PRINT_BUFFER,y            ; C3D1 B9 00 01
        bne     LC3D0                           ; C3D4 D0 FA
        iny                                     ; C3D6 C8
        tya                                     ; C3D7 98
        pha                                     ; C3D8 48
        lda     #$00                            ; C3D9 A9 00
        sta     BASIC_INDEX                     ; C3DB 85 22
        lda     #$01                            ; C3DD A9 01
        sta     BASIC_INDEX+1                   ; C3DF 85 23
        pla                                     ; C3E1 68
        jsr     BASIC_PRINT_STRING              ; C3E2 20 24 AB
        rts                                     ; C3E5 60

; ----------------------------------------------------------------------------
; Fill PAT(i)=i, shuffle the order, classify each pattern, and update the winning cluster.
TrainEpoch:
        lda     #$01                            ; C3E6 A9 01
        sta     IndexI                          ; C3E8 8D 36 03
LC3EB:
        lda     OrderOffset                     ; C3EB AD C3 02
        clc                                     ; C3EE 18
        adc     BASIC_ARYTAB                    ; C3EF 65 2F
        sta     ElementPtr                      ; C3F1 8D 34 03
        lda     OrderOffset+1                   ; C3F4 AD C4 02
        adc     BASIC_ARYTAB+1                  ; C3F7 65 30
        sta     ElementPtr+1                    ; C3F9 8D 35 03
        lda     IndexI                          ; C3FC AD 36 03
        jsr     IndexVector                     ; C3FF 20 78 C3
        lda     IndexI                          ; C402 AD 36 03
        jsr     FP_FROM_BYTE                    ; C405 20 3C BC
        ldx     ElementPtr                      ; C408 AE 34 03
        ldy     ElementPtr+1                    ; C40B AC 35 03
        jsr     FP_STORE                        ; C40E 20 D4 BB
        inc     IndexI                          ; C411 EE 36 03
        lda     PatternCount                    ; C414 AD AC 02
        cmp     IndexI                          ; C417 CD 36 03
        bcs     LC3EB                           ; C41A B0 CF
        lda     #$01                            ; C41C A9 01
        sta     IndexI                          ; C41E 8D 36 03
; For each position i, swap PAT(i) with PAT(i+INT(RND(1)*(NP+1-i))).
ShufflePatterns:
        ldy     PatternCount                    ; C421 AC AC 02
        iny                                     ; C424 C8
        tya                                     ; C425 98
        sec                                     ; C426 38
        sbc     IndexI                          ; C427 ED 36 03
        jsr     FP_FROM_BYTE                    ; C42A 20 3C BC
        ldx     #$CD                            ; C42D A2 CD
        ldy     #$02                            ; C42F A0 02
        jsr     FP_STORE                        ; C431 20 D4 BB
        lda     #$01                            ; C434 A9 01
        jsr     FP_FROM_BYTE                    ; C436 20 3C BC
        jsr     FP_RND                          ; C439 20 97 E0
        lda     #$CD                            ; C43C A9 CD
        ldy     #$02                            ; C43E A0 02
        jsr     FP_MUL_MEM                      ; C440 20 28 BA
        jsr     FP_INT                          ; C443 20 CC BC
        ldx     #$CD                            ; C446 A2 CD
        ldy     #$02                            ; C448 A0 02
        jsr     FP_STORE                        ; C44A 20 D4 BB
        lda     IndexI                          ; C44D AD 36 03
        jsr     FP_FROM_BYTE                    ; C450 20 3C BC
        lda     #$CD                            ; C453 A9 CD
        ldy     #$02                            ; C455 A0 02
        jsr     FP_ADD_MEM                      ; C457 20 67 B8
        jsr     BASIC_FAC_TO_BYTE               ; C45A 20 A1 B7
        stx     IndexJ                          ; C45D 8E 38 03
        lda     OrderOffset                     ; C460 AD C3 02
        clc                                     ; C463 18
        adc     BASIC_ARYTAB                    ; C464 65 2F
        sta     ElementPtr                      ; C466 8D 34 03
        lda     OrderOffset+1                   ; C469 AD C4 02
        adc     BASIC_ARYTAB+1                  ; C46C 65 30
        sta     ElementPtr+1                    ; C46E 8D 35 03
        lda     IndexI                          ; C471 AD 36 03
        jsr     IndexVector                     ; C474 20 78 C3
        lda     ElementPtr                      ; C477 AD 34 03
        sta     WorkFloat                       ; C47A 8D CD 02
        ldy     ElementPtr+1                    ; C47D AC 35 03
        sty     WorkFloat+1                     ; C480 8C CE 02
        jsr     FP_LOAD_ARG                     ; C483 20 8C BA
        lda     OrderOffset                     ; C486 AD C3 02
        clc                                     ; C489 18
        adc     BASIC_ARYTAB                    ; C48A 65 2F
        sta     ElementPtr                      ; C48C 8D 34 03
        lda     OrderOffset+1                   ; C48F AD C4 02
        adc     BASIC_ARYTAB+1                  ; C492 65 30
        sta     ElementPtr+1                    ; C494 8D 35 03
        lda     IndexJ                          ; C497 AD 38 03
        jsr     IndexVector                     ; C49A 20 78 C3
        lda     ElementPtr                      ; C49D AD 34 03
        ldy     ElementPtr+1                    ; C4A0 AC 35 03
        jsr     FP_LOAD                         ; C4A3 20 A2 BB
        ldx     WorkFloat                       ; C4A6 AE CD 02
        ldy     WorkFloat+1                     ; C4A9 AC CE 02
        jsr     FP_STORE                        ; C4AC 20 D4 BB
        jsr     FP_ARG_TO_FAC                   ; C4AF 20 FC BB
        ldx     ElementPtr                      ; C4B2 AE 34 03
        ldy     ElementPtr+1                    ; C4B5 AC 35 03
        jsr     FP_STORE                        ; C4B8 20 D4 BB
        inc     IndexI                          ; C4BB EE 36 03
        lda     PatternCount                    ; C4BE AD AC 02
        cmp     IndexI                          ; C4C1 CD 36 03
        bcc     PresentShuffledPatterns         ; C4C4 90 03
        jmp     ShufflePatterns                 ; C4C6 4C 21 C4

; ----------------------------------------------------------------------------
; Fetch the next pattern number from PAT() and classify it.
PresentShuffledPatterns:
        lda     #$01                            ; C4C9 A9 01
        sta     OrderIndex                      ; C4CB 8D C6 02
LC4CE:
        lda     OrderOffset                     ; C4CE AD C3 02
        clc                                     ; C4D1 18
        adc     BASIC_ARYTAB                    ; C4D2 65 2F
        sta     ElementPtr                      ; C4D4 8D 34 03
        lda     OrderOffset+1                   ; C4D7 AD C4 02
        adc     BASIC_ARYTAB+1                  ; C4DA 65 30
        sta     ElementPtr+1                    ; C4DC 8D 35 03
        lda     OrderIndex                      ; C4DF AD C6 02
        jsr     IndexVector                     ; C4E2 20 78 C3
        lda     ElementPtr                      ; C4E5 AD 34 03
        ldy     ElementPtr+1                    ; C4E8 AC 35 03
        jsr     FP_LOAD                         ; C4EB 20 A2 BB
        jsr     BASIC_FAC_TO_BYTE               ; C4EE 20 A1 B7
        txa                                     ; C4F1 8A
        sta     PatternIndex                    ; C4F2 8D BB 02
        jsr     ClassifyPattern                 ; C4F5 20 4F C2
        lda     InputOffset                     ; C4F8 AD C1 02
        clc                                     ; C4FB 18
        adc     BASIC_ARYTAB                    ; C4FC 65 2F
        sta     ElementPtr                      ; C4FE 8D 34 03
        lda     InputOffset+1                   ; C501 AD C2 02
        adc     BASIC_ARYTAB+1                  ; C504 65 30
        sta     ElementPtr+1                    ; C506 8D 35 03
        ldy     #$00                            ; C509 A0 00
        ldx     PatternIndex                    ; C50B AE BB 02
        lda     InputCount                      ; C50E AD A9 02
        jsr     IndexMatrix                     ; C511 20 92 C3
        lda     ElementPtr                      ; C514 AD 34 03
        ldy     ElementPtr+1                    ; C517 AC 35 03
        jsr     FP_LOAD                         ; C51A 20 A2 BB
        jsr     BASIC_FAC_TO_BYTE               ; C51D 20 A1 B7
        cpx     #$00                            ; C520 E0 00
        bne     UpdateWinningCluster            ; C522 D0 03
        jmp     LC5EE                           ; C524 4C EE C5

; ----------------------------------------------------------------------------
; For input i: W1(winner,i)+=rate*(IN(i,p)/IN(0,p)-W1(winner,i)). Only the winner changes.
UpdateWinningCluster:
        lda     #$01                            ; C527 A9 01
        sta     IndexI                          ; C529 8D 36 03
LC52C:
        lda     InputOffset                     ; C52C AD C1 02
        clc                                     ; C52F 18
        adc     BASIC_ARYTAB                    ; C530 65 2F
        sta     ElementPtr                      ; C532 8D 34 03
        lda     InputOffset+1                   ; C535 AD C2 02
        adc     BASIC_ARYTAB+1                  ; C538 65 30
        sta     ElementPtr+1                    ; C53A 8D 35 03
        lda     InputCount                      ; C53D AD A9 02
        ldy     #$00                            ; C540 A0 00
        ldx     PatternIndex                    ; C542 AE BB 02
        jsr     IndexMatrix                     ; C545 20 92 C3
        lda     ElementPtr                      ; C548 AD 34 03
        ldy     ElementPtr+1                    ; C54B AC 35 03
        jsr     FP_LOAD                         ; C54E 20 A2 BB
        lda     InputOffset                     ; C551 AD C1 02
        clc                                     ; C554 18
        adc     BASIC_ARYTAB                    ; C555 65 2F
        sta     ElementPtr                      ; C557 8D 34 03
        lda     InputOffset+1                   ; C55A AD C2 02
        adc     BASIC_ARYTAB+1                  ; C55D 65 30
        sta     ElementPtr+1                    ; C55F 8D 35 03
        lda     InputCount                      ; C562 AD A9 02
        ldy     IndexI                          ; C565 AC 36 03
        ldx     PatternIndex                    ; C568 AE BB 02
        jsr     IndexMatrix                     ; C56B 20 92 C3
        lda     ElementPtr                      ; C56E AD 34 03
        ldy     ElementPtr+1                    ; C571 AC 35 03
        jsr     FP_MEM_DIV_FAC                  ; C574 20 0F BB
        lda     RateOffset                      ; C577 AD AD 02
        clc                                     ; C57A 18
        adc     BASIC_VARTAB                    ; C57B 65 2D
        sta     ElementPtr                      ; C57D 8D 34 03
        lda     RateOffset+1                    ; C580 AD AE 02
        adc     BASIC_VARTAB+1                  ; C583 65 2E
        sta     ElementPtr+1                    ; C585 8D 35 03
        lda     ElementPtr                      ; C588 AD 34 03
        ldy     ElementPtr+1                    ; C58B AC 35 03
        jsr     FP_MUL_MEM                      ; C58E 20 28 BA
        ldx     #$CD                            ; C591 A2 CD
        ldy     #$02                            ; C593 A0 02
        jsr     FP_STORE                        ; C595 20 D4 BB
        lda     ElementPtr                      ; C598 AD 34 03
        ldy     ElementPtr+1                    ; C59B AC 35 03
        jsr     FP_LOAD                         ; C59E 20 A2 BB
        lda     W1Offset                        ; C5A1 AD BF 02
        clc                                     ; C5A4 18
        adc     BASIC_ARYTAB                    ; C5A5 65 2F
        sta     ElementPtr                      ; C5A7 8D 34 03
        lda     W1Offset+1                      ; C5AA AD C0 02
        adc     BASIC_ARYTAB+1                  ; C5AD 65 30
        sta     ElementPtr+1                    ; C5AF 8D 35 03
        lda     OutputCount                     ; C5B2 AD AA 02
        ldy     Winner                          ; C5B5 AC C5 02
        ldx     IndexI                          ; C5B8 AE 36 03
        jsr     IndexMatrix                     ; C5BB 20 92 C3
        lda     ElementPtr                      ; C5BE AD 34 03
        ldy     ElementPtr+1                    ; C5C1 AC 35 03
        jsr     FP_MUL_MEM                      ; C5C4 20 28 BA
        lda     #$CD                            ; C5C7 A9 CD
        ldy     #$02                            ; C5C9 A0 02
        jsr     FP_MEM_MINUS_FAC                ; C5CB 20 50 B8
        lda     ElementPtr                      ; C5CE AD 34 03
        ldy     ElementPtr+1                    ; C5D1 AC 35 03
        jsr     FP_ADD_MEM                      ; C5D4 20 67 B8
        ldx     ElementPtr                      ; C5D7 AE 34 03
        ldy     ElementPtr+1                    ; C5DA AC 35 03
        jsr     FP_STORE                        ; C5DD 20 D4 BB
        inc     IndexI                          ; C5E0 EE 36 03
        lda     InputCount                      ; C5E3 AD A9 02
        cmp     IndexI                          ; C5E6 CD 36 03
        bcc     LC5EE                           ; C5E9 90 03
        jmp     LC52C                           ; C5EB 4C 2C C5

; ----------------------------------------------------------------------------
LC5EE:
        inc     OrderIndex                      ; C5EE EE C6 02
        lda     PatternCount                    ; C5F1 AD AC 02
        cmp     OrderIndex                      ; C5F4 CD C6 02
        bcc     LC5FC                           ; C5F7 90 03
        jmp     LC4CE                           ; C5F9 4C CE C4

; ----------------------------------------------------------------------------
LC5FC:
        rts                                     ; C5FC 60

; ----------------------------------------------------------------------------
; Parse trial count and run the epoch routine, polling RUN/STOP between passes. Counter instructions are preserved literally.
LearnTrials:
        jsr     BASIC_COMMA                     ; C5FD 20 FD AE
        jsr     BASIC_EVAL_NUMBER               ; C600 20 8A AD
        jsr     BASIC_TO_WORD                   ; C603 20 AA B1
        sta     TrialsRemaining+1               ; C606 8D C8 02
        sty     TrialsRemaining                 ; C609 8C C7 02
        cpy     #$00                            ; C60C C0 00
        bne     LC614                           ; C60E D0 04
        cmp     #$00                            ; C610 C9 00
        beq     LC62B                           ; C612 F0 17
LC614:
        jsr     TrainEpoch                      ; C614 20 E6 C3
        jsr     K_STOP                          ; C617 20 E1 FF
        beq     LC62C                           ; C61A F0 10
        dec     TrialsRemaining                 ; C61C CE C7 02
        bne     LC614                           ; C61F D0 F3
        lda     TrialsRemaining+1               ; C621 AD C8 02
        beq     LC62B                           ; C624 F0 05
        dec     TrialsRemaining+1               ; C626 CE C8 02
        bne     LC614                           ; C629 D0 E9
LC62B:
        rts                                     ; C62B 60

; ----------------------------------------------------------------------------
LC62C:
        ldy     #$00                            ; C62C A0 00
        jmp     BASIC_BREAK                     ; C62E 4C 38 A8

; ----------------------------------------------------------------------------
; Require a stored pattern index in 1..NP before importing the string.
DefinePattern:
        jsr     BASIC_COMMA                     ; C631 20 FD AE
        jsr     BASIC_GET_BYTE                  ; C634 20 9E B7
        stx     PatternIndex                    ; C637 8E BB 02
        cpx     #$00                            ; C63A E0 00
        beq     LC646                           ; C63C F0 08
        lda     PatternCount                    ; C63E AD AC 02
        cmp     PatternIndex                    ; C641 CD BB 02
        bcs     ReadInputString                 ; C644 B0 03
LC646:
        jmp     BASIC_BAD_QUANTITY              ; C646 4C 48 B2

; ----------------------------------------------------------------------------
; Require length P1. ASCII 1 becomes numeric one; all other characters become zero.
ReadInputString:
        jsr     BASIC_COMMA                     ; C649 20 FD AE
        jsr     BASIC_EVAL                      ; C64C 20 9E AD
        jsr     BASIC_REQUIRE_STRING            ; C64F 20 8F AD
        jsr     BASIC_STRING_DATA               ; C652 20 A6 B6
        cmp     InputCount                      ; C655 CD A9 02
        bne     LC646                           ; C658 D0 EC
        stx     WorkFloat                       ; C65A 8E CD 02
        sty     WorkFloat+1                     ; C65D 8C CE 02
        lda     #$00                            ; C660 A9 00
        sta     IndexI                          ; C662 8D 36 03
        sta     IndexJ                          ; C665 8D 38 03
LC668:
        ldy     IndexI                          ; C668 AC 36 03
        lda     WorkFloat                       ; C66B AD CD 02
        sta     BASIC_INDEX                     ; C66E 85 22
        lda     WorkFloat+1                     ; C670 AD CE 02
        sta     BASIC_INDEX+1                   ; C673 85 23
        lda     (BASIC_INDEX),y                 ; C675 B1 22
        cmp     #$31                            ; C677 C9 31
        beq     CountActiveInputs               ; C679 F0 04
        lda     #$00                            ; C67B A9 00
        beq     LC684                           ; C67D F0 05
; Count ASCII-1 entries while filling IN(:,pattern).
CountActiveInputs:
        inc     IndexJ                          ; C67F EE 38 03
        lda     #$01                            ; C682 A9 01
LC684:
        jsr     FP_FROM_BYTE                    ; C684 20 3C BC
        lda     InputOffset                     ; C687 AD C1 02
        clc                                     ; C68A 18
        adc     BASIC_ARYTAB                    ; C68B 65 2F
        sta     ElementPtr                      ; C68D 8D 34 03
        lda     InputOffset+1                   ; C690 AD C2 02
        adc     BASIC_ARYTAB+1                  ; C693 65 30
        sta     ElementPtr+1                    ; C695 8D 35 03
        lda     InputCount                      ; C698 AD A9 02
        ldy     IndexI                          ; C69B AC 36 03
        iny                                     ; C69E C8
        ldx     PatternIndex                    ; C69F AE BB 02
        jsr     IndexMatrix                     ; C6A2 20 92 C3
        ldx     ElementPtr                      ; C6A5 AE 34 03
        ldy     ElementPtr+1                    ; C6A8 AC 35 03
        jsr     FP_STORE                        ; C6AB 20 D4 BB
        inc     IndexI                          ; C6AE EE 36 03
        lda     InputCount                      ; C6B1 AD A9 02
        cmp     IndexI                          ; C6B4 CD 36 03
        bne     LC668                           ; C6B7 D0 AF
; Store number of active inputs in IN(0,pattern); learning uses it to normalize the target vector.
StoreActiveCount:
        lda     IndexJ                          ; C6B9 AD 38 03
        jsr     FP_FROM_BYTE                    ; C6BC 20 3C BC
        lda     InputOffset                     ; C6BF AD C1 02
        clc                                     ; C6C2 18
        adc     BASIC_ARYTAB                    ; C6C3 65 2F
        sta     ElementPtr                      ; C6C5 8D 34 03
        lda     InputOffset+1                   ; C6C8 AD C2 02
        adc     BASIC_ARYTAB+1                  ; C6CB 65 30
        sta     ElementPtr+1                    ; C6CD 8D 35 03
        lda     InputCount                      ; C6D0 AD A9 02
        ldy     #$00                            ; C6D3 A0 00
        ldx     PatternIndex                    ; C6D5 AE BB 02
        jsr     IndexMatrix                     ; C6D8 20 92 C3
        ldx     ElementPtr                      ; C6DB AE 34 03
        ldy     ElementPtr+1                    ; C6DE AC 35 03
        jsr     FP_STORE                        ; C6E1 20 D4 BB
        rts                                     ; C6E4 60

; ----------------------------------------------------------------------------
        jmp     BASIC_BAD_QUANTITY              ; C6E5 4C 48 B2

; ----------------------------------------------------------------------------
; Sequential file on device 8; logical file 1, secondary address 2; append comma-W.
SaveNetwork:
        jsr     OpenStatusChannel               ; C6E8 20 15 C9
        jsr     BASIC_COMMA                     ; C6EB 20 FD AE
        jsr     BASIC_EVAL                      ; C6EE 20 9E AD
        jsr     BASIC_REQUIRE_STRING            ; C6F1 20 8F AD
        jsr     BASIC_STRING_DATA               ; C6F4 20 A6 B6
        sta     IndexI                          ; C6F7 8D 36 03
        ldy     #$00                            ; C6FA A0 00
LC6FC:
        lda     (BASIC_INDEX),y                 ; C6FC B1 22
        sta     FilenameBuffer,y                ; C6FE 99 DD 02
        iny                                     ; C701 C8
        cpy     IndexI                          ; C702 CC 36 03
        beq     LC70B                           ; C705 F0 04
        cpy     #$14                            ; C707 C0 14
        bne     LC6FC                           ; C709 D0 F1
LC70B:
        lda     #$2C                            ; C70B A9 2C
        sta     FilenameBuffer,y                ; C70D 99 DD 02
        iny                                     ; C710 C8
        lda     #$57                            ; C711 A9 57
        sta     FilenameBuffer,y                ; C713 99 DD 02
        iny                                     ; C716 C8
        tya                                     ; C717 98
        ldx     #$DD                            ; C718 A2 DD
        ldy     #$02                            ; C71A A0 02
        jsr     K_SETNAM                        ; C71C 20 BD FF
        lda     #$01                            ; C71F A9 01
        ldx     #$08                            ; C721 A2 08
        ldy     #$02                            ; C723 A0 02
        jsr     K_SETLFS                        ; C725 20 BA FF
        jsr     K_OPEN                          ; C728 20 C0 FF
        ldx     #$0F                            ; C72B A2 0F
        jsr     K_CHKIN                         ; C72D 20 C6 FF
        jsr     K_CHRIN                         ; C730 20 CF FF
        cmp     #$30                            ; C733 C9 30
        beq     WriteNetworkBody                ; C735 F0 03
        jmp     DiskError                       ; C737 4C DA C7

; ----------------------------------------------------------------------------
; Write P1/P2/NP, then RA, W1 and IN. PAT is temporary and is regenerated for training.
WriteNetworkBody:
        jsr     K_CLRCHN                        ; C73A 20 CC FF
        ldx     #$01                            ; C73D A2 01
        jsr     K_CHKOUT                        ; C73F 20 C9 FF
        lda     InputCount                      ; C742 AD A9 02
        jsr     K_CHROUT                        ; C745 20 D2 FF
        lda     OutputCount                     ; C748 AD AA 02
        jsr     K_CHROUT                        ; C74B 20 D2 FF
        lda     PatternCount                    ; C74E AD AC 02
        jsr     K_CHROUT                        ; C751 20 D2 FF
        ldx     RateOffset                      ; C754 AE AD 02
        ldy     RateOffset+1                    ; C757 AC AE 02
        jsr     WriteScalar                     ; C75A 20 86 C7
        lda     W1Offset                        ; C75D AD BF 02
        sta     BASIC_INDEX                     ; C760 85 22
        lda     W1Offset+1                      ; C762 AD C0 02
        sta     BASIC_INDEX+1                   ; C765 85 23
        ldy     OutputCount                     ; C767 AC AA 02
        ldx     InputCount                      ; C76A AE A9 02
        jsr     WriteMatrix                     ; C76D 20 9E C7
        lda     InputOffset                     ; C770 AD C1 02
        sta     BASIC_INDEX                     ; C773 85 22
        lda     InputOffset+1                   ; C775 AD C2 02
        sta     BASIC_INDEX+1                   ; C778 85 23
        ldy     InputCount                      ; C77A AC A9 02
        ldx     PatternCount                    ; C77D AE AC 02
        jsr     WriteMatrix                     ; C780 20 9E C7
        jmp     CloseNetworkFiles               ; C783 4C 27 C9

; ----------------------------------------------------------------------------
; Resolve VARTAB-relative scalar offset and write five stored bytes.
WriteScalar:
        txa                                     ; C786 8A
        clc                                     ; C787 18
        adc     BASIC_VARTAB                    ; C788 65 2D
        sta     BASIC_INDEX                     ; C78A 85 22
        tya                                     ; C78C 98
        adc     BASIC_VARTAB+1                  ; C78D 65 2E
        sta     BASIC_INDEX+1                   ; C78F 85 23
        ldy     #$00                            ; C791 A0 00
LC793:
        lda     (BASIC_INDEX),y                 ; C793 B1 22
        jsr     K_CHROUT                        ; C795 20 D2 FF
        iny                                     ; C798 C8
        cpy     #$05                            ; C799 C0 05
        bne     LC793                           ; C79B D0 F6
        rts                                     ; C79D 60

; ----------------------------------------------------------------------------
; Write all five-byte elements, including allocated row and column zero.
WriteMatrix:
        lda     BASIC_ARYTAB                    ; C79E A5 2F
        clc                                     ; C7A0 18
        adc     BASIC_INDEX                     ; C7A1 65 22
        sta     BASIC_INDEX                     ; C7A3 85 22
        lda     BASIC_ARYTAB+1                  ; C7A5 A5 30
        adc     BASIC_INDEX+1                   ; C7A7 65 23
        sta     BASIC_INDEX+1                   ; C7A9 85 23
        iny                                     ; C7AB C8
        sty     IndexI                          ; C7AC 8C 36 03
        sty     WorkFloat                       ; C7AF 8C CD 02
        inx                                     ; C7B2 E8
        stx     IndexJ                          ; C7B3 8E 38 03
        ldy     #$00                            ; C7B6 A0 00
        ldx     #$05                            ; C7B8 A2 05
LC7BA:
        lda     (BASIC_INDEX),y                 ; C7BA B1 22
        jsr     K_CHROUT                        ; C7BC 20 D2 FF
        iny                                     ; C7BF C8
        bne     LC7C4                           ; C7C0 D0 02
        inc     BASIC_INDEX+1                   ; C7C2 E6 23
LC7C4:
        dex                                     ; C7C4 CA
        bne     LC7BA                           ; C7C5 D0 F3
        ldx     #$05                            ; C7C7 A2 05
        dec     IndexI                          ; C7C9 CE 36 03
        bne     LC7BA                           ; C7CC D0 EC
        lda     WorkFloat                       ; C7CE AD CD 02
        sta     IndexI                          ; C7D1 8D 36 03
        dec     IndexJ                          ; C7D4 CE 38 03
        bne     LC7BA                           ; C7D7 D0 E1
        rts                                     ; C7D9 60

; ----------------------------------------------------------------------------
; Print drive status, close channels, reset BASIC stack and return to READY.
DiskError:
        jsr     K_CHROUT                        ; C7DA 20 D2 FF
        jsr     K_CHRIN                         ; C7DD 20 CF FF
        cmp     #$0D                            ; C7E0 C9 0D
        bne     DiskError                       ; C7E2 D0 F6
        jsr     K_CHROUT                        ; C7E4 20 D2 FF
        jsr     K_CLALL                         ; C7E7 20 E7 FF
        jsr     BASIC_RESET_STACK               ; C7EA 20 7A A6
        jmp     BASIC_READY                     ; C7ED 4C 74 A4

; ----------------------------------------------------------------------------
; Append comma-R; read dimensions, rebuild BASIC storage, then restore RA/W1/IN.
LoadNetwork:
        jsr     OpenStatusChannel               ; C7F0 20 15 C9
        jsr     BASIC_COMMA                     ; C7F3 20 FD AE
        jsr     BASIC_EVAL                      ; C7F6 20 9E AD
        jsr     BASIC_REQUIRE_STRING            ; C7F9 20 8F AD
        jsr     BASIC_STRING_DATA               ; C7FC 20 A6 B6
        sta     IndexI                          ; C7FF 8D 36 03
        ldy     #$00                            ; C802 A0 00
LC804:
        lda     (BASIC_INDEX),y                 ; C804 B1 22
        sta     FilenameBuffer,y                ; C806 99 DD 02
        iny                                     ; C809 C8
        cpy     IndexI                          ; C80A CC 36 03
        beq     LC813                           ; C80D F0 04
        cpy     #$14                            ; C80F C0 14
        bne     LC804                           ; C811 D0 F1
LC813:
        lda     #$2C                            ; C813 A9 2C
        sta     FilenameBuffer,y                ; C815 99 DD 02
        iny                                     ; C818 C8
        lda     #$52                            ; C819 A9 52
        sta     FilenameBuffer,y                ; C81B 99 DD 02
        iny                                     ; C81E C8
        tya                                     ; C81F 98
        ldx     #$DD                            ; C820 A2 DD
        ldy     #$02                            ; C822 A0 02
        jsr     K_SETNAM                        ; C824 20 BD FF
        lda     #$01                            ; C827 A9 01
        ldx     #$08                            ; C829 A2 08
        ldy     #$02                            ; C82B A0 02
        jsr     K_SETLFS                        ; C82D 20 BA FF
        jsr     K_OPEN                          ; C830 20 C0 FF
        ldx     #$0F                            ; C833 A2 0F
        jsr     K_CHKIN                         ; C835 20 C6 FF
        jsr     K_CHRIN                         ; C838 20 CF FF
        cmp     #$30                            ; C83B C9 30
        bne     DiskError                       ; C83D D0 9B
        jsr     K_CLRCHN                        ; C83F 20 CC FF
        ldx     #$01                            ; C842 A2 01
        jsr     K_CHKIN                         ; C844 20 C6 FF
        jsr     K_CHRIN                         ; C847 20 CF FF
        sta     InputCount                      ; C84A 8D A9 02
        jsr     K_CHRIN                         ; C84D 20 CF FF
        sta     OutputCount                     ; C850 8D AA 02
        jsr     K_CHRIN                         ; C853 20 CF FF
        sta     PatternCount                    ; C856 8D AC 02
        jsr     RecreateForLoad                 ; C859 20 E2 C8
        ldx     RateOffset                      ; C85C AE AD 02
        ldy     RateOffset+1                    ; C85F AC AE 02
        jsr     ReadScalar                      ; C862 20 8E C8
        lda     W1Offset                        ; C865 AD BF 02
        sta     BASIC_INDEX                     ; C868 85 22
        lda     W1Offset+1                      ; C86A AD C0 02
        sta     BASIC_INDEX+1                   ; C86D 85 23
        ldy     OutputCount                     ; C86F AC AA 02
        ldx     InputCount                      ; C872 AE A9 02
        jsr     ReadMatrix                      ; C875 20 A6 C8
        lda     InputOffset                     ; C878 AD C1 02
        sta     BASIC_INDEX                     ; C87B 85 22
        lda     InputOffset+1                   ; C87D AD C2 02
        sta     BASIC_INDEX+1                   ; C880 85 23
        ldy     InputCount                      ; C882 AC A9 02
        ldx     PatternCount                    ; C885 AE AC 02
        jsr     ReadMatrix                      ; C888 20 A6 C8
        jmp     CloseNetworkFiles               ; C88B 4C 27 C9

; ----------------------------------------------------------------------------
; Read five bytes into a BASIC scalar.
ReadScalar:
        txa                                     ; C88E 8A
        clc                                     ; C88F 18
        adc     BASIC_VARTAB                    ; C890 65 2D
        sta     BASIC_INDEX                     ; C892 85 22
        tya                                     ; C894 98
        adc     BASIC_VARTAB+1                  ; C895 65 2E
        sta     BASIC_INDEX+1                   ; C897 85 23
        ldy     #$00                            ; C899 A0 00
LC89B:
        jsr     K_CHRIN                         ; C89B 20 CF FF
        sta     (BASIC_INDEX),y                 ; C89E 91 22
        iny                                     ; C8A0 C8
        cpy     #$05                            ; C8A1 C0 05
        bne     LC89B                           ; C8A3 D0 F6
        rts                                     ; C8A5 60

; ----------------------------------------------------------------------------
; Read all allocated matrix elements into BASIC storage.
ReadMatrix:
        lda     BASIC_ARYTAB                    ; C8A6 A5 2F
        clc                                     ; C8A8 18
        adc     BASIC_INDEX                     ; C8A9 65 22
        sta     BASIC_INDEX                     ; C8AB 85 22
        lda     BASIC_ARYTAB+1                  ; C8AD A5 30
        adc     BASIC_INDEX+1                   ; C8AF 65 23
        sta     BASIC_INDEX+1                   ; C8B1 85 23
        iny                                     ; C8B3 C8
        sty     IndexI                          ; C8B4 8C 36 03
        sty     WorkFloat                       ; C8B7 8C CD 02
        inx                                     ; C8BA E8
        stx     IndexJ                          ; C8BB 8E 38 03
        ldy     #$00                            ; C8BE A0 00
        ldx     #$05                            ; C8C0 A2 05
LC8C2:
        jsr     K_CHRIN                         ; C8C2 20 CF FF
        sta     (BASIC_INDEX),y                 ; C8C5 91 22
        iny                                     ; C8C7 C8
        bne     LC8CC                           ; C8C8 D0 02
        inc     BASIC_INDEX+1                   ; C8CA E6 23
LC8CC:
        dex                                     ; C8CC CA
        bne     LC8C2                           ; C8CD D0 F3
        ldx     #$05                            ; C8CF A2 05
        dec     IndexI                          ; C8D1 CE 36 03
        bne     LC8C2                           ; C8D4 D0 EC
        lda     WorkFloat                       ; C8D6 AD CD 02
        sta     IndexI                          ; C8D9 8D 36 03
        dec     IndexJ                          ; C8DC CE 38 03
        bne     LC8C2                           ; C8DF D0 E1
        rts                                     ; C8E1 60

; ----------------------------------------------------------------------------
; Reset BASIC array/string boundaries and recreate storage for the dimensions just read.
RecreateForLoad:
        lda     BASIC_MEMSIZ                    ; C8E2 A5 37
        ldy     BASIC_MEMSIZ+1                  ; C8E4 A4 38
        sta     BASIC_FRETOP                    ; C8E6 85 33
        sty     BASIC_FRETOP+1                  ; C8E8 84 34
        lda     BASIC_VARTAB                    ; C8EA A5 2D
        ldy     BASIC_VARTAB+1                  ; C8EC A4 2E
        sta     BASIC_ARYTAB                    ; C8EE 85 2F
        sty     BASIC_ARYTAB+1                  ; C8F0 84 30
        sta     BASIC_STREND                    ; C8F2 85 31
        sty     BASIC_STREND+1                  ; C8F4 84 32
        lda     BASIC_TXTPTR                    ; C8F6 A5 7A
        sta     SavedTextPtr                    ; C8F8 8D A7 02
        lda     BASIC_TXTPTR+1                  ; C8FB A5 7B
        sta     SavedTextPtr+1                  ; C8FD 8D A8 02
        lda     #$58                            ; C900 A9 58
        sta     BASIC_TXTPTR                    ; C902 85 7A
        lda     #$C9                            ; C904 A9 C9
        sta     BASIC_TXTPTR+1                  ; C906 85 7B
        jsr     BASIC_VARIABLE                  ; C908 20 8B B0
        sta     RateOffset                      ; C90B 8D AD 02
        sty     RateOffset+1                    ; C90E 8C AE 02
        jsr     CreateBasicStorage              ; C911 20 71 C0
        rts                                     ; C914 60

; ----------------------------------------------------------------------------
; Open logical file 15 on device 8, secondary address 15.
OpenStatusChannel:
        lda     #$00                            ; C915 A9 00
        jsr     K_SETNAM                        ; C917 20 BD FF
        lda     #$0F                            ; C91A A9 0F
        ldx     #$08                            ; C91C A2 08
        ldy     #$0F                            ; C91E A0 0F
        jsr     K_SETLFS                        ; C920 20 BA FF
        jsr     K_OPEN                          ; C923 20 C0 FF
        rts                                     ; C926 60

; ----------------------------------------------------------------------------
; Restore default channels and close logical files 1 and 15.
CloseNetworkFiles:
        jsr     K_CLRCHN                        ; C927 20 CC FF
        lda     #$01                            ; C92A A9 01
        jsr     K_CLOSE                         ; C92C 20 C3 FF
        lda     #$0F                            ; C92F A9 0F
        jsr     K_CLOSE                         ; C931 20 C3 FF
        rts                                     ; C934 60

; ----------------------------------------------------------------------------
; BASIC DIM argument text, not executable 6502 instructions.
DimExpressions:
        .byte   "O2(P2),W1(P2,P1),IN(P1,NP),PAT("; C935 4F 32 28 50 32 29 2C 57
                                                ; C93D 31 28 50 32 2C 50 31 29
                                                ; C945 2C 49 4E 28 50 31 2C 4E
                                                ; C94D 50 29 2C 50 41 54 28
        .byte   "NP)"                           ; C954 4E 50 29
        .byte   $00                             ; C957 00
; RA is the BASIC name prefix for RATE.
NameRate:
        .byte   "RA"                            ; C958 52 41
        .byte   $00                             ; C95A 00
; Input dimension.
NameP1:
        .byte   "P1"                            ; C95B 50 31
        .byte   $00                             ; C95D 00
; Output cluster count.
NameP2:
        .byte   "P2"                            ; C95E 50 32
        .byte   $00                             ; C960 00
; Pattern count.
NameNP:
        .byte   "NP"                            ; C961 4E 50
        .byte   $00                             ; C963 00
; Lookup text for O2(0).
NameO2:
        .byte   "O2(0)"                         ; C964 4F 32 28 30 29
        .byte   $00                             ; C969 00
; Lookup text for IN(0,0).
NameInput:
        .byte   "IN(0,0)"                       ; C96A 49 4E 28 30 2C 30 29
        .byte   $00                             ; C971 00
; Lookup text for W1(0,0).
NameW1:
        .byte   "W1(0,0)"                       ; C972 57 31 28 30 2C 30 29
        .byte   $00                             ; C979 00
; Lookup text for PAT(0), the shuffle work array.
NameOrder:
        .byte   "PAT(0)"                        ; C97A 50 41 54 28 30 29
        .byte   $00                             ; C980 00
; ----------------------------------------------------------------------------
; Zero constant retained from the original image; no internal load references it.
FloatZeroUnused:
        .byte   $00,$00,$00,$00,$00             ; C981 00 00 00 00 00
; One constant retained from the original image; no internal load references it.
FloatOneUnused:
        .byte   $81,$00,$00,$00,$00             ; C986 81 00 00 00 00
; ----------------------------------------------------------------------------
; Unused TE string retained verbatim. File ends at $C98D, before two printed trailing zeros.
NameTotalErrorUnused:
        .byte   "TE"                            ; C98B 54 45
        .byte   $00                             ; C98D 00

PayloadEnd:
.assert PayloadEnd-PayloadStart = 2446, error, "Original payload length changed"
