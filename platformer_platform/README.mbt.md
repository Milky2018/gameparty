# platformer_platform

Data-driven 2D side-scrolling action platform runtime for Selene ECS.

## Usage

Define a plugin and call `@platformer_platform.run(plugin)`:

```mbt nocheck
let my_plugin = @platformer_platform.plugin(
  @platformer_platform.meta("my-platformer", "My Platformer"),
  levels,
  @platformer_platform.ui_theme("MY PLATFORMER"),
  movement=Some(
    @platformer_platform.movement_profile(
      max_air_dashes=1,
      allow_wall_jump=true,
    ),
  ),
  hooks=Some(
    @platformer_platform.hooks(
      on_item_collected=Some((snapshot, item) => {
        println("item=\{item} score=\{snapshot.score}")
      }),
    ),
  ),
)

@platformer_platform.run(my_plugin)
```

## Plugin Data Model

- `PlatformerPluginDef`
  - `meta`
  - `levels` (`Array[LevelSpec]`)
  - `ui_theme`
  - `hooks` (optional)
- `LevelSpec`
  - `player_spawn`, `goal_center`, `goal_size`, `world_width`
  - `blocks` (`Array[SolidBlock]`)
  - `enemy_spawns` (`Array[EnemySpawn]`)

## Helper API

- `meta(id, name, version?)`
- `ui_theme(title, hud_hint?)`
- `movement_profile(...)`
- `block(center, size, kind, payload?)`
- `enemy_spawn(center, patrol_left, patrol_right, facing_right?, kind?)`
- `level(name, player_spawn, goal_center, goal_size, world_width, blocks, enemy_spawns?)`
- `hooks(on_run_start?, on_enemy_stomped?, on_item_collected?, on_level_won?)`
- `plugin(meta, levels, ui_theme, movement?, hooks?)`
