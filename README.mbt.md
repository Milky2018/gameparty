# Milky2018/gameparty

A MoonBit game collection built on top of [Selene](https://github.com/moonbit-community/selene) and the raylib backend.

This repository currently contains these playable prototypes and ports:

- `thetawave`: an ongoing MoonBit/Selene port of the upstream Thetawave project.
- `pacman3d`: a native 3D Pac-Man-style game built with Selene `render3d`.
- `angryrabbits`: a physics-based slingshot prototype.
- `bombman`: a Bomberman-style 2D prototype with single-player, co-op, and versus modes.
- `mooncraft`: a Selene ECS rewrite of the Mooncraft prototype with chunk streaming and first-person block interaction.
- `coinpusher3d`: a 3D roguelike coin-pusher run with chest upgrades and physics-driven scoring.
- `tankbattle`: a 2D tank-battle prototype built with pure primitives and procedural audio.
- `supermario`: a 2D side-scroller prototype built with pure primitives and procedural audio.
- `celeste`: a Celeste-style 2D platformer built as a plugin on `platformer_platform`.
- `plantvszombies`: a lane-defense prototype built with pure primitives and procedural audio.
- `bejeweled`: a match-3 prototype built with pure primitives and procedural audio.
- `jackal`: a top-down run-and-gun prototype built with pure primitives and procedural audio.
- `kofarena`: a 2D versus-fighter prototype built with pure primitives and procedural audio.
- `netplay`: a standalone networking layer subpackage for host-authoritative input sync (library-only, no `cmd/*` entry).
- `platformer_platform`: a reusable side-scrolling platform action runtime (data + hooks plugin style).
- `topdown_platform`: a reusable top-down data+hooks platform package.
- `topdown_pluginkit`: shared plugin helpers for fast top-down data authoring.
- `topdown_rogue_proto`: the first data-driven ARPG roguelite plugin on top of `topdown_platform`.

## Included Packages

- `cmd/thetawave`: run Thetawave directly.
- `cmd/pacman3d`: run Pacman 3D directly.
- `cmd/angryrabbits`: run Angry Rabbits directly.
- `cmd/bombman`: run Bombman directly.
- `cmd/mooncraft`: run Mooncraft directly.
- `cmd/coinpusher3d`: run CoinPusher3D directly.
- `cmd/tankbattle`: run TankBattle directly.
- `cmd/supermario`: run SuperMario directly.
- `cmd/celeste`: run Celeste directly.
- `cmd/plantvszombies`: run PlantVsZombies directly.
- `cmd/bejeweled`: run Bejeweled directly.
- `cmd/jackal`: run Jackal directly.
- `cmd/kofarena`: run KOFArena directly.
- `cmd/topdown_rogue_proto`: run the top-down roguelite prototype directly.
- `assets/`: shared asset root (`assets/<game>/...`).
- `thetawave/`: Thetawave package and tests.
- `pacman3d/`: Pacman 3D package and tests.
- `angryrabbits/`: Angry Rabbits package and tests.
- `bombman/`: Bombman package and tests.
- `mooncraft_core/`: pure MoonBit world/block/item/generation core reused by Mooncraft.
- `mooncraft/`: Selene ECS runtime and tests for Mooncraft.
- `coinpusher3d/`: CoinPusher3D package and tests.
- `tankbattle/`: TankBattle package and tests.
- `supermario/`: SuperMario package and tests.
- `celeste/`: Celeste plugin package and tests.
- `plantvszombies/`: PlantVsZombies package and tests.
- `bejeweled/`: Bejeweled package and tests.
- `jackal/`: Jackal package and tests.
- `kofarena/`: KOFArena package and tests.
- `netplay/`: shared networking-layer package for future multiplayer integration.
- `platformer_platform/`: reusable side-scroller platform package and tests.
- `topdown_platform/`: reusable top-down platform package and tests.
- `topdown_pluginkit/`: shared helper package for topdown plugin construction.
- `topdown_rogue_proto/`: first plugin package and tests.

## Requirements

- MoonBit toolchain
- Native target toolchain for your platform

## Run

Run an individual game directly:

```bash
moon run cmd/thetawave
moon run cmd/pacman3d
moon run cmd/angryrabbits
moon run cmd/bombman
moon run cmd/mooncraft
moon run cmd/coinpusher3d
moon run cmd/tankbattle
moon run cmd/supermario
moon run cmd/celeste
moon run cmd/plantvszombies
moon run cmd/bejeweled
moon run cmd/jackal
moon run cmd/kofarena
moon run cmd/topdown_rogue_proto
```

## Web (Emscripten)

You can build web outputs from MoonBit native-generated C artifacts (without changing MoonBit target).

```bash
# Build one game to web/<game>/index.html
scripts/build_web_game.sh bejeweled

# Build all cmd/* games
scripts/build_web_all_games.sh

# Optional release build
scripts/build_web_game.sh bejeweled --release
scripts/build_web_all_games.sh --release

# Regenerate gallery page (auto-called by build_web_game.sh)
scripts/gen_web_gallery.sh

# Serve and open gallery
cd web && python3 -m http.server 4173
# open http://127.0.0.1:4173/
```

Notes:

- Requires `emcc` (`brew install emscripten` on macOS).
- Current build chain uses `native -> C -> emcc` and keeps MoonBit target as `native`.
- Use `EMCC_OPT_LEVEL` to tune compile speed/size, e.g. `EMCC_OPT_LEVEL=-O0 scripts/build_web_all_games.sh`.

`bombman` netplay is now fully menu-driven (no `BOMBMAN_NET_*` env vars):

1. In main menu, enter `NETWORK BATTLE`.
2. Host chooses `CREATE ROOM`, picks mode `A/B` and a port, then waits in lobby.
3. Client chooses `JOIN ROOM`, enters host IP and port.
4. After handshake, round starts automatically and client syncs host level/mode.

Lobby shows both detected LAN IPv4 and `127.0.0.1` for local testing.

## Check

```bash
moon check --debug
moon check --release
moon test
```

## Runtime QA Review

Run the unified gameplay QA gate (run + capture + FPS + warning scan):

```bash
tools/review_all_games.sh
```

Useful overrides:

```bash
# Review subset only
tools/review_all_games.sh mooncraft bombman pacman3d

# Tune thresholds/timeouts
FPS_MIN=58 FPS_MAX=64 RUN_TIMEOUT=60 PRECHECK=0 tools/review_all_games.sh
```

## Asset Loading

All builds now load assets directly from the filesystem under the root `assets/` directory.

- Game-local assets: `assets/<game>/...`
- Cross-game shared assets: `assets/shared/...`

For native distribution, copy the `assets/` directory next to the executable (or keep a working directory that can resolve `assets/...` paths).

## Current Status

### Thetawave

- Ported into the shared `gameparty` repository.
- Uses filesystem assets from `assets/thetawave/...` in both debug and release.
- Remaining Selene-vs-upstream parity gaps are tracked in [PORTING_BLOCKERS.md](/Users/zhengyu/Documents/projects/gameparty/thetawave/PORTING_BLOCKERS.md).

### Pacman 3D

- Runs as a true 3D game using Selene `render3d`.
- Uses textured floor, wall, and ceiling tiles sourced from the Pac-Man tileset.
- Uses filesystem assets from `assets/pacman3d/...` in both debug and release.

### Mooncraft

- Reuses `mooncraft_core` for world generation, blocks, items, and chunk mesh building.
- Reimplements the runtime in Selene ECS instead of reusing the upstream browser runtime.
- Current scope is a first-person creative prototype with chunk streaming, block breaking/placing, a hotbar, an inventory catalog, and demo glTF entities.
- No save system is implemented yet.

### New Primitive-Only Prototypes

- `tankbattle`, `supermario`, `bejeweled`, and `kofarena` intentionally avoid external art assets.
- `celeste` currently follows the same primitive-only visual style and focuses on movement feel.
- Their runtime visuals are built from Selene/raylib primitive drawing and mesh/material paths.
- Their runtime audio uses procedural synthesis (`Wave::load_sound` from generated sample buffers), not packaged music/sfx files.

### TopDown Platformized Prototypes

- `jackal` and `plantvszombies` are now reset onto `topdown_platform` as data-driven plugins.
- Both reuse platform systems (movement/collision/combat/waves/drops/HUD) and keep only game-specific content data in their own package.

## Engine Issues

- Known Selene/raylib integration issues and local workarounds are tracked in [ENGINE_BUGS.md](/Users/zhengyu/Documents/projects/gameparty/ENGINE_BUGS.md).

## Notes

- The module `preferred-target` is `native`.
- The games currently assume a desktop/native runtime.
