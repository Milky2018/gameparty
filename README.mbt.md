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
- `plantvszombies`: a lane-defense prototype built with pure primitives and procedural audio.
- `bejeweled`: a match-3 prototype built with pure primitives and procedural audio.
- `jackal`: a top-down run-and-gun prototype built with pure primitives and procedural audio.
- `kofarena`: a 2D versus-fighter prototype built with pure primitives and procedural audio.
- `netplay`: a standalone networking layer subpackage for host-authoritative input sync (library-only, no `cmd/*` entry).

## Included Packages

- `cmd/thetawave`: run Thetawave directly.
- `cmd/pacman3d`: run Pacman 3D directly.
- `cmd/angryrabbits`: run Angry Rabbits directly.
- `cmd/bombman`: run Bombman directly.
- `cmd/mooncraft`: run Mooncraft directly.
- `cmd/coinpusher3d`: run CoinPusher3D directly.
- `cmd/tankbattle`: run TankBattle directly.
- `cmd/supermario`: run SuperMario directly.
- `cmd/plantvszombies`: run PlantVsZombies directly.
- `cmd/bejeweled`: run Bejeweled directly.
- `cmd/jackal`: run Jackal directly.
- `cmd/kofarena`: run KOFArena directly.
- `thetawave/`: Thetawave package and assets.
- `pacman3d/`: Pacman 3D package and assets.
- `angryrabbits/`: Angry Rabbits package and assets.
- `bombman/`: Bombman package and assets.
- `mooncraft_core/`: pure MoonBit world/block/item/generation core reused by Mooncraft.
- `mooncraft/`: Selene ECS runtime, assets, and tests for Mooncraft.
- `coinpusher3d/`: CoinPusher3D package, assets, and tests.
- `tankbattle/`: TankBattle package and tests.
- `supermario/`: SuperMario package and tests.
- `plantvszombies/`: PlantVsZombies package and tests.
- `bejeweled/`: Bejeweled package and tests.
- `jackal/`: Jackal package and tests.
- `kofarena/`: KOFArena package and tests.
- `netplay/`: shared networking-layer package for future multiplayer integration.

## Requirements

- MoonBit toolchain
- Native target toolchain for your platform
- `selene-embed-assets` available in `PATH`

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
moon run cmd/plantvszombies
moon run cmd/bejeweled
moon run cmd/jackal
moon run cmd/kofarena
```

`bombman` local netplay bridge (host/client loopback in one process, for development):

```bash
BOMBMAN_NET_LOCAL_LOOP=1 moon run cmd/bombman
```

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

Game packages use pre-build asset generation:

- `debug` builds read assets from local `assets/` directories.
- `release` builds embed assets through `selene-embed-assets` and `:embed`.

The generated embedded asset blobs are excluded from module publishing in [moon.mod.json](/Users/zhengyu/Documents/projects/gameparty/moon.mod.json).

## Current Status

### Thetawave

- Ported into the shared `gameparty` repository.
- Uses embedded assets in `release` mode and local assets in `debug` mode.
- Remaining Selene-vs-upstream parity gaps are tracked in [PORTING_BLOCKERS.md](/Users/zhengyu/Documents/projects/gameparty/thetawave/PORTING_BLOCKERS.md).

### Pacman 3D

- Runs as a true 3D game using Selene `render3d`.
- Uses textured floor, wall, and ceiling tiles sourced from the Pac-Man tileset.
- Shares the release embedded asset flow with the rest of the repository.

### Mooncraft

- Reuses `mooncraft_core` for world generation, blocks, items, and chunk mesh building.
- Reimplements the runtime in Selene ECS instead of reusing the upstream browser runtime.
- Current scope is a first-person creative prototype with chunk streaming, block breaking/placing, a hotbar, an inventory catalog, and demo glTF entities.
- No save system is implemented yet.

### New Primitive-Only Prototypes

- `tankbattle`, `supermario`, `plantvszombies`, `bejeweled`, `jackal`, and `kofarena` intentionally avoid external art assets.
- Their runtime visuals are built from Selene/raylib primitive drawing and mesh/material paths.
- Their runtime audio uses procedural synthesis (`Wave::load_sound` from generated sample buffers), not packaged music/sfx files.

## Engine Issues

- Known Selene/raylib integration issues and local workarounds are tracked in [ENGINE_BUGS.md](/Users/zhengyu/Documents/projects/gameparty/ENGINE_BUGS.md).

## Notes

- The module `preferred-target` is `native`.
- The games currently assume a desktop/native runtime.
