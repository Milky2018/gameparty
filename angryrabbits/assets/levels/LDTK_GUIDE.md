# AngryRabbits LDtk Level Guide

This package reads level data from an LDtk project file via `selene/ldtk`.

## File

- Default level file: `angryrabbits/assets/levels/level_01.ldtk`
- Loader behavior: use the first level from `project.indexed_levels()`

## Coordinate System

- `1 LDtk pixel = 1 game world unit`
- Recommended level size: `640 x 480`

## Required Level Field

- `max_shots` (`Int`): rabbit count for the level.

## Required Entity Layer

Use one `Entities` layer. Entity `identifier` values are parsed as follows.

### Meta entities

1. `SlingshotAnchor`
- `px` is used directly as anchor position.

2. `RabbitSpawn`
- `px` is used directly as rabbit spawn position.

### Decor entities

1. `BackgroundRect`
- Uses `px` as top-left position.
- Uses `width/height` as size.
- Optional fields:
  - `color` (`String`, e.g. `rgb(183, 225, 255)`)
  - `zindex` (`Int`)

2. `GroundRect`
- Same rules as `BackgroundRect`.

3. `HillCircle`
- Uses entity bounds to derive center/radius.
- Optional fields:
  - `color` (`String`)
  - `zindex` (`Int`)
  - `radius` (`Float`, fallback only when bounds are zero)

### Gameplay entities

1. `Block`
- Uses entity bounds for center/size.
- Optional fields:
  - `color` (`String`)

2. `Target`
- Uses entity bounds for center/radius.
- Optional fields:
  - `color` (`String`)
  - `radius` (`Float`, fallback only when bounds are zero)

## Fallback Behavior

- Invalid/empty LDtk file: fall back to built-in default level.
- Missing entities for blocks/targets: built-in default blocks/targets are used.
- Missing decor/meta entities: built-in default decor/spawn values are used.
