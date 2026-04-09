///|
const VIEWPORT_WIDTH : Double = 1280.0

///|
const VIEWPORT_HEIGHT : Double = 720.0

///|
const FPS : UInt = 60

///|
const BOARD_ROWS : Int = 8

///|
const BOARD_COLS : Int = 8

///|
const CELL_SIZE : Double = 68.0

///|
const BOARD_ORIGIN_X : Double = 280.0

///|
const BOARD_ORIGIN_Y : Double = 86.0

///|
const BOARD_GAP : Double = 6.0

///|
const GEM_COUNT : Int = 6

///|
const GAME_TIME_LIMIT : Double = 180.0

///|
const SWAP_FORWARD_SECONDS : Double = 0.12

///|
const SWAP_ROLLBACK_SECONDS : Double = 0.10

///|
const CLEAR_SECONDS : Double = 0.12

///|
const FALL_SECONDS_PER_CELL : Double = 0.08

///|
const REFILL_SECONDS_PER_CELL : Double = 0.08

///|
const FLASH_TIME_FREEZE_SCALE : Double = 0.0

///|
const FLASH_EMERALD_FREEZE_SECONDS : Double = 5.0

///|
const FLASH_AMETHYST_SCORE_SECONDS : Double = 10.0

///|
const FLASH_PEARL_SCORE_MULTIPLIER : Int = 3

///|
const FLASH_AMETHYST_SCORE_MULTIPLIER : Int = 2

///|
const FLASH_AURA_SCALE : Double = 1.56

///|
const FLASH_AURA_ALPHA : Double = 0.88

///|
const FLASH_AURA_CLIP_GAP_FACTOR : Double = 0.2

///|
const SELECT_FRAME_THICKNESS : Double = 4.0

///|
const SELECT_FRAME_Z : Double = 240.0

///|
const DEBUG_CAPTURE_ENV : String = "BEJEWELED_CAPTURE"

///|
const DEBUG_CAPTURE_PATH : String = "bejeweled_capture.png"

///|
const DEBUG_CAPTURE_DELAY_SECONDS : Double = 4.0

///|
const BEJEWELED_PROFILE_ENV : String = "BEJEWELED_PROFILE"

///|
const BEJEWELED_PROFILE_REPORT_SECONDS : Double = 1.0

///|
const BEJEWELED_PROFILE_WARMUP_SECONDS : Double = 2.5

///|
const BEJEWELED_FONT_FAMILY : String = "MGS1Codec"

///|
const BEJEWELED_FONT_PATH : String = "bejeweled/assets/mgs1codec.ttf"

///|
const STATUS_BOX_WIDTH : Double = 220.0

///|
const STATUS_BOX_HEIGHT : Double = 82.0

///|
const STATUS_BOX_GAP : Double = 14.0

///|
const STATUS_BOX_MARGIN_RIGHT : Double = 24.0

///|
const STATUS_BOX_TOP : Double = 24.0

///|
enum GamePhase {
  Playing
  GameOver
} derive(Eq)

///|
priv enum ResolutionPhase {
  InputReady
  SwapForward
  SwapRollback
  Clear
  Fall
  DeadlockClear
  CascadeCheck
} derive(Eq)

///|
enum GemKind {
  Ruby
  Emerald
  Sapphire
  Amber
  Amethyst
  Pearl
} derive(Eq, Hash, Debug)

///|
pub impl Show for GemKind with output(self, logger) {
  let text = match self {
    Ruby => "Ruby"
    Emerald => "Emerald"
    Sapphire => "Sapphire"
    Amber => "Amber"
    Amethyst => "Amethyst"
    Pearl => "Pearl"
  }
  logger.write_string(text)
}

///|
struct Cell {
  row : Int
  col : Int
} derive(Eq, Hash, Debug)

///|
pub impl Show for Cell with output(self, logger) {
  logger.write_string("{row: \{self.row}, col: \{self.col}}")
}

///|
priv struct Gem {
  kind : GemKind
  flash : Bool
  entity : @entity.Entity
  aura_entity : @entity.Entity
}

///|
priv struct GemTween {
  entity : @entity.Entity
  aura_entity : @entity.Entity
  kind : GemKind
  flash : Bool
  from_x : Double
  from_y : Double
  to_x : Double
  to_y : Double
  from_z : Double
  to_z : Double
  from_scale : Double
  to_scale : Double
  from_alpha : Double
  to_alpha : Double
  duration : Double
}

///|
priv struct SpecialSpawn {
  cell : Cell
  kind : GemKind
}

///|
priv struct GameState {
  mut phase : GamePhase
  mut resolution_phase : ResolutionPhase
  mut resolution_elapsed : Double
  mut resolution_duration : Double
  mut score : Int
  mut time_left : Double
  mut time_freeze_remaining : Double
  mut score_bonus_remaining : Double
  mut first_pick : Cell?
  mut drag_origin : Cell?
  mut drag_pointer_down : Bool
  mut drag_swapped : Bool
  mut pending_swap_a : Cell?
  mut pending_swap_b : Cell?
  mut pending_matches : Array[Cell]
  mut pending_match_count : Int
  mut pending_special_spawns : Array[SpecialSpawn]
  mut active_tweens : Array[GemTween]
  mut cascade_depth : Int
  mut debug_fps : Bool
  mut debug_capture_enabled : Bool
  mut debug_capture_started_at : Double
  mut debug_capture_taken : Bool
  mut profile_enabled : Bool
  mut profile_started_at : Double
  mut profile_last_report_at : Double
  mut profile_frame_count : Int
  mut profile_input_total : Double
  mut profile_update_total : Double
  mut profile_render_total : Double
  mut profile_slowest_frame : Double
  mut timer_text_cache : String
  mut score_text_cache : String
  mut overlay_text_cache : String
  mut game_over_reason : String
}

///|
let game_state : GameState = {
  phase: Playing,
  resolution_phase: InputReady,
  resolution_elapsed: 0.0,
  resolution_duration: 0.0,
  score: 0,
  time_left: GAME_TIME_LIMIT,
  time_freeze_remaining: 0.0,
  score_bonus_remaining: 0.0,
  first_pick: None,
  drag_origin: None,
  drag_pointer_down: false,
  drag_swapped: false,
  pending_swap_a: None,
  pending_swap_b: None,
  pending_matches: [],
  pending_match_count: 0,
  pending_special_spawns: [],
  active_tweens: [],
  cascade_depth: 0,
  debug_fps: false,
  debug_capture_enabled: false,
  debug_capture_started_at: 0.0,
  debug_capture_taken: false,
  profile_enabled: false,
  profile_started_at: 0.0,
  profile_last_report_at: 0.0,
  profile_frame_count: 0,
  profile_input_total: 0.0,
  profile_update_total: 0.0,
  profile_render_total: 0.0,
  profile_slowest_frame: 0.0,
  timer_text_cache: "",
  score_text_cache: "",
  overlay_text_cache: "",
  game_over_reason: "",
}

///|
let rand : @random.Rand = @random.Rand::new()

///|
let board_bg_entity : @entity.Entity = @entity.Entity::new()

///|
let title_glow_outer_entity : @entity.Entity = @entity.Entity::new()

///|
let title_glow_inner_entity : @entity.Entity = @entity.Entity::new()

///|
let title_entity : @entity.Entity = @entity.Entity::new()

///|
let timer_panel_entity : @entity.Entity = @entity.Entity::new()

///|
let timer_fx_entity : @entity.Entity = @entity.Entity::new()

///|
let timer_text_entity : @entity.Entity = @entity.Entity::new()

///|
let score_panel_entity : @entity.Entity = @entity.Entity::new()

///|
let score_fx_entity : @entity.Entity = @entity.Entity::new()

///|
let score_text_entity : @entity.Entity = @entity.Entity::new()

///|
let board_panel_entity : @entity.Entity = @entity.Entity::new()

///|
let flash_legend_panel_entity : @entity.Entity = @entity.Entity::new()

///|
let flash_legend_title_entity : @entity.Entity = @entity.Entity::new()

///|
let flash_legend_icon_entities : Array[@entity.Entity] = [
  @entity.Entity::new(),
  @entity.Entity::new(),
  @entity.Entity::new(),
  @entity.Entity::new(),
  @entity.Entity::new(),
  @entity.Entity::new(),
]

///|
let flash_legend_aura_entities : Array[@entity.Entity] = [
  @entity.Entity::new(),
  @entity.Entity::new(),
  @entity.Entity::new(),
  @entity.Entity::new(),
  @entity.Entity::new(),
  @entity.Entity::new(),
]

///|
let flash_legend_text_entities : Array[@entity.Entity] = [
  @entity.Entity::new(),
  @entity.Entity::new(),
  @entity.Entity::new(),
  @entity.Entity::new(),
  @entity.Entity::new(),
  @entity.Entity::new(),
]

///|
let overlay_entity : @entity.Entity = @entity.Entity::new()

///|
let overlay_text_entity : @entity.Entity = @entity.Entity::new()

///|
let selected_frame_top_entity : @entity.Entity = @entity.Entity::new()

///|
let selected_frame_bottom_entity : @entity.Entity = @entity.Entity::new()

///|
let selected_frame_left_entity : @entity.Entity = @entity.Entity::new()

///|
let selected_frame_right_entity : @entity.Entity = @entity.Entity::new()

///|
let gem_entities : Array[@entity.Entity] = []

///|
let gem_aura_entities : Array[@entity.Entity] = []

///|
let board : Array[GemKind?] = []

///|
let gem_lookup : Map[Cell, Gem] = Map::new()

///|
let gem_image_paths : Array[String] = [
  "bejeweled/assets/Bun.png", "bejeweled/assets/Go.png", "bejeweled/assets/MoonBit.png",
  "bejeweled/assets/OCaml.png", "bejeweled/assets/Python.png", "bejeweled/assets/Rust.png",
]

///|
let gem_image_sizes : Array[@math.Vec2D] = [
  @math.Vec2D(512.0, 512.0),
  @math.Vec2D(512.0, 512.0),
  @math.Vec2D(508.0, 652.0),
  @math.Vec2D(512.0, 512.0),
  @math.Vec2D(512.0, 512.0),
  @math.Vec2D(900.0, 673.0),
]

///|
let gem_image_handles : Array[@asset.ImageHandle] = []

///|
let gem_aura_colors : Array[@render.Color] = [
  { r: 255U, g: 103U, b: 128U, a: 1.0 },
  { r: 124U, g: 255U, b: 168U, a: 1.0 },
  { r: 120U, g: 182U, b: 255U, a: 1.0 },
  { r: 255U, g: 214U, b: 114U, a: 1.0 },
  { r: 213U, g: 144U, b: 255U, a: 1.0 },
  { r: 255U, g: 247U, b: 188U, a: 1.0 },
]

///|
let sound_swap : Ref[@raylib.Sound?] = { val: None }

///|
let sound_match : Ref[@raylib.Sound?] = { val: None }

///|
let sound_cascade : Ref[@raylib.Sound?] = { val: None }

///|
let sound_gameover : Ref[@raylib.Sound?] = { val: None }

///|
fn board_index(row : Int, col : Int) -> Int {
  row * BOARD_COLS + col
}

///|
fn in_bounds(row : Int, col : Int) -> Bool {
  row >= 0 && row < BOARD_ROWS && col >= 0 && col < BOARD_COLS
}

///|
fn cell_center(cell : Cell) -> (@math.Vec2D, Double) {
  (
    @math.Vec2D(
      BOARD_ORIGIN_X + cell.col.to_double() * CELL_SIZE + CELL_SIZE * 0.5,
      BOARD_ORIGIN_Y + cell.row.to_double() * CELL_SIZE + CELL_SIZE * 0.5,
    ),
    200.0 + cell.row.to_double(),
  )
}

///|
fn ensure_gem_images_loaded() -> Unit {
  if gem_image_handles.is_empty() {
    for path in gem_image_paths {
      gem_image_handles.push(@asset.load_image(path))
    }
  }
}

///|
fn gem_image(kind : GemKind) -> @asset.ImageHandle {
  ensure_gem_images_loaded()
  gem_image_handles[gem_index(kind)]
}

///|
fn gem_image_size(kind : GemKind) -> @math.Vec2D {
  gem_image_sizes[gem_index(kind)]
}

///|
fn gem_aura_color(kind : GemKind) -> @render.Color {
  gem_aura_colors[gem_index(kind)]
}

///|
fn gem_index(kind : GemKind) -> Int {
  match kind {
    Ruby => 0
    Emerald => 1
    Sapphire => 2
    Amber => 3
    Amethyst => 4
    Pearl => 5
  }
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
