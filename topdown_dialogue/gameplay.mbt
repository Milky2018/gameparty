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
fn player_archetype() -> @topdown_platform.ArchetypeDef {
  match player_runtime.val {
    Some(player) => archetype_by_id(plugin(), player.archetype_id).unwrap()
    None => archetype_by_id(plugin(), plugin().player_archetype_id).unwrap()
  }
}

///|
fn sync_player_visual(player : PlayerRuntime) -> PlayerRuntime {
  let archetype = player_archetype()
  let anim = @topdown_platform.sprite_anim_for_facing(
    archetype.sprites,
    player.facing,
  )
  let path = anim.image
  let frame = @topdown_platform.actor_frame_index(
    player.moving,
    player.anim_elapsed,
    anim,
  )
  let frame_rect = @topdown_platform.anim_frame_rect(anim, frame)
  let size = archetype.radius * 2.0 * anim.scale
  if path != player.last_sprite_path ||
    @sprite.sprites().get(player.entity) is None {
    let sprite = @sprite.Sprite::from_image(
      image_handle(path),
      custom_size=Some(@math.Vec2(size, size)),
    )
    sprite.rect = Some(frame_rect)
    sprite.anchor = @sprite.Anchor(@math.Vec2(-0.5, 0.5))
    @sprite.sprites().set(player.entity, sprite)
    player.last_sprite_path = path
  } else {
    match @sprite.sprites().get(player.entity) {
      Some(sprite) => {
        sprite.custom_size = Some(@math.Vec2(size, size))
        sprite.rect = Some(frame_rect)
        @sprite.sprites().set(player.entity, sprite)
      }
      None => ()
    }
  }
  @transform.transforms().set(
    player.entity,
    @topdown_platform.transform_xy(
      player.position[X] - archetype.radius,
      player.position[Y] - archetype.radius,
      PLAYER_Z,
    ),
  )
  @topdown_platform.set_entity_visible(player.entity, true)
  player
}

///|
fn sync_npc_visual(npc : NpcRuntime) -> NpcRuntime {
  let archetype = archetype_by_id(plugin(), npc.archetype_id).unwrap()
  let anim = @topdown_platform.sprite_anim_for_facing(
    archetype.sprites,
    npc.facing,
  )
  let path = anim.image
  let frame = @topdown_platform.actor_frame_index(
    npc.moving,
    npc.anim_elapsed,
    anim,
  )
  let frame_rect = @topdown_platform.anim_frame_rect(anim, frame)
  let size = archetype.radius * 2.0 * anim.scale
  if path != npc.last_sprite_path || @sprite.sprites().get(npc.entity) is None {
    let sprite = @sprite.Sprite::from_image(
      image_handle(path),
      custom_size=Some(@math.Vec2(size, size)),
    )
    sprite.rect = Some(frame_rect)
    sprite.anchor = @sprite.Anchor(@math.Vec2(-0.5, 0.5))
    @sprite.sprites().set(npc.entity, sprite)
    npc.last_sprite_path = path
  } else {
    match @sprite.sprites().get(npc.entity) {
      Some(sprite) => {
        sprite.custom_size = Some(@math.Vec2(size, size))
        sprite.rect = Some(frame_rect)
        @sprite.sprites().set(npc.entity, sprite)
      }
      None => ()
    }
  }
  @transform.transforms().set(
    npc.entity,
    @topdown_platform.transform_xy(
      npc.position[X] - archetype.radius,
      npc.position[Y] - archetype.radius,
      NPC_Z,
    ),
  )
  @topdown_platform.set_entity_visible(npc.entity, true)
  npc
}

///|
fn nearest_npc() -> NpcRuntime? {
  let player = match player_runtime.val {
    Some(player) => player
    None => return None
  }
  let mut best : NpcRuntime? = None
  let mut best_dist_sq = plugin().settings.interaction_radius *
    plugin().settings.interaction_radius
  for npc in npc_runtimes {
    let dx = npc.position[X] - player.position[X]
    let dy = npc.position[Y] - player.position[Y]
    let dist_sq = dx * dx + dy * dy
    if dist_sq <= best_dist_sq {
      best_dist_sq = dist_sq
      best = Some(npc)
    }
  }
  best
}

///|
fn active_line() -> DialogueLineDef? {
  let dialogue_id = match dialogue_state.active_dialogue_id {
    Some(id) => id
    None => return None
  }
  let script = match dialogue_by_id(plugin(), dialogue_id) {
    Some(script) => script
    None => return None
  }
  if dialogue_state.line_index < 0 ||
    dialogue_state.line_index >= script.lines.length() {
    return None
  }
  Some(script.lines[dialogue_state.line_index])
}

///|
fn update_runtime_snapshot() -> Unit {
  plugin_runtime_state.snapshot = make_runtime_snapshot()
}

///|
fn start_dialogue(npc : NpcRuntime) -> Unit {
  dialogue_state.active_npc_id = Some(npc.id)
  dialogue_state.active_dialogue_id = Some(npc.dialogue_id)
  dialogue_state.line_index = 0
  run_state.phase = Dialogue
  update_runtime_snapshot()
  match plugin().hooks {
    Some(hooks) =>
      match hooks.on_dialogue_started {
        Some(f) => f(plugin_runtime_state.snapshot, npc.id, npc.dialogue_id)
        None => ()
      }
    None => ()
  }
}

///|
fn finish_dialogue() -> Unit {
  let npc_id = dialogue_state.active_npc_id
  let dialogue_id = dialogue_state.active_dialogue_id
  update_runtime_snapshot()
  match plugin().hooks {
    Some(hooks) =>
      match hooks.on_dialogue_finished {
        Some(f) =>
          match npc_id {
            Some(npc_id) =>
              match dialogue_id {
                Some(dialogue_id) =>
                  f(plugin_runtime_state.snapshot, npc_id, dialogue_id)
                None => ()
              }
            None => ()
          }
        None => ()
      }
    None => ()
  }
  dialogue_state.active_npc_id = None
  dialogue_state.active_dialogue_id = None
  dialogue_state.line_index = 0
  run_state.phase = Playing
  update_runtime_snapshot()
}

///|
fn advance_dialogue() -> Unit {
  let dialogue_id = match dialogue_state.active_dialogue_id {
    Some(id) => id
    None => return
  }
  let script = dialogue_by_id(plugin(), dialogue_id).unwrap()
  if dialogue_state.line_index + 1 >= script.lines.length() {
    finish_dialogue()
  } else {
    dialogue_state.line_index += 1
    update_runtime_snapshot()
  }
}

///|
fn profile_debug_line() -> String {
  if !debug_overlay_enabled.val {
    ""
  } else {
    let fps = (1.0 / @topdown_platform.clamp_double(@time.delta(), 0.0001, 1.0)).to_int()
    "FPS \{fps} phase \{phase_name(run_state.phase)} npcs \{npc_runtimes.length()}"
  }
}

///|
pub fn input_system(_world : @ecs.World) -> Unit {
  if @raylib.is_key_pressed(@raylib.KeyF3) {
    debug_overlay_enabled.val = !debug_overlay_enabled.val
  }
  if run_state.phase == Dialogue {
    input_state.move_intent = @math.Vec2(0.0, 0.0)
    if @inputs.is_just_pressed(Escape) {
      finish_dialogue()
      return
    }
    if @inputs.is_just_pressed(KeyE) ||
      @inputs.is_just_pressed(Enter) ||
      @inputs.is_just_pressed(Space) {
      advance_dialogue()
    }
    return
  }

  if @inputs.is_just_pressed(Escape) {
    @system.exit()
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
  input_state.move_intent = @topdown_platform.vec_normalize(@math.Vec2(x, y))

  if @inputs.is_just_pressed(KeyE) ||
    @inputs.is_just_pressed(Enter) ||
    @inputs.is_just_pressed(Space) {
    match nearest_npc() {
      Some(npc) => start_dialogue(npc)
      None => ()
    }
  }
}

///|
pub fn intent_system(_world : @ecs.World) -> Unit {
  if run_state.phase != Playing {
    return
  }
  match player_runtime.val {
    Some(player) => {
      player.facing = @topdown_platform.facing_from_vector(
        input_state.move_intent,
        player.facing,
      )
      player_runtime.val = Some(player)
    }
    None => ()
  }
}

///|
pub fn movement_collision_system(_world : @ecs.World) -> Unit {
  let dt = @time.fixed_delta()

  match player_runtime.val {
    Some(player) => {
      let mut player = player
      let archetype = player_archetype()
      let is_moving = run_state.phase == Playing &&
        @topdown_platform.vec_length(input_state.move_intent) > 0.001
      let delta = if is_moving {
        input_state.move_intent.scalar_mul(archetype.move_speed * dt)
      } else {
        @math.Vec2(0.0, 0.0)
      }
      player.position = @topdown_platform.move_circle_with_collision(
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
      player = sync_player_visual(player)
      player_runtime.val = Some(player)
    }
    None => ()
  }

  let mut i = 0
  while i < npc_runtimes.length() {
    let npc = npc_runtimes[i]
    npc.moving = false
    npc.anim_elapsed = 0.0
    npc_runtimes[i] = sync_npc_visual(npc)
    i += 1
  }
}

///|
pub fn state_transition_system(_world : @ecs.World) -> Unit {
  run_state.elapsed += @time.fixed_delta()
  update_runtime_snapshot()
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
  ui_state.hud_text = "Tile (\{player_col}, \{player_row})  NPCs \{npc_runtimes.length()}  Time \{run_state.elapsed.floor().to_int()}s"
  sync_text(hud_entity, hud_cache, ui_state.hud_text)

  if run_state.phase == Dialogue {
    ui_state.message_text = plugin().settings.advance_hint
    sync_text(message_entity, message_cache, ui_state.message_text)
    match active_line() {
      Some(line) => {
        ui_state.speaker_text = line.speaker
        ui_state.dialogue_text = line.text
      }
      None => {
        ui_state.speaker_text = ""
        ui_state.dialogue_text = ""
      }
    }
    ui_state.dialogue_hint_text = plugin().settings.advance_hint
    sync_text(dialogue_speaker_entity, speaker_cache, ui_state.speaker_text)
    sync_text(dialogue_body_entity, body_cache, ui_state.dialogue_text)
    sync_text(dialogue_hint_entity, hint_cache, ui_state.dialogue_hint_text)
    set_panel_visible(true)
  } else {
    ui_state.message_text = match nearest_npc() {
      Some(npc) =>
        "\{plugin().settings.interact_prompt}: \{npc.display_name}  |  \{plugin().ui_theme.control_hint}"
      None => plugin().ui_theme.control_hint
    }
    sync_text(message_entity, message_cache, ui_state.message_text)
    sync_text(dialogue_speaker_entity, speaker_cache, "")
    sync_text(dialogue_body_entity, body_cache, "")
    sync_text(dialogue_hint_entity, hint_cache, plugin().settings.advance_hint)
    set_panel_visible(false)
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
