///|
const CAMPAIGN_CAPTURE_ENV : String = "TOPDOWN_ACTION_CAMPAIGN_CAPTURE"

///|
const CAMPAIGN_CAPTURE_DELAY_SECONDS : Double = 2.5

///|
const CAMPAIGN_CAPTURE_PATH : String = "topdown_action_campaign_capture.png"

///|
const CAMPAIGN_PROFILE_ENV : String = "TOPDOWN_ACTION_CAMPAIGN_PROFILE"

///|
const CAMPAIGN_SPRITE_AUDIT_ENV : String = "TOPDOWN_ACTION_CAMPAIGN_SPRITE_AUDIT"

///|
const CAMPAIGN_AUDIT_OUTPUT_DIR : String = "/tmp"

///|
const CAMPAIGN_TILE_Z : Double = 5.0

///|
const CAMPAIGN_PROP_Z : Double = 18.0

///|
const CAMPAIGN_PLAYER_Z : Double = 34.0

///|
const CAMPAIGN_ENEMY_Z : Double = 32.0

///|
const CAMPAIGN_FOLLOWER_Z : Double = 30.0

///|
const CAMPAIGN_PROJECTILE_Z : Double = 36.0

///|
const CAMPAIGN_HUD_Z : Double = 420.0

///|
const CAMPAIGN_WORLD_PADDING : Double = 3.0

///|
const CAMPAIGN_PLAYER_RESPAWN_SECONDS : Double = 1.1

///|
const CAMPAIGN_FOLLOWER_JOIN_BURST : Int = 3

///|
priv struct CampaignWorldTile {
  floor_entity : @entity.Entity
  prop_entity : @entity.Entity?
  center : @math.Vec2
  floor_visual : @topdown_platform.ImageVisualDef
  prop_visual : @topdown_platform.ImageVisualDef?
}

///|
priv struct CampaignActorRuntime {
  entity : @entity.Entity
  archetype_id : String
  mut hp : Int
  mut position : @math.Vec2
  mut facing : @topdown_platform.Facing
  mut moving : Bool
  mut anim_elapsed : Double
  mut attack_cd : Double
  mut invuln_ttl : Double
  mut last_sprite_path : String
  mut ai_wander_dir : @math.Vec2
  mut ai_wander_timer : Double
}

///|
priv struct CampaignProjectileRuntime {
  entity : @entity.Entity
  owner_enemy : Bool
  mut position : @math.Vec2
  velocity : @math.Vec2
  radius : Double
  damage : Int
  mut ttl : Double
}

///|
priv struct CampaignFollowerRuntime {
  entity : @entity.Entity
  mut position : @math.Vec2
}

///|
priv struct CampaignCampRuntime {
  position : @math.Vec2
  rescue_count : Int
  mut triggered : Bool
}

///|
priv struct CampaignExitRuntime {
  position : @math.Vec2
  radius : Double
}

///|
pub struct CampaignSpawnCursor {
  mut wave_index : Int
  mut entry_index : Int
  mut spawned_in_entry : Int
  mut wait_timer : Double
  mut wave_started : Bool
  mut all_spawned : Bool
}

///|
pub struct CampaignRunState {
  mut phase : CampaignPhase
  mut stage_index : Int
  mut lives : Int
  mut score : Int
  mut rescued_total : Int
  mut rescued_delivered : Int
  mut required_rescued : Int
  mut stage_intro_ttl : Double
  mut stage_clear_ttl : Double
  mut status_message : String
  mut spawn_cursor : CampaignSpawnCursor
}

///|
pub struct CampaignWorldState {
  mut tile_size : Double
  mut rows : Int
  mut cols : Int
  mut world_width : Double
  mut world_height : Double
  mut player_spawn : @math.Vec2
  mut camera_origin : @math.Vec2
  enemy_spawns : Array[@topdown_platform.ActorSpawnPoint]
  tagged_points : Array[@topdown_platform.TaggedPoint]
  blocking_rects : Array[@math.Rect]
}

///|
pub struct CampaignInputState {
  mut move_intent : @math.Vec2
  mut primary_requested : Bool
  mut secondary_requested : Bool
}

///|
pub struct CampaignUiState {
  mut title_text : String
  mut hud_text : String
  mut message_text : String
}

///|
let campaign_run_state : CampaignRunState = {
  phase: MainMenu,
  stage_index: 0,
  lives: 0,
  score: 0,
  rescued_total: 0,
  rescued_delivered: 0,
  required_rescued: 0,
  stage_intro_ttl: 0.0,
  stage_clear_ttl: 0.0,
  status_message: "",
  spawn_cursor: {
    wave_index: 0,
    entry_index: 0,
    spawned_in_entry: 0,
    wait_timer: 0.0,
    wave_started: false,
    all_spawned: true,
  },
}

///|
let campaign_world_state : CampaignWorldState = {
  tile_size: 64.0,
  rows: 0,
  cols: 0,
  world_width: 0.0,
  world_height: 0.0,
  player_spawn: @math.Vec2(64.0, 64.0),
  camera_origin: @math.Vec2(0.0, 0.0),
  enemy_spawns: [],
  tagged_points: [],
  blocking_rects: [],
}

///|
let campaign_input_state : CampaignInputState = {
  move_intent: @math.Vec2(0.0, 0.0),
  primary_requested: false,
  secondary_requested: false,
}

///|
let campaign_ui_state : CampaignUiState = {
  title_text: "",
  hud_text: "",
  message_text: "",
}

///|
let campaign_active_plugin : Ref[TopDownCampaignPluginDef?] = { val: None }

///|
let campaign_player_runtime : Ref[CampaignActorRuntime?] = { val: None }

///|
let campaign_enemy_runtimes : Array[CampaignActorRuntime] = []

///|
let campaign_projectile_runtimes : Array[CampaignProjectileRuntime] = []

///|
let campaign_follower_runtimes : Array[CampaignFollowerRuntime] = []

///|
let campaign_world_tiles : Array[CampaignWorldTile] = []

///|
let campaign_dynamic_entities : Array[@entity.Entity] = []

///|
let campaign_camps : Array[CampaignCampRuntime] = []

///|
let campaign_exit_zone : Ref[CampaignExitRuntime?] = { val: None }

///|
let campaign_player_trail : Array[@math.Vec2] = []

///|
let campaign_image_cache : Map[String, @asset.ImageHandle] = Map::new()

///|
let campaign_world_bg_entity : @entity.Entity = @entity.Entity::new()

///|
let campaign_title_entity : @entity.Entity = @entity.Entity::new()

///|
let campaign_hud_entity : @entity.Entity = @entity.Entity::new()

///|
let campaign_message_entity : @entity.Entity = @entity.Entity::new()

///|
let campaign_overlay_entity : @entity.Entity = @entity.Entity::new()

///|
let campaign_font_registered : Ref[Bool] = { val: false }

///|
let campaign_capture_done : Ref[Bool] = { val: false }

///|
let campaign_capture_timer : Ref[Double] = { val: 0.0 }

///|
let campaign_debug_overlay_enabled : Ref[Bool] = { val: false }

///|
let campaign_rand : @random.Rand = @random.Rand::new()

///|
fn campaign_phase_name(phase : CampaignPhase) -> String {
  match phase {
    MainMenu => "MainMenu"
    StageIntro => "StageIntro"
    Playing => "Playing"
    StageClear => "StageClear"
    GameOver => "GameOver"
    CampaignClear => "CampaignClear"
  }
}
