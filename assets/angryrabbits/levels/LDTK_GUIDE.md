# AngryRabbits LDtk Level Guide

This package reads level data from an LDtk project file via `selene/ldtk`.

## File

- Default level file: `assets/angryrabbits/levels/level_01.ldtk`
- Loader behavior: use the first level from `project.indexed_levels()`
- Keep `externalLevels` disabled in LDtk for now. AngryRabbits currently loads a single in-file `.ldtk` project.

## Coordinate System

- `1 LDtk pixel = 1 game world unit`
- Recommended level size: `640 x 480`

## Required Level Field

- `max_shots` (`Int`): rabbit count for the level.

## Required Entity Layers

Use:
- `Entities` layer for gameplay/meta entities.
- `Decor` layer for background/decor entities (`BackgroundRect`, `GroundRect`, `HillCircle`).

Entity `identifier` values are parsed as follows.

### Meta entities

1. `SlingshotAnchor`
- `px` is used directly as anchor position.

2. `SlingshotFrontStick`
- `px` is used directly as the front slingshot sprite top-left position.

3. `SlingshotBackStick`
- `px` is used directly as the back slingshot sprite top-left position.

4. `RabbitSpawn`
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

2. `Target`
- Uses entity bounds for center/radius.

## Validation Behavior

- Invalid JSON, unreadable asset bytes, non-UTF-8 text, missing required fields, or missing required entities (including both slingshot stick entities): the game enters its in-game error scene and prints the exact load error.
- Invalid JSON, unreadable asset bytes, non-UTF-8 text, missing required fields, or missing required entities (including both slingshot stick entities): the game enters its in-game error scene and prints the exact load error.
- No silent fallback values are applied during level loading.
- `Block` and `Target` entities are read only from the visible `Entities` layer.
- Decor entities are read only from the visible `Decor` layer.
