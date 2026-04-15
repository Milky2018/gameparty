#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

DIST_DIR="$ROOT_DIR/dist/web"
mkdir -p "$DIST_DIR"

GAME_ROWS=""
while IFS= read -r game; do
  [[ -z "$game" ]] && continue
  if [[ -f "$DIST_DIR/$game.html" ]]; then
    GAME_ROWS+=$'\n'"        <div class=\"card ready\">"
    GAME_ROWS+=$'\n'"          <h3>$game</h3>"
    GAME_ROWS+=$'\n'"          <p>Status: Ready</p>"
    GAME_ROWS+=$'\n'"          <a href=\"./$game.html\">Play</a>"
    GAME_ROWS+=$'\n'"        </div>"
  else
    GAME_ROWS+=$'\n'"        <div class=\"card pending\">"
    GAME_ROWS+=$'\n'"          <h3>$game</h3>"
    GAME_ROWS+=$'\n'"          <p>Status: Not built</p>"
    GAME_ROWS+=$'\n'"          <code>scripts/build_web_game.sh $game</code>"
    GAME_ROWS+=$'\n'"        </div>"
  fi
done < <(
  find "$ROOT_DIR/apps-web" -mindepth 1 -maxdepth 1 -type d \
    -exec test -f "{}/moon.pkg" ';' \
    -exec test -f "{}/main.mbt" ';' \
    -exec basename {} \; | sort
)

cat >"$DIST_DIR/index.html" <<HTML
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
        background:
          radial-gradient(circle at top, rgba(130, 179, 255, 0.12), transparent 36%),
          linear-gradient(180deg, #101621, #0a0f18 72%);
        color: #dce6ff;
      }
      .wrap {
        max-width: 1120px;
        margin: 0 auto;
        padding: 28px;
      }
      h1 {
        margin: 0 0 10px;
        font-size: 30px;
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
        border: 1px solid #2a3447;
        border-radius: 12px;
        padding: 16px;
        background: rgba(18, 26, 39, 0.92);
        box-shadow: 0 12px 24px rgba(0, 0, 0, 0.18);
      }
      .card.ready {
        border-color: #385c7a;
      }
      .card.pending {
        border-color: #4b3540;
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
        background: #0c121c;
        border: 1px solid #253042;
        border-radius: 6px;
        padding: 2px 6px;
        color: #d1dcf6;
      }
    </style>
  </head>
  <body>
    <main class="wrap">
      <h1>Gameparty Web Gallery</h1>
      <p class="hint">Build outputs live in <code>dist/web</code>. Serve that directory to run the WebGPU entries.</p>
      <p class="hint">Example: <code>cd dist/web && python3 -m http.server 4173</code></p>
      <section class="grid">$GAME_ROWS
      </section>
    </main>
  </body>
</html>
HTML

touch "$DIST_DIR/.nojekyll"

echo "[web-gallery] generated: $DIST_DIR/index.html"
