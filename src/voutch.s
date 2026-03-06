;==============================================================
; K-1008 VISABLE MEMORY - Character Display Routines
; MTU K-1008 mapped at $C000-$DFFF
;
; Display: 320 x 200 pixels, 40 bytes/scanline
; Text:    40 columns x 25 rows, 8x8 pixel characters
;          Bit 7 of each byte = leftmost pixel (MSB-first)
;
; USAGE - modeled after KIM-1 OUTCH ($1EA0):
;
;   JSR  VINIT      ; once at startup: clear screen, home cursor
;
;   LDA  #'H'
;   JSR  VOUTCH     ; display character, advance cursor
;
;   LDA  #$0D       ; move to next line (scrolls at bottom)
;   JSR  VOUTCH
;
; Supported input values:
;   $08        -> backspace (move cursor back one column; wraps to prev row)
;   $0A / $0D  -> newline (column 0, next row; scrolls at bottom)
;   $20-$5F    -> printable: space, 0-9, A-Z, punctuation
;   $61-$7A    -> lowercase a-z (silently upcased to A-Z)
;   All other values are ignored.
;
; Zero page used ($E0-$E5):
;   VCOL   $E0   cursor column  (0-39)
;   VROW   $E1   cursor row     (0-24)
;   VPTR   $E2   font read ptr, lo byte  }
;   VPTR1  $E3   font read ptr, hi byte  } 16-bit
;   VDST   $E4   screen write ptr, lo    }
;   VDST1  $E5   screen write ptr, hi    } 16-bit
;
; Clobbers: A, X, Y
;==============================================================

VMBASE  = $C000
VWIDTH  = 40
VCOLS   = 40
VROWS   = 25

VCOL    = $E0
VROW    = $E1
VPTR    = $E2
VPTR1   = $E3
VDST    = $E4
VDST1   = $E5

VINIT:
        lda  #0
        sta  VCOL
        sta  VROW

VCLR:
        lda  #<VMBASE
        sta  VDST
        lda  #>VMBASE
        sta  VDST1
        lda  #0
        ldx  #$20
        ldy  #0
VCLR1:  sta  (VDST),y
        iny
        bne  VCLR1
        inc  VDST1
        dex
        bne  VCLR1
        rts

VOUTCH:
        cmp  #$08
        bne  VNOTBS
        jmp  VBKSP
VNOTBS:
        cmp  #$0D
        beq  VCRLF
        cmp  #$0A
        beq  VCRLF

        cmp  #$20
        bcc  VOUT_RTS

        cmp  #$61
        bcc  VNOTLWR
        cmp  #$7B
        bcs  VNOTLWR
        sec
        sbc  #$20
VNOTLWR:
        cmp  #$60
        bcs  VOUT_RTS

        sec
        sbc  #$20
        tax

        lda  #0
        sta  VPTR1
        txa
        asl  a
        rol  VPTR1
        asl  a
        rol  VPTR1
        asl  a
        rol  VPTR1
        clc
        adc  #<VFONT
        sta  VPTR
        lda  VPTR1
        adc  #>VFONT
        sta  VPTR1

        lda  VROW
        asl  a
        tax
        lda  VROWTBL,x
        clc
        adc  VCOL
        sta  VDST
        lda  VROWTBL+1,x
        adc  #0
        sta  VDST1

        ldy  #0
        ldx  #8
VREND:
        lda  (VPTR),y
        sta  (VDST),y

        inc  VPTR
        bne  VNXT_DST
        inc  VPTR1

VNXT_DST:
        lda  VDST
        clc
        adc  #VWIDTH
        sta  VDST
        bcc  VREND_CHK
        inc  VDST1

VREND_CHK:
        dex
        bne  VREND

        inc  VCOL
        lda  VCOL
        cmp  #VCOLS
        bcc  VOUT_RTS

VCRLF:
        lda  #0
        sta  VCOL
        inc  VROW
        lda  VROW
        cmp  #VROWS
        bcc  VOUT_RTS

        jsr  VSCROLL
        lda  #VROWS-1
        sta  VROW

VOUT_RTS:
        rts

VBKSP:
        lda  VCOL
        bne  VBKSP_DEC
        lda  VROW
        beq  VOUT_RTS
        dec  VROW
        lda  #VCOLS-1
        sta  VCOL
        rts
VBKSP_DEC:
        dec  VCOL
        rts

VSCROLL:
        lda  #<(VMBASE + VWIDTH*8)
        sta  VPTR
        lda  #>(VMBASE + VWIDTH*8)
        sta  VPTR1

        lda  #<VMBASE
        sta  VDST
        lda  #>VMBASE
        sta  VDST1

        ldx  #30
        ldy  #0
VSCR1:
        lda  (VPTR),y
        sta  (VDST),y
        iny
        bne  VSCR1
        inc  VPTR1
        inc  VDST1
        dex
        bne  VSCR1

        lda  #0
        ldy  #0
VSCR2:  sta  (VDST),y
        iny
        bne  VSCR2
        inc  VDST1
VSCR3:  sta  (VDST),y
        iny
        cpy  #64
        bne  VSCR3
        rts

VROWTBL:
        .byte $00,$C0
        .byte $40,$C1
        .byte $80,$C2
        .byte $C0,$C3
        .byte $00,$C5
        .byte $40,$C6
        .byte $80,$C7
        .byte $C0,$C8
        .byte $00,$CA
        .byte $40,$CB
        .byte $80,$CC
        .byte $C0,$CD
        .byte $00,$CF
        .byte $40,$D0
        .byte $80,$D1
        .byte $C0,$D2
        .byte $00,$D4
        .byte $40,$D5
        .byte $80,$D6
        .byte $C0,$D7
        .byte $00,$D9
        .byte $40,$DA
        .byte $80,$DB
        .byte $C0,$DC
        .byte $00,$DE

VFONT:
        .byte $00,$00,$00,$00,$00,$00,$00,$00
        .byte $18,$18,$18,$18,$18,$00,$18,$00
        .byte $6C,$6C,$24,$00,$00,$00,$00,$00
        .byte $36,$36,$7F,$36,$7F,$36,$36,$00
        .byte $18,$3E,$60,$3C,$06,$7C,$18,$00
        .byte $61,$62,$04,$0C,$10,$26,$43,$00
        .byte $38,$6C,$6C,$38,$6D,$66,$3B,$00
        .byte $18,$18,$30,$00,$00,$00,$00,$00
        .byte $0C,$18,$30,$30,$30,$18,$0C,$00
        .byte $30,$18,$0C,$0C,$0C,$18,$30,$00
        .byte $00,$66,$3C,$FF,$3C,$66,$00,$00
        .byte $00,$18,$18,$7E,$18,$18,$00,$00
        .byte $00,$00,$00,$00,$00,$18,$18,$30
        .byte $00,$00,$00,$3C,$00,$00,$00,$00
        .byte $00,$00,$00,$00,$00,$18,$18,$00
        .byte $00,$03,$06,$0C,$18,$30,$60,$00
        .byte $3C,$66,$6E,$76,$66,$66,$3C,$00
        .byte $18,$38,$18,$18,$18,$18,$7E,$00
        .byte $3C,$66,$06,$0C,$18,$30,$7E,$00
        .byte $3C,$66,$06,$1C,$06,$66,$3C,$00
        .byte $06,$0E,$1E,$66,$7F,$06,$06,$00
        .byte $7E,$60,$7C,$06,$06,$66,$3C,$00
        .byte $1C,$30,$60,$7C,$66,$66,$3C,$00
        .byte $7E,$66,$0C,$18,$18,$18,$18,$00
        .byte $3C,$66,$66,$3C,$66,$66,$3C,$00
        .byte $3C,$66,$66,$3E,$06,$0C,$38,$00
        .byte $00,$18,$18,$00,$18,$18,$00,$00
        .byte $00,$18,$18,$00,$18,$18,$30,$00
        .byte $06,$0C,$18,$30,$18,$0C,$06,$00
        .byte $00,$00,$3C,$00,$3C,$00,$00,$00
        .byte $60,$30,$18,$0C,$18,$30,$60,$00
        .byte $3C,$66,$06,$0C,$18,$00,$18,$00
        .byte $3E,$63,$6F,$69,$6F,$60,$3E,$00
        .byte $18,$3C,$66,$7E,$66,$66,$66,$00
        .byte $7C,$66,$66,$7C,$66,$66,$7C,$00
        .byte $3C,$66,$60,$60,$60,$66,$3C,$00
        .byte $78,$6C,$66,$66,$66,$6C,$78,$00
        .byte $7E,$60,$60,$78,$60,$60,$7E,$00
        .byte $7E,$60,$60,$78,$60,$60,$60,$00
        .byte $3C,$66,$60,$6E,$66,$66,$3C,$00
        .byte $66,$66,$66,$7E,$66,$66,$66,$00
        .byte $3C,$18,$18,$18,$18,$18,$3C,$00
        .byte $1E,$0C,$0C,$0C,$0C,$6C,$38,$00
        .byte $66,$6C,$78,$70,$78,$6C,$66,$00
        .byte $60,$60,$60,$60,$60,$60,$7E,$00
        .byte $63,$77,$7F,$6B,$63,$63,$63,$00
        .byte $66,$76,$7E,$7E,$6E,$66,$66,$00
        .byte $3C,$66,$66,$66,$66,$66,$3C,$00
        .byte $7C,$66,$66,$7C,$60,$60,$60,$00
        .byte $3C,$66,$66,$66,$76,$3C,$06,$00
        .byte $7C,$66,$66,$7C,$6C,$66,$63,$00
        .byte $3C,$66,$60,$3C,$06,$66,$3C,$00
        .byte $7E,$18,$18,$18,$18,$18,$18,$00
        .byte $66,$66,$66,$66,$66,$66,$3C,$00
        .byte $66,$66,$66,$66,$66,$3C,$18,$00
        .byte $63,$63,$63,$6B,$7F,$77,$63,$00
        .byte $66,$66,$3C,$18,$3C,$66,$66,$00
        .byte $66,$66,$66,$3C,$18,$18,$18,$00
        .byte $7E,$06,$0C,$18,$30,$60,$7E,$00
        .byte $3C,$30,$30,$30,$30,$30,$3C,$00
        .byte $00,$60,$30,$18,$0C,$06,$00,$00
        .byte $3C,$0C,$0C,$0C,$0C,$0C,$3C,$00
        .byte $08,$1C,$36,$63,$00,$00,$00,$00
        .byte $00,$00,$00,$00,$00,$00,$00,$FF
