# AngryRabbits LDtk Level Guide

This package reads level data from an LDtk project file via `selene/ldtk`.

## File

- Default level file: `angryrabbits/assets/levels/level_01.ldtk`
- Loader behavior: use the first level from `project.indexed_levels()`
- Keep `externalLevels` disabled in LDtk for now. AngryRabbits currently loads a single in-file `.ldtk` project.

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
- Required fields:
  - `color` (`String`, e.g. `rgb(183, 225, 255)`)
  - `zindex` (`Int`)

2. `GroundRect`
- Same rules as `BackgroundRect`.

3. `HillCircle`
- Uses entity bounds to derive center/radius.
- Required fields:
  - `color` (`String`)
  - `zindex` (`Int`)

### Gameplay entities

1. `Block`
- Uses entity bounds for center/size.
- Required fields:
  - `color` (`String`)

2. `Target`
- Uses entity bounds for center/radius.
- Required fields:
  - `color` (`String`)

## Validation Behavior

- Invalid JSON, unreadable asset bytes, non-UTF-8 text, missing required fields, or missing required entities: the game enters its in-game error scene and prints the exact load error.
- No silent fallback values are applied during level loading.
- `Block` and `Target` entities are read only from the visible `Entities` layer.
