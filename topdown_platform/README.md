# TopDown Platform (Core Runtime)

`topdown_platform` is the reusable ECS runtime for pure top-down traversal.
It is intentionally limited to:

- grid map parsing
- top-down movement + wall collision
- camera/background/HUD bootstrap
- player + generic actor visual synchronization

It does **not** include action-game semantics such as combat, skills, waves,
drops, enemy AI, or score loops. Those belong in higher-level packages such as
`topdown_action`.

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
- `player_archetype_id`: which archetype the player uses
- `archetypes`: shared visual + movement definitions
- `actor_spawns`: static actor placement by spawn tag
- `ui_theme`: title/font/colors/control hint
- `hooks`: optional lifecycle callbacks

## What belongs here

- tile layout
- wall collision
- sprite-strip based facing visuals
- spawn tags for non-player actors
- core top-down HUD and capture hooks

## What does not belong here

- melee/projectile combat
- enemy AI policies
- wave spawning
- drops and pickups
- run scoring / survival rules

Those should be layered on top of this package instead of being pushed back
into the core.
