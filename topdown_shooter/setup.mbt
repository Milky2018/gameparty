///|
fn maybe_enable_hidden_window() -> Unit {
  if env_flag_enabled(CAPTURE_ENV) {
    @raylib.set_config_flags(@raylib.FlagWindowHidden)
  }
}

///|
fn runtime_fps() -> UInt {
  FPS
}

///|
fn register_font_once() -> Unit {
  if shooter_font_registered.val {
    return
  }
  let theme = active_plugin_def().ui_theme
  ignore(
    @asset.load_font(
      resolved_asset_path(theme.font_path),
      family=theme.font_family,
    ),
  )
  shooter_font_registered.val = true
}

///|
fn actor_by_id(
  plugin : TopDownShooterPluginDef,
  id : String,
) -> ActorArchetypeDef? {
  for actor in plugin.actors {
    if actor.id == id {
      return Some(actor)
    }
  }
  None
}

///|
fn weapon_by_id(plugin : TopDownShooterPluginDef, id : String) -> WeaponDef? {
  for weapon in plugin.weapons {
    if weapon.id == id {
      return Some(weapon)
    }
  }
  None
}

///|
fn pickup_spawn_by_id(
  plugin : TopDownShooterPluginDef,
  id : String,
) -> PickupSpawnDef? {
  for pickup in plugin.pickup_spawns {
    if pickup.id == id {
      return Some(pickup)
    }
  }
  None
}

///|
pub fn validate_plugin(plugin : TopDownShooterPluginDef) -> String? {
  if plugin.meta.id.is_empty() {
    return Some("meta.id must not be empty")
  }
  if plugin.map.rows.is_empty() {
    return Some("map.rows must not be empty")
  }
  if plugin.map.tile_size <= 0.0 {
    return Some("map.tile_size must be > 0")
  }
  let cols = plugin.map.rows[0].length()
  if cols == 0 {
    return Some("map rows must not be empty strings")
  }
  let mut player_spawn_count = 0
  let mut bot_spawn_count = 0
  for row_index = 0
      row_index < plugin.map.rows.length()
      row_index = row_index + 1 {
    let row = plugin.map.rows[row_index]
    if row.length() != cols {
      return Some("map row widths must match")
    }
    for col = 0; col < cols; col = col + 1 {
      let code = row.unsafe_get(col).unsafe_to_char()
      match plugin.map.legend.get(code) {
        Some(rule) =>
          match rule.kind {
            PlayerSpawn => player_spawn_count += 1
            BotSpawn => bot_spawn_count += 1
            WeaponSpawn | AmmoSpawn | HealSpawn =>
              match rule.pickup_id {
                Some(id) =>
                  if pickup_spawn_by_id(plugin, id) is None {
                    return Some("pickup_id '\{id}' is missing")
                  }
                None => return Some("pickup spawn tile is missing pickup_id")
              }
            _ => ()
          }
        None => return Some("legend missing entry for '\{code}'")
      }
    }
  }
  if player_spawn_count == 0 {
    return Some("map must contain at least one player spawn")
  }
  if !plugin.bots.is_empty() && bot_spawn_count == 0 {
    return Some("map must contain bot spawns when bots are configured")
  }
  if actor_by_id(plugin, plugin.player_archetype_id) is None {
    return Some("player_archetype_id is missing")
  }
  if weapon_by_id(plugin, plugin.player_weapon_id) is None {
    return Some("player_weapon_id is missing")
  }
  if plugin.respawn.delay_seconds < 0.0 || plugin.respawn.invuln_seconds < 0.0 {
    return Some("respawn values must be >= 0")
  }
  if plugin.score_rules.match_seconds <= 0.0 {
    return Some("score_rules.match_seconds must be > 0")
  }
  for actor in plugin.actors {
    if actor.radius <= 0.0 || actor.move_speed <= 0.0 || actor.max_hp <= 0 {
      return Some("actor '\{actor.id}' has invalid stats")
    }
  }
  for weapon in plugin.weapons {
    if weapon.damage <= 0 ||
      weapon.projectile_speed <= 0.0 ||
      weapon.projectile_radius <= 0.0 ||
      weapon.projectile_ttl <= 0.0 ||
      weapon.cooldown <= 0.0 ||
      weapon.projectile_count <= 0 ||
      weapon.magazine <= 0 ||
      weapon.reserve_ammo < 0 {
      return Some("weapon '\{weapon.id}' has invalid stats")
    }
  }
  for pickup in plugin.pickup_spawns {
    if pickup.radius <= 0.0 || pickup.respawn_seconds < 0.0 {
      return Some("pickup '\{pickup.id}' has invalid size or respawn")
    }
    match pickup.kind {
      Weapon =>
        match pickup.weapon_id {
          Some(id) =>
            if weapon_by_id(plugin, id) is None {
              return Some(
                "pickup '\{pickup.id}' references missing weapon '\{id}'",
              )
            }
          None =>
            return Some("weapon pickup '\{pickup.id}' is missing weapon_id")
        }
      Ammo =>
        if pickup.ammo_amount <= 0 {
          return Some("ammo pickup '\{pickup.id}' must add ammo")
        }
      Heal =>
        if pickup.heal_amount <= 0 {
          return Some("heal pickup '\{pickup.id}' must heal")
        }
    }
  }
  for bot in plugin.bots {
    if actor_by_id(plugin, bot.archetype_id) is None {
      return Some("bot '\{bot.id}' references missing archetype")
    }
    if weapon_by_id(plugin, bot.weapon_id) is None {
      return Some("bot '\{bot.id}' references missing weapon")
    }
    if bot.count <= 0 ||
      bot.aim_range <= 0.0 ||
      bot.aggro_range <= 0.0 ||
      bot.fire_range <= 0.0 ||
      bot.wander_interval <= 0.0 {
      return Some("bot '\{bot.id}' has invalid stats")
    }
  }
  None
}

///|
fn clear_world_entities() -> Unit {
  for tile in world_tiles {
    if tile.floor_entity.is_alive() {
      tile.floor_entity.destroy()
    }
    match tile.overlay_entity {
      Some(entity) => if entity.is_alive() { entity.destroy() }
      None => ()
    }
  }
  world_tiles.clear()
}

///|
fn clear_dynamic_entities() -> Unit {
  for entity in dynamic_entities {
    if entity.is_alive() {
      entity.destroy()
    }
  }
  dynamic_entities.clear()
  pickup_runtimes.clear()
  projectile_runtimes.clear()
  bot_runtimes.clear()
  player_runtime.val = None
  next_actor_id.val = 1
}

///|
fn build_panel_entity(
  entity : @entity.Entity,
  color : @render.Color,
  size : @math.Vec2,
  top_left : @math.Vec2,
  z : Double,
) -> Unit {
  let sprite = @sprite.Sprite::from_color(color, size)
  sprite.anchor = @sprite.Anchor(@math.Vec2(-0.5, 0.5))
  @sprite.sprites().set(entity, sprite)
  @transform.transforms().set(entity, transform_xy(top_left[X], top_left[Y], z))
  set_entity_visible(entity, true)
}

///|
fn ensure_text_entity(
  entity : @entity.Entity,
  text : String,
  x : Double,
  y : Double,
  z : Double,
  color : @render.Color,
  size : Int,
) -> Unit {
  @ui.texts().set(entity, @ui.Text::new(text))
  @ui.text_fonts().set(
    entity,
    @ui.TextFont::from_css(
      "\{size}px \{active_plugin_def().ui_theme.font_family}",
    ),
  )
  @ui.text_colors().set(entity, @ui.TextColor::new(color))
  @ui.text_layouts().set(
    entity,
    @ui.TextLayout::new(align=Left, baseline=Top, wrap=WordWrap),
  )
  @text2d.text2ds().set(entity, @text2d.Text2d::new())
  @text2d.text_anchors().set(entity, @sprite.Anchor(@math.Vec2(-0.5, 0.5)))
  @transform.transforms().set(entity, transform_xy(x, y, z))
  set_entity_visible(entity, true)
}

///|
fn sync_text(
  entity : @entity.Entity,
  cache : Ref[String],
  value : String,
) -> Unit {
  if cache.val == value {
    return
  }
  @ui.texts().set(entity, @ui.Text::new(value))
  cache.val = value
}

///|
fn ensure_world_background() -> Unit {
  build_panel_entity(
    world_bg_entity,
    active_plugin_def().ui_theme.background_color,
    @math.Vec2(VIEWPORT_WIDTH, VIEWPORT_HEIGHT),
    @math.Vec2(0.0, 0.0),
    WORLD_BG_Z,
  )
}

///|
fn setup_ui() -> Unit {
  let accent = active_plugin_def().ui_theme.accent_color
  build_panel_entity(
    top_panel_entity,
    active_plugin_def().ui_theme.panel_color,
    @math.Vec2(VIEWPORT_WIDTH - 32.0, 84.0),
    @math.Vec2(16.0, 12.0),
    HUD_Z - 2.0,
  )
  build_panel_entity(
    bottom_panel_entity,
    active_plugin_def().ui_theme.panel_color,
    @math.Vec2(VIEWPORT_WIDTH - 32.0, 46.0),
    @math.Vec2(16.0, VIEWPORT_HEIGHT - 58.0),
    HUD_Z - 2.0,
  )
  ensure_text_entity(
    title_entity,
    active_plugin_def().ui_theme.title,
    28.0,
    20.0,
    HUD_Z,
    accent,
    32,
  )
  ensure_text_entity(
    hud_entity,
    "",
    28.0,
    54.0,
    HUD_Z,
    rgba(235U, 242U, 249U),
    20,
  )
  ensure_text_entity(
    message_entity,
    "",
    28.0,
    VIEWPORT_HEIGHT - 48.0,
    HUD_Z,
    rgba(255U, 228U, 156U),
    20,
  )
}

///|
fn parse_map() -> Unit {
  clear_world_entities()
  world_state.player_spawns.clear()
  world_state.bot_spawns.clear()
  world_state.wall_rects.clear()
  world_state.pickup_markers.clear()

  let map = active_plugin_def().map
  world_state.tile_size = map.tile_size
  world_state.rows = map.rows.length()
  world_state.cols = map.rows[0].length()
  world_state.world_width = world_state.cols.to_double() * map.tile_size
  world_state.world_height = world_state.rows.to_double() * map.tile_size
  let available_h = VIEWPORT_HEIGHT - WORLD_TOP_MARGIN - WORLD_BOTTOM_MARGIN
  world_state.origin = @math.Vec2(
    ((VIEWPORT_WIDTH - world_state.world_width) * 0.5).max(24.0),
    WORLD_TOP_MARGIN + ((available_h - world_state.world_height) * 0.5).max(0.0),
  )

  for row = 0; row < world_state.rows; row = row + 1 {
    let line = map.rows[row]
    for col = 0; col < world_state.cols; col = col + 1 {
      let code = line.unsafe_get(col).unsafe_to_char()
      let rule = map.legend.get(code).unwrap()
      let top_left = @math.Vec2(
        world_state.origin[X] + col.to_double() * world_state.tile_size,
        world_state.origin[Y] + row.to_double() * world_state.tile_size,
      )
      let center = @math.Vec2(
        top_left[X] + world_state.tile_size * 0.5,
        top_left[Y] + world_state.tile_size * 0.5,
      )
      let tile_size = @math.Vec2(
        world_state.tile_size - 1.0,
        world_state.tile_size - 1.0,
      )
      let floor = @entity.Entity::new()
      build_panel_entity(floor, rule.floor_color, tile_size, top_left, TILE_Z)
      let mut overlay_entity : @entity.Entity? = None
      match rule.overlay_color {
        Some(color) => {
          let overlay = @entity.Entity::new()
          let inset = world_state.tile_size * 0.22
          build_panel_entity(
            overlay,
            color,
            @math.Vec2(
              world_state.tile_size - inset * 2.0,
              world_state.tile_size - inset * 2.0,
            ),
            @math.Vec2(top_left[X] + inset, top_left[Y] + inset),
            TILE_OVERLAY_Z,
          )
          overlay_entity = Some(overlay)
        }
        None => ()
      }
      if rule.blocks || rule.kind == Wall || rule.kind == Cover {
        world_state.wall_rects.push({
          position: @math.Vec2(
            top_left[X] + WALL_PADDING,
            top_left[Y] + WALL_PADDING,
          ),
          size: @math.Vec2(
            world_state.tile_size - WALL_PADDING * 2.0,
            world_state.tile_size - WALL_PADDING * 2.0,
          ),
        })
      }
      match rule.kind {
        PlayerSpawn =>
          world_state.player_spawns.push({ center, tag: rule.spawn_tag })
        BotSpawn => world_state.bot_spawns.push({ center, tag: rule.spawn_tag })
        WeaponSpawn | AmmoSpawn | HealSpawn =>
          match rule.pickup_id {
            Some(id) =>
              world_state.pickup_markers.push({ center, pickup_id: id })
            None => ()
          }
        _ => ()
      }
      world_tiles.push({ floor_entity: floor, overlay_entity })
    }
  }
}

///|
fn make_snapshot() -> ShooterRuntimeSnapshot {
  match player_runtime.val {
    Some(player) =>
      {
        phase: match_state.phase,
        time_left: match_state.time_left,
        score: match_state.score,
        kills: match_state.kills,
        deaths: match_state.deaths,
        best_streak: match_state.best_streak,
        player_hp: player.hp,
        ammo_in_magazine: player.ammo_in_magazine,
        reserve_ammo: player.reserve_ammo,
        active_weapon_id: player.weapon_id,
        bots_alive: live_bot_count(),
      }
    None =>
      {
        phase: match_state.phase,
        time_left: match_state.time_left,
        score: match_state.score,
        kills: match_state.kills,
        deaths: match_state.deaths,
        best_streak: match_state.best_streak,
        player_hp: 0,
        ammo_in_magazine: 0,
        reserve_ammo: 0,
        active_weapon_id: "",
        bots_alive: live_bot_count(),
      }
  }
}

///|
fn trigger_match_start_hook() -> Unit {
  match active_plugin_def().hooks {
    Some(hooks) =>
      match hooks.on_match_start {
        Some(f) => f(make_snapshot())
        None => ()
      }
    None => ()
  }
}

///|
fn trigger_actor_killed_hook(label : String) -> Unit {
  match active_plugin_def().hooks {
    Some(hooks) =>
      match hooks.on_actor_killed {
        Some(f) => f(make_snapshot(), label)
        None => ()
      }
    None => ()
  }
}

///|
fn trigger_pickup_hook(id : String) -> Unit {
  match active_plugin_def().hooks {
    Some(hooks) =>
      match hooks.on_pickup_taken {
        Some(f) => f(make_snapshot(), id)
        None => ()
      }
    None => ()
  }
}

///|
fn spawn_actor_runtime(
  archetype_id : String,
  weapon_id : String,
  center : @math.Vec2,
  is_player : Bool,
  bot_profile_id? : String? = None,
) -> ActorRuntime {
  let archetype = actor_by_id(active_plugin_def(), archetype_id).unwrap()
  let weapon = weapon_by_id(active_plugin_def(), weapon_id).unwrap()
  let body_entity = @entity.Entity::new()
  let barrel_entity = @entity.Entity::new()
  dynamic_entities.push(body_entity)
  dynamic_entities.push(barrel_entity)
  let runtime = {
    id: next_actor_id.val,
    body_entity,
    barrel_entity,
    archetype_id,
    weapon_id,
    is_player,
    bot_profile_id,
    alive: true,
    hp: archetype.max_hp,
    center,
    aim_dir: @math.Vec2(1.0, 0.0),
    fire_cooldown: 0.0,
    invuln_ttl: 0.0,
    respawn_ttl: 0.0,
    ammo_in_magazine: weapon.magazine,
    reserve_ammo: weapon.reserve_ammo,
    wander_dir: @math.Vec2(1.0, 0.0),
    wander_ttl: 0.0,
    strafe_sign: 1.0,
  }
  next_actor_id.val += 1
  runtime
}

///|
fn reset_match_state() -> Unit {
  match_state.phase = Playing
  match_state.elapsed = 0.0
  match_state.time_left = active_plugin_def().score_rules.match_seconds
  match_state.score = 0
  match_state.kills = 0
  match_state.deaths = 0
  match_state.current_streak = 0
  match_state.best_streak = 0
  match_state.status_message = ""
  input_state.move_intent = @math.Vec2(0.0, 0.0)
  input_state.fire_requested = false
  capture_timer.val = 0.0
  capture_done.val = false
}

///|
fn first_player_spawn() -> @math.Vec2 {
  if world_state.player_spawns.is_empty() {
    @math.Vec2(
      world_state.origin[X] + world_state.tile_size,
      world_state.origin[Y] + world_state.tile_size,
    )
  } else {
    world_state.player_spawns[0].center
  }
}

///|
fn spawn_pickups() -> Unit {
  for marker in world_state.pickup_markers {
    let def = pickup_spawn_by_id(active_plugin_def(), marker.pickup_id).unwrap()
    let entity = @entity.Entity::new()
    dynamic_entities.push(entity)
    pickup_runtimes.push({
      entity,
      spawn_id: def.id,
      center: marker.center,
      radius: def.radius,
      color: def.color,
      active: true,
      respawn_ttl: 0.0,
    })
  }
}

///|
fn spawn_player() -> Unit {
  player_runtime.val = Some(
    spawn_actor_runtime(
      active_plugin_def().player_archetype_id,
      active_plugin_def().player_weapon_id,
      first_player_spawn(),
      true,
    ),
  )
}

///|
fn spawn_bots() -> Unit {
  if world_state.bot_spawns.is_empty() {
    return
  }
  let mut spawn_index = 0
  for profile in active_plugin_def().bots {
    let mut idx = 0
    while idx < profile.count {
      let matching : Array[SpawnPoint] = []
      for spawn in world_state.bot_spawns {
        if profile.spawn_tag is None || spawn.tag == profile.spawn_tag {
          matching.push(spawn)
        }
      }
      if matching.is_empty() {
        continue
      }
      let spawn = matching[spawn_index % matching.length()]
      spawn_index += 1
      bot_runtimes.push(
        spawn_actor_runtime(
          profile.archetype_id,
          profile.weapon_id,
          spawn.center,
          false,
          bot_profile_id=Some(profile.id),
        ),
      )
      idx += 1
    }
  }
}

///|
fn restart_match() -> Unit {
  clear_dynamic_entities()
  parse_map()
  reset_match_state()
  spawn_pickups()
  spawn_player()
  spawn_bots()
  setup_ui()
  trigger_match_start_hook()
}

///|
pub fn setup_plugin(plugin : TopDownShooterPluginDef) -> Unit {
  active_plugin.val = Some(plugin)
}

///|
pub fn startup_system(_world : @ecs.World) -> Unit {
  maybe_enable_hidden_window()
  register_font_once()
  ensure_world_background()
  restart_match()
}
