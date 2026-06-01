///|
const VIEWPORT_WIDTH : Double = 800.0

///|
const VIEWPORT_HEIGHT : Double = 720.0

///|
const FPS : UInt = 60

///|
const ZOOM : Double = 1.0

///|
const STAGE_COLS : Int = 13

///|
const STAGE_ROWS : Int = 13

///|
const TILE_SIZE : Double = 32.0

///|
const BOARD_WIDTH : Double = 416.0

///|
const BOARD_HEIGHT : Double = 416.0

///|
const BOARD_LEFT : Double = 96.0

///|
const BOARD_TOP : Double = 136.0

///|
const BOARD_RIGHT : Double = BOARD_LEFT + BOARD_WIDTH

///|
const BOARD_BOTTOM : Double = BOARD_TOP + BOARD_HEIGHT

///|
const HUD_LEFT : Double = BOARD_RIGHT + 26.0

///|
const HUD_TOP : Double = BOARD_TOP

///|
const HUD_WIDTH : Double = VIEWPORT_WIDTH - HUD_LEFT - 42.0

///|
const HUD_TEXT_COLOR : String = "rgb(240, 236, 220)"

///|
const HUD_MUTED_COLOR : String = "rgb(194, 186, 168)"

///|
const OVERLAY_COLOR : String = "rgb(255, 216, 96)"

///|
const BACKGROUND_COLOR : String = "rgb(31, 31, 31)"

///|
const BOARD_BG_COLOR : String = "rgb(10, 10, 10)"

///|
const PANEL_COLOR : String = "rgb(72, 72, 72)"

///|
const FONT_FAMILY : String = "BattleCityMono"

///|
const FONT_PATH : String = "assets/tankbattle/fonts/FiraMono-Medium.ttf"

///|
const TITLE_IMAGE_PATH : String = "assets/tankbattle/title.png"

///|
const GAME_OVER_IMAGE_PATH : String = "assets/tankbattle/game_over.png"

///|
const MAP_IMAGE_PATH : String = "assets/tankbattle/map.png"

///|
const PLAYER_SHEET_PATH : String = "assets/tankbattle/player_tank.png"

///|
const ENEMY_SHEET_PATH : String = "assets/tankbattle/enemies.png"

///|
const POWERUP_SHEET_PATH : String = "assets/tankbattle/powerups.png"

///|
const SHIELD_SHEET_PATH : String = "assets/tankbattle/shield.png"

///|
const SPAWN_SHEET_PATH : String = "assets/tankbattle/spawn.png"

///|
const BULLET_SHEET_PATH : String = "assets/tankbattle/bullet.png"

///|
const FLAG_IMAGE_PATH : String = "assets/tankbattle/flag.png"

///|
const ICE_TILE_PATH : String = "assets/tankbattle/ice_tile.png"

///|
const BULLET_EXPLOSION_1_PATH : String = "assets/tankbattle/effects/bullet_explosion_1.png"

///|
const BULLET_EXPLOSION_2_PATH : String = "assets/tankbattle/effects/bullet_explosion_2.png"

///|
const BULLET_EXPLOSION_3_PATH : String = "assets/tankbattle/effects/bullet_explosion_3.png"

///|
const BIG_EXPLOSION_1_PATH : String = "assets/tankbattle/effects/big_explosion_1.png"

///|
const BIG_EXPLOSION_2_PATH : String = "assets/tankbattle/effects/big_explosion_2.png"

///|
const BIG_EXPLOSION_3_PATH : String = "assets/tankbattle/effects/big_explosion_3.png"

///|
const BIG_EXPLOSION_4_PATH : String = "assets/tankbattle/effects/big_explosion_4.png"

///|
const BIG_EXPLOSION_5_PATH : String = "assets/tankbattle/effects/big_explosion_5.png"

///|
const SFX_MENU_PATH : String = "assets/tankbattle/sounds/start_menu.ogg"

///|
const SFX_SWITCH_PATH : String = "assets/tankbattle/sounds/mode_switch.ogg"

///|
const SFX_FIRE_PATH : String = "assets/tankbattle/sounds/player_fire.ogg"

///|
const SFX_BULLET_EXPLOSION_PATH : String = "assets/tankbattle/sounds/bullet_explosion.ogg"

///|
const SFX_BIG_EXPLOSION_PATH : String = "assets/tankbattle/sounds/big_explosion.ogg"

///|
const SFX_HIT_1_PATH : String = "assets/tankbattle/sounds/bullet_hit_1.ogg"

///|
const SFX_HIT_2_PATH : String = "assets/tankbattle/sounds/bullet_hit_2.ogg"

///|
const SFX_POWERUP_APPEAR_PATH : String = "assets/tankbattle/sounds/powerup_appear.ogg"

///|
const SFX_POWERUP_PICK_PATH : String = "assets/tankbattle/sounds/powerup_pick.ogg"

///|
const SFX_PAUSE_PATH : String = "assets/tankbattle/sounds/game_pause.ogg"

///|
const SFX_GAME_OVER_PATH : String = "assets/tankbattle/sounds/game_over.ogg"

///|
const PLAYER_SIZE : Double = 32.0

///|
const TANK_ATLAS_CELL : Double = 28.0

///|
const PLAYER_COLLIDER_SIZE : Double = 28.0

///|
const PROJECTILE_SIZE : Double = 8.0

///|
const POWERUP_WIDTH : Double = 30.0

///|
const POWERUP_HEIGHT : Double = 28.0

///|
const QUEUE_ICON_SIZE : Double = 16.0

///|
const MAX_ACTIVE_ENEMIES : Int = 4

///|
const MAX_PROJECTILES : Int = 16

///|
const MAX_EXPLOSIONS : Int = 12

///|
const ENEMIES_PER_STAGE : Int = 20

///|
const STARTING_LIVES : Int = 3

///|
const PLAYER_BASE_SPEED : Double = 108.0

///|
const PLAYER_FAST_SPEED : Double = 124.0

///|
const PLAYER_POWER_SPEED : Double = 132.0

///|
const ENEMY_BASIC_SPEED : Double = 78.0

///|
const ENEMY_FAST_SPEED : Double = 112.0

///|
const ENEMY_POWER_SPEED : Double = 88.0

///|
const ENEMY_ARMOR_SPEED : Double = 74.0

///|
const PLAYER_BASE_PROJECTILE_SPEED : Double = 224.0

///|
const PLAYER_FAST_PROJECTILE_SPEED : Double = 252.0

///|
const PLAYER_POWER_PROJECTILE_SPEED : Double = 272.0

///|
const ENEMY_PROJECTILE_SPEED : Double = 208.0

///|
const PLAYER_FIRE_COOLDOWN : Double = 0.34

///|
const ENEMY_BASIC_FIRE_COOLDOWN : Double = 1.60

///|
const ENEMY_FAST_FIRE_COOLDOWN : Double = 1.32

///|
const ENEMY_POWER_FIRE_COOLDOWN : Double = 0.90

///|
const ENEMY_ARMOR_FIRE_COOLDOWN : Double = 1.44

///|
const PLAYER_RESPAWN_DELAY : Double = 1.25

///|
const SPAWN_FLASH_SECONDS : Double = 0.72

///|
const RESPAWN_SHIELD_SECONDS : Double = 3.2

///|
const HELMET_SECONDS : Double = 9.0

///|
const TIMER_SECONDS : Double = 7.5

///|
const SHOVEL_SECONDS : Double = 10.0

///|
const POWERUP_VISIBLE_SECONDS : Double = 9.0

///|
const STAGE_INTRO_SECONDS : Double = 1.35

///|
const STAGE_CLEAR_SECONDS : Double = 1.8

///|
const SPAWN_INTERVAL_SECONDS : Double = 1.25

///|
const ENEMY_TURN_SECONDS : Double = 0.82

///|
const BULLET_EXPLOSION_SECONDS : Double = 0.18

///|
const BIG_EXPLOSION_SECONDS : Double = 0.34

///|
const TILE_Z : Int = 10

///|
const TANK_Z : Int = 40

///|
const FOREST_Z : Int = 55

///|
const PROJECTILE_Z : Int = 60

///|
const EFFECT_Z : Int = 70

///|
const HUD_Z : Int = 120

///|
const OVERLAY_Z : Int = 150

///|
priv enum TerrainKind {
  Empty
  Brick
  Steel
  Water
  Forest
  Ice
  Base
} derive(Eq)

///|
priv enum StagePhase {
  MainMenu
  StageIntro
  Playing
  Paused
  StageClear
  GameOver
  CampaignClear
} derive(Eq)

///|
priv enum Direction {
  Up
  Right
  Down
  Left
} derive(Eq)

///|
priv enum EnemyKind {
  Basic
  Fast
  Power
  Armor
} derive(Eq)

///|
priv enum PowerUpKind {
  Helmet
  Timer
  Shovel
  Star
  Grenade
  Tank
} derive(Eq)

///|
priv enum TankRank {
  Basic
  Speed
  Twin
  Power
} derive(Eq)

///|
priv enum TankOwner {
  Player
  Enemy
} derive(Eq)

///|
priv enum MenuOption {
  OnePlayer
  Exit
} derive(Eq)

///|
priv enum ExplosionKind {
  Bullet
  Big
} derive(Eq)

///|
priv struct Rect {
  left : Double
  top : Double
  width : Double
  height : Double
}

///|
priv struct SpawnSpec {
  kind : EnemyKind
  drop : PowerUpKind?
}

///|
priv struct StageSpec {
  name : String
  tiles : Array[String]
  queue : Array[SpawnSpec]
}

///|
priv struct TankState {
  mut active : Bool
  mut center : @math.Vec2
  mut direction : Direction
  mut rank : TankRank
  mut kind : EnemyKind
  mut hp : Int
  mut fire_cooldown : Double
  mut born_seconds : Double
  mut shield_seconds : Double
  mut turn_seconds : Double
  mut carrier_drop : PowerUpKind?
}

///|
priv struct ProjectileState {
  mut active : Bool
  mut owner : TankOwner
  mut center : @math.Vec2
  mut direction : Direction
  mut speed : Double
  mut can_break_steel : Bool
}

///|
priv struct PowerUpState {
  mut active : Bool
  mut kind : PowerUpKind
  mut center : @math.Vec2
  mut seconds_remaining : Double
}

///|
priv struct ExplosionState {
  mut active : Bool
  mut kind : ExplosionKind
  mut center : @math.Vec2
  mut seconds_remaining : Double
}

///|
priv struct CampaignState {
  mut phase : StagePhase
  mut menu_option : MenuOption
  mut current_stage : Int
  mut lives : Int
  mut phase_seconds : Double
  mut queue_index : Int
  mut spawn_seconds : Double
  mut freeze_seconds : Double
  mut shovel_seconds : Double
  mut pending_respawn_seconds : Double
  mut base_destroyed : Bool
  mut debug_fps_enabled : Bool
}

///|
let campaign_state : CampaignState = {
  phase: MainMenu,
  menu_option: OnePlayer,
  current_stage: 0,
  lives: STARTING_LIVES,
  phase_seconds: 0.0,
  queue_index: 0,
  spawn_seconds: 0.0,
  freeze_seconds: 0.0,
  shovel_seconds: 0.0,
  pending_respawn_seconds: 0.0,
  base_destroyed: false,
  debug_fps_enabled: false,
}

///|
let terrain_tiles : Array[TerrainKind] = []

///|
let player_tank : TankState = {
  active: false,
  center: @math.Vec2(0.0, 0.0),
  direction: Up,
  rank: Basic,
  kind: Basic,
  hp: 1,
  fire_cooldown: 0.0,
  born_seconds: 0.0,
  shield_seconds: 0.0,
  turn_seconds: 0.0,
  carrier_drop: None,
}

///|
let enemy_tanks : Array[TankState] = []

///|
let projectiles : Array[ProjectileState] = []

///|
let explosions : Array[ExplosionState] = []

///|
let active_powerup : PowerUpState = {
  active: false,
  kind: Helmet,
  center: @math.Vec2(0.0, 0.0),
  seconds_remaining: 0.0,
}

///|
let current_player_spawn : Ref[(Int, Int)] = { val: (4, 12) }

///|
let current_base_grid : Ref[(Int, Int)] = { val: (6, 12) }

///|
let current_enemy_spawn_points : Array[(Int, Int)] = []

///|
let fortress_positions : Array[(Int, Int)] = []

///|
let terrain_entities : Array[@entity.Entity] = []

///|
let terrain_overlay_entities : Array[@entity.Entity] = []

///|
let queue_icon_entities : Array[@entity.Entity] = []

///|
let player_entity : @entity.Entity = @entity.Entity::Entity()

///|
let player_effect_entity : @entity.Entity = @entity.Entity::Entity()

///|
let enemy_entities : Array[@entity.Entity] = []

///|
let enemy_effect_entities : Array[@entity.Entity] = []

///|
let projectile_entities : Array[@entity.Entity] = []

///|
let explosion_entities : Array[@entity.Entity] = []

///|
let powerup_entity : @entity.Entity = @entity.Entity::Entity()

///|
let background_entity : @entity.Entity = @entity.Entity::Entity()

///|
let board_entity : @entity.Entity = @entity.Entity::Entity()

///|
let hud_entity : @entity.Entity = @entity.Entity::Entity()

///|
let title_image_entity : @entity.Entity = @entity.Entity::Entity()

///|
let game_over_image_entity : @entity.Entity = @entity.Entity::Entity()

///|
let menu_one_player_entity : @entity.Entity = @entity.Entity::Entity()

///|
let menu_exit_entity : @entity.Entity = @entity.Entity::Entity()

///|
let hud_lives_icon_entity : @entity.Entity = @entity.Entity::Entity()

///|
let hud_flag_entity : @entity.Entity = @entity.Entity::Entity()

///|
let hud_lives_text_entity : @entity.Entity = @entity.Entity::Entity()

///|
let hud_stage_text_entity : @entity.Entity = @entity.Entity::Entity()

///|
let hud_status_text_entity : @entity.Entity = @entity.Entity::Entity()

///|
let overlay_text_entity : @entity.Entity = @entity.Entity::Entity()

///|
let overlay_subtext_entity : @entity.Entity = @entity.Entity::Entity()

///|
let fps_text_entity : @entity.Entity = @entity.Entity::Entity()

///|
let map_image_handle : Ref[@asset.ImageHandle?] = { val: None }

///|
let player_sheet_handle : Ref[@asset.ImageHandle?] = { val: None }

///|
let enemy_sheet_handle : Ref[@asset.ImageHandle?] = { val: None }

///|
let powerup_sheet_handle : Ref[@asset.ImageHandle?] = { val: None }

///|
let shield_sheet_handle : Ref[@asset.ImageHandle?] = { val: None }

///|
let spawn_sheet_handle : Ref[@asset.ImageHandle?] = { val: None }

///|
let bullet_sheet_handle : Ref[@asset.ImageHandle?] = { val: None }

///|
let title_image_handle : Ref[@asset.ImageHandle?] = { val: None }

///|
let game_over_image_handle : Ref[@asset.ImageHandle?] = { val: None }

///|
let flag_image_handle : Ref[@asset.ImageHandle?] = { val: None }

///|
let ice_image_handle : Ref[@asset.ImageHandle?] = { val: None }

///|
let bullet_explosion_handles : Array[@asset.ImageHandle] = []

///|
let big_explosion_handles : Array[@asset.ImageHandle] = []

///|
let font_registered : Ref[Bool] = { val: false }

///|
let sfx_menu_handle : Ref[@asset.AudioHandle?] = { val: None }

///|
let sfx_switch_handle : Ref[@asset.AudioHandle?] = { val: None }

///|
let sfx_fire_handle : Ref[@asset.AudioHandle?] = { val: None }

///|
let sfx_bullet_explosion_handle : Ref[@asset.AudioHandle?] = { val: None }

///|
let sfx_big_explosion_handle : Ref[@asset.AudioHandle?] = { val: None }

///|
let sfx_hit_1_handle : Ref[@asset.AudioHandle?] = { val: None }

///|
let sfx_hit_2_handle : Ref[@asset.AudioHandle?] = { val: None }

///|
let sfx_powerup_appear_handle : Ref[@asset.AudioHandle?] = { val: None }

///|
let sfx_powerup_pick_handle : Ref[@asset.AudioHandle?] = { val: None }

///|
let sfx_pause_handle : Ref[@asset.AudioHandle?] = { val: None }

///|
let sfx_game_over_handle : Ref[@asset.AudioHandle?] = { val: None }

///|
let last_stage_text : Ref[String] = { val: "" }

///|
let last_lives_text : Ref[String] = { val: "" }

///|
let last_status_text : Ref[String] = { val: "" }

///|
let last_overlay_text : Ref[String] = { val: "" }

///|
let last_overlay_subtext : Ref[String] = { val: "" }

///|
let last_menu_one_player_text : Ref[String] = { val: "" }

///|
let last_menu_exit_text : Ref[String] = { val: "" }

///|
let last_fps_text : Ref[String] = { val: "" }

///|
fn vec2(x : Double, y : Double) -> @math.Vec2 {
  @math.Vec2(x, y)
}

///|
fn rect(left : Double, top : Double, width : Double, height : Double) -> Rect {
  { left, top, width, height }
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
fn clamp_int(value : Int, min_ : Int, max_ : Int) -> Int {
  if value < min_ {
    min_
  } else if value > max_ {
    max_
  } else {
    value
  }
}

///|
fn abs_double(value : Double) -> Double {
  if value < 0.0 {
    -value
  } else {
    value
  }
}

///|
fn terrain_index(x : Int, y : Int) -> Int {
  y * STAGE_COLS + x
}

///|
fn terrain_in_bounds(x : Int, y : Int) -> Bool {
  x >= 0 && x < STAGE_COLS && y >= 0 && y < STAGE_ROWS
}

///|
fn tile_rect(x : Int, y : Int) -> Rect {
  rect(
    BOARD_LEFT + x.to_double() * TILE_SIZE,
    BOARD_TOP + y.to_double() * TILE_SIZE,
    TILE_SIZE,
    TILE_SIZE,
  )
}

///|
fn tile_center(x : Int, y : Int) -> @math.Vec2 {
  vec2(
    BOARD_LEFT + x.to_double() * TILE_SIZE + TILE_SIZE * 0.5,
    BOARD_TOP + y.to_double() * TILE_SIZE + TILE_SIZE * 0.5,
  )
}

///|
fn tank_rect(center : @math.Vec2) -> Rect {
  rect(
    center[X] - PLAYER_COLLIDER_SIZE * 0.5,
    center[Y] - PLAYER_COLLIDER_SIZE * 0.5,
    PLAYER_COLLIDER_SIZE,
    PLAYER_COLLIDER_SIZE,
  )
}

///|
fn projectile_rect(center : @math.Vec2) -> Rect {
  rect(
    center[X] - PROJECTILE_SIZE * 0.5,
    center[Y] - PROJECTILE_SIZE * 0.5,
    PROJECTILE_SIZE,
    PROJECTILE_SIZE,
  )
}

///|
fn powerup_rect(center : @math.Vec2) -> Rect {
  rect(
    center[X] - POWERUP_WIDTH * 0.5,
    center[Y] - POWERUP_HEIGHT * 0.5,
    POWERUP_WIDTH,
    POWERUP_HEIGHT,
  )
}

///|
fn rects_overlap(a : Rect, b : Rect) -> Bool {
  a.left < b.left + b.width &&
  a.left + a.width > b.left &&
  a.top < b.top + b.height &&
  a.top + a.height > b.top
}

///|
fn world_to_grid(point : @math.Vec2) -> (Int, Int) {
  let x = clamp_int(
    ((point[X] - BOARD_LEFT) / TILE_SIZE).to_int(),
    0,
    STAGE_COLS - 1,
  )
  let y = clamp_int(
    ((point[Y] - BOARD_TOP) / TILE_SIZE).to_int(),
    0,
    STAGE_ROWS - 1,
  )
  (x, y)
}

///|
fn direction_step(direction : Direction, distance : Double) -> @math.Vec2 {
  match direction {
    Up => vec2(0.0, -distance)
    Right => vec2(distance, 0.0)
    Down => vec2(0.0, distance)
    Left => vec2(-distance, 0.0)
  }
}

///|
fn is_vertical(direction : Direction) -> Bool {
  direction == Up || direction == Down
}

///|
fn nearest_tile_center_coord(value : Double, axis_origin : Double) -> Double {
  let tile = ((value - axis_origin) / TILE_SIZE).round().to_int()
  axis_origin + tile.to_double() * TILE_SIZE + TILE_SIZE * 0.5
}

///|
fn move_towards(value : Double, target : Double, max_delta : Double) -> Double {
  if value < target {
    let next = value + max_delta
    if next > target {
      target
    } else {
      next
    }
  } else if value > target {
    let next = value - max_delta
    if next < target {
      target
    } else {
      next
    }
  } else {
    value
  }
}

///|
fn aligned_center_for_turn(
  center : @math.Vec2,
  direction : Direction,
  max_delta : Double,
) -> @math.Vec2 {
  if is_vertical(direction) {
    vec2(
      move_towards(
        center[X],
        nearest_tile_center_coord(center[X], BOARD_LEFT),
        max_delta,
      ),
      center[Y],
    )
  } else {
    vec2(
      center[X],
      move_towards(
        center[Y],
        nearest_tile_center_coord(center[Y], BOARD_TOP),
        max_delta,
      ),
    )
  }
}

///|
fn terrain_blocks_tank(tile : TerrainKind) -> Bool {
  match tile {
    Empty | Forest | Ice => false
    _ => true
  }
}

///|
fn terrain_blocks_bullet(tile : TerrainKind) -> Bool {
  match tile {
    Empty | Water | Forest | Ice => false
    _ => true
  }
}

///|
fn terrain_uses_overlay(tile : TerrainKind) -> Bool {
  tile == Forest
}

///|
fn terrain_is_slippery(tile : TerrainKind) -> Bool {
  tile == Ice
}

///|
fn tile_at(x : Int, y : Int) -> TerrainKind {
  if terrain_in_bounds(x, y) {
    terrain_tiles[terrain_index(x, y)]
  } else {
    Steel
  }
}

///|
fn set_tile(x : Int, y : Int, tile : TerrainKind) -> Unit {
  if terrain_in_bounds(x, y) {
    terrain_tiles[terrain_index(x, y)] = tile
  }
}

///|
fn player_rank_set_index(rank : TankRank) -> Int {
  match rank {
    Basic => 0
    Speed => 1
    Twin => 2
    Power => 3
  }
}

///|
fn enemy_kind_set_index(kind : EnemyKind) -> Int {
  match kind {
    Basic => 0
    Fast => 1
    Power => 2
    Armor => 3
  }
}

///|
fn player_sprite_index(
  rank : TankRank,
  direction : Direction,
  frame : Int,
) -> Int {
  let set_index = player_rank_set_index(rank)
  let base = set_index * 2
  match direction {
    Up => base + frame
    Right => 8 + base + frame
    Down => 16 + base + frame
    Left => 24 + base + frame
  }
}

///|
fn enemy_sprite_index(
  kind : EnemyKind,
  direction : Direction,
  frame : Int,
  carrier_flash : Bool,
) -> Int {
  let set_index = enemy_kind_set_index(kind) +
    (if carrier_flash { 4 } else { 0 })
  let base = set_index * 2
  match direction {
    Up => base + frame
    Right => 8 + base + frame
    Down => 16 + base + frame
    Left => 24 + base + frame
  }
}

///|
fn projectile_sprite_index(direction : Direction) -> Int {
  match direction {
    Up => 0
    Right => 1
    Down => 2
    Left => 3
  }
}

///|
fn powerup_sprite_index(kind : PowerUpKind) -> Int {
  match kind {
    Helmet => 0
    Timer => 1
    Shovel => 2
    Star => 3
    Grenade => 4
    Tank => 5
  }
}

///|
fn format_counter(value : Int) -> String {
  if value < 0 {
    "0"
  } else if value < 10 {
    "0\{value}"
  } else {
    "\{value}"
  }
}

///|
fn next_rank(rank : TankRank) -> TankRank {
  match rank {
    Basic => Speed
    Speed => Twin
    Twin => Power
    Power => Power
  }
}

///|
fn player_projectile_limit(rank : TankRank) -> Int {
  match rank {
    Basic | Speed => 1
    Twin | Power => 2
  }
}

///|
fn player_can_break_steel(rank : TankRank) -> Bool {
  rank == Power
}

///|
fn player_move_speed(rank : TankRank) -> Double {
  match rank {
    Basic => PLAYER_BASE_SPEED
    Speed | Twin => PLAYER_FAST_SPEED
    Power => PLAYER_POWER_SPEED
  }
}

///|
fn player_projectile_speed(rank : TankRank) -> Double {
  match rank {
    Basic => PLAYER_BASE_PROJECTILE_SPEED
    Speed => PLAYER_FAST_PROJECTILE_SPEED
    Twin | Power => PLAYER_POWER_PROJECTILE_SPEED
  }
}

///|
fn enemy_move_speed(kind : EnemyKind) -> Double {
  match kind {
    Basic => ENEMY_BASIC_SPEED
    Fast => ENEMY_FAST_SPEED
    Power => ENEMY_POWER_SPEED
    Armor => ENEMY_ARMOR_SPEED
  }
}

///|
fn enemy_fire_cooldown(kind : EnemyKind) -> Double {
  match kind {
    Basic => ENEMY_BASIC_FIRE_COOLDOWN
    Fast => ENEMY_FAST_FIRE_COOLDOWN
    Power => ENEMY_POWER_FIRE_COOLDOWN
    Armor => ENEMY_ARMOR_FIRE_COOLDOWN
  }
}

///|
fn enemy_hit_points(kind : EnemyKind) -> Int {
  match kind {
    Armor => 4
    _ => 1
  }
}

///|
fn default_enemy_state(kind? : EnemyKind = Basic) -> TankState {
  {
    active: false,
    center: vec2(0.0, 0.0),
    direction: Down,
    rank: Basic,
    kind,
    hp: enemy_hit_points(kind),
    fire_cooldown: enemy_fire_cooldown(kind),
    born_seconds: 0.0,
    shield_seconds: 0.0,
    turn_seconds: ENEMY_TURN_SECONDS,
    carrier_drop: None,
  }
}

///|
fn default_projectile_state() -> ProjectileState {
  {
    active: false,
    owner: Player,
    center: vec2(0.0, 0.0),
    direction: Up,
    speed: PLAYER_BASE_PROJECTILE_SPEED,
    can_break_steel: false,
  }
}

///|
fn default_explosion_state() -> ExplosionState {
  {
    active: false,
    kind: Bullet,
    center: vec2(0.0, 0.0),
    seconds_remaining: 0.0,
  }
}

///|
fn spawn(kind : EnemyKind) -> SpawnSpec {
  { kind, drop: None }
}

///|
fn carrier(kind : EnemyKind, power : PowerUpKind) -> SpawnSpec {
  { kind, drop: Some(power) }
}

///|
fn stage(
  name : String,
  tiles : Array[String],
  queue : Array[SpawnSpec],
) -> StageSpec {
  { name, tiles, queue }
}

///|
fn make_stage_1() -> StageSpec {
  stage(
    "STAGE 1",
    [
      "A.....C.....E", ".###.....###.", ".#...F.F...#.", "..#.......#..", "..W..###..W..",
      ".###.....###.", ".............", ".#.#.SSS.#.#.", "..#...I...#..", ".FFF.....FFF.",
      ".###.....###.", ".....###.....", "...P.#B#.....",
    ],
    [
      spawn(Basic),
      spawn(Basic),
      spawn(Fast),
      spawn(Basic),
      carrier(Basic, Helmet),
      spawn(Basic),
      spawn(Basic),
      spawn(Power),
      spawn(Fast),
      spawn(Basic),
      carrier(Fast, Star),
      spawn(Basic),
      spawn(Power),
      spawn(Basic),
      spawn(Armor),
      spawn(Fast),
      spawn(Basic),
      spawn(Power),
      spawn(Basic),
      spawn(Armor),
    ],
  )
}

///|
fn make_stage_2() -> StageSpec {
  stage(
    "STAGE 2",
    [
      "A.....C.....E", ".SSS.....SSS.", ".#.#.FFF.#.#.", ".#...WWW...#.", ".###.....###.",
      "...#.#.#.#...", ".III.....III.", ".###.SSS.###.", "...#.....#...", ".FFF.###.FFF.",
      ".#.........#.", ".....###.....", "...P.#B#.....",
    ],
    [
      spawn(Basic),
      spawn(Fast),
      spawn(Fast),
      spawn(Power),
      spawn(Basic),
      spawn(Basic),
      carrier(Power, Timer),
      spawn(Fast),
      spawn(Fast),
      spawn(Armor),
      spawn(Power),
      spawn(Basic),
      spawn(Armor),
      spawn(Fast),
      spawn(Power),
      spawn(Basic),
      carrier(Fast, Star),
      spawn(Armor),
      spawn(Power),
      spawn(Fast),
    ],
  )
}

///|
fn make_stage_3() -> StageSpec {
  stage(
    "STAGE 3",
    [
      "A.....C.....E", ".###.WWW.###.", ".#...W.W...#.", ".#.F.....F.#.", ".#.###.###.#.",
      "...#..I..#...", ".SSS.....SSS.", "...#..I..#...", ".#.###.###.#.", ".#.F.....F.#.",
      ".#...W.W...#.", ".....###.....", "...P.#B#.....",
    ],
    [
      spawn(Fast),
      spawn(Power),
      spawn(Basic),
      spawn(Armor),
      spawn(Fast),
      carrier(Basic, Shovel),
      spawn(Power),
      spawn(Fast),
      spawn(Basic),
      spawn(Armor),
      spawn(Power),
      spawn(Power),
      spawn(Fast),
      carrier(Power, Star),
      spawn(Armor),
      spawn(Basic),
      spawn(Fast),
      spawn(Power),
      spawn(Armor),
      spawn(Fast),
    ],
  )
}

///|
fn make_stage_4() -> StageSpec {
  stage(
    "STAGE 4",
    [
      "A.....C.....E", ".FFF.###.FFF.", ".F...#.#...F.", ".F.SS...SS.F.", ".###.....###.",
      "..W.W.I.W.W..", "..W.W...W.W..", ".###.....###.", ".F.SS...SS.F.", ".F...#.#...F.",
      ".FFF.###.FFF.", ".....###.....", "...P.#B#.....",
    ],
    [
      spawn(Power),
      spawn(Fast),
      spawn(Armor),
      spawn(Basic),
      spawn(Fast),
      spawn(Power),
      carrier(Armor, Grenade),
      spawn(Fast),
      spawn(Basic),
      spawn(Armor),
      spawn(Power),
      spawn(Fast),
      spawn(Basic),
      spawn(Armor),
      spawn(Power),
      spawn(Fast),
      carrier(Power, Timer),
      spawn(Armor),
      spawn(Basic),
      spawn(Fast),
    ],
  )
}

///|
fn make_stage_5() -> StageSpec {
  stage(
    "STAGE 5",
    [
      "A.....C.....E", ".III.....III.", ".#.#.SSS.#.#.", ".#...FFF...#.", ".###.....###.",
      "..W..###..W..", ".............", "..W..###..W..", ".###.....###.", ".#...FFF...#.",
      ".#.#.SSS.#.#.", ".....###.....", "...P.#B#.....",
    ],
    [
      spawn(Fast),
      spawn(Fast),
      spawn(Power),
      spawn(Armor),
      spawn(Basic),
      carrier(Fast, Tank),
      spawn(Power),
      spawn(Armor),
      spawn(Basic),
      spawn(Fast),
      spawn(Power),
      spawn(Armor),
      spawn(Fast),
      spawn(Basic),
      spawn(Power),
      spawn(Armor),
      carrier(Power, Star),
      spawn(Fast),
      spawn(Power),
      spawn(Armor),
    ],
  )
}

///|
fn make_stage_6() -> StageSpec {
  stage(
    "STAGE 6",
    [
      "A.....C.....E", ".###.SSS.###.", "...#.....#...", ".W.#.FFF.#.W.", ".W...I.I...W.",
      ".###.....###.", ".SSS..W..SSS.", ".###.....###.", ".W...I.I...W.", ".W.#.FFF.#.W.",
      "...#.....#...", ".....###.....", "...P.#B#.....",
    ],
    [
      spawn(Armor),
      spawn(Power),
      spawn(Fast),
      spawn(Armor),
      spawn(Power),
      spawn(Fast),
      carrier(Armor, Helmet),
      spawn(Power),
      spawn(Fast),
      spawn(Armor),
      spawn(Power),
      spawn(Armor),
      spawn(Fast),
      spawn(Power),
      spawn(Armor),
      carrier(Power, Shovel),
      spawn(Fast),
      spawn(Armor),
      spawn(Power),
      spawn(Fast),
    ],
  )
}

///|
fn make_stage_7() -> StageSpec {
  stage(
    "STAGE 7",
    [
      "A.....C.....E", ".FFF.....FFF.", ".F.###.###.F.", ".F.#.....#.F.", "...#.WWW.#...",
      ".SS.#.I.#.SS.", ".SS...I...SS.", ".SS.#.I.#.SS.", "...#.WWW.#...", ".F.#.....#.F.",
      ".F.###.###.F.", ".....###.....", "...P.#B#.....",
    ],
    [
      spawn(Armor),
      spawn(Armor),
      spawn(Power),
      spawn(Fast),
      spawn(Armor),
      carrier(Fast, Grenade),
      spawn(Power),
      spawn(Armor),
      spawn(Fast),
      spawn(Power),
      spawn(Armor),
      spawn(Fast),
      spawn(Power),
      spawn(Armor),
      spawn(Fast),
      spawn(Power),
      carrier(Armor, Tank),
      spawn(Fast),
      spawn(Power),
      spawn(Armor),
    ],
  )
}

///|
fn make_stage_8() -> StageSpec {
  stage(
    "STAGE 8",
    [
      "A.....C.....E", ".SSS.III.SSS.", ".#.#.....#.#.", ".#.###.###.#.", ".W...F.F...W.",
      ".###.WWW.###.", ".....SSS.....", ".###.WWW.###.", ".W...F.F...W.", ".#.###.###.#.",
      ".#.#.....#.#.", ".....###.....", "...P.#B#.....",
    ],
    [
      spawn(Armor),
      spawn(Power),
      spawn(Fast),
      spawn(Armor),
      carrier(Power, Helmet),
      spawn(Armor),
      spawn(Power),
      spawn(Fast),
      spawn(Armor),
      carrier(Fast, Timer),
      spawn(Power),
      spawn(Armor),
      spawn(Fast),
      carrier(Armor, Shovel),
      spawn(Power),
      spawn(Armor),
      carrier(Power, Star),
      spawn(Fast),
      carrier(Armor, Grenade),
      carrier(Power, Tank),
    ],
  )
}

///|
let stages : Array[StageSpec] = [
  make_stage_1(),
  make_stage_2(),
  make_stage_3(),
  make_stage_4(),
  make_stage_5(),
  make_stage_6(),
  make_stage_7(),
  make_stage_8(),
]

///|
fn stage_count() -> Int {
  stages.length()
}
