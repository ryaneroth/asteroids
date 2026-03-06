; Asteroids game scaffold for KIM-1 + NES controller
; --------------------------------------------------
; This is a starting point for the game state machine:
;   - ATTRACT mode prints "PRESS START TO PLAY"
;   - After ~15 seconds (frame-based), transitions to DEMO mode
;   - Pressing START from ATTRACT/DEMO enters PLAY mode
;
; Video integration note:
;   This scaffold currently uses OUTCH for visible feedback. Replace
;   the PRINT_* routines with your kimlife-style video text drawing.

                .setcpu "6502"

                .include "nes_controller.s"

OUTCH           = $1EA0

STATE_ATTRACT   = $00
STATE_DEMO      = $01
STATE_PLAY      = $02

FRAMES_PER_SEC  = 60
ATTRACT_SECONDS = 15
ATTRACT_FRAMES  = FRAMES_PER_SEC * ATTRACT_SECONDS ; 900 = $0384

                .segment "ZEROPAGE"
GAME_STATE:      .res 1
STATE_DIRTY:     .res 1
ATTRACT_LO:      .res 1
ATTRACT_HI:      .res 1

                .segment "CODE"

RESET:
                sei
                cld
                jsr NES_InitIO
                jsr GAME_Init

MAIN_LOOP:
                jsr WAIT_FRAME_TICK
                jsr GAME_Frame
                jmp MAIN_LOOP

GAME_Init:
                lda #STATE_ATTRACT
                sta GAME_STATE
                lda #$01
                sta STATE_DIRTY

                lda #<ATTRACT_FRAMES
                sta ATTRACT_LO
                lda #>ATTRACT_FRAMES
                sta ATTRACT_HI
                rts

GAME_Frame:
                jsr NES_ReadButtons

                lda GAME_STATE
                cmp #STATE_ATTRACT
                beq GAME_FrameAttract
                cmp #STATE_DEMO
                beq GAME_FrameDemo
                jmp GAME_FramePlay

GAME_FrameAttract:
                lda STATE_DIRTY
                beq @update
                jsr PRINT_ATTRACT_SCREEN
                lda #$00
                sta STATE_DIRTY

@update:
                ; START edge immediately enters play
                lda NES_BUTTONS_NEW
                and #BTN_START
                beq @tick
                jsr GAME_EnterPlay
                rts

@tick:
                ; 16-bit countdown: after ~15 seconds enter demo
                lda ATTRACT_LO
                bne @dec_low
                lda ATTRACT_HI
                beq @timeout
                dec ATTRACT_HI
@dec_low:
                dec ATTRACT_LO
                rts

@timeout:
                jsr GAME_EnterDemo
                rts

GAME_FrameDemo:
                lda STATE_DIRTY
                beq @check_start
                jsr PRINT_DEMO_SCREEN
                lda #$00
                sta STATE_DIRTY

@check_start:
                lda NES_BUTTONS_NEW
                and #BTN_START
                beq @demo_run
                jsr GAME_EnterPlay
                rts

@demo_run:
                ; TODO: insert AI-driven demo gameplay here.
                rts

GAME_FramePlay:
                lda STATE_DIRTY
                beq @play_run
                jsr PRINT_PLAY_SCREEN
                lda #$00
                sta STATE_DIRTY

@play_run:
                ; TODO: update asteroids, ship, bullets, collisions, render.
                rts

GAME_EnterDemo:
                lda #STATE_DEMO
                sta GAME_STATE
                lda #$01
                sta STATE_DIRTY
                rts

GAME_EnterPlay:
                lda #STATE_PLAY
                sta GAME_STATE
                lda #$01
                sta STATE_DIRTY
                rts

; ---------------------------------------------------
; Output helpers (temporary)
; ---------------------------------------------------
PRINT_ATTRACT_SCREEN:
                jsr PRINT_CRLF
                ldx #$00
@loop_a:
                lda MSG_PRESS_START,x
                beq @done_a
                jsr OUTCH
                inx
                bne @loop_a
@done_a:
                jsr PRINT_CRLF
                rts

PRINT_DEMO_SCREEN:
                jsr PRINT_CRLF
                ldx #$00
@loop_d:
                lda MSG_DEMO_MODE,x
                beq @done_d
                jsr OUTCH
                inx
                bne @loop_d
@done_d:
                jsr PRINT_CRLF
                rts

PRINT_PLAY_SCREEN:
                jsr PRINT_CRLF
                ldx #$00
@loop_p:
                lda MSG_PLAY_MODE,x
                beq @done_p
                jsr OUTCH
                inx
                bne @loop_p
@done_p:
                jsr PRINT_CRLF
                rts

PRINT_CRLF:
                lda #$0D
                jsr OUTCH
                lda #$0A
                jsr OUTCH
                rts

; Replace with your frame pacing / vsync control.
WAIT_FRAME_TICK:
                ldx #$FF
@d1:            ldy #$FF
@d2:            dey
                bne @d2
                dex
                bne @d1
                rts

MSG_PRESS_START:
                .asciiz "PRESS START TO PLAY"
MSG_DEMO_MODE:
                .asciiz "DEMO MODE"
MSG_PLAY_MODE:
                .asciiz "PLAY MODE"
