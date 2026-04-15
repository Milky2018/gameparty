///|
pub(all) enum MatchPhase {
  Boot
  Playing
  MatchOver
} derive(Eq, Debug)

///|
pub(all) enum ShooterTileKind {
  Floor
  Wall
  PlayerSpawn
  BotSpawn
  WeaponSpawn
  AmmoSpawn
  HealSpawn
  Cover
} derive(Eq, Debug)

///|
pub(all) enum PickupKind {
  Weapon
  Ammo
  Heal
} derive(Eq, Debug)

///|
pub(all) struct PluginMeta {
  id : String
  name : String
  version : String
}

///|
pub(all) struct ShooterMapCellRule {
  kind : ShooterTileKind
  floor_color : @render.Color
  overlay_color : @render.Color?
  blocks : Bool
  spawn_tag : String?
  pickup_id : String?
}

///|
pub(all) struct ShooterMapDef {
  tile_size : Double
  rows : Array[String]
  legend : Map[Char, ShooterMapCellRule]
}

///|
pub(all) struct ActorArchetypeDef {
  id : String
  radius : Double
  move_speed : Double
  max_hp : Int
  body_color : @render.Color
  accent_color : @render.Color
}

///|
pub(all) struct WeaponDef {
  id : String
  damage : Int
  projectile_speed : Double
  projectile_radius : Double
  projectile_ttl : Double
  cooldown : Double
  spread_degrees : Double
  projectile_count : Int
  magazine : Int
  reserve_ammo : Int
  projectile_color : @render.Color
  pickup_color : @render.Color
}

///|
pub(all) struct PickupSpawnDef {
  id : String
  kind : PickupKind
  weapon_id : String?
  ammo_amount : Int
  heal_amount : Int
  radius : Double
  respawn_seconds : Double
  color : @render.Color
  label : String
}

///|
pub(all) struct RespawnRuleDef {
  delay_seconds : Double
  invuln_seconds : Double
}

///|
pub(all) struct BotProfileDef {
  id : String
  archetype_id : String
  weapon_id : String
  count : Int
  spawn_tag : String?
  aim_range : Double
  aggro_range : Double
  fire_range : Double
  strafe_strength : Double
  wander_interval : Double
}

///|
pub(all) struct ScoreRuleDef {
  match_seconds : Double
  kill_score : Int
  death_penalty : Int
  streak_bonus_step : Int
}

///|
pub(all) struct UiThemeDef {
  title : String
  hud_hint : String
  font_path : String
  font_family : String
  background_color : @render.Color
  panel_color : @render.Color
  accent_color : @render.Color
}

///|
pub(all) struct ShooterRuntimeSnapshot {
  phase : MatchPhase
  time_left : Double
  score : Int
  kills : Int
  deaths : Int
  best_streak : Int
  player_hp : Int
  ammo_in_magazine : Int
  reserve_ammo : Int
  active_weapon_id : String
  bots_alive : Int
}

///|
pub(all) struct ShooterHooks {
  on_match_start : ((ShooterRuntimeSnapshot) -> Unit)?
  on_actor_killed : ((ShooterRuntimeSnapshot, String) -> Unit)?
  on_pickup_taken : ((ShooterRuntimeSnapshot, String) -> Unit)?
}

///|
pub(all) struct TopDownShooterPluginDef {
  meta : PluginMeta
  map : ShooterMapDef
  player_archetype_id : String
  player_weapon_id : String
  actors : Array[ActorArchetypeDef]
  weapons : Array[WeaponDef]
  pickup_spawns : Array[PickupSpawnDef]
  respawn : RespawnRuleDef
  bots : Array[BotProfileDef]
  score_rules : ScoreRuleDef
  ui_theme : UiThemeDef
  hooks : ShooterHooks?
}
