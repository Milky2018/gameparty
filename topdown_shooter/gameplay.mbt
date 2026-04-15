///|
fn live_bot_count() -> Int {
  let mut count = 0
  for bot in bot_runtimes {
    if bot.alive {
      count += 1
    }
  }
  count
}

///|
fn archetype_for(actor : ActorRuntime) -> ActorArchetypeDef {
  actor_by_id(active_plugin_def(), actor.archetype_id).unwrap()
}

///|
fn weapon_for(actor : ActorRuntime) -> WeaponDef {
  weapon_by_id(active_plugin_def(), actor.weapon_id).unwrap()
}

///|
fn bot_profile_for(actor : ActorRuntime) -> BotProfileDef? {
  match actor.bot_profile_id {
    Some(id) => {
      for profile in active_plugin_def().bots {
        if profile.id == id {
          return Some(profile)
        }
      }
      None
    }
    None => None
  }
}

///|
fn choose_respawn_center(tag : String?) -> @math.Vec2 {
  let candidates : Array[SpawnPoint] = []
  for spawn in world_state.bot_spawns {
    if tag is None || spawn.tag == tag {
      candidates.push(spawn)
    }
  }
  if candidates.is_empty() {
    return first_player_spawn()
  }
  candidates[rand.int(limit=candidates.length())].center
}

///|
fn player_respawn_center() -> @math.Vec2 {
  if world_state.player_spawns.length() <= 1 {
    first_player_spawn()
  } else {
    world_state.player_spawns[rand.int(limit=world_state.player_spawns.length())].center
  }
}

///|
fn set_rect_entity(
  entity : @entity.Entity,
  color : @render.Color,
  size : @math.Vec2,
  center : @math.Vec2,
  z : Double,
) -> Unit {
  ensure_entity_alive(entity)
  let sprite = @sprite.Sprite::from_color(color, size)
  sprite.anchor = @sprite.Anchor(@math.Vec2(-0.5, 0.5))
  @sprite.sprites().set(entity, sprite)
  @transform.transforms().set(
    entity,
    transform_xy(center[X] - size[X] * 0.5, center[Y] - size[Y] * 0.5, z),
  )
  set_entity_visible(entity, true)
}

///|
fn set_circle_entity(
  entity : @entity.Entity,
  color : @render.Color,
  radius : Double,
  center : @math.Vec2,
  z : Double,
) -> Unit {
  ensure_entity_alive(entity)
  @sprite.sprites().remove(entity)
  @mesh2d.mesh2ds().set(entity, @mesh2d.Mesh2d::new(circle_mesh_handle(radius)))
  @material2d.mesh_material2ds().set(
    entity,
    @material2d.MeshMaterial2d::from_color_material(
      circle_material_handle(color),
    ),
  )
  @transform.transforms().set(entity, transform_xy(center[X], center[Y], z))
  set_entity_visible(entity, true)
}

///|
fn sync_actor_visual(actor : ActorRuntime) -> ActorRuntime {
  let actor = actor
  let archetype = archetype_for(actor)
  if !actor.alive {
    set_entity_visible(actor.body_entity, false)
    set_entity_visible(actor.barrel_entity, false)
    return actor
  }
  let alpha = if actor.invuln_ttl > 0.0 {
    0.55 + @cmath.sin(actor.invuln_ttl * 6.0).abs() * 0.45
  } else {
    1.0
  }
  let body_color = rgba(
    archetype.body_color.r,
    archetype.body_color.g,
    archetype.body_color.b,
    a=alpha,
  )
  let barrel_color = rgba(
    archetype.accent_color.r,
    archetype.accent_color.g,
    archetype.accent_color.b,
    a=alpha,
  )
  set_circle_entity(
    actor.body_entity,
    body_color,
    archetype.radius,
    actor.center,
    ACTOR_Z,
  )
  let dir = if vec_length(actor.aim_dir) <= 0.001 {
    @math.Vec2(1.0, 0.0)
  } else {
    vec_normalize(actor.aim_dir)
  }
  let horizontal = dir[X].abs() >= dir[Y].abs()
  let barrel_size = if horizontal {
    @math.Vec2(archetype.radius * 1.2, archetype.radius * 0.42)
  } else {
    @math.Vec2(archetype.radius * 0.42, archetype.radius * 1.2)
  }
  let barrel_center = actor.center + dir.scalar_mul(archetype.radius * 0.6)
  set_rect_entity(
    actor.barrel_entity,
    barrel_color,
    barrel_size,
    barrel_center,
    BARREL_Z,
  )
  actor
}

///|
fn move_with_collision(
  center : @math.Vec2,
  radius : Double,
  delta : @math.Vec2,
) -> @math.Vec2 {
  let mut next = center
  let trial_x = @math.Vec2(next[X] + delta[X], next[Y])
  let mut blocked_x = false
  for rect in world_state.wall_rects {
    if rect_intersects_circle(rect, trial_x, radius) {
      blocked_x = true
      break
    }
  }
  if !blocked_x {
    next = @math.Vec2(trial_x[X], next[Y])
  }
  let trial_y = @math.Vec2(next[X], next[Y] + delta[Y])
  let mut blocked_y = false
  for rect in world_state.wall_rects {
    if rect_intersects_circle(rect, trial_y, radius) {
      blocked_y = true
      break
    }
  }
  if !blocked_y {
    next = @math.Vec2(next[X], trial_y[Y])
  }
  @math.Vec2(
    clamp_double(
      next[X],
      world_state.origin[X] + radius,
      world_state.origin[X] + world_state.world_width - radius,
    ),
    clamp_double(
      next[Y],
      world_state.origin[Y] + radius,
      world_state.origin[Y] + world_state.world_height - radius,
    ),
  )
}

///|
fn try_reload(
  ammo_in_magazine : Int,
  reserve_ammo : Int,
  weapon : WeaponDef,
) -> (Int, Int) {
  if ammo_in_magazine > 0 || reserve_ammo <= 0 {
    (ammo_in_magazine, reserve_ammo)
  } else {
    let refill = weapon.magazine.min(reserve_ammo)
    (refill, reserve_ammo - refill)
  }
}

///|
fn pickup_applies_to_actor(
  actor : ActorRuntime,
  pickup : PickupSpawnDef,
) -> ActorRuntime {
  let actor = actor
  match pickup.kind {
    Weapon =>
      match pickup.weapon_id {
        Some(id) => {
          let weapon = weapon_by_id(active_plugin_def(), id).unwrap()
          actor.weapon_id = id
          actor.ammo_in_magazine = weapon.magazine
          actor.reserve_ammo = weapon.reserve_ammo
        }
        None => ()
      }
    Ammo => actor.reserve_ammo += pickup.ammo_amount
    Heal =>
      actor.hp = (actor.hp + pickup.heal_amount).min(
        archetype_for(actor).max_hp,
      )
  }
  actor
}

///|
fn award_player_kill() -> Unit {
  match_state.kills += 1
  match_state.current_streak += 1
  match_state.best_streak = match_state.best_streak.max(
    match_state.current_streak,
  )
  let mut gained = active_plugin_def().score_rules.kill_score.max(0)
  let step = active_plugin_def().score_rules.streak_bonus_step
  if step > 0 && match_state.current_streak % step == 0 {
    gained += active_plugin_def().score_rules.kill_score.max(0)
  }
  match_state.score += gained
  match_state.best_score = match_state.best_score.max(match_state.score)
}

///|
fn mark_actor_dead(victim : ActorRuntime, killer_id : Int) -> Unit {
  let victim = victim
  if !victim.alive {
    return
  }
  victim.alive = false
  victim.respawn_ttl = active_plugin_def().respawn.delay_seconds
  victim.invuln_ttl = 0.0
  victim.hp = 0
  set_entity_visible(victim.body_entity, false)
  set_entity_visible(victim.barrel_entity, false)
  if victim.is_player {
    match_state.deaths += 1
    match_state.current_streak = 0
    match_state.score = (match_state.score -
    active_plugin_def().score_rules.death_penalty.max(0)).max(0)
    match_state.status_message = "Respawning..."
  } else if killer_id == 1 {
    award_player_kill()
  }
  let label = if victim.is_player { "player" } else { victim.archetype_id }
  trigger_actor_killed_hook(label)
}

///|
fn respawn_actor(actor : ActorRuntime) -> ActorRuntime {
  let actor = actor
  let archetype = archetype_for(actor)
  actor.alive = true
  actor.hp = archetype.max_hp
  actor.fire_cooldown = 0.0
  actor.invuln_ttl = active_plugin_def().respawn.invuln_seconds
  actor.respawn_ttl = 0.0
  let weapon = weapon_for(actor)
  actor.ammo_in_magazine = weapon.magazine
  actor.reserve_ammo = weapon.reserve_ammo
  actor.center = if actor.is_player {
    player_respawn_center()
  } else {
    match bot_profile_for(actor) {
      Some(profile) => choose_respawn_center(profile.spawn_tag)
      None => choose_respawn_center(None)
    }
  }
  actor.aim_dir = @math.Vec2(1.0, 0.0)
  actor
}

///|
fn spawn_projectile(
  actor : ActorRuntime,
  direction : @math.Vec2,
  weapon : WeaponDef,
) -> Unit {
  let dir = vec_normalize(direction)
  let count = weapon.projectile_count.max(1)
  let spread_rad = weapon.spread_degrees * @cmath.PI / 180.0
  let step = if count <= 1 { 0.0 } else { spread_rad / (count - 1).to_double() }
  let start = -spread_rad * 0.5
  for idx = 0; idx < count; idx = idx + 1 {
    let angle = start + step * idx.to_double()
    let shot_dir = if count == 1 {
      dir
    } else {
      vec_normalize(rotate_vector(dir, angle))
    }
    let entity = @entity.Entity::new()
    dynamic_entities.push(entity)
    projectile_runtimes.push({
      entity,
      owner_actor_id: actor.id,
      center: actor.center +
      shot_dir.scalar_mul(archetype_for(actor).radius * 0.9),
      velocity: shot_dir.scalar_mul(weapon.projectile_speed),
      radius: weapon.projectile_radius,
      damage: weapon.damage,
      color: weapon.projectile_color,
      ttl: weapon.projectile_ttl,
    })
  }
}

///|
fn update_pickups_for_actor(actor : ActorRuntime) -> ActorRuntime {
  let actor = actor
  for i = 0; i < pickup_runtimes.length(); i = i + 1 {
    let pickup = pickup_runtimes[i]
    if !pickup.active {
      continue
    }
    if !circle_intersects_circle(
        actor.center,
        archetype_for(actor).radius,
        pickup.center,
        pickup.radius,
      ) {
      continue
    }
    let def = pickup_spawn_by_id(active_plugin_def(), pickup.spawn_id).unwrap()
    let updated = pickup_applies_to_actor(actor, def)
    actor.weapon_id = updated.weapon_id
    actor.ammo_in_magazine = updated.ammo_in_magazine
    actor.reserve_ammo = updated.reserve_ammo
    actor.hp = updated.hp
    pickup.active = false
    pickup.respawn_ttl = def.respawn_seconds
    set_entity_visible(pickup.entity, false)
    pickup_runtimes[i] = pickup
    if actor.is_player {
      trigger_pickup_hook(def.id)
    }
  }
  actor
}

///|
fn target_candidates(bot : ActorRuntime) -> Array[(Int, @math.Vec2, Double)] {
  let out : Array[(Int, @math.Vec2, Double)] = []
  match player_runtime.val {
    Some(player) =>
      if player.alive && player.id != bot.id {
        let to = player.center - bot.center
        out.push((player.id, player.center, vec_length(to)))
      }
    None => ()
  }
  for other in bot_runtimes {
    if other.alive && other.id != bot.id {
      let to = other.center - bot.center
      out.push((other.id, other.center, vec_length(to)))
    }
  }
  out
}

///|
fn nearest_target(bot : ActorRuntime) -> (Int, @math.Vec2, Double)? {
  let mut best : (Int, @math.Vec2, Double)? = None
  for candidate in target_candidates(bot) {
    match best {
      Some((_, _, dist)) => if candidate.2 < dist { best = Some(candidate) }
      None => best = Some(candidate)
    }
  }
  best
}

///|
fn update_player_aim() -> Unit {
  match player_runtime.val {
    Some(player) => {
      if !player.alive {
        player_runtime.val = Some(player)
        return
      }
      let screen_pos = @inputs.mouse.pos
      let dir = screen_pos - player.center
      if vec_length(dir) > 0.001 {
        player.aim_dir = vec_normalize(dir)
      }
      player_runtime.val = Some(player)
    }
    None => ()
  }
}

///|
pub fn input_system(_world : @ecs.World) -> Unit {
  if @inputs.is_just_pressed(Escape) {
    @system.exit()
    return
  }
  if @inputs.is_just_pressed(KeyR) {
    restart_match()
    title_cache.val = ""
    hud_cache.val = ""
    message_cache.val = ""
    return
  }
  if match_state.phase != Playing {
    if @inputs.is_just_pressed(Enter) || @inputs.is_just_pressed(Space) {
      restart_match()
      title_cache.val = ""
      hud_cache.val = ""
      message_cache.val = ""
    }
    input_state.move_intent = @math.Vec2(0.0, 0.0)
    input_state.fire_requested = false
    return
  }
  let x = (if @inputs.is_pressed(KeyD) || @inputs.is_pressed(ArrowRight) {
      1.0
    } else {
      0.0
    }) +
    (if @inputs.is_pressed(KeyA) || @inputs.is_pressed(ArrowLeft) {
      -1.0
    } else {
      0.0
    })
  let y = (if @inputs.is_pressed(KeyS) || @inputs.is_pressed(ArrowDown) {
      1.0
    } else {
      0.0
    }) +
    (if @inputs.is_pressed(KeyW) || @inputs.is_pressed(ArrowUp) {
      -1.0
    } else {
      0.0
    })
  input_state.move_intent = vec_normalize(@math.Vec2(x, y))
  input_state.fire_requested = @inputs.is_mouse_pressed(
    @inputs.MouseButton::Left,
  )
}

///|
pub fn aim_system(_world : @ecs.World) -> Unit {
  if match_state.phase != Playing {
    return
  }
  update_player_aim()
}

///|
pub fn movement_collision_system(_world : @ecs.World) -> Unit {
  if match_state.phase != Playing {
    return
  }
  let dt = @time.fixed_delta()
  match player_runtime.val {
    Some(player) => {
      if player.alive {
        let archetype = archetype_for(player)
        player.center = move_with_collision(
          player.center,
          archetype.radius,
          input_state.move_intent.scalar_mul(archetype.move_speed * dt),
        )
      }
      player.fire_cooldown = (player.fire_cooldown - dt).max(0.0)
      player.invuln_ttl = (player.invuln_ttl - dt).max(0.0)
      player_runtime.val = Some(player)
    }
    None => ()
  }
  for i = 0; i < bot_runtimes.length(); i = i + 1 {
    let bot = bot_runtimes[i]
    bot.fire_cooldown = (bot.fire_cooldown - dt).max(0.0)
    bot.invuln_ttl = (bot.invuln_ttl - dt).max(0.0)
    bot_runtimes[i] = bot
  }
}

///|
fn try_fire(actor : ActorRuntime) -> ActorRuntime {
  let actor = actor
  if !actor.alive || actor.fire_cooldown > 0.0 {
    return actor
  }
  let weapon = weapon_for(actor)
  let (mag, reserve) = try_reload(
    actor.ammo_in_magazine,
    actor.reserve_ammo,
    weapon,
  )
  actor.ammo_in_magazine = mag
  actor.reserve_ammo = reserve
  if actor.ammo_in_magazine <= 0 {
    return actor
  }
  if vec_length(actor.aim_dir) <= 0.001 {
    return actor
  }
  actor.ammo_in_magazine -= 1
  actor.fire_cooldown = weapon.cooldown
  spawn_projectile(actor, actor.aim_dir, weapon)
  actor
}

///|
pub fn pickups_system(_world : @ecs.World) -> Unit {
  if match_state.phase != Playing {
    return
  }
  let dt = @time.fixed_delta()
  for i = 0; i < pickup_runtimes.length(); i = i + 1 {
    let pickup = pickup_runtimes[i]
    if pickup.active {
      continue
    }
    pickup.respawn_ttl -= dt
    if pickup.respawn_ttl <= 0.0 {
      pickup.active = true
      pickup.respawn_ttl = 0.0
      set_entity_visible(pickup.entity, true)
    }
    pickup_runtimes[i] = pickup
  }
  match player_runtime.val {
    Some(player) =>
      if player.alive {
        player_runtime.val = Some(update_pickups_for_actor(player))
      }
    None => ()
  }
  for i = 0; i < bot_runtimes.length(); i = i + 1 {
    let bot = bot_runtimes[i]
    if bot.alive {
      bot_runtimes[i] = update_pickups_for_actor(bot)
    }
  }
}

///|
fn apply_projectile_hit(actor_id : Int, damage : Int, owner_id : Int) -> Bool {
  match player_runtime.val {
    Some(player) =>
      if player.alive && player.id == actor_id {
        if player.invuln_ttl <= 0.0 {
          player.hp = (player.hp - damage).max(0)
          if player.hp <= 0 {
            mark_actor_dead(player, owner_id)
          }
          player_runtime.val = Some(player)
        }
        return true
      }
    None => ()
  }
  for i = 0; i < bot_runtimes.length(); i = i + 1 {
    let bot = bot_runtimes[i]
    if bot.alive && bot.id == actor_id {
      if bot.invuln_ttl <= 0.0 {
        bot.hp = (bot.hp - damage).max(0)
        if bot.hp <= 0 {
          mark_actor_dead(bot, owner_id)
        }
        bot_runtimes[i] = bot
      }
      return true
    }
  }
  false
}

///|
fn projectile_hits_any_target(projectile : ProjectileRuntime) -> Bool {
  match player_runtime.val {
    Some(player) =>
      if player.alive &&
        player.id != projectile.owner_actor_id &&
        circle_intersects_circle(
          projectile.center,
          projectile.radius,
          player.center,
          archetype_for(player).radius,
        ) {
        return apply_projectile_hit(
          player.id,
          projectile.damage,
          projectile.owner_actor_id,
        )
      }
    None => ()
  }
  for bot in bot_runtimes {
    if bot.alive &&
      bot.id != projectile.owner_actor_id &&
      circle_intersects_circle(
        projectile.center,
        projectile.radius,
        bot.center,
        archetype_for(bot).radius,
      ) {
      return apply_projectile_hit(
        bot.id,
        projectile.damage,
        projectile.owner_actor_id,
      )
    }
  }
  false
}

///|
pub fn fire_projectiles_system(_world : @ecs.World) -> Unit {
  if match_state.phase != Playing {
    return
  }
  match player_runtime.val {
    Some(player) =>
      if input_state.fire_requested {
        player_runtime.val = Some(try_fire(player))
      }
    None => ()
  }
  let dt = @time.fixed_delta()
  let mut i = 0
  while i < projectile_runtimes.length() {
    let projectile = projectile_runtimes[i]
    projectile.ttl -= dt
    if projectile.ttl <= 0.0 {
      if projectile.entity.is_alive() {
        projectile.entity.destroy()
      }
      ignore(projectile_runtimes.remove(i))
      continue
    }
    projectile.center = projectile.center + projectile.velocity.scalar_mul(dt)
    let mut blocked = false
    for rect in world_state.wall_rects {
      if rect_intersects_circle(rect, projectile.center, projectile.radius) {
        blocked = true
        break
      }
    }
    if blocked || projectile_hits_any_target(projectile) {
      if projectile.entity.is_alive() {
        projectile.entity.destroy()
      }
      ignore(projectile_runtimes.remove(i))
      continue
    }
    projectile_runtimes[i] = projectile
    i += 1
  }
}

///|
fn bot_move_and_fire(bot : ActorRuntime, dt : Double) -> ActorRuntime {
  let mut bot = bot
  if !bot.alive {
    return bot
  }
  let profile = bot_profile_for(bot).unwrap()
  match nearest_target(bot) {
    Some((_, target_center, distance)) => {
      let to_target = target_center - bot.center
      let aim_dir = vec_normalize(to_target)
      bot.aim_dir = aim_dir
      if distance <= profile.aggro_range &&
        !line_blocked(world_state.wall_rects, bot.center, target_center) {
        let strafe = vec_perp(aim_dir).scalar_mul(
          profile.strafe_strength * bot.strafe_sign,
        )
        bot.wander_ttl -= dt
        if bot.wander_ttl <= 0.0 {
          bot.strafe_sign = if rand.int(limit=2) == 0 { -1.0 } else { 1.0 }
          bot.wander_ttl = profile.wander_interval
        }
        let move_dir = if distance > profile.fire_range * 0.92 {
          aim_dir
        } else if distance < profile.fire_range * 0.55 {
          vec_normalize(bot.center - target_center)
        } else {
          vec_normalize(strafe)
        }
        bot.center = move_with_collision(
          bot.center,
          archetype_for(bot).radius,
          move_dir.scalar_mul(archetype_for(bot).move_speed * dt),
        )
        if distance <= profile.fire_range && distance <= profile.aim_range {
          bot = try_fire(bot)
        }
      } else {
        bot.wander_ttl -= dt
        if bot.wander_ttl <= 0.0 {
          let raw = @math.Vec2(
            rand.double() * 2.0 - 1.0,
            rand.double() * 2.0 - 1.0,
          )
          bot.wander_dir = if vec_length(raw) <= 0.001 {
            @math.Vec2(1.0, 0.0)
          } else {
            vec_normalize(raw)
          }
          bot.wander_ttl = profile.wander_interval
        }
        bot.center = move_with_collision(
          bot.center,
          archetype_for(bot).radius,
          bot.wander_dir.scalar_mul(archetype_for(bot).move_speed * dt * 0.55),
        )
      }
    }
    None => ()
  }
  bot
}

///|
pub fn bot_update_system(_world : @ecs.World) -> Unit {
  if match_state.phase != Playing {
    return
  }
  let dt = @time.fixed_delta()
  for i = 0; i < bot_runtimes.length(); i = i + 1 {
    bot_runtimes[i] = bot_move_and_fire(bot_runtimes[i], dt)
  }
}

///|
pub fn damage_respawn_system(_world : @ecs.World) -> Unit {
  let dt = @time.fixed_delta()
  match player_runtime.val {
    Some(player) =>
      if !player.alive {
        player.respawn_ttl -= dt
        if player.respawn_ttl <= 0.0 {
          player_runtime.val = Some(respawn_actor(player))
        } else {
          player_runtime.val = Some(player)
        }
      }
    None => ()
  }
  for i = 0; i < bot_runtimes.length(); i = i + 1 {
    let bot = bot_runtimes[i]
    if !bot.alive {
      bot.respawn_ttl -= dt
      if bot.respawn_ttl <= 0.0 {
        bot_runtimes[i] = respawn_actor(bot)
      } else {
        bot_runtimes[i] = bot
      }
    }
  }
}

///|
pub fn score_time_system(_world : @ecs.World) -> Unit {
  if match_state.phase != Playing {
    return
  }
  let dt = @time.fixed_delta()
  match_state.elapsed += dt
  match_state.time_left = (match_state.time_left - dt).max(0.0)
  if match_state.time_left <= 0.0 {
    match_state.phase = MatchOver
    match_state.status_message = "MATCH OVER  SCORE \{match_state.score}  KILLS \{match_state.kills}  BEST \{match_state.best_streak}  Enter/R restart"
    match_state.best_score = match_state.best_score.max(match_state.score)
  }
}

///|
pub fn ui_sync_system(_world : @ecs.World) -> Unit {
  ui_state.title_text = active_plugin_def().ui_theme.title
  sync_text(title_entity, title_cache, ui_state.title_text)
  match player_runtime.val {
    Some(player) =>
      ui_state.hud_text = "TIME \{match_state.time_left.to_int()}  SCORE \{match_state.score}  K \{match_state.kills}  D \{match_state.deaths}  STREAK \{match_state.current_streak}/\{match_state.best_streak}  HP \{player.hp}/\{archetype_for(player).max_hp}  \{player.weapon_id} \{player.ammo_in_magazine}/\{player.reserve_ammo}  BOTS \{live_bot_count()}"
    None =>
      ui_state.hud_text = "TIME \{match_state.time_left.to_int()}  SCORE \{match_state.score}  K \{match_state.kills}  D \{match_state.deaths}"
  }
  sync_text(hud_entity, hud_cache, ui_state.hud_text)
  ui_state.message_text = if match_state.phase == Playing {
    if match_state.status_message.is_empty() {
      active_plugin_def().ui_theme.hud_hint
    } else {
      "\{active_plugin_def().ui_theme.hud_hint}  |  \{match_state.status_message}"
    }
  } else {
    match_state.status_message
  }
  sync_text(message_entity, message_cache, ui_state.message_text)
  for i = 0; i < pickup_runtimes.length(); i = i + 1 {
    let pickup = pickup_runtimes[i]
    if pickup.active {
      set_rect_entity(
        pickup.entity,
        pickup.color,
        @math.Vec2(pickup.radius * 2.0, pickup.radius * 2.0),
        pickup.center,
        PICKUP_Z,
      )
    } else {
      set_entity_visible(pickup.entity, false)
    }
  }
  match player_runtime.val {
    Some(player) => player_runtime.val = Some(sync_actor_visual(player))
    None => ()
  }
  for i = 0; i < bot_runtimes.length(); i = i + 1 {
    bot_runtimes[i] = sync_actor_visual(bot_runtimes[i])
  }
  for i = 0; i < projectile_runtimes.length(); i = i + 1 {
    let projectile = projectile_runtimes[i]
    set_rect_entity(
      projectile.entity,
      projectile.color,
      @math.Vec2(projectile.radius * 2.0, projectile.radius * 2.0),
      projectile.center,
      PROJECTILE_Z,
    )
  }
}

///|
pub fn capture_after_render_system(_world : @ecs.World) -> Unit {
  if !env_flag_enabled(CAPTURE_ENV) || capture_done.val {
    return
  }
  capture_timer.val += @time.delta()
  if capture_timer.val < CAPTURE_DELAY_SECONDS {
    return
  }
  @host.take_screenshot(CAPTURE_PATH)
  capture_done.val = true
  @system.exit()
}
