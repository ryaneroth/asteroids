# KIM-1 Asteroids Starter

This repository now contains a starting point for building an **Asteroids-style game on the KIM-1** using:

- A NES controller (8-button serial interface through the internal 4021 shift register)
- The same KIM-1 video output strategy used in [`kimlife`](https://github.com/ryaneroth/kimlife)
- 6502 assembly routines intended to be dropped into your game loop

## What is included

- `docs/nes-controller-kim1.md`
  - Wiring guide from NES controller to KIM-1 I/O
  - Signal timing and protocol notes
  - Pin assignment recommendations
- `src/nes_controller.s`
  - Reusable 6502 routines to read all 8 NES controller buttons
  - Zero-page state bytes and bit definitions
- `docs/asteroids-game-flow.md`
  - State-machine overview for attract/demo/play
  - Frame-based timeout guidance and renderer integration notes
- `examples/read_controller_demo.s`
  - Minimal polling loop showing how to call the controller routine
  - Example mapping to game-style controls (`rotate`, `thrust`, `fire`, etc.)
- `src/asteroids_game.s`
  - Initial game scaffold with `ATTRACT`, `DEMO`, and `PLAY` states
  - Attract message (`PRESS START TO PLAY`) and ~15 second timeout to demo mode


## Building

This repo now includes a `Makefile` for cc65 toolchains:

```sh
make
```

Build outputs:

- `build/asteroids_game.bin`
- `build/read_controller_demo.bin`

Requirements:

- `ca65`
- `ld65`

If either tool is missing, `make` now fails fast with a clear error message.

If your KIM-1 memory map differs, adjust `kim1.cfg` and the I/O constants in `src/nes_controller.s`.

## Quick start

1. Wire the controller as documented in `docs/nes-controller-kim1.md`.
2. Copy `src/nes_controller.s` into your game build.
3. Call `NES_ReadButtons` once per frame (or once per game tick).
4. Read button bits from `NES_BUTTONS_CUR`.
5. Optionally use `NES_BUTTONS_NEW` for edge-triggered actions (newly pressed this frame).

## Notes about addresses and hardware variants

KIM-1 clones and expansions may map RIOT/VIA ports differently. This code provides constants near the top of each assembly file to make remapping simple. Verify your exact memory map and update these symbols as needed.

## Next steps toward Asteroids

- Tie `NES_BUTTONS_CUR` to your ship controls:
  - Left/Right: rotation
  - A: thrust
  - B: fire
  - Start: pause
- Keep rendering/video timing in your existing kimlife-style frame loop.
- Use `NES_BUTTONS_NEW` for single-shot actions like spawning bullets or toggling menus.


## Current game scaffold behavior

- On boot, game enters **ATTRACT** and displays `PRESS START TO PLAY`.
- If Start is not pressed for about 15 seconds (frame-based timer), it transitions to **DEMO**.
- Pressing Start in **ATTRACT** or **DEMO** transitions to **PLAY**.
- Output is currently shown through KIM monitor `OUTCH` so you can verify flow before wiring text into your kimlife renderer.
