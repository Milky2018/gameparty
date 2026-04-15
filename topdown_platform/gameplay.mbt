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
fn sync_actor_visual(actor : ActorRuntime, z : Double) -> ActorRuntime {
  let archetype = archetype_for(actor)
  let anim = sprite_anim_for_facing(archetype.sprites, actor.facing)
  let path = anim.image
  let frame = actor_frame_index(actor.moving, actor.anim_elapsed, anim)
  let frame_rect = anim_frame_rect(anim, frame)
  let size = archetype.radius * 2.0 * anim.scale
  if path != actor.last_sprite_path ||
    @sprite.sprites().get(actor.entity) is None {
    let sprite = @sprite.Sprite::from_image(
      image_handle(path),
      custom_size=Some(@math.Vec2(size, size)),
    )
    sprite.rect = Some(frame_rect)
    sprite.anchor = @sprite.Anchor(@math.Vec2(-0.5, 0.5))
    @sprite.sprites().set(actor.entity, sprite)
    actor.last_sprite_path = path
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
  if @host.is_key_pressed("F3") {
    debug_overlay_enabled.val = !debug_overlay_enabled.val
  }
  request_restart_if_needed()
  if run_state.phase != Playing {
    input_state.move_intent = @math.Vec2(0.0, 0.0)
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
}

///|
pub fn intent_system(_world : @ecs.World) -> Unit {
  if run_state.phase != Playing {
    return
  }
  match player_runtime.val {
    Some(player) => {
      player.facing = facing_from_vector(input_state.move_intent, player.facing)
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
      let is_moving = vec_length(input_state.move_intent) > 0.001
      let delta = input_state.move_intent.scalar_mul(archetype.move_speed * dt)
      player.position = move_circle_with_collision(
        player.position,
        archetype.radius,
        delta,
        world_state.blocking_rects,
        world_state.world_width,
        world_state.world_height,
      )
      player.moving = is_moving
      player.anim_elapsed = if is_moving {
        player.anim_elapsed + dt
      } else {
        0.0
      }
      player = sync_actor_visual(player, PLAYER_Z)
      player_runtime.val = Some(player)
    }
    None => ()
  }

  let mut i = 0
  while i < actor_runtimes.length() {
    let actor = actor_runtimes[i]
    actor.moving = false
    actor.anim_elapsed = 0.0
    actor_runtimes[i] = sync_actor_visual(actor, ACTOR_Z)
    i += 1
  }
}

///|
pub fn state_transition_system(_world : @ecs.World) -> Unit {
  if run_state.phase != Playing {
    return
  }
  run_state.elapsed += @time.fixed_delta()
}

///|
fn profile_debug_line() -> String {
  if !debug_overlay_enabled.val {
    ""
  } else {
    let fps = (1.0 / clamp_double(@time.delta(), 0.0001, 1.0)).to_int()
    "FPS \{fps} phase \{phase_name(run_state.phase)} actors \{actor_runtimes.length()}"
  }
}

///|
pub fn render_sync_system(_world : @ecs.World) -> Unit {
  let mut title = plugin().ui_theme.title
  let profile = profile_debug_line()
  if profile != "" {
    title = "\{title}  |  \{profile}"
  }
  ui_state.title_text = title
  sync_text(title_entity, title_cache, ui_state.title_text)

  let tile_size = world_state.tile_size.max(1.0)
  let player_pos = match player_runtime.val {
    Some(player) => player.position
    None => @math.Vec2(0.0, 0.0)
  }
  let player_col = (player_pos[X] / tile_size).floor().to_int()
  let player_row = (player_pos[Y] / tile_size).floor().to_int()
  ui_state.hud_text = "Tile (\{player_col}, \{player_row})  Actors \{actor_runtimes.length()}  Time \{run_state.elapsed.floor().to_int()}s"
  sync_text(hud_entity, hud_cache, ui_state.hud_text)

  ui_state.message_text = plugin().ui_theme.control_hint
  sync_text(message_entity, message_cache, ui_state.message_text)
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
