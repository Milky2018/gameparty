///|
const VIEWPORT_WIDTH : Double = 1280.0

///|
const VIEWPORT_HEIGHT : Double = 720.0

///|
const FPS : UInt = 60

///|
const GRID_COLS : Int = 9

///|
const GRID_ROWS : Int = 5

///|
const CELL_SIZE : Double = 92.0

///|
const BOARD_LEFT : Double = 220.0

///|
const BOARD_TOP : Double = 122.0

///|
const BOARD_RIGHT : Double = 1048.0

///|
const BOARD_BOTTOM : Double = 582.0

///|
const HOUSE_X : Double = 96.0

///|
const HUD_Z : Double = 200.0

///|
const BOARD_Z : Double = 0.0

///|
const PLANT_Z : Double = 10.0

///|
const ZOMBIE_Z : Double = 12.0

///|
const BULLET_Z : Double = 14.0

///|
const SUN_Z : Double = 16.0

///|
const OVERLAY_Z : Double = 220.0

///|
const SHOOTER_COST : Int = 100

///|
const WALL_COST : Int = 50

///|
const START_SUN : Int = 150

///|
const SUN_VALUE : Int = 25

///|
const ZOMBIE_REWARD_SUN : Int = 25

///|
const SHOOTER_HP : Int = 6

///|
const WALL_HP : Int = 18

///|
const BULLET_DAMAGE : Int = 1

///|
const SHOOTER_FIRE_INTERVAL : Double = 1.15

///|
const BULLET_SPEED : Double = 320.0

///|
const ZOMBIE_CHEW_INTERVAL : Double = 0.75

///|
const SUN_SPAWN_INTERVAL : Double = 5.8

///|
const SUN_FALL_SPEED : Double = 34.0

///|
const SUN_LIFETIME : Double = 10.0

///|
const WAVE_COUNT : Int = 3

///|
let wave_spawn_counts : ReadOnlyArray[Int] = [5, 7, 9]

///|
let wave_spawn_intervals : ReadOnlyArray[Double] = [2.3, 1.8, 1.4]

///|
let wave_zombie_speeds : ReadOnlyArray[Double] = [28.0, 32.0, 38.0]

///|
let wave_zombie_hps : ReadOnlyArray[Int] = [3, 4, 5]

///|
const PVZ_CAPTURE_ENV : String = "PVZ_CAPTURE"

///|
const PVZ_CAPTURE_PATH : String = "plantvszombies_capture.png"

///|
const PVZ_CAPTURE_DELAY_SECONDS : Double = 2.0

///|
const PVZ_PROFILE_ENV : String = "PVZ_PROFILE"

///|
const PVZ_PROFILE_REPORT_SECONDS : Double = 0.75

///|
const TITLE_COLOR : String = "rgb(244, 248, 250)"

///|
const HUD_COLOR : String = "rgb(230, 244, 224)"

///|
const HUD_MUTED_COLOR : String = "rgb(171, 190, 162)"

///|
const RESULT_WIN_COLOR : String = "rgb(174, 246, 173)"

///|
const RESULT_LOSE_COLOR : String = "rgb(255, 173, 173)"

///|
priv enum GamePhase {
  Playing
  Won
  Lost
} derive(Eq)

///|
priv enum PlantKind {
  Shooter
  Wall
} derive(Eq)

///|
priv enum SoundKind {
  Place
  Shoot
  Hit
  Kill
  Sun
  Win
  Lose
}

///|
priv struct PlantState {
  kind : PlantKind
  cell_x : Int
  cell_y : Int
  hp : Int
  attack_timer : Double
  entity : @entity.Entity
  alive : Bool
}

///|
priv struct ZombieState {
  x : Double
  y : Double
  lane : Int
  hp : Int
  speed : Double
  chew_timer : Double
  entity : @entity.Entity
  alive : Bool
}

///|
priv struct BulletState {
  x : Double
  y : Double
  speed : Double
  damage : Int
  entity : @entity.Entity
  alive : Bool
}

///|
priv struct SunState {
  x : Double
  y : Double
  vy : Double
  life_time : Double
  entity : @entity.Entity
  alive : Bool
}

///|
priv struct WaveState {
  mut wave_index : Int
  mut spawned_in_wave : Int
  mut spawn_timer : Double
}

///|
let phase : Ref[GamePhase] = { val: Playing }

///|
let sun_points : Ref[Int] = { val: START_SUN }

///|
let wave_state : Ref[WaveState] = {
  val: { wave_index: 0, spawned_in_wave: 0, spawn_timer: 0.0 },
}

///|
let sun_spawn_timer : Ref[Double] = { val: 0.0 }

///|
let show_fps : Ref[Bool] = { val: false }

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
let profile_render_total : Ref[Double] = { val: 0.0 }

///|
let profile_sim_total : Ref[Double] = { val: 0.0 }

///|
let profile_slowest_frame : Ref[Double] = { val: 0.0 }

///|
let hud_text_cache : Ref[String] = { val: "" }

///|
let hint_text_cache : Ref[String] = { val: "" }

///|
let result_text_cache : Ref[String] = { val: "" }

///|
let fps_text_cache : Ref[String] = { val: "" }

///|
let rng : @random.Rand = @random.Rand::new()

///|
let plants : Array[PlantState] = []

///|
let zombies : Array[ZombieState] = []

///|
let bullets : Array[BulletState] = []

///|
let suns : Array[SunState] = []

///|
let board_cells : Array[@entity.Entity] = []

///|
let board_grid_lines : Array[@entity.Entity] = []

///|
let house_entities : Array[@entity.Entity] = []

///|
let plant_overlay_entities : Array[@entity.Entity] = []

///|
let title_entity : @entity.Entity = @entity.Entity::new()

///|
let hud_entity : @entity.Entity = @entity.Entity::new()

///|
let hint_entity : @entity.Entity = @entity.Entity::new()

///|
let result_entity : @entity.Entity = @entity.Entity::new()

///|
let fps_entity : @entity.Entity = @entity.Entity::new()

///|
let sun_mesh_handle : Ref[@mesh2d.Mesh2dHandle?] = { val: None }

///|
let bullet_mesh_handle : Ref[@mesh2d.Mesh2dHandle?] = { val: None }

///|
let sun_material_handle : Ref[@material2d.ColorMaterialHandle?] = { val: None }

///|
let bullet_material_handle : Ref[@material2d.ColorMaterialHandle?] = {
  val: None,
}

///|
let place_sound : Ref[@raylib.Sound?] = { val: None }

///|
let shoot_sound : Ref[@raylib.Sound?] = { val: None }

///|
let hit_sound : Ref[@raylib.Sound?] = { val: None }

///|
let kill_sound : Ref[@raylib.Sound?] = { val: None }

///|
let sun_sound : Ref[@raylib.Sound?] = { val: None }

///|
let win_sound : Ref[@raylib.Sound?] = { val: None }

///|
let lose_sound : Ref[@raylib.Sound?] = { val: None }

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
fn abs_double(value : Double) -> Double {
  if value < 0.0 {
    -value
  } else {
    value
  }
}

///|
fn cell_in_bounds(x : Int, y : Int) -> Bool {
  x >= 0 && x < GRID_COLS && y >= 0 && y < GRID_ROWS
}

///|
fn cell_left(x : Int) -> Double {
  BOARD_LEFT + x.to_double() * CELL_SIZE
}

///|
fn cell_top(y : Int) -> Double {
  BOARD_TOP + y.to_double() * CELL_SIZE
}

///|
fn cell_center(x : Int, y : Int) -> @math.Vec2D {
  @math.Vec2D(cell_left(x) + CELL_SIZE * 0.5, cell_top(y) + CELL_SIZE * 0.5)
}

///|
fn point_in_rect(point : @math.Vec2D, rect : @raylib.Rectangle) -> Bool {
  let px = Float::from_double(point[X])
  let py = Float::from_double(point[Y])
  px >= rect.x &&
  px <= rect.x + rect.width &&
  py >= rect.y &&
  py <= rect.y + rect.height
}

///|
fn world_to_cell(pos : @math.Vec2D) -> (Int, Int) {
  let x = ((pos[X] - BOARD_LEFT) / CELL_SIZE).floor().to_int()
  let y = ((pos[Y] - BOARD_TOP) / CELL_SIZE).floor().to_int()
  (x, y)
}

///|
fn plant_cost(kind : PlantKind) -> Int {
  match kind {
    Shooter => SHOOTER_COST
    Wall => WALL_COST
  }
}

///|
fn plant_hp_for(kind : PlantKind) -> Int {
  match kind {
    Shooter => SHOOTER_HP
    Wall => WALL_HP
  }
}

///|
fn wave_plan_count(index : Int) -> Int {
  wave_spawn_counts[index]
}

///|
fn wave_plan_interval(index : Int) -> Double {
  wave_spawn_intervals[index]
}

///|
fn wave_plan_speed(index : Int) -> Double {
  wave_zombie_speeds[index]
}

///|
fn wave_plan_hp(index : Int) -> Int {
  wave_zombie_hps[index]
}

///|
fn current_wave_complete() -> Bool {
  wave_state.val.wave_index >= WAVE_COUNT
}

///|
fn can_place_plant(
  kind : PlantKind,
  available_sun : Int,
  occupied : Bool,
) -> Bool {
  available_sun >= plant_cost(kind) && !occupied
}

///|
fn projectile_hits_zombie(projectile_x : Double, zombie_x : Double) -> Bool {
  abs_double(projectile_x - zombie_x) <= 18.0
}

///|
fn zombie_reaches_house(zombie_x : Double) -> Bool {
  zombie_x <= HOUSE_X + 22.0
}

///|
fn env_flag_enabled(name : String) -> Bool {
  match @env.get_env_var(name) {
    Some(raw) =>
      match raw {
        "1" | "true" | "TRUE" | "yes" | "YES" | "on" | "ON" => true
        _ => false
      }
    None => false
  }
}

///|
fn reloadable_capture_enabled() -> Bool {
  env_flag_enabled(PVZ_CAPTURE_ENV)
}
