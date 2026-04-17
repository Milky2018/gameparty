#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ASSET_DIR="$ROOT_DIR/assets/jackal"

required=(
  "NES - Jackal - Playable Characters - Jackal Squad.png"
  "NES - Jackal - Enemies - Grenadier Jeep.png"
  "NES - Jackal - Enemies - Light Tank.png"
  "NES - Jackal - Enemies - Medium Tank.png"
  "NES - Jackal - Enemies - Heavy Tank.png"
  "NES - Jackal - Enemies - Assault Transport Helicopter.png"
  "NES - Jackal - Enemies - Bomber.png"
  "NES - Jackal - Enemies - BM-13 Katyusha.png"
  "NES - Jackal - Enemies - Land Mine.png"
  "NES - Jackal - Miscellaneous - POWs.png"
)

missing=0
for file in "${required[@]}"; do
  if [[ ! -f "$ASSET_DIR/$file" ]]; then
    echo "[missing] $ASSET_DIR/$file"
    missing=1
  fi
done

if [[ "$missing" -ne 0 ]]; then
  echo
  echo "One or more source sheets are missing."
  echo "Download them manually, place them into: $ASSET_DIR"
  exit 1
fi

echo "All required source sheets are present in: $ASSET_DIR"
python3 "$ROOT_DIR/tools/import_jackal_sprites.py"
