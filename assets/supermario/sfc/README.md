# Super Mario SFC Asset Bundle

This folder contains SFC/SNES sprite sheets downloaded from:

- https://www.mariouniverse.com/sprites-snes-smw

## Files

### Raw source sheets

- `mario.png`
- `goombas.png`
- `koopas.png`
- `enemies.png`
- `pipes.png`
- `tiles.png`
- `tiles-ground.png`
- `backgrounds.png`

### Processed transparent sheets

- `mario_keyed.png`
- `goombas_keyed.png`
- `koopas_keyed.png`
- `enemies_keyed.png`
- `pipes_keyed.png`
- `tiles_keyed.png`
- `tiles-ground_keyed.png`

`*_keyed.png` are produced by key-color removal while preserving original atlas size.

### Runtime-ready cleaned sheets

- `runtime_mario.png`
- `runtime_enemies.png`
- `runtime_tiles.png`
- `runtime_pipes.png`
- `runtime_background_01.png`
- `runtime_background_02.png`

These are cropped to avoid annotation/credit areas from the original source atlases.

## Rebuild pipeline

Run this to regenerate processed sheets:

```bash
bash assets/supermario/sfc/rebuild_keyed.sh
```

The script uses the local Codex skill utility:

`/Users/zhengyu/.ai/skills/sprite-cutout-pipeline/scripts/sprite_pipeline.py`

## Notes

- These sheets still include original atlas annotations/credits embedded in source images.
- Runtime code should prefer `runtime_*.png`.
- For future mapping:
  - player sprites: `runtime_mario.png`
  - goomba/koopa sprites: `runtime_enemies.png`
  - terrain blocks/question/used: `runtime_tiles.png`
  - pipe blocks: `runtime_pipes.png`
  - level background: `runtime_background_01.png` or `runtime_background_02.png`
- This directory only prepares assets; gameplay mapping is handled in `supermario/plugin.mbt`.
