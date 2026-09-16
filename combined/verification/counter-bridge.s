.setcpu "6502"
.export _engine, _run_counter
.segment "RODATA"
_engine:
.incbin "../prg/CL.ML.prg", 2
.segment "CODE"
_run_counter:
    tay
    txa
    jsr $c606
    lda $0400
    ldx $0401
    rts
