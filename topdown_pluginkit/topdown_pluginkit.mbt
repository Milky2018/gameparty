///|
pub let summer_ground_43 : String = "assets/top-down-summer/Top-Down Simple Summer_Ground 43.png"

///|
pub fn visual(
  path : String,
  scale? : Double = 1.0,
  y_offset? : Double = 0.0,
) -> @topdown_platform.ImageVisualDef {
  { path, scale, y_offset }
}

///|
pub fn sprite_strip(
  image : String,
  scale? : Double = 2.4,
  fps? : Double = 12.0,
  frame_width? : Double = 480.0,
  frame_height? : Double = 480.0,
  columns? : Int = 4,
  frame_count? : Int = 12,
) -> @topdown_platform.SpriteAnimDef {
  { image, frame_width, frame_height, columns, frame_count, fps, scale }
}

///|
pub fn humanoid_running_sprites(
  asset_dir : String,
  scale? : Double = 2.4,
  fps? : Double = 12.0,
) -> @topdown_platform.DirectionalSprites {
  {
    up: sprite_strip("\{asset_dir}/Back - Running.png", scale~, fps~),
    down: sprite_strip("\{asset_dir}/Front - Running.png", scale~, fps~),
    left: sprite_strip("\{asset_dir}/Left - Running.png", scale~, fps~),
    right: sprite_strip("\{asset_dir}/Right - Running.png", scale~, fps~),
  }
}

///|
pub fn floor_tile(floor_path : String) -> @topdown_platform.TileOrSpawnRule {
  {
    kind: @topdown_platform.Floor,
    floor_image: Some(visual(floor_path)),
    prop_image: None,
    blocks: false,
    enemy_spawn_tag: None,
  }
}

///|
pub fn wall_tile(
  floor_path : String,
  prop_path : String,
  prop_scale? : Double = 1.2,
  prop_y_offset? : Double = -10.0,
) -> @topdown_platform.TileOrSpawnRule {
  {
    kind: @topdown_platform.Wall,
    floor_image: Some(visual(floor_path)),
    prop_image: Some(
      visual(prop_path, scale=prop_scale, y_offset=prop_y_offset),
    ),
    blocks: true,
    enemy_spawn_tag: None,
  }
}

///|
pub fn player_spawn_tile(
  floor_path : String,
) -> @topdown_platform.TileOrSpawnRule {
  {
    kind: @topdown_platform.PlayerSpawn,
    floor_image: Some(visual(floor_path)),
    prop_image: None,
    blocks: false,
    enemy_spawn_tag: None,
  }
}

///|
pub fn enemy_spawn_tile(
  floor_path : String,
  spawn_tag : String,
) -> @topdown_platform.TileOrSpawnRule {
  {
    kind: @topdown_platform.EnemySpawn,
    floor_image: Some(visual(floor_path)),
    prop_image: None,
    blocks: false,
    enemy_spawn_tag: Some(spawn_tag),
  }
}

///|
pub fn wave_entry(
  archetype_id : String,
  count : Int,
  spawn_interval : Double,
  spawn_tag? : String? = None,
) -> @topdown_platform.WaveEntryDef {
  { archetype_id, count, spawn_interval, spawn_tag }
}

///|
pub fn ui_theme(
  title : String,
  font_path : String,
  font_family : String,
  hud_color_css : String,
  control_hint : String,
) -> @topdown_platform.UiThemeDef {
  { title, font_path, font_family, hud_color_css, control_hint }
}
