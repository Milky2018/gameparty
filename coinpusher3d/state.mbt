///|
const VIEWPORT_WIDTH : Double = 800.0

///|
const VIEWPORT_HEIGHT : Double = 450.0

///|
const FPS : UInt = 60

///|
const UI_ZINDEX : Int = 300

///|
const RUN_DURATION_SECONDS : Double = 600.0

///|
const DIFFICULTY_STEP_SECONDS : Double = 120.0

///|
const MAX_DIFFICULTY_TIER : Int = 4

///|
const INITIAL_COIN_CHARGE_MAX : Int = 8

///|
const INITIAL_DROP_COOLDOWN : Double = 0.18

///|
const INITIAL_REGEN_RATE : Double = 1.0 / 0.75

///|
const BASE_COMBO_WINDOW : Double = 1.6

///|
const CHEST_TRIGGER_CHANCE : Double = 0.08

///|
const CHEST_PITY_SECONDS : Double = 35.0

///|
const COIN_LIMIT : Int = 80

///|
const INITIAL_BOARD_COINS : Int = 4

///|
const SCORE_BASE : Int = 10

///|
const SCORE_SLOT_X1 : Double = 1.0

///|
const SCORE_SLOT_X2 : Double = 2.0

///|
const SCORE_SLOT_X4 : Double = 4.0

///|
const SCORE_COMBO_STEP : Double = 0.1

///|
const SCORE_COMBO_MAX : Double = 3.0

///|
const CAMERA_ORDER : Int = 10

///|
const CAMERA_NEAR : Double = 0.01

///|
const CAMERA_FAR : Double = 200.0

///|
const CAMERA_FOV_Y : Double = 48.0

///|
let camera_position : @math.Vec3 = @math.Vec3::new(0.0, 8.2, 19.0)

///|
let camera_target : @math.Vec3 = @math.Vec3::new(0.0, 1.2, 2.0)

///|
const BOARD_WIDTH : Double = 12.0

///|
const BOARD_LENGTH : Double = 18.0

///|
const BOARD_THICKNESS : Double = 0.6

///|
const BOARD_TILT_RADIANS : Double = 0.2

///|
const BOARD_CENTER_Y : Double = 0.0

///|
const RAIL_WIDTH : Double = 0.5

///|
const RAIL_HEIGHT : Double = 1.2

///|
const RAIL_DEPTH_PADDING : Double = 0.6

///|
const BACK_STOP_THICKNESS : Double = 0.8

///|
const COLLECTOR_Z : Double = BOARD_LENGTH * 0.5 - 0.4

///|
const COLLECTOR_Y_MAX : Double = 2.5

///|
const COIN_RADIUS : Double = 0.36

///|
const COIN_HEIGHT : Double = 0.16

///|
const COIN_SPAWN_Y : Double = 4.8

///|
const COIN_SPAWN_Z : Double = -BOARD_LENGTH * 0.5 + 2.0

///|
const COIN_DESPAWN_Y : Double = -8.0

///|
const COIN_DESPAWN_Z : Double = BOARD_LENGTH * 0.5 + 5.0

///|
const PUSHER_WIDTH : Double = BOARD_WIDTH - 1.2

///|
const PUSHER_HEIGHT : Double = 0.8

///|
const PUSHER_DEPTH : Double = 0.7

///|
const PUSHER_CENTER_Z : Double = -4.6

///|
const PUSHER_BASE_SPEED : Double = 1.8

///|
const PUSHER_BASE_STROKE_LENGTH : Double = 1.35

///|
const PUSHER_BASE_LANE_JITTER : Double = 0.32

///|
let bumper_size : @math.Vec3 = @math.Vec3::new(0.7, 0.7, 0.7)

///|
const BUMPER_Z : Double = 1.8

///|
const BUMPER_X_OFFSET : Double = 3.1

///|
const MAGNET_PULSE_PERIOD : Double = 1.2

///|
const MAGNET_ZONE_Z : Double = 4.2

///|
const MAGNET_FORWARD_BOOST : Double = 2.4

///|
const MAGNET_LANE_PULL : Double = 1.5

///|
const SPLIT_TRIGGER_Z : Double = 2.6

///|
const LUCKY_CHECK_SPEED : Double = 0.9

///|
const LUCKY_BONUS_CHANCE : Double = 0.24

///|
const LUCKY_BONUS_SCORE : Int = 35

///|
const HUD_FONT_FAMILY : String = "ThaleahFat"

///|
const HUD_FONT_PATH : String = "assets/shared/fonts/ThaleahFat.ttf"

///|
const TABLE_TOP_PATH : String = "assets/coinpusher3d/textures/table_top.png"

///|
const TABLE_SIDE_PATH : String = "assets/coinpusher3d/textures/table_side.png"

///|
const PUSHER_PATH : String = "assets/coinpusher3d/textures/pusher.png"

///|
const COIN_PATH : String = "assets/coinpusher3d/textures/coin.png"

///|
const SFX_COIN_DROP_PATH : String = "assets/coinpusher3d/sounds/coin_drop.wav"

///|
const SFX_CHEST_PICK_PATH : String = "assets/coinpusher3d/sounds/chest_pick.wav"

///|
const MUSIC_RUN_LOOP_PATH : String = "assets/coinpusher3d/music/run_loop.mp3"

///|
const DEBUG_CAPTURE_ENV : String = "COINPUSHER3D_CAPTURE"

///|
const DEBUG_CAPTURE_PATH : String = "coinpusher3d_capture.png"

///|
const DEBUG_CAPTURE_DELAY_SECONDS : Double = 4.0

///|
const PROFILE_ENV : String = "COINPUSHER3D_PROFILE"

///|
const PROFILE_REPORT_SECONDS : Double = 1.0

///|
priv enum RunPhase {
  Playing
  ChestPick
  Finished
} derive(Eq)

///|
priv enum UpgradeId {
  MaxCharge
  RegenBoost
  ScoreBoost
  ComboWindowBoost
  CooldownCut
  SplitCoin
  MagnetPulse
  LuckyBounce
  HeavyCoin
} derive(Eq, Hash)

///|
priv struct RunState {
  mut phase : RunPhase
  mut time_left : Double
  mut score : Int
  mut best_combo : Int
  mut combo_count : Int
  mut combo_window : Double
  mut last_score_time : Double
  mut score_multiplier : Double
}

///|
priv struct EconomyState {
  mut coin_charge : Int
  mut coin_charge_max : Int
  mut regen_rate : Double
  mut regen_accum : Double
  mut drop_cooldown : Double
  mut drop_cooldown_timer : Double
  mut spawn_x : Double
}

///|
priv struct BoardState {
  mut difficulty_tier : Int
  mut pusher_phase : Double
  mut pusher_speed : Double
  mut stroke_length : Double
  mut lane_jitter : Double
}

///|
priv struct UpgradeState {
  owned : Map[UpgradeId, Int]
  picked_order : Array[UpgradeId]
  mut magnet_timer : Double
}

///|
priv struct ChestState {
  mut pending : Bool
  mut options : Array[UpgradeId]
  mut last_chest_time : Double
}

///|
priv struct Coin {
  mut split_done : Bool
  mut lucky_checked : Bool
  mut life_time : Double
  heavy : Bool
}

///|
let run_state : RunState = {
  phase: Playing,
  time_left: RUN_DURATION_SECONDS,
  score: 0,
  best_combo: 0,
  combo_count: 0,
  combo_window: BASE_COMBO_WINDOW,
  last_score_time: -1000.0,
  score_multiplier: 1.0,
}

///|
let economy_state : EconomyState = {
  coin_charge: INITIAL_COIN_CHARGE_MAX,
  coin_charge_max: INITIAL_COIN_CHARGE_MAX,
  regen_rate: INITIAL_REGEN_RATE,
  regen_accum: 0.0,
  drop_cooldown: INITIAL_DROP_COOLDOWN,
  drop_cooldown_timer: 0.0,
  spawn_x: 0.0,
}

///|
let board_state : BoardState = {
  difficulty_tier: 0,
  pusher_phase: 0.0,
  pusher_speed: PUSHER_BASE_SPEED,
  stroke_length: PUSHER_BASE_STROKE_LENGTH,
  lane_jitter: PUSHER_BASE_LANE_JITTER,
}

///|
let upgrade_state : UpgradeState = {
  owned: Map::new(),
  picked_order: [],
  magnet_timer: 0.0,
}

///|
let chest_state : ChestState = {
  pending: false,
  options: [],
  last_chest_time: -1000.0,
}

///|
let rand : @random.Rand = @random.Rand::new()

///|
let camera_entity : @entity.Entity = @entity.Entity::new()

///|
let light_entity : @entity.Entity = @entity.Entity::new()

///|
let table_entity : @entity.Entity = @entity.Entity::new()

///|
let pusher_entity : @entity.Entity = @entity.Entity::new()

///|
let hud_bg_entity : @entity.Entity = @entity.Entity::new()

///|
let hud_main_entity : @entity.Entity = @entity.Entity::new()

///|
let hud_sub_entity : @entity.Entity = @entity.Entity::new()

///|
let hud_hint_entity : @entity.Entity = @entity.Entity::new()

///|
let chest_title_entity : @entity.Entity = @entity.Entity::new()

///|
let chest_option_panel_entities : Array[@entity.Entity] = [
  @entity.Entity::new(),
  @entity.Entity::new(),
  @entity.Entity::new(),
]

///|
let chest_option_text_entities : Array[@entity.Entity] = [
  @entity.Entity::new(),
  @entity.Entity::new(),
  @entity.Entity::new(),
]

///|
let summary_title_entity : @entity.Entity = @entity.Entity::new()

///|
let summary_body_entity : @entity.Entity = @entity.Entity::new()

///|
let hud_main_text_cache : Ref[String] = { val: "" }

///|
let hud_sub_text_cache : Ref[String] = { val: "" }

///|
let hud_hint_text_cache : Ref[String] = { val: "" }

///|
let summary_title_text_cache : Ref[String] = { val: "" }

///|
let summary_body_text_cache : Ref[String] = { val: "" }

///|
let table_mesh_handle : Ref[@render3d.MeshHandle?] = { val: None }

///|
let coin_mesh_handle : Ref[@render3d.MeshHandle?] = { val: None }

///|
let pusher_mesh_handle : Ref[@render3d.MeshHandle?] = { val: None }

///|
let bumper_mesh_handle : Ref[@render3d.MeshHandle?] = { val: None }

///|
let table_material_handle : Ref[@render3d.MaterialHandle?] = { val: None }

///|
let rail_material_handle : Ref[@render3d.MaterialHandle?] = { val: None }

///|
let collector_material_handle : Ref[@render3d.MaterialHandle?] = { val: None }

///|
let pusher_material_handle : Ref[@render3d.MaterialHandle?] = { val: None }

///|
let bumper_material_handle : Ref[@render3d.MaterialHandle?] = { val: None }

///|
let coin_material_handle : Ref[@render3d.MaterialHandle?] = { val: None }

///|
let cabinet_material_handle : Ref[@render3d.MaterialHandle?] = { val: None }

///|
let glass_material_handle : Ref[@render3d.MaterialHandle?] = { val: None }

///|
let static_entities : Array[@entity.Entity] = []

///|
let collector_entities : Array[@entity.Entity] = []

///|
let coin_entities : Map[@entity.Entity, Coin] = Map::new()

///|
let chest_option_rects : Array[(Double, Double, Double, Double)] = []

///|
let music_started : Ref[Bool] = { val: false }

///|
let coinpusher_font_registered : Ref[Bool] = { val: false }

///|
let score_events_in_frame : Ref[Int] = { val: 0 }

///|
let debug_capture_enabled : Ref[Bool] = { val: false }

///|
let debug_capture_started_at : Ref[Double] = { val: 0.0 }

///|
let debug_capture_taken : Ref[Bool] = { val: false }

///|
let profile_enabled : Ref[Bool] = { val: false }

///|
let profile_started_at : Ref[Double] = { val: 0.0 }

///|
let profile_last_report_at : Ref[Double] = { val: 0.0 }

///|
let profile_frame_count : Ref[Int] = { val: 0 }

///|
let profile_delta_accum : Ref[Double] = { val: 0.0 }

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
fn difficulty_tier_for_elapsed(elapsed : Double) -> Int {
  let step = (elapsed / DIFFICULTY_STEP_SECONDS).to_int()
  clamp_int(step, 0, MAX_DIFFICULTY_TIER)
}

///|
fn combo_multiplier(combo_count : Int) -> Double {
  if combo_count <= 0 {
    1.0
  } else {
    let raw = 1.0 + (combo_count - 1).to_double() * SCORE_COMBO_STEP
    clamp_double(raw, 1.0, SCORE_COMBO_MAX)
  }
}

///|
fn chest_should_trigger(roll : Double, seconds_since_last : Double) -> Bool {
  if seconds_since_last >= CHEST_PITY_SECONDS {
    true
  } else {
    roll < CHEST_TRIGGER_CHANCE
  }
}

///|
fn regen_charge_step(
  charge : Int,
  max_charge : Int,
  regen_accum : Double,
  regen_rate : Double,
  delta : Double,
) -> (Int, Double) {
  if charge >= max_charge || regen_rate <= 0.0 {
    return (charge, 0.0)
  }
  let mut next_charge = charge
  let mut next_accum = regen_accum + delta * regen_rate
  while next_accum >= 1.0 && next_charge < max_charge {
    next_accum -= 1.0
    next_charge += 1
  }
  if next_charge >= max_charge {
    (next_charge, 0.0)
  } else {
    (next_charge, next_accum)
  }
}

///|
fn board_half_width() -> Double {
  BOARD_WIDTH * 0.5
}

///|
fn board_half_length() -> Double {
  BOARD_LENGTH * 0.5
}

///|
fn lane_min_x() -> Double {
  -board_half_width() + 0.8
}

///|
fn lane_max_x() -> Double {
  board_half_width() - 0.8
}

///|
fn lane_width() -> Double {
  (lane_max_x() - lane_min_x()) / 3.0
}

///|
fn lane_center(index : Int) -> Double {
  lane_min_x() + lane_width() * (index.to_double() + 0.5)
}

///|
fn slot_multiplier_for_x(x : Double) -> Double {
  let split1 = lane_min_x() + lane_width()
  let split2 = lane_min_x() + lane_width() * 2.0
  if x < split1 {
    SCORE_SLOT_X1
  } else if x < split2 {
    SCORE_SLOT_X2
  } else {
    SCORE_SLOT_X4
  }
}

///|
fn board_surface_y(z : Double) -> Double {
  BOARD_CENTER_Y + BOARD_THICKNESS * 0.5 - z * @cmath.tan(BOARD_TILT_RADIANS)
}

///|
fn screen_x_to_spawn_x(mouse_x : Double) -> Double {
  let normalized = clamp_double(mouse_x / VIEWPORT_WIDTH, 0.0, 1.0)
  lane_min_x() + (lane_max_x() - lane_min_x()) * normalized
}

///|
fn has_upgrade(id : UpgradeId) -> Bool {
  upgrade_state.owned.contains(id)
}

///|
fn upgrade_stacks(id : UpgradeId) -> Int {
  match upgrade_state.owned.get(id) {
    Some(v) => v
    None => 0
  }
}

///|
fn upgrade_unique(id : UpgradeId) -> Bool {
  match id {
    SplitCoin | MagnetPulse | LuckyBounce | HeavyCoin => true
    _ => false
  }
}

///|
fn upgrade_weight(id : UpgradeId) -> Double {
  match id {
    MaxCharge => 1.0
    RegenBoost => 1.0
    ScoreBoost => 1.0
    ComboWindowBoost => 1.0
    CooldownCut => 1.0
    SplitCoin => 0.8
    MagnetPulse => 0.8
    LuckyBounce => 0.8
    HeavyCoin => 0.7
  }
}

///|
fn upgrades_conflict(a : UpgradeId, b : UpgradeId) -> Bool {
  match (a, b) {
    (HeavyCoin, CooldownCut) => true
    (CooldownCut, HeavyCoin) => true
    (HeavyCoin, RegenBoost) => true
    (RegenBoost, HeavyCoin) => true
    _ => false
  }
}

///|
fn upgrade_can_roll(id : UpgradeId) -> Bool {
  if upgrade_unique(id) && has_upgrade(id) {
    return false
  }
  for owned, _ in upgrade_state.owned {
    if upgrades_conflict(id, owned) {
      return false
    }
  }
  true
}

///|
fn upgrade_display_name(id : UpgradeId) -> String {
  match id {
    MaxCharge => "+Max Charge"
    RegenBoost => "+Regen Rate"
    ScoreBoost => "+Score Mult"
    ComboWindowBoost => "+Combo Window"
    CooldownCut => "-Drop Cooldown"
    SplitCoin => "Split Coin"
    MagnetPulse => "Magnet Pulse"
    LuckyBounce => "Lucky Bounce"
    HeavyCoin => "Heavy Coin"
  }
}

///|
fn upgrade_description(id : UpgradeId) -> String {
  match id {
    MaxCharge => "Increase max coin charge by 2."
    RegenBoost => "Recharge coins faster."
    ScoreBoost => "Increase total score multiplier."
    ComboWindowBoost => "Extend combo timeout."
    CooldownCut => "Drop coins more frequently."
    SplitCoin => "Each coin splits once after mid-board."
    MagnetPulse => "Periodic pull toward collector lanes."
    LuckyBounce => "Chance to gain bonus score on side bounce."
    HeavyCoin => "Heavier coins push stronger but move slower."
  }
}

///|
fn all_upgrade_ids() -> Array[UpgradeId] {
  [
    MaxCharge,
    RegenBoost,
    ScoreBoost,
    ComboWindowBoost,
    CooldownCut,
    SplitCoin,
    MagnetPulse,
    LuckyBounce,
    HeavyCoin,
  ]
}

///|
fn eligible_upgrades() -> Array[UpgradeId] {
  let result : Array[UpgradeId] = []
  for id in all_upgrade_ids() {
    if upgrade_can_roll(id) {
      result.push(id)
    }
  }
  result
}

///|
fn run_elapsed_seconds() -> Double {
  RUN_DURATION_SECONDS - run_state.time_left
}

///|
fn reset_run_state(seed : Int) -> Unit {
  run_state.phase = Playing
  run_state.time_left = RUN_DURATION_SECONDS
  run_state.score = 0
  run_state.best_combo = 0
  run_state.combo_count = 0
  run_state.combo_window = BASE_COMBO_WINDOW
  run_state.last_score_time = -1000.0
  run_state.score_multiplier = 1.0
  ignore(seed)

  economy_state.coin_charge_max = INITIAL_COIN_CHARGE_MAX
  economy_state.coin_charge = INITIAL_COIN_CHARGE_MAX
  economy_state.regen_rate = INITIAL_REGEN_RATE
  economy_state.regen_accum = 0.0
  economy_state.drop_cooldown = INITIAL_DROP_COOLDOWN
  economy_state.drop_cooldown_timer = 0.0
  economy_state.spawn_x = 0.0

  board_state.difficulty_tier = 0
  board_state.pusher_phase = 0.0
  board_state.pusher_speed = PUSHER_BASE_SPEED
  board_state.stroke_length = PUSHER_BASE_STROKE_LENGTH
  board_state.lane_jitter = PUSHER_BASE_LANE_JITTER

  upgrade_state.owned.clear()
  upgrade_state.picked_order.clear()
  upgrade_state.magnet_timer = 0.0

  chest_state.pending = false
  chest_state.options.clear()
  chest_state.last_chest_time = -1000.0

  debug_capture_enabled.val = env_flag_enabled(DEBUG_CAPTURE_ENV)
  debug_capture_started_at.val = @time.elapsed()
  debug_capture_taken.val = false
  profile_enabled.val = env_flag_enabled(PROFILE_ENV)
  profile_started_at.val = debug_capture_started_at.val
  profile_last_report_at.val = profile_started_at.val
  profile_frame_count.val = 0
  profile_delta_accum.val = 0.0
}
