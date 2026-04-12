///|
const VIEWPORT_WIDTH : Double = 1280.0

///|
const VIEWPORT_HEIGHT : Double = 720.0

///|
const FPS : UInt = 60

///|
const TILE_SIZE : Double = 48.0

///|
const PLAYER_WIDTH : Double = 34.0

///|
const PLAYER_HEIGHT_SMALL : Double = 44.0

///|
const PLAYER_HEIGHT_BIG : Double = 74.0

///|
const PLAYER_MOVE_SPEED : Double = 236.0

///|
const PLAYER_JUMP_SPEED : Double = 620.0

///|
const PLAYER_GRAVITY : Double = 1600.0

///|
const PLAYER_MAX_FALL_SPEED : Double = 980.0

///|
const PLAYER_HURT_INVULN_SECONDS : Double = 1.15

///|
const PLAYER_FIRE_COOLDOWN_SECONDS : Double = 0.28

///|
const PLAYER_STARTUP_GRACE_SECONDS : Double = 2.4

///|
const COYOTE_TIME_SECONDS : Double = 0.11

///|
const JUMP_BUFFER_SECONDS : Double = 0.12

///|
const PLAYER_DASH_SPEED : Double = 560.0

///|
const PLAYER_DASH_SECONDS : Double = 0.18

///|
const PLAYER_DASH_COOLDOWN_SECONDS : Double = 0.15

///|
const PLAYER_WALL_SLIDE_SPEED : Double = 180.0

///|
const PLAYER_WALL_JUMP_SPEED_X : Double = 310.0

///|
const PLAYER_WALL_JUMP_SPEED_Y : Double = 620.0

///|
const PLAYER_WALL_STAMINA_MAX : Double = 100.0

///|
const PLAYER_WALL_STAMINA_DRAIN_PER_SECOND : Double = 48.0

///|
const PLAYER_WALL_JUMP_STAMINA_COST : Double = 32.0

///|
const PLAYER_SPRING_BOOST_SPEED : Double = 820.0

///|
const PLAYER_SPRING_COOLDOWN_SECONDS : Double = 0.12

///|
const DASH_CRYSTAL_RESPAWN_SECONDS : Double = 3.0

///|
const ENEMY_WIDTH : Double = 34.0

///|
const ENEMY_HEIGHT : Double = 34.0

///|
const ENEMY_MOVE_SPEED : Double = 96.0

///|
const ENEMY_GRAVITY : Double = 1600.0

///|
const ENEMY_MAX_FALL_SPEED : Double = 980.0

///|
const ITEM_WIDTH : Double = 30.0

///|
const ITEM_HEIGHT : Double = 30.0

///|
const ITEM_GRAVITY : Double = 1500.0

///|
const ITEM_MOVE_SPEED : Double = 130.0

///|
const FIREBALL_SIZE : Double = 18.0

///|
const FIREBALL_SPEED_X : Double = 420.0

///|
const FIREBALL_BOUNCE_VELOCITY : Double = 380.0

///|
const FIREBALL_GRAVITY : Double = 1500.0

///|
const FIREBALL_MAX_LIFETIME_SECONDS : Double = 4.0

///|
const SCORE_STOMP_ENEMY : Int = 100

///|
const SCORE_COLLECT_COIN : Int = 100

///|
const SCORE_HIT_GOAL : Int = 1000

///|
const DEBUG_CAPTURE_ENV : String = "PLATFORMER_CAPTURE"

///|
const DEBUG_CAPTURE_PATH : String = "platformer_capture.png"

///|
const DEBUG_CAPTURE_DELAY_SECONDS : Double = 2.0

///|
const PROFILE_ENV : String = "PLATFORMER_PROFILE"

///|
const WORLD_HEIGHT : Double = 12.0 * TILE_SIZE

///|
const CAMERA_TOP_LEFT_Y : Double = -96.0

///|
let hud_color_white : @render.Color = rgb(247U, 248U, 251U)

///|
let hud_color_soft : @render.Color = rgb(219U, 228U, 238U)

///|
let hud_color_gold : @render.Color = rgb(255U, 229U, 168U)

///|
let hud_color_dark : @render.Color = rgb(20U, 28U, 40U, a=0.82)

///|
pub(all) enum GamePhase {
  Playing
  Won
  Lost
} derive(Eq)

///|
pub(all) enum PowerState {
  Small
  Big
  Fire
} derive(Eq)

///|
pub(all) enum ItemKind {
  Mushroom
  FireFlower
  Coin
} derive(Eq)

///|
pub(all) enum TileKind {
  Ground
  Brick
  Pipe
  Spike
  DashCrystal
  Spring
  QuestionMushroom
  QuestionFlower
  QuestionCoin
  UsedBlock
} derive(Eq)

///|
pub(all) enum EnemyKind {
  Goomba
  Koopa
} derive(Eq)

///|
pub(all) struct SolidBlock {
  base_center : @math.Vec2D
  size : @math.Vec2D
  mut kind : TileKind
  payload : ItemKind?
}

///|
pub(all) struct EnemySpawn {
  kind : EnemyKind
  center : @math.Vec2D
  patrol_left : Double
  patrol_right : Double
  facing_right : Bool
}

///|
pub(all) struct LevelSpec {
  name : String
  player_spawn : @math.Vec2D
  goal_center : @math.Vec2D
  goal_size : @math.Vec2D
  world_width : Double
  blocks : Array[SolidBlock]
  enemy_spawns : Array[EnemySpawn]
}

///|
pub(all) struct PluginMeta {
  id : String
  name : String
  version : String
}

///|
pub(all) struct UiTheme {
  title : String
  hud_hint : String
}

///|
pub(all) struct SpritePack {
  player_idle_path : String?
  enemy_goomba_path : String?
  enemy_koopa_path : String?
  tile_ground_path : String?
  tile_brick_path : String?
  tile_pipe_path : String?
  tile_spike_path : String?
  tile_question_path : String?
  tile_used_path : String?
  background_path : String?
}

///|
pub(all) struct MovementProfile {
  move_speed : Double
  jump_speed : Double
  gravity : Double
  max_fall_speed : Double
  coyote_time : Double
  jump_buffer : Double
  max_air_dashes : Int
  dash_speed : Double
  dash_duration : Double
  dash_cooldown : Double
  allow_wall_jump : Bool
  wall_slide_speed : Double
  wall_jump_speed_x : Double
  wall_jump_speed_y : Double
  wall_stamina_max : Double
  wall_stamina_drain_per_second : Double
  wall_jump_stamina_cost : Double
  spring_boost_speed : Double
}

///|
pub(all) struct RuntimeSnapshot {
  phase : GamePhase
  level_index : Int
  level_name : String
  power : PowerState
  score : Int
  coins : Int
  enemies_alive : Int
}

///|
pub(all) struct PlatformerHooks {
  on_run_start : ((RuntimeSnapshot) -> Unit)?
  on_enemy_stomped : ((RuntimeSnapshot, EnemyKind) -> Unit)?
  on_item_collected : ((RuntimeSnapshot, ItemKind) -> Unit)?
  on_level_won : ((RuntimeSnapshot, Int) -> Unit)?
}

///|
pub(all) struct PlatformerPluginDef {
  meta : PluginMeta
  levels : Array[LevelSpec]
  ui_theme : UiTheme
  sprites : SpritePack?
  movement : MovementProfile?
  hooks : PlatformerHooks?
}

///|
priv struct PlayerState {
  mut center : @math.Vec2D
  mut velocity : @math.Vec2D
  mut facing_right : Bool
  mut on_ground : Bool
  mut coyote_timer : Double
  mut jump_buffer : Double
  mut hurt_timer : Double
  mut startup_grace_timer : Double
  mut fire_cooldown_timer : Double
  mut dash_timer : Double
  mut dash_cooldown_timer : Double
  mut air_dashes_left : Int
  mut wall_contact_dir : Int
  mut dash_dir : @math.Vec2D
  mut wall_stamina : Double
  mut spring_cooldown_timer : Double
  mut power : PowerState
  mut score : Int
  mut coin_count : Int
  mut alive : Bool
}

///|
priv struct EnemyState {
  kind : EnemyKind
  mut center : @math.Vec2D
  mut velocity : @math.Vec2D
  mut facing_right : Bool
  mut on_ground : Bool
  mut alive : Bool
  patrol_left : Double
  patrol_right : Double
}

///|
priv struct ItemState {
  kind : ItemKind
  mut center : @math.Vec2D
  mut velocity : @math.Vec2D
  mut emerging : Bool
  emerge_target_y : Double
  mut alive : Bool
}

///|
priv struct FireballState {
  mut center : @math.Vec2D
  mut velocity : @math.Vec2D
  mut lifetime : Double
  mut alive : Bool
}

///|
priv struct AudioBank {
  jump : @raylib.Sound
  stomp : @raylib.Sound
  hit : @raylib.Sound
  goal : @raylib.Sound
  collect : @raylib.Sound
  shoot : @raylib.Sound
}

///|
let game_phase : Ref[GamePhase] = { val: Playing }

///|
let current_level_index : Ref[Int] = { val: 0 }

///|
let debug_overlay : Ref[Bool] = { val: false }

///|
let capture_enabled : Ref[Bool] = { val: false }

///|
let capture_started_at : Ref[Double] = { val: 0.0 }

///|
let capture_taken : Ref[Bool] = { val: false }

///|
let profile_enabled : Ref[Bool] = { val: false }

///|
let profile_started_at : Ref[Double] = { val: 0.0 }

///|
let profile_last_report_at : Ref[Double] = { val: 0.0 }

///|
let profile_frame_count : Ref[Int] = { val: 0 }

///|
let profile_input_total : Ref[Double] = { val: 0.0 }

///|
let profile_update_total : Ref[Double] = { val: 0.0 }

///|
let profile_sync_total : Ref[Double] = { val: 0.0 }

///|
let profile_camera_total : Ref[Double] = { val: 0.0 }

///|
let profile_hud_total : Ref[Double] = { val: 0.0 }

///|
let profile_slowest_frame : Ref[Double] = { val: 0.0 }

///|
let player_state : Ref[PlayerState] = {
  val: {
    center: @math.Vec2D::zero(),
    velocity: @math.Vec2D::zero(),
    facing_right: true,
    on_ground: false,
    coyote_timer: 0.0,
    jump_buffer: 0.0,
    hurt_timer: 0.0,
    startup_grace_timer: 0.0,
    fire_cooldown_timer: 0.0,
    dash_timer: 0.0,
    dash_cooldown_timer: 0.0,
    air_dashes_left: 0,
    wall_contact_dir: 0,
    dash_dir: @math.Vec2D::zero(),
    wall_stamina: 0.0,
    spring_cooldown_timer: 0.0,
    power: Small,
    score: 0,
    coin_count: 0,
    alive: true,
  },
}

///|
let level_specs : Array[LevelSpec] = []

///|
let current_level : Ref[LevelSpec?] = { val: None }

///|
let solid_blocks : Array[SolidBlock] = []

///|
let block_entities : Array[@entity.Entity] = []

///|
let dash_crystal_respawn_timers : Map[Int, Double] = Map::new()

///|
let enemy_entities : Map[@entity.Entity, EnemyState] = Map::new()

///|
let static_entities : Array[@entity.Entity] = []

///|
let enemy_entities_order : Array[@entity.Entity] = []

///|
let item_entities : Map[@entity.Entity, ItemState] = Map::new()

///|
let item_entities_order : Array[@entity.Entity] = []

///|
let fireball_entities : Map[@entity.Entity, FireballState] = Map::new()

///|
let fireball_entities_order : Array[@entity.Entity] = []

///|
let player_entity : @entity.Entity = @entity.Entity::new()

///|
let camera_entity : @entity.Entity = @entity.Entity::new()

///|
let hud_title_entity : @entity.Entity = @entity.Entity::new()

///|
let hud_sub_entity : @entity.Entity = @entity.Entity::new()

///|
let hud_hint_entity : @entity.Entity = @entity.Entity::new()

///|
let hud_message_entity : @entity.Entity = @entity.Entity::new()

///|
let hud_overlay_entity : @entity.Entity = @entity.Entity::new()

///|
let player_sprite_color : @render.Color = { r: 53U, g: 112U, b: 222U, a: 1.0 }

///|
let enemy_sprite_color : @render.Color = { r: 214U, g: 86U, b: 69U, a: 1.0 }

///|
let brick_color : @render.Color = { r: 198U, g: 113U, b: 53U, a: 1.0 }

///|
let ground_color : @render.Color = { r: 97U, g: 170U, b: 60U, a: 1.0 }

///|
let pipe_color : @render.Color = { r: 58U, g: 149U, b: 86U, a: 1.0 }

///|
let spike_color : @render.Color = { r: 214U, g: 76U, b: 102U, a: 1.0 }

///|
let dash_crystal_color : @render.Color = { r: 82U, g: 220U, b: 255U, a: 1.0 }

///|
let spring_color : @render.Color = { r: 255U, g: 112U, b: 120U, a: 1.0 }

///|
let question_block_color : @render.Color = { r: 240U, g: 182U, b: 53U, a: 1.0 }

///|
let used_block_color : @render.Color = { r: 130U, g: 120U, b: 104U, a: 1.0 }

///|
let mushroom_color : @render.Color = { r: 230U, g: 88U, b: 75U, a: 1.0 }

///|
let flower_color : @render.Color = { r: 255U, g: 221U, b: 85U, a: 1.0 }

///|
let coin_color : @render.Color = { r: 248U, g: 214U, b: 86U, a: 1.0 }

///|
let fireball_color : @render.Color = { r: 252U, g: 104U, b: 64U, a: 1.0 }

///|
let flag_color : @render.Color = { r: 246U, g: 211U, b: 80U, a: 1.0 }

///|
let background_color : @render.Color = { r: 131U, g: 203U, b: 255U, a: 1.0 }

///|
let far_hill_color : @render.Color = { r: 87U, g: 165U, b: 105U, a: 1.0 }

///|
let near_hill_color : @render.Color = { r: 67U, g: 150U, b: 87U, a: 1.0 }

///|
let audio_bank : Ref[AudioBank?] = { val: None }

///|
let last_hud_title_text : Ref[String] = { val: "" }

///|
let last_hud_sub_text : Ref[String] = { val: "" }

///|
let last_hud_hint_text : Ref[String] = { val: "" }

///|
let last_hud_message_text : Ref[String] = { val: "" }

///|
let active_plugin : Ref[PlatformerPluginDef?] = { val: None }

///|
fn current_plugin() -> PlatformerPluginDef {
  match active_plugin.val {
    Some(plugin) => plugin
    None => abort("platformer_platform: no plugin configured")
  }
}

///|
fn current_plugin_or_none() -> PlatformerPluginDef? {
  active_plugin.val
}

///|
fn default_movement_profile() -> MovementProfile {
  {
    move_speed: PLAYER_MOVE_SPEED,
    jump_speed: PLAYER_JUMP_SPEED,
    gravity: PLAYER_GRAVITY,
    max_fall_speed: PLAYER_MAX_FALL_SPEED,
    coyote_time: COYOTE_TIME_SECONDS,
    jump_buffer: JUMP_BUFFER_SECONDS,
    max_air_dashes: 0,
    dash_speed: PLAYER_DASH_SPEED,
    dash_duration: PLAYER_DASH_SECONDS,
    dash_cooldown: PLAYER_DASH_COOLDOWN_SECONDS,
    allow_wall_jump: false,
    wall_slide_speed: PLAYER_WALL_SLIDE_SPEED,
    wall_jump_speed_x: PLAYER_WALL_JUMP_SPEED_X,
    wall_jump_speed_y: PLAYER_WALL_JUMP_SPEED_Y,
    wall_stamina_max: PLAYER_WALL_STAMINA_MAX,
    wall_stamina_drain_per_second: PLAYER_WALL_STAMINA_DRAIN_PER_SECOND,
    wall_jump_stamina_cost: PLAYER_WALL_JUMP_STAMINA_COST,
    spring_boost_speed: PLAYER_SPRING_BOOST_SPEED,
  }
}

///|
fn current_movement_profile() -> MovementProfile {
  match current_plugin().movement {
    Some(profile) => profile
    None => default_movement_profile()
  }
}

///|
fn alive_enemy_count() -> Int {
  let mut count = 0
  for _, enemy in enemy_entities {
    if enemy.alive {
      count = count + 1
    }
  }
  count
}

///|
fn make_runtime_snapshot() -> RuntimeSnapshot {
  let level_name = match current_level.val {
    Some(level) => level.name
    None => "-"
  }
  {
    phase: game_phase.val,
    level_index: current_level_index.val,
    level_name,
    power: player_state.val.power,
    score: player_state.val.score,
    coins: player_state.val.coin_count,
    enemies_alive: alive_enemy_count(),
  }
}

///|
fn run_hook_on_start() -> Unit {
  match current_plugin_or_none() {
    Some(plugin) =>
      match plugin.hooks {
        Some(hooks) =>
          match hooks.on_run_start {
            Some(f) => f(make_runtime_snapshot())
            None => ()
          }
        None => ()
      }
    None => ()
  }
}

///|
fn run_hook_on_enemy_stomped(kind : EnemyKind) -> Unit {
  match current_plugin_or_none() {
    Some(plugin) =>
      match plugin.hooks {
        Some(hooks) =>
          match hooks.on_enemy_stomped {
            Some(f) => f(make_runtime_snapshot(), kind)
            None => ()
          }
        None => ()
      }
    None => ()
  }
}

///|
fn run_hook_on_item_collected(kind : ItemKind) -> Unit {
  match current_plugin_or_none() {
    Some(plugin) =>
      match plugin.hooks {
        Some(hooks) =>
          match hooks.on_item_collected {
            Some(f) => f(make_runtime_snapshot(), kind)
            None => ()
          }
        None => ()
      }
    None => ()
  }
}

///|
fn run_hook_on_level_won(level_index : Int) -> Unit {
  match current_plugin_or_none() {
    Some(plugin) =>
      match plugin.hooks {
        Some(hooks) =>
          match hooks.on_level_won {
            Some(f) => f(make_runtime_snapshot(), level_index)
            None => ()
          }
        None => ()
      }
    None => ()
  }
}

///|
fn rgb(r : UInt, g : UInt, b : UInt, a? : Double = 1.0) -> @render.Color {
  { r, g, b, a }
}

///|
fn vec2(x : Double, y : Double) -> @math.Vec2D {
  @math.Vec2D(x, y)
}

///|
fn rect_from_center(center : @math.Vec2D, size : @math.Vec2D) -> @math.Rect {
  { position: center - size.scalar_mul(0.5), size }
}

///|
fn clamp_double(value : Double, min_ : Double, max_ : Double) -> Double {
  if value < min_ {
    min_
  } else if value > max_ {
    max_
  } else {
    value
  }
}

///|
fn env_flag_enabled(name : String) -> Bool {
  match @env.get_env_var(name) {
    Some(value) =>
      value == "1" ||
      value == "true" ||
      value == "yes" ||
      value == "on" ||
      value == "TRUE" ||
      value == "YES" ||
      value == "ON"
    None => false
  }
}

///|
const PROFILE_REPORT_SECONDS : Double = 0.75

///|
fn set_profile_from_env() -> Unit {
  profile_enabled.val = env_flag_enabled(PROFILE_ENV)
}

///|
fn profile_phase(label : String, started_at : Double) -> Unit {
  if profile_enabled.val {
    let elapsed = @time.elapsed() - started_at
    if label == "input" {
      profile_input_total.val += elapsed
    } else if label == "update" {
      profile_update_total.val += elapsed
    } else if label == "sync" {
      profile_sync_total.val += elapsed
    } else if label == "camera" {
      profile_camera_total.val += elapsed
    } else if label == "hud" {
      profile_hud_total.val += elapsed
    }
  }
}

///|
fn maybe_report_profile() -> Unit {
  if !profile_enabled.val {
    return
  }
  let now = @time.elapsed()
  if now - profile_last_report_at.val < PROFILE_REPORT_SECONDS {
    return
  }
  let window = now - profile_last_report_at.val
  if window <= 0.0 {
    return
  }
  let frame_count = if profile_frame_count.val <= 0 {
    1
  } else {
    profile_frame_count.val
  }
  let frame_count_f = frame_count.to_double()
  let fps = frame_count_f / window
  let min_fps = if profile_slowest_frame.val > 0.0 {
    1.0 / profile_slowest_frame.val
  } else {
    0.0
  }
  let input_ms = profile_input_total.val / frame_count_f * 1000.0
  let update_ms = profile_update_total.val / frame_count_f * 1000.0
  let sync_ms = profile_sync_total.val / frame_count_f * 1000.0
  let camera_ms = profile_camera_total.val / frame_count_f * 1000.0
  let hud_ms = profile_hud_total.val / frame_count_f * 1000.0
  let slowest_frame_ms = profile_slowest_frame.val * 1000.0
  let phase_text = match game_phase.val {
    Playing => "Playing"
    Won => "Won"
    Lost => "Lost"
  }
  println(
    "[platformer][profile] elapsed_total=\{now - profile_started_at.val}s window=\{window}s frames=\{profile_frame_count.val} fps_avg=\{fps} fps_min=\{min_fps} input_avg_ms=\{input_ms} update_avg_ms=\{update_ms} sync_avg_ms=\{sync_ms} camera_avg_ms=\{camera_ms} hud_avg_ms=\{hud_ms} slowest_frame_ms=\{slowest_frame_ms} level=\{current_level_index.val + 1} phase=\{phase_text}",
  )
  profile_last_report_at.val = now
  profile_frame_count.val = 0
  profile_input_total.val = 0.0
  profile_update_total.val = 0.0
  profile_sync_total.val = 0.0
  profile_camera_total.val = 0.0
  profile_hud_total.val = 0.0
  profile_slowest_frame.val = 0.0
}

///|
fn update_text_entity_if_changed(
  entity : @entity.Entity,
  cache : Ref[String],
  text : String,
) -> Unit {
  if cache.val != text {
    cache.val = text
    @ui.texts().set(entity, @ui.Text::new(text))
  }
}
