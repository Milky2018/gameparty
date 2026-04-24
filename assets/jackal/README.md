# Jackal Runtime Assets

The canonical Jackal runtime assets are generated locally by:

```bash
scripts/jackal_import_sprites.sh
```

This runs `tools/generate_jackal_assets.py` and writes every asset referenced by
`jackal/plugin.mbt`. The generated style is original project-local pixel art and
does not depend on downloaded sprite sheets.

## Role Sheets

Each actor has a single canonical role sheet under:

- `assets/jackal/roles/jeep.png`
- `assets/jackal/roles/soldier.png`
- `assets/jackal/roles/turret.png`
- `assets/jackal/roles/vehicle.png`
- `assets/jackal/roles/fort.png`

Each role sheet is a `128x128` transparent PNG: four direction rows (`up`,
`right`, `down`, `left`) by four animation columns.

## Runtime strips

The current `topdown_action` sprite model still consumes one horizontal strip
per direction, so the generator also writes derived runtime strips under:

- `assets/jackal/jeep/`
- `assets/jackal/soldier/`
- `assets/jackal/turret/`
- `assets/jackal/vehicle/`
- `assets/jackal/fort/`

Each strip is generated as a `32x32`, `4-frame` horizontal atlas.

## Terrain and Objectives

The generated terrain/objective props live under:

- `assets/jackal/terrain/`
- `assets/jackal/objectives/`

They are `64x64` PNGs aligned to the current `topdown_action` tile size.
