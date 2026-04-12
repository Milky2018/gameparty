///|
const VIEWPORT_WIDTH : Double = 656.0

///|
const VIEWPORT_HEIGHT : Double = 616.0

///|
const ZOOM : Double = 1.0

///|
const FPS : UInt = 60

///|
const GRID_WIDTH : Int = 13

///|
const GRID_HEIGHT : Int = 11

///|
const CELL_SIZE : Double = 48.0

///|
const GRID_OFFSET_X : Double = 16.0

///|
const GRID_OFFSET_Y : Double = 84.0

///|
const FLOOR_INSET : Double = 2.0

///|
const TURN_ASSIST_PX : Double = 10.0

///|
const PLAYER_SPEED : Double = CELL_SIZE * 4.0

///|
const PLAYER_MAX_SPEED : Double = CELL_SIZE * 9.0

///|
const ENEMY_SPEED : Double = CELL_SIZE * 2.5

///|
const PLAYER_RADIUS : Double = CELL_SIZE / 2.0 - 0.5

///|
const ENEMY_RADIUS : Double = CELL_SIZE / 2.0 - 0.5

///|
const BOMB_RADIUS : Double = CELL_SIZE / 2.0 - 0.5

///|
const COLLISION_EPSILON : Double = 0.001

///|
const BOMB_FUSE_TIME : Double = 2.0

///|
const ANIM_FPS : Double = 8.0

///|
const FLAME_DAMAGE_DURATION : Double = 0.16

///|
const FLAME_VISUAL_DURATION : Double = 0.34

///|
const SOFT_WALL_BREAK_DURATION : Double = 0.34

///|
const PLAYER_START_BOMBS : Int = 1

///|
const PLAYER_MAX_BOMBS : Int = 9

///|
const PLAYER_BLAST_RADIUS : Int = 1

///|
const PLAYER_MAX_BLAST_RADIUS : Int = 9

///|
const SOFT_WALL_ITEM_DROP_CHANCE : Double = 0.15

///|
const ENEMY_ITEM_DROP_CHANCE : Double = 0.5

///|
const P1_COLOR : String = "rgb(70, 200, 255)"

///|
const P1_DEAD_COLOR : String = "rgb(80, 98, 110)"

///|
const P2_COLOR : String = "rgb(255, 201, 84)"

///|
const P2_DEAD_COLOR : String = "rgb(124, 112, 82)"

///|
const SHOES_ITEM_COLOR : String = "rgb(108, 232, 143)"

///|
const BOMB_ITEM_COLOR : String = "rgb(253, 236, 102)"

///|
const POWER_ITEM_COLOR : String = "rgb(176, 124, 255)"

///|
const FLOOR_TILE_COLOR_A : String = "rgb(56, 135, 0)"

///|
const FLOOR_TILE_COLOR_B : String = "rgb(56, 135, 0)"

///|
const ITEM_BUBBLE_COLOR : String = "rgba(244, 247, 250, 0.92)"

///|
const ITEM_BUBBLE_RADIUS : Double = 24.0

///|
const HUD_TEXT_COLOR : String = "rgb(239, 241, 244)"

///|
const HUD_MUTED_TEXT_COLOR : String = "rgb(166, 176, 184)"

///|
const MENU_SELECTED_COLOR : String = "rgb(255, 220, 120)"

///|
const MENU_NORMAL_COLOR : String = HUD_TEXT_COLOR

///|
const BOMBMAN_FONT_FAMILY : String = "MGS1Codec"

///|
const BOMBMAN_FONT_PATH : String = "assets/shared/fonts/mgs1codec.ttf"

///|
const BOMBMAN_SPRITES_PATH : String = "assets/bombman/bomberman.png"

///|
const BOMBMAN_SPRITE_TILE_SIZE : Double = 16.0

///|
const BOMBMAN_SPRITE_ATLAS_COLUMNS : Int = 16

///|
const BOMBMAN_SPRITE_ATLAS_ROWS : Int = 24

///|
const SPRITE_HARD_WALL_COL : Int = 3

///|
const SPRITE_HARD_WALL_ROW : Int = 3

///|
const SPRITE_SOFT_WALL_COL : Int = 4

///|
const SPRITE_SOFT_WALL_ROW : Int = 3

///|
const SPRITE_SHOES_COL : Int = 2

///|
const SPRITE_SHOES_ROW : Int = 14

///|
const SPRITE_BOMB_ITEM_COL : Int = 0

///|
const SPRITE_BOMB_ITEM_ROW : Int = 14

///|
const SPRITE_POWER_ITEM_COL : Int = 1

///|
const SPRITE_POWER_ITEM_ROW : Int = 14

///|
const PLAYER_SPRITE_SIZE : Double = CELL_SIZE - 2.0

///|
const ENEMY_SPRITE_SIZE : Double = CELL_SIZE - 2.0

///|
const BOMB_SPRITE_SIZE : Double = CELL_SIZE - 2.0

///|
const FLAME_SPRITE_SIZE : Double = CELL_SIZE - FLOOR_INSET * 2.0

///|
const ITEM_ICON_SIZE : Double = ITEM_BUBBLE_RADIUS * 1.2

///|
const LEVEL_EMPTY : Int = 0

///|
const LEVEL_HARD_WALL : Int = 1

///|
const LEVEL_SOFT_WALL : Int = 2

///|
const LEVEL_P1_SPAWN : Int = 3

///|
const LEVEL_P2_SPAWN : Int = 4

///|
const LEVEL_ENEMY_SPAWN : Int = 5

///|
priv enum TileKind {
  Empty
  HardWall
  SoftWall
} derive(Eq)

///|
priv enum GamePhase {
  MainMenu
  Playing
  RoundOver
} derive(Eq)

///|
priv enum GameMode {
  SinglePlayer
  Coop
  Versus
} derive(Eq)

///|
priv enum MenuOption {
  OnePlayer
  TwoPlayersA
  TwoPlayersB
  NetworkBattle
  Exit
} derive(Eq)

///|
priv enum MenuScreen {
  MainRoot
  NetworkRoot
  NetworkHostSetup
  NetworkJoinSetup
  NetworkLobby
} derive(Eq)

///|
priv enum NetworkRootOption {
  CreateRoom
  JoinRoom
  Back
} derive(Eq)

///|
priv enum HostSetupFocus {
  Mode
  Level
  Port
} derive(Eq)

///|
priv enum JoinSetupFocus {
  Host
  Port
} derive(Eq)

///|
priv enum RoundOutcome {
  LevelClear
  Defeat
  P1Win
  P2Win
  Draw
}

///|
priv enum NetTransportMode {
  Off
  Loopback
  Host
  Client
} derive(Eq)

///|
priv enum ItemKind {
  Shoes
  BombUp
  PowerUp
} derive(Eq)

///|
priv enum PlayerId {
  P1
  P2
} derive(Eq)

///|
priv enum Direction {
  Up
  Down
  Left
  Right
} derive(Eq)

///|
priv enum EnemySkinKind {
  Blue
  Pink
  Peach
}

///|
priv enum FlameKind {
  Center
  BodyH
  BodyV
  EndLeft
  EndRight
  EndUp
  EndDown
} derive(Eq)

///|
priv enum AnimClip {
  PlayerIdleDown
  PlayerIdleUp
  PlayerIdleLeft
  PlayerIdleRight
  PlayerMoveDown
  PlayerMoveUp
  PlayerMoveLeft
  PlayerMoveRight
  PlayerDeath
  EnemyBlueMoveRight
  EnemyBlueMoveLeft
  EnemyBlueDeath
  EnemyPinkMoveRight
  EnemyPinkMoveLeft
  EnemyPinkDeath
  EnemyPeachMoveRight
  EnemyPeachMoveLeft
  EnemyPeachDeath
  BombFuse
  FlameCenterActive
  FlameBodyHActive
  FlameBodyVActive
  FlameEndLeftActive
  FlameEndRightActive
  FlameEndUpActive
  FlameEndDownActive
  FlameCenterTail
  FlameBodyHTail
  FlameBodyVTail
  FlameEndLeftTail
  FlameEndRightTail
  FlameEndUpTail
  FlameEndDownTail
  SoftWallBreak
} derive(Eq)

///|
priv struct AnimPlayback {
  mut clip_id : AnimClip
  mut looping : Bool
  mut finished : Bool
}

///|
type Level = ReadOnlyArray[ReadOnlyArray[Int]]

///|
priv struct Rect {
  left : Double
  top : Double
  right : Double
  bottom : Double
}

///|
priv struct PlayerState {
  id : PlayerId
  entity : @entity.Entity
  active : Bool
  mut center : @math.Vec2D
  mut direction : Direction?
  mut desired_direction : Direction?
  mut facing : Direction
  mut flip_x : Bool
  mut speed : Double
  radius : Double
  mut alive : Bool
  mut death_animation_done : Bool
  anim : AnimPlayback
  mut active_bombs : Int
  mut max_bombs : Int
  mut blast_radius : Int
}

///|
priv struct EnemyState {
  entity : @entity.Entity
  mut cell_x : Int
  mut cell_y : Int
  mut center : @math.Vec2D
  mut direction : Direction
  mut desired_direction : Direction
  mut facing : Direction
  mut flip_x : Bool
  speed : Double
  radius : Double
  mut alive : Bool
  skin : EnemySkinKind
  mut death_animation_done : Bool
  anim : AnimPlayback
}

///|
priv struct BombState {
  entity : @entity.Entity
  cell_x : Int
  cell_y : Int
  mut timer : Double
  radius : Int
  owner : PlayerId
  mut passable_for_owner : Bool
  anim : AnimPlayback
}

///|
priv struct FlameState {
  entity : @entity.Entity
  cell_x : Int
  cell_y : Int
  mut kind : FlameKind
  mut damage_timer : Double
  mut visual_timer : Double
  mut tail_phase : Bool
  mut anim : AnimPlayback
}

///|
priv struct SoftWallBreakState {
  entity : @entity.Entity
  cell_x : Int
  cell_y : Int
  mut timer : Double
  anim : AnimPlayback
}

///|
priv struct ItemState {
  entity : @entity.Entity
  label_entity : @entity.Entity
  cell_x : Int
  cell_y : Int
  kind : ItemKind
}

///|
priv struct InputStamps {
  mut sequence : Int
  mut up : Int
  mut down : Int
  mut left : Int
  mut right : Int
}

///|
let phase : Ref[GamePhase] = { val: MainMenu }

///|
let current_mode : Ref[GameMode] = { val: SinglePlayer }

///|
let menu_selection : Ref[MenuOption] = { val: OnePlayer }

///|
let menu_screen : Ref[MenuScreen] = { val: MainRoot }

///|
let network_root_selection : Ref[NetworkRootOption] = { val: CreateRoom }

///|
let host_setup_focus : Ref[HostSetupFocus] = { val: Mode }

///|
let join_setup_focus : Ref[JoinSetupFocus] = { val: Host }

///|
let host_setup_mode : Ref[GameMode] = { val: Coop }

///|
let host_setup_level : Ref[Int] = { val: 0 }

///|
let host_setup_port : Ref[String] = { val: "39000" }

///|
let join_setup_host : Ref[String] = { val: "127.0.0.1" }

///|
let join_setup_port : Ref[String] = { val: "39000" }

///|
let lobby_local_ip : Ref[String?] = { val: None }

///|
let lobby_mode_label : Ref[String] = { val: "A" }

///|
let lobby_endpoint_label : Ref[String] = { val: "" }

///|
let lobby_status_label : Ref[String] = { val: "" }

///|
let round_outcome : Ref[RoundOutcome] = { val: LevelClear }

///|
let tiles : Array[TileKind] = []

///|
let enemies : Array[EnemyState] = []

///|
let bombs : Array[BombState] = []

///|
let flames : Array[FlameState] = []

///|
let soft_wall_breaks : Array[SoftWallBreakState] = []

///|
let items : Array[ItemState] = []

///|
let players : Array[PlayerState] = [
  {
    id: P1,
    entity: @entity.Entity::new(),
    active: true,
    center: cell_center(1, 1),
    direction: None,
    desired_direction: None,
    facing: Down,
    flip_x: false,
    speed: PLAYER_SPEED,
    radius: PLAYER_RADIUS,
    alive: true,
    death_animation_done: false,
    anim: { clip_id: PlayerIdleDown, looping: true, finished: false },
    active_bombs: 0,
    max_bombs: PLAYER_START_BOMBS,
    blast_radius: PLAYER_BLAST_RADIUS,
  },
  {
    id: P2,
    entity: @entity.Entity::new(),
    active: false,
    center: cell_center(11, 9),
    direction: None,
    desired_direction: None,
    facing: Down,
    flip_x: false,
    speed: PLAYER_SPEED,
    radius: PLAYER_RADIUS,
    alive: true,
    death_animation_done: false,
    anim: { clip_id: PlayerIdleDown, looping: true, finished: false },
    active_bombs: 0,
    max_bombs: PLAYER_START_BOMBS,
    blast_radius: PLAYER_BLAST_RADIUS,
  },
]

///|
let level1 : Level = [
  [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
  [1, 3, 0, 2, 0, 2, 0, 2, 0, 2, 0, 4, 1],
  [1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1],
  [1, 2, 0, 2, 0, 2, 0, 2, 0, 2, 0, 2, 1],
  [1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1],
  [1, 0, 0, 2, 0, 2, 0, 2, 0, 5, 0, 2, 1],
  [1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1],
  [1, 2, 0, 2, 0, 2, 0, 2, 0, 2, 0, 2, 1],
  [1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1],
  [1, 0, 0, 0, 0, 2, 0, 2, 0, 0, 5, 0, 1],
  [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
]

///|
let level2 : Level = [
  [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
  [1, 3, 0, 0, 2, 0, 2, 0, 2, 0, 0, 4, 1],
  [1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1],
  [1, 0, 0, 2, 0, 0, 0, 2, 0, 0, 0, 0, 1],
  [1, 2, 1, 0, 1, 2, 1, 0, 1, 2, 1, 0, 1],
  [1, 0, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 1],
  [1, 0, 1, 2, 1, 0, 1, 2, 1, 0, 1, 0, 1],
  [1, 0, 0, 0, 2, 0, 2, 0, 2, 0, 0, 0, 1],
  [1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1],
  [1, 0, 5, 0, 2, 0, 2, 0, 2, 0, 0, 0, 1],
  [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
]

///|
let level3 : Level = [
  [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
  [1, 3, 0, 2, 0, 0, 0, 2, 0, 0, 0, 4, 1],
  [1, 0, 1, 0, 1, 2, 1, 0, 1, 2, 1, 0, 1],
  [1, 2, 0, 2, 0, 0, 0, 2, 0, 0, 0, 2, 1],
  [1, 0, 1, 0, 1, 2, 1, 0, 1, 2, 1, 0, 1],
  [1, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 1],
  [1, 0, 1, 2, 1, 0, 1, 0, 1, 2, 1, 0, 1],
  [1, 2, 0, 0, 0, 2, 0, 2, 0, 0, 0, 2, 1],
  [1, 0, 1, 2, 1, 0, 1, 0, 1, 2, 1, 0, 1],
  [1, 0, 5, 0, 0, 2, 0, 2, 0, 0, 0, 0, 1],
  [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
]

///|
let level4 : Level = [
  [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
  [1, 3, 0, 0, 2, 0, 2, 0, 2, 0, 0, 4, 1],
  [1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1],
  [1, 0, 0, 2, 0, 2, 0, 2, 0, 2, 0, 0, 1],
  [1, 2, 1, 0, 1, 0, 1, 0, 1, 0, 1, 2, 1],
  [1, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 1],
  [1, 2, 1, 0, 1, 0, 1, 0, 1, 0, 1, 2, 1],
  [1, 0, 0, 2, 0, 2, 0, 2, 0, 2, 0, 0, 1],
  [1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1],
  [1, 0, 5, 0, 2, 0, 2, 0, 2, 0, 0, 0, 1],
  [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
]

///|
let levels : ReadOnlyArray[Level] = [level1, level2, level3, level4]

///|
let current_level : Ref[Int] = { val: 0 }

///|
let direction_input_state : Array[InputStamps] = [
  { sequence: 0, up: 0, down: 0, left: 0, right: 0 },
  { sequence: 0, up: 0, down: 0, left: 0, right: 0 },
]

///|
let tile_entities : Array[@entity.Entity] = []

///|
let background_entity : @entity.Entity = @entity.Entity::new()

///|
let title_entity : @entity.Entity = @entity.Entity::new()

///|
let menu_entities : Array[@entity.Entity] = [
  @entity.Entity::new(),
  @entity.Entity::new(),
  @entity.Entity::new(),
  @entity.Entity::new(),
  @entity.Entity::new(),
]

///|
let hud_entity : @entity.Entity = @entity.Entity::new()

///|
let status_entity : @entity.Entity = @entity.Entity::new()

///|
let hint_entity : @entity.Entity = @entity.Entity::new()

///|
let menu_error_message : Ref[String] = { val: "" }

///|
let p2_bomb_test_override : Ref[Bool] = { val: false }

///|
let exit_request_count : Ref[Int] = { val: 0 }

///|
let suppress_exit_for_tests : Ref[Bool] = { val: false }

///|
let drop_rng : Ref[@random.Rand] = { val: @random.Rand::new() }

///|
let forced_drop_rolls : Array[Double] = []

///|
let forced_drop_kinds : Array[ItemKind] = []

///|
const PROFILE_ENV : String = "BOMBMAN_PROFILE"

///|
const CAPTURE_ENV : String = "BOMBMAN_CAPTURE"

///|
const CAPTURE_PATH : String = "bombman_capture.png"

///|
const CAPTURE_DELAY_SECONDS : Double = 4.0

///|
let profile_enabled : Ref[Bool] = { val: false }

///|
let profile_started_at : Ref[Double] = { val: 0.0 }

///|
let profile_last_report_at : Ref[Double] = { val: 0.0 }

///|
let profile_frame_count : Ref[Int] = { val: 0 }

///|
let profile_sim_total : Ref[Double] = { val: 0.0 }

///|
let profile_render_total : Ref[Double] = { val: 0.0 }

///|
let profile_frame_dt_total : Ref[Double] = { val: 0.0 }

///|
let profile_motion_total : Ref[Double] = { val: 0.0 }

///|
let profile_bombs_total : Ref[Double] = { val: 0.0 }

///|
let profile_flames_total : Ref[Double] = { val: 0.0 }

///|
let profile_enemies_total : Ref[Double] = { val: 0.0 }

///|
let profile_hits_total : Ref[Double] = { val: 0.0 }

///|
let profile_phase_total : Ref[Double] = { val: 0.0 }

///|
let capture_enabled : Ref[Bool] = { val: false }

///|
let capture_started_at : Ref[Double] = { val: 0.0 }

///|
let capture_taken : Ref[Bool] = { val: false }

///|
let netplay_mode : Ref[NetTransportMode] = { val: Off }

///|
let netplay_host_session : Ref[@netplay.NetSession?] = { val: None }

///|
let netplay_client_session : Ref[@netplay.NetSession?] = { val: None }

///|
let netplay_session : Ref[@netplay.NetSession?] = { val: None }

///|
let netplay_link : Ref[@netplay.TcpLink?] = { val: None }

///|
let netplay_local_frame : Ref[Int] = { val: 0 }

///|
let netplay_port : Ref[Int] = { val: 39000 }

///|
let netplay_remote_port : Ref[Int] = { val: 39000 }

///|
let netplay_remote_host : Ref[String] = { val: "127.0.0.1" }

///|
let netplay_last_remote_input : Ref[@netplay.PlayerInput?] = { val: None }

///|
let netplay_last_remote_action_frame : Ref[Int] = { val: -1 }

///|
let netplay_round_seed_applied : Ref[Int] = { val: -1 }

///|
let capture_perf_started_at : Ref[Double] = { val: 0.0 }

///|
let capture_perf_frame_count : Ref[Int] = { val: 0 }

///|
let capture_perf_frame_dt_total : Ref[Double] = { val: 0.0 }

///|
let movement_player_bomb_centers : Array[Array[@math.Vec2D]] = [[], []]

///|
let movement_enemy_bomb_centers : Array[@math.Vec2D] = []

///|
let movement_tile_rects_cache : Array[Rect] = []

///|
let bombman_atlas_layout : Ref[@sprite.TextureAtlasLayoutHandle?] = {
  val: None,
}

///|
let bombman_anim_graph : Ref[@animation.AnimationGraphHandle?] = { val: None }

///|
let bombman_anim_nodes : Array[@animation.AnimationNodeIndex] = []

///|
let tile_visuals_dirty : Ref[Bool] = { val: true }

///|
fn cell_index(x : Int, y : Int) -> Int {
  y * GRID_WIDTH + x
}

///|
fn cell_in_bounds(x : Int, y : Int) -> Bool {
  x >= 0 && x < GRID_WIDTH && y >= 0 && y < GRID_HEIGHT
}

///|
fn cell_center(x : Int, y : Int) -> @math.Vec2D {
  @math.Vec2D(
    GRID_OFFSET_X + x.to_double() * CELL_SIZE + CELL_SIZE / 2.0,
    GRID_OFFSET_Y + y.to_double() * CELL_SIZE + CELL_SIZE / 2.0,
  )
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
fn player_index(id : PlayerId) -> Int {
  match id {
    P1 => 0
    P2 => 1
  }
}

///|
fn menu_options() -> Array[MenuOption] {
  [OnePlayer, TwoPlayersA, TwoPlayersB, NetworkBattle, Exit]
}

///|
fn menu_option_label(option : MenuOption) -> String {
  match option {
    OnePlayer => "1 PLAYER"
    TwoPlayersA => "2 PLAYERS A"
    TwoPlayersB => "2 PLAYERS B"
    NetworkBattle => "NETWORK BATTLE"
    Exit => "EXIT"
  }
}

///|
fn network_root_option_label(option : NetworkRootOption) -> String {
  match option {
    CreateRoom => "CREATE ROOM"
    JoinRoom => "JOIN ROOM"
    Back => "BACK"
  }
}

///|
fn next_menu_option(option : MenuOption) -> MenuOption {
  match option {
    OnePlayer => TwoPlayersA
    TwoPlayersA => TwoPlayersB
    TwoPlayersB => NetworkBattle
    NetworkBattle => Exit
    Exit => OnePlayer
  }
}

///|
fn next_network_root_option(option : NetworkRootOption) -> NetworkRootOption {
  match option {
    CreateRoom => JoinRoom
    JoinRoom => Back
    Back => CreateRoom
  }
}

///|
fn previous_menu_option(option : MenuOption) -> MenuOption {
  match option {
    OnePlayer => Exit
    TwoPlayersA => OnePlayer
    TwoPlayersB => TwoPlayersA
    NetworkBattle => TwoPlayersB
    Exit => NetworkBattle
  }
}

///|
fn previous_network_root_option(
  option : NetworkRootOption,
) -> NetworkRootOption {
  match option {
    CreateRoom => Back
    JoinRoom => CreateRoom
    Back => JoinRoom
  }
}

///|
fn mode_label(mode : GameMode) -> String {
  match mode {
    SinglePlayer => "1 PLAYER"
    Coop => "2 PLAYERS A"
    Versus => "2 PLAYERS B"
  }
}

///|
fn network_mode_short(mode : GameMode) -> String {
  match mode {
    Coop => "A (CO-OP)"
    Versus => "B (VS)"
    SinglePlayer => "A (CO-OP)"
  }
}

///|
fn netplay_mode_code(mode : GameMode) -> Int {
  match mode {
    SinglePlayer => 1
    Coop => 2
    Versus => 3
  }
}

///|
fn netplay_mode_from_code(code : Int) -> GameMode? {
  match code {
    1 => Some(SinglePlayer)
    2 => Some(Coop)
    3 => Some(Versus)
    _ => None
  }
}

///|
fn encode_round_seed_for_netplay(level_index : Int, mode : GameMode) -> Int {
  (level_index + 1) * 10 + netplay_mode_code(mode)
}

///|
fn decode_round_seed_from_netplay(seed : Int) -> (Int, GameMode)? {
  if seed <= 0 {
    return None
  }
  let mode_code = seed % 10
  let level_number = seed / 10
  guard netplay_mode_from_code(mode_code) is Some(mode) else { return None }
  let level_index = level_number - 1
  if level_index < 0 || level_index >= levels.length() {
    return None
  }
  Some((level_index, mode))
}

///|
fn item_color(kind : ItemKind) -> String {
  match kind {
    Shoes => SHOES_ITEM_COLOR
    BombUp => BOMB_ITEM_COLOR
    PowerUp => POWER_ITEM_COLOR
  }
}

///|
fn player_color(id : PlayerId, alive : Bool) -> String {
  match id {
    P1 => if alive { P1_COLOR } else { P1_DEAD_COLOR }
    P2 => if alive { P2_COLOR } else { P2_DEAD_COLOR }
  }
}

///|
fn cell_top_left(x : Int, y : Int) -> @math.Vec2D {
  @math.Vec2D(
    GRID_OFFSET_X + x.to_double() * CELL_SIZE,
    GRID_OFFSET_Y + y.to_double() * CELL_SIZE,
  )
}

///|
fn cell_bounds(x : Int, y : Int) -> Rect {
  let top_left = cell_top_left(x, y)
  {
    left: top_left[X],
    top: top_left[Y],
    right: top_left[X] + CELL_SIZE,
    bottom: top_left[Y] + CELL_SIZE,
  }
}

///|
fn world_to_cell(center : @math.Vec2D) -> (Int, Int) {
  let raw_x = @cmath.floor((center[X] - GRID_OFFSET_X) / CELL_SIZE).to_int()
  let raw_y = @cmath.floor((center[Y] - GRID_OFFSET_Y) / CELL_SIZE).to_int()
  (clamp_int(raw_x, 0, GRID_WIDTH - 1), clamp_int(raw_y, 0, GRID_HEIGHT - 1))
}

///|
fn nearest_lane_center_x(x : Double) -> Double {
  let raw = @cmath.round((x - GRID_OFFSET_X - CELL_SIZE / 2.0) / CELL_SIZE).to_int()
  let cell_x = clamp_int(raw, 0, GRID_WIDTH - 1)
  cell_center(cell_x, 0)[X]
}

///|
fn nearest_lane_center_y(y : Double) -> Double {
  let raw = @cmath.round((y - GRID_OFFSET_Y - CELL_SIZE / 2.0) / CELL_SIZE).to_int()
  let cell_y = clamp_int(raw, 0, GRID_HEIGHT - 1)
  cell_center(0, cell_y)[Y]
}

///|
fn floor_tile_size() -> @math.Vec2D {
  @math.Vec2D(CELL_SIZE - FLOOR_INSET * 2.0, CELL_SIZE - FLOOR_INSET * 2.0)
}

///|
fn floor_tile_position(x : Int, y : Int) -> @math.Vec2D {
  cell_top_left(x, y) + @math.Vec2D(FLOOR_INSET, FLOOR_INSET)
}

///|
fn direction_delta(direction : Direction) -> (Int, Int) {
  match direction {
    Up => (0, -1)
    Down => (0, 1)
    Left => (-1, 0)
    Right => (1, 0)
  }
}

///|
fn direction_vector(direction : Direction) -> @math.Vec2D {
  match direction {
    Up => @math.Vec2D(0.0, -1.0)
    Down => @math.Vec2D(0.0, 1.0)
    Left => @math.Vec2D(-1.0, 0.0)
    Right => @math.Vec2D(1.0, 0.0)
  }
}

///|
fn is_horizontal(direction : Direction) -> Bool {
  match direction {
    Left | Right => true
    Up | Down => false
  }
}

///|
fn are_perpendicular(a : Direction, b : Direction) -> Bool {
  is_horizontal(a) != is_horizontal(b)
}

///|
fn turn_left(direction : Direction) -> Direction {
  match direction {
    Up => Left
    Down => Right
    Left => Down
    Right => Up
  }
}

///|
fn turn_right(direction : Direction) -> Direction {
  match direction {
    Up => Right
    Down => Left
    Left => Up
    Right => Down
  }
}

///|
fn opposite_direction(direction : Direction) -> Direction {
  match direction {
    Up => Down
    Down => Up
    Left => Right
    Right => Left
  }
}

///|
fn default_enemy_direction() -> Direction {
  Down
}

///|
fn current_level_number() -> Int {
  current_level.val + 1
}

///|
fn next_level_index(level_index : Int) -> Int {
  (level_index + 1) % levels.length()
}

///|
fn previous_level_index(level_index : Int) -> Int {
  if level_index <= 0 {
    levels.length() - 1
  } else {
    level_index - 1
  }
}

///|
fn alive_player_count() -> Int {
  players.fold(init=0, fn(acc, player) {
    if player.active && player.alive {
      acc + 1
    } else {
      acc
    }
  })
}

///|
fn player_can_use_item(player : PlayerState, kind : ItemKind) -> Bool {
  if !player.active {
    return false
  }
  match kind {
    Shoes => player.speed < PLAYER_MAX_SPEED
    BombUp => player.max_bombs < PLAYER_MAX_BOMBS
    PowerUp => player.blast_radius < PLAYER_MAX_BLAST_RADIUS
  }
}

///|
fn anim_frame_duration() -> Double {
  if ANIM_FPS <= 0.0 {
    1.0 / 8.0
  } else {
    1.0 / ANIM_FPS
  }
}

///|
fn anim_playback_new(clip_id : AnimClip, looping : Bool) -> AnimPlayback {
  { clip_id, looping, finished: false }
}

///|
let all_anim_clips : ReadOnlyArray[AnimClip] = [
  PlayerIdleDown,
  PlayerIdleUp,
  PlayerIdleLeft,
  PlayerIdleRight,
  PlayerMoveDown,
  PlayerMoveUp,
  PlayerMoveLeft,
  PlayerMoveRight,
  PlayerDeath,
  EnemyBlueMoveRight,
  EnemyBlueMoveLeft,
  EnemyBlueDeath,
  EnemyPinkMoveRight,
  EnemyPinkMoveLeft,
  EnemyPinkDeath,
  EnemyPeachMoveRight,
  EnemyPeachMoveLeft,
  EnemyPeachDeath,
  BombFuse,
  FlameCenterActive,
  FlameBodyHActive,
  FlameBodyVActive,
  FlameEndLeftActive,
  FlameEndRightActive,
  FlameEndUpActive,
  FlameEndDownActive,
  FlameCenterTail,
  FlameBodyHTail,
  FlameBodyVTail,
  FlameEndLeftTail,
  FlameEndRightTail,
  FlameEndUpTail,
  FlameEndDownTail,
  SoftWallBreak,
]

///|
fn enemy_skin_for_spawn(x : Int, y : Int, order : Int) -> EnemySkinKind {
  let value = ((x + 1) * 31 + (y + 1) * 17 + order * 13) % 3
  match value {
    0 => Blue
    1 => Pink
    _ => Peach
  }
}

///|
fn player_idle_clip(_id : PlayerId, facing : Direction) -> AnimClip {
  match facing {
    Up => PlayerIdleUp
    Left => PlayerIdleLeft
    Right => PlayerIdleRight
    Down => PlayerIdleDown
  }
}

///|
fn player_move_clip(_id : PlayerId, direction : Direction) -> AnimClip {
  match direction {
    Up => PlayerMoveUp
    Left => PlayerMoveLeft
    Right => PlayerMoveRight
    Down => PlayerMoveDown
  }
}

///|
fn enemy_move_clip(skin : EnemySkinKind, direction : Direction) -> AnimClip {
  let horizontal = if direction == Left { Left } else { Right }
  match skin {
    Blue =>
      if horizontal == Left {
        EnemyBlueMoveLeft
      } else {
        EnemyBlueMoveRight
      }
    Pink =>
      if horizontal == Left {
        EnemyPinkMoveLeft
      } else {
        EnemyPinkMoveRight
      }
    Peach =>
      if horizontal == Left {
        EnemyPeachMoveLeft
      } else {
        EnemyPeachMoveRight
      }
  }
}

///|
fn enemy_death_clip(skin : EnemySkinKind) -> AnimClip {
  match skin {
    Blue => EnemyBlueDeath
    Pink => EnemyPinkDeath
    Peach => EnemyPeachDeath
  }
}

///|
fn flame_active_clip(kind : FlameKind) -> AnimClip {
  match kind {
    Center => FlameCenterActive
    BodyH => FlameBodyHActive
    BodyV => FlameBodyVActive
    EndLeft => FlameEndLeftActive
    EndRight => FlameEndRightActive
    EndUp => FlameEndUpActive
    EndDown => FlameEndDownActive
  }
}

///|
fn flame_tail_clip(kind : FlameKind) -> AnimClip {
  match kind {
    Center => FlameCenterTail
    BodyH => FlameBodyHTail
    BodyV => FlameBodyVTail
    EndLeft => FlameEndLeftTail
    EndRight => FlameEndRightTail
    EndUp => FlameEndUpTail
    EndDown => FlameEndDownTail
  }
}

///|
fn anim_clip_frame_count(clip_id : AnimClip) -> Int {
  match clip_id {
    PlayerIdleDown | PlayerIdleUp | PlayerIdleLeft | PlayerIdleRight => 1
    PlayerMoveDown | PlayerMoveUp | PlayerMoveLeft | PlayerMoveRight => 3
    PlayerDeath => 7
    EnemyBlueMoveRight
    | EnemyBlueMoveLeft
    | EnemyPinkMoveRight
    | EnemyPinkMoveLeft
    | EnemyPeachMoveRight
    | EnemyPeachMoveLeft => 3
    EnemyBlueDeath | EnemyPinkDeath | EnemyPeachDeath => 5
    BombFuse => 3
    FlameCenterActive => 2
    FlameBodyHActive | FlameBodyVActive => 6
    FlameEndLeftActive
    | FlameEndRightActive
    | FlameEndUpActive
    | FlameEndDownActive => 3
    FlameCenterTail | FlameBodyHTail | FlameBodyVTail => 2
    FlameEndLeftTail | FlameEndRightTail | FlameEndUpTail | FlameEndDownTail =>
      2
    SoftWallBreak => 6
  }
}

///|
fn anim_clip_frame(clip_id : AnimClip, frame_index : Int) -> (Int, Int) {
  match clip_id {
    PlayerIdleDown => (3, 0)
    PlayerIdleUp => (3, 1)
    PlayerIdleLeft => (0, 0)
    PlayerIdleRight => (0, 1)
    PlayerMoveDown => [(3, 0), (4, 0), (5, 0)][frame_index]
    PlayerMoveUp => [(3, 1), (4, 1), (5, 1)][frame_index]
    PlayerMoveLeft => [(0, 0), (1, 0), (2, 0)][frame_index]
    PlayerMoveRight => [(0, 1), (1, 1), (2, 1)][frame_index]
    PlayerDeath =>
      [(0, 2), (1, 2), (2, 2), (3, 2), (4, 2), (5, 2), (6, 2)][frame_index]
    EnemyBlueMoveRight => [(0, 19), (1, 19), (2, 19)][frame_index]
    EnemyBlueMoveLeft => [(3, 19), (4, 19), (5, 19)][frame_index]
    EnemyBlueDeath =>
      [(7, 18), (8, 18), (9, 18), (10, 18), (11, 18)][frame_index]
    EnemyPinkMoveRight => [(0, 20), (1, 20), (2, 20)][frame_index]
    EnemyPinkMoveLeft => [(3, 20), (4, 20), (5, 20)][frame_index]
    EnemyPinkDeath =>
      [(7, 17), (8, 17), (9, 17), (10, 17), (11, 17)][frame_index]
    EnemyPeachMoveRight => [(0, 21), (1, 21), (2, 21)][frame_index]
    EnemyPeachMoveLeft => [(3, 21), (4, 21), (5, 21)][frame_index]
    EnemyPeachDeath =>
      [(7, 15), (8, 15), (9, 15), (10, 15), (11, 15)][frame_index]
    BombFuse => [(0, 3), (1, 3), (2, 3)][frame_index]
    FlameCenterActive => [(2, 6), (7, 6)][frame_index]
    FlameBodyHActive =>
      [(0, 6), (1, 6), (5, 6), (6, 6), (8, 6), (9, 6)][frame_index]
    FlameBodyVActive =>
      [(2, 4), (2, 5), (2, 7), (2, 8), (2, 9), (2, 10)][frame_index]
    FlameEndLeftActive => [(0, 6), (1, 6), (0, 6)][frame_index]
    FlameEndRightActive => [(10, 6), (9, 6), (10, 6)][frame_index]
    FlameEndUpActive => [(2, 4), (2, 5), (2, 4)][frame_index]
    FlameEndDownActive => [(2, 10), (2, 9), (2, 10)][frame_index]
    FlameCenterTail => [(7, 11), (8, 11)][frame_index]
    FlameBodyHTail => [(5, 11), (9, 11)][frame_index]
    FlameBodyVTail => [(7, 8), (7, 10)][frame_index]
    FlameEndLeftTail => [(0, 11), (1, 11)][frame_index]
    FlameEndRightTail => [(10, 11), (9, 11)][frame_index]
    FlameEndUpTail => [(2, 8), (2, 9)][frame_index]
    FlameEndDownTail => [(2, 10), (2, 9)][frame_index]
    SoftWallBreak =>
      [(5, 3), (6, 3), (7, 3), (8, 3), (9, 3), (10, 3)][frame_index]
  }
}

///|
fn available_drop_kinds() -> Array[ItemKind] {
  let kinds : Array[ItemKind] = []
  for kind in [Shoes, BombUp, PowerUp] {
    if players.any(fn(player) { player_can_use_item(player, kind) }) {
      kinds.push(kind)
    }
  }
  kinds
}
