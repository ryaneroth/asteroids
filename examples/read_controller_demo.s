; Minimal NES controller polling demo for KIM-1
; -------------------------------------------
; This example focuses on input only. Integrate into your own
; kimlife-derived frame loop and rendering path.
;
; On each newly-pressed button, this demo prints a short token via
; the KIM monitor OUTCH routine.

                .setcpu "6502"

                .include "../src/nes_controller.s"

OUTCH           = $1EA0       ; KIM-1 monitor: print ASCII character in A

; Optional game-control state bytes
                .segment "ZEROPAGE"
ROTATE_DIR:      .res 1       ; $FF left, $01 right, $00 none
THRUST_FLAG:     .res 1
FIRE_PULSE:      .res 1
PAUSE_TOGGLE:    .res 1

                .segment "CODE"

RESET:
                sei
                cld
                jsr NES_InitIO

MAIN_LOOP:
                ; Poll once per frame/tick
                jsr NES_ReadButtons

                ; Print any newly pressed buttons to terminal
                jsr PRINT_NEW_BUTTONS

                ; Rotate control
                lda #$00
                sta ROTATE_DIR

                lda NES_BUTTONS_CUR
                and #BTN_LEFT
                beq @check_right
                lda #$FF
                sta ROTATE_DIR

@check_right:
                lda NES_BUTTONS_CUR
                and #BTN_RIGHT
                beq @check_thrust
                lda #$01
                sta ROTATE_DIR

@check_thrust:
                lda #$00
                sta THRUST_FLAG
                lda NES_BUTTONS_CUR
                and #BTN_A
                beq @check_fire
                lda #$01
                sta THRUST_FLAG

@check_fire:
                ; fire only on new press
                lda #$00
                sta FIRE_PULSE
                lda NES_BUTTONS_NEW
                and #BTN_B
                beq @check_pause
                lda #$01
                sta FIRE_PULSE

@check_pause:
                ; pause toggles on Start edge
                lda NES_BUTTONS_NEW
                and #BTN_START
                beq @render

                lda PAUSE_TOGGLE
                eor #$01
                sta PAUSE_TOGGLE

@render:
                ; Insert kimlife-style video frame work here,
                ; plus asteroid update logic based on control bytes.
                jmp MAIN_LOOP

; ---------------------------------------------------
; Debug output helpers
; ---------------------------------------------------
; Prints button labels for newly-pressed bits in NES_BUTTONS_NEW.
; Output format example: "A B U\r\n"
PRINT_NEW_BUTTONS:
                lda NES_BUTTONS_NEW
                beq @done

                lda NES_BUTTONS_NEW
                and #BTN_A
                beq @check_b
                lda #'A'
                jsr OUTCH
                lda #' '
                jsr OUTCH

@check_b:
                lda NES_BUTTONS_NEW
                and #BTN_B
                beq @check_select
                lda #'B'
                jsr OUTCH
                lda #' '
                jsr OUTCH

@check_select:
                lda NES_BUTTONS_NEW
                and #BTN_SELECT
                beq @check_start
                lda #'E'           ; sElEct
                jsr OUTCH
                lda #' '
                jsr OUTCH

@check_start:
                lda NES_BUTTONS_NEW
                and #BTN_START
                beq @check_up
                lda #'T'           ; sTarT
                jsr OUTCH
                lda #' '
                jsr OUTCH

@check_up:
                lda NES_BUTTONS_NEW
                and #BTN_UP
                beq @check_down
                lda #'U'
                jsr OUTCH
                lda #' '
                jsr OUTCH

@check_down:
                lda NES_BUTTONS_NEW
                and #BTN_DOWN
                beq @check_left
                lda #'D'
                jsr OUTCH
                lda #' '
                jsr OUTCH

@check_left:
                lda NES_BUTTONS_NEW
                and #BTN_LEFT
                beq @check_right_btn
                lda #'L'
                jsr OUTCH
                lda #' '
                jsr OUTCH

@check_right_btn:
                lda NES_BUTTONS_NEW
                and #BTN_RIGHT
                beq @line_end
                lda #'R'
                jsr OUTCH
                lda #' '
                jsr OUTCH

@line_end:
                lda #$0D
                jsr OUTCH
                lda #$0A
                jsr OUTCH

@done:
                rts
