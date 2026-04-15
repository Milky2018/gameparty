#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

MODE_FLAG=""
if [[ "${1:-}" == "--release" ]]; then
  MODE_FLAG="--release"
fi

BUILD_SCRIPT="$ROOT_DIR/scripts/build_web_game.sh"
if [[ ! -x "$BUILD_SCRIPT" ]]; then
  echo "Error: missing executable script: $BUILD_SCRIPT"
  exit 1
fi

DIST_DIR="$ROOT_DIR/dist/web"
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR/assets"
cp -R "$ROOT_DIR/assets/." "$DIST_DIR/assets/"
find "$DIST_DIR/assets" -name '.DS_Store' -delete

GAMES=()
while IFS= read -r game; do
  [[ -z "$game" ]] && continue
  GAMES+=("$game")
done < <(
  find "$ROOT_DIR/apps-web" -mindepth 1 -maxdepth 1 -type d \
    -exec test -f "{}/moon.pkg" ';' \
    -exec test -f "{}/main.mbt" ';' \
    -exec basename {} \; | sort
)

if [[ ${#GAMES[@]} -eq 0 ]]; then
  echo "No apps-web packages found."
  exit 0
fi

ok_count=0
fail_count=0
failed_games=()

echo "[web-build-all] games: ${#GAMES[@]}"
for game in "${GAMES[@]}"; do
  echo "[web-build-all] >>> $game"
  if [[ -n "$MODE_FLAG" ]]; then
    if SKIP_GALLERY=1 SKIP_ASSET_SYNC=1 "$BUILD_SCRIPT" "$game" "$MODE_FLAG"; then
      ok_count=$((ok_count + 1))
    else
      fail_count=$((fail_count + 1))
      failed_games+=("$game")
    fi
  else
    if SKIP_GALLERY=1 SKIP_ASSET_SYNC=1 "$BUILD_SCRIPT" "$game"; then
      ok_count=$((ok_count + 1))
    else
      fail_count=$((fail_count + 1))
      failed_games+=("$game")
    fi
  fi
done

if [[ -x "$ROOT_DIR/scripts/gen_web_gallery.sh" ]]; then
  "$ROOT_DIR/scripts/gen_web_gallery.sh"
fi

touch "$DIST_DIR/.nojekyll"

echo "[web-build-all] done: ok=$ok_count fail=$fail_count"
if [[ $fail_count -gt 0 ]]; then
  echo "[web-build-all] failed games: ${failed_games[*]}"
  exit 1
fi
