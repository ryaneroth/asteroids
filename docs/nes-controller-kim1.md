# NES Controller Interface for KIM-1

This document describes a practical way to connect an original NES-style controller to a KIM-1-compatible system.

## 1. NES controller protocol (summary)

An NES controller contains a **4021 parallel-in/serial-out shift register**.

Signals:

- `LATCH` (a.k.a. `STROBE`): pulse high to copy button states into the shift register.
- `CLOCK`: each pulse shifts the next button bit onto `DATA`.
- `DATA`: serial button output (active-low on original controllers).

Read sequence:

1. Set `LATCH=1` briefly, then `LATCH=0`.
2. Read `DATA` 8 times.
3. Before each subsequent read, pulse `CLOCK` high then low.

Bit order from the controller is typically:

1. A
2. B
3. Select
4. Start
5. Up
6. Down
7. Left
8. Right

`0` means **pressed**, `1` means **released**. The sample code normalizes this so a pressed button becomes bit = `1`.

---

## 2. Suggested KIM-1 wiring

Use any free output bits for `LATCH` and `CLOCK`, and one input bit for `DATA`.

Example mapping used by sample code:

- `PB0` -> `NES_LATCH`
- `PB1` -> `NES_CLOCK`
- `PA0` <- `NES_DATA`

Also connect:

- NES `VCC` -> +5V
- NES `GND` -> GND

### Electrical notes

- Keep shared ground between KIM-1 and controller.
- The controller is 5V TTL-compatible.
- If your cable is long/noisy, a small series resistor (100–330Ω) on output lines can help signal integrity.

---

## 3. Timing guidance

NES controllers are forgiving, so software bit-banging on a 1 MHz 6502 is straightforward.

Conservative timing:

- `LATCH` high for a few microseconds.
- `CLOCK` high pulse for a few microseconds.
- Read `DATA` while `CLOCK` is low (or consistently at one point in your cycle).

The included assembly has short delay loops between transitions.

---

## 4. Software interface in this repo

`src/nes_controller.s` exposes:

- `NES_InitIO`
  - Configure direction registers for latch/clock outputs and data input.
- `NES_ReadButtons`
  - Returns a byte with pressed buttons as `1` bits.
  - Stores current state in `NES_BUTTONS_CUR`.
  - Stores edge presses (new this frame) in `NES_BUTTONS_NEW`.

Button bit masks:

- `BTN_A      = %00000001`
- `BTN_B      = %00000010`
- `BTN_SELECT = %00000100`
- `BTN_START  = %00001000`
- `BTN_UP     = %00010000`
- `BTN_DOWN   = %00100000`
- `BTN_LEFT   = %01000000`
- `BTN_RIGHT  = %10000000`

---

## 5. Integrating with kimlife-style video loop

If you already have a stable frame loop from `kimlife`, add controller polling once per frame:

1. Begin frame
2. Call `NES_ReadButtons`
3. Update game state from button bits
4. Render video line/frame output

This keeps controls responsive and deterministic while preserving your existing video timing strategy.

---

## 6. Troubleshooting

- If no buttons register:
  - Verify power and ground.
  - Confirm `DATA` line is configured as input.
  - Check that `LATCH` and `CLOCK` actually toggle on a scope/logic probe.
- If buttons appear scrambled:
  - Confirm read order is exactly 8 shifts.
  - Confirm bit mapping in your game logic matches NES order.
- If directions seem inverted:
  - Ensure you are using the post-inversion value from `NES_ReadButtons` (pressed = 1).
