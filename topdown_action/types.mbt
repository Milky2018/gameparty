///|
pub(all) enum RunPhase {
  Boot
  Playing
  Won
  Lost
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
pub(all) struct ArchetypeDef {
  id : String
  ai_mode : EnemyAiMode
  preferred_range : Double
  max_hp : Int
  move_speed : Double
  radius : Double
  touch_damage : Int
  score_value : Int
  sprites : @topdown_platform.DirectionalSprites
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
  meta : @topdown_platform.PluginMeta
  map : @topdown_platform.MapDef
  archetypes : Array[ArchetypeDef]
  skills : Array[SkillDef]
  waves : Array[WaveDef]
  drops : Array[DropTableDef]
  progression : ProgressionDef
  ui_theme : @topdown_platform.UiThemeDef
  hooks : TopDownHooks?
}
