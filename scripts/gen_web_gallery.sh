#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

mkdir -p "$ROOT_DIR/web"

GAME_ROWS=""
while IFS= read -r game; do
  [[ -z "$game" ]] && continue
  if [[ -f "$ROOT_DIR/web/$game/index.html" ]]; then
    GAME_ROWS+=$'\n'"        <div class=\"card\">"
    GAME_ROWS+=$'\n'"          <h3>$game</h3>"
    GAME_ROWS+=$'\n'"          <p>Status: Ready</p>"
    GAME_ROWS+=$'\n'"          <a href=\"./$game/index.html\">Play</a>"
    GAME_ROWS+=$'\n'"        </div>"
  else
    GAME_ROWS+=$'\n'"        <div class=\"card\">"
    GAME_ROWS+=$'\n'"          <h3>$game</h3>"
    GAME_ROWS+=$'\n'"          <p>Status: Not built</p>"
    GAME_ROWS+=$'\n'"          <code>scripts/build_web_game.sh $game</code>"
    GAME_ROWS+=$'\n'"        </div>"
  fi
done < <(
  find "$ROOT_DIR/cmd" -mindepth 1 -maxdepth 1 -type d \
    -exec test -f "{}/moon.pkg" ';' \
    -exec basename {} \; | sort
)

cat >"$ROOT_DIR/web/index.html" <<HTML
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>Gameparty Web Gallery</title>
    <style>
      :root {
        color-scheme: dark;
      }
      body {
        margin: 0;
        font-family: Menlo, Consolas, monospace;
        background: #151922;
        color: #dce6ff;
      }
      .wrap {
        max-width: 1100px;
        margin: 0 auto;
        padding: 28px;
      }
      h1 {
        margin: 0 0 10px;
        font-size: 28px;
      }
      .hint {
        opacity: 0.82;
        margin: 0 0 18px;
      }
      .grid {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
        gap: 14px;
      }
      .card {
        border: 1px solid #2b3448;
        background: #1d2433;
        border-radius: 10px;
        padding: 14px;
      }
      .card h3 {
        margin: 0 0 8px;
      }
      .card p {
        margin: 0 0 10px;
      }
      a {
        color: #9ec8ff;
        text-decoration: none;
        font-weight: 700;
      }
      a:hover {
        text-decoration: underline;
      }
      code {
        display: inline-block;
        background: #0f1420;
        border: 1px solid #2a3140;
        border-radius: 6px;
        padding: 2px 6px;
        color: #d1dcf6;
      }
    </style>
  </head>
  <body>
    <main class="wrap">
      <h1>Gameparty Web Gallery</h1>
      <p class="hint">Serve <code>web/</code> and open this page in a browser.</p>
      <p class="hint">Example: <code>cd web && python3 -m http.server 4173</code></p>
      <section class="grid">$GAME_ROWS
      </section>
    </main>
  </body>
  </html>
HTML

echo "[web-gallery] generated: $ROOT_DIR/web/index.html"
