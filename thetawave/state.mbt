///|
const VIEWPORT_WIDTH : Double = 512.0

///|
const VIEWPORT_HEIGHT : Double = 320.0

///|
const ZOOM : Double = 2.5

///|
const FPS : UInt = 60

///|
const DEBUG_CAPTURE_ENV : String = "THETAWAVE_CAPTURE"

///|
const DEBUG_CAPTURE_PATH : String = "thetawave_capture.png"

///|
const DEBUG_CAPTURE_DELAY_SECONDS : Double = 2.2

///|
const DEBUG_PROFILE_ENV : String = "THETAWAVE_PROFILE"

///|
const PROFILE_REPORT_SECONDS : Double = 1.0

///|
const HUD_SIDE_COLUMN_WIDTH : Double = VIEWPORT_WIDTH * 0.1

///|
const HUD_CENTER_BAND_WIDTH : Double = VIEWPORT_WIDTH * 0.8

///|
const HUD_CENTER_LEFT_X : Double = HUD_SIDE_COLUMN_WIDTH +
  HUD_CENTER_BAND_WIDTH * 0.25

///|
const HUD_TOP_SPLIT_X : Double = HUD_SIDE_COLUMN_WIDTH +
  HUD_CENTER_BAND_WIDTH * 0.5

///|
const HUD_TOP_PANEL_PADDING : Double = 8.0

///|
const HUD_TOP_LEFT_PANEL_X : Double = HUD_SIDE_COLUMN_WIDTH +
  HUD_TOP_PANEL_PADDING

///|
const HUD_TOP_RIGHT_PANEL_X : Double = HUD_TOP_SPLIT_X + HUD_TOP_PANEL_PADDING

///|
const HUD_TOP_PANEL_WIDTH : Double = HUD_CENTER_BAND_WIDTH * 0.5 -
  HUD_TOP_PANEL_PADDING * 2.0

///|
const HUD_ABILITY_SLOT_SIZE : Double = 32.0

///|
const HUD_ABILITY_SLOT_LEFT_X : Double = 0.0

///|
const HUD_ABILITY_SLOT_CENTER_X : Double = HUD_ABILITY_SLOT_LEFT_X +
  HUD_ABILITY_SLOT_SIZE / 2.0

///|
const HUD_ABILITY_SLOT1_CENTER_Y : Double = 248.0

///|
const HUD_ABILITY_SLOT2_CENTER_Y : Double = 176.0

///|
const HUD_ABILITY_SLOT_FILL_WIDTH : Double = HUD_ABILITY_SLOT_SIZE

///|
const HUD_ABILITY_SLOT1_FILL_BOTTOM_Y : Double = HUD_ABILITY_SLOT1_CENTER_Y +
  HUD_ABILITY_SLOT_SIZE / 2.0

///|
const HUD_ABILITY_SLOT2_FILL_BOTTOM_Y : Double = HUD_ABILITY_SLOT2_CENTER_Y +
  HUD_ABILITY_SLOT_SIZE / 2.0

///|
const HUD_HEALTH_BAR_BG_X : Double = 32.0

///|
const HUD_HEALTH_BAR_FILL_X : Double = 33.0

///|
const HUD_SHIELD_BAR_BG_X : Double = 46.0

///|
const HUD_SHIELD_BAR_FILL_X : Double = 47.0

///|
const WORLD_X_SCALE : Double = 0.35

///|
const WORLD_Y_SCALE : Double = 0.30

///|
const PLAYER_HALF_SIZE : Double = 14.0

///|
const ENEMY_HALF_SIZE : Double = 12.0

///|
const CONSUMABLE_HALF_SIZE : Double = 8.0

///|
const ITEM_HALF_SIZE : Double = 9.0

///|
const PLAYER_INVULNERABLE_SECONDS : Double = 0.8

///|
const SHIELD_RECHARGE_DELAY_SECONDS : Double = 2.0

///|
const MAX_PROJECTILE_COUNT : Int = 8

///|
const SCORE_PER_KILL : Int = 10

///|
priv struct TextState {
  mut content : String
  mut color : String
  mut font : String
  mut baseline : @math.VAlign
  mut align : @math.HAlign
}

///|
fn text_state(
  content : String,
  color? : String = "white",
  font? : String = UI_FONT_SMALL,
  baseline? : @math.VAlign = Top,
  align? : @math.HAlign = Left,
) -> TextState {
  { content, color, font, baseline, align }
}

///|
fn text_anchor(text : TextState) -> @sprite.Anchor {
  let x = match text.align {
    Left => -0.5
    Center => 0.0
    Right => 0.5
  }
  let y = match text.baseline {
    Top => 0.5
    Center => 0.0
    Bottom => -0.5
  }
  @sprite.Anchor(@math.Vec2(x, y))
}

///|
fn entity_transform_2d(
  position : @math.Vec2,
  zindex? : Int = 0,
) -> @transform.Transform {
  {
    translation: @math.Vec3::new(position[X], position[Y], zindex.to_double()),
    rotation: @math.Quat::identity(),
    scale: @math.Vec3::one(),
  }
}

///|
fn set_entity_position(entity : @entity.Entity, position : @math.Vec2) -> Unit {
  let transform = @transform.transforms()
    .get(entity)
    .unwrap_or(entity_transform_2d(position))
  @transform.transforms().set(entity, {
    ..transform,
    translation: @math.Vec3::new(
      position[X],
      position[Y],
      transform.translation.z,
    ),
  })
}

///|
fn entity_position(entity : @entity.Entity) -> @math.Vec2? {
  @transform.transforms()
  .get(entity)
  .map(fn(transform) {
    @math.Vec2(transform.translation.x, transform.translation.y)
  })
}

///|
fn remove_entity_position(entity : @entity.Entity) -> Unit {
  @transform.transforms().remove(entity)
}

///|
fn set_entity_visibility(entity : @entity.Entity, visible : Bool) -> Unit {
  @visibility.visibilities().set(entity, if visible { Visible } else { Hidden })
}

///|
enum ScreenState {
  MainMenu
  CharacterSelection
  InGame
} derive(Eq)

///|
enum BackgroundKind {
  Menu
  CharacterSelection
  Game
  GameOver
  Victory
} derive(Eq)

///|
enum RunPhase {
  Playing
  Paused
  GameOver
  Victory
} derive(Eq)

///|
enum CharacterType {
  Captain
  Juggernaut
} derive(Eq)

///|
priv enum CharacterStatType {
  Damage
  Health
  Range
  FireRate
  Size
  Speed
}

///|
enum ProjectileKind {
  Blast
  Bullet
} derive(Eq)

///|
enum BulletFaction {
  Ally
  Enemy
} derive(Eq)

///|
enum SpecialAbility {
  MegaBlast
  Charge
} derive(Eq)

///|
enum EnemyKind {
  Pawn
  Drone
  TutorialDrone
  Shelly
  StraferRight
  StraferLeft
  MissileLauncher
  Missile
  MoneyAsteroid
  CrustlingRight
  CrustlingLeft
  Ferritharax
  MechaFerritharax
  MechaSaucetron
  Hauler
} derive(Eq)

///|
enum ConsumableKind {
  Money1
  Money3
  HealthWrench
  Armor
  GainProjectiles
} derive(Eq)

///|
enum ItemKind {
  EnhancedPlating
} derive(Eq)

///|
enum EnemyMovementKind {
  DownBrake
  DownHorizontal
  Homing
  DownOnly
  BossHover
} derive(Eq)

///|
enum EnemyShooterKind {
  NoShooter
  PawnBlaster
  StraferBlaster
  ShellyRing
  MissileLauncherSpawner
  BossSpawner
} derive(Eq)

///|
priv enum EnemyPartRole {
  PartGeneric
  PartShoulderLeft
  PartShoulderRight
  PartArmLeft
  PartArmRight
  PartClawLeft
  PartClawRight
}

///|
priv struct Enemy {
  kind : EnemyKind
  mut hp : Int
  speed_x : Double
  speed_y : Double
  collision_damage : Int
  escape_defense_delta : Int
  movement : EnemyMovementKind
  mut horizontal_dir : Double
  shooter : EnemyShooterKind
  shoot_interval : Double
  mut shoot_cooldown : Double
  mut boss_phase : Int
  mut boss_phase_elapsed : Double
  mut boss_left_pawn_timer : Double
  mut boss_left_drone_timer : Double
  mut boss_right_pawn_timer : Double
  mut boss_right_drone_timer : Double
  mut boss_left_missile_timer : Double
  mut boss_right_missile_timer : Double
  mut boss_left_weapon_timer : Double
  mut boss_right_weapon_timer : Double
}

///|
priv struct Bullet {
  mut ttl : Double
  velocity : @math.Vec2
  damage : Int
  faction : BulletFaction
  radius : Double
}

///|
priv struct Consumable {
  kind : ConsumableKind
  speed : Double
}

///|
priv struct ItemDrop {
  kind : ItemKind
  speed : Double
}

///|
priv struct EnemyVisualPart {
  entity : @entity.Entity
  role : EnemyPartRole
  offset : @math.Vec2
  bob_amp : Double
  bob_speed : Double
  bob_phase : Double
}

///|
priv struct CharacterConfig {
  name : String
  speed : Double
  max_hull : Int
  max_shield : Int
  shield_recharge_rate : Double
  attraction_distance : Double
  attraction_acceleration : Double
  base_cooldown_multiplier : Double
  shoot_interval : Double
  special_cooldown : Double
  projectile_kind : ProjectileKind
  projectile_speed : Double
  projectile_damage : Int
  projectile_ttl : Double
  special_ability : SpecialAbility
}

///|
priv struct EnemyArchetype {
  hp : Int
  speed_x : Double
  speed_y : Double
  collision_damage : Int
  escape_defense_delta : Int
  movement : EnemyMovementKind
  horizontal_dir : Double
  shooter : EnemyShooterKind
  shoot_interval : Double
  initial_shoot_delay : Double
}

///|
fn character_config(character : CharacterType) -> CharacterConfig {
  match character {
    Captain =>
      {
        name: "Captain",
        speed: 300.0,
        max_hull: 80,
        max_shield: 5,
        shield_recharge_rate: 1.0,
        attraction_distance: 150.0,
        attraction_acceleration: 15.0,
        base_cooldown_multiplier: 2.0,
        shoot_interval: 0.25,
        special_cooldown: 2.5,
        projectile_kind: Blast,
        projectile_speed: 800.0,
        projectile_damage: 10,
        projectile_ttl: 1.0,
        special_ability: MegaBlast,
      }
    Juggernaut =>
      {
        name: "Juggernaut",
        speed: 250.0,
        max_hull: 140,
        max_shield: 10,
        shield_recharge_rate: 0.75,
        attraction_distance: 150.0,
        attraction_acceleration: 15.0,
        base_cooldown_multiplier: 2.7,
        shoot_interval: 0.30,
        special_cooldown: 3.0,
        projectile_kind: Bullet,
        projectile_speed: 650.0,
        projectile_damage: 8,
        projectile_ttl: 0.4,
        special_ability: Charge,
      }
  }
}

///|
fn character_stat_percent(
  character : CharacterType,
  stat : CharacterStatType,
) -> Double {
  let percent = match character {
    Captain =>
      match stat {
        Damage => (10.0 + 10.0 * 1.0) / 50.0
        Health => (80.0 + 5.0) / 160.0
        Range => 1.0 / 1.0
        FireRate => (5.0 - 2.0) / 5.0
        Size => 2.0 * 4.0 / 30.0
        Speed => (25.0 + 25.0 + 10.0 + 10.0 + 300.0 + 300.0) / 800.0
      }
    Juggernaut =>
      match stat {
        Damage => (15.0 + 10.0 * 3.0) / 50.0
        Health => (140.0 + 10.0) / 160.0
        Range => 0.4 / 1.0
        FireRate => (5.0 - 2.7) / 5.0
        Size => 4.0 * 5.5 / 30.0
        Speed => (25.0 + 25.0 + 10.0 + 10.0 + 250.0 + 250.0) / 800.0
      }
  }
  if percent < 0.0 {
    0.0
  } else if percent > 1.0 {
    1.0
  } else {
    percent
  }
}

///|
fn character_carousel_neighbors(
  character : CharacterType,
) -> (CharacterType, CharacterType, CharacterType) {
  match character {
    Captain => (Juggernaut, Captain, Juggernaut)
    Juggernaut => (Captain, Juggernaut, Captain)
  }
}

///|
priv struct GameState {
  player : @entity.Entity
  background : @entity.Entity
  score_ui : @entity.Entity
  hull_ui : @entity.Entity
  shield_ui : @entity.Entity
  defense_ui : @entity.Entity
  stage_ui : @entity.Entity
  timer_ui : @entity.Entity
  banner_ui : @entity.Entity
  menu_logo_ui : @entity.Entity
  menu_button_start_ui : @entity.Entity
  menu_button_options_ui : @entity.Entity
  menu_button_compendium_ui : @entity.Entity
  menu_button_exit_ui : @entity.Entity
  character_portrait_ui : @entity.Entity
  character_description_ui : @entity.Entity
  phase_prompt_ui : @entity.Entity
  warning_gradient_ui : @entity.Entity
  defense_gradient_ui : @entity.Entity
  hud_health_label_ui : @entity.Entity
  hud_health_bar_bg_ui : @entity.Entity
  hud_health_bar_fill_ui : @entity.Entity
  hud_shield_bar_bg_ui : @entity.Entity
  hud_shield_bar_fill_ui : @entity.Entity
  hud_defense_label_ui : @entity.Entity
  hud_defense_bar_bg_ui : @entity.Entity
  hud_defense_bar_fill_ui : @entity.Entity
  hud_slot1_bg_ui : @entity.Entity
  hud_slot1_icon_ui : @entity.Entity
  hud_slot1_fill_ui : @entity.Entity
  hud_slot2_bg_ui : @entity.Entity
  hud_slot2_icon_ui : @entity.Entity
  hud_slot2_fill_ui : @entity.Entity
  score_text : TextState
  hull_text : TextState
  shield_text : TextState
  defense_text : TextState
  stage_text : TextState
  timer_text : TextState
  banner_text : TextState
  mut screen : ScreenState
  mut background_kind : BackgroundKind
  mut phase : RunPhase
  mut selected_character : CharacterType
  mut cs_p1_joined : Bool
  mut cs_p1_ready : Bool
  mut cs_p1_character : CharacterType
  mut cs_p2_joined : Bool
  mut cs_p2_ready : Bool
  mut cs_p2_character : CharacterType
  mut score : Int
  mut shots_fired : Int
  mut shots_hit : Int
  mut enemies_destroyed : Int
  mut money : Int
  mut armor : Int
  mut hull : Int
  mut max_hull : Int
  mut shield : Int
  mut max_shield : Int
  mut shield_recharge_rate : Double
  mut shield_recharge_delay : Double
  mut shield_recharge_progress : Double
  mut defense : Int
  mut elapsed : Double
  mut stage_index : Int
  mut stage_elapsed : Double
  mut stage_spawn_timer : Double
  mut stage_label : String
  mut boss_spawned : Bool
  mut plating_count : Int
  mut allow_move : Bool
  mut allow_main_attack : Bool
  mut allow_special : Bool
  mut tutorial_lesson : Int
  mut tutorial_up_progress : Double
  mut tutorial_down_progress : Double
  mut tutorial_left_progress : Double
  mut tutorial_right_progress : Double
  mut tutorial_up_left_progress : Double
  mut tutorial_up_right_progress : Double
  mut tutorial_down_left_progress : Double
  mut tutorial_down_right_progress : Double
  mut tutorial_slot1_destroy : Int
  mut tutorial_slot1_protect : Int
  mut tutorial_slot2_destroy : Int
  mut tutorial_spawn_timer : Double
  mut center_intro_text : String
  mut center_intro_timer : Double
  mut warning_gradient_timer : Double
  mut defense_gradient_timer : Double
  mut shoot_cooldown : Double
  mut special_cooldown : Double
  mut player_invulnerable : Double
  mut charge_time_left : Double
  mut charge_velocity : @math.Vec2
  mut attraction_distance : Double
  mut attraction_acceleration : Double
  mut base_cooldown_multiplier : Double
  mut cooldown_multiplier : Double
  mut player_speed : Double
  mut shoot_interval : Double
  mut special_cooldown_base : Double
  mut projectile_count : Int
  mut projectile_kind : ProjectileKind
  mut projectile_speed : Double
  mut projectile_damage : Int
  mut projectile_ttl : Double
  mut special_ability : SpecialAbility
  mut main_menu_selected : Int
  mut music_started : Bool
  rand : @random.Rand
}

///|
let game_state : GameState = {
  player: @entity.Entity::new(),
  background: @entity.Entity::new(),
  score_ui: @entity.Entity::new(),
  hull_ui: @entity.Entity::new(),
  shield_ui: @entity.Entity::new(),
  defense_ui: @entity.Entity::new(),
  stage_ui: @entity.Entity::new(),
  timer_ui: @entity.Entity::new(),
  banner_ui: @entity.Entity::new(),
  menu_logo_ui: @entity.Entity::new(),
  menu_button_start_ui: @entity.Entity::new(),
  menu_button_options_ui: @entity.Entity::new(),
  menu_button_compendium_ui: @entity.Entity::new(),
  menu_button_exit_ui: @entity.Entity::new(),
  character_portrait_ui: @entity.Entity::new(),
  character_description_ui: @entity.Entity::new(),
  phase_prompt_ui: @entity.Entity::new(),
  warning_gradient_ui: @entity.Entity::new(),
  defense_gradient_ui: @entity.Entity::new(),
  hud_health_label_ui: @entity.Entity::new(),
  hud_health_bar_bg_ui: @entity.Entity::new(),
  hud_health_bar_fill_ui: @entity.Entity::new(),
  hud_shield_bar_bg_ui: @entity.Entity::new(),
  hud_shield_bar_fill_ui: @entity.Entity::new(),
  hud_defense_label_ui: @entity.Entity::new(),
  hud_defense_bar_bg_ui: @entity.Entity::new(),
  hud_defense_bar_fill_ui: @entity.Entity::new(),
  hud_slot1_bg_ui: @entity.Entity::new(),
  hud_slot1_icon_ui: @entity.Entity::new(),
  hud_slot1_fill_ui: @entity.Entity::new(),
  hud_slot2_bg_ui: @entity.Entity::new(),
  hud_slot2_icon_ui: @entity.Entity::new(),
  hud_slot2_fill_ui: @entity.Entity::new(),
  score_text: text_state(
    "Score: 0",
    color="white",
    font=UI_FONT_SMALL,
    baseline=Top,
    align=Left,
  ),
  hull_text: text_state(
    "Hull: 0",
    color="white",
    font=UI_FONT_SMALL,
    baseline=Top,
    align=Left,
  ),
  shield_text: text_state(
    "Shield: 0",
    color="white",
    font=UI_FONT_SMALL,
    baseline=Top,
    align=Left,
  ),
  defense_text: text_state(
    "Defense: 0",
    color="white",
    font=UI_FONT_SMALL,
    baseline=Top,
    align=Left,
  ),
  stage_text: text_state(
    "Stage",
    color="white",
    font=UI_FONT_SMALL,
    baseline=Top,
    align=Left,
  ),
  timer_text: text_state(
    "Time: 0",
    color="white",
    font=UI_FONT_SMALL,
    baseline=Top,
    align=Left,
  ),
  banner_text: text_state(
    "Press Enter",
    color="skyblue",
    font=UI_FONT_MEDIUM,
    baseline=Top,
    align=Left,
  ),
  screen: MainMenu,
  background_kind: Menu,
  phase: Playing,
  selected_character: Captain,
  cs_p1_joined: false,
  cs_p1_ready: false,
  cs_p1_character: Captain,
  cs_p2_joined: false,
  cs_p2_ready: false,
  cs_p2_character: Juggernaut,
  score: 0,
  shots_fired: 0,
  shots_hit: 0,
  enemies_destroyed: 0,
  money: 0,
  armor: 0,
  hull: 80,
  max_hull: 80,
  shield: 5,
  max_shield: 5,
  shield_recharge_rate: 1.0,
  shield_recharge_delay: 0.0,
  shield_recharge_progress: 0.0,
  defense: 100,
  elapsed: 0.0,
  stage_index: 0,
  stage_elapsed: 0.0,
  stage_spawn_timer: 0.0,
  stage_label: "",
  boss_spawned: false,
  plating_count: 0,
  allow_move: true,
  allow_main_attack: true,
  allow_special: true,
  tutorial_lesson: 0,
  tutorial_up_progress: 0.0,
  tutorial_down_progress: 0.0,
  tutorial_left_progress: 0.0,
  tutorial_right_progress: 0.0,
  tutorial_up_left_progress: 0.0,
  tutorial_up_right_progress: 0.0,
  tutorial_down_left_progress: 0.0,
  tutorial_down_right_progress: 0.0,
  tutorial_slot1_destroy: 0,
  tutorial_slot1_protect: 0,
  tutorial_slot2_destroy: 0,
  tutorial_spawn_timer: 0.0,
  center_intro_text: "",
  center_intro_timer: 0.0,
  warning_gradient_timer: 0.0,
  defense_gradient_timer: 0.0,
  shoot_cooldown: 0.0,
  special_cooldown: 0.0,
  player_invulnerable: 0.0,
  charge_time_left: 0.0,
  charge_velocity: @math.Vec2(0.0, 0.0),
  attraction_distance: 150.0,
  attraction_acceleration: 15.0,
  base_cooldown_multiplier: 2.0,
  cooldown_multiplier: 2.0,
  player_speed: 300.0,
  shoot_interval: 0.25,
  special_cooldown_base: 2.5,
  projectile_count: 1,
  projectile_kind: Blast,
  projectile_speed: 800.0,
  projectile_damage: 10,
  projectile_ttl: 1.0,
  special_ability: MegaBlast,
  main_menu_selected: 0,
  music_started: false,
  rand: @random.Rand::new(),
}

///|
let ui_initialized : Ref[Bool] = { val: false }

///|
let debug_bootstrapped : Ref[Bool] = { val: false }

///|
let debug_capture_enabled : Ref[Bool] = { val: false }

///|
let debug_capture_started_at : Ref[Double] = { val: 0.0 }

///|
let debug_capture_taken : Ref[Bool] = { val: false }

///|
let debug_profile_enabled : Ref[Bool] = { val: false }

///|
let debug_profile_started_at : Ref[Double] = { val: 0.0 }

///|
let debug_profile_last_report_at : Ref[Double] = { val: 0.0 }

///|
let debug_profile_frame_count : Ref[Int] = { val: 0 }

///|
let debug_profile_delta_accum : Ref[Double] = { val: 0.0 }

///|
let enemies : Map[@entity.Entity, Enemy] = Map::new()

///|
let enemy_visual_parts : Map[@entity.Entity, Array[EnemyVisualPart]] = Map::new()

///|
let bullets : Map[@entity.Entity, Bullet] = Map::new()

///|
let consumables : Map[@entity.Entity, Consumable] = Map::new()

///|
let items : Map[@entity.Entity, ItemDrop] = Map::new()

///|
fn env_flag_enabled(name : String) -> Bool {
  match @env.get_env_var(name) {
    Some(raw) =>
      raw == "1" ||
      raw == "true" ||
      raw == "TRUE" ||
      raw == "yes" ||
      raw == "YES" ||
      raw == "on" ||
      raw == "ON"
    None => false
  }
}

///|
fn ensure_debug_runtime_state() -> Unit {
  if debug_bootstrapped.val {
    return
  }
  let started_at = @time.elapsed()
  debug_capture_enabled.val = env_flag_enabled(DEBUG_CAPTURE_ENV)
  debug_capture_started_at.val = started_at
  debug_capture_taken.val = false
  debug_profile_enabled.val = env_flag_enabled(DEBUG_PROFILE_ENV)
  debug_profile_started_at.val = started_at
  debug_profile_last_report_at.val = started_at
  debug_profile_frame_count.val = 0
  debug_profile_delta_accum.val = 0.0
  debug_bootstrapped.val = true
}

///|
fn initial_player_position() -> @math.Vec2 {
  @math.Vec2(VIEWPORT_WIDTH / 2.0, VIEWPORT_HEIGHT - 34.0)
}

///|
fn is_ferritharax_family(kind : EnemyKind) -> Bool {
  kind is Ferritharax || kind is MechaFerritharax || kind is MechaSaucetron
}

///|
fn ferritharax_attack_duration(kind : EnemyKind) -> Double {
  match kind {
    Ferritharax => 10.0
    MechaFerritharax => 8.0
    MechaSaucetron => 7.0
    _ => 10.0
  }
}

///|
fn ferritharax_missile_period(kind : EnemyKind) -> Double {
  match kind {
    Ferritharax => 5.0
    MechaFerritharax => 7.0
    MechaSaucetron => 5.5
    _ => 5.0
  }
}

///|
fn has_ferritharax_arm_weapons(kind : EnemyKind) -> Bool {
  kind is MechaFerritharax || kind is MechaSaucetron
}

///|
fn enemy_archetype(kind : EnemyKind) -> EnemyArchetype {
  match kind {
    Pawn =>
      {
        hp: 20,
        speed_x: 0.0,
        speed_y: 85.0,
        collision_damage: 8,
        escape_defense_delta: -8,
        movement: DownBrake,
        horizontal_dir: 0.0,
        shooter: PawnBlaster,
        shoot_interval: 3.0,
        initial_shoot_delay: 1.0,
      }
    Drone =>
      {
        hp: 30,
        speed_x: 0.0,
        speed_y: 100.0,
        collision_damage: 12,
        escape_defense_delta: -8,
        movement: DownBrake,
        horizontal_dir: 0.0,
        shooter: NoShooter,
        shoot_interval: 0.0,
        initial_shoot_delay: 0.0,
      }
    TutorialDrone =>
      {
        hp: 30,
        speed_x: 0.0,
        speed_y: 100.0,
        collision_damage: 12,
        escape_defense_delta: -8,
        movement: DownBrake,
        horizontal_dir: 0.0,
        shooter: NoShooter,
        shoot_interval: 0.0,
        initial_shoot_delay: 0.0,
      }
    Shelly =>
      {
        hp: 50,
        speed_x: 0.0,
        speed_y: 75.0,
        collision_damage: 8,
        escape_defense_delta: -8,
        movement: DownBrake,
        horizontal_dir: 0.0,
        shooter: ShellyRing,
        shoot_interval: 1.6,
        initial_shoot_delay: 1.0,
      }
    StraferRight =>
      {
        hp: 20,
        speed_x: 75.0,
        speed_y: 75.0,
        collision_damage: 10,
        escape_defense_delta: -12,
        movement: DownHorizontal,
        horizontal_dir: 1.0,
        shooter: StraferBlaster,
        shoot_interval: 3.0,
        initial_shoot_delay: 1.0,
      }
    StraferLeft =>
      {
        hp: 20,
        speed_x: 75.0,
        speed_y: 75.0,
        collision_damage: 10,
        escape_defense_delta: -12,
        movement: DownHorizontal,
        horizontal_dir: -1.0,
        shooter: StraferBlaster,
        shoot_interval: 3.0,
        initial_shoot_delay: 1.0,
      }
    MissileLauncher =>
      {
        hp: 50,
        speed_x: 0.0,
        speed_y: 75.0,
        collision_damage: 6,
        escape_defense_delta: -15,
        movement: DownBrake,
        horizontal_dir: 0.0,
        shooter: MissileLauncherSpawner,
        shoot_interval: 4.0,
        initial_shoot_delay: 1.0,
      }
    Missile =>
      {
        hp: 15,
        speed_x: 150.0,
        speed_y: 150.0,
        collision_damage: 30,
        escape_defense_delta: 0,
        movement: Homing,
        horizontal_dir: 0.0,
        shooter: NoShooter,
        shoot_interval: 0.0,
        initial_shoot_delay: 0.0,
      }
    MoneyAsteroid =>
      {
        hp: 50,
        speed_x: 0.0,
        speed_y: 75.0,
        collision_damage: 7,
        escape_defense_delta: 0,
        movement: DownOnly,
        horizontal_dir: 0.0,
        shooter: NoShooter,
        shoot_interval: 0.0,
        initial_shoot_delay: 0.0,
      }
    CrustlingRight =>
      {
        hp: 40,
        speed_x: 80.0,
        speed_y: 45.0,
        collision_damage: 20,
        escape_defense_delta: -15,
        movement: DownHorizontal,
        horizontal_dir: 1.0,
        shooter: NoShooter,
        shoot_interval: 0.0,
        initial_shoot_delay: 0.0,
      }
    CrustlingLeft =>
      {
        hp: 40,
        speed_x: 80.0,
        speed_y: 45.0,
        collision_damage: 20,
        escape_defense_delta: -15,
        movement: DownHorizontal,
        horizontal_dir: -1.0,
        shooter: NoShooter,
        shoot_interval: 0.0,
        initial_shoot_delay: 0.0,
      }
    Ferritharax =>
      {
        hp: 1200,
        speed_x: 48.0,
        speed_y: 52.0,
        collision_damage: 24,
        escape_defense_delta: -30,
        movement: BossHover,
        horizontal_dir: 1.0,
        shooter: ShellyRing,
        shoot_interval: 1.2,
        initial_shoot_delay: 2.5,
      }
    MechaFerritharax =>
      {
        hp: 1800,
        speed_x: 62.0,
        speed_y: 58.0,
        collision_damage: 26,
        escape_defense_delta: -35,
        movement: BossHover,
        horizontal_dir: 1.0,
        shooter: MissileLauncherSpawner,
        shoot_interval: 3.2,
        initial_shoot_delay: 2.0,
      }
    MechaSaucetron =>
      {
        hp: 2400,
        speed_x: 70.0,
        speed_y: 60.0,
        collision_damage: 30,
        escape_defense_delta: -40,
        movement: BossHover,
        horizontal_dir: 1.0,
        shooter: BossSpawner,
        shoot_interval: 4.6,
        initial_shoot_delay: 2.0,
      }
    Hauler =>
      {
        hp: 80,
        speed_x: 0.0,
        speed_y: 70.0,
        collision_damage: 0,
        escape_defense_delta: 5,
        movement: DownBrake,
        horizontal_dir: 0.0,
        shooter: NoShooter,
        shoot_interval: 0.0,
        initial_shoot_delay: 0.0,
      }
  }
}
