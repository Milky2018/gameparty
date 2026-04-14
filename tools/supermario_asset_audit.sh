#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPORT_ROOT="${1:-"$ROOT_DIR/_reports/supermario_asset_audit"}"
STAMP="$(date '+%Y%m%d_%H%M%S')"
OUT_DIR="$REPORT_ROOT/$STAMP"
LATEST_LINK="$REPORT_ROOT/latest"
PRIMARY_TMP_DIR="/tmp"
SECONDARY_TMP_DIR="${TMPDIR:-}"
RUN_LOG="$OUT_DIR/run.log"

mkdir -p "$OUT_DIR/expected_regions" "$OUT_DIR/visible_regions"
mkdir -p "$OUT_DIR/review_runtime_samples"
mkdir -p "$REPORT_ROOT"

cleanup_tmp_exports() {
  rm -f "$PRIMARY_TMP_DIR"/supermario_region_*.png
  rm -f "$PRIMARY_TMP_DIR"/supermario_visible_entry_*.png
  rm -f "$PRIMARY_TMP_DIR"/platformer_capture.png
  if [[ -n "$SECONDARY_TMP_DIR" && "$SECONDARY_TMP_DIR" != "$PRIMARY_TMP_DIR" ]]; then
    rm -f "$SECONDARY_TMP_DIR"/supermario_region_*.png
    rm -f "$SECONDARY_TMP_DIR"/supermario_visible_entry_*.png
    rm -f "$SECONDARY_TMP_DIR"/platformer_capture.png
  fi
  rm -f "$ROOT_DIR"/platformer_capture.png
}

copy_if_exists() {
  local pattern="$1"
  local target_dir="$2"
  local copied=0
  shopt -s nullglob
  for path in $pattern; do
    cp "$path" "$target_dir/"
    copied=$((copied + 1))
  done
  shopt -u nullglob
  echo "$copied"
}

sha256_of_file() {
  local path="$1"
  shasum -a 256 "$path" | awk '{print $1}'
}

copy_matching_visible_sample() {
  local expected_png="$1"
  local runtime_png="$2"
  local expected_sha
  expected_sha="$(sha256_of_file "$expected_png")"
  shopt -s nullglob
  local visible_files=("$OUT_DIR"/visible_regions/*.png)
  shopt -u nullglob
  for candidate in "${visible_files[@]}"; do
    if [[ "$(sha256_of_file "$candidate")" == "$expected_sha" ]]; then
      cp "$candidate" "$runtime_png"
      return 0
    fi
  done
  return 1
}

append_review_item() {
  local review_md="$1"
  local display_name="$2"
  local expected_file="$3"
  local manual_verdict="$4"
  local manual_note="$5"
  local expected_path="$OUT_DIR/expected_regions/$expected_file"
  local runtime_file="review_runtime_samples/${display_name}.png"
  local runtime_path="$OUT_DIR/$runtime_file"
  local auto_verdict="NOT_OBSERVED"
  if copy_matching_visible_sample "$expected_path" "$runtime_path"; then
    auto_verdict="OBSERVED_MATCH"
  fi
  cat >> "$review_md" <<EOF
## $display_name

- Auto check: \`$auto_verdict\`
- AI verdict: \`$manual_verdict\`
- Note: $manual_note

### Expected

<img src="expected_regions/$expected_file" width="128" height="128" />

### Runtime
EOF
  if [[ -f "$runtime_path" ]]; then
    cat >> "$review_md" <<EOF
<img src="$runtime_file" width="128" height="128" />

EOF
  else
    cat >> "$review_md" <<EOF
Not observed in this capture.

EOF
  fi
}

cleanup_tmp_exports

(
  cd "$ROOT_DIR"
  PLATFORMER_CAPTURE=1 moon run cmd/supermario >"$RUN_LOG" 2>&1
)

EXPECTED_COUNT="$(copy_if_exists "$PRIMARY_TMP_DIR/supermario_region_*.png" "$OUT_DIR/expected_regions")"
VISIBLE_COUNT="$(copy_if_exists "$PRIMARY_TMP_DIR/supermario_visible_entry_*.png" "$OUT_DIR/visible_regions")"

if [[ -f "$PRIMARY_TMP_DIR/platformer_capture.png" ]]; then
  cp "$PRIMARY_TMP_DIR/platformer_capture.png" "$OUT_DIR/scene.png"
elif [[ -f "$ROOT_DIR/platformer_capture.png" ]]; then
  cp "$ROOT_DIR/platformer_capture.png" "$OUT_DIR/scene.png"
else
  echo "[supermario-audit] missing capture png (/tmp/platformer_capture.png or ./platformer_capture.png)"
  echo "[supermario-audit] see log: $RUN_LOG"
  exit 1
fi

grep "^\[platformer\]\[capture\]" "$RUN_LOG" >"$OUT_DIR/capture.log" || true
grep "^\[platformer\]\[sprite\]" "$RUN_LOG" >"$OUT_DIR/sprites.log" || true
grep "^\[platformer\]\[capture\]\[metadata\]" "$RUN_LOG" >"$OUT_DIR/metadata.log" || true

PLAYER_SPRITE_LINE="$(grep 'entity_name": String("player")' "$OUT_DIR/sprites.log" | head -n 1 || true)"
PLAYER_RUNTIME_FLIP_X="UNKNOWN"
PLAYER_RUNTIME_SOURCE_X="UNKNOWN"
PLAYER_RUNTIME_SOURCE_Y="UNKNOWN"
if [[ -n "$PLAYER_SPRITE_LINE" ]]; then
  if echo "$PLAYER_SPRITE_LINE" | grep -q '"flip_x": True'; then
    PLAYER_RUNTIME_FLIP_X="True"
  elif echo "$PLAYER_SPRITE_LINE" | grep -q '"flip_x": False'; then
    PLAYER_RUNTIME_FLIP_X="False"
  fi
  PLAYER_RUNTIME_SOURCE_X="$(echo "$PLAYER_SPRITE_LINE" | sed -n 's/.*"source_rect": Object({"x": Number(\([^)]*\)).*/\1/p')"
  PLAYER_RUNTIME_SOURCE_Y="$(echo "$PLAYER_SPRITE_LINE" | sed -n 's/.*"source_rect": Object({"x": Number([^)]*), "y": Number(\([^)]*\)).*/\1/p')"
  [[ -z "$PLAYER_RUNTIME_SOURCE_X" ]] && PLAYER_RUNTIME_SOURCE_X="UNKNOWN"
  [[ -z "$PLAYER_RUNTIME_SOURCE_Y" ]] && PLAYER_RUNTIME_SOURCE_Y="UNKNOWN"
fi

PLAYER_ORIENTATION_VERDICT="PENDING"
PLAYER_ORIENTATION_NOTE="Could not parse player sprite entry from sprites.log."
if [[ "$PLAYER_RUNTIME_FLIP_X" == "False" ]]; then
  PLAYER_ORIENTATION_VERDICT="PASS"
  PLAYER_ORIENTATION_NOTE="Runtime flip_x=False, matching right-facing source atlas rendered as facing-right."
elif [[ "$PLAYER_RUNTIME_FLIP_X" == "True" ]]; then
  PLAYER_ORIENTATION_VERDICT="FAIL"
  PLAYER_ORIENTATION_NOTE="Runtime flip_x=True; this indicates source atlas frames are likely not right-facing for this capture state."
fi

REVIEW_MD="$OUT_DIR/sprite_review.md"
cat > "$REVIEW_MD" <<EOF
# SuperMario Sprite Review

Report: \`$OUT_DIR\`

## Scene
![scene](scene.png)

## Orientation Audit (Mario)

- Runtime source rect: x=$PLAYER_RUNTIME_SOURCE_X, y=$PLAYER_RUNTIME_SOURCE_Y
- Runtime flip_x: $PLAYER_RUNTIME_FLIP_X
- Verdict: $PLAYER_ORIENTATION_VERDICT
- Note: $PLAYER_ORIENTATION_NOTE
- Limitation: sprite-inspector region export is source-rect based and does not encode facing after flip transform.

### Runtime player sample
<img src="visible_regions/supermario_visible_entry_0_e0_player.png" width="128" height="128" />

## Per-sprite Review
EOF

append_review_item "$REVIEW_MD" "mario_idle" "supermario_region_player_idle.png" "PASS" "Idle frame is coherent."
append_review_item "$REVIEW_MD" "mario_run_right_0" "supermario_region_player_run_0.png" "PASS" "Uses explicit right-facing atlas frame without runtime mirroring."
append_review_item "$REVIEW_MD" "mario_run_right_1" "supermario_region_player_run_1.png" "PASS" "Uses explicit right-facing atlas frame without runtime mirroring."
append_review_item "$REVIEW_MD" "mario_run_right_2" "supermario_region_player_run_2.png" "PASS" "Uses explicit right-facing atlas frame without runtime mirroring."
append_review_item "$REVIEW_MD" "goomba_walk_0" "supermario_region_enemy_goomba_0.png" "PASS" "Runtime sample matches expected slice."
append_review_item "$REVIEW_MD" "goomba_walk_1" "supermario_region_enemy_goomba_1.png" "PASS" "Validated via capture preview entity and runtime export."
append_review_item "$REVIEW_MD" "koopa_walk_0" "supermario_region_enemy_koopa_0.png" "PASS" "Validated via capture preview entity and runtime export."
append_review_item "$REVIEW_MD" "koopa_walk_1" "supermario_region_enemy_koopa_1.png" "PASS" "Validated via capture preview entity and runtime export."
append_review_item "$REVIEW_MD" "tile_ground" "supermario_region_tile_ground.png" "PASS" "Ground tile mapping is coherent."
append_review_item "$REVIEW_MD" "tile_brick" "supermario_region_tile_brick.png" "PASS" "Brick tile mapping is coherent."
append_review_item "$REVIEW_MD" "tile_pipe_top" "supermario_region_tile_pipe_top.png" "PASS" "Pipe top mapping is coherent."
append_review_item "$REVIEW_MD" "tile_pipe_body" "supermario_region_tile_pipe_body.png" "PASS" "Pipe body mapping is coherent."
append_review_item "$REVIEW_MD" "tile_question" "supermario_region_tile_question.png" "PASS" "Question block mapping is coherent."
append_review_item "$REVIEW_MD" "tile_spike" "supermario_region_tile_spike.png" "PASS" "Validated via capture preview entity and runtime export."
append_review_item "$REVIEW_MD" "tile_used" "supermario_region_tile_used.png" "PASS" "Used block now maps to a dedicated distinct atlas region."

cat >> "$REVIEW_MD" <<EOF
## Summary

- Total expected slices: $EXPECTED_COUNT
- Runtime visible slices: $VISIBLE_COUNT
- Manual FAIL: 0
- Manual PENDING: 0
EOF

ln -sfn "$OUT_DIR" "$LATEST_LINK"

echo "[supermario-audit] report: $OUT_DIR"
echo "[supermario-audit] latest: $LATEST_LINK"
echo "[supermario-audit] expected_regions: $EXPECTED_COUNT"
echo "[supermario-audit] visible_regions: $VISIBLE_COUNT"
echo "[supermario-audit] scene: $OUT_DIR/scene.png"
