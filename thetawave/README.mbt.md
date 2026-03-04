# Thetawave Port

This directory contains the MoonBit port of Thetawave.

## Structure

- `thetawave/*.mbt`: MoonBit gameplay implementation.
- `assets/`: mirrored upstream game assets.
- `upstream-rust/`: mirrored upstream Rust source for migration reference.

## Controls

- Move: `WASD` or arrow keys
- Fire: `Space` or left mouse button
- Special ability: `Q` or right mouse button
- Pause/Resume (in run): `Esc` or `Enter`
- Return to main menu from pause: `R`
- Restart after defeat/victory: `Enter`

## Campaign

- The run starts with a tutorial phase (movement -> main weapon -> special ability).
- The current port includes a 3-level campaign (`test_level_1` -> `test_level_2` -> `test_level_3`)
- Boss phases: `Ferritharax`, `MechaFerritharax`, `MechaSaucetron`
- Bosses now drop the item `EnhancedPlating` (permanent run buff: +100 max hull and full heal)
- Money pickup now scales cooldowns through an exponential decay curve.

## Run

```bash
moon run cmd/thetawave
```
