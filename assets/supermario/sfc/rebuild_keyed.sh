#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
PIPELINE="/Users/zhengyu/.ai/skills/sprite-cutout-pipeline/scripts/sprite_pipeline.py"

python3 "$PIPELINE" cutout "$ROOT_DIR/mario.png" "$ROOT_DIR/mario_keyed.png" --bg auto --tolerance 24
python3 "$PIPELINE" cutout "$ROOT_DIR/goombas.png" "$ROOT_DIR/goombas_keyed.png" --bg auto --tolerance 20
python3 "$PIPELINE" cutout "$ROOT_DIR/koopas.png" "$ROOT_DIR/koopas_keyed.png" --bg auto --tolerance 20
python3 "$PIPELINE" cutout "$ROOT_DIR/enemies.png" "$ROOT_DIR/enemies_keyed.png" --bg auto --tolerance 20
python3 "$PIPELINE" cutout "$ROOT_DIR/pipes.png" "$ROOT_DIR/pipes_keyed.png" --bg auto --tolerance 24
python3 "$PIPELINE" cutout "$ROOT_DIR/tiles.png" "$ROOT_DIR/tiles_keyed.png" --bg auto --tolerance 24
python3 "$PIPELINE" cutout "$ROOT_DIR/tiles-ground.png" "$ROOT_DIR/tiles-ground_keyed.png" --bg auto --tolerance 24

ROOT_DIR_ENV="$ROOT_DIR" python3 - <<'PY'
from PIL import Image
from pathlib import Path
import os

root = Path(os.environ["ROOT_DIR_ENV"])

mario = Image.open(root / "mario_keyed.png").convert("RGBA")
enemies = Image.open(root / "enemies_keyed.png").convert("RGBA")
tiles = Image.open(root / "tiles_keyed.png").convert("RGBA")
pipes = Image.open(root / "pipes_keyed.png").convert("RGBA")
backgrounds = Image.open(root / "backgrounds.png").convert("RGBA")

mario.save(root / "runtime_mario.png")
enemies.save(root / "runtime_enemies.png")
tiles.crop((0, 0, 500, 560)).save(root / "runtime_tiles.png")
pipes.crop((0, 0, 640, 270)).save(root / "runtime_pipes.png")
backgrounds.crop((258, 0, 516, 307)).save(root / "runtime_background_01.png")
backgrounds.crop((258, 307, 516, 614)).save(root / "runtime_background_02.png")
PY

echo "[ok] rebuilt keyed SFC sheets in $ROOT_DIR"
