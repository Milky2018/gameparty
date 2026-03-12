# Milky2018/gameparty

A MoonBit game collection built on top of [Selene](https://github.com/moonbit-community/selene) and the raylib backend.

This repository currently contains three playable games:

- `thetawave`: an ongoing MoonBit/Selene port of the upstream Thetawave project.
- `pacman3d`: a native 3D Pac-Man-style game built with Selene `render3d`.
- `angryrabbits`: a simple physics-based slingshot prototype.

## Included Packages

- `cmd/thetawave`: run Thetawave directly.
- `cmd/pacman3d`: run Pacman 3D directly.
- `cmd/angryrabbits`: run Angry Rabbits directly.
- `thetawave/`: Thetawave port package and assets.
- `pacman3d/`: Pacman 3D package and assets.
- `angryrabbits/`: Angry Rabbits package and assets.

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
```

## Check

```bash
moon check --debug
moon check --release
moon test
```

## Asset Loading

Both game packages use pre-build asset generation:

- `debug` builds read assets from the local `assets/` directories.
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

## Notes

- The module `preferred-target` is `native`.
- The games currently assume a desktop/native runtime.
