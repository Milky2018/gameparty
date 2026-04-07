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
const PLAYER_HEIGHT : Double = 44.0

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
const COYOTE_TIME_SECONDS : Double = 0.11

///|
const JUMP_BUFFER_SECONDS : Double = 0.12

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
const DEBUG_CAPTURE_ENV : String = "SUPERMARIO_CAPTURE"

///|
const DEBUG_CAPTURE_PATH : String = "supermario_capture.png"

///|
const DEBUG_CAPTURE_DELAY_SECONDS : Double = 1.0

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
priv enum GamePhase {
  Playing
  Won
  Lost
} derive(Eq)

///|
priv enum TileKind {
  Ground
  Brick
  Pipe
} derive(Eq)

///|
priv struct SolidBlock {
  center : @math.Vec2D
  size : @math.Vec2D
  kind : TileKind
}

///|
priv struct EnemySpawn {
  center : @math.Vec2D
  patrol_left : Double
  patrol_right : Double
  facing_right : Bool
}

///|
priv struct LevelSpec {
  name : String
  player_spawn : @math.Vec2D
  goal_center : @math.Vec2D
  goal_size : @math.Vec2D
  world_width : Double
  blocks : Array[SolidBlock]
  enemy_spawns : Array[EnemySpawn]
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
  mut alive : Bool
}

///|
priv struct EnemyState {
  mut center : @math.Vec2D
  mut velocity : @math.Vec2D
  mut facing_right : Bool
  mut on_ground : Bool
  mut alive : Bool
  patrol_left : Double
  patrol_right : Double
}

///|
priv struct AudioBank {
  jump : @raylib.Sound
  stomp : @raylib.Sound
  hit : @raylib.Sound
  goal : @raylib.Sound
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
let player_state : Ref[PlayerState] = {
  val: {
    center: @math.Vec2D::zero(),
    velocity: @math.Vec2D::zero(),
    facing_right: true,
    on_ground: false,
    coyote_timer: 0.0,
    jump_buffer: 0.0,
    hurt_timer: 0.0,
    alive: true,
  }
}

///|
let level_specs : Array[LevelSpec] = []

///|
let current_level : Ref[LevelSpec?] = { val: None }

///|
let solid_blocks : Array[SolidBlock] = []

///|
let enemy_entities : Map[@entity.Entity, EnemyState] = Map::new()

///|
let static_entities : Array[@entity.Entity] = []

///|
let enemy_entities_order : Array[@entity.Entity] = []

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
    Some(value) => {
      value == "1" || value == "true" || value == "yes" || value == "on" ||
      value == "TRUE" || value == "YES" || value == "ON"
    }
    None => false
  }
}

///|
fn make_block(center : @math.Vec2D, size : @math.Vec2D, kind : TileKind) -> SolidBlock {
  { center, size, kind }
}

///|
fn make_enemy_spawn(
  center : @math.Vec2D,
  patrol_left : Double,
  patrol_right : Double,
  facing_right : Bool,
) -> EnemySpawn {
  { center, patrol_left, patrol_right, facing_right }
}

///|
fn build_level_specs() -> Array[LevelSpec] {
  let levels : Array[LevelSpec] = []
  levels.push(build_level_one())
  levels.push(build_level_two())
  levels
}

///|
fn build_level_one() -> LevelSpec {
  let blocks : Array[SolidBlock] = []
  let ground_y = 10.0 * TILE_SIZE
  for i in 0..<90 {
    blocks.push(make_block(
      vec2((i.to_double() + 0.5) * TILE_SIZE, ground_y + TILE_SIZE * 0.5),
      vec2(TILE_SIZE, TILE_SIZE),
      Ground,
    ))
  }
  for i in 14..<21 {
    blocks.push(make_block(
      vec2((i.to_double() + 0.5) * TILE_SIZE, 7.6 * TILE_SIZE),
      vec2(TILE_SIZE, TILE_SIZE),
      Brick,
    ))
  }
  for i in 27..<31 {
    blocks.push(make_block(
      vec2((i.to_double() + 0.5) * TILE_SIZE, 6.2 * TILE_SIZE),
      vec2(TILE_SIZE, TILE_SIZE),
      Brick,
    ))
  }
  for i in 40..<44 {
    blocks.push(make_block(
      vec2((i.to_double() + 0.5) * TILE_SIZE, 8.1 * TILE_SIZE),
      vec2(TILE_SIZE, TILE_SIZE),
      Brick,
    ))
  }
  for i in 54..<60 {
    blocks.push(make_block(
      vec2((i.to_double() + 0.5) * TILE_SIZE, 6.2 * TILE_SIZE),
      vec2(TILE_SIZE, TILE_SIZE),
      Brick,
    ))
  }
  for i in 67..<72 {
    blocks.push(make_block(
      vec2((i.to_double() + 0.5) * TILE_SIZE, 7.2 * TILE_SIZE),
      vec2(TILE_SIZE, TILE_SIZE),
      Brick,
    ))
  }
  for y in 8..<10 {
    blocks.push(make_block(
      vec2(9.5 * TILE_SIZE, (y.to_double() + 0.5) * TILE_SIZE),
      vec2(TILE_SIZE, TILE_SIZE),
      Pipe,
    ))
    blocks.push(make_block(
      vec2(73.5 * TILE_SIZE, (y.to_double() + 0.5) * TILE_SIZE),
      vec2(TILE_SIZE, TILE_SIZE),
      Pipe,
    ))
  }
  let enemy_spawns : Array[EnemySpawn] = [
    make_enemy_spawn(vec2(380.0, 9.2 * TILE_SIZE), 320.0, 620.0, true),
    make_enemy_spawn(vec2(1120.0, 9.2 * TILE_SIZE), 980.0, 1360.0, false),
    make_enemy_spawn(vec2(1730.0, 9.2 * TILE_SIZE), 1600.0, 1900.0, true),
  ]
  {
    name: "Green Plains",
    player_spawn: vec2(2.0 * TILE_SIZE, 8.8 * TILE_SIZE),
    goal_center: vec2(86.8 * TILE_SIZE, 7.9 * TILE_SIZE),
    goal_size: vec2(42.0, 180.0),
    world_width: 90.0 * TILE_SIZE,
    blocks,
    enemy_spawns,
  }
}

///|
fn build_level_two() -> LevelSpec {
  let blocks : Array[SolidBlock] = []
  let ground_y = 10.0 * TILE_SIZE
  for i in 0..<96 {
    if i >= 17 && i <= 20 {
      continue
    }
    if i >= 33 && i <= 35 {
      continue
    }
    if i >= 58 && i <= 61 {
      continue
    }
    blocks.push(make_block(
      vec2((i.to_double() + 0.5) * TILE_SIZE, ground_y + TILE_SIZE * 0.5),
      vec2(TILE_SIZE, TILE_SIZE),
      Ground,
    ))
  }
  for i in 15..<22 {
    blocks.push(make_block(
      vec2((i.to_double() + 0.5) * TILE_SIZE, 7.8 * TILE_SIZE),
      vec2(TILE_SIZE, TILE_SIZE),
      Brick,
    ))
  }
  for i in 31..<37 {
    blocks.push(make_block(
      vec2((i.to_double() + 0.5) * TILE_SIZE, 6.7 * TILE_SIZE),
      vec2(TILE_SIZE, TILE_SIZE),
      Brick,
    ))
  }
  for i in 49..<55 {
    blocks.push(make_block(
      vec2((i.to_double() + 0.5) * TILE_SIZE, 7.2 * TILE_SIZE),
      vec2(TILE_SIZE, TILE_SIZE),
      Brick,
    ))
  }
  for i in 64..<70 {
    blocks.push(make_block(
      vec2((i.to_double() + 0.5) * TILE_SIZE, 5.9 * TILE_SIZE),
      vec2(TILE_SIZE, TILE_SIZE),
      Brick,
    ))
  }
  for y in 8..<10 {
    blocks.push(make_block(
      vec2(10.5 * TILE_SIZE, (y.to_double() + 0.5) * TILE_SIZE),
      vec2(TILE_SIZE, TILE_SIZE),
      Pipe,
    ))
    blocks.push(make_block(
      vec2(44.5 * TILE_SIZE, (y.to_double() + 0.5) * TILE_SIZE),
      vec2(TILE_SIZE, TILE_SIZE),
      Pipe,
    ))
    blocks.push(make_block(
      vec2(78.5 * TILE_SIZE, (y.to_double() + 0.5) * TILE_SIZE),
      vec2(TILE_SIZE, TILE_SIZE),
      Pipe,
    ))
  }
  let enemy_spawns : Array[EnemySpawn] = [
    make_enemy_spawn(vec2(420.0, 9.2 * TILE_SIZE), 320.0, 620.0, true),
    make_enemy_spawn(vec2(970.0, 9.2 * TILE_SIZE), 860.0, 1180.0, false),
    make_enemy_spawn(vec2(1560.0, 9.2 * TILE_SIZE), 1450.0, 1760.0, true),
    make_enemy_spawn(vec2(2360.0, 9.2 * TILE_SIZE), 2250.0, 2600.0, false),
  ]
  {
    name: "Castle Gauntlet",
    player_spawn: vec2(2.0 * TILE_SIZE, 8.8 * TILE_SIZE),
    goal_center: vec2(92.8 * TILE_SIZE, 7.9 * TILE_SIZE),
    goal_size: vec2(42.0, 180.0),
    world_width: 96.0 * TILE_SIZE,
    blocks,
    enemy_spawns,
  }
}
