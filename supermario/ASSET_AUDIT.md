# Super Mario Asset Audit Workflow

This workflow is the fixed path for atlas/slice debugging in `supermario`.

## Run Once

```bash
tools/supermario_asset_audit.sh
```

Optionally choose a custom report root:

```bash
tools/supermario_asset_audit.sh /absolute/path/to/reports
```

## Output Structure

The script creates:

- `_reports/supermario_asset_audit/<timestamp>/run.log`
- `_reports/supermario_asset_audit/<timestamp>/scene.png`
- `_reports/supermario_asset_audit/<timestamp>/expected_regions/*.png`
- `_reports/supermario_asset_audit/<timestamp>/visible_regions/*.png`
- `_reports/supermario_asset_audit/<timestamp>/capture.log`
- `_reports/supermario_asset_audit/<timestamp>/sprites.log`
- `_reports/supermario_asset_audit/<timestamp>/metadata.log`
- `_reports/supermario_asset_audit/<timestamp>/sprite_review.md`
- `_reports/supermario_asset_audit/latest` (symlink)

## What Each Artifact Means

- `expected_regions/`: regions exported from plugin sprite declarations.
- `visible_regions/`: runtime sprite inspector exports from live entities.
- `scene.png`: frame capture from the actual game render.
- `sprites.log`: raw sprite inspector entries (entity id, entity name, rect, image path).
- `metadata.log`: full frame metadata JSON.
- `sprite_review.md`: per-sprite review report (each sprite has its own section and image).

## Acceptance Checklist (Mandatory)

1. Open `sprite_review.md` and confirm each sprite section has final verdict (`PASS`/`FAIL`) with notes.
2. `scene.png` must show coherent composition (player, enemies, tiles, UI).
3. Every key entry in `expected_regions/` must match intended sprite meaning.
4. `visible_regions/` files with named entities (`player`, `enemy_*`, `block_*`) must use the same atlas families and correct slices.
5. If a mismatch exists, adjust atlas coordinates in [plugin.mbt](/Users/zhengyu/Documents/projects/gameparty/supermario/plugin.mbt), rerun the script, and re-check.

## Notes

- The run uses `PLATFORMER_CAPTURE=1` and exits automatically after capture.
- The workflow is deterministic enough for slice verification and should be used before each sprite mapping commit.
