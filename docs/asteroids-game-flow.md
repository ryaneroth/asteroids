# Asteroids Game Flow (Scaffold)

The first playable scaffold is implemented in `src/asteroids_game.s`.

## States

- `STATE_ATTRACT`
  - Displays `PRESS START TO PLAY`
  - Runs a frame countdown timer (`15 * 60 = 900` frames)
  - Transitions to `STATE_DEMO` on timeout
  - Transitions to `STATE_PLAY` immediately on Start press edge
- `STATE_DEMO`
  - Displays `DEMO MODE`
  - Placeholder for AI/demo gameplay loop
  - Transitions to `STATE_PLAY` on Start press edge
- `STATE_PLAY`
  - Displays `PLAY MODE`
  - Placeholder for full gameplay update/render loop

## Timing

The attract timeout is frame-count based, using constants near the top of `src/asteroids_game.s`:

- `FRAMES_PER_SEC = 60`
- `ATTRACT_SECONDS = 15`
- `ATTRACT_FRAMES = 900`

If your real frame rate differs, update `FRAMES_PER_SEC`.

## Rendering integration

The scaffold currently uses `OUTCH` text output to make state transitions visible while bringing up the game logic. Replace:

- `PRINT_ATTRACT_SCREEN`
- `PRINT_DEMO_SCREEN`
- `PRINT_PLAY_SCREEN`

with your kimlife-compatible on-screen text rendering routines.
