; NES controller driver for KIM-1-style 6502 systems
; ---------------------------------------------------
; Assumes one output port for LATCH/CLOCK and one input bit for DATA.
; Adjust register addresses and bit masks for your hardware.
;
; Public routines:
;   NES_InitIO
;   NES_ReadButtons
;
; Public data:
;   NES_BUTTONS_CUR   ; buttons currently held (pressed=1)
;   NES_BUTTONS_PREV  ; previous sample
;   NES_BUTTONS_NEW   ; newly pressed this sample
;
; Bit order and masks after read normalization:
;   bit0 A, bit1 B, bit2 Select, bit3 Start,
;   bit4 Up, bit5 Down, bit6 Left, bit7 Right

                .setcpu "6502"

; ---------------------------------------------------
; Hardware mapping (update as needed)
; ---------------------------------------------------
PORTA_DATA      = $1740
PORTA_DDR       = $1741
PORTB_DATA      = $1742
PORTB_DDR       = $1743

NES_LATCH_BIT   = %00000001   ; PB0 output
NES_CLOCK_BIT   = %00000010   ; PB1 output
NES_DATA_BIT    = %00000001   ; PA0 input

; ---------------------------------------------------
; Zero-page / state bytes
; ---------------------------------------------------
                .segment "ZEROPAGE"
NES_BUTTONS_CUR: .res 1
NES_BUTTONS_PREV:.res 1
NES_BUTTONS_NEW: .res 1
NES_TMP:         .res 1
NES_COUNT:       .res 1

; ---------------------------------------------------
; Code
; ---------------------------------------------------
                .segment "CODE"

; Configure pin directions.
; PB0/PB1 outputs for latch/clock; PA0 input for data.
NES_InitIO:
                lda PORTB_DDR
                ora #NES_LATCH_BIT | NES_CLOCK_BIT
                sta PORTB_DDR

                lda PORTA_DDR
                and #($FF ^ NES_DATA_BIT)
                sta PORTA_DDR

                ; Default low on latch and clock
                lda PORTB_DATA
                and #($FF ^ (NES_LATCH_BIT | NES_CLOCK_BIT))
                sta PORTB_DATA
                rts

; Read all 8 controller bits (pressed=1), and compute new presses.
NES_ReadButtons:
                ; Save previous state
                lda NES_BUTTONS_CUR
                sta NES_BUTTONS_PREV

                ; Pulse latch high then low
                jsr NES_LatchPulse

                lda #$00
                sta NES_TMP
                lda #$08
                sta NES_COUNT

@read_loop:
                ; Read data bit (active-low from controller)
                lda PORTA_DATA
                and #NES_DATA_BIT
                beq @pressed
@released:
                ; released -> keep bit cleared
                jmp @shift_next

@pressed:
                ; pressed -> set bit7 before rotate-right assembly
                lda NES_TMP
                ora #$80
                sta NES_TMP

@shift_next:
                ; Clock pulse for next bit
                jsr NES_ClockPulse

                ; Rotate assembled bits right so first read ends at bit0
                lsr NES_TMP

                dec NES_COUNT
                bne @read_loop
                ; NES_TMP already stores pressed=1, released=0.
                lda NES_TMP
                sta NES_BUTTONS_CUR

                ; newly pressed = current & (~previous)
                lda NES_BUTTONS_PREV
                eor #$FF
                and NES_BUTTONS_CUR
                sta NES_BUTTONS_NEW

                rts

NES_LatchPulse:
                lda PORTB_DATA
                ora #NES_LATCH_BIT
                sta PORTB_DATA
                jsr NES_ShortDelay

                lda PORTB_DATA
                and #($FF ^ NES_LATCH_BIT)
                sta PORTB_DATA
                jsr NES_ShortDelay
                rts

NES_ClockPulse:
                lda PORTB_DATA
                ora #NES_CLOCK_BIT
                sta PORTB_DATA
                jsr NES_ShortDelay

                lda PORTB_DATA
                and #($FF ^ NES_CLOCK_BIT)
                sta PORTB_DATA
                jsr NES_ShortDelay
                rts

NES_ShortDelay:
                ldx #$08
@dly:           dex
                bne @dly
                rts

; ---------------------------------------------------
; Button masks exported for callers
; ---------------------------------------------------
BTN_A           = %00000001
BTN_B           = %00000010
BTN_SELECT      = %00000100
BTN_START       = %00001000
BTN_UP          = %00010000
BTN_DOWN        = %00100000
BTN_LEFT        = %01000000
BTN_RIGHT       = %10000000
