# Milky2018/gameparty

A MoonBit game collection built on top of [Selene](https://github.com/moonbit-community/selene) and the raylib backend.

This repository currently contains these playable prototypes and ports:

- `thetawave`: an ongoing MoonBit/Selene port of the upstream Thetawave project.
- `pacman3d`: a native 3D Pac-Man-style game built with Selene `render3d`.
- `angryrabbits`: a physics-based slingshot prototype.
- `bombman`: a Bomberman-style 2D prototype with single-player, co-op, and versus modes.
- `mooncraft`: a Selene ECS rewrite of the Mooncraft prototype with chunk streaming and first-person block interaction.

## Included Packages

- `cmd/thetawave`: run Thetawave directly.
- `cmd/pacman3d`: run Pacman 3D directly.
- `cmd/angryrabbits`: run Angry Rabbits directly.
- `cmd/bombman`: run Bombman directly.
- `cmd/mooncraft`: run Mooncraft directly.
- `thetawave/`: Thetawave package and assets.
- `pacman3d/`: Pacman 3D package and assets.
- `angryrabbits/`: Angry Rabbits package and assets.
- `bombman/`: Bombman package and assets.
- `mooncraft_core/`: pure MoonBit world/block/item/generation core reused by Mooncraft.
- `mooncraft/`: Selene ECS runtime, assets, and tests for Mooncraft.

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
```

## Check

```bash
moon check --debug
moon check --release
moon test
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

## Notes

- The module `preferred-target` is `native`.
- The games currently assume a desktop/native runtime.
