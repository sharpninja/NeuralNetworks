; CL.ML — Competitive Learning engine
; Kevin E. Martin, "Future Computing: Neural Networks" Part 3
; COMPUTE!'s Gazette, March 1990 (Issue 81), pp. 43-46
;
; Official Gazette Disk binary (March 1990 companion). Payload is
; $C000-$C98C (2445 bytes). Printed MLX range was $C000-$C98F; the
; three missing tail bytes are $00 $00 $00 after the "TE" marker.
;
; Assemble:
;   ca65 -t c64 CL.ML.s -o CL.ML.o
;   ld65 -C c64-asm.cfg CL.ML.o -o CL.ML.prg
;
; BASIC interface (DIPOLE.prg):
;   SYS 49152, p1, p2, np, rate     init
;   SYS 49155, pat$                 recognize  -> O2(1..p2)
;   SYS 49164, n                    learn n presentations of the set
;   SYS 49167, pn, pat$             store training pattern pn
;   SYS 49170, file$                save network
;   SYS 49173, file$                load network
;
; Signature checked by DIPOLE line 30:
;   PEEK(49153)=24  ($C001 = $18, low byte of init address)
;   PEEK(49157)=194 ($C005 = $C2, high byte of recognize address)
;
; Created BASIC symbols (Table in the March article, plus PAT):
;   RA          learning rate
;   P1, P2, NP  layer-1 size, layer-2 size, pattern count
;   O2(P2)      output / winner flags after a forward pass
;   W1(P2,P1)   excitatory weights, each row sums to 1
;   IN(P1,NP)   training patterns
;   PAT(NP)     scratch / per-pattern workspace
;
; Algorithm (article): no teacher. Each layer-2 PE competes; the
; winner's W1 row is pulled toward the active input bits and away
; from the inactive bits so the row still sums to 1.
;
.setcpu "6502"
.segment "CODE"
.org $C000

; KERNAL / BASIC ROM
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
np_count     = $02AC
saved_txtptr = $02A7
ptr_rate     = $02AD
ptr_o2       = $02B3
ptr_w1       = $02BF
ptr_in       = $02C1
ptr_pat      = $02C3
rec_flag     = $02BB
winner       = $02C5
fac_scratch  = $02CD
elem_ptr     = $0334
idx_p2       = $0336
idx_p1       = $0338



; Jump table. PEEK(49153)=24 ($18) and PEEK(49157)=194 ($C2) is the DIPOLE signature.
jmp_init:
        jmp init_network
jmp_recognize:
        jmp recognize
jmp_unused_49158:
        nop
        nop
        rts
jmp_unused_49161:
        nop
        nop
        rts
jmp_learn:
        jmp learn
jmp_setpattern:
        jmp setpattern
jmp_save:
        jmp save_net
jmp_load:
        jmp load_net

; SYS 49152,p1,p2,np,rate — create BASIC vars and init W1 rows to 1/p1.
init_network:
        jsr CHKCOM
        jsr GETBYTC
        stx p1_count          ; p1_count
        jsr CHKCOM
        jsr GETBYTC
        stx p2_count          ; p2_count
        jsr CHKCOM
        jsr GETBYTC
        stx np_count          ; np_count
        jsr CHKCOM
        lda TXTPTR
        sta saved_txtptr          ; saved_txtptr
        lda TXTPTR+1
        sta saved_txtptr+1          ; saved_txtptr+1

; TXTPTR := "RA" at var_rate; PTRGET creates scalar RA (learning rate).
        lda #$58
        sta TXTPTR
        lda #$C9
        sta TXTPTR+1
        jsr PTRGET
        sta ptr_rate          ; ptr_rate
        sty ptr_rate+1          ; ptr_rate+1
        lda saved_txtptr          ; saved_txtptr
        sta TXTPTR
        lda saved_txtptr+1          ; saved_txtptr+1
        sta TXTPTR+1

; FRMNUM reads the rate argument; store into RA.
        jsr FRMNUM
        ldx ptr_rate          ; ptr_rate
        ldy ptr_rate+1          ; ptr_rate+1
        jsr MOVMF
        lda TXTPTR
        sta saved_txtptr          ; saved_txtptr
        lda TXTPTR+1
        sta saved_txtptr+1          ; saved_txtptr+1

; Create P1, P2, NP scalars from the three byte arguments.
create_scalars:
        lda #$5B
        sta TXTPTR
        lda #$C9
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
        lda #$5E
        sta TXTPTR
        lda #$C9
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
        lda #$61
        sta TXTPTR
        lda #$C9
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

; PTRGET2 on the DIM list O2(P2),W1(P2,P1),IN(P1,NP),PAT(NP).
        lda #$35
        sta TXTPTR
        lda #$C9
        sta TXTPTR+1
        lda $C935
        jsr PTRGET2

; Create array descriptors O2(0), IN(0,0), W1(0,0).
        lda #$64
        sta TXTPTR
        lda #$C9
        sta TXTPTR+1
        jsr PTRGET
        sta ptr_o2          ; ptr_o2
        sty ptr_o2+1          ; ptr_o2+1
        lda #$01
        jsr FACBYTE
        ldx ptr_o2          ; ptr_o2
        ldy ptr_o2+1          ; ptr_o2+1
        jsr MOVMF
        lda #$6A
        sta TXTPTR
        lda #$C9
        sta TXTPTR+1
        jsr PTRGET
        sta ptr_in          ; ptr_in
        sty ptr_in+1          ; ptr_in+1
        lda #$01
        sta idx_p2          ; idx_p2
        lda #$00
        sta idx_p1          ; idx_p1
        lda #$72
        sta TXTPTR
        lda #$C9
        sta TXTPTR+1
        jsr PTRGET
        sta ptr_w1          ; ptr_w1
        sty ptr_w1+1          ; ptr_w1+1

; For each W1(p2,p1): seed first column with 0, remaining with RND; then normalize the row so weights sum to 1.
init_w1_col:
        lda idx_p1          ; idx_p1
        bne init_w1_rnd
        lda #$00
        jsr FACBYTE
        ldy ptr_w1+1          ; ptr_w1+1
        ldx ptr_w1          ; ptr_w1
        jsr MOVMF
        jmp init_w1_nextcol
init_w1_rnd:
        lda #$01
        jsr FACBYTE
        jsr RND0
        lda ptr_w1          ; ptr_w1
        sta elem_ptr          ; elem_ptr
        lda ptr_w1+1          ; ptr_w1+1
        sta elem_ptr+1          ; elem_ptr+1
        ldy idx_p2          ; idx_p2
        ldx idx_p1          ; idx_p1
        lda p2_count          ; p2_count
        jsr index_fac
        ldy elem_ptr+1          ; elem_ptr+1
        ldx elem_ptr          ; elem_ptr
        jsr MOVMF
        lda ptr_w1          ; ptr_w1
        ldy ptr_w1+1          ; ptr_w1+1
        jsr MOVFM
        lda elem_ptr          ; elem_ptr
        ldy elem_ptr+1          ; elem_ptr+1
        jsr FADD
        ldx ptr_w1          ; ptr_w1
        ldy ptr_w1+1          ; ptr_w1+1
        jsr MOVMF
init_w1_nextcol:
        inc idx_p1
        lda p1_count          ; p1_count
        cmp idx_p1
        bcs init_w1_col
        lda #$01
        sta idx_p1          ; idx_p1
normalize_row:
        lda ptr_w1          ; ptr_w1
        sta elem_ptr          ; elem_ptr
        lda ptr_w1+1          ; ptr_w1+1
        sta elem_ptr+1          ; elem_ptr+1
        ldy idx_p2          ; idx_p2
        ldx idx_p1          ; idx_p1
        lda p2_count          ; p2_count
        jsr index_fac
        lda ptr_w1          ; ptr_w1
        ldy ptr_w1+1          ; ptr_w1+1
        jsr MOVFM
        lda elem_ptr          ; elem_ptr
        ldy elem_ptr+1          ; elem_ptr+1
        jsr FDIV
        ldy elem_ptr+1          ; elem_ptr+1
        ldx elem_ptr          ; elem_ptr
        jsr MOVMF
        inc idx_p1
        lda p1_count          ; p1_count
        cmp idx_p1
        bcs normalize_row
        inc idx_p2
        lda p2_count          ; p2_count
        cmp idx_p2
        bcc create_pat
        lda #$00
        sta idx_p1          ; idx_p1
        jmp init_w1_col

; Create PAT(0). Convert array pointers from absolute to offsets from ARYTAB/VARTAB so they survive string garbage collection.
create_pat:
        lda #$7A
        sta TXTPTR
        lda #$C9
        sta TXTPTR+1
        jsr PTRGET
        sta ptr_pat          ; ptr_pat
        sty ptr_pat+1          ; ptr_pat+1
        lda ptr_o2          ; ptr_o2
        sec
        sbc ARYTAB
        sta ptr_o2          ; ptr_o2
        lda ptr_o2+1          ; ptr_o2+1
        sbc ARYTAB+1
        sta ptr_o2+1          ; ptr_o2+1
        lda ptr_w1          ; ptr_w1
        sec
        sbc ARYTAB
        sta ptr_w1          ; ptr_w1
        lda ptr_w1+1          ; ptr_w1+1
        sbc ARYTAB+1
        sta ptr_w1+1          ; ptr_w1+1
        lda ptr_in          ; ptr_in
        sec
        sbc ARYTAB
        sta ptr_in          ; ptr_in
        lda ptr_in+1          ; ptr_in+1
        sbc ARYTAB+1
        sta ptr_in+1          ; ptr_in+1
        lda ptr_pat          ; ptr_pat
        sec
        sbc ARYTAB
        sta ptr_pat          ; ptr_pat
        lda ptr_pat+1          ; ptr_pat+1
        sbc ARYTAB+1
        sta ptr_pat+1          ; ptr_pat+1
        lda ptr_rate          ; ptr_rate
        sec
        sbc VARTAB
        sta ptr_rate          ; ptr_rate
        lda ptr_rate+1          ; ptr_rate+1
        sbc VARTAB+1
        sta ptr_rate+1          ; ptr_rate+1
        lda saved_txtptr          ; saved_txtptr
        sta TXTPTR
        lda saved_txtptr+1          ; saved_txtptr+1
        sta TXTPTR+1
        rts

; SYS 49155,pat$ — recognize. Parse the 0/1 string, run one forward pass, leave the winner in O2.
recognize:
        lda #$00
        sta rec_flag          ; rec_flag
        jsr parse_patstr
recog_setup:
        lda #$01
        sta idx_p2          ; idx_p2
        lda #$00
        sta winner          ; winner
recog_loop:
        lda #$01
        sta idx_p1          ; idx_p1
        lda #$00
        jsr FACBYTE
LC263:
        ldx #$CD
        ldy #$02
        jsr MOVMF
        lda ptr_w1          ; ptr_w1
        clc
        adc ARYTAB
        sta elem_ptr          ; elem_ptr
        lda ptr_w1+1          ; ptr_w1+1
        adc ARYTAB+1
        sta elem_ptr+1          ; elem_ptr+1
        ldx idx_p1          ; idx_p1
        ldy idx_p2          ; idx_p2
        lda p2_count          ; p2_count
        jsr index_fac
        lda elem_ptr          ; elem_ptr
        ldy elem_ptr+1          ; elem_ptr+1
        jsr MOVFM
        lda ptr_in          ; ptr_in
        clc
        adc ARYTAB
        sta elem_ptr          ; elem_ptr
        lda ptr_in+1          ; ptr_in+1
        adc ARYTAB+1
        sta elem_ptr+1          ; elem_ptr+1
        ldx rec_flag          ; rec_flag
        ldy idx_p1          ; idx_p1
        lda p1_count          ; p1_count
        jsr index_fac
        lda elem_ptr          ; elem_ptr
        ldy elem_ptr+1          ; elem_ptr+1
        jsr FMULT
        lda #$CD
        ldy #$02
        jsr FADD
        inc idx_p1
        lda p1_count          ; p1_count
        cmp idx_p1
        bcs LC263
        lda winner          ; winner
        bne LC2D5
        lda #$01
        sta winner          ; winner
        jmp LC324
LC2D5:
        ldx #$CD
        ldy #$02
        jsr MOVMF
        lda ptr_o2          ; ptr_o2
        clc
        adc ARYTAB
        sta elem_ptr          ; elem_ptr
        lda ptr_o2+1          ; ptr_o2+1
        adc ARYTAB+1
        sta elem_ptr+1          ; elem_ptr+1
        lda winner          ; winner
        jsr add5_ptr
        lda elem_ptr          ; elem_ptr
        ldy elem_ptr+1          ; elem_ptr+1
        jsr MOVFM
        lda #$CD
        ldy #$02
        jsr FCOMP
        pha
        lda #$00
        jsr FACBYTE
        pla
        cmp #$01
        beq LC324
        ldx elem_ptr          ; elem_ptr
        ldy elem_ptr+1          ; elem_ptr+1
        jsr MOVMF
        lda idx_p2          ; idx_p2
        sta winner          ; winner
        lda #$CD
        ldy #$02
        jsr MOVFM
LC324:
        lda ptr_o2          ; ptr_o2
        clc
        adc ARYTAB
        sta elem_ptr          ; elem_ptr
        lda ptr_o2+1          ; ptr_o2+1
        adc ARYTAB+1
        sta elem_ptr+1          ; elem_ptr+1
        lda idx_p2          ; idx_p2
        jsr add5_ptr
        ldx elem_ptr          ; elem_ptr
        ldy elem_ptr+1          ; elem_ptr+1
        jsr MOVMF
        inc idx_p2
        lda p2_count          ; p2_count
        cmp idx_p2
        bcc LC352
        jmp recog_loop
LC352:
        lda ptr_o2          ; ptr_o2
        clc
        adc ARYTAB
        sta elem_ptr          ; elem_ptr
        lda ptr_o2+1          ; ptr_o2+1
        adc ARYTAB+1
        sta elem_ptr+1          ; elem_ptr+1
        lda winner          ; winner
        jsr add5_ptr
        lda #$01
        jsr FACBYTE
        ldx elem_ptr          ; elem_ptr
        ldy elem_ptr+1          ; elem_ptr+1
        jsr MOVMF
        rts
add5_ptr:
        tax
        inx
LC37A:
        dex
        beq LC391
        lda elem_ptr          ; elem_ptr
        clc
        adc #$05
        sta elem_ptr          ; elem_ptr
        lda elem_ptr+1          ; elem_ptr+1
        adc #$00
        sta elem_ptr+1          ; elem_ptr+1
        jmp LC37A
LC391:
        rts

; Index helper: FAC-element pointer := base + (x-1)*stride + (y-1)*5  (5-byte FAC).
index_fac:
        sta $03FD
        tya
        pha
        inx
LC398:
        dex
        beq LC3C7
        ldy $03FD
        iny
        lda elem_ptr          ; elem_ptr
        clc
        adc #$05
        sta elem_ptr          ; elem_ptr
        lda elem_ptr+1          ; elem_ptr+1
        adc #$00
        sta elem_ptr+1          ; elem_ptr+1
LC3B0:
        dey
        beq LC398
        lda elem_ptr          ; elem_ptr
        clc
        adc #$05
        sta elem_ptr          ; elem_ptr
        lda elem_ptr+1          ; elem_ptr+1
        adc #$00
        sta elem_ptr+1          ; elem_ptr+1
        jmp LC3B0
LC3C7:
        pla
        jmp add5_ptr
        .byte $20, $DD, $BD, $A0, $FF, $C8, $B9, $00, $01, $D0, $FA, $C8, $98, $48, $A9, $00
        .byte $85, $22, $A9, $01, $85, $23, $68, $20, $24, $AB, $60
LC3E6:
        lda #$01
        sta idx_p2          ; idx_p2
LC3EB:
        lda ptr_pat          ; ptr_pat
        clc
        adc ARYTAB
        sta elem_ptr          ; elem_ptr
        lda ptr_pat+1          ; ptr_pat+1
        adc ARYTAB+1
        sta elem_ptr+1          ; elem_ptr+1
        lda idx_p2          ; idx_p2
        jsr add5_ptr
        lda idx_p2          ; idx_p2
        jsr FACBYTE
        ldx elem_ptr          ; elem_ptr
        ldy elem_ptr+1          ; elem_ptr+1
        jsr MOVMF
        inc idx_p2
        lda np_count          ; np_count
        cmp idx_p2
        bcs LC3EB
        lda #$01
        sta idx_p2          ; idx_p2
LC421:
        ldy np_count          ; np_count
        iny
        tya
        sec
        sbc idx_p2
        jsr FACBYTE
        ldx #$CD
        ldy #$02
        jsr MOVMF
        lda #$01
        jsr FACBYTE
        jsr RND0
        lda #$CD
        ldy #$02
        jsr FMULT
        jsr FACINT
        ldx #$CD
        ldy #$02
        jsr MOVMF
        lda idx_p2          ; idx_p2
        jsr FACBYTE
        lda #$CD
        ldy #$02
        jsr FADD
        jsr COMBYTE
        stx idx_p1          ; idx_p1
        lda ptr_pat          ; ptr_pat
        clc
        adc ARYTAB
        sta elem_ptr          ; elem_ptr
        lda ptr_pat+1          ; ptr_pat+1
        adc ARYTAB+1
        sta elem_ptr+1          ; elem_ptr+1
        lda idx_p2          ; idx_p2
        jsr add5_ptr
        lda elem_ptr          ; elem_ptr
        sta fac_scratch          ; fac_scratch
        ldy elem_ptr+1          ; elem_ptr+1
        sty $02CE
        jsr CONUPK
        lda ptr_pat          ; ptr_pat
        clc
        adc ARYTAB
        sta elem_ptr          ; elem_ptr
        lda ptr_pat+1          ; ptr_pat+1
        adc ARYTAB+1
        sta elem_ptr+1          ; elem_ptr+1
        lda idx_p1          ; idx_p1
        jsr add5_ptr
        lda elem_ptr          ; elem_ptr
        ldy elem_ptr+1          ; elem_ptr+1
        jsr MOVFM
        ldx fac_scratch          ; fac_scratch
        ldy $02CE
        jsr MOVMF
        jsr MOVFA
        ldx elem_ptr          ; elem_ptr
        ldy elem_ptr+1          ; elem_ptr+1
        jsr MOVMF
        inc idx_p2
        lda np_count          ; np_count
        cmp idx_p2
        bcc LC4C9
        jmp LC421
LC4C9:
        lda #$01
        sta $02C6
LC4CE:
        lda ptr_pat          ; ptr_pat
        clc
        adc ARYTAB
        sta elem_ptr          ; elem_ptr
        lda ptr_pat+1          ; ptr_pat+1
        adc ARYTAB+1
        sta elem_ptr+1          ; elem_ptr+1
        lda $02C6
        jsr add5_ptr
        lda elem_ptr          ; elem_ptr
        ldy elem_ptr+1          ; elem_ptr+1
        jsr MOVFM
        jsr COMBYTE
        txa
        sta rec_flag          ; rec_flag
        jsr recog_setup
        lda ptr_in          ; ptr_in
        clc
        adc ARYTAB
        sta elem_ptr          ; elem_ptr
        lda ptr_in+1          ; ptr_in+1
        adc ARYTAB+1
        sta elem_ptr+1          ; elem_ptr+1
        ldy #$00
        ldx rec_flag          ; rec_flag
        lda p1_count          ; p1_count
        jsr index_fac
        lda elem_ptr          ; elem_ptr
        ldy elem_ptr+1          ; elem_ptr+1
        jsr MOVFM
        jsr COMBYTE
        cpx #$00
        bne LC527
        jmp LC5EE
LC527:
        lda #$01
        sta idx_p2          ; idx_p2
LC52C:
        lda ptr_in          ; ptr_in
        clc
        adc ARYTAB
        sta elem_ptr          ; elem_ptr
        lda ptr_in+1          ; ptr_in+1
        adc ARYTAB+1
        sta elem_ptr+1          ; elem_ptr+1
        lda p1_count          ; p1_count
        ldy #$00
        ldx rec_flag          ; rec_flag
        jsr index_fac
        lda elem_ptr          ; elem_ptr
        ldy elem_ptr+1          ; elem_ptr+1
        jsr MOVFM
        lda ptr_in          ; ptr_in
        clc
        adc ARYTAB
        sta elem_ptr          ; elem_ptr
        lda ptr_in+1          ; ptr_in+1
        adc ARYTAB+1
        sta elem_ptr+1          ; elem_ptr+1
        lda p1_count          ; p1_count
        ldy idx_p2          ; idx_p2
        ldx rec_flag          ; rec_flag
        jsr index_fac
        lda elem_ptr          ; elem_ptr
        ldy elem_ptr+1          ; elem_ptr+1
        jsr FDIV
        lda ptr_rate          ; ptr_rate
        clc
        adc VARTAB
        sta elem_ptr          ; elem_ptr
        lda ptr_rate+1          ; ptr_rate+1
        adc VARTAB+1
        sta elem_ptr+1          ; elem_ptr+1
        lda elem_ptr          ; elem_ptr
        ldy elem_ptr+1          ; elem_ptr+1
        jsr FMULT
        ldx #$CD
        ldy #$02
        jsr MOVMF
        lda elem_ptr          ; elem_ptr
        ldy elem_ptr+1          ; elem_ptr+1
        jsr MOVFM
        lda ptr_w1          ; ptr_w1
        clc
        adc ARYTAB
        sta elem_ptr          ; elem_ptr
        lda ptr_w1+1          ; ptr_w1+1
        adc ARYTAB+1
        sta elem_ptr+1          ; elem_ptr+1
        lda p2_count          ; p2_count
        ldy winner          ; winner
        ldx idx_p2          ; idx_p2
        jsr index_fac
        lda elem_ptr          ; elem_ptr
        ldy elem_ptr+1          ; elem_ptr+1
        jsr FMULT
        lda #$CD
        ldy #$02
        jsr FSUB
        lda elem_ptr          ; elem_ptr
        ldy elem_ptr+1          ; elem_ptr+1
        jsr FADD
        ldx elem_ptr          ; elem_ptr
        ldy elem_ptr+1          ; elem_ptr+1
        jsr MOVMF
        inc idx_p2
        lda p1_count          ; p1_count
        cmp idx_p2
        bcc LC5EE
        jmp LC52C
LC5EE:
        inc $02C6
        lda np_count          ; np_count
        cmp $02C6
        bcc LC5FC
        jmp LC4CE
LC5FC:
        rts

; SYS 49164,n — present the training set n times. Each pass: compete, then update the winning row of W1.
learn:
        jsr CHKCOM
        jsr FRMNUM
        jsr FRESTR
        sta $02C8
        sty $02C7
        cpy #$00
        bne LC614
        cmp #$00
        beq LC62B
LC614:
        jsr LC3E6
        jsr STOP
        beq LC62C
        dec $02C7
        bne LC614
        lda $02C8
        beq LC62B
        dec $02C8
        bne LC614
LC62B:
        rts
LC62C:
        ldy #$00
        jmp OMERR

; SYS 49167,pn,pat$ — store input pattern pn (1-based) into IN( ,pn).
setpattern:
        jsr CHKCOM
        jsr GETBYTC
        stx rec_flag          ; rec_flag
        cpx #$00
        beq LC646
        lda np_count          ; np_count
        cmp rec_flag
        bcs parse_patstr
LC646:
        jmp $B248
parse_patstr:
        jsr CHKCOM
        jsr FRMEVL
        jsr CHKNUM
        jsr GETSTR
        cmp p1_count
        bne LC646
        stx fac_scratch          ; fac_scratch
        sty $02CE
        lda #$00
        sta idx_p2          ; idx_p2
        sta idx_p1          ; idx_p1
LC668:
        ldy idx_p2          ; idx_p2
        lda fac_scratch          ; fac_scratch
        sta INDEX
        lda $02CE
        sta INDEX+1
        lda ($22),y
        cmp #$31
        beq LC67F
        lda #$00
        beq LC684
LC67F:
        inc idx_p1
        lda #$01
LC684:
        jsr FACBYTE
        lda ptr_in          ; ptr_in
        clc
        adc ARYTAB
        sta elem_ptr          ; elem_ptr
        lda ptr_in+1          ; ptr_in+1
        adc ARYTAB+1
        sta elem_ptr+1          ; elem_ptr+1
        lda p1_count          ; p1_count
        ldy idx_p2          ; idx_p2
        iny
        ldx rec_flag          ; rec_flag
        jsr index_fac
        ldx elem_ptr          ; elem_ptr
        ldy elem_ptr+1          ; elem_ptr+1
        jsr MOVMF
        inc idx_p2
        lda p1_count          ; p1_count
        cmp idx_p2
        bne LC668
        lda idx_p1          ; idx_p1
        jsr FACBYTE
        lda ptr_in          ; ptr_in
        clc
        adc ARYTAB
        sta elem_ptr          ; elem_ptr
        lda ptr_in+1          ; ptr_in+1
        adc ARYTAB+1
        sta elem_ptr+1          ; elem_ptr+1
        lda p1_count          ; p1_count
        ldy #$00
        ldx rec_flag          ; rec_flag
        jsr index_fac
        ldx elem_ptr          ; elem_ptr
        ldy elem_ptr+1          ; elem_ptr+1
        jsr MOVMF
        rts
        .byte $4C, $48, $B2

; SYS 49170,filename$ — save network (RA,P1,P2,NP,O2,W1,IN,PAT) as a SEQ file.
save_net:
        jsr open_cmd15
        jsr CHKCOM
        jsr FRMEVL
        jsr CHKNUM
        jsr GETSTR
        sta idx_p2          ; idx_p2
        ldy #$00
LC6FC:
        lda ($22),y
        sta $02DD,y
        iny
        cpy idx_p2
        beq LC70B
        cpy #$14
        bne LC6FC
LC70B:
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
        beq LC73A
        jmp LC7DA
LC73A:
        jsr CLRCHN
        ldx #$01
        jsr CHKOUT
        lda p1_count          ; p1_count
        jsr CHROUT
        lda p2_count          ; p2_count
        jsr CHROUT
        lda np_count          ; np_count
        jsr CHROUT
        ldx ptr_rate          ; ptr_rate
        ldy ptr_rate+1          ; ptr_rate+1
        jsr LC786
        lda ptr_w1          ; ptr_w1
        sta INDEX
        lda ptr_w1+1          ; ptr_w1+1
        sta INDEX+1
        ldy p2_count          ; p2_count
        ldx p1_count          ; p1_count
        jsr LC79E
        lda ptr_in          ; ptr_in
        sta INDEX
        lda ptr_in+1          ; ptr_in+1
        sta INDEX+1
        ldy p1_count          ; p1_count
        ldx np_count          ; np_count
        jsr LC79E
        jmp close_files
LC786:
        txa
        clc
        adc VARTAB
        sta INDEX
        tya
        adc VARTAB+1
        sta INDEX+1
        ldy #$00
LC793:
        lda ($22),y
        jsr CHROUT
        iny
        cpy #$05
        bne LC793
        rts
LC79E:
        lda ARYTAB
        clc
        adc INDEX
        sta INDEX
        lda ARYTAB+1
        adc INDEX+1
        sta INDEX+1
        iny
        sty idx_p2          ; idx_p2
        sty fac_scratch          ; fac_scratch
        inx
        stx idx_p1          ; idx_p1
        ldy #$00
        ldx #$05
LC7BA:
        lda ($22),y
        jsr CHROUT
        iny
        bne LC7C4
        inc INDEX+1
LC7C4:
        dex
        bne LC7BA
        ldx #$05
        dec idx_p2
        bne LC7BA
        lda fac_scratch          ; fac_scratch
        sta idx_p2          ; idx_p2
        dec idx_p1
        bne LC7BA
        rts
LC7DA:
        jsr CHROUT
        jsr CHRIN
        cmp #$0D
        bne LC7DA
        jsr CHROUT
        jsr CLALL
        jsr STXTPT
        jmp ERROR

; SYS 49173,filename$ — load a previously saved network.
load_net:
        jsr open_cmd15
        jsr CHKCOM
        jsr FRMEVL
        jsr CHKNUM
        jsr GETSTR
        sta idx_p2          ; idx_p2
        ldy #$00
LC804:
        lda ($22),y
        sta $02DD,y
        iny
        cpy idx_p2
        beq LC813
        cpy #$14
        bne LC804
LC813:
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
        bne LC7DA
        jsr CLRCHN
        ldx #$01
        jsr CHKIN
        jsr CHRIN
        sta p1_count          ; p1_count
        jsr CHRIN
        sta p2_count          ; p2_count
        jsr CHRIN
        sta np_count          ; np_count
        jsr snap_mem
        ldx ptr_rate          ; ptr_rate
        ldy ptr_rate+1          ; ptr_rate+1
        jsr LC88E
        lda ptr_w1          ; ptr_w1
        sta INDEX
        lda ptr_w1+1          ; ptr_w1+1
        sta INDEX+1
        ldy p2_count          ; p2_count
        ldx p1_count          ; p1_count
        jsr copy_bytes
        lda ptr_in          ; ptr_in
        sta INDEX
        lda ptr_in+1          ; ptr_in+1
        sta INDEX+1
        ldy p1_count          ; p1_count
        ldx np_count          ; np_count
        jsr copy_bytes
        jmp close_files
LC88E:
        txa
        clc
        adc VARTAB
        sta INDEX
        tya
        adc VARTAB+1
        sta INDEX+1
        ldy #$00
LC89B:
        jsr CHRIN
        sta ($22),y
        iny
        cpy #$05
        bne LC89B
        rts
copy_bytes:
        lda ARYTAB
        clc
        adc INDEX
        sta INDEX
        lda ARYTAB+1
        adc INDEX+1
        sta INDEX+1
        iny
        sty idx_p2          ; idx_p2
        sty fac_scratch          ; fac_scratch
        inx
        stx idx_p1          ; idx_p1
        ldy #$00
        ldx #$05
LC8C2:
        jsr CHRIN
        sta ($22),y
        iny
        bne LC8CC
        inc INDEX+1
LC8CC:
        dex
        bne LC8C2
        ldx #$05
        dec idx_p2
        bne LC8C2
        lda fac_scratch          ; fac_scratch
        sta idx_p2          ; idx_p2
        dec idx_p1
        bne LC8C2
        rts

; Snapshot BASIC memory bounds before a file transfer.
snap_mem:
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
        lda #$58
        sta TXTPTR
        lda #$C9
        sta TXTPTR+1
        jsr PTRGET
        sta ptr_rate          ; ptr_rate
        sty ptr_rate+1          ; ptr_rate+1
        jsr create_scalars
        rts

; SETLFS 15,8,15 / OPEN command channel.
open_cmd15:
        lda #$00
        jsr SETNAM
        lda #$0F
        ldx #$08
        ldy #$0F
        jsr SETLFS
        jsr OPEN
        rts
close_files:
        jsr CLRCHN
        lda #$01
        jsr CLOSE
        lda #$0F
        jsr CLOSE
        rts

; Name list fed to PTRGET so the arrays exist as real BASIC variables.
; Layout at $C935 (init does LDA $C935 / JSR PTRGET2 for the DIM list):
;   O2(P2),W1(P2,P1),IN(P1,NP),PAT(NP)  $00
;   RA $00 P1 $00 P2 $00 NP $00
;   O2(0) $00 IN(0,0) $00 W1(0,0) $00 PAT(0) $00
;   padding / FAC seed $81 / "TE" end marker
dim_list:
        .byte "O2(P2),W1(P2,P1),IN(P1,NP),PAT(NP)", $00
        .byte "RA", $00
        .byte "P1", $00
        .byte "P2", $00
        .byte "NP", $00
        .byte "O2(0)", $00
        .byte "IN(0,0)", $00
        .byte "W1(0,0)", $00
        .byte "PAT(0)", $00
        .byte $00, $00, $00, $00, $00, $81, $00, $00, $00, $00
        .byte "TE"
