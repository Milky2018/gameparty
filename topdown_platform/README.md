# TopDown Platform (Plugin Runtime)

`topdown_platform` is a reusable ECS runtime for top-down action games.
You provide one typed plugin definition, and the platform handles:

- fixed-step loop (`60Hz`)
- movement + collision
- melee/projectile combat
- wave spawning
- pickup/drop flow
- HUD synchronization

## Public Entry

- `@topdown_platform.run(plugin)`
- `@topdown_platform.validate_plugin(plugin)`

## Plugin Contract

Create one exported value:

```moonbit
pub let plugin : @topdown_platform.TopDownPluginDef = { ... }
```

Main sections:

- `meta`: id/name/version
- `map`: grid rows + legend + `default_floor_image`
- `archetypes`: player/enemy actor definitions
- `skills`: melee/projectile definitions
- `waves`: spawn timeline
- `drops`: pickup tables
- `progression`: run duration + player archetype
- `ui_theme`: title/font/colors/control hint
- `hooks`: optional callbacks

## Reuse Features (for multiple game styles)

- **Spawn tags**
  - Set `enemy_spawn_tag` in map legend `EnemySpawn` tiles.
  - Set `WaveEntryDef.spawn_tag` to route waves to specific lanes/zones.
- **Enemy AI modes**
  - `Chase`
  - `HoldDistance` (`preferred_range > 0`)
  - `Wander`
- **Theme-level control hint**
  - Configure `ui_theme.control_hint` per game without touching runtime code.
- **Map default floor image**
  - `map.default_floor_image` avoids runtime hardcoded fallback visuals.

## What belongs to platform vs plugin

- Platform:
  - all systems and update order
  - runtime state machines
  - collision/combat/spawn/drop execution
  - validation rules
- Plugin:
  - data and balancing
  - map layout
  - enemy composition
  - skills/drops/waves
  - optional hook side-effects

## Validation

`validate_plugin` checks:

- required map/archetype/skill/drop references
- map legend coverage
- spawn tag consistency
- numeric range constraints
- UI/theme required fields

Invalid plugin data fails fast before runtime starts.
