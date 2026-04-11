///|
pub(all) enum RunPhase {
  Boot
  Playing
  Won
  Lost
} derive(Eq, Debug)

///|
pub(all) enum TileKind {
  Floor
  Wall
  PlayerSpawn
  EnemySpawn
  Interact
} derive(Eq, Debug)

///|
pub(all) enum SkillKind {
  Melee
  Projectile
} derive(Eq, Debug)

///|
pub(all) enum EnemyAiMode {
  Chase
  HoldDistance
  Wander
} derive(Eq, Debug)

///|
pub(all) enum Facing {
  Up
  Down
  Left
  Right
} derive(Eq, Debug)

///|
pub(all) struct PluginMeta {
  id : String
  name : String
  version : String
}

///|
pub(all) struct TileOrSpawnRule {
  kind : TileKind
  floor_image : ImageVisualDef?
  prop_image : ImageVisualDef?
  blocks : Bool
  enemy_spawn_tag : String?
}

///|
pub(all) struct ImageVisualDef {
  path : String
  scale : Double
  y_offset : Double
}

///|
pub(all) struct MapDef {
  tile_size : Double
  default_floor_image : ImageVisualDef
  rows : Array[String]
  legend : Map[Char, TileOrSpawnRule]
}

///|
pub(all) struct SpriteAnimDef {
  image : String
  frame_width : Double
  frame_height : Double
  columns : Int
  frame_count : Int
  fps : Double
  scale : Double
}

///|
pub(all) struct DirectionalSprites {
  up : SpriteAnimDef
  down : SpriteAnimDef
  left : SpriteAnimDef
  right : SpriteAnimDef
}

///|
pub(all) struct ArchetypeDef {
  id : String
  ai_mode : EnemyAiMode
  preferred_range : Double
  max_hp : Int
  move_speed : Double
  radius : Double
  touch_damage : Int
  score_value : Int
  sprites : DirectionalSprites
  drop_table_id : String?
  primary_skill_id : String?
  secondary_skill_id : String?
}

///|
pub(all) struct SkillDef {
  id : String
  kind : SkillKind
  cooldown : Double
  damage : Int
  range : Double
  projectile_speed : Double
  projectile_radius : Double
}

///|
pub(all) struct WaveEntryDef {
  archetype_id : String
  count : Int
  spawn_interval : Double
  spawn_tag : String?
}

///|
pub(all) struct WaveDef {
  id : Int
  start_delay : Double
  entries : Array[WaveEntryDef]
}

///|
pub(all) struct DropItemDef {
  id : String
  image : String
  weight : Int
  heal : Int
  score_bonus : Int
}

///|
pub(all) struct DropTableDef {
  id : String
  chance : Double
  items : Array[DropItemDef]
}

///|
pub(all) struct ProgressionDef {
  run_seconds : Double
  player_archetype_id : String
}

///|
pub(all) struct UiThemeDef {
  title : String
  font_path : String
  font_family : String
  hud_color_css : String
  control_hint : String
}

///|
pub(all) struct PluginRuntimeState {
  phase : RunPhase
  score : Int
  player_hp : Int
  player_hp_max : Int
  wave : Int
  waves_total : Int
  time_left : Double
  enemies_alive : Int
  enemies_killed : Int
  pickups_collected : Int
}

///|
pub(all) struct TopDownHooks {
  on_run_start : ((PluginRuntimeState) -> Unit)?
  on_enemy_killed : ((PluginRuntimeState, String) -> Unit)?
  on_pickup : ((PluginRuntimeState, String) -> Unit)?
}

///|
pub(all) struct TopDownPluginDef {
  meta : PluginMeta
  map : MapDef
  archetypes : Array[ArchetypeDef]
  skills : Array[SkillDef]
  waves : Array[WaveDef]
  drops : Array[DropTableDef]
  progression : ProgressionDef
  ui_theme : UiThemeDef
  hooks : TopDownHooks?
}
