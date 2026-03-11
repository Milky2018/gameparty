# AngryRabbits Tiled Level Guide

This package loads level data from a Tiled `.tmj` map through `selene/tiled`.

## Coordinate System

- Map orientation: `orthogonal`
- Units: `1 tiled pixel = 1 game world unit`
- Viewport reference: `640 x 480`

## Required Map Properties

- `max_shots` (`int`): rabbit count for this level.

## Parsed Object Types

The loader parses all object layers and reads objects by `type`.
Layer names are for organization only.

### Meta

1. `slingshot_anchor`
- Recommended object kind: `point`
- Uses object position as slingshot anchor.

2. `rabbit_spawn`
- Recommended object kind: `point`
- Uses object position as rabbit spawn position.

### Decor

1. `background_rect`
- Recommended object kind: rectangle
- Uses `x/y/width/height`
- Properties:
  - `color` (`string`, e.g. `rgb(183, 225, 255)`)
  - `zindex` (`int`)

2. `ground_rect`
- Same format as `background_rect`

3. `hill_circle`
- Recommended object kind: ellipse
- Uses ellipse center and radius
- Properties:
  - `color` (`string`)
  - `zindex` (`int`)

### Gameplay

1. `block`
- Recommended object kind: rectangle
- Uses `x/y/width/height`
- Properties:
  - `color` (`string`)

2. `target`
- Recommended object kind: ellipse
- Uses center/radius from object bounds
- Properties:
  - `color` (`string`)
  - `radius` (`float`, optional fallback when no bounds)

## Recommended Layer Layout

- `Meta` (object layer)
- `Decor` (object layer)
- `Blocks` (object layer)
- `Targets` (object layer)

## Fallback Behavior

- Missing or invalid map: loader falls back to built-in default level.
- Missing block/target objects: uses built-in block/target defaults.
- Missing decor/meta objects: uses built-in decor and spawn defaults.

## Current Template

Use this file as the starting point:
- `angryrabbits/assets/levels/level_01.tmj`
