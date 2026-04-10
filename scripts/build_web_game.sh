#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if [[ $# -lt 1 ]]; then
  echo "Usage: scripts/build_web_game.sh <game|cmd/game> [--release]"
  exit 1
fi

if ! command -v emcc >/dev/null 2>&1; then
  echo "Error: emcc not found. Install emscripten first."
  exit 1
fi

GAME="${1#cmd/}"
MODE="debug"
MOON_BUILD_ARGS=()
if [[ "${2:-}" == "--release" ]]; then
  MODE="release"
  MOON_BUILD_ARGS+=(--release)
fi

CMD_PKG="cmd/${GAME}"
if [[ ! -d "$CMD_PKG" ]]; then
  echo "Error: package '$CMD_PKG' not found."
  exit 1
fi

if [[ ${#MOON_BUILD_ARGS[@]} -gt 0 ]]; then
  moon build "${MOON_BUILD_ARGS[@]}" "$CMD_PKG"
else
  moon build "$CMD_PKG"
fi

C_FILE="$ROOT_DIR/_build/native/${MODE}/build/cmd/${GAME}/${GAME}.c"
if [[ ! -f "$C_FILE" ]]; then
  echo "Error: generated C file not found: $C_FILE"
  exit 1
fi

RUNTIME_C="$HOME/.moon/lib/runtime.c"
if [[ ! -f "$RUNTIME_C" ]]; then
  echo "Error: moon runtime C not found: $RUNTIME_C"
  exit 1
fi

RAY_DIR="$ROOT_DIR/.mooncakes/tonyfettes/raylib/internal/raylib"
FS_NATIVE_C="$ROOT_DIR/.mooncakes/moonbitlang/x/fs/fs_native.c"
NETPLAY_STUB_C="$ROOT_DIR/netplay/transport_native_stub.c"
EMCC_OPT_LEVEL="${EMCC_OPT_LEVEL:--O1}"
EMCC_ENABLE_ASYNCIFY="${EMCC_ENABLE_ASYNCIFY:-1}"
EMCC_ASYNCIFY_IGNORE_INDIRECT="${EMCC_ASYNCIFY_IGNORE_INDIRECT:-1}"

SOURCES=(
  "$C_FILE"
  "$RUNTIME_C"
  "$FS_NATIVE_C"
  "$NETPLAY_STUB_C"
  "$RAY_DIR/rcore.c"
  "$RAY_DIR/rshapes.c"
  "$RAY_DIR/rtextures.c"
  "$RAY_DIR/rtext.c"
  "$RAY_DIR/rmodels.c"
  "$RAY_DIR/raudio.c"
  "$RAY_DIR/utils.c"
  "$RAY_DIR/stub_window.c"
  "$RAY_DIR/stub_input.c"
  "$RAY_DIR/stub_drawing.c"
  "$RAY_DIR/stub_camera.c"
  "$RAY_DIR/stub_color.c"
  "$RAY_DIR/stub_shapes.c"
  "$RAY_DIR/stub_textures.c"
  "$RAY_DIR/stub_text.c"
  "$RAY_DIR/stub_models.c"
  "$RAY_DIR/stub_audio.c"
  "$RAY_DIR/stub_image_processing.c"
  "$RAY_DIR/stub_image_drawing.c"
  "$RAY_DIR/stub_filesystem.c"
  "$RAY_DIR/stub_utils.c"
  "$RAY_DIR/stub_automation.c"
)

for src in "${SOURCES[@]}"; do
  if [[ ! -f "$src" ]]; then
    echo "Error: missing source file: $src"
    exit 1
  fi
done

OUT_DIR="$ROOT_DIR/web/$GAME"
mkdir -p "$OUT_DIR"

echo "[web-build] compiling $GAME (${MODE})..."
EMCC_FLAGS=(
  -include string.h
  -I"$HOME/.moon/include"
  -I"$RAY_DIR"
  -DPLATFORM_WEB
  -DGRAPHICS_API_OPENGL_ES2
  -DSUPPORT_BUSY_WAIT_LOOP
  -sUSE_GLFW=3
  -sALLOW_MEMORY_GROWTH=1
  -sFORCE_FILESYSTEM=1
  --preload-file "$ROOT_DIR/assets@/assets"
  "$EMCC_OPT_LEVEL"
)

if [[ "$EMCC_ENABLE_ASYNCIFY" == "1" ]]; then
  EMCC_FLAGS+=(-sASYNCIFY)
  if [[ "$EMCC_ASYNCIFY_IGNORE_INDIRECT" == "1" ]]; then
    EMCC_FLAGS+=(-sASYNCIFY_IGNORE_INDIRECT=1)
  fi
fi

emcc \
  "${SOURCES[@]}" \
  "${EMCC_FLAGS[@]}" \
  -o "$OUT_DIR/index.html"

echo "[web-build] output: $OUT_DIR/index.html"

if [[ "${SKIP_GALLERY:-0}" != "1" && -x "$ROOT_DIR/scripts/gen_web_gallery.sh" ]]; then
  "$ROOT_DIR/scripts/gen_web_gallery.sh"
fi
