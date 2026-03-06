; Minimal NES controller polling demo for KIM-1
; -------------------------------------------
; This example focuses on input only. Integrate into your own
; kimlife-derived frame loop and rendering path.

                .setcpu "6502"

                .include "../src/nes_controller.s"

; Optional game-control state bytes
                .segment "ZEROPAGE"
ROTATE_DIR:      .res 1      ; $FF left, $01 right, $00 none
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
