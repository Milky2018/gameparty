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

///|
pub fn map_def(
  rows : Array[String],
  legend : Map[Char, @topdown_platform.TileOrSpawnRule],
  tile_size? : Double = 64.0,
  default_floor_path? : String = summer_ground_43,
) -> @topdown_platform.MapDef {
  { tile_size, default_floor_image: visual(default_floor_path), rows, legend }
}

///|
pub fn humanoid_archetype(
  id : String,
  sprite_dir : String,
  ai_mode : @topdown_platform.EnemyAiMode,
  preferred_range : Double,
  max_hp : Int,
  move_speed : Double,
  radius : Double,
  touch_damage : Int,
  score_value : Int,
  drop_table_id? : String? = None,
  primary_skill_id? : String? = None,
  secondary_skill_id? : String? = None,
  sprite_scale? : Double = 2.4,
  sprite_fps? : Double = 12.0,
) -> @topdown_platform.ArchetypeDef {
  {
    id,
    ai_mode,
    preferred_range,
    max_hp,
    move_speed,
    radius,
    touch_damage,
    score_value,
    sprites: humanoid_running_sprites(
      sprite_dir,
      scale=sprite_scale,
      fps=sprite_fps,
    ),
    drop_table_id,
    primary_skill_id,
    secondary_skill_id,
  }
}

///|
pub fn melee_skill(
  id : String,
  cooldown : Double,
  damage : Int,
  range : Double,
) -> @topdown_platform.SkillDef {
  {
    id,
    kind: @topdown_platform.Melee,
    cooldown,
    damage,
    range,
    projectile_speed: 0.0,
    projectile_radius: 0.0,
  }
}

///|
pub fn projectile_skill(
  id : String,
  cooldown : Double,
  damage : Int,
  range : Double,
  projectile_speed : Double,
  projectile_radius : Double,
) -> @topdown_platform.SkillDef {
  {
    id,
    kind: @topdown_platform.Projectile,
    cooldown,
    damage,
    range,
    projectile_speed,
    projectile_radius,
  }
}

///|
pub fn drop_item(
  id : String,
  image : String,
  weight : Int,
  heal? : Int = 0,
  score_bonus? : Int = 0,
) -> @topdown_platform.DropItemDef {
  { id, image, weight, heal, score_bonus }
}

///|
pub fn drop_table(
  id : String,
  chance : Double,
  items : Array[@topdown_platform.DropItemDef],
) -> @topdown_platform.DropTableDef {
  { id, chance, items }
}
