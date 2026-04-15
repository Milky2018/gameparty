# TopDown Action Platform

`topdown_action` is the reusable ECS runtime for top-down action games.
It sits above `topdown_platform` conceptually and owns action-specific
semantics such as:

- melee / projectile combat
- enemy AI modes
- wave spawning
- drops / pickups
- score and run phases

## Public Entry

- `@topdown_action.run(plugin)`
- `@topdown_action.validate_plugin(plugin)`

`topdown_action` reuses the core spatial model from
`topdown_platform`:

- `meta`
- `map`
- directional sprite strips
- UI theme
- actor-spawn tile tags

## Plugin Contract

Create one exported value:

```moonbit
pub let plugin : @topdown_action.TopDownPluginDef = { ... }
```

Main sections:

- `meta`
- `map`
- `archetypes`
- `skills`
- `waves`
- `drops`
- `progression`
- `ui_theme`
- `hooks`

## Boundary

What stays in `topdown_platform`:

- ASCII map parsing
- top-down movement + wall collision
- actor-facing visuals
- `ActorSpawn` tile semantics

What `topdown_action` adds:

- combat skills
- enemy AI
- wave spawning
- loot / pickups
- score / win / lose phases
