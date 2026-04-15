#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUN_TIMEOUT="${RUN_TIMEOUT:-45}"
FPS_MIN="${FPS_MIN:-56}"
FPS_MAX="${FPS_MAX:-65}"
PRECHECK="${PRECHECK:-1}"
SHOT_MIN_WIDTH="${SHOT_MIN_WIDTH:-640}"
SHOT_MIN_HEIGHT="${SHOT_MIN_HEIGHT:-360}"
LOCK_MODE="${LOCK_MODE:-1}"
LOCK_WAIT_SEC="${LOCK_WAIT_SEC:-600}"
REQUIRE_PROFILE="${REQUIRE_PROFILE:-1}"
REQUIRE_CAPTURE_LOG="${REQUIRE_CAPTURE_LOG:-1}"
REQUIRE_PLAY_MARKER="${REQUIRE_PLAY_MARKER:-1}"
REQUIRE_WINDOW_CLOSE_LOG="${REQUIRE_WINDOW_CLOSE_LOG:-0}"

TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
OUT_DIR="${OUT_DIR:-$ROOT/review_logs/full_review_${TIMESTAMP}_script}"
mkdir -p "$OUT_DIR"

SUMMARY_TSV="$OUT_DIR/summary.tsv"
PRECHECK_TSV="$OUT_DIR/precheck.tsv"

CAPTURE_POOL=(
  "angryrabbits_capture.png"
  "bombman_capture.png"
  "mooncraft_capture.png"
  "tankbattle_capture.png"
  "supermario_capture.png"
  "plantvszombies_capture.png"
  "bejeweled_capture.png"
  "jackal_capture.png"
  "kofarena_capture.png"
  "pacman3d_capture.png"
  "thetawave_capture.png"
  "coinpusher3d_capture.png"
)

RUN_NATIVE="moon run --manifest-path apps-native/moon.mod.json --target native"

CASES=(
  "angryrabbits|angryrabbits|angryrabbits_capture.png|ANGRYRABBITS_CAPTURE=1 ANGRYRABBITS_PROFILE=1 timeout __TIMEOUT__ $RUN_NATIVE apps-native/angryrabbits|\\[angryrabbits\\]\\[perf\\]"
  "bombman|bombman|bombman_capture.png|BOMBMAN_CAPTURE=1 BOMBMAN_PROFILE=1 timeout __TIMEOUT__ $RUN_NATIVE apps-native/bombman|fps_avg="
  "mooncraft|mooncraft|mooncraft_capture.png|MOONCRAFT_CAPTURE=1 MOONCRAFT_PROFILE=1 timeout __TIMEOUT__ $RUN_NATIVE apps-native/mooncraft|loaded_chunks="
  "tankbattle|tankbattle|tankbattle_capture.png|TANKBATTLE_CAPTURE=1 TANKBATTLE_PROFILE=1 timeout __TIMEOUT__ $RUN_NATIVE apps-native/tankbattle|phase=Playing"
  "supermario|supermario|supermario_capture.png|SUPERMARIO_CAPTURE=1 SUPERMARIO_PROFILE=1 timeout __TIMEOUT__ $RUN_NATIVE apps-native/supermario|phase=Playing"
  "plantvszombies|plantvszombies|plantvszombies_capture.png|PVZ_CAPTURE=1 PVZ_PROFILE=1 timeout __TIMEOUT__ $RUN_NATIVE apps-native/plantvszombies|wave="
  "bejeweled|bejeweled|bejeweled_capture.png|BEJEWELED_CAPTURE=1 BEJEWELED_PROFILE=1 timeout __TIMEOUT__ $RUN_NATIVE apps-native/bejeweled|moves="
  "jackal|jackal|jackal_capture.png|JACKAL_CAPTURE=1 JACKAL_PROFILE=1 timeout __TIMEOUT__ $RUN_NATIVE apps-native/jackal|wave="
  "kofarena|kofarena|kofarena_capture.png|KOF_CAPTURE=1 KOF_PROFILE=1 timeout __TIMEOUT__ $RUN_NATIVE apps-native/kofarena|phase=Playing"
  "pacman3d|pacman3d|pacman3d_capture.png|PACMAN3D_CAPTURE=1 PACMAN3D_PROFILE=1 timeout __TIMEOUT__ $RUN_NATIVE apps-native/pacman3d|dots="
  "thetawave|thetawave|thetawave_capture.png|THETAWAVE_CAPTURE=1 THETAWAVE_PROFILE=1 timeout __TIMEOUT__ $RUN_NATIVE apps-native/thetawave|phase=(Movement|Playing)"
  "coinpusher3d|coinpusher3d|coinpusher3d_capture.png|COINPUSHER3D_CAPTURE=1 COINPUSHER3D_PROFILE=1 timeout __TIMEOUT__ $RUN_NATIVE apps-native/coinpusher3d|phase=Playing"
)

is_requested() {
  local game="$1"
  if [[ "$#" -eq 1 && "${#REQUESTED[@]}" -eq 0 ]]; then
    return 0
  fi
  local requested
  for requested in "${REQUESTED[@]}"; do
    if [[ "$requested" == "$game" ]]; then
      return 0
    fi
  done
  return 1
}

extract_fps_metric() {
  local log="$1"
  local metric
  metric="$(grep -Eo 'fps_frame_dt=[0-9]+([.][0-9]+)?' "$log" | tail -n1 | cut -d= -f2 || true)"
  if [[ -z "$metric" ]]; then
    metric="$(grep -Eo 'fps_avg=[0-9]+([.][0-9]+)?' "$log" | tail -n1 | cut -d= -f2 || true)"
  fi
  if [[ -z "$metric" ]]; then
    metric="$(grep -Eo 'fps_window=[0-9]+([.][0-9]+)?' "$log" | tail -n1 | cut -d= -f2 || true)"
  fi
  if [[ -z "$metric" ]]; then
    metric="$(grep -Eo 'fps=[0-9]+([.][0-9]+)?' "$log" | tail -n1 | cut -d= -f2 || true)"
  fi
  if [[ -z "$metric" ]]; then
    echo "n/a"
  else
    echo "$metric"
  fi
}

fps_in_range() {
  local fps="$1"
  if [[ ! "$fps" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
    return 1
  fi
  awk "BEGIN { exit !($fps >= $FPS_MIN && $fps <= $FPS_MAX) }"
}

capture_dim_ok() {
  local width="$1"
  local height="$2"
  if [[ ! "$width" =~ ^[0-9]+$ ]]; then
    return 1
  fi
  if [[ ! "$height" =~ ^[0-9]+$ ]]; then
    return 1
  fi
  [[ "$width" -ge "$SHOT_MIN_WIDTH" && "$height" -ge "$SHOT_MIN_HEIGHT" ]]
}

capture_dimensions() {
  local path="$1"
  if [[ ! -f "$path" ]]; then
    echo "0 0"
    return
  fi
  if command -v sips >/dev/null 2>&1; then
    local width height
    width="$(sips -g pixelWidth "$path" 2>/dev/null | awk '/pixelWidth/ { print $2; exit }')"
    height="$(sips -g pixelHeight "$path" 2>/dev/null | awk '/pixelHeight/ { print $2; exit }')"
    if [[ -n "$width" && -n "$height" ]]; then
      echo "$width $height"
      return
    fi
  fi
  local dims
  dims="$(file "$path" | grep -Eo '[0-9]+ x [0-9]+' | head -n1 | tr -d ' ' | tr 'x' ' ' || true)"
  if [[ -n "$dims" ]]; then
    echo "$dims"
  else
    echo "0 0"
  fi
}

acquire_lock() {
  if [[ "$LOCK_MODE" != "1" ]]; then
    return
  fi
  local lock_dir="/tmp/gameparty_review_lock"
  local waited=0
  while ! mkdir "$lock_dir" >/dev/null 2>&1; do
    sleep 1
    waited=$((waited + 1))
    if [[ "$waited" -ge "$LOCK_WAIT_SEC" ]]; then
      echo "[review] lock timeout after ${LOCK_WAIT_SEC}s: $lock_dir" >&2
      exit 3
    fi
  done
  REVIEW_LOCK_DIR="$lock_dir"
}

release_lock() {
  if [[ -n "${REVIEW_LOCK_DIR:-}" ]]; then
    rmdir "${REVIEW_LOCK_DIR}" >/dev/null 2>&1 || true
    REVIEW_LOCK_DIR=""
  fi
}

printf "game\texit\tduration_s\tscreenshot\tshot_bytes\tshot_width\tshot_height\tdim_ok\twindow_closed\tprofile_line\tcapture_line\tplay_marker_ok\tfps_metric\tfps_ok\tglfw_warn\tpbr_warn\textra_capture\tgate\treason\n" > "$SUMMARY_TSV"
printf "package\tduration_s\texit\n" > "$PRECHECK_TSV"

REQUESTED=("$@")

echo "[review] out_dir=$OUT_DIR"
echo "[review] timeout=${RUN_TIMEOUT}s fps_range=${FPS_MIN}-${FPS_MAX} shot_min=${SHOT_MIN_WIDTH}x${SHOT_MIN_HEIGHT} precheck=$PRECHECK lock=$LOCK_MODE require_window_close=$REQUIRE_WINDOW_CLOSE_LOG"

REVIEW_LOCK_DIR=""
trap release_lock EXIT
acquire_lock

pkill -f "moon run --manifest-path apps-native/moon.mod.json" >/dev/null 2>&1 || true
pkill -f "timeout [0-9]+s moon run" >/dev/null 2>&1 || true

if [[ "$PRECHECK" == "1" ]]; then
  local_case=""
  for local_case in "${CASES[@]}"; do
    IFS='|' read -r game pkg _capture _command _marker <<< "$local_case"
    if ! is_requested "$game"; then
      continue
    fi
    echo "[precheck] $pkg"
    start="$(date +%s)"
    set +e
    moon check "$pkg" > "$OUT_DIR/${game}.precheck.log" 2>&1
    code="$?"
    set -e
    end="$(date +%s)"
    dur="$((end - start))"
    printf "%s\t%s\t%s\n" "$pkg" "$dur" "$code" >> "$PRECHECK_TSV"
    if [[ "$code" -ne 0 ]]; then
      echo "[precheck] FAIL $pkg code=$code"
    else
      echo "[precheck] PASS $pkg (${dur}s)"
    fi
  done
fi

all_passed=1
local_case=""
for local_case in "${CASES[@]}"; do
  IFS='|' read -r game pkg capture command_template play_marker <<< "$local_case"
  if ! is_requested "$game"; then
    continue
  fi

  command="${command_template/__TIMEOUT__/${RUN_TIMEOUT}s}"
  log="$OUT_DIR/${game}.log"
  meta="$OUT_DIR/${game}.meta"

  for f in "${CAPTURE_POOL[@]}"; do
    rm -f "$ROOT/$f"
  done

  echo "[run] $game"
  start="$(date +%s)"
  set +e
  eval "$command" > "$log" 2>&1
  code="$?"
  set -e
  end="$(date +%s)"
  dur="$((end - start))"

  screenshot="no"
  shot_bytes="0"
  shot_width="0"
  shot_height="0"
  dim_ok="no"
  if [[ -f "$ROOT/$capture" ]]; then
    cp "$ROOT/$capture" "$OUT_DIR/$capture"
    screenshot="yes"
    shot_bytes="$(wc -c < "$ROOT/$capture" | tr -d ' ')"
    read -r shot_width shot_height <<< "$(capture_dimensions "$ROOT/$capture")"
    if capture_dim_ok "$shot_width" "$shot_height"; then
      dim_ok="yes"
    fi
  fi

  window_closed="no"
  if grep -q "Window closed successfully" "$log"; then
    window_closed="yes"
  fi

  profile_line="no"
  if grep -Eq "\[$game\]\[(profile|perf)\]" "$log"; then
    profile_line="yes"
  fi

  capture_line="no"
  if grep -q "\[$game\]\[capture\]" "$log" || grep -q "Screenshot taken successfully" "$log"; then
    capture_line="yes"
  fi

  play_marker_ok="no"
  if [[ -z "$play_marker" ]] || grep -Eq "$play_marker" "$log"; then
    play_marker_ok="yes"
  fi

  fps_metric="$(extract_fps_metric "$log")"
  fps_ok="no"
  if fps_in_range "$fps_metric"; then
    fps_ok="yes"
  fi

  glfw_warn="no"
  if grep -q "GLFW: Failed to determine Monitor to center Window" "$log"; then
    glfw_warn="yes"
  fi

  pbr_warn="no"
  if grep -q "pbr_metallic_roughness is not fully supported" "$log"; then
    pbr_warn="yes"
  fi

  extra_capture="no"
  extra_list=()
  for f in "${CAPTURE_POOL[@]}"; do
    if [[ "$f" == "$capture" ]]; then
      continue
    fi
    if [[ -f "$ROOT/$f" ]]; then
      extra_capture="yes"
      extra_list+=("$f")
    fi
  done

  gate="PASS"
  reasons=()

  if [[ "$code" -ne 0 ]]; then
    gate="FAIL"
    reasons+=("exit=$code")
  fi
  if [[ "$screenshot" != "yes" ]]; then
    gate="FAIL"
    reasons+=("missing_capture")
  fi
  if [[ "$REQUIRE_PROFILE" == "1" && "$profile_line" != "yes" ]]; then
    gate="FAIL"
    reasons+=("missing_profile_line")
  fi
  if [[ "$REQUIRE_CAPTURE_LOG" == "1" && "$capture_line" != "yes" ]]; then
    gate="FAIL"
    reasons+=("missing_capture_line")
  fi
  if [[ "$REQUIRE_PLAY_MARKER" == "1" && "$play_marker_ok" != "yes" ]]; then
    gate="FAIL"
    reasons+=("play_marker_not_found")
  fi
  if [[ "$REQUIRE_WINDOW_CLOSE_LOG" == "1" && "$window_closed" != "yes" ]]; then
    gate="FAIL"
    reasons+=("no_window_close_log")
  fi
  if [[ "$fps_ok" != "yes" ]]; then
    gate="FAIL"
    reasons+=("fps_out_of_range($fps_metric)")
  fi
  if [[ "$shot_bytes" -lt 8192 ]]; then
    gate="FAIL"
    reasons+=("capture_too_small($shot_bytes)")
  fi
  if [[ "$dim_ok" != "yes" ]]; then
    gate="FAIL"
    reasons+=("capture_dim_too_small(${shot_width}x${shot_height})")
  fi
  if [[ "$extra_capture" == "yes" ]]; then
    reasons+=("extra_capture:${extra_list[*]}")
  fi

  reason_str="ok"
  if [[ "${#reasons[@]}" -gt 0 ]]; then
    reason_str="$(IFS=','; echo "${reasons[*]}")"
  fi

  printf "game=%s\nexit_code=%s\nduration_s=%s\ncapture=%s\nfps=%s\ngate=%s\nreason=%s\n" \
    "$game" "$code" "$dur" "$capture" "$fps_metric" "$gate" "$reason_str" > "$meta"

  printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" \
    "$game" "$code" "$dur" "$screenshot" "$shot_bytes" "$shot_width" "$shot_height" "$dim_ok" "$window_closed" "$profile_line" "$capture_line" "$play_marker_ok" "$fps_metric" "$fps_ok" "$glfw_warn" "$pbr_warn" "$extra_capture" "$gate" "$reason_str" >> "$SUMMARY_TSV"

  echo "[done] $game code=$code fps=$fps_metric gate=$gate"
  if [[ "$gate" != "PASS" ]]; then
    all_passed=0
  fi

  pkill -f "moon run --manifest-path apps-native/moon.mod.json" >/dev/null 2>&1 || true
  pkill -f "timeout [0-9]+s moon run" >/dev/null 2>&1 || true
done

echo "[review] summary=$SUMMARY_TSV"
cat "$SUMMARY_TSV"
if [[ "$all_passed" -ne 1 ]]; then
  exit 2
fi
