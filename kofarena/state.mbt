///|
const VIEWPORT_WIDTH : Double = 1280.0

///|
const VIEWPORT_HEIGHT : Double = 720.0

///|
const FPS : UInt = 60

///|
const UI_ZINDEX : Int = 300

///|
const GROUND_Y : Double = 620.0

///|
const STAGE_LEFT : Double = 80.0

///|
const STAGE_RIGHT : Double = 1200.0

///|
const FALL_KILL_Y : Double = 840.0

///|
const ROUND_TIME_SECONDS : Double = 99.0

///|
const MAX_HEALTH : Int = 100

///|
const MOVE_SPEED : Double = 260.0

///|
const CROUCH_SPEED : Double = 170.0

///|
const BACKSTEP_SPEED : Double = 380.0

///|
const JUMP_VELOCITY : Double = 720.0

///|
const GRAVITY : Double = 1900.0

///|
const MAX_FALL_SPEED : Double = 1300.0

///|
const HURTBOX_WIDTH : Double = 42.0

///|
const HURTBOX_HEIGHT : Double = 84.0

///|
const CROUCH_HEIGHT : Double = 58.0

///|
const LIGHT_STARTUP : Double = 0.08

///|
const LIGHT_ACTIVE : Double = 0.11

///|
const LIGHT_RECOVERY : Double = 0.16

///|
const LIGHT_DAMAGE : Int = 6

///|
const LIGHT_RANGE : Double = 54.0

///|
const LIGHT_HEIGHT : Double = 28.0

///|
const HEAVY_STARTUP : Double = 0.15

///|
const HEAVY_ACTIVE : Double = 0.12

///|
const HEAVY_RECOVERY : Double = 0.30

///|
const HEAVY_DAMAGE : Int = 11

///|
const HEAVY_RANGE : Double = 68.0

///|
const HEAVY_HEIGHT : Double = 30.0

///|
const LIGHT_COOLDOWN : Double = 0.38

///|
const HEAVY_COOLDOWN : Double = 0.72

///|
const HITSTUN_SECONDS : Double = 0.26

///|
const KNOCKBACK_LIGHT : Double = 130.0

///|
const KNOCKBACK_HEAVY : Double = 190.0

///|
const AI_PRESSURE_DISTANCE : Double = 120.0

///|
const AI_ATTACK_DISTANCE : Double = 92.0

///|
const AI_BACKSTEP_DISTANCE : Double = 54.0

///|
const AI_JUMP_CHANCE : Double = 0.12

///|
const CAPTURE_ENV : String = "KOF_CAPTURE"

///|
const CAPTURE_PATH : String = "kofarena_capture.png"

///|
const CAPTURE_DELAY_SECONDS : Double = 2.2

///|
const AUDIO_SAMPLE_RATE : Int = 22050

///|
const PROFILE_ENV : String = "KOF_PROFILE"

///|
const PROFILE_REPORT_SECONDS : Double = 1.0

///|
const AUDIO_DURATION_PUNCH : Double = 0.07

///|
const AUDIO_DURATION_HIT : Double = 0.11

///|
const AUDIO_DURATION_KO : Double = 0.22

///|
priv enum GamePhase {
  MainMenu
  Playing
  RoundOver
} derive(Eq, Debug)

///|
impl Show for GamePhase with output(self, logger) {
  let text = match self {
    MainMenu => "MainMenu"
    Playing => "Playing"
    RoundOver => "RoundOver"
  }
  logger.write_string(text)
}

///|
priv enum RoundOutcome {
  P1Win
  P2Win
  Draw
} derive(Debug)

///|
impl Show for RoundOutcome with output(self, logger) {
  let text = match self {
    P1Win => "P1Win"
    P2Win => "P2Win"
    Draw => "Draw"
  }
  logger.write_string(text)
}

///|
priv enum Facing {
  Left
  Right
} derive(Debug)

///|
impl Show for Facing with output(self, logger) {
  let text = match self {
    Left => "Left"
    Right => "Right"
  }
  logger.write_string(text)
}

///|
priv enum Pose {
  Idle
  Run
  Crouch
  Jump
  Attack
  Hit
  KO
} derive(Debug)

///|
impl Show for Pose with output(self, logger) {
  let text = match self {
    Idle => "Idle"
    Run => "Run"
    Crouch => "Crouch"
    Jump => "Jump"
    Attack => "Attack"
    Hit => "Hit"
    KO => "KO"
  }
  logger.write_string(text)
}

///|
priv enum AttackKind {
  Light
  Heavy
} derive(Debug)

///|
impl Show for AttackKind with output(self, logger) {
  let text = match self {
    Light => "Light"
    Heavy => "Heavy"
  }
  logger.write_string(text)
}

///|
priv enum PlayerId {
  P1
  P2
} derive(Eq, Debug)

///|
impl Show for PlayerId with output(self, logger) {
  let text = match self {
    P1 => "P1"
    P2 => "P2"
  }
  logger.write_string(text)
}

///|
priv enum InputMode {
  Human
  AI
} derive(Debug)

///|
impl Show for InputMode with output(self, logger) {
  let text = match self {
    Human => "Human"
    AI => "AI"
  }
  logger.write_string(text)
}

///|
priv struct Rect {
  x : Double
  y : Double
  w : Double
  h : Double
} derive(Debug)

///|
impl Show for Rect with output(self, logger) {
  logger.write_string(
    "{x: \{self.x}, y: \{self.y}, w: \{self.w}, h: \{self.h}}",
  )
}

///|
priv struct AttackSpec {
  startup : Double
  active : Double
  recovery : Double
  damage : Int
  range : Double
  height : Double
  knockback : Double
  cooldown : Double
}

///|
priv struct FighterState {
  id : PlayerId
  mut alive : Bool
  mut x : Double
  mut y : Double
  mut vx : Double
  mut vy : Double
  mut facing : Facing
  mut pose : Pose
  mut on_ground : Bool
  mut crouching : Bool
  mut health : Int
  mut attack_kind : AttackKind?
  mut attack_elapsed : Double
  mut attack_cooldown : Double
  mut attack_hit : Bool
  mut hitstun : Double
  mut invuln : Double
  mut backstep_timer : Double
  mut ai_timer : Double
  mut last_human_input : Double
  mut input_mode : InputMode
} derive(Debug)

///|
impl Show for FighterState with output(self, logger) {
  logger.write_string(
    "{id: \{self.id}, alive: \{self.alive}, x: \{self.x}, y: \{self.y}, vx: \{self.vx}, vy: \{self.vy}, facing: \{self.facing}, pose: \{self.pose}, on_ground: \{self.on_ground}, crouching: \{self.crouching}, health: \{self.health}, attack_kind: \{self.attack_kind}, attack_elapsed: \{self.attack_elapsed}, attack_cooldown: \{self.attack_cooldown}, attack_hit: \{self.attack_hit}, hitstun: \{self.hitstun}, invuln: \{self.invuln}, backstep_timer: \{self.backstep_timer}, ai_timer: \{self.ai_timer}, last_human_input: \{self.last_human_input}, input_mode: \{self.input_mode}}",
  )
}

///|
priv struct GameState {
  mut phase : GamePhase
  mut round_time : Double
  mut round_outcome : RoundOutcome?
  mut debug_fps : Bool
  mut p2_human_enabled : Bool
  menu_selected : Int
  mut round_banner_timer : Double
} derive(Debug)

///|
impl Show for GameState with output(self, logger) {
  logger.write_string(
    "{phase: \{self.phase}, round_time: \{self.round_time}, round_outcome: \{self.round_outcome}, debug_fps: \{self.debug_fps}, p2_human_enabled: \{self.p2_human_enabled}, menu_selected: \{self.menu_selected}, round_banner_timer: \{self.round_banner_timer}}",
  )
}

///|
priv struct StageObject {
  kind : StageObjectKind
  rect : Rect
} derive(Debug)

///|
impl Show for StageObject with output(self, logger) {
  logger.write_string("{kind: \{self.kind}, rect: \{self.rect}}")
}

///|
priv enum StageObjectKind {
  Ground
  Platform
  Pillar
} derive(Debug)

///|
impl Show for StageObjectKind with output(self, logger) {
  let text = match self {
    Ground => "Ground"
    Platform => "Platform"
    Pillar => "Pillar"
  }
  logger.write_string(text)
}

///|
priv struct SoundSet {
  mut punch : @raylib.Sound?
  mut hit : @raylib.Sound?
  mut ko : @raylib.Sound?
}

///|
priv struct AudioTone {
  freq : Double
  duration : Double
  amplitude : Double
}

///|
let game_state : GameState = {
  phase: MainMenu,
  round_time: ROUND_TIME_SECONDS,
  round_outcome: None,
  debug_fps: false,
  p2_human_enabled: false,
  menu_selected: 0,
  round_banner_timer: 0.0,
}

///|
let p1 : FighterState = {
  id: P1,
  alive: true,
  x: 0.0,
  y: 0.0,
  vx: 0.0,
  vy: 0.0,
  facing: Right,
  pose: Idle,
  on_ground: true,
  crouching: false,
  health: MAX_HEALTH,
  attack_kind: None,
  attack_elapsed: 0.0,
  attack_cooldown: 0.0,
  attack_hit: false,
  hitstun: 0.0,
  invuln: 0.0,
  backstep_timer: 0.0,
  ai_timer: 0.0,
  last_human_input: 0.0,
  input_mode: Human,
}

///|
let p2 : FighterState = {
  id: P2,
  alive: true,
  x: 0.0,
  y: 0.0,
  vx: 0.0,
  vy: 0.0,
  facing: Left,
  pose: Idle,
  on_ground: true,
  crouching: false,
  health: MAX_HEALTH,
  attack_kind: None,
  attack_elapsed: 0.0,
  attack_cooldown: 0.0,
  attack_hit: false,
  hitstun: 0.0,
  invuln: 0.0,
  backstep_timer: 0.0,
  ai_timer: 0.0,
  last_human_input: -1000.0,
  input_mode: AI,
}

///|

///|
let stage_objects : Array[StageObject] = []

///|
let sound_set : SoundSet = { punch: None, hit: None, ko: None }

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
let profile_delta_accum : Ref[Double] = { val: 0.0 }

///|
let fps_text_enabled : Ref[Bool] = { val: false }

///|
let rng : @random.Rand = @random.Rand::new()

///|
let title_entity : @entity.Entity = @entity.Entity::new()

///|
let menu_entity : @entity.Entity = @entity.Entity::new()

///|
let timer_entity : @entity.Entity = @entity.Entity::new()

///|
let info_entity : @entity.Entity = @entity.Entity::new()

///|
let debug_entity : @entity.Entity = @entity.Entity::new()

///|
let banner_entity : @entity.Entity = @entity.Entity::new()

///|
let p1_bar_back : @entity.Entity = @entity.Entity::new()

///|
let p1_bar_fill : @entity.Entity = @entity.Entity::new()

///|
let p2_bar_back : @entity.Entity = @entity.Entity::new()

///|
let p2_bar_fill : @entity.Entity = @entity.Entity::new()

///|
let stage_bg_entity : @entity.Entity = @entity.Entity::new()

///|
let floor_entity : @entity.Entity = @entity.Entity::new()

///|
let platform_entity : @entity.Entity = @entity.Entity::new()

///|
let left_pillar_entity : @entity.Entity = @entity.Entity::new()

///|
let right_pillar_entity : @entity.Entity = @entity.Entity::new()

///|
let left_fighter_entity : @entity.Entity = @entity.Entity::new()

///|
let right_fighter_entity : @entity.Entity = @entity.Entity::new()

///|
let left_attack_entity : @entity.Entity = @entity.Entity::new()

///|
let right_attack_entity : @entity.Entity = @entity.Entity::new()

///|
let left_crouch_entity : @entity.Entity = @entity.Entity::new()

///|
let right_crouch_entity : @entity.Entity = @entity.Entity::new()
