///|
pub fn rgb(r : UInt, g : UInt, b : UInt, a? : Double = 1.0) -> @render.Color {
  { r, g, b, a }
}

///|
pub fn meta(
  id : String,
  name : String,
  version? : String = "0.1.0",
) -> PluginMeta {
  { id, name, version }
}

///|
pub fn cell_rule(
  kind : ShooterTileKind,
  floor_color : @render.Color,
  blocks? : Bool = false,
  overlay_color? : @render.Color? = None,
  spawn_tag? : String? = None,
  pickup_id? : String? = None,
) -> ShooterMapCellRule {
  { kind, floor_color, overlay_color, blocks, spawn_tag, pickup_id }
}

///|
pub fn map_def(
  rows : Array[String],
  legend : Map[Char, ShooterMapCellRule],
  tile_size? : Double = 48.0,
) -> ShooterMapDef {
  { tile_size, rows, legend }
}

///|
pub fn actor_archetype(
  id : String,
  radius : Double,
  move_speed : Double,
  max_hp : Int,
  body_color : @render.Color,
  accent_color : @render.Color,
) -> ActorArchetypeDef {
  { id, radius, move_speed, max_hp, body_color, accent_color }
}

///|
pub fn weapon(
  id : String,
  damage : Int,
  projectile_speed : Double,
  projectile_radius : Double,
  projectile_ttl : Double,
  cooldown : Double,
  spread_degrees : Double,
  projectile_count : Int,
  magazine : Int,
  reserve_ammo : Int,
  projectile_color : @render.Color,
  pickup_color : @render.Color,
) -> WeaponDef {
  {
    id,
    damage,
    projectile_speed,
    projectile_radius,
    projectile_ttl,
    cooldown,
    spread_degrees,
    projectile_count,
    magazine,
    reserve_ammo,
    projectile_color,
    pickup_color,
  }
}

///|
pub fn pickup_spawn(
  id : String,
  kind : PickupKind,
  color : @render.Color,
  label : String,
  weapon_id? : String? = None,
  ammo_amount? : Int = 0,
  heal_amount? : Int = 0,
  radius? : Double = 16.0,
  respawn_seconds? : Double = 10.0,
) -> PickupSpawnDef {
  {
    id,
    kind,
    weapon_id,
    ammo_amount,
    heal_amount,
    radius,
    respawn_seconds,
    color,
    label,
  }
}

///|
pub fn respawn_rule(
  delay_seconds? : Double = 2.0,
  invuln_seconds? : Double = 1.0,
) -> RespawnRuleDef {
  { delay_seconds, invuln_seconds }
}

///|
pub fn bot_profile(
  id : String,
  archetype_id : String,
  weapon_id : String,
  count : Int,
  aim_range : Double,
  aggro_range : Double,
  fire_range : Double,
  strafe_strength : Double,
  wander_interval : Double,
  spawn_tag? : String? = None,
) -> BotProfileDef {
  {
    id,
    archetype_id,
    weapon_id,
    count,
    spawn_tag,
    aim_range,
    aggro_range,
    fire_range,
    strafe_strength,
    wander_interval,
  }
}

///|
pub fn score_rules(
  match_seconds? : Double = 180.0,
  kill_score? : Int = 100,
  death_penalty? : Int = 30,
  streak_bonus_step? : Int = 3,
) -> ScoreRuleDef {
  { match_seconds, kill_score, death_penalty, streak_bonus_step }
}

///|
pub fn ui_theme(
  title : String,
  hud_hint? : String = "WASD move  Mouse aim  LMB fire  R restart  ESC quit",
  font_path? : String = "assets/shared/fonts/mgs1codec.ttf",
  font_family? : String = "MGS1Codec",
  background_color? : @render.Color = rgb(20U, 31U, 48U),
  panel_color? : @render.Color = rgb(12U, 18U, 27U, a=0.82),
  accent_color? : @render.Color = rgb(228U, 238U, 248U),
) -> UiThemeDef {
  {
    title,
    hud_hint,
    font_path,
    font_family,
    background_color,
    panel_color,
    accent_color,
  }
}

///|
pub fn hooks(
  on_match_start? : ((ShooterRuntimeSnapshot) -> Unit)? = None,
  on_actor_killed? : ((ShooterRuntimeSnapshot, String) -> Unit)? = None,
  on_pickup_taken? : ((ShooterRuntimeSnapshot, String) -> Unit)? = None,
) -> ShooterHooks {
  { on_match_start, on_actor_killed, on_pickup_taken }
}

///|
pub fn plugin(
  meta : PluginMeta,
  map : ShooterMapDef,
  player_archetype_id : String,
  player_weapon_id : String,
  actors : Array[ActorArchetypeDef],
  weapons : Array[WeaponDef],
  pickup_spawns : Array[PickupSpawnDef],
  respawn : RespawnRuleDef,
  bots : Array[BotProfileDef],
  score_rules : ScoreRuleDef,
  ui_theme : UiThemeDef,
  hooks? : ShooterHooks? = None,
) -> TopDownShooterPluginDef {
  {
    meta,
    map,
    player_archetype_id,
    player_weapon_id,
    actors,
    weapons,
    pickup_spawns,
    respawn,
    bots,
    score_rules,
    ui_theme,
    hooks,
  }
}
