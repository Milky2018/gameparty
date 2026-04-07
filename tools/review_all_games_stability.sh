#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROUNDS="${ROUNDS:-1}"

games_for_group() {
  case "${GROUP:-}" in
    A) echo "angryrabbits bombman mooncraft" ;;
    B) echo "tankbattle supermario plantvszombies" ;;
    C) echo "bejeweled jackal kofarena" ;;
    D) echo "pacman3d thetawave coinpusher3d" ;;
    "")
      echo "angryrabbits bombman mooncraft tankbattle supermario plantvszombies bejeweled jackal kofarena pacman3d thetawave coinpusher3d"
      ;;
    *)
      echo "unsupported GROUP=${GROUP:-}" >&2
      exit 2
      ;;
  esac
}

if [[ "$ROUNDS" =~ ^[0-9]+$ ]] && [[ "$ROUNDS" -gt 0 ]]; then
  :
else
  echo "invalid ROUNDS=$ROUNDS" >&2
  exit 2
fi

if [[ "$#" -gt 0 ]]; then
  GAMES=("$@")
else
  read -r -a GAMES <<< "$(games_for_group)"
fi

OUT_ROOT="${OUT_ROOT:-$ROOT/review_logs/stability_$(date +%Y%m%d_%H%M%S)}"
mkdir -p "$OUT_ROOT"
AGG="$OUT_ROOT/aggregate.tsv"
printf "round\tstatus\texit\tfail_count\tfailed_games\tmin_fps\tround_dir\n" > "$AGG"

all_ok=1
for ((i = 1; i <= ROUNDS; i = i + 1)); do
  round_dir="$OUT_ROOT/round_$i"
  mkdir -p "$round_dir"
  echo "[stability] round=$i out_dir=$round_dir"

  set +e
  OUT_DIR="$round_dir" \
    RUN_TIMEOUT="${RUN_TIMEOUT:-90}" \
    FPS_MIN="${FPS_MIN:-60}" \
    FPS_MAX="${FPS_MAX:-65}" \
    PRECHECK="${PRECHECK:-0}" \
    LOCK_MODE="${LOCK_MODE:-1}" \
    REQUIRE_WINDOW_CLOSE_LOG="${REQUIRE_WINDOW_CLOSE_LOG:-0}" \
    bash "$ROOT/tools/review_all_games.sh" "${GAMES[@]}"
  run_code="$?"
  set -e

  summary="$round_dir/summary.tsv"
  if [[ ! -f "$summary" ]]; then
    printf "%s\tFAIL\t%s\t1\tmissing_summary\tn/a\t%s\n" "$i" "$run_code" "$round_dir" >> "$AGG"
    all_ok=0
    continue
  fi

  fail_count="$(awk -F'\t' 'NR>1 && $18=="FAIL"{c++} END{print c+0}' "$summary")"
  failed_games="$(awk -F'\t' 'NR>1 && $18=="FAIL"{print $1}' "$summary" | paste -sd',' -)"
  [[ -z "$failed_games" ]] && failed_games="-"
  min_fps="$(awk -F'\t' 'NR>1 && $13 ~ /^[0-9.]+$/ { if (min=="" || $13 < min) min=$13 } END { if (min=="") print "n/a"; else print min }' "$summary")"

  status="PASS"
  if [[ "$run_code" -ne 0 || "$fail_count" -ne 0 ]]; then
    status="FAIL"
    all_ok=0
  fi
  printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\n" "$i" "$status" "$run_code" "$fail_count" "$failed_games" "$min_fps" "$round_dir" >> "$AGG"
done

echo "[stability] aggregate=$AGG"
cat "$AGG"

if [[ "$all_ok" -ne 1 ]]; then
  exit 2
fi
