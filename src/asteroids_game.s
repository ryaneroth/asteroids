; Asteroids game scaffold for KIM-1 + NES controller
; --------------------------------------------------
; This is a starting point for the game state machine:
;   - ATTRACT mode prints "PRESS START TO PLAY"
;   - After ~15 seconds (frame-based), transitions to DEMO mode
;   - Pressing START from ATTRACT/DEMO enters PLAY mode
;
; Video integration note:
;   Output uses the same voutch/K-1008 path as kimlife, with video RAM
;   mapped at $C000-$DFFF.

                .setcpu "6502"

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
PRINT_INDEX:     .res 1

                .segment "CODE"

RESET:
                sei
                cld
                ldx #$FF
                txs
                jsr VINIT
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
; Output helpers
; ---------------------------------------------------
PRINT_ATTRACT_SCREEN:
                jsr PRINT_CRLF
                ldx #$00
@loop_a:
                lda MSG_PRESS_START,x
                beq @done_a
                stx PRINT_INDEX
                jsr VOUTCH
                ldx PRINT_INDEX
                inx
                bne @loop_a
@done_a:
                rts

PRINT_DEMO_SCREEN:
                jsr PRINT_CRLF
                ldx #$00
@loop_d:
                lda MSG_DEMO_MODE,x
                beq @done_d
                stx PRINT_INDEX
                jsr VOUTCH
                ldx PRINT_INDEX
                inx
                bne @loop_d
@done_d:
                rts

PRINT_PLAY_SCREEN:
                jsr PRINT_CRLF
                ldx #$00
@loop_p:
                lda MSG_PLAY_MODE,x
                beq @done_p
                stx PRINT_INDEX
                jsr VOUTCH
                ldx PRINT_INDEX
                inx
                bne @loop_p
@done_p:
                rts

PRINT_CRLF:
                lda #$0D
                jsr VOUTCH
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

                .include "nes_controller.s"
                .include "voutch.s"
