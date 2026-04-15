#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if [[ $# -lt 1 ]]; then
  echo "Usage: scripts/build_web_game.sh <game|apps-web/game> [--release]"
  exit 1
fi

GAME="${1#apps-web/}"
MODE="debug"
MOON_ARGS=(
  run
  --manifest-path
  apps-web/moon.mod.json
  --target
  js
  --build-only
  "apps-web/${GAME}"
)
if [[ "${2:-}" == "--release" ]]; then
  MODE="release"
  MOON_ARGS=(
    run
    --manifest-path
    apps-web/moon.mod.json
    --target
    js
    --build-only
    --release
    "apps-web/${GAME}"
  )
fi

PKG_DIR="$ROOT_DIR/apps-web/$GAME"
if [[ ! -f "$PKG_DIR/moon.pkg" ]]; then
  echo "Error: package '$PKG_DIR' not found."
  exit 1
fi

DIST_DIR="$ROOT_DIR/dist/web"
mkdir -p "$DIST_DIR"

if [[ "${SKIP_ASSET_SYNC:-0}" != "1" ]]; then
  rm -rf "$DIST_DIR/assets"
  mkdir -p "$DIST_DIR/assets"
  cp -R "$ROOT_DIR/assets/." "$DIST_DIR/assets/"
  find "$DIST_DIR/assets" -name '.DS_Store' -delete
fi

ARTIFACT_ERR="$(mktemp)"
if ! ARTIFACT_JSON="$(moon "${MOON_ARGS[@]}" 2>"$ARTIFACT_ERR")"; then
  cat "$ARTIFACT_ERR" >&2
  rm -f "$ARTIFACT_ERR"
  exit 1
fi
rm -f "$ARTIFACT_ERR"
JS_ARTIFACT="$(python3 -c 'import json, sys; print(json.load(sys.stdin)["artifacts_path"][0])' <<<"$ARTIFACT_JSON")"
if [[ ! -f "$JS_ARTIFACT" ]]; then
  echo "Error: generated JS artifact not found: $JS_ARTIFACT"
  exit 1
fi

cp "$JS_ARTIFACT" "$DIST_DIR/$GAME.js"
if [[ -f "$JS_ARTIFACT.map" ]]; then
  cp "$JS_ARTIFACT.map" "$DIST_DIR/$GAME.js.map"
fi

cat >"$DIST_DIR/$GAME.html" <<HTML
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>Gameparty - ${GAME}</title>
    <style>
      html,
      body {
        height: 100%;
      }
      body {
        margin: 0;
        background: #0f1520;
      }
      canvas {
        display: block;
        margin: 0 auto;
      }
    </style>
    <script src="./${GAME}.js" defer></script>
  </head>
  <body>
    <canvas id="canvas"></canvas>
  </body>
</html>
HTML

touch "$DIST_DIR/.nojekyll"

echo "[web-build] built $GAME ($MODE) -> $DIST_DIR/$GAME.html"

if [[ "${SKIP_GALLERY:-0}" != "1" && -x "$ROOT_DIR/scripts/gen_web_gallery.sh" ]]; then
  "$ROOT_DIR/scripts/gen_web_gallery.sh"
fi
