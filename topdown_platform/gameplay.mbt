///|
let title_cache : Ref[String] = { val: "" }

///|
let hud_cache : Ref[String] = { val: "" }

///|
let message_cache : Ref[String] = { val: "" }

///|
let debug_overlay_enabled : Ref[Bool] = { val: false }

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
fn archetype_for(actor : ActorRuntime) -> ArchetypeDef {
  archetype_by_id(plugin(), actor.archetype_id).unwrap()
}

///|
fn sprite_anim_for_facing(
  sprites : DirectionalSprites,
  facing : Facing,
) -> SpriteAnimDef {
  match facing {
    Up => sprites.up
    Down => sprites.down
    Left => sprites.left
    Right => sprites.right
  }
}

///|
fn actor_frame_index(actor : ActorRuntime, anim : SpriteAnimDef) -> Int {
  if !actor.moving || anim.frame_count <= 1 {
    0
  } else {
    let count = anim.frame_count.max(1)
    (actor.anim_elapsed * anim.fps).to_int() % count
  }
}

///|
fn anim_frame_rect(anim : SpriteAnimDef, frame_index : Int) -> @math.Rect {
  let columns = anim.columns.max(1)
  let col = frame_index % columns
  let row = frame_index / columns
  {
    position: @math.Vec2D(
      col.to_double() * anim.frame_width,
      row.to_double() * anim.frame_height,
    ),
    size: @math.Vec2D(anim.frame_width, anim.frame_height),
  }
}

///|
fn sync_actor_visual(actor : ActorRuntime, z : Double) -> ActorRuntime {
  let archetype = archetype_for(actor)
  let anim = sprite_anim_for_facing(archetype.sprites, actor.facing)
  let path = anim.image
  let frame = actor_frame_index(actor, anim)
  let frame_rect = anim_frame_rect(anim, frame)
  let size = archetype.radius * 2.0 * anim.scale
  if path != actor.last_sprite_path ||
    @sprite.sprites().get(actor.entity) is None {
    let sprite = @sprite.Sprite::from_image(
      image_handle(path),
      custom_size=Some(@math.Vec2D(size, size)),
    )
    sprite.rect = Some(frame_rect)
    sprite.anchor = @sprite.Anchor(@math.Vec2D(-0.5, 0.5))
    @sprite.sprites().set(actor.entity, sprite)
    actor.last_sprite_path = path
  } else {
    match @sprite.sprites().get(actor.entity) {
      Some(sprite) => {
        sprite.custom_size = Some(@math.Vec2D(size, size))
        sprite.rect = Some(frame_rect)
        @sprite.sprites().set(actor.entity, sprite)
      }
      None => ()
    }
  }
  @transform.transforms().set(
    actor.entity,
    transform_xy(
      actor.position[X] - archetype.radius,
      actor.position[Y] - archetype.radius,
      z,
    ),
  )
  set_entity_visible(actor.entity, true)
  actor
}

///|
fn move_with_collision(
  center : @math.Vec2D,
  radius : Double,
  delta : @math.Vec2D,
) -> @math.Vec2D {
  let mut next = center

  let trial_x = @math.Vec2D(next[X] + delta[X], next[Y])
  let mut blocked_x = false
  for rect in world_state.blocking_rects {
    if rect_intersects_circle(rect, trial_x, radius) {
      blocked_x = true
      break
    }
  }
  if !blocked_x {
    next = @math.Vec2D(trial_x[X], next[Y])
  }

  let trial_y = @math.Vec2D(next[X], next[Y] + delta[Y])
  let mut blocked_y = false
  for rect in world_state.blocking_rects {
    if rect_intersects_circle(rect, trial_y, radius) {
      blocked_y = true
      break
    }
  }
  if !blocked_y {
    next = @math.Vec2D(next[X], trial_y[Y])
  }

  @math.Vec2D(
    clamp_double(next[X], radius, world_state.world_width - radius),
    clamp_double(next[Y], radius, world_state.world_height - radius),
  )
}

///|
fn spawn_enemy(archetype_id : String, position : @math.Vec2D) -> Unit {
  match archetype_by_id(plugin(), archetype_id) {
    Some(archetype) => {
      let entity = @entity.Entity::new()
      dynamic_entities.push(entity)
      enemy_runtimes.push({
        entity,
        archetype_id,
        hp: archetype.max_hp,
        position,
        facing: Down,
        attack_cd: 0.0,
        moving: false,
        anim_elapsed: 0.0,
        last_sprite_path: "",
        ai_wander_dir: @math.Vec2D(0.0, 0.0),
        ai_wander_timer: 0.0,
      })
    }
    None => ()
  }
}

///|
fn spawn_pickup(position : @math.Vec2D, item : DropItemDef) -> Unit {
  let entity = @entity.Entity::new()
  dynamic_entities.push(entity)
  pickup_runtimes.push({
    entity,
    item_id: item.id,
    position,
    radius: 20.0,
    heal: item.heal,
    score_bonus: item.score_bonus,
  })
  let sprite = @sprite.Sprite::from_image(
    image_handle(item.image),
    custom_size=Some(@math.Vec2D(38.0, 38.0)),
  )
  sprite.anchor = @sprite.Anchor(@math.Vec2D(-0.5, 0.5))
  @sprite.sprites().set(entity, sprite)
  @transform.transforms().set(
    entity,
    transform_xy(position[X] - 19.0, position[Y] - 19.0, PICKUP_Z),
  )
  set_entity_visible(entity, true)
  loot_state.live_pickups = pickup_runtimes.length()
}

///|
fn choose_drop_item(table : DropTableDef) -> DropItemDef? {
  let mut total_weight = 0
  for item in table.items {
    total_weight += item.weight
  }
  if total_weight <= 0 {
    return None
  }
  let mut cursor = rand.int(limit=total_weight)
  for item in table.items {
    cursor -= item.weight
    if cursor < 0 {
      return Some(item)
    }
  }
  None
}

///|
fn maybe_drop_for_enemy(enemy : ActorRuntime) -> Unit {
  let archetype = archetype_for(enemy)
  let table_id = match archetype.drop_table_id {
    Some(id) => id
    None => return
  }
  let table = match drop_table_by_id(plugin(), table_id) {
    Some(table) => table
    None => return
  }
  if rand.double() > table.chance {
    return
  }
  match choose_drop_item(table) {
    Some(item) => spawn_pickup(enemy.position, item)
    None => ()
  }
}

///|
fn skill_by_id_or_abort(id : String) -> SkillDef {
  match skill_by_id(plugin(), id) {
    Some(skill) => skill
    None => abort("topdown_platform: missing skill '\{id}'")
  }
}

///|
fn spawn_projectile(
  owner_enemy : Bool,
  origin : @math.Vec2D,
  direction : @math.Vec2D,
  skill : SkillDef,
) -> Unit {
  let entity = @entity.Entity::new()
  dynamic_entities.push(entity)
  let vel = direction.scalar_mul(skill.projectile_speed)
  projectile_runtimes.push({
    entity,
    owner_enemy,
    position: origin + direction.scalar_mul(24.0),
    velocity: vel,
    radius: skill.projectile_radius,
    damage: skill.damage,
    ttl: skill.range / skill.projectile_speed,
  })
  let sprite = @sprite.Sprite::from_color(
    if owner_enemy {
      color_rgba(255U, 112U, 112U, 1.0)
    } else {
      color_rgba(120U, 220U, 255U, 1.0)
    },
    @math.Vec2D(skill.projectile_radius * 2.0, skill.projectile_radius * 2.0),
  )
  sprite.anchor = @sprite.Anchor(@math.Vec2D(-0.5, 0.5))
  @sprite.sprites().set(entity, sprite)
  @transform.transforms().set(
    entity,
    transform_xy(
      origin[X] - skill.projectile_radius,
      origin[Y] - skill.projectile_radius,
      PROJECTILE_Z,
    ),
  )
  set_entity_visible(entity, true)
}

///|
fn apply_damage_to_player(amount : Int) -> Unit {
  if run_state.phase != Playing {
    return
  }
  match player_runtime.val {
    Some(player) => {
      if player.hp <= 0 {
        return
      }
      player.hp = (player.hp - amount).max(0)
      player_runtime.val = Some(player)
      combat_state.attack_flash_ttl = ATTACK_FLASH_SECONDS
      if player.hp <= 0 {
        run_state.phase = Lost
        run_state.status_message = "You were defeated. Press Enter to restart."
      }
    }
    None => ()
  }
}

///|
fn apply_enemy_killed_hook(archetype_id : String) -> Unit {
  plugin_runtime_state.snapshot = make_runtime_snapshot()
  match plugin().hooks {
    Some(hooks) =>
      match hooks.on_enemy_killed {
        Some(f) => f(plugin_runtime_state.snapshot, archetype_id)
        None => ()
      }
    None => ()
  }
}

///|
fn apply_pickup_hook(item_id : String) -> Unit {
  plugin_runtime_state.snapshot = make_runtime_snapshot()
  match plugin().hooks {
    Some(hooks) =>
      match hooks.on_pickup {
        Some(f) => f(plugin_runtime_state.snapshot, item_id)
        None => ()
      }
    None => ()
  }
}

///|
fn request_restart_if_needed() -> Unit {
  if run_state.phase == Playing {
    return
  }
  if @inputs.is_just_pressed(Enter) || @inputs.is_just_pressed(Space) {
    restart_world()
    title_cache.val = ""
    hud_cache.val = ""
    message_cache.val = ""
  }
}

///|
pub fn input_system(_world : @ecs.World) -> Unit {
  if @inputs.is_just_pressed(Escape) {
    @system.exit()
    return
  }
  if @raylib.is_key_pressed(@raylib.KeyF3) {
    debug_overlay_enabled.val = !debug_overlay_enabled.val
  }
  request_restart_if_needed()
  if run_state.phase != Playing {
    combat_state.move_intent = @math.Vec2D(0.0, 0.0)
    combat_state.primary_requested = false
    combat_state.secondary_requested = false
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
  combat_state.move_intent = vec_normalize(@math.Vec2D(x, y))
  combat_state.primary_requested = @inputs.is_mouse_pressed(
    @inputs.MouseButton::Left,
  )
  combat_state.secondary_requested = @inputs.is_just_pressed(Space)
}

///|
pub fn intent_system(_world : @ecs.World) -> Unit {
  if run_state.phase != Playing {
    return
  }
  match player_runtime.val {
    Some(player) => {
      player.facing = facing_from_vector(
        combat_state.move_intent,
        player.facing,
      )
      player_runtime.val = Some(player)
    }
    None => ()
  }
}

///|
pub fn movement_collision_system(_world : @ecs.World) -> Unit {
  if run_state.phase != Playing {
    return
  }
  let dt = @time.fixed_delta()

  match player_runtime.val {
    Some(player) => {
      let mut player = player
      let archetype = archetype_for(player)
      let is_moving = vec_length(combat_state.move_intent) > 0.001
      let delta = combat_state.move_intent.scalar_mul(archetype.move_speed * dt)
      player.position = move_with_collision(
        player.position,
        archetype.radius,
        delta,
      )
      player.moving = is_moving
      player.anim_elapsed = if is_moving {
        player.anim_elapsed + dt
      } else {
        0.0
      }
      if player.attack_cd > 0.0 {
        player.attack_cd = (player.attack_cd - dt).max(0.0)
      }
      player = sync_actor_visual(player, PLAYER_Z)
      player_runtime.val = Some(player)
    }
    None => ()
  }

  let player_pos = match player_runtime.val {
    Some(player) => player.position
    None => @math.Vec2D(0.0, 0.0)
  }
  let mut i = 0
  while i < enemy_runtimes.length() {
    let mut enemy = enemy_runtimes[i]
    let archetype = archetype_for(enemy)
    let to_player = player_pos - enemy.position
    let distance = vec_length(to_player)
    let mut dir = @math.Vec2D(0.0, 0.0)
    match archetype.ai_mode {
      Chase => dir = vec_normalize(to_player)
      HoldDistance => {
        let preferred = archetype.preferred_range.max(1.0)
        if distance > preferred * 1.15 {
          dir = vec_normalize(to_player)
        } else if distance < preferred * 0.85 {
          dir = vec_normalize(enemy.position - player_pos)
        } else {
          enemy.ai_wander_timer -= dt
          if enemy.ai_wander_timer <= 0.0 {
            let sign = if rand.int(limit=2) == 0 { -1.0 } else { 1.0 }
            let toward = vec_normalize(to_player)
            enemy.ai_wander_dir = @math.Vec2D(
              -toward[Y] * sign,
              toward[X] * sign,
            )
            enemy.ai_wander_timer = 0.45 + rand.double() * 0.35
          }
          dir = enemy.ai_wander_dir
        }
      }
      Wander => {
        enemy.ai_wander_timer -= dt
        if enemy.ai_wander_timer <= 0.0 {
          let raw_dir = @math.Vec2D(
            rand.double() * 2.0 - 1.0,
            rand.double() * 2.0 - 1.0,
          )
          enemy.ai_wander_dir = if vec_length(raw_dir) <= 0.001 {
            @math.Vec2D(1.0, 0.0)
          } else {
            vec_normalize(raw_dir)
          }
          enemy.ai_wander_timer = 0.55 + rand.double() * 1.1
        }
        dir = enemy.ai_wander_dir
      }
    }
    let is_moving = vec_length(dir) > 0.001
    enemy.facing = facing_from_vector(dir, enemy.facing)
    enemy.position = move_with_collision(
      enemy.position,
      archetype.radius,
      dir.scalar_mul(archetype.move_speed * dt),
    )
    enemy.moving = is_moving
    enemy.anim_elapsed = if is_moving { enemy.anim_elapsed + dt } else { 0.0 }
    enemy.attack_cd = (enemy.attack_cd - dt).max(0.0)
    enemy = sync_actor_visual(enemy, ENEMY_Z)
    enemy_runtimes[i] = enemy
    i += 1
  }
}

///|
fn player_forward(player : ActorRuntime) -> @math.Vec2D {
  match player.facing {
    Up => @math.Vec2D(0.0, -1.0)
    Down => @math.Vec2D(0.0, 1.0)
    Left => @math.Vec2D(-1.0, 0.0)
    Right => @math.Vec2D(1.0, 0.0)
  }
}

///|
fn process_player_attack_request(skill_id : String) -> Unit {
  match player_runtime.val {
    Some(player) => {
      if player.attack_cd > 0.0 {
        return
      }
      let skill = skill_by_id_or_abort(skill_id)
      let forward = player_forward(player)
      match skill.kind {
        Melee => {
          let mut hit_any = false
          for i = 0; i < enemy_runtimes.length(); i = i + 1 {
            let enemy = enemy_runtimes[i]
            let enemy_arch = archetype_for(enemy)
            let reach = skill.range + enemy_arch.radius
            if circle_intersects_circle(
                player.position + forward.scalar_mul(skill.range * 0.5),
                reach,
                enemy.position,
                enemy_arch.radius,
              ) {
              enemy.hp -= skill.damage.max(1)
              enemy_runtimes[i] = enemy
              hit_any = true
            }
          }
          if hit_any {
            combat_state.attack_flash_ttl = ATTACK_FLASH_SECONDS
          }
        }
        Projectile => spawn_projectile(false, player.position, forward, skill)
      }
      player.attack_cd = skill.cooldown.max(0.05)
      player_runtime.val = Some(player)
    }
    None => ()
  }
}

///|
fn enemy_try_attack_player(
  enemy : ActorRuntime,
  player : ActorRuntime,
) -> ActorRuntime {
  let enemy = enemy
  if enemy.attack_cd > 0.0 || run_state.phase != Playing {
    return enemy
  }
  let archetype = archetype_for(enemy)
  let player_radius = archetype_for(player).radius
  let to_player = player.position - enemy.position
  let distance = vec_length(to_player)
  match archetype.primary_skill_id {
    Some(skill_id) => {
      let skill = skill_by_id_or_abort(skill_id)
      match skill.kind {
        Melee =>
          if distance <= skill.range + archetype.radius + player_radius {
            apply_damage_to_player(skill.damage.max(1))
            enemy.attack_cd = skill.cooldown.max(0.12)
          }
        Projectile =>
          if distance <= skill.range && distance > 0.001 {
            spawn_projectile(
              true,
              enemy.position,
              vec_normalize(to_player),
              skill,
            )
            enemy.attack_cd = skill.cooldown.max(0.12)
          }
      }
    }
    None =>
      if archetype.touch_damage > 0 &&
        circle_intersects_circle(
          enemy.position,
          archetype.radius,
          player.position,
          player_radius,
        ) {
        apply_damage_to_player(archetype.touch_damage.max(1))
        enemy.attack_cd = 0.9
      }
  }
  enemy
}

///|
fn remove_dead_enemies() -> Unit {
  let mut i = 0
  while i < enemy_runtimes.length() {
    let enemy = enemy_runtimes[i]
    if enemy.hp > 0 {
      i += 1
      continue
    }
    let archetype = archetype_for(enemy)
    if enemy.entity.is_alive() {
      enemy.entity.destroy()
    }
    run_state.score += archetype.score_value.max(0)
    run_state.enemies_killed += 1
    maybe_drop_for_enemy(enemy)
    apply_enemy_killed_hook(enemy.archetype_id)
    ignore(enemy_runtimes.remove(i))
  }
}

///|
fn update_projectiles(dt : Double) -> Unit {
  let mut i = 0
  while i < projectile_runtimes.length() {
    let p = projectile_runtimes[i]
    p.ttl -= dt
    if p.ttl <= 0.0 {
      if p.entity.is_alive() {
        p.entity.destroy()
      }
      ignore(projectile_runtimes.remove(i))
      continue
    }
    p.position = p.position + p.velocity.scalar_mul(dt)
    let mut blocked = false
    for rect in world_state.blocking_rects {
      if rect_intersects_circle(rect, p.position, p.radius) {
        blocked = true
        break
      }
    }
    if blocked {
      if p.entity.is_alive() {
        p.entity.destroy()
      }
      ignore(projectile_runtimes.remove(i))
      continue
    }
    if p.owner_enemy {
      match player_runtime.val {
        Some(player) =>
          if circle_intersects_circle(
              p.position,
              p.radius,
              player.position,
              archetype_for(player).radius,
            ) {
            apply_damage_to_player(p.damage.max(1))
            if p.entity.is_alive() {
              p.entity.destroy()
            }
            ignore(projectile_runtimes.remove(i))
            continue
          }
        None => ()
      }
    } else {
      let mut hit_enemy = false
      for j = 0; j < enemy_runtimes.length(); j = j + 1 {
        let enemy = enemy_runtimes[j]
        let enemy_arch = archetype_for(enemy)
        if circle_intersects_circle(
            p.position,
            p.radius,
            enemy.position,
            enemy_arch.radius,
          ) {
          enemy.hp -= p.damage.max(1)
          enemy_runtimes[j] = enemy
          hit_enemy = true
          break
        }
      }
      if hit_enemy {
        if p.entity.is_alive() {
          p.entity.destroy()
        }
        ignore(projectile_runtimes.remove(i))
        continue
      }
    }
    if p.entity.is_alive() {
      @transform.transforms().set(
        p.entity,
        transform_xy(
          p.position[X] - p.radius,
          p.position[Y] - p.radius,
          PROJECTILE_Z,
        ),
      )
    }
    projectile_runtimes[i] = p
    i += 1
  }
}

///|
fn update_pickups() -> Unit {
  let mut i = 0
  while i < pickup_runtimes.length() {
    let pickup = pickup_runtimes[i]
    let mut picked = false
    match player_runtime.val {
      Some(player) =>
        if circle_intersects_circle(
            pickup.position,
            pickup.radius,
            player.position,
            archetype_for(player).radius,
          ) {
          if pickup.heal > 0 {
            let max_hp = archetype_for(player).max_hp
            player.hp = (player.hp + pickup.heal).min(max_hp)
            player_runtime.val = Some(player)
          }
          run_state.score += pickup.score_bonus
          run_state.pickups_collected += 1
          apply_pickup_hook(pickup.item_id)
          picked = true
        }
      None => ()
    }
    if picked {
      if pickup.entity.is_alive() {
        pickup.entity.destroy()
      }
      ignore(pickup_runtimes.remove(i))
      continue
    }
    i += 1
  }
  loot_state.live_pickups = pickup_runtimes.length()
}

///|
pub fn combat_system(_world : @ecs.World) -> Unit {
  if run_state.phase != Playing {
    return
  }
  let dt = @time.fixed_delta()
  match player_runtime.val {
    Some(player) => {
      if combat_state.primary_requested {
        match archetype_for(player).primary_skill_id {
          Some(skill_id) => process_player_attack_request(skill_id)
          None => ()
        }
      }
      if combat_state.secondary_requested {
        match archetype_for(player).secondary_skill_id {
          Some(skill_id) => process_player_attack_request(skill_id)
          None => ()
        }
      }
      for i = 0; i < enemy_runtimes.length(); i = i + 1 {
        enemy_runtimes[i] = enemy_try_attack_player(enemy_runtimes[i], player)
      }
    }
    None => ()
  }
  update_projectiles(dt)
  remove_dead_enemies()
}

///|
fn wave_finished_spawn(state : SpawnCursor) -> Bool {
  state.wave_index >= plugin().waves.length()
}

///|
fn spawn_point_indices_for_tag(tag : String?) -> Array[Int] {
  let indices : Array[Int] = []
  for idx = 0; idx < world_state.enemy_spawns.length(); idx = idx + 1 {
    let spawn = world_state.enemy_spawns[idx]
    if tag is None || spawn.tag == tag {
      indices.push(idx)
    }
  }
  indices
}

///|
pub fn spawn_loot_system(_world : @ecs.World) -> Unit {
  if run_state.phase != Playing {
    return
  }
  let dt = @time.fixed_delta()
  let cursor = spawn_state.cursor
  if !wave_finished_spawn(cursor) {
    let wave = plugin().waves[cursor.wave_index]
    if !cursor.wave_started {
      cursor.wait_timer -= dt
      if cursor.wait_timer <= 0.0 {
        cursor.wave_started = true
        cursor.wait_timer = 0.0
      }
    } else if !cursor.all_spawned {
      let entry = wave.entries[cursor.entry_index]
      cursor.wait_timer -= dt
      if cursor.wait_timer <= 0.0 {
        let spawn_indices = spawn_point_indices_for_tag(entry.spawn_tag)
        if spawn_indices.length() == 0 {
          cursor.wait_timer = entry.spawn_interval.max(0.15)
          spawn_state.cursor = cursor
          update_pickups()
          return
        }
        let spawn_index = (
            run_state.enemies_killed +
            enemy_runtimes.length() +
            cursor.spawned_in_entry
          ) %
          spawn_indices.length()
        let spawn_pos = world_state.enemy_spawns[spawn_indices[spawn_index]].position
        spawn_enemy(entry.archetype_id, spawn_pos)
        cursor.spawned_in_entry += 1
        cursor.wait_timer = entry.spawn_interval
      }
      if cursor.spawned_in_entry >= entry.count {
        cursor.entry_index += 1
        cursor.spawned_in_entry = 0
        cursor.wait_timer = 0.0
        if cursor.entry_index >= wave.entries.length() {
          cursor.all_spawned = true
        }
      }
    } else if enemy_runtimes.length() == 0 {
      cursor.wave_index += 1
      cursor.entry_index = 0
      cursor.spawned_in_entry = 0
      if cursor.wave_index < plugin().waves.length() {
        cursor.wave_started = false
        cursor.all_spawned = false
        cursor.wait_timer = plugin().waves[cursor.wave_index].start_delay
      }
    }
  }
  spawn_state.cursor = cursor
  update_pickups()
}

///|
pub fn state_transition_system(_world : @ecs.World) -> Unit {
  if run_state.phase != Playing {
    return
  }
  let dt = @time.fixed_delta()
  run_state.elapsed += dt
  run_state.time_left = (run_state.time_left - dt).max(0.0)
  if run_state.time_left <= 0.0 {
    run_state.phase = Lost
    run_state.status_message = "Time up. Press Enter to restart."
    return
  }
  if spawn_state.cursor.wave_index >= plugin().waves.length() &&
    enemy_runtimes.length() == 0 {
    run_state.phase = Won
    run_state.status_message = "Run clear! Press Enter to restart."
  }
}

///|
fn profile_debug_line() -> String {
  if !debug_overlay_enabled.val {
    ""
  } else {
    let fps = (1.0 / clamp_double(@time.delta(), 0.0001, 1.0)).to_int()
    "FPS \{fps} phase \{phase_name(run_state.phase)} enemies \{enemy_runtimes.length()} projectiles \{projectile_runtimes.length()} pickups \{pickup_runtimes.length()}"
  }
}

///|
pub fn render_sync_system(_world : @ecs.World) -> Unit {
  let mut title = plugin().ui_theme.title
  if profile_debug_line() != "" {
    title = "\{title}  |  \{profile_debug_line()}"
  }
  ui_state.title_text = title
  sync_text(title_entity, title_cache, ui_state.title_text)
  let hp_line = match player_runtime.val {
    Some(player) => {
      let max_hp = archetype_for(player).max_hp
      "HP \{player.hp}/\{max_hp}"
    }
    None => "HP 0/0"
  }
  ui_state.hud_text = "\{hp_line}  Score \{run_state.score}  Wave \{spawn_state.cursor.wave_index.min(plugin().waves.length()) + 1}/\{plugin().waves.length()}  Time \{run_state.time_left.floor().to_int()}s"
  sync_text(hud_entity, hud_cache, ui_state.hud_text)
  ui_state.message_text = if run_state.phase == Playing {
    plugin().ui_theme.control_hint
  } else {
    run_state.status_message
  }
  sync_text(message_entity, message_cache, ui_state.message_text)

  if combat_state.attack_flash_ttl > 0.0 {
    combat_state.attack_flash_ttl = (combat_state.attack_flash_ttl -
    @time.delta()).max(0.0)
  }
  let alpha = if combat_state.attack_flash_ttl > 0.0 {
    (combat_state.attack_flash_ttl / ATTACK_FLASH_SECONDS).min(1.0) * 0.32
  } else {
    0.0
  }
  match @sprite.sprites().get(attack_flash_entity) {
    Some(sprite) => {
      sprite.color = color_rgba(255U, 255U, 255U, alpha)
      @sprite.sprites().set(attack_flash_entity, sprite)
      set_entity_visible(attack_flash_entity, alpha > 0.001)
    }
    None => ()
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
  @raylib.take_screenshot(CAPTURE_PATH)
  capture_done.val = true
  @system.exit()
}
