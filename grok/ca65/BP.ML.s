; BP.ML — Back-Propagation engine
; Kevin E. Martin, "Future Computing: Neural Networks" Part 2
; COMPUTE!'s Gazette, February 1990 (Issue 80), pp. 35-41
;
; Binary: Alt / Gaz-Type feb90.d64 copy supplied as BP.ML.prg
; (4097 bytes, load $C000, payload $C000-$CFFE). Printed MLX ended
; at $CFFF; the last published byte is the $00 after the "TE" marker.
;
; Assemble:
;   ca65 -t c64 BP.ML.s -o BP.ML.o
;   ld65 -C c64-asm.cfg BP.ML.o -o BP.ML.prg
;
; BASIC interface (XOR.prg / ENCODE.prg):
;   SYS 49152, fpe, spe, tpe, np, lr, momen, err
;   SYS 49155, pat$
;   SYS 49164, se
;   SYS 49167, pn, ip$, tp$
;   SYS 49170, file$
;   SYS 49173, file$
;
; Signature checked by XOR/ENCODE line 30:
;   PEEK(49153)=24   ($C001 = $18)
;   PEEK(49157)=196  ($C005 = $C4)
;
; BASIC symbols created by init (article Table 1):
;   RA, MO, EP          rate, momentum, epsilon
;   P1 P2 P3 NP TE
;   O2(P2) O3(P3)       layer outputs
;   E2(P2) E3(P3)       layer errors
;   W1(P2,P1) W2(P3,P2) weights
;   M1(P2,P1) M2(P3,P2) previous deltas (momentum)
;   T(P3,NP) IN(P1,NP)  teacher / input patterns
;   E(NP)               per-pattern error
; Name table also allocates O1(0) as a scratch shell.
;
; Algorithm (article): three-layer net, two weight matrices.
; Activation is summed through W then passed through an output
; function. Layer-3 error is back-propagated to layer 2. Weights
; move by rate*error*input plus momen*previous delta. Training
; stops when total error te < epsilon. RUN/STOP is polled between
; trials. XOR (2-2-1) ~1:20; ENCODE (4-2-4) ~27:49.
;
.setcpu "6502"
.segment "CODE"
.org $C000

CHKCOM   = $AEFD
GETBYTC  = $B79E
COMBYTE  = $B7A1
FRMNUM   = $AD8A
FRMEVL   = $AD9E
CHKNUM   = $AD8F
PTRGET   = $B08B
PTRGET2  = $B081
FRESTR   = $B1AA
MOVMF    = $BBD4
MOVFM    = $BBA2
MOVFA    = $BBFC
FACBYTE  = $BC3C
FCOMP    = $BC5B
FACINT   = $BCCC
FADD     = $B867
FSUB     = $B850
FMULT    = $BA28
FDIV     = $BB0F
CONUPK   = $BA8C
FOUT     = $BDDD
PRINTFAC = $AB24
GETSTR   = $B6A6
RND0     = $E097
STXTPT   = $A67A
OMERR    = $A838
ERROR    = $A474
STOP     = $FFE1
CHROUT   = $FFD2
CHRIN    = $FFCF
SETNAM   = $FFBD
SETLFS   = $FFBA
OPEN     = $FFC0
CLOSE    = $FFC3
CHKIN    = $FFC6
CHKOUT   = $FFC9
CLRCHN   = $FFCC
CLALL    = $FFE7

TXTPTR   = $7A
VARTAB   = $2D
ARYTAB   = $2F
STREND   = $31
FRETOP   = $33
MEMSIZ   = $37
INDEX    = $22

p1_count     = $02A9
p2_count     = $02AA
p3_count     = $02AB
np_count     = $02AC
saved_txtptr = $02A7
ptr_rate     = $02AD
ptr_mo       = $02B1
ptr_ep       = $02AF
elem_ptr     = $0334
idx_a        = $0336
idx_b        = $0338



; Jump table. PEEK(49153)=24 ($18) and PEEK(49157)=196 ($C4) is the XOR/ENCODE signature.
jmp_init:
        jmp init_network
jmp_recognize:
        jmp recognize
jmp_undoc_49158:
        jmp undoc_49158
jmp_undoc_49161:
        jmp undoc_49161
jmp_learn:
        jmp learn
jmp_setpair:
        jmp setpair
jmp_save:
        jmp save_net
jmp_load:
        jmp load_net

; SYS 49152,fpe,spe,tpe,np,lr,momen,err — create BASIC vars and init W1/W2.
init_network:
        jsr CHKCOM
        jsr GETBYTC
        stx p1_count          ; p1_count
        jsr CHKCOM
        jsr GETBYTC
        stx p2_count          ; p2_count
        jsr CHKCOM
        jsr GETBYTC
        stx p3_count          ; p3_count
        jsr CHKCOM
        jsr GETBYTC
        stx np_count          ; np_count
        jsr CHKCOM
        lda TXTPTR
        sta saved_txtptr          ; saved_txtptr
        lda TXTPTR+1
        sta saved_txtptr+1          ; saved_txtptr+1
        lda #$8B
        sta TXTPTR
        lda #$CF
        sta TXTPTR+1
        jsr PTRGET
        sta ptr_rate          ; ptr_rate
        sty ptr_rate+1          ; ptr_rate+1
        lda saved_txtptr          ; saved_txtptr
        sta TXTPTR
        lda saved_txtptr+1          ; saved_txtptr+1
        sta TXTPTR+1
        jsr FRMNUM
        ldx ptr_rate          ; ptr_rate
        ldy ptr_rate+1          ; ptr_rate+1
        jsr MOVMF
        jsr CHKCOM
        lda TXTPTR
        sta saved_txtptr          ; saved_txtptr
        lda TXTPTR+1
        sta saved_txtptr+1          ; saved_txtptr+1
        lda #$8E
        sta TXTPTR
        lda #$CF
        sta TXTPTR+1
        jsr PTRGET
        sta ptr_mo          ; ptr_mo
        sty ptr_mo+1          ; ptr_mo+1
        lda saved_txtptr          ; saved_txtptr
        sta TXTPTR
        lda saved_txtptr+1          ; saved_txtptr+1
        sta TXTPTR+1
        jsr FRMNUM
        ldx ptr_mo          ; ptr_mo
        ldy ptr_mo+1          ; ptr_mo+1
        jsr MOVMF
        jsr CHKCOM
        lda TXTPTR
        sta saved_txtptr          ; saved_txtptr
        lda TXTPTR+1
        sta saved_txtptr+1          ; saved_txtptr+1
        lda #$91
        sta TXTPTR
        lda #$CF
        sta TXTPTR+1
        jsr PTRGET
        sta ptr_ep          ; ptr_ep
        sty ptr_ep+1          ; ptr_ep+1
        lda saved_txtptr          ; saved_txtptr
        sta TXTPTR
        lda saved_txtptr+1          ; saved_txtptr+1
        sta TXTPTR+1
        jsr FRMNUM
        ldx ptr_ep          ; ptr_ep
        ldy ptr_ep+1          ; ptr_ep+1
        jsr MOVMF
        lda TXTPTR
        sta saved_txtptr          ; saved_txtptr
        lda TXTPTR+1
        sta saved_txtptr+1          ; saved_txtptr+1
LC0E2:
        lda #$94
        sta TXTPTR
        lda #$CF
        sta TXTPTR+1
        jsr PTRGET
        pha
        tya
        pha
        lda p1_count          ; p1_count
        jsr FACBYTE
        pla
        tay
        pla
        tax
        jsr MOVMF
        lda #$97
        sta TXTPTR
        lda #$CF
        sta TXTPTR+1
        jsr PTRGET
        pha
        tya
        pha
        lda p2_count          ; p2_count
        jsr FACBYTE
        pla
        tay
        pla
        tax
        jsr MOVMF
        lda #$9A
        sta TXTPTR
        lda #$CF
        sta TXTPTR+1
        jsr PTRGET
        pha
        tya
        pha
        lda p3_count          ; p3_count
        jsr FACBYTE
        pla
        tay
        pla
        tax
        jsr MOVMF
        lda #$9D
        sta TXTPTR
        lda #$CF
        sta TXTPTR+1
        jsr PTRGET
        pha
        tya
        pha
        lda np_count          ; np_count
        jsr FACBYTE
        pla
        tay
        pla
        tax
        jsr MOVMF
        lda #$FC
        sta TXTPTR
        lda #$CF
        sta TXTPTR+1
        jsr PTRGET
        sta $02D2
        sty $02D3
        lda #$2E
        sta TXTPTR
        lda #$CF
        sta TXTPTR+1
        lda dim_list
        jsr PTRGET2
        lda #$A6
        sta TXTPTR
        lda #$CF
        sta TXTPTR+1
        jsr PTRGET
        sta $02B3
        sty $02B4
        lda #$01
        jsr FACBYTE
        ldx $02B3
        ldy $02B4
        jsr MOVMF
        lda #$AC
        sta TXTPTR
        lda #$CF
        sta TXTPTR+1
        jsr PTRGET
        sta $02B5
        sty $02B6
        lda #$01
        jsr FACBYTE
        ldx $02B5
        ldy $02B6
        jsr MOVMF
        lda #$00
        sta idx_a          ; idx_a
        lda #$B2
        sta TXTPTR
        lda #$CF
        sta TXTPTR+1
        jsr PTRGET
        sta $02C9
        sta elem_ptr          ; elem_ptr
        sty $02CA
        sty elem_ptr+1          ; elem_ptr+1
LC1C7:
        lda #$01
        jsr FACBYTE
        ldy elem_ptr+1          ; elem_ptr+1
        ldx elem_ptr          ; elem_ptr
        jsr MOVMF
        inc idx_a
        lda np_count          ; np_count
        cmp idx_a
        bcc LC203
        lda #$00
        sta idx_b          ; idx_b
LC1E5:
        lda elem_ptr          ; elem_ptr
        clc
        adc #$05
        sta elem_ptr          ; elem_ptr
        lda elem_ptr+1          ; elem_ptr+1
        adc #$00
        sta elem_ptr+1          ; elem_ptr+1
        inc idx_b
        lda p1_count          ; p1_count
        cmp idx_b
        bcs LC1E5
        bcc LC1C7
LC203:
        lda #$00
        sta idx_a          ; idx_a
        sta idx_b          ; idx_b
        lda #$BA
        sta TXTPTR
        lda #$CF
        sta TXTPTR+1
        jsr PTRGET
        sta $02BF
        sta elem_ptr          ; elem_ptr
        sty $02C0
        sty elem_ptr+1          ; elem_ptr+1
LC222:
        lda #$01
        jsr FACBYTE
        jsr RND0
        jsr $BAE2
        jsr $BC0C
        lda #$05
        jsr FACBYTE
        jsr $B853
        ldy elem_ptr+1          ; elem_ptr+1
        ldx elem_ptr          ; elem_ptr
        jsr MOVMF
        inc idx_a
        lda elem_ptr          ; elem_ptr
        clc
        adc #$05
        sta elem_ptr          ; elem_ptr
        lda elem_ptr+1          ; elem_ptr+1
        adc #$00
        sta elem_ptr+1          ; elem_ptr+1
        lda p2_count          ; p2_count
        cmp idx_a
        bcs LC222
        inc idx_b
        lda p1_count          ; p1_count
        cmp idx_b
        bcc LC270
        lda #$00
        sta idx_a          ; idx_a
        jmp LC222
LC270:
        lda #$00
        sta idx_a          ; idx_a
        sta idx_b          ; idx_b
        lda #$C2
        sta TXTPTR
        lda #$CF
        sta TXTPTR+1
        jsr PTRGET
        sta $02C1
        sta elem_ptr          ; elem_ptr
        sty $02C2
        sty elem_ptr+1          ; elem_ptr+1
LC28F:
        lda #$01
        jsr FACBYTE
        jsr RND0
        jsr $BAE2
        jsr $BC0C
        lda #$05
        jsr FACBYTE
        jsr $B853
        ldy elem_ptr+1          ; elem_ptr+1
        ldx elem_ptr          ; elem_ptr
        jsr MOVMF
        inc idx_a
        lda elem_ptr          ; elem_ptr
        clc
        adc #$05
        sta elem_ptr          ; elem_ptr
        lda elem_ptr+1          ; elem_ptr+1
        adc #$00
        sta elem_ptr+1          ; elem_ptr+1
        lda p3_count          ; p3_count
        cmp idx_a
        bcs LC28F
        inc idx_b
        lda p2_count          ; p2_count
        cmp idx_b
        bcc LC2DD
        lda #$00
        sta idx_a          ; idx_a
        jmp LC28F
LC2DD:
        lda #$CA
        sta TXTPTR
        lda #$CF
        sta TXTPTR+1
        jsr PTRGET
        sta $02B7
        sty $02B8
        lda #$D0
        sta TXTPTR
        lda #$CF
        sta TXTPTR+1
        jsr PTRGET
        sta $02B9
        sty $02BA
        lda #$D6
        sta TXTPTR
        lda #$CF
        sta TXTPTR+1
        jsr PTRGET
        sta $02C7
        sty $02C8
        lda #$DD
        sta TXTPTR
        lda #$CF
        sta TXTPTR+1
        jsr PTRGET
        sta $02C3
        sty $02C4
        lda #$E5
        sta TXTPTR
        lda #$CF
        sta TXTPTR+1
        jsr PTRGET
        sta $02C5
        sty $02C6
        lda #$ED
        sta TXTPTR
        lda #$CF
        sta TXTPTR+1
        jsr PTRGET
        sta $02CB
        sty $02CC
        lda $02B3
        sec
        sbc ARYTAB
        sta $02B3
        lda $02B4
        sbc ARYTAB+1
        sta $02B4
        lda $02B5
        sec
        sbc ARYTAB
        sta $02B5
        lda $02B6
        sbc ARYTAB+1
        sta $02B6
        lda $02B7
        sec
        sbc ARYTAB
        sta $02B7
        lda $02B8
        sbc ARYTAB+1
        sta $02B8
        lda $02B9
        sec
        sbc ARYTAB
        sta $02B9
        lda $02BA
        sbc ARYTAB+1
        sta $02BA
        lda $02BF
        sec
        sbc ARYTAB
        sta $02BF
        lda $02C0
        sbc ARYTAB+1
        sta $02C0
        lda $02C1
        sec
        sbc ARYTAB
        sta $02C1
        lda $02C2
        sbc ARYTAB+1
        sta $02C2
        lda $02C3
        sec
        sbc ARYTAB
        sta $02C3
        lda $02C4
        sbc ARYTAB+1
        sta $02C4
        lda $02C5
        sec
        sbc ARYTAB
        sta $02C5
        lda $02C6
        sbc ARYTAB+1
        sta $02C6
        lda $02C7
        sec
        sbc ARYTAB
        sta $02C7
        lda $02C8
        sbc ARYTAB+1
        sta $02C8
        lda $02C9
        sec
        sbc ARYTAB
        sta $02C9
        lda $02CA
        sbc ARYTAB+1
        sta $02CA
        lda $02CB
        sec
        sbc ARYTAB
        sta $02CB
        lda $02CC
        sbc ARYTAB+1
        sta $02CC
        lda ptr_rate          ; ptr_rate
        sec
        sbc VARTAB
        sta ptr_rate          ; ptr_rate
        lda ptr_rate+1          ; ptr_rate+1
        sbc VARTAB+1
        sta ptr_rate+1          ; ptr_rate+1
        lda ptr_mo          ; ptr_mo
        sec
        sbc VARTAB
        sta ptr_mo          ; ptr_mo
        lda ptr_mo+1          ; ptr_mo+1
        sbc VARTAB+1
        sta ptr_mo+1          ; ptr_mo+1
        lda ptr_ep          ; ptr_ep
        sec
        sbc VARTAB
        sta ptr_ep          ; ptr_ep
        lda ptr_ep+1          ; ptr_ep+1
        sbc VARTAB+1
        sta ptr_ep+1          ; ptr_ep+1
        lda $02D2
        sec
        sbc VARTAB
        sta $02D2
        lda $02D3
        sbc VARTAB+1
        sta $02D3
        lda saved_txtptr          ; saved_txtptr
        sta TXTPTR
        lda saved_txtptr+1          ; saved_txtptr+1
        sta TXTPTR+1
        rts

; SYS 49155,pat$ — recognize. Forward pass; outputs in O2() and O3().
recognize:
        lda #$00
        sta $02BB
        jsr LCB1C
        beq LC46F
LC457:
        jsr CHKCOM
        jsr GETBYTC
        stx $02BB
        cpx #$00
        beq LC46C
        lda np_count          ; np_count
        cmp $02BB
        bcs LC46F
LC46C:
        jmp $B248
LC46F:
        lda #$01
        sta idx_a          ; idx_a
LC474:
        lda #$00
        sta idx_b          ; idx_b
        jsr FACBYTE
LC47C:
        ldx #$CD
        ldy #$02
        jsr MOVMF
        lda $02BF
        clc
        adc ARYTAB
        sta elem_ptr          ; elem_ptr
        lda $02C0
        adc ARYTAB+1
        sta elem_ptr+1          ; elem_ptr+1
        ldx idx_b          ; idx_b
        ldy idx_a          ; idx_a
        lda p2_count          ; p2_count
        jsr LC6AA
        lda elem_ptr          ; elem_ptr
        ldy elem_ptr+1          ; elem_ptr+1
        jsr MOVFM
        lda $02C9
        clc
        adc ARYTAB
        sta elem_ptr          ; elem_ptr
        lda $02CA
        adc ARYTAB+1
        sta elem_ptr+1          ; elem_ptr+1
        ldx $02BB
        ldy idx_b          ; idx_b
        lda p1_count          ; p1_count
        jsr LC6AA
        lda elem_ptr          ; elem_ptr
        ldy elem_ptr+1          ; elem_ptr+1
        jsr FMULT
        lda #$CD
        ldy #$02
        jsr FADD
        inc idx_b
        lda p1_count          ; p1_count
        cmp idx_b
        bcs LC47C
        lda #$F2
        ldy #$CF
        jsr FSUB
        jsr $BFED
        jsr $BC0C
        lda #$01
        jsr FACBYTE
        jsr $B86A
        lda #$F7
        ldy #$CF
        jsr FDIV
        lda $02B3
        clc
        adc ARYTAB
        sta elem_ptr          ; elem_ptr
        lda $02B4
        adc ARYTAB+1
        sta elem_ptr+1          ; elem_ptr+1
        lda idx_a          ; idx_a
        jsr LC690
        ldx elem_ptr          ; elem_ptr
        ldy elem_ptr+1          ; elem_ptr+1
        jsr MOVMF
        inc idx_a
        lda p2_count          ; p2_count
        cmp idx_a
        bcc LC52B
        jmp LC474
LC52B:
        lda #$01
        sta idx_a          ; idx_a
LC530:
        lda #$00
        sta idx_b          ; idx_b
        jsr FACBYTE
LC538:
        ldx #$CD
        ldy #$02
        jsr MOVMF
        lda $02C1
        clc
        adc ARYTAB
        sta elem_ptr          ; elem_ptr
        lda $02C2
        adc ARYTAB+1
        sta elem_ptr+1          ; elem_ptr+1
        ldx idx_b          ; idx_b
        ldy idx_a          ; idx_a
        lda p3_count          ; p3_count
        jsr LC6AA
        lda elem_ptr          ; elem_ptr
        ldy elem_ptr+1          ; elem_ptr+1
        jsr MOVFM
        lda $02B3
        clc
        adc ARYTAB
        sta elem_ptr          ; elem_ptr
        lda $02B4
        adc ARYTAB+1
        sta elem_ptr+1          ; elem_ptr+1
        lda idx_b          ; idx_b
        jsr LC690
        lda elem_ptr          ; elem_ptr
        ldy elem_ptr+1          ; elem_ptr+1
        jsr FMULT
        lda #$CD
        ldy #$02
        jsr FADD
        inc idx_b
        lda p2_count          ; p2_count
        cmp idx_b
        bcs LC538
        lda #$F2
        ldy #$CF
        jsr FSUB
        jsr $BFED
        jsr $BC0C
        lda #$01
        jsr FACBYTE
        jsr $B86A
        lda #$F7
        ldy #$CF
        jsr FDIV
        lda $02B5
        clc
        adc ARYTAB
        sta elem_ptr          ; elem_ptr
        lda $02B6
        adc ARYTAB+1
        sta elem_ptr+1          ; elem_ptr+1
        lda idx_a          ; idx_a
        jsr LC690
        ldx elem_ptr          ; elem_ptr
        ldy elem_ptr+1          ; elem_ptr+1
        jsr MOVMF
        inc idx_a
        lda p3_count          ; p3_count
        cmp idx_a
        bcc LC5E1
        jmp LC530
LC5E1:
        lda #$00
        jsr FACBYTE
        lda #$01
        sta idx_a          ; idx_a
LC5EB:
        ldx #$CD
        ldy #$02
        jsr MOVMF
        lda $02B5
        clc
        adc ARYTAB
        sta elem_ptr          ; elem_ptr
        lda $02B6
        adc ARYTAB+1
        sta elem_ptr+1          ; elem_ptr+1
        lda idx_a          ; idx_a
        jsr LC690
        lda elem_ptr          ; elem_ptr
        ldy elem_ptr+1          ; elem_ptr+1
        jsr MOVFM
        lda $02C7
        clc
        adc ARYTAB
        sta elem_ptr          ; elem_ptr
        lda $02C8
        adc ARYTAB+1
        sta elem_ptr+1          ; elem_ptr+1
        lda p3_count          ; p3_count
        ldy idx_a          ; idx_a
        ldx $02BB
        jsr LC6AA
        lda elem_ptr          ; elem_ptr
        ldy elem_ptr+1          ; elem_ptr+1
        jsr FSUB
        ldx #$D8
        ldy #$02
        jsr MOVMF
        lda #$D8
        ldy #$02
        jsr FMULT
        lda #$CD
        ldy #$02
        jsr FADD
        inc idx_a
        lda p3_count          ; p3_count
        cmp idx_a
        bcs LC5EB
        lda $02CB
        clc
        adc ARYTAB
        sta elem_ptr          ; elem_ptr
        lda $02CC
        adc ARYTAB+1
        sta elem_ptr+1          ; elem_ptr+1
        lda $02BB
        jsr LC690
        ldx elem_ptr          ; elem_ptr
        ldy elem_ptr+1          ; elem_ptr+1
        jsr MOVMF
        lda #$02
        jsr FACBYTE
        lda elem_ptr          ; elem_ptr
        ldy elem_ptr+1          ; elem_ptr+1
        jsr FDIV
        ldx elem_ptr          ; elem_ptr
        ldy elem_ptr+1          ; elem_ptr+1
        jsr MOVMF
        rts
LC690:
        tax
        inx
LC692:
        dex
        beq LC6A9
        lda elem_ptr          ; elem_ptr
        clc
        adc #$05
        sta elem_ptr          ; elem_ptr
        lda elem_ptr+1          ; elem_ptr+1
        adc #$00
        sta elem_ptr+1          ; elem_ptr+1
        jmp LC692
LC6A9:
        rts
LC6AA:
        sta $03FD
        tya
        pha
        inx
LC6B0:
        dex
        beq LC6DF
        ldy $03FD
        iny
        lda elem_ptr          ; elem_ptr
        clc
        adc #$05
        sta elem_ptr          ; elem_ptr
        lda elem_ptr+1          ; elem_ptr+1
        adc #$00
        sta elem_ptr+1          ; elem_ptr+1
LC6C8:
        dey
        beq LC6B0
        lda elem_ptr          ; elem_ptr
        clc
        adc #$05
        sta elem_ptr          ; elem_ptr
        lda elem_ptr+1          ; elem_ptr+1
        adc #$00
        sta elem_ptr+1          ; elem_ptr+1
        jmp LC6C8
LC6DF:
        pla
        jmp LC690
LC6E3:
        jsr FOUT
        ldy #$FF
LC6E8:
        iny
        lda $0100,y
        bne LC6E8
        iny
        tya
        pha
        lda #$00
        sta INDEX
        lda #$01
        sta INDEX+1
        pla
        jsr PRINTFAC
        rts

; SYS 49158 — undocumented slot (present in the binary, not in the article).
undoc_49158:
        jsr LC457
        jmp LC707
LC704:
        jsr LC46F
LC707:
        lda #$01
        sta idx_a          ; idx_a
LC70C:
        lda $02C7
        clc
        adc ARYTAB
        sta elem_ptr          ; elem_ptr
        lda $02C8
        adc ARYTAB+1
        sta elem_ptr+1          ; elem_ptr+1
        lda p3_count          ; p3_count
        ldy idx_a          ; idx_a
        ldx $02BB
        jsr LC6AA
        lda elem_ptr          ; elem_ptr
        ldy elem_ptr+1          ; elem_ptr+1
        jsr CONUPK
        lda $02B5
        clc
        adc ARYTAB
        sta elem_ptr          ; elem_ptr
        lda $02B6
        adc ARYTAB+1
        sta elem_ptr+1          ; elem_ptr+1
        lda idx_a          ; idx_a
        jsr LC690
        lda elem_ptr          ; elem_ptr
        ldy elem_ptr+1          ; elem_ptr+1
        jsr MOVFM
        jsr $B853
        lda elem_ptr          ; elem_ptr
        ldy elem_ptr+1          ; elem_ptr+1
        jsr FMULT
        ldx #$CD
        ldy #$02
        jsr MOVMF
        lda elem_ptr          ; elem_ptr
        ldy elem_ptr+1          ; elem_ptr+1
        jsr MOVFM
        lda #$F7
        ldy #$CF
        jsr FSUB
        lda #$CD
        ldy #$02
        jsr FMULT
        lda $02B9
        clc
        adc ARYTAB
        sta elem_ptr          ; elem_ptr
        lda $02BA
        adc ARYTAB+1
        sta elem_ptr+1          ; elem_ptr+1
        lda idx_a          ; idx_a
        jsr LC690
        ldx elem_ptr          ; elem_ptr
        ldy elem_ptr+1          ; elem_ptr+1
        jsr MOVMF
        lda #$00
        sta idx_b          ; idx_b
LC7A1:
        lda ptr_rate          ; ptr_rate
        clc
        adc VARTAB
        pha
        lda ptr_rate+1          ; ptr_rate+1
        adc VARTAB+1
        tay
        pla
        jsr MOVFM
        lda $02B9
        clc
        adc ARYTAB
        sta elem_ptr          ; elem_ptr
        lda $02BA
        adc ARYTAB+1
        sta elem_ptr+1          ; elem_ptr+1
        lda idx_a          ; idx_a
        jsr LC690
        lda elem_ptr          ; elem_ptr
        ldy elem_ptr+1          ; elem_ptr+1
        jsr FMULT
        lda $02B3
        clc
        adc ARYTAB
        sta elem_ptr          ; elem_ptr
        lda $02B4
        adc ARYTAB+1
        sta elem_ptr+1          ; elem_ptr+1
        lda idx_b          ; idx_b
        jsr LC690
        lda elem_ptr          ; elem_ptr
        ldy elem_ptr+1          ; elem_ptr+1
        jsr FMULT
        ldx #$CD
        ldy #$02
        jsr MOVMF
        lda ptr_mo          ; ptr_mo
        clc
        adc VARTAB
        pha
        lda ptr_mo+1          ; ptr_mo+1
        adc VARTAB+1
        tay
        pla
        jsr MOVFM
        lda $02C5
        clc
        adc ARYTAB
        sta elem_ptr          ; elem_ptr
        lda $02C6
        adc ARYTAB+1
        sta elem_ptr+1          ; elem_ptr+1
        lda p3_count          ; p3_count
        ldy idx_a          ; idx_a
        ldx idx_b          ; idx_b
        jsr LC6AA
        lda elem_ptr          ; elem_ptr
        ldy elem_ptr+1          ; elem_ptr+1
        jsr FMULT
        lda #$CD
        ldy #$02
        jsr FADD
        ldx elem_ptr          ; elem_ptr
        ldy elem_ptr+1          ; elem_ptr+1
        jsr MOVMF
        lda $02C1
        clc
        adc ARYTAB
        sta elem_ptr          ; elem_ptr
        lda $02C2
        adc ARYTAB+1
        sta elem_ptr+1          ; elem_ptr+1
        lda p3_count          ; p3_count
        ldy idx_a          ; idx_a
        ldx idx_b          ; idx_b
        jsr LC6AA
        lda elem_ptr          ; elem_ptr
        ldy elem_ptr+1          ; elem_ptr+1
        jsr FADD
        ldx elem_ptr          ; elem_ptr
        ldy elem_ptr+1          ; elem_ptr+1
        jsr MOVMF
        inc idx_b
        lda p2_count          ; p2_count
        cmp idx_b
        bcc LC87D
        jmp LC7A1
LC87D:
        inc idx_a
        lda p3_count          ; p3_count
        cmp idx_a
        bcc LC88B
        jmp LC70C
LC88B:
        lda #$01
        sta idx_a          ; idx_a
LC890:
        lda #$00
        ldy #$05
LC894:
        sta $02CC,y
        dey
        bne LC894
        lda #$01
        sta idx_b          ; idx_b
LC89F:
        lda $02B9
        clc
        adc ARYTAB
        sta elem_ptr          ; elem_ptr
        lda $02BA
        adc ARYTAB+1
        sta elem_ptr+1          ; elem_ptr+1
        lda idx_b          ; idx_b
        jsr LC690
        lda elem_ptr          ; elem_ptr
        ldy elem_ptr+1          ; elem_ptr+1
        jsr MOVFM
        lda $02C1
        clc
        adc ARYTAB
        sta elem_ptr          ; elem_ptr
        lda $02C2
        adc ARYTAB+1
        sta elem_ptr+1          ; elem_ptr+1
        lda p3_count          ; p3_count
        ldy idx_b          ; idx_b
        ldx idx_a          ; idx_a
        jsr LC6AA
        lda elem_ptr          ; elem_ptr
        ldy elem_ptr+1          ; elem_ptr+1
        jsr FMULT
        lda #$CD
        ldy #$02
        jsr FADD
        ldx #$CD
        ldy #$02
        jsr MOVMF
        inc idx_b
        lda p3_count          ; p3_count
        cmp idx_b
        bcs LC89F
        lda $02B3
        clc
        adc ARYTAB
        sta elem_ptr          ; elem_ptr
        lda $02B4
        adc ARYTAB+1
        sta elem_ptr+1          ; elem_ptr+1
        lda idx_a          ; idx_a
        jsr LC690
        lda elem_ptr          ; elem_ptr
        ldy elem_ptr+1          ; elem_ptr+1
        jsr MOVFM
        lda #$F7
        ldy #$CF
        jsr FSUB
        lda elem_ptr          ; elem_ptr
        ldy elem_ptr+1          ; elem_ptr+1
        jsr FMULT
        lda #$CD
        ldy #$02
        jsr FMULT
        lda $02B7
        clc
        adc ARYTAB
        sta elem_ptr          ; elem_ptr
        lda $02B8
        adc ARYTAB+1
        sta elem_ptr+1          ; elem_ptr+1
        lda idx_a          ; idx_a
        jsr LC690
        ldx elem_ptr          ; elem_ptr
        ldy elem_ptr+1          ; elem_ptr+1
        jsr MOVMF
        lda #$00
        sta idx_b          ; idx_b
LC95A:
        lda ptr_rate          ; ptr_rate
        clc
        adc VARTAB
        pha
        lda ptr_rate+1          ; ptr_rate+1
        adc VARTAB+1
        tay
        pla
        jsr MOVFM
        lda $02B7
        clc
        adc ARYTAB
        sta elem_ptr          ; elem_ptr
        lda $02B8
        adc ARYTAB+1
        sta elem_ptr+1          ; elem_ptr+1
        lda idx_a          ; idx_a
        jsr LC690
        lda elem_ptr          ; elem_ptr
        ldy elem_ptr+1          ; elem_ptr+1
        jsr FMULT
        lda $02C9
        clc
        adc ARYTAB
        sta elem_ptr          ; elem_ptr
        lda $02CA
        adc ARYTAB+1
        sta elem_ptr+1          ; elem_ptr+1
        lda p1_count          ; p1_count
        ldy idx_b          ; idx_b
        ldx $02BB
        jsr LC6AA
        lda elem_ptr          ; elem_ptr
        ldy elem_ptr+1          ; elem_ptr+1
        jsr FMULT
        ldx #$CD
        ldy #$02
        jsr MOVMF
        lda ptr_mo          ; ptr_mo
        clc
        adc VARTAB
        pha
        lda ptr_mo+1          ; ptr_mo+1
        adc VARTAB+1
        tay
        pla
        jsr MOVFM
        lda $02C3
        clc
        adc ARYTAB
        sta elem_ptr          ; elem_ptr
        lda $02C4
        adc ARYTAB+1
        sta elem_ptr+1          ; elem_ptr+1
        lda p2_count          ; p2_count
        ldy idx_a          ; idx_a
        ldx idx_b          ; idx_b
        jsr LC6AA
        lda elem_ptr          ; elem_ptr
        ldy elem_ptr+1          ; elem_ptr+1
        jsr FMULT
        lda #$CD
        ldy #$02
        jsr FADD
        ldx elem_ptr          ; elem_ptr
        ldy elem_ptr+1          ; elem_ptr+1
        jsr MOVMF
        lda $02BF
        clc
        adc ARYTAB
        sta elem_ptr          ; elem_ptr
        lda $02C0
        adc ARYTAB+1
        sta elem_ptr+1          ; elem_ptr+1
        lda p2_count          ; p2_count
        ldy idx_a          ; idx_a
        ldx idx_b          ; idx_b
        jsr LC6AA
        lda elem_ptr          ; elem_ptr
        ldy elem_ptr+1          ; elem_ptr+1
        jsr FADD
        ldx elem_ptr          ; elem_ptr
        ldy elem_ptr+1          ; elem_ptr+1
        jsr MOVMF
        inc idx_b
        lda p1_count          ; p1_count
        cmp idx_b
        bcc LCA3C
        jmp LC95A
LCA3C:
        inc idx_a
        lda p2_count          ; p2_count
        cmp idx_a
        bcc LCA4A
        jmp LC890
LCA4A:
        rts

; SYS 49161 — undocumented slot (present in the binary, not in the article).
undoc_49161:
        lda #$00
        jsr FACBYTE
        lda $02D2
        clc
        adc VARTAB
        sta $02D4
        lda $02D3
        adc VARTAB+1
        sta $02D5
        ldx $02D4
        ldy $02D5
        jsr MOVMF
        lda #$01
        sta $02BB
LCA6F:
        jsr LC704
        lda $02CB
        clc
        adc ARYTAB
        sta elem_ptr          ; elem_ptr
        lda $02CC
        adc ARYTAB+1
        sta elem_ptr+1          ; elem_ptr+1
        lda $02BB
        jsr LC690
        lda elem_ptr          ; elem_ptr
        ldy elem_ptr+1          ; elem_ptr+1
        jsr MOVFM
        lda $02D4
        ldy $02D5
        jsr FADD
        ldx $02D4
        ldy $02D5
        jsr MOVMF
        inc $02BB
        lda np_count          ; np_count
        cmp $02BB
        bcs LCA6F
        rts

; SYS 49164,se — learn until te < epsilon. se=1 prints total error each trial.
learn:
        jsr CHKCOM
        jsr GETBYTC
        stx $03FC
        lda ptr_ep          ; ptr_ep
        clc
        adc VARTAB
        sta $02D6
        lda ptr_ep+1          ; ptr_ep+1
        adc VARTAB+1
        sta $02D7
LCACA:
        jsr undoc_49161
        jsr STOP
        beq LCAFF
        lda $03FC
        beq LCAE8
        lda $02D4
        ldy $02D5
        jsr MOVFM
        jsr LC6E3
        lda #$0D
        jsr CHROUT
LCAE8:
        lda $02D4
        ldy $02D5
        jsr MOVFM
        lda $02D6
        ldy $02D7
        jsr FCOMP
        cmp #$01
        beq LCACA
        rts
LCAFF:
        ldy #$00
        jmp OMERR

; SYS 49167,pn,ip$,tp$ — store training pair pn (input string + teacher string).
setpair:
        jsr CHKCOM
        jsr GETBYTC
        stx $02BB
        cpx #$00
        beq LCB19
        lda np_count          ; np_count
        cmp $02BB
        bcs LCB1C
LCB19:
        jmp $B248
LCB1C:
        jsr CHKCOM
        jsr FRMEVL
        jsr CHKNUM
        jsr GETSTR
        cmp p1_count
        bne LCB19
        stx $02CD
        sty $02CE
        lda #$00
        sta idx_a          ; idx_a
LCB38:
        ldx #$01
        ldy idx_a          ; idx_a
        lda $02CD
        sta INDEX
        lda $02CE
        sta INDEX+1
        lda ($22),y
        cmp #$31
        beq LCB4F
        ldx #$00
LCB4F:
        txa
        jsr FACBYTE
        lda $02C9
        clc
        adc ARYTAB
        sta elem_ptr          ; elem_ptr
        lda $02CA
        adc ARYTAB+1
        sta elem_ptr+1          ; elem_ptr+1
        lda p1_count          ; p1_count
        ldy idx_a          ; idx_a
        iny
        ldx $02BB
        jsr LC6AA
        ldx elem_ptr          ; elem_ptr
        ldy elem_ptr+1          ; elem_ptr+1
        jsr MOVMF
        inc idx_a
        lda p1_count          ; p1_count
        cmp idx_a
        bne LCB38
        lda $02BB
        beq LCBF3
        jsr CHKCOM
        jsr FRMEVL
        jsr CHKNUM
        jsr GETSTR
        cmp p3_count
        bne LCBF4
        stx $02CD
        sty $02CE
        lda #$00
        sta idx_a          ; idx_a
LCBA6:
        ldx #$01
        ldy idx_a          ; idx_a
        lda $02CD
        sta INDEX
        lda $02CE
        sta INDEX+1
        lda ($22),y
        cmp #$31
        beq LCBBD
        ldx #$00
LCBBD:
        txa
        jsr FACBYTE
        lda $02C7
        clc
        adc ARYTAB
        sta elem_ptr          ; elem_ptr
        lda $02C8
        adc ARYTAB+1
        sta elem_ptr+1          ; elem_ptr+1
        lda p3_count          ; p3_count
        ldy idx_a          ; idx_a
        iny
        ldx $02BB
        jsr LC6AA
        ldx elem_ptr          ; elem_ptr
        ldy elem_ptr+1          ; elem_ptr+1
        jsr MOVMF
        inc idx_a
        lda p3_count          ; p3_count
        cmp idx_a
        bne LCBA6
LCBF3:
        rts
LCBF4:
        jmp $B248

; SYS 49170,file$ — save network variables/arrays.
save_net:
        jsr LCF0E
        jsr CHKCOM
        jsr FRMEVL
        jsr CHKNUM
        jsr GETSTR
        sta idx_a          ; idx_a
        ldy #$00
LCC0B:
        lda ($22),y
        sta $02DD,y
        iny
        cpy idx_a
        beq LCC1A
        cpy #$14
        bne LCC0B
LCC1A:
        lda #$2C
        sta $02DD,y
        iny
        lda #$57
        sta $02DD,y
        iny
        tya
        ldx #$DD
        ldy #$02
        jsr SETNAM
        lda #$01
        ldx #$08
        ldy #$02
        jsr SETLFS
        jsr OPEN
        ldx #$0F
        jsr CHKIN
        jsr CHRIN
        cmp #$30
        beq LCC49
        jmp LCD4D
LCC49:
        jsr CLRCHN
        ldx #$01
        jsr CHKOUT
        lda p1_count          ; p1_count
        jsr CHROUT
        lda p2_count          ; p2_count
        jsr CHROUT
        lda p3_count          ; p3_count
        jsr CHROUT
        lda np_count          ; np_count
        jsr CHROUT
        ldx ptr_rate          ; ptr_rate
        ldy ptr_rate+1          ; ptr_rate+1
        jsr LCCF9
        ldx ptr_mo          ; ptr_mo
        ldy ptr_mo+1          ; ptr_mo+1
        jsr LCCF9
        ldx ptr_ep          ; ptr_ep
        ldy ptr_ep+1          ; ptr_ep+1
        jsr LCCF9
        lda $02BF
        sta INDEX
        lda $02C0
        sta INDEX+1
        ldy p2_count          ; p2_count
        ldx p1_count          ; p1_count
        jsr LCD11
        lda $02C1
        sta INDEX
        lda $02C2
        sta INDEX+1
        ldy p3_count          ; p3_count
        ldx p2_count          ; p2_count
        jsr LCD11
        lda $02C3
        sta INDEX
        lda $02C4
        sta INDEX+1
        ldy p2_count          ; p2_count
        ldx p1_count          ; p1_count
        jsr LCD11
        lda $02C5
        sta INDEX
        lda $02C6
        sta INDEX+1
        ldy p3_count          ; p3_count
        ldx p2_count          ; p2_count
        jsr LCD11
        lda $02C9
        sta INDEX
        lda $02CA
        sta INDEX+1
        ldy p1_count          ; p1_count
        ldx np_count          ; np_count
        jsr LCD11
        lda $02C7
        sta INDEX
        lda $02C8
        sta INDEX+1
        ldy p3_count          ; p3_count
        ldx np_count          ; np_count
        jsr LCD11
        jmp LCF20
LCCF9:
        txa
        clc
        adc VARTAB
        sta INDEX
        tya
        adc VARTAB+1
        sta INDEX+1
        ldy #$00
LCD06:
        lda ($22),y
        jsr CHROUT
        iny
        cpy #$05
        bne LCD06
        rts
LCD11:
        lda ARYTAB
        clc
        adc INDEX
        sta INDEX
        lda ARYTAB+1
        adc INDEX+1
        sta INDEX+1
        iny
        sty idx_a          ; idx_a
        sty $02CD
        inx
        stx idx_b          ; idx_b
        ldy #$00
        ldx #$05
LCD2D:
        lda ($22),y
        jsr CHROUT
        iny
        bne LCD37
        inc INDEX+1
LCD37:
        dex
        bne LCD2D
        ldx #$05
        dec idx_a
        bne LCD2D
        lda $02CD
        sta idx_a          ; idx_a
        dec idx_b
        bne LCD2D
        rts
LCD4D:
        jsr CHROUT
        jsr CHRIN
        cmp #$0D
        bne LCD4D
        jsr CHROUT
        jsr CLALL
        jsr STXTPT
        jmp ERROR

; SYS 49173,file$ — load a previously saved network.
load_net:
        jsr LCF0E
        jsr CHKCOM
        jsr FRMEVL
        jsr CHKNUM
        jsr GETSTR
        sta idx_a          ; idx_a
        ldy #$00
LCD77:
        lda ($22),y
        sta $02DD,y
        iny
        cpy idx_a
        beq LCD86
        cpy #$14
        bne LCD77
LCD86:
        lda #$2C
        sta $02DD,y
        iny
        lda #$52
        sta $02DD,y
        iny
        tya
        ldx #$DD
        ldy #$02
        jsr SETNAM
        lda #$01
        ldx #$08
        ldy #$02
        jsr SETLFS
        jsr OPEN
        ldx #$0F
        jsr CHKIN
        jsr CHRIN
        cmp #$30
        bne LCD4D
        jsr CLRCHN
        ldx #$01
        jsr CHKIN
        jsr CHRIN
        sta p1_count          ; p1_count
        jsr CHRIN
        sta p2_count          ; p2_count
        jsr CHRIN
        sta p3_count          ; p3_count
        jsr CHRIN
        sta np_count          ; np_count
        jsr LCEB9
        ldx ptr_rate          ; ptr_rate
        ldy ptr_rate+1          ; ptr_rate+1
        jsr LCE65
        ldx ptr_mo          ; ptr_mo
        ldy ptr_mo+1          ; ptr_mo+1
        jsr LCE65
        ldx ptr_ep          ; ptr_ep
        ldy ptr_ep+1          ; ptr_ep+1
        jsr LCE65
        lda $02BF
        sta INDEX
        lda $02C0
        sta INDEX+1
        ldy p2_count          ; p2_count
        ldx p1_count          ; p1_count
        jsr LCE7D
        lda $02C1
        sta INDEX
        lda $02C2
        sta INDEX+1
        ldy p3_count          ; p3_count
        ldx p2_count          ; p2_count
        jsr LCE7D
        lda $02C3
        sta INDEX
        lda $02C4
        sta INDEX+1
        ldy p2_count          ; p2_count
        ldx p1_count          ; p1_count
        jsr LCE7D
        lda $02C5
        sta INDEX
        lda $02C6
        sta INDEX+1
        ldy p3_count          ; p3_count
        ldx p2_count          ; p2_count
        jsr LCE7D
        lda $02C9
        sta INDEX
        lda $02CA
        sta INDEX+1
        ldy p1_count          ; p1_count
        ldx np_count          ; np_count
        jsr LCE7D
        lda $02C7
        sta INDEX
        lda $02C8
        sta INDEX+1
        ldy p3_count          ; p3_count
        ldx np_count          ; np_count
        jsr LCE7D
        jmp LCF20
LCE65:
        txa
        clc
        adc VARTAB
        sta INDEX
        tya
        adc VARTAB+1
        sta INDEX+1
        ldy #$00
LCE72:
        jsr CHRIN
        sta ($22),y
        iny
        cpy #$05
        bne LCE72
        rts
LCE7D:
        lda ARYTAB
        clc
        adc INDEX
        sta INDEX
        lda ARYTAB+1
        adc INDEX+1
        sta INDEX+1
        iny
        sty idx_a          ; idx_a
        sty $02CD
        inx
        stx idx_b          ; idx_b
        ldy #$00
        ldx #$05
LCE99:
        jsr CHRIN
        sta ($22),y
        iny
        bne LCEA3
        inc INDEX+1
LCEA3:
        dex
        bne LCE99
        ldx #$05
        dec idx_a
        bne LCE99
        lda $02CD
        sta idx_a          ; idx_a
        dec idx_b
        bne LCE99
        rts
LCEB9:
        lda MEMSIZ
        ldy MEMSIZ+1
        sta FRETOP
        sty FRETOP+1
        lda VARTAB
        ldy VARTAB+1
        sta ARYTAB
        sty ARYTAB+1
        sta STREND
        sty STREND+1
        lda TXTPTR
        sta saved_txtptr          ; saved_txtptr
        lda TXTPTR+1
        sta saved_txtptr+1          ; saved_txtptr+1
        lda #$8B
        sta TXTPTR
        lda #$CF
        sta TXTPTR+1
        jsr PTRGET
        sta ptr_rate          ; ptr_rate
        sty ptr_rate+1          ; ptr_rate+1
        lda #$8E
        sta TXTPTR
        lda #$CF
        sta TXTPTR+1
        jsr PTRGET
        sta ptr_mo          ; ptr_mo
        sty ptr_mo+1          ; ptr_mo+1
        lda #$91
        sta TXTPTR
        lda #$CF
        sta TXTPTR+1
        jsr PTRGET
        sta ptr_ep          ; ptr_ep
        sty ptr_ep+1          ; ptr_ep+1
        jsr LC0E2
        rts
LCF0E:
        lda #$00
        jsr SETNAM
        lda #$0F
        ldx #$08
        ldy #$0F
        jsr SETLFS
        jsr OPEN
close_files:
        rts
LCF20:
        jsr CLRCHN
        lda #$01
        jsr CLOSE
        lda #$0F
        jsr CLOSE
        rts

; PTRGET name table: DIM list then scalars RA/MO/EP/P1/P2/P3/NP and zero-based array shells.
dim_list:
        .byte "O2(P2),O3(P3),E2(P2),E3(P3),W1(P2,P1),W2(P3,P2),M1(P2,P1),M2(P3,P2),T(P3,NP),IN(P1,NP),E(NP)", $00
        .byte "RA", $00
        .byte "MO", $00
        .byte "EP", $00
        .byte "P1", $00
        .byte "P2", $00
        .byte "P3", $00
        .byte "NP", $00
        .byte "O1(0)", $00
        .byte "O2(0)", $00
        .byte "O3(0)", $00
        .byte "IN(0,0)", $00
        .byte "W1(0,0)", $00
        .byte "W2(0,0)", $00
        .byte "E2(0)", $00
        .byte "E3(0)", $00
        .byte "T(0,0)", $00
        .byte "M1(0,0)", $00
        .byte "M2(0,0)", $00
        .byte "E(0)", $00
        .byte $00, $00, $00, $00, $00, $81, $00, $00, $00, $00
        .byte "TE", $00
