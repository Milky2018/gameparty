# Jackal Sprite Sources

Primary source:

- https://www.spriters-resource.com/nes/jackaltopgunner/?source=genre

Raw sheet files are kept in this directory with the original filenames from the site.

## Runtime strips

The game runtime uses extracted directional strips under:

- `assets/jackal/jeep/`
- `assets/jackal/soldier/`
- `assets/jackal/turret/`
- `assets/jackal/vehicle/`
- `assets/jackal/fort/`

Each strip is generated as a `32x32`, `4-frame` horizontal atlas.

## Regenerate

From project root:

```bash
scripts/jackal_import_sprites.sh
```

This runs:

- `tools/import_jackal_sprites.py`

which keys out border-connected background colors and writes the runtime strips.

