///|
pub fn meta(
  id : String,
  name : String,
  version? : String = "0.1.0",
) -> PluginMeta {
  { id, name, version }
}

///|
pub fn ui_theme(
  title : String,
  hud_hint? : String = "A/D or arrows: move  SPACE/UP: jump  X/CTRL: fire  R: restart  F3: debug  ESC: quit",
) -> UiTheme {
  { title, hud_hint }
}

///|
pub fn sprite_region(
  path : String,
  x : Double,
  y : Double,
  width : Double,
  height : Double,
) -> SpriteRegion {
  {
    path,
    rect: { position: @math.Vec2(x, y), size: @math.Vec2(width, height) },
  }
}

///|
pub fn sprite_pack(
  player_idle_region? : SpriteRegion? = None,
  player_run_regions? : Array[SpriteRegion]? = None,
  enemy_goomba_regions? : Array[SpriteRegion]? = None,
  enemy_koopa_regions? : Array[SpriteRegion]? = None,
  tile_ground_region? : SpriteRegion? = None,
  tile_brick_region? : SpriteRegion? = None,
  tile_pipe_region? : SpriteRegion? = None,
  tile_pipe_body_region? : SpriteRegion? = None,
  tile_spike_region? : SpriteRegion? = None,
  tile_question_region? : SpriteRegion? = None,
  tile_used_region? : SpriteRegion? = None,
  background_path? : String? = None,
) -> SpritePack {
  {
    player_idle_region,
    player_run_regions,
    enemy_goomba_regions,
    enemy_koopa_regions,
    tile_ground_region,
    tile_brick_region,
    tile_pipe_region,
    tile_pipe_body_region,
    tile_spike_region,
    tile_question_region,
    tile_used_region,
    background_path,
  }
}

///|
pub fn movement_profile(
  move_speed? : Double = PLAYER_MOVE_SPEED,
  jump_speed? : Double = PLAYER_JUMP_SPEED,
  gravity? : Double = PLAYER_GRAVITY,
  max_fall_speed? : Double = PLAYER_MAX_FALL_SPEED,
  coyote_time? : Double = COYOTE_TIME_SECONDS,
  jump_buffer? : Double = JUMP_BUFFER_SECONDS,
  max_air_dashes? : Int = 0,
  dash_speed? : Double = PLAYER_DASH_SPEED,
  dash_duration? : Double = PLAYER_DASH_SECONDS,
  dash_cooldown? : Double = PLAYER_DASH_COOLDOWN_SECONDS,
  allow_wall_jump? : Bool = false,
  wall_slide_speed? : Double = PLAYER_WALL_SLIDE_SPEED,
  wall_jump_speed_x? : Double = PLAYER_WALL_JUMP_SPEED_X,
  wall_jump_speed_y? : Double = PLAYER_WALL_JUMP_SPEED_Y,
  wall_stamina_max? : Double = PLAYER_WALL_STAMINA_MAX,
  wall_stamina_drain_per_second? : Double = PLAYER_WALL_STAMINA_DRAIN_PER_SECOND,
  wall_jump_stamina_cost? : Double = PLAYER_WALL_JUMP_STAMINA_COST,
  spring_boost_speed? : Double = PLAYER_SPRING_BOOST_SPEED,
) -> MovementProfile {
  {
    move_speed,
    jump_speed,
    gravity,
    max_fall_speed,
    coyote_time,
    jump_buffer,
    max_air_dashes,
    dash_speed,
    dash_duration,
    dash_cooldown,
    allow_wall_jump,
    wall_slide_speed,
    wall_jump_speed_x,
    wall_jump_speed_y,
    wall_stamina_max,
    wall_stamina_drain_per_second,
    wall_jump_stamina_cost,
    spring_boost_speed,
  }
}

///|
pub fn block(
  center : @math.Vec2,
  size : @math.Vec2,
  kind : TileKind,
  payload? : ItemKind? = None,
) -> SolidBlock {
  { base_center: center, size, kind, payload }
}

///|
pub fn enemy_spawn(
  center : @math.Vec2,
  patrol_left : Double,
  patrol_right : Double,
  facing_right? : Bool = true,
  kind? : EnemyKind = Goomba,
) -> EnemySpawn {
  { kind, center, patrol_left, patrol_right, facing_right }
}

///|
pub fn level(
  name : String,
  player_spawn : @math.Vec2,
  goal_center : @math.Vec2,
  goal_size : @math.Vec2,
  world_width : Double,
  blocks : Array[SolidBlock],
  enemy_spawns? : Array[EnemySpawn] = [],
) -> LevelSpec {
  {
    name,
    player_spawn,
    goal_center,
    goal_size,
    world_width,
    blocks,
    enemy_spawns,
  }
}

///|
pub fn hooks(
  on_run_start? : ((RuntimeSnapshot) -> Unit)? = None,
  on_enemy_stomped? : ((RuntimeSnapshot, EnemyKind) -> Unit)? = None,
  on_item_collected? : ((RuntimeSnapshot, ItemKind) -> Unit)? = None,
  on_level_won? : ((RuntimeSnapshot, Int) -> Unit)? = None,
) -> PlatformerHooks {
  { on_run_start, on_enemy_stomped, on_item_collected, on_level_won }
}

///|
pub fn plugin(
  meta : PluginMeta,
  levels : Array[LevelSpec],
  ui_theme : UiTheme,
  sprites? : SpritePack? = None,
  movement? : MovementProfile? = None,
  hooks? : PlatformerHooks? = None,
) -> PlatformerPluginDef {
  { meta, levels, ui_theme, sprites, movement, hooks }
}
