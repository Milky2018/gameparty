///|
const PLATFORMER_FONT_FAMILY : String = "MGS1Codec"

///|
const PLATFORMER_FONT_PATH : String = "assets/shared/fonts/mgs1codec.ttf"

///|
let platformer_font_registered : Ref[Bool] = { val: false }

///|
let sprite_pack_state : Ref[SpritePack?] = { val: None }

///|
let image_cache : Map[String, @asset.ImageHandle] = Map::new()

///|
fn register_platformer_font_once() -> Unit {
  if platformer_font_registered.val {
    return
  }
  ignore(@asset.load_font(PLATFORMER_FONT_PATH, family=PLATFORMER_FONT_FAMILY))
  platformer_font_registered.val = true
}

///|
fn image_handle_for(path : String) -> @asset.ImageHandle {
  image_cache.get_or_init(path, fn() { @asset.load_image(path) })
}

///|
fn sprite_region_for_tile(kind : TileKind) -> SpriteRegion? {
  match sprite_pack_state.val {
    Some(pack) =>
      match kind {
        Ground => pack.tile_ground_region
        Brick => pack.tile_brick_region
        Pipe => pack.tile_pipe_region
        Spike => pack.tile_spike_region
        DashCrystal => pack.tile_question_region
        Spring => pack.tile_question_region
        QuestionMushroom => pack.tile_question_region
        QuestionFlower => pack.tile_question_region
        QuestionCoin => pack.tile_question_region
        UsedBlock => pack.tile_used_region
      }
    None => None
  }
}

///|
fn sprite_region_for_pipe_body() -> SpriteRegion? {
  match sprite_pack_state.val {
    Some(pack) =>
      match pack.tile_pipe_body_region {
        Some(region) => Some(region)
        None => pack.tile_pipe_region
      }
    None => None
  }
}

///|
fn sprite_regions_for_enemy(kind : EnemyKind) -> Array[SpriteRegion]? {
  match sprite_pack_state.val {
    Some(pack) =>
      match kind {
        Goomba => pack.enemy_goomba_regions
        Koopa => pack.enemy_koopa_regions
      }
    None => None
  }
}

///|
fn sprite_region_for_player_idle(facing_right : Bool) -> SpriteRegion? {
  match sprite_pack_state.val {
    Some(pack) =>
      if facing_right {
        pack.player_idle_right_region
      } else {
        pack.player_idle_left_region
      }
    None => None
  }
}

///|
fn sprite_regions_for_player_run(facing_right : Bool) -> Array[SpriteRegion]? {
  match sprite_pack_state.val {
    Some(pack) =>
      if facing_right {
        pack.player_run_right_regions
      } else {
        pack.player_run_left_regions
      }
    None => None
  }
}

///|
fn validate_player_sprite_pack(pack : SpritePack) -> Unit {
  if pack.player_idle_left_region is None ||
    pack.player_idle_right_region is None {
    abort(
      "platformer_platform: SpritePack requires both player_idle_left_region and player_idle_right_region",
    )
  }
  if pack.player_run_left_regions is None ||
    pack.player_run_right_regions is None {
    abort(
      "platformer_platform: SpritePack requires both player_run_left_regions and player_run_right_regions",
    )
  }
  match pack.player_run_left_regions {
    Some(regions) =>
      if regions.length() == 0 {
        abort("platformer_platform: player_run_left_regions must not be empty")
      }
    None => ()
  }
  match pack.player_run_right_regions {
    Some(regions) =>
      if regions.length() == 0 {
        abort("platformer_platform: player_run_right_regions must not be empty")
      }
    None => ()
  }
}

///|
fn sprite_path_for_background() -> String? {
  match sprite_pack_state.val {
    Some(pack) => pack.background_path
    None => None
  }
}

///|
fn ensure_entity_alive(entity : @entity.Entity) -> Unit {
  if !entity.is_alive() {
    entity.respawn()
  }
}

///|
fn set_entity_name(entity : @entity.Entity, value : String) -> Unit {
  @name.names().set(entity, @name.Name::new(value))
}

///|
fn tile_kind_name(kind : TileKind) -> String {
  match kind {
    Ground => "ground"
    Brick => "brick"
    Pipe => "pipe"
    Spike => "spike"
    DashCrystal => "dash_crystal"
    Spring => "spring"
    QuestionMushroom => "question_mushroom"
    QuestionFlower => "question_flower"
    QuestionCoin => "question_coin"
    UsedBlock => "used_block"
  }
}

///|
fn enemy_kind_name(kind : EnemyKind) -> String {
  match kind {
    Goomba => "goomba"
    Koopa => "koopa"
  }
}

///|
fn item_kind_name(kind : ItemKind) -> String {
  match kind {
    Mushroom => "mushroom"
    FireFlower => "fire_flower"
    Coin => "coin"
  }
}

///|
fn set_visibility(entity : @entity.Entity, visible : Bool) -> Unit {
  @visibility.visibilities().set(entity, if visible { Visible } else { Hidden })
}

///|
fn transform_2d(center : @math.Vec2, z : Double) -> @transform.Transform {
  {
    translation: @math.Vec3::new(center[X], center[Y], z),
    rotation: @math.Quat::identity(),
    scale: @math.Vec3::one(),
  }
}

///|
fn set_sprite_entity(
  entity : @entity.Entity,
  color : @render.Color,
  size : @math.Vec2,
  center : @math.Vec2,
  z : Double,
) -> Unit {
  ensure_entity_alive(entity)
  let sprite = @sprite.Sprite::from_color(color, size)
  sprite.anchor = @sprite.Anchor(@math.Vec2(-0.5, 0.5))
  let top_left = vec2(center[X] - size[X] * 0.5, center[Y] - size[Y] * 0.5)
  @sprite.sprites().set(entity, sprite)
  @transform.transforms().set(entity, transform_2d(top_left, z))
  set_visibility(entity, true)
}

///|
fn set_sprite_entity_with_image(
  entity : @entity.Entity,
  region : SpriteRegion?,
  fallback_color : @render.Color,
  size : @math.Vec2,
  center : @math.Vec2,
  z : Double,
  flip_x? : Bool = false,
) -> Unit {
  ensure_entity_alive(entity)
  let sprite = match region {
    Some(region) => {
      let sprite = @sprite.Sprite::from_image(
        image_handle_for(region.path),
        custom_size=Some(size),
      )
      sprite.rect = Some(region.rect)
      sprite
    }
    None => @sprite.Sprite::from_color(fallback_color, size)
  }
  sprite.flip_x = flip_x
  sprite.anchor = @sprite.Anchor(@math.Vec2(-0.5, 0.5))
  let top_left = vec2(center[X] - size[X] * 0.5, center[Y] - size[Y] * 0.5)
  @sprite.sprites().set(entity, sprite)
  @transform.transforms().set(entity, transform_2d(top_left, z))
  set_visibility(entity, true)
}

///|
fn set_sprite_entity_with_full_image(
  entity : @entity.Entity,
  image_path : String?,
  fallback_color : @render.Color,
  size : @math.Vec2,
  center : @math.Vec2,
  z : Double,
) -> Unit {
  ensure_entity_alive(entity)
  let sprite = match image_path {
    Some(path) =>
      @sprite.Sprite::from_image(image_handle_for(path), custom_size=Some(size))
    None => @sprite.Sprite::from_color(fallback_color, size)
  }
  sprite.anchor = @sprite.Anchor(@math.Vec2(-0.5, 0.5))
  let top_left = vec2(center[X] - size[X] * 0.5, center[Y] - size[Y] * 0.5)
  @sprite.sprites().set(entity, sprite)
  @transform.transforms().set(entity, transform_2d(top_left, z))
  set_visibility(entity, true)
}

///|
fn block_color(kind : TileKind) -> @render.Color {
  match kind {
    Ground => ground_color
    Brick => brick_color
    Pipe => pipe_color
    Spike => spike_color
    DashCrystal => dash_crystal_color
    Spring => spring_color
    QuestionMushroom => question_block_color
    QuestionFlower => question_block_color
    QuestionCoin => question_block_color
    UsedBlock => used_block_color
  }
}

///|
fn enemy_color(kind : EnemyKind) -> @render.Color {
  match kind {
    Goomba => enemy_sprite_color
    Koopa => rgb(90U, 174U, 84U)
  }
}

///|
fn item_color(kind : ItemKind) -> @render.Color {
  match kind {
    Mushroom => mushroom_color
    FireFlower => flower_color
    Coin => coin_color
  }
}

///|
fn set_text_entity(
  entity : @entity.Entity,
  content : String,
  center : @math.Vec2,
  font_size : String,
  color : @render.Color,
) -> Unit {
  ensure_entity_alive(entity)
  @ui.texts().set(entity, @ui.Text::new(content))
  @ui.text_fonts().set(entity, @ui.TextFont::from_css(font_size))
  @ui.text_colors().set(entity, @ui.TextColor::new(color))
  @ui.text_layouts().set(
    entity,
    @ui.TextLayout::new(align=Left, baseline=Top, wrap=WordWrap),
  )
  @text2d.text2ds().set(entity, @text2d.Text2d::new())
  @text2d.text_anchors().set(entity, @sprite.Anchor(@math.Vec2(-0.5, 0.5)))
  @transform.transforms().set(entity, transform_2d(center, 1000.0))
  set_visibility(entity, true)
}

///|
fn clear_static_entities() -> Unit {
  for entity in static_entities {
    entity.destroy()
  }
  static_entities.clear()
}

///|
fn clear_enemies() -> Unit {
  for entity, _ in enemy_entities {
    entity.destroy()
  }
  enemy_entities.clear()
  enemy_entities_order.clear()
}

///|
fn clear_items() -> Unit {
  for entity, _ in item_entities {
    entity.destroy()
  }
  item_entities.clear()
  item_entities_order.clear()
}

///|
fn clear_fireballs() -> Unit {
  for entity, _ in fireball_entities {
    entity.destroy()
  }
  fireball_entities.clear()
  fireball_entities_order.clear()
}

///|
fn spawn_background(level : LevelSpec) -> Unit {
  let sky = @entity.Entity::new()
  set_entity_name(sky, "level_sky")
  let mut has_custom_background = false
  match sprite_path_for_background() {
    Some(path) => {
      has_custom_background = true
      set_sprite_entity_with_full_image(
        sky,
        Some(path),
        background_color,
        vec2(level.world_width + 600.0, WORLD_HEIGHT + 240.0),
        vec2(level.world_width * 0.5, WORLD_HEIGHT * 0.42),
        -200.0,
      )
    }
    None =>
      set_sprite_entity(
        sky,
        background_color,
        vec2(level.world_width + 600.0, WORLD_HEIGHT + 240.0),
        vec2(level.world_width * 0.5, WORLD_HEIGHT * 0.42),
        -200.0,
      )
  }
  static_entities.push(sky)

  if has_custom_background {
    return
  }

  let near_hill = @entity.Entity::new()
  set_entity_name(near_hill, "level_near_hill")
  set_sprite_entity(
    near_hill,
    near_hill_color,
    vec2(level.world_width * 0.34, 170.0),
    vec2(level.world_width * 0.25, WORLD_HEIGHT - 85.0),
    -180.0,
  )
  static_entities.push(near_hill)

  let far_hill = @entity.Entity::new()
  set_entity_name(far_hill, "level_far_hill")
  set_sprite_entity(
    far_hill,
    far_hill_color,
    vec2(level.world_width * 0.22, 120.0),
    vec2(level.world_width * 0.68, WORLD_HEIGHT - 125.0),
    -190.0,
  )
  static_entities.push(far_hill)
}

///|
fn spawn_level_entities(level : LevelSpec) -> Unit {
  clear_static_entities()
  clear_enemies()
  clear_items()
  clear_fireballs()
  block_entities.clear()
  dash_crystal_respawn_timers.clear()
  spawn_background(level)
  for index, block in level.blocks {
    let entity = @entity.Entity::new()
    set_entity_name(entity, "block_\{index}_\{tile_kind_name(block.kind)}")
    set_sprite_entity_with_image(
      entity,
      sprite_region_for_tile(block.kind),
      block_color(block.kind),
      block.size,
      block.base_center,
      0.0,
    )
    static_entities.push(entity)
    block_entities.push(entity)
  }
  let goal_pole = @entity.Entity::new()
  set_entity_name(goal_pole, "goal_pole")
  set_sprite_entity(
    goal_pole,
    rgb(233U, 235U, 240U),
    vec2(14.0, level.goal_size[Y]),
    level.goal_center,
    1.0,
  )
  static_entities.push(goal_pole)
  let goal_flag = @entity.Entity::new()
  set_entity_name(goal_flag, "goal_flag")
  set_sprite_entity(
    goal_flag,
    flag_color,
    vec2(64.0, 36.0),
    vec2(level.goal_center[X] + 38.0, level.goal_center[Y] - 40.0),
    2.0,
  )
  static_entities.push(goal_flag)
  for spawn in level.enemy_spawns {
    spawn_enemy(spawn)
  }
}

///|
fn spawn_player(level : LevelSpec) -> Unit {
  let movement = current_movement_profile()
  let kept_score = player_state.val.score
  let kept_coins = player_state.val.coin_count
  let kept_power = player_state.val.power
  player_state.val = {
    center: level.player_spawn,
    velocity: @math.Vec2::zero(),
    facing_right: true,
    on_ground: false,
    coyote_timer: 0.0,
    jump_buffer: 0.0,
    hurt_timer: 0.0,
    startup_grace_timer: PLAYER_STARTUP_GRACE_SECONDS,
    fire_cooldown_timer: 0.0,
    dash_timer: 0.0,
    dash_cooldown_timer: 0.0,
    air_dashes_left: movement.max_air_dashes,
    wall_contact_dir: 0,
    dash_dir: @math.Vec2::zero(),
    wall_stamina: movement.wall_stamina_max,
    spring_cooldown_timer: 0.0,
    power: kept_power,
    score: kept_score,
    coin_count: kept_coins,
    alive: true,
  }
  ensure_entity_alive(player_entity)
  set_entity_name(player_entity, "player")
  let idle_region = sprite_region_for_player_idle(true)
  set_sprite_entity_with_image(
    player_entity,
    idle_region,
    player_sprite_color,
    vec2(PLAYER_WIDTH, PLAYER_HEIGHT_SMALL),
    level.player_spawn,
    5.0,
  )
}

///|
fn spawn_enemy(spawn : EnemySpawn) -> Unit {
  let speed = if spawn.kind == Koopa {
    ENEMY_MOVE_SPEED * 0.82
  } else {
    ENEMY_MOVE_SPEED
  }
  let entity = @entity.Entity::new()
  let enemy_index = enemy_entities_order.length()
  set_entity_name(entity, "enemy_\{enemy_index}_\{enemy_kind_name(spawn.kind)}")
  enemy_entities.set(entity, {
    kind: spawn.kind,
    center: spawn.center,
    velocity: vec2(if spawn.facing_right { speed } else { -speed }, 0.0),
    facing_right: spawn.facing_right,
    on_ground: false,
    alive: true,
    patrol_left: spawn.patrol_left,
    patrol_right: spawn.patrol_right,
  })
  enemy_entities_order.push(entity)
  let enemy_regions = sprite_regions_for_enemy(spawn.kind)
  let enemy_region = match enemy_regions {
    Some(regions) if regions.length() > 0 => Some(regions[0])
    _ => None
  }
  set_sprite_entity_with_image(
    entity,
    enemy_region,
    enemy_color(spawn.kind),
    vec2(ENEMY_WIDTH, ENEMY_HEIGHT),
    spawn.center,
    4.0,
  )
}

///|
fn spawn_item(
  kind : ItemKind,
  center : @math.Vec2,
  velocity? : @math.Vec2 = @math.Vec2::zero(),
  emerging? : Bool = false,
) -> Unit {
  let entity = @entity.Entity::new()
  let item_index = item_entities_order.length()
  set_entity_name(entity, "item_\{item_index}_\{item_kind_name(kind)}")
  item_entities.set(entity, {
    kind,
    center,
    velocity,
    emerging,
    emerge_target_y: center[Y] - TILE_SIZE,
    alive: true,
  })
  item_entities_order.push(entity)
  set_sprite_entity(
    entity,
    item_color(kind),
    vec2(ITEM_WIDTH, ITEM_HEIGHT),
    center,
    4.5,
  )
}

///|
fn spawn_player_fireball(center : @math.Vec2, facing_right : Bool) -> Unit {
  let entity = @entity.Entity::new()
  let fireball_index = fireball_entities_order.length()
  set_entity_name(entity, "fireball_\{fireball_index}")
  fireball_entities.set(entity, {
    center,
    velocity: vec2(
      if facing_right {
        FIREBALL_SPEED_X
      } else {
        -FIREBALL_SPEED_X
      },
      -120.0,
    ),
    lifetime: FIREBALL_MAX_LIFETIME_SECONDS,
    alive: true,
  })
  fireball_entities_order.push(entity)
  set_sprite_entity(
    entity,
    fireball_color,
    vec2(FIREBALL_SIZE, FIREBALL_SIZE),
    center,
    4.6,
  )
}

///|
fn set_message_visible(visible : Bool) -> Unit {
  set_visibility(hud_overlay_entity, visible)
  set_visibility(hud_message_entity, visible)
}

///|
fn setup_hud() -> Unit {
  let theme = current_plugin().ui_theme
  set_entity_name(hud_overlay_entity, "hud_overlay")
  set_sprite_entity(
    hud_overlay_entity,
    hud_color_dark,
    vec2(VIEWPORT_WIDTH, 120.0),
    vec2(VIEWPORT_WIDTH * 0.5, VIEWPORT_HEIGHT - 60.0),
    900.0,
  )
  set_entity_name(hud_title_entity, "hud_title")
  set_text_entity(
    hud_title_entity,
    theme.title,
    vec2(28.0, 24.0),
    "34px \{PLATFORMER_FONT_FAMILY}",
    hud_color_white,
  )
  set_entity_name(hud_sub_entity, "hud_sub")
  set_text_entity(
    hud_sub_entity,
    "",
    vec2(28.0, 68.0),
    "22px \{PLATFORMER_FONT_FAMILY}",
    hud_color_soft,
  )
  set_entity_name(hud_hint_entity, "hud_hint")
  set_text_entity(
    hud_hint_entity,
    "",
    vec2(28.0, VIEWPORT_HEIGHT - 36.0),
    "20px \{PLATFORMER_FONT_FAMILY}",
    hud_color_soft,
  )
  set_entity_name(hud_message_entity, "hud_message")
  set_text_entity(
    hud_message_entity,
    "",
    vec2(VIEWPORT_WIDTH * 0.5 - 220.0, VIEWPORT_HEIGHT * 0.5 - 30.0),
    "48px \{PLATFORMER_FONT_FAMILY}",
    hud_color_gold,
  )
  set_visibility(hud_overlay_entity, false)
  set_visibility(hud_message_entity, false)
}

///|
fn setup_audio() -> Unit {
  audio_bank.val = Some(create_audio_bank())
}

///|
fn set_current_level(level_index : Int) -> Unit {
  let level = level_specs[level_index]
  current_level.val = Some(level)
  solid_blocks.clear()
  for block in level.blocks {
    solid_blocks.push(block)
  }
  spawn_level_entities(level)
  spawn_player(level)
}

///|
fn startup_system(_world : @ecs.World) -> Unit {
  ignore(current_plugin())
  sprite_pack_state.val = current_plugin().sprites
  match sprite_pack_state.val {
    Some(pack) => validate_player_sprite_pack(pack)
    None => ()
  }
  register_platformer_font_once()
  set_profile_from_env()
  let startup_started_at = @time.elapsed()

  let levels_started_at = @time.elapsed()
  level_specs.clear()
  for level in current_plugin().levels {
    level_specs.push(level)
  }
  if level_specs.is_empty() {
    abort("platformer_platform: plugin has no levels")
  }
  profile_phase("startup/build-levels", levels_started_at)

  let hud_started_at = @time.elapsed()
  setup_hud()
  profile_phase("startup/hud", hud_started_at)

  let audio_started_at = @time.elapsed()
  setup_audio()
  profile_phase("startup/audio", audio_started_at)

  let capture_stage_started_at = @time.elapsed()
  capture_enabled.val = env_flag_enabled(DEBUG_CAPTURE_ENV)
  capture_started_at.val = @time.elapsed()
  capture_taken.val = false
  profile_phase("startup/capture-flags", capture_stage_started_at)

  let window_started_at = @time.elapsed()
  if @raylib.is_window_fullscreen() {
    @raylib.clear_window_state(@raylib.FlagFullscreenMode)
  }
  profile_phase("startup/window-state", window_started_at)

  let scene_started_at = @time.elapsed()
  ensure_entity_alive(camera_entity)
  set_entity_name(camera_entity, "camera")
  @camera.cameras().set(
    camera_entity,
    @camera.Camera::new(is_active=true, order=0),
  )
  @camera.camera2ds().set(camera_entity, @camera.Camera2d::new())
  @camera.orthographic_projections().set(
    camera_entity,
    @camera.OrthographicProjection::new(scale=1.0),
  )
  @transform.transforms().set(
    camera_entity,
    @transform.Transform::from_xyz(
      VIEWPORT_WIDTH * 0.5,
      CAMERA_TOP_LEFT_Y + VIEWPORT_HEIGHT * 0.5,
      999.0,
    ),
  )
  current_level_index.val = 0
  game_phase.val = Playing
  debug_overlay.val = false
  player_state.val.score = 0
  player_state.val.coin_count = 0
  player_state.val.power = Small
  set_current_level(current_level_index.val)
  run_hook_on_start()
  profile_phase("startup/first-scene", scene_started_at)
  if profile_enabled.val {
    profile_started_at.val = @time.elapsed()
    profile_last_report_at.val = profile_started_at.val
    profile_frame_count.val = 0
    profile_input_total.val = 0.0
    profile_update_total.val = 0.0
    profile_sync_total.val = 0.0
    profile_camera_total.val = 0.0
    profile_hud_total.val = 0.0
    profile_slowest_frame.val = 0.0
  }
  profile_phase("startup/total", startup_started_at)
}
