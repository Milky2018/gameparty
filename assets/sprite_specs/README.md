# Sprite Extract Specs

`extract_sprites.py` consumes a single JSON spec file.

Quick usage:

```bash
python scripts/extract_sprites.py validate --spec assets/sprite_specs/supermario_mario.json
python scripts/extract_sprites.py run --spec assets/sprite_specs/supermario_mario.json --out /tmp/supermario_extract

# full supermario runtime set
python scripts/extract_sprites.py validate --spec assets/sprite_specs/supermario_all.json
python scripts/extract_sprites.py run --spec assets/sprite_specs/supermario_all.json --out assets/supermario/extracted --overwrite
```

Top-level required fields:

- `version`: must be `"sprite-extractor-v1"`
- `sources`: `{ "key": "path/to/image.png" }`
- `jobs`: extraction jobs

Each job:

- `source`: key from `sources`
- `mode`: `"grid"` or `"rects"`
- `outputs`: array of explicitly named frames

`grid` mode fields:

- `origin_x`, `origin_y`, `step_x`, `step_y`, `frame_w`, `frame_h`
- each output frame: `{ "name": "...", "col": 0, "row": 0 }`

`rects` mode fields:

- each output frame: `{ "name": "...", "x": 0, "y": 0, "w": 16, "h": 16 }`

Optional postprocess fields (job-level or output-level):

- `remove_bg`: `{"rgb":[r,g,b], "tolerance":0..255}` or `false`
- `trim`: `true|false`
- `pad`: `{"width":N, "height":N}` or `false`
