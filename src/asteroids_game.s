; Minimal playable Asteroids for KIM-1 + K-1008 + NES controller
; ---------------------------------------------------------------
; Render model:
;   - 40x25 text grid on the K-1008 via voutch
;   - row 0 = HUD
;   - rows 1-24 = playfield
;
; Controls:
;   - Left / Right: rotate ship
;   - A: move one cell forward
;   - B: fire
;   - Start: begin game from attract/demo

                .setcpu "6502"

STATE_ATTRACT   = $00
STATE_DEMO      = $01
STATE_PLAY      = $02

FRAMES_PER_SEC  = 60
ATTRACT_SECONDS = 15
ATTRACT_FRAMES  = FRAMES_PER_SEC * ATTRACT_SECONDS

PLAY_MIN_Y      = 1
PLAY_MAX_Y      = 24
PLAY_WIDTH      = 40

NUM_ASTEROIDS   = 4
NUM_BULLETS     = 4
SHIP_START_X    = 20
SHIP_START_Y    = 12
INVALID_POS     = $FF

DIR_UP          = $00
DIR_RIGHT       = $01
DIR_DOWN        = $02
DIR_LEFT        = $03

                .segment "ZEROPAGE"
GAME_STATE:      .res 1
STATE_DIRTY:     .res 1
ATTRACT_LO:      .res 1
ATTRACT_HI:      .res 1
PRINT_INDEX:     .res 1
STR_PTR_LO:      .res 1
STR_PTR_HI:      .res 1
ROW_INDEX:       .res 1
COL_INDEX:       .res 1
CHAR_TEMP:       .res 1
ENTITY_INDEX:    .res 1
SCORE_TENS:      .res 1
RAND_SEED:       .res 1

                .segment "BSS"
SHIP_X:          .res 1
SHIP_Y:          .res 1
SHIP_DIR:        .res 1
SHIP_COOLDOWN:   .res 1
LIVES:           .res 1
SCORE:           .res 1
DEMO_STEP:       .res 1
FULL_REDRAW:     .res 1
PREV_SCORE:      .res 1
PREV_LIVES:      .res 1
PREV_MODE:       .res 1
PREV_SHIP_X:     .res 1
PREV_SHIP_Y:     .res 1
PREV_SHIP_DIR:   .res 1

AST_X:           .res NUM_ASTEROIDS
AST_Y:           .res NUM_ASTEROIDS
AST_DX:          .res NUM_ASTEROIDS
AST_DY:          .res NUM_ASTEROIDS
PREV_AST_X:      .res NUM_ASTEROIDS
PREV_AST_Y:      .res NUM_ASTEROIDS

BULLET_X:        .res NUM_BULLETS
BULLET_Y:        .res NUM_BULLETS
BULLET_DX:       .res NUM_BULLETS
BULLET_DY:       .res NUM_BULLETS
BULLET_LIFE:     .res NUM_BULLETS
PREV_BULLET_X:   .res NUM_BULLETS
PREV_BULLET_Y:   .res NUM_BULLETS

                .segment "CODE"

RESET:
                sei
                cld
                ldx #$FF
                txs
                jmp START_MAIN

                .include "nes_controller.s"
                .include "voutch.s"

START_MAIN:
                jsr VINIT
                jsr NES_InitIO
                jsr GAME_Init

MAIN_LOOP:
                jsr WAIT_FRAME_TICK
                jsr GAME_Frame
                jmp MAIN_LOOP

GAME_Init:
                lda #$5A
                sta RAND_SEED
                lda #$00
                sta SCORE
                lda #$03
                sta LIVES
                lda #STATE_ATTRACT
                sta GAME_STATE
                lda #$01
                sta STATE_DIRTY
                lda #<ATTRACT_FRAMES
                sta ATTRACT_LO
                lda #>ATTRACT_FRAMES
                sta ATTRACT_HI
                lda #$00
                sta DEMO_STEP
                jsr INVALIDATE_RenderState
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
                jsr RENDER_ATTRACT_SCREEN
                lda #$00
                sta STATE_DIRTY
@update:
                lda NES_BUTTONS_NEW
                and #BTN_START
                beq @tick
                jsr GAME_EnterPlay
                rts
@tick:
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
                beq @run
                jsr ROUND_Reset
                lda #$00
                sta DEMO_STEP
                lda #$00
                sta STATE_DIRTY
@run:
                lda NES_BUTTONS_NEW
                and #BTN_START
                beq @demo_continue
                jsr GAME_EnterPlay
                rts
@demo_continue:
                jsr DEMO_ApplyControls
                jsr UPDATE_Ship
                jsr UPDATE_Bullets
                jsr UPDATE_Asteroids
                jsr CHECK_BulletAsteroidCollisions
                jsr CHECK_ShipAsteroidCollision
                jsr RENDER_PLAYFIELD
                rts

GAME_FramePlay:
                lda STATE_DIRTY
                beq @run
                lda #$00
                sta SCORE
                lda #$03
                sta LIVES
                jsr ROUND_Reset
                lda #$00
                sta STATE_DIRTY
@run:
                jsr UPDATE_Ship
                jsr UPDATE_Bullets
                jsr UPDATE_Asteroids
                jsr CHECK_BulletAsteroidCollisions
                jsr CHECK_ShipAsteroidCollision
                jsr RENDER_PLAYFIELD
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

ROUND_Reset:
                lda #SHIP_START_X
                sta SHIP_X
                lda #SHIP_START_Y
                sta SHIP_Y
                lda #DIR_UP
                sta SHIP_DIR
                lda #$00
                sta SHIP_COOLDOWN

                ldx #$00
@clear_bullets:
                lda #$00
                sta BULLET_LIFE,x
                inx
                cpx #NUM_BULLETS
                bne @clear_bullets

                ldx #$00
@spawn_asteroids:
                jsr RESPAWN_Asteroid
                inx
                cpx #NUM_ASTEROIDS
                bne @spawn_asteroids
                jsr INVALIDATE_RenderState
                rts

UPDATE_Ship:
                lda SHIP_COOLDOWN
                beq @turns
                dec SHIP_COOLDOWN
@turns:
                lda GAME_STATE
                cmp #STATE_PLAY
                beq @player_controls
                rts
@player_controls:
                lda NES_BUTTONS_CUR
                and #BTN_LEFT
                beq @check_right
                lda SHIP_DIR
                beq @wrap_left
                dec SHIP_DIR
                jmp @check_right
@wrap_left:
                lda #DIR_LEFT
                sta SHIP_DIR
@check_right:
                lda NES_BUTTONS_CUR
                and #BTN_RIGHT
                beq @check_thrust
                lda SHIP_DIR
                cmp #DIR_LEFT
                beq @wrap_right
                inc SHIP_DIR
                jmp @check_thrust
@wrap_right:
                lda #DIR_UP
                sta SHIP_DIR
@check_thrust:
                lda NES_BUTTONS_CUR
                and #BTN_A
                beq @check_fire
                jsr MOVE_ShipForward
@check_fire:
                lda NES_BUTTONS_NEW
                and #BTN_B
                beq @done
                lda SHIP_COOLDOWN
                bne @done
                jsr SPAWN_Bullet
                lda #$04
                sta SHIP_COOLDOWN
@done:
                rts

DEMO_ApplyControls:
                inc DEMO_STEP
                lda DEMO_STEP
                and #$07
                bne @maybe_thrust
                lda SHIP_DIR
                cmp #DIR_LEFT
                beq @demo_wrap
                inc SHIP_DIR
                jmp @maybe_thrust
@demo_wrap:
                lda #DIR_UP
                sta SHIP_DIR
@maybe_thrust:
                lda DEMO_STEP
                and #$01
                beq @maybe_fire
                jsr MOVE_ShipForward
@maybe_fire:
                lda DEMO_STEP
                and #$0F
                bne @done
                lda SHIP_COOLDOWN
                bne @done
                jsr SPAWN_Bullet
                lda #$06
                sta SHIP_COOLDOWN
@done:
                lda SHIP_COOLDOWN
                beq @finish
                dec SHIP_COOLDOWN
@finish:
                rts

MOVE_ShipForward:
                ldx SHIP_DIR
                lda SHIP_X
                clc
                adc SHIP_DX_TABLE,x
                jsr WRAP_X
                sta SHIP_X
                lda SHIP_Y
                clc
                adc SHIP_DY_TABLE,x
                jsr WRAP_Y
                sta SHIP_Y
                rts

SPAWN_Bullet:
                ldx #$00
@find_slot:
                lda BULLET_LIFE,x
                beq @spawn_here
                inx
                cpx #NUM_BULLETS
                bne @find_slot
                rts
@spawn_here:
                lda SHIP_X
                sta BULLET_X,x
                lda SHIP_Y
                sta BULLET_Y,x
                ldy SHIP_DIR
                lda SHIP_DX_TABLE,y
                sta BULLET_DX,x
                lda SHIP_DY_TABLE,y
                sta BULLET_DY,x
                lda #$10
                sta BULLET_LIFE,x
                rts

UPDATE_Bullets:
                ldx #$00
@loop:
                lda BULLET_LIFE,x
                beq @next
                dec BULLET_LIFE,x
                lda BULLET_LIFE,x
                beq @next
                lda BULLET_X,x
                clc
                adc BULLET_DX,x
                jsr WRAP_X
                sta BULLET_X,x
                lda BULLET_Y,x
                clc
                adc BULLET_DY,x
                jsr WRAP_Y
                sta BULLET_Y,x
@next:
                inx
                cpx #NUM_BULLETS
                bne @loop
                rts

UPDATE_Asteroids:
                ldx #$00
@loop:
                lda AST_X,x
                clc
                adc AST_DX,x
                jsr WRAP_X
                sta AST_X,x
                lda AST_Y,x
                clc
                adc AST_DY,x
                jsr WRAP_Y
                sta AST_Y,x
                inx
                cpx #NUM_ASTEROIDS
                bne @loop
                rts

CHECK_BulletAsteroidCollisions:
                ldx #$00
@bullet_loop:
                lda BULLET_LIFE,x
                beq @next_bullet
                stx ENTITY_INDEX
                ldy #$00
@asteroid_loop:
                lda BULLET_X,x
                cmp AST_X,y
                bne @next_asteroid
                lda BULLET_Y,x
                cmp AST_Y,y
                bne @next_asteroid
                lda #$00
                sta BULLET_LIFE,x
                tya
                tax
                jsr RESPAWN_Asteroid
                ldx ENTITY_INDEX
                inc SCORE
                jmp @next_bullet
@next_asteroid:
                iny
                cpy #NUM_ASTEROIDS
                bne @asteroid_loop
                ldx ENTITY_INDEX
@next_bullet:
                inx
                cpx #NUM_BULLETS
                bne @bullet_loop
                rts

CHECK_ShipAsteroidCollision:
                ldx #$00
@loop:
                lda SHIP_X
                cmp AST_X,x
                bne @next
                lda SHIP_Y
                cmp AST_Y,x
                bne @next
                lda LIVES
                beq @game_over
                dec LIVES
                lda LIVES
                beq @game_over
                jsr ROUND_Reset
                rts
@game_over:
                jsr GAME_ResetToAttract
                rts
@next:
                inx
                cpx #NUM_ASTEROIDS
                bne @loop
                rts

GAME_ResetToAttract:
                lda #STATE_ATTRACT
                sta GAME_STATE
                lda #$01
                sta STATE_DIRTY
                lda #<ATTRACT_FRAMES
                sta ATTRACT_LO
                lda #>ATTRACT_FRAMES
                sta ATTRACT_HI
                lda #$03
                sta LIVES
                lda #$00
                sta SCORE
                jsr INVALIDATE_RenderState
                rts

RESPAWN_Asteroid:
@retry:
                jsr NEXT_RANDOM
                and #$1F
                clc
                adc #$04
                cmp #PLAY_WIDTH
                bcc @store_x
                sbc #PLAY_WIDTH
@store_x:
                sta AST_X,x
                jsr NEXT_RANDOM
                and #$0F
                clc
                adc #$08
                cmp #25
                bcc @store_y
                lda #PLAY_MAX_Y
@store_y:
                sta AST_Y,x
                ; Keep new asteroids away from the ship spawn/current ship area
                lda AST_X,x
                sec
                sbc SHIP_X
                cmp #$FB
                bcc @retry
                cmp #$06
                bcc @retry_y_check
                jmp @pick_motion
@retry_y_check:
                lda AST_Y,x
                sec
                sbc SHIP_Y
                cmp #$FB
                bcc @retry
                cmp #$06
                bcc @retry
@pick_motion:
                jsr NEXT_RANDOM
                and #$03
                tay
                lda ASTEROID_DX_TABLE,y
                sta AST_DX,x
                lda ASTEROID_DY_TABLE,y
                sta AST_DY,x
                rts

NEXT_RANDOM:
                lda RAND_SEED
                bne @step
                lda #$5A
@step:
                asl a
                bcc @done
                eor #$1D
@done:
                sta RAND_SEED
                rts

RENDER_ATTRACT_SCREEN:
                jsr VINIT
                lda #5
                sta VROW
                lda #9
                sta VCOL
                lda #<MSG_ASTEROIDS
                sta STR_PTR_LO
                lda #>MSG_ASTEROIDS
                sta STR_PTR_HI
                jsr PRINT_STRING

                lda #9
                sta VROW
                lda #10
                sta VCOL
                lda #<MSG_PRESS_START
                sta STR_PTR_LO
                lda #>MSG_PRESS_START
                sta STR_PTR_HI
                jsr PRINT_STRING

                lda #13
                sta VROW
                lda #8
                sta VCOL
                lda #<MSG_CONTROLS
                sta STR_PTR_LO
                lda #>MSG_CONTROLS
                sta STR_PTR_HI
                jsr PRINT_STRING
                rts

RENDER_PLAYFIELD:
                lda FULL_REDRAW
                beq @incremental
                jsr VCLR
                jsr RENDER_HUD
                jsr REDRAW_AllEntities
                jsr SNAPSHOT_RenderState
                lda #$00
                sta FULL_REDRAW
                rts
@incremental:
                jsr UPDATE_HUD_IF_NEEDED
                jsr REDRAW_PreviousEntities
                jsr REDRAW_AllEntities
                jsr SNAPSHOT_RenderState
                rts

RENDER_HUD:
                lda #$00
                sta VROW
                lda #$00
                sta VCOL
                lda #<MSG_SCORE
                sta STR_PTR_LO
                lda #>MSG_SCORE
                sta STR_PTR_HI
                jsr PRINT_STRING
                lda SCORE
                jsr PRINT_TWO_DIGITS

                lda #' '
                jsr VOUTCH
                lda #'L'
                jsr VOUTCH
                lda #' '
                jsr VOUTCH
                lda LIVES
                clc
                adc #'0'
                jsr VOUTCH

                lda #' '
                jsr VOUTCH
                lda GAME_STATE
                cmp #STATE_DEMO
                bne @play_label
                lda #<MSG_DEMO
                sta STR_PTR_LO
                lda #>MSG_DEMO
                sta STR_PTR_HI
                jsr PRINT_STRING
                lda SCORE
                sta PREV_SCORE
                lda LIVES
                sta PREV_LIVES
                lda GAME_STATE
                sta PREV_MODE
                rts
@play_label:
                lda #<MSG_PLAY
                sta STR_PTR_LO
                lda #>MSG_PLAY
                sta STR_PTR_HI
                jsr PRINT_STRING
                lda SCORE
                sta PREV_SCORE
                lda LIVES
                sta PREV_LIVES
                lda GAME_STATE
                sta PREV_MODE
                rts

UPDATE_HUD_IF_NEEDED:
                lda SCORE
                cmp PREV_SCORE
                bne @redraw
                lda LIVES
                cmp PREV_LIVES
                bne @redraw
                lda GAME_STATE
                cmp PREV_MODE
                beq @done
@redraw:
                jsr RENDER_HUD
@done:
                rts

REDRAW_PreviousEntities:
                lda PREV_SHIP_Y
                cmp #INVALID_POS
                beq @bullets
                lda PREV_SHIP_X
                ldx PREV_SHIP_Y
                jsr DRAW_CellAt
@bullets:
                ldx #$00
@bullet_loop:
                lda PREV_BULLET_Y,x
                cmp #INVALID_POS
                beq @next_bullet
                stx ENTITY_INDEX
                lda PREV_BULLET_X,x
                lda PREV_BULLET_Y,x
                tax
                jsr DRAW_CellAt
                ldx ENTITY_INDEX
@next_bullet:
                inx
                cpx #NUM_BULLETS
                bne @bullet_loop

                ldx #$00
@asteroid_loop:
                lda PREV_AST_Y,x
                cmp #INVALID_POS
                beq @next_asteroid
                stx ENTITY_INDEX
                lda PREV_AST_X,x
                lda PREV_AST_Y,x
                tax
                jsr DRAW_CellAt
                ldx ENTITY_INDEX
@next_asteroid:
                inx
                cpx #NUM_ASTEROIDS
                bne @asteroid_loop
                rts

REDRAW_AllEntities:
                lda SHIP_X
                ldx SHIP_Y
                jsr DRAW_CellAt

                ldx #$00
@bullet_loop:
                lda BULLET_LIFE,x
                beq @next_bullet
                stx ENTITY_INDEX
                lda BULLET_X,x
                lda BULLET_Y,x
                tax
                jsr DRAW_CellAt
                ldx ENTITY_INDEX
@next_bullet:
                inx
                cpx #NUM_BULLETS
                bne @bullet_loop

                ldx #$00
@asteroid_loop:
                stx ENTITY_INDEX
                lda AST_X,x
                lda AST_Y,x
                tax
                jsr DRAW_CellAt
                ldx ENTITY_INDEX
                inx
                cpx #NUM_ASTEROIDS
                bne @asteroid_loop
                rts

DRAW_CellAt:
                sta COL_INDEX
                stx ROW_INDEX
                stx VROW
                lda COL_INDEX
                sta VCOL
                jsr GET_CELL_CHAR
                jsr VOUTCH
                rts

SNAPSHOT_RenderState:
                lda SHIP_X
                sta PREV_SHIP_X
                lda SHIP_Y
                sta PREV_SHIP_Y
                lda SHIP_DIR
                sta PREV_SHIP_DIR

                ldx #$00
@bullet_loop:
                lda BULLET_LIFE,x
                beq @clear_bullet
                lda BULLET_X,x
                sta PREV_BULLET_X,x
                lda BULLET_Y,x
                sta PREV_BULLET_Y,x
                jmp @next_bullet
@clear_bullet:
                lda #INVALID_POS
                sta PREV_BULLET_X,x
                sta PREV_BULLET_Y,x
@next_bullet:
                inx
                cpx #NUM_BULLETS
                bne @bullet_loop

                ldx #$00
@asteroid_loop:
                lda AST_X,x
                sta PREV_AST_X,x
                lda AST_Y,x
                sta PREV_AST_Y,x
                inx
                cpx #NUM_ASTEROIDS
                bne @asteroid_loop
                rts

INVALIDATE_RenderState:
                lda #$01
                sta FULL_REDRAW
                lda #INVALID_POS
                sta PREV_SHIP_X
                sta PREV_SHIP_Y
                sta PREV_SHIP_DIR
                sta PREV_SCORE
                sta PREV_LIVES
                sta PREV_MODE

                ldx #$00
@bullet_loop:
                sta PREV_BULLET_X,x
                sta PREV_BULLET_Y,x
                inx
                cpx #NUM_BULLETS
                bne @bullet_loop

                ldx #$00
@asteroid_loop:
                sta PREV_AST_X,x
                sta PREV_AST_Y,x
                inx
                cpx #NUM_ASTEROIDS
                bne @asteroid_loop
                rts

GET_CELL_CHAR:
                lda COL_INDEX
                cmp SHIP_X
                bne @check_bullets
                lda ROW_INDEX
                cmp SHIP_Y
                bne @check_bullets
                ldx SHIP_DIR
                lda SHIP_CHAR_TABLE,x
                rts

@check_bullets:
                ldx #$00
@bullet_loop:
                lda BULLET_LIFE,x
                beq @next_bullet
                lda COL_INDEX
                cmp BULLET_X,x
                bne @next_bullet
                lda ROW_INDEX
                cmp BULLET_Y,x
                bne @next_bullet
                lda #'*'
                rts
@next_bullet:
                inx
                cpx #NUM_BULLETS
                bne @bullet_loop

                ldx #$00
@asteroid_loop:
                lda COL_INDEX
                cmp AST_X,x
                bne @next_asteroid
                lda ROW_INDEX
                cmp AST_Y,x
                bne @next_asteroid
                lda #'%'
                rts
@next_asteroid:
                inx
                cpx #NUM_ASTEROIDS
                bne @asteroid_loop

                lda #' '
                rts

PRINT_STRING:
                ldy #$00
@loop:
                lda (STR_PTR_LO),y
                beq @done
                sty PRINT_INDEX
                jsr VOUTCH
                ldy PRINT_INDEX
                iny
                bne @loop
@done:
                rts

PRINT_TWO_DIGITS:
                pha
                lda #$00
                sta SCORE_TENS
                pla
@tens_loop:
                cmp #10
                bcc @ones
                sec
                sbc #10
                inc SCORE_TENS
                bne @tens_loop
@ones:
                sta CHAR_TEMP
                lda SCORE_TENS
                clc
                adc #'0'
                jsr VOUTCH
                lda CHAR_TEMP
                clc
                adc #'0'
                jsr VOUTCH
                rts

WRAP_X:
                cmp #$FF
                bne @check_high
                lda #PLAY_WIDTH-1
                rts
@check_high:
                cmp #PLAY_WIDTH
                bcc @done
                lda #$00
@done:
                rts

WRAP_Y:
                cmp #$00
                bne @check_high
                lda #PLAY_MAX_Y
                rts
@check_high:
                cmp #PLAY_MAX_Y+1
                bcc @done
                lda #PLAY_MIN_Y
@done:
                rts

WAIT_FRAME_TICK:
                ldx #$60
@d1:            ldy #$FF
@d2:            dey
                bne @d2
                dex
                bne @d1
                rts

SHIP_DX_TABLE:
                .byte $00,$01,$00,$FF
SHIP_DY_TABLE:
                .byte $FF,$00,$01,$00
SHIP_CHAR_TABLE:
                .byte '!','"','#','$'

ASTEROID_DX_TABLE:
                .byte $01,$FF,$00,$00
ASTEROID_DY_TABLE:
                .byte $00,$00,$01,$FF

MSG_ASTEROIDS:
                .asciiz "ASTEROIDS"
MSG_PRESS_START:
                .asciiz "PRESS START TO PLAY"
MSG_CONTROLS:
                .asciiz "A THRUST  B FIRE  LR TURN"
MSG_SCORE:
                .asciiz "S "
MSG_PLAY:
                .asciiz " PLAY"
MSG_DEMO:
                .asciiz " DEMO"
