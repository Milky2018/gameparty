///|
pub(all) enum RunPhase {
  Boot
  Playing
} derive(Eq, Debug)

///|
pub(all) enum TileKind {
  Floor
  Wall
  PlayerSpawn
  ActorSpawn
  Interact
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
pub(all) struct ImageVisualDef {
  path : String
  scale : Double
  y_offset : Double
}

///|
pub(all) struct TileOrSpawnRule {
  kind : TileKind
  floor_image : ImageVisualDef?
  prop_image : ImageVisualDef?
  blocks : Bool
  actor_spawn_tag : String?
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
  move_speed : Double
  radius : Double
  sprites : DirectionalSprites
}

///|
pub(all) struct ActorSpawnDef {
  archetype_id : String
  spawn_tag : String?
  facing : Facing
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
  player_cell_x : Int
  player_cell_y : Int
  actor_count : Int
}

///|
pub(all) struct TopDownHooks {
  on_run_start : ((PluginRuntimeState) -> Unit)?
}

///|
pub(all) struct TopDownPluginDef {
  meta : PluginMeta
  map : MapDef
  player_archetype_id : String
  archetypes : Array[ArchetypeDef]
  actor_spawns : Array[ActorSpawnDef]
  ui_theme : UiThemeDef
  hooks : TopDownHooks?
}
