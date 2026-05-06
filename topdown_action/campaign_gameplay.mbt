///|
let campaign_title_cache : Ref[String] = { val: "" }

///|
let campaign_hud_cache : Ref[String] = { val: "" }

///|
let campaign_message_cache : Ref[String] = { val: "" }

///|
let campaign_overlay_cache : Ref[String] = { val: "" }

///|
fn campaign_sync_text(
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
fn campaign_actor_archetype(actor : CampaignActorRuntime) -> ArchetypeDef {
  campaign_archetype_by_id(actor.archetype_id)
}

///|
fn campaign_player_position() -> @math.Vec2 {
  match campaign_player_runtime.val {
    Some(player) => player.position
    None => campaign_world_state.player_spawn
  }
}

///|
fn campaign_update_camera() -> Unit {
  campaign_world_state.camera_origin = @topdown_platform.camera_origin_for_focus(
    campaign_player_position(),
    VIEWPORT_WIDTH,
    VIEWPORT_HEIGHT,
    campaign_world_state.world_width,
    campaign_world_state.world_height,
  )
}

///|
fn campaign_sync_world_tiles() -> Unit {
  for tile in campaign_world_tiles {
    let center = campaign_world_to_screen(tile.center)
    let floor_size = campaign_world_state.tile_size * tile.floor_visual.scale
    @transform.transforms().set(
      tile.floor_entity,
      transform_xy(
        center[X] - floor_size * 0.5,
        center[Y] - floor_size * 0.5 + tile.floor_visual.y_offset,
        CAMPAIGN_TILE_Z,
      ),
    )
    match (tile.prop_entity, tile.prop_visual) {
      (Some(prop_entity), Some(visual)) => {
        let prop_size = campaign_world_state.tile_size * visual.scale
        @transform.transforms().set(
          prop_entity,
          transform_xy(
            center[X] - prop_size * 0.5,
            center[Y] - prop_size * 0.5 + visual.y_offset,
            CAMPAIGN_PROP_Z,
          ),
        )
      }
      _ => ()
    }
  }
}

///|
fn campaign_sync_actor_visual(
  actor : CampaignActorRuntime,
  z : Double,
) -> CampaignActorRuntime {
  let archetype = campaign_actor_archetype(actor)
  let anim = @topdown_platform.sprite_anim_for_facing(
    archetype.sprites,
    actor.facing,
  )
  let frame = @topdown_platform.actor_frame_index(
    actor.moving,
    actor.anim_elapsed,
    anim,
  )
  let frame_rect = @topdown_platform.anim_frame_rect(anim, frame)
  let size = archetype.radius * 2.0 * anim.scale
  if actor.last_sprite_path != anim.image ||
    @sprite.sprites().get(actor.entity) is None {
    let sprite = @sprite.Sprite::from_image(
      campaign_image_handle(anim.image),
      custom_size=Some(@math.Vec2(size, size)),
    )
    sprite.rect = Some(frame_rect)
    sprite.anchor = @sprite.Anchor(@math.Vec2(-0.5, 0.5))
    @sprite.sprites().set(actor.entity, sprite)
    actor.last_sprite_path = anim.image
  } else {
    match @sprite.sprites().get(actor.entity) {
      Some(sprite) => {
        sprite.custom_size = Some(@math.Vec2(size, size))
        sprite.rect = Some(frame_rect)
        @sprite.sprites().set(actor.entity, sprite)
      }
      None => ()
    }
  }
  let screen = campaign_world_to_screen(actor.position)
  @transform.transforms().set(
    actor.entity,
    transform_xy(screen[X] - archetype.radius, screen[Y] - archetype.radius, z),
  )
  @topdown_platform.set_entity_visible(actor.entity, true)
  actor
}

///|
fn campaign_sync_follower_visual(
  follower : CampaignFollowerRuntime,
  index : Int,
) -> CampaignFollowerRuntime {
  if @sprite.sprites().get(follower.entity) is None {
    let base = campaign_plugin().follower.radius * 2.0
    let sprite = @sprite.Sprite::from_color(
      color_rgba(245U, 228U, 154U, 0.95),
      @math.Vec2(base, base),
    )
    sprite.anchor = @sprite.Anchor(@math.Vec2(-0.5, 0.5))
    @sprite.sprites().set(follower.entity, sprite)
  }
  let screen = campaign_world_to_screen(follower.position)
  let radius = campaign_plugin().follower.radius
  @transform.transforms().set(
    follower.entity,
    transform_xy(
      screen[X] - radius,
      screen[Y] - radius - (index % 2).to_double() * 1.5,
      CAMPAIGN_FOLLOWER_Z,
    ),
  )
  @topdown_platform.set_entity_visible(follower.entity, true)
  follower
}

///|
fn campaign_spawn_enemy(archetype_id : String, position : @math.Vec2) -> Unit {
  let archetype = campaign_archetype_by_id(archetype_id)
  let entity = @entity.Entity::new()
  campaign_dynamic_entities.push(entity)
  campaign_enemy_runtimes.push({
    entity,
    archetype_id: archetype.id,
    hp: archetype.max_hp,
    position,
    facing: @topdown_platform.Down,
    moving: false,
    anim_elapsed: 0.0,
    attack_cd: 0.0,
    invuln_ttl: 0.0,
    last_sprite_path: "",
    ai_wander_dir: @math.Vec2(0.0, 0.0),
    ai_wander_timer: 0.0,
  })
}

///|
fn campaign_spawn_projectile(
  owner_enemy : Bool,
  origin : @math.Vec2,
  direction : @math.Vec2,
  skill : SkillDef,
) -> Unit {
  let entity = @entity.Entity::new()
  campaign_dynamic_entities.push(entity)
  let velocity = direction.scalar_mul(skill.projectile_speed)
  let position = origin + direction.scalar_mul(24.0)
  campaign_projectile_runtimes.push({
    entity,
    owner_enemy,
    position,
    velocity,
    radius: skill.projectile_radius.max(2.0),
    damage: skill.damage.max(1),
    ttl: (skill.range / skill.projectile_speed).max(0.1),
  })
  let sprite = @sprite.Sprite::from_color(
    if owner_enemy {
      color_rgba(255U, 120U, 104U, 1.0)
    } else {
      color_rgba(120U, 220U, 255U, 1.0)
    },
    @math.Vec2(skill.projectile_radius * 2.0, skill.projectile_radius * 2.0),
  )
  sprite.anchor = @sprite.Anchor(@math.Vec2(-0.5, 0.5))
  @sprite.sprites().set(entity, sprite)
}

///|
fn campaign_spawn_followers(count : Int) -> Unit {
  for _ in 0..<count {
    let entity = @entity.Entity::new()
    campaign_dynamic_entities.push(entity)
    campaign_follower_runtimes.push({
      entity,
      position: campaign_player_position(),
    })
  }
}

///|
fn campaign_player_forward(player : CampaignActorRuntime) -> @math.Vec2 {
  match player.facing {
    @topdown_platform.Up => @math.Vec2(0.0, -1.0)
    @topdown_platform.UpRight => @math.Vec2(0.707, -0.707)
    @topdown_platform.Down => @math.Vec2(0.0, 1.0)
    @topdown_platform.DownRight => @math.Vec2(0.707, 0.707)
    @topdown_platform.Left => @math.Vec2(-1.0, 0.0)
    @topdown_platform.DownLeft => @math.Vec2(-0.707, 0.707)
    @topdown_platform.Right => @math.Vec2(1.0, 0.0)
    @topdown_platform.UpLeft => @math.Vec2(-0.707, -0.707)
  }
}

///|
fn campaign_can_player_fire(player : CampaignActorRuntime) -> Bool {
  player.attack_cd <= 0.0 && campaign_run_state.phase == Playing
}

///|
fn campaign_try_player_attack(skill_id : String) -> Unit {
  match campaign_player_runtime.val {
    Some(player) =>
      if campaign_can_player_fire(player) {
        match campaign_skill_by_id(skill_id) {
          Some(skill) => {
            let forward = campaign_player_forward(player)
            match skill.kind {
              Melee =>
                for idx = 0
                    idx < campaign_enemy_runtimes.length()
                    idx = idx + 1 {
                  let enemy = campaign_enemy_runtimes[idx]
                  let enemy_arch = campaign_actor_archetype(enemy)
                  if @topdown_platform.rect_intersects_circle(
                      {
                        position: player.position +
                        forward.scalar_mul(skill.range * 0.3) -
                        @math.Vec2(skill.range * 0.5, skill.range * 0.5),
                        size: @math.Vec2(skill.range, skill.range),
                      },
                      enemy.position,
                      enemy_arch.radius,
                    ) {
                    enemy.hp -= skill.damage.max(1)
                    campaign_enemy_runtimes[idx] = enemy
                  }
                }
              Projectile =>
                campaign_spawn_projectile(
                  false,
                  player.position,
                  forward,
                  skill,
                )
            }
            player.attack_cd = skill.cooldown.max(0.08)
            campaign_player_runtime.val = Some(player)
          }
          None => ()
        }
      }
    None => ()
  }
}

///|
fn campaign_apply_damage_to_player(amount : Int) -> Unit {
  if campaign_run_state.phase != Playing {
    return
  }
  match campaign_player_runtime.val {
    Some(player) =>
      if player.invuln_ttl <= 0.0 && player.hp > 0 {
        player.hp = (player.hp - amount.max(1)).max(0)
        campaign_player_runtime.val = Some(player)
      }
    None => ()
  }
}

///|
fn campaign_enemy_try_attack_player(
  enemy : CampaignActorRuntime,
  player : CampaignActorRuntime,
) -> CampaignActorRuntime {
  let enemy = enemy
  if enemy.attack_cd > 0.0 {
    return enemy
  }
  let archetype = campaign_actor_archetype(enemy)
  let player_arch = campaign_actor_archetype(player)
  let to_player = player.position - enemy.position
  let distance = @topdown_platform.vec_length(to_player)
  match archetype.primary_skill_id {
    Some(skill_id) =>
      match campaign_skill_by_id(skill_id) {
        Some(skill) =>
          match skill.kind {
            Melee =>
              if distance <= skill.range + archetype.radius + player_arch.radius {
                campaign_apply_damage_to_player(skill.damage.max(1))
                enemy.attack_cd = skill.cooldown.max(0.2)
              }
            Projectile =>
              if distance <= skill.range && distance > 0.001 {
                campaign_spawn_projectile(
                  true,
                  enemy.position,
                  @topdown_platform.vec_normalize(to_player),
                  skill,
                )
                enemy.attack_cd = skill.cooldown.max(0.2)
              }
          }
        None => ()
      }
    None =>
      if archetype.touch_damage > 0 &&
        @topdown_platform.rect_intersects_circle(
          {
            position: enemy.position -
            @math.Vec2(archetype.radius, archetype.radius),
            size: @math.Vec2(archetype.radius * 2.0, archetype.radius * 2.0),
          },
          player.position,
          player_arch.radius,
        ) {
        campaign_apply_damage_to_player(archetype.touch_damage.max(1))
        enemy.attack_cd = 0.9
      }
  }
  enemy
}

///|
fn campaign_remove_dead_enemies() -> Unit {
  let mut i = 0
  while i < campaign_enemy_runtimes.length() {
    let enemy = campaign_enemy_runtimes[i]
    if enemy.hp > 0 {
      i += 1
      continue
    }
    if enemy.entity.is_alive() {
      enemy.entity.destroy()
    }
    campaign_run_state.score += campaign_actor_archetype(enemy).score_value.max(
      0,
    )
    ignore(campaign_enemy_runtimes.remove(i))
  }
}

///|
fn campaign_update_projectiles(dt : Double) -> Unit {
  let mut i = 0
  while i < campaign_projectile_runtimes.length() {
    let projectile = campaign_projectile_runtimes[i]
    projectile.ttl -= dt
    if projectile.ttl <= 0.0 {
      if projectile.entity.is_alive() {
        projectile.entity.destroy()
      }
      ignore(campaign_projectile_runtimes.remove(i))
      continue
    }
    projectile.position = projectile.position +
      projectile.velocity.scalar_mul(dt)
    let mut blocked = false
    for rect in campaign_world_state.blocking_rects {
      if @topdown_platform.rect_intersects_circle(
          rect,
          projectile.position,
          projectile.radius,
        ) {
        blocked = true
        break
      }
    }
    if blocked {
      if projectile.entity.is_alive() {
        projectile.entity.destroy()
      }
      ignore(campaign_projectile_runtimes.remove(i))
      continue
    }
    if projectile.owner_enemy {
      match campaign_player_runtime.val {
        Some(player) =>
          if @topdown_platform.rect_intersects_circle(
              {
                position: player.position -
                @math.Vec2(
                  campaign_actor_archetype(player).radius,
                  campaign_actor_archetype(player).radius,
                ),
                size: @math.Vec2(
                  campaign_actor_archetype(player).radius * 2.0,
                  campaign_actor_archetype(player).radius * 2.0,
                ),
              },
              projectile.position,
              projectile.radius,
            ) {
            campaign_apply_damage_to_player(projectile.damage)
            if projectile.entity.is_alive() {
              projectile.entity.destroy()
            }
            ignore(campaign_projectile_runtimes.remove(i))
            continue
          }
        None => ()
      }
    } else {
      let mut hit_enemy = false
      for j = 0; j < campaign_enemy_runtimes.length(); j = j + 1 {
        let enemy = campaign_enemy_runtimes[j]
        let radius = campaign_actor_archetype(enemy).radius
        if @topdown_platform.rect_intersects_circle(
            {
              position: enemy.position - @math.Vec2(radius, radius),
              size: @math.Vec2(radius * 2.0, radius * 2.0),
            },
            projectile.position,
            projectile.radius,
          ) {
          enemy.hp -= projectile.damage
          campaign_enemy_runtimes[j] = enemy
          hit_enemy = true
          break
        }
      }
      if hit_enemy {
        if projectile.entity.is_alive() {
          projectile.entity.destroy()
        }
        ignore(campaign_projectile_runtimes.remove(i))
        continue
      }
    }
    if projectile.entity.is_alive() {
      let screen = campaign_world_to_screen(projectile.position)
      @transform.transforms().set(
        projectile.entity,
        transform_xy(
          screen[X] - projectile.radius,
          screen[Y] - projectile.radius,
          CAMPAIGN_PROJECTILE_Z,
        ),
      )
      @topdown_platform.set_entity_visible(projectile.entity, true)
    }
    campaign_projectile_runtimes[i] = projectile
    i += 1
  }
}

///|
fn campaign_spawn_indices_for_tag(tag : String?) -> Array[Int] {
  let indices : Array[Int] = []
  for idx = 0; idx < campaign_world_state.enemy_spawns.length(); idx = idx + 1 {
    let spawn = campaign_world_state.enemy_spawns[idx]
    if tag is None || spawn.tag == tag {
      indices.push(idx)
    }
  }
  indices
}

///|
fn campaign_advance_spawn_cursor(dt : Double) -> Unit {
  if campaign_run_state.phase != Playing {
    return
  }
  let stage = campaign_stage()
  let cursor = campaign_run_state.spawn_cursor
  if cursor.wave_index >= stage.waves.length() {
    return
  }
  let wave = stage.waves[cursor.wave_index]
  if !cursor.wave_started {
    cursor.wait_timer -= dt
    if cursor.wait_timer <= 0.0 {
      cursor.wave_started = true
      cursor.wait_timer = 0.0
    }
    campaign_run_state.spawn_cursor = cursor
    return
  }
  if cursor.all_spawned {
    if campaign_enemy_runtimes.length() == 0 {
      cursor.wave_index += 1
      cursor.entry_index = 0
      cursor.spawned_in_entry = 0
      if cursor.wave_index < stage.waves.length() {
        cursor.wave_started = false
        cursor.all_spawned = false
        cursor.wait_timer = stage.waves[cursor.wave_index].start_delay
      }
    }
    campaign_run_state.spawn_cursor = cursor
    return
  }
  let entry = wave.entries[cursor.entry_index]
  cursor.wait_timer -= dt
  if cursor.wait_timer <= 0.0 {
    let spawn_indices = campaign_spawn_indices_for_tag(entry.spawn_tag)
    if spawn_indices.length() > 0 {
      let offset = (
          cursor.spawned_in_entry +
          campaign_enemy_runtimes.length() +
          campaign_run_state.stage_index
        ) %
        spawn_indices.length()
      let spawn_pos = campaign_world_state.enemy_spawns[spawn_indices[offset]].position
      campaign_spawn_enemy(entry.archetype_id, spawn_pos)
      cursor.spawned_in_entry += 1
      cursor.wait_timer = entry.spawn_interval.max(0.12)
    } else {
      cursor.wait_timer = 0.25
    }
  }
  if cursor.spawned_in_entry >= entry.count {
    cursor.entry_index += 1
    cursor.spawned_in_entry = 0
    cursor.wait_timer = 0.0
    if cursor.entry_index >= wave.entries.length() {
      cursor.all_spawned = true
    }
  }
  campaign_run_state.spawn_cursor = cursor
}

///|
fn campaign_update_followers() -> Unit {
  if campaign_player_runtime.val is None {
    return
  }
  campaign_player_trail.push(campaign_player_position())
  let max_trail = 4096
  if campaign_player_trail.length() > max_trail {
    ignore(campaign_player_trail.remove(0))
  }
  let spacing = campaign_plugin().follower.spacing_steps.max(1)
  let trail_len = campaign_player_trail.length()
  for idx = 0; idx < campaign_follower_runtimes.length(); idx = idx + 1 {
    let follower = campaign_follower_runtimes[idx]
    let back_steps = (idx + 1) * spacing
    let target_index = if trail_len > back_steps {
      trail_len - 1 - back_steps
    } else {
      0
    }
    follower.position = campaign_player_trail[target_index]
    campaign_follower_runtimes[idx] = follower
  }
}

///|
fn campaign_update_objectives() -> Unit {
  if campaign_run_state.phase != Playing {
    return
  }
  let player_radius = match campaign_player_runtime.val {
    Some(player) => campaign_actor_archetype(player).radius
    None => return
  }
  let player_pos = campaign_player_position()
  let camp_radius = campaign_world_state.tile_size * 0.60
  for idx = 0; idx < campaign_camps.length(); idx = idx + 1 {
    let camp = campaign_camps[idx]
    if camp.triggered {
      continue
    }
    if @topdown_platform.rect_intersects_circle(
        {
          position: camp.position - @math.Vec2(camp_radius, camp_radius),
          size: @math.Vec2(camp_radius * 2.0, camp_radius * 2.0),
        },
        player_pos,
        player_radius,
      ) {
      camp.triggered = true
      campaign_run_state.rescued_total += camp.rescue_count
      campaign_spawn_followers(camp.rescue_count + CAMPAIGN_FOLLOWER_JOIN_BURST)
      campaign_camps[idx] = camp
      campaign_run_state.status_message = "Rescued \{campaign_run_state.rescued_total}/\{campaign_run_state.required_rescued}. Head to exit."
    }
  }
  match campaign_exit_zone.val {
    Some(exit_zone) =>
      if @topdown_platform.rect_intersects_circle(
          {
            position: exit_zone.position -
            @math.Vec2(exit_zone.radius, exit_zone.radius),
            size: @math.Vec2(exit_zone.radius * 2.0, exit_zone.radius * 2.0),
          },
          player_pos,
          player_radius,
        ) {
        if campaign_run_state.rescued_total >=
          campaign_run_state.required_rescued {
          campaign_run_state.rescued_delivered = campaign_run_state.rescued_total
          campaign_run_state.phase = StageClear
          campaign_run_state.stage_clear_ttl = campaign_plugin().campaign.clear_seconds
          campaign_run_state.status_message = "Stage \{campaign_stage().id} clear"
        } else {
          let need = campaign_run_state.required_rescued -
            campaign_run_state.rescued_total
          campaign_run_state.status_message = "Need \{need} more rescued before extraction"
        }
      }
    None => ()
  }
}

///|
fn campaign_try_transition_after_player_death() -> Unit {
  match campaign_player_runtime.val {
    Some(player) =>
      if player.hp <= 0 && campaign_run_state.phase == Playing {
        if campaign_run_state.lives > 1 {
          campaign_run_state.lives -= 1
          campaign_load_stage(campaign_run_state.stage_index)
        } else {
          campaign_run_state.lives = 0
          campaign_run_state.phase = GameOver
          campaign_run_state.status_message = "Base lost. Campaign failed."
        }
      }
    None => ()
  }
}

///|
fn campaign_try_advance_stage() -> Unit {
  let next = campaign_run_state.stage_index + 1
  if next >= campaign_plugin().campaign.stages.length() {
    campaign_run_state.phase = CampaignClear
    campaign_run_state.status_message = "Campaign clear."
  } else {
    campaign_load_stage(next)
  }
}

///|
fn campaign_request_start_from_menu() -> Unit {
  campaign_run_state.lives = campaign_plugin().campaign.lives
  campaign_run_state.score = 0
  campaign_load_stage(0)
}

///|
fn campaign_request_back_to_menu() -> Unit {
  campaign_enter_menu()
}

///|
fn campaign_request_restart_campaign() -> Unit {
  campaign_request_start_from_menu()
}

///|
fn campaign_sprite_audit_enabled() -> Bool {
  env_flag_enabled(CAMPAIGN_SPRITE_AUDIT_ENV)
}

///|
fn campaign_capture_requested() -> Bool {
  env_flag_enabled(CAMPAIGN_CAPTURE_ENV) || campaign_sprite_audit_enabled()
}

///|
fn campaign_sanitize_token(value : String) -> String {
  value
  .replace(old="/", new="_")
  .replace(old="\\", new="_")
  .replace(old=" ", new="_")
  .replace(old=":", new="_")
  .replace(old=".", new="_")
}

///|
fn campaign_sprite_path_matches(
  path : String,
  tracked_paths : Array[String],
) -> Bool {
  for tracked in tracked_paths {
    if path == tracked || path.contains(tracked) {
      return true
    }
  }
  false
}

///|
fn campaign_export_expected_anim_frames(
  plugin_id : String,
  archetype_id : String,
  direction : String,
  anim : @topdown_platform.SpriteAnimDef,
) -> Int {
  let mut exported = 0
  let columns = if anim.columns <= 0 { 1 } else { anim.columns }
  let frame_count = if anim.frame_count <= 0 { 1 } else { anim.frame_count }
  let resolved_path = @topdown_platform.resolve_asset_path(
    anim.image,
    asset_path_prefixes,
  )
  for frame in 0..<frame_count {
    let column = frame % columns
    let row = frame / columns
    let rect : @math.Rect = {
      position: @math.Vec2(
        column.to_double() * anim.frame_width,
        row.to_double() * anim.frame_height,
      ),
      size: @math.Vec2(anim.frame_width, anim.frame_height),
    }
    let out_path = "\{CAMPAIGN_AUDIT_OUTPUT_DIR}/\{plugin_id}_expected_\{campaign_sanitize_token(archetype_id)}_\{direction}_f\{frame}.png"
    let mut ok = @runtime_debug.export_texture_region_png(
      resolved_path, rect, out_path,
    )
    if !ok && resolved_path != anim.image {
      ok = @runtime_debug.export_texture_region_png(anim.image, rect, out_path)
    }
    if ok {
      exported += 1
    } else {
      println(
        "[topdown_action][campaign][audit] export_expected_failed archetype=\{archetype_id} direction=\{direction} frame=\{frame} image=\{resolved_path}",
      )
    }
  }
  exported
}

///|
fn campaign_export_expected_regions() -> Int {
  let plugin_id = campaign_sanitize_token(campaign_plugin().meta.id)
  let mut exported = 0
  for archetype in campaign_plugin().archetypes {
    exported += campaign_export_expected_anim_frames(
      plugin_id,
      archetype.id,
      "up",
      archetype.sprites.up,
    )
    exported += campaign_export_expected_anim_frames(
      plugin_id,
      archetype.id,
      "up_right",
      archetype.sprites.up_right,
    )
    exported += campaign_export_expected_anim_frames(
      plugin_id,
      archetype.id,
      "down",
      archetype.sprites.down,
    )
    exported += campaign_export_expected_anim_frames(
      plugin_id,
      archetype.id,
      "down_right",
      archetype.sprites.down_right,
    )
    exported += campaign_export_expected_anim_frames(
      plugin_id,
      archetype.id,
      "left",
      archetype.sprites.left,
    )
    exported += campaign_export_expected_anim_frames(
      plugin_id,
      archetype.id,
      "down_left",
      archetype.sprites.down_left,
    )
    exported += campaign_export_expected_anim_frames(
      plugin_id,
      archetype.id,
      "right",
      archetype.sprites.right,
    )
    exported += campaign_export_expected_anim_frames(
      plugin_id,
      archetype.id,
      "up_left",
      archetype.sprites.up_left,
    )
  }
  exported
}

///|
fn campaign_export_visible_regions() -> Int {
  let tracked_paths : Array[String] = []
  for archetype in campaign_plugin().archetypes {
    let sprites = archetype.sprites
    for
      image in [
        sprites.up.image,
        sprites.up_right.image,
        sprites.down.image,
        sprites.down_right.image,
        sprites.left.image,
        sprites.down_left.image,
        sprites.right.image,
        sprites.up_left.image,
      ] {
      tracked_paths.push(image)
      let resolved = @topdown_platform.resolve_asset_path(
        image, asset_path_prefixes,
      )
      if resolved != image {
        tracked_paths.push(resolved)
      }
    }
  }
  let entries = @runtime_debug.sprite_inspector_entries()
  let visible_entries : Array[@runtime_debug.SpriteInspectorEntry] = []
  for entry in entries {
    match entry.image_path {
      Some(path) =>
        if campaign_sprite_path_matches(path, tracked_paths) {
          visible_entries.push(entry)
        }
      None => ()
    }
  }
  let plugin_id = campaign_sanitize_token(campaign_plugin().meta.id)
  let exported = @runtime_debug.export_sprite_inspector_regions(
    visible_entries,
    CAMPAIGN_AUDIT_OUTPUT_DIR,
    file_naming=fn(entry, index) {
      let entity_name = match entry.entity_name {
        Some(value) => campaign_sanitize_token(value)
        None => "unnamed"
      }
      let image_name = match entry.image_path {
        Some(value) => campaign_sanitize_token(value)
        None => "no_image"
      }
      "\{plugin_id}_visible_entry_\{index}_e\{entry.entity_id}_\{entity_name}_\{image_name}.png"
    },
  )
  let mut exported_manual = 0
  if exported == 0 && visible_entries.length() > 0 {
    for index, entry in visible_entries {
      match (entry.image_path, entry.source_rect) {
        (Some(image_path), Some(rect)) => {
          let region : @math.Rect = {
            position: @math.Vec2(rect.x, rect.y),
            size: @math.Vec2(rect.width, rect.height),
          }
          let entity_name = match entry.entity_name {
            Some(value) => campaign_sanitize_token(value)
            None => "unnamed"
          }
          let out_path = "\{CAMPAIGN_AUDIT_OUTPUT_DIR}/\{plugin_id}_visible_manual_entry_\{index}_e\{entry.entity_id}_\{entity_name}.png"
          let mut ok = @runtime_debug.export_texture_region_png(
            image_path, region, out_path,
          )
          if !ok {
            let resolved = @topdown_platform.resolve_asset_path(
              image_path, asset_path_prefixes,
            )
            if resolved != image_path {
              ok = @runtime_debug.export_texture_region_png(
                resolved, region, out_path,
              )
            }
          }
          if ok {
            exported_manual += 1
          } else {
            println(
              "[topdown_action][campaign][audit] export_visible_failed entity=\{entry.entity_id} image=\{image_path} rect=\{rect.x},\{rect.y},\{rect.width},\{rect.height}",
            )
          }
        }
        _ => ()
      }
    }
  }
  println(
    "[topdown_action][campaign][audit] sprite_entries=\{entries.length()} matched=\{visible_entries.length()} exported_visible=\{exported} exported_visible_manual=\{exported_manual}",
  )
  exported + exported_manual
}

///|
fn campaign_capture_scene() -> Bool {
  let plugin_id = campaign_sanitize_token(campaign_plugin().meta.id)
  @runtime_debug.capture_frame_png_to_file(
    "\{CAMPAIGN_AUDIT_OUTPUT_DIR}/\{plugin_id}_campaign_scene.png",
  )
}

///|
pub fn campaign_input_system(_world : @ecs.World) -> Unit {
  if @host.is_key_pressed("F3") {
    campaign_debug_overlay_enabled.val = !campaign_debug_overlay_enabled.val
  }
  if @inputs.is_just_pressed(Escape) {
    if campaign_run_state.phase == MainMenu {
      @system.exit()
      return
    }
    campaign_request_back_to_menu()
    return
  }
  if campaign_sprite_audit_enabled() && campaign_run_state.phase == MainMenu {
    campaign_request_start_from_menu()
  }
  if campaign_run_state.phase == MainMenu {
    if @inputs.is_just_pressed(Enter) {
      campaign_request_start_from_menu()
    }
    campaign_input_state.move_intent = @math.Vec2(0.0, 0.0)
    campaign_input_state.primary_requested = false
    campaign_input_state.secondary_requested = false
    return
  }
  if campaign_run_state.phase == GameOver ||
    campaign_run_state.phase == CampaignClear {
    if @inputs.is_just_pressed(Enter) {
      campaign_request_restart_campaign()
    }
    campaign_input_state.move_intent = @math.Vec2(0.0, 0.0)
    campaign_input_state.primary_requested = false
    campaign_input_state.secondary_requested = false
    return
  }
  if campaign_run_state.phase == StageIntro ||
    campaign_run_state.phase == StageClear {
    campaign_input_state.move_intent = @math.Vec2(0.0, 0.0)
    campaign_input_state.primary_requested = false
    campaign_input_state.secondary_requested = false
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
  campaign_input_state.move_intent = @topdown_platform.vec_normalize(
    @math.Vec2(x, y),
  )
  campaign_input_state.primary_requested = @inputs.is_mouse_pressed(
    @inputs.MouseButton::Left,
  )
  campaign_input_state.secondary_requested = @inputs.is_just_pressed(Space)
}

///|
pub fn campaign_intent_system(_world : @ecs.World) -> Unit {
  if campaign_run_state.phase != Playing {
    return
  }
  match campaign_player_runtime.val {
    Some(player) => {
      player.facing = @topdown_platform.facing_from_vector(
        campaign_input_state.move_intent,
        player.facing,
      )
      campaign_player_runtime.val = Some(player)
    }
    None => ()
  }
}

///|
pub fn campaign_movement_collision_system(_world : @ecs.World) -> Unit {
  if campaign_run_state.phase != Playing {
    return
  }
  let dt = @time.fixed_delta()
  match campaign_player_runtime.val {
    Some(player) => {
      let player = player
      let archetype = campaign_actor_archetype(player)
      let is_moving = @topdown_platform.vec_length(
          campaign_input_state.move_intent,
        ) >
        0.001
      let delta = campaign_input_state.move_intent.scalar_mul(
        archetype.move_speed * dt,
      )
      player.position = @topdown_platform.move_circle_with_collision(
        player.position,
        archetype.radius,
        delta,
        campaign_world_state.blocking_rects,
        campaign_world_state.world_width,
        campaign_world_state.world_height,
      )
      player.moving = is_moving
      player.anim_elapsed = if is_moving {
        player.anim_elapsed + dt
      } else {
        0.0
      }
      player.attack_cd = (player.attack_cd - dt).max(0.0)
      player.invuln_ttl = (player.invuln_ttl - dt).max(0.0)
      campaign_player_runtime.val = Some(player)
    }
    None => ()
  }
  let player_pos = campaign_player_position()
  for i = 0; i < campaign_enemy_runtimes.length(); i = i + 1 {
    let enemy = campaign_enemy_runtimes[i]
    let archetype = campaign_actor_archetype(enemy)
    let to_player = player_pos - enemy.position
    let distance = @topdown_platform.vec_length(to_player)
    let mut dir = @math.Vec2(0.0, 0.0)
    match archetype.ai_mode {
      Chase => dir = @topdown_platform.vec_normalize(to_player)
      HoldDistance => {
        let preferred = archetype.preferred_range.max(1.0)
        if distance > preferred * 1.12 {
          dir = @topdown_platform.vec_normalize(to_player)
        } else if distance < preferred * 0.82 {
          dir = @topdown_platform.vec_normalize(enemy.position - player_pos)
        } else {
          enemy.ai_wander_timer -= dt
          if enemy.ai_wander_timer <= 0.0 {
            let toward = @topdown_platform.vec_normalize(to_player)
            let sign = if campaign_rand.int(limit=2) == 0 { -1.0 } else { 1.0 }
            enemy.ai_wander_dir = @math.Vec2(
              -toward[Y] * sign,
              toward[X] * sign,
            )
            enemy.ai_wander_timer = 0.4 + campaign_rand.double() * 0.35
          }
          dir = enemy.ai_wander_dir
        }
      }
      Wander => {
        enemy.ai_wander_timer -= dt
        if enemy.ai_wander_timer <= 0.0 {
          let candidate = @math.Vec2(
            campaign_rand.double() * 2.0 - 1.0,
            campaign_rand.double() * 2.0 - 1.0,
          )
          enemy.ai_wander_dir = if @topdown_platform.vec_length(candidate) <=
            0.001 {
            @math.Vec2(1.0, 0.0)
          } else {
            @topdown_platform.vec_normalize(candidate)
          }
          enemy.ai_wander_timer = 0.5 + campaign_rand.double() * 0.8
        }
        dir = enemy.ai_wander_dir
      }
    }
    enemy.moving = @topdown_platform.vec_length(dir) > 0.001
    enemy.facing = @topdown_platform.facing_from_vector(dir, enemy.facing)
    enemy.position = @topdown_platform.move_circle_with_collision(
      enemy.position,
      archetype.radius,
      dir.scalar_mul(archetype.move_speed * dt),
      campaign_world_state.blocking_rects,
      campaign_world_state.world_width,
      campaign_world_state.world_height,
    )
    enemy.anim_elapsed = if enemy.moving {
      enemy.anim_elapsed + dt
    } else {
      0.0
    }
    enemy.attack_cd = (enemy.attack_cd - dt).max(0.0)
    campaign_enemy_runtimes[i] = enemy
  }
  campaign_update_followers()
  campaign_update_camera()
}

///|
pub fn campaign_combat_system(_world : @ecs.World) -> Unit {
  if campaign_run_state.phase != Playing {
    return
  }
  let dt = @time.fixed_delta()
  match campaign_player_runtime.val {
    Some(player) => {
      if campaign_input_state.primary_requested {
        match campaign_actor_archetype(player).primary_skill_id {
          Some(skill_id) => campaign_try_player_attack(skill_id)
          None => ()
        }
      }
      if campaign_input_state.secondary_requested {
        match campaign_actor_archetype(player).secondary_skill_id {
          Some(skill_id) => campaign_try_player_attack(skill_id)
          None => ()
        }
      }
      for i = 0; i < campaign_enemy_runtimes.length(); i = i + 1 {
        campaign_enemy_runtimes[i] = campaign_enemy_try_attack_player(
          campaign_enemy_runtimes[i],
          player,
        )
      }
    }
    None => ()
  }
  campaign_update_projectiles(dt)
  campaign_remove_dead_enemies()
}

///|
pub fn campaign_spawn_system(_world : @ecs.World) -> Unit {
  campaign_advance_spawn_cursor(@time.fixed_delta())
}

///|
pub fn campaign_state_transition_system(_world : @ecs.World) -> Unit {
  let dt = @time.fixed_delta()
  match campaign_run_state.phase {
    MainMenu => ()
    StageIntro => {
      campaign_run_state.stage_intro_ttl = (campaign_run_state.stage_intro_ttl -
      dt).max(0.0)
      if campaign_run_state.stage_intro_ttl <= 0.0 {
        campaign_run_state.phase = Playing
      }
    }
    Playing => {
      campaign_try_transition_after_player_death()
      campaign_update_objectives()
    }
    StageClear => {
      campaign_run_state.stage_clear_ttl = (campaign_run_state.stage_clear_ttl -
      dt).max(0.0)
      if campaign_run_state.stage_clear_ttl <= 0.0 {
        campaign_try_advance_stage()
      }
    }
    GameOver => ()
    CampaignClear => ()
  }
}

///|
fn campaign_debug_line() -> String {
  if !campaign_debug_overlay_enabled.val {
    return ""
  }
  let fps = (1.0 / @topdown_platform.clamp_double(@time.delta(), 0.0001, 1.0)).to_int()
  "FPS \{fps} phase \{campaign_phase_name(campaign_run_state.phase)} enemies \{campaign_enemy_runtimes.length()} followers \{campaign_follower_runtimes.length()} projectiles \{campaign_projectile_runtimes.length()}"
}

///|
fn campaign_stage_progress_text() -> String {
  let total = campaign_plugin().campaign.stages.length()
  "Stage \{campaign_run_state.stage_index + 1}/\{total}"
}

///|
pub fn campaign_render_sync_system(_world : @ecs.World) -> Unit {
  campaign_update_camera()
  campaign_sync_world_tiles()

  match campaign_player_runtime.val {
    Some(player) =>
      campaign_player_runtime.val = Some(
        campaign_sync_actor_visual(player, CAMPAIGN_PLAYER_Z),
      )
    None => ()
  }
  for idx = 0; idx < campaign_enemy_runtimes.length(); idx = idx + 1 {
    campaign_enemy_runtimes[idx] = campaign_sync_actor_visual(
      campaign_enemy_runtimes[idx],
      CAMPAIGN_ENEMY_Z,
    )
  }
  for idx = 0; idx < campaign_follower_runtimes.length(); idx = idx + 1 {
    campaign_follower_runtimes[idx] = campaign_sync_follower_visual(
      campaign_follower_runtimes[idx],
      idx,
    )
  }
  for idx = 0; idx < campaign_projectile_runtimes.length(); idx = idx + 1 {
    let projectile = campaign_projectile_runtimes[idx]
    if projectile.entity.is_alive() {
      let screen = campaign_world_to_screen(projectile.position)
      @transform.transforms().set(
        projectile.entity,
        transform_xy(
          screen[X] - projectile.radius,
          screen[Y] - projectile.radius,
          CAMPAIGN_PROJECTILE_Z,
        ),
      )
    }
  }

  let mut title = campaign_plugin().ui_theme.title
  let debug = campaign_debug_line()
  if debug != "" {
    title = "\{title}  |  \{debug}"
  }
  campaign_ui_state.title_text = title
  campaign_sync_text(campaign_title_entity, campaign_title_cache, title)

  let hud = "Lives \{campaign_run_state.lives}  \{campaign_stage_progress_text()}  Rescued \{campaign_run_state.rescued_total}/\{campaign_run_state.required_rescued}  Enemies \{campaign_enemy_runtimes.length()}"
  campaign_ui_state.hud_text = hud
  campaign_sync_text(campaign_hud_entity, campaign_hud_cache, hud)

  let message = match campaign_run_state.phase {
    MainMenu => "ENTER start  ESC quit"
    StageIntro => "Get ready: \{campaign_stage().title}"
    Playing =>
      if campaign_run_state.status_message != "" {
        campaign_run_state.status_message
      } else {
        campaign_plugin().ui_theme.control_hint
      }
    StageClear => "Stage clear"
    GameOver => "Game over. ENTER restart"
    CampaignClear => "Campaign clear. ENTER restart"
  }
  campaign_ui_state.message_text = message
  campaign_sync_text(campaign_message_entity, campaign_message_cache, message)

  let overlay = match campaign_run_state.phase {
    MainMenu => "JACKAL  CAMPAIGN"
    StageIntro => "STAGE \{campaign_stage().id}"
    StageClear => "STAGE CLEARED"
    GameOver => "GAME OVER"
    CampaignClear => "CAMPAIGN CLEAR"
    Playing => ""
  }
  campaign_sync_text(campaign_overlay_entity, campaign_overlay_cache, overlay)
}

///|
pub fn campaign_capture_after_render_system(_world : @ecs.World) -> Unit {
  if !campaign_capture_requested() || campaign_capture_done.val {
    return
  }
  campaign_capture_timer.val += @time.delta()
  if campaign_capture_timer.val < CAMPAIGN_CAPTURE_DELAY_SECONDS {
    return
  }
  if campaign_sprite_audit_enabled() {
    let expected = campaign_export_expected_regions()
    let visible = campaign_export_visible_regions()
    println(
      "[topdown_action][campaign][audit] expected_exports=\{expected} visible_exports=\{visible}",
    )
  }
  if !campaign_capture_scene() {
    @host.take_screenshot(CAMPAIGN_CAPTURE_PATH)
    println(
      "[topdown_action][campaign][capture] path=\{CAMPAIGN_CAPTURE_PATH} (host fallback)",
    )
  }
  campaign_capture_done.val = true
  @system.exit()
}
