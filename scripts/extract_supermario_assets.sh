#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SPEC="$ROOT_DIR/assets/sprite_specs/supermario_all.json"
OUT="$ROOT_DIR/assets/supermario/extracted"

python3 "$ROOT_DIR/scripts/extract_sprites.py" validate --spec "$SPEC"
python3 "$ROOT_DIR/scripts/extract_sprites.py" run --spec "$SPEC" --out "$OUT" --overwrite

echo "[ok] extracted supermario assets -> $OUT"
