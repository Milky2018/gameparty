///|
const ANGRYRABBITS_FONT_FAMILY : String = "ThaleahFat"

///|
const ANGRYRABBITS_FONT_PATH : String = "angryrabbits/assets/ThaleahFat.ttf"

///|
let angryrabbits_font_registered : Ref[Bool] = { val: false }

///|
fn register_angryrabbits_font_once() -> Unit {
  if angryrabbits_font_registered.val {
    return
  }
  ignore(
    @asset.load_font(ANGRYRABBITS_FONT_PATH, family=ANGRYRABBITS_FONT_FAMILY),
  )
  angryrabbits_font_registered.val = true
}

///|
fn ensure_entity_alive(entity : @entity.Entity) -> Unit {
  if !entity.is_alive() {
    entity.respawn()
  }
}

///|
fn ensure_entity_list(entities : Array[@entity.Entity], count : Int) -> Unit {
  while entities.length() < count {
    entities.push(@entity.Entity::new())
  }
  for entity in entities {
    ensure_entity_alive(entity)
  }
}

///|
fn center_to_rect_position(
  center : @math.Vec2D,
  size : @math.Vec2D,
) -> @math.Vec2D {
  @math.Vec2D(center[X] - size[X] / 2.0, center[Y] - size[Y] / 2.0)
}

///|
fn center_to_circle_position(
  center : @math.Vec2D,
  radius : Double,
) -> @math.Vec2D {
  @math.Vec2D(center[X] - radius, center[Y] - radius)
}

///|
fn rabbit_center_top_left() -> @math.Vec2D {
  center_to_circle_position(rabbit_center.val, RABBIT_RADIUS)
}

///|
fn register_scene_entities() -> Unit {
  for
    entity in [
      background_entity, ground_entity, hill_entity, slingshot_left_entity, slingshot_right_entity,
      slingshot_base_entity, rabbit_entity, rabbit_eye_entity, title_entity, hint_entity,
      status_entity, score_entity,
    ] {
    ensure_entity_alive(entity)
  }
  ensure_entity_list(aim_dot_entities, AIM_DOT_COUNT)
}

///|
fn register_level_entities(level : LevelDef) -> Unit {
  ensure_entity_list(block_entities, level.blocks.length())
  ensure_entity_list(target_entities, level.targets.length())
}

///|
fn hide_unused_level_entities(level : LevelDef) -> Unit {
  for index in level.blocks.length()..<block_entities.length() {
    if @sprite.sprites().get(block_entities[index]) is Some(sprite) {
      sprite.visible = false
    }
  }
  for index in level.targets.length()..<target_entities.length() {
    if @sprite.sprites().get(target_entities[index]) is Some(sprite) {
      sprite.visible = false
    }
  }
}

///|
fn instantiate_level(level : LevelDef) -> Unit {
  blocks.clear()
  targets.clear()
  for index, block in level.blocks {
    blocks.push({
      entity: block_entities[index],
      center: block.center,
      size: block.size,
      velocity: @math.Vec2D::zero(),
      color: block.color,
      alive: true,
    })
  }
  for index, target in level.targets {
    targets.push({
      entity: target_entities[index],
      center: target.center,
      radius: target.radius,
      velocity: @math.Vec2D::zero(),
      color: target.color,
      alive: true,
    })
  }
  hide_unused_level_entities(level)
}

///|
fn hide_aim_dots() -> Unit {
  for entity in aim_dot_entities {
    if @sprite.sprites().get(entity) is Some(sprite) {
      sprite.visible = false
    }
  }
}

///|
fn launch_velocity_from_rabbit(center : @math.Vec2D) -> @math.Vec2D {
  (slingshot_anchor() - center).scalar_mul(LAUNCH_SPEED_FACTOR)
}

///|
fn refresh_aim_dots() -> Unit {
  if phase.val != Dragging {
    hide_aim_dots()
    return
  }
  let velocity = launch_velocity_from_rabbit(rabbit_center.val)
  for index, entity in aim_dot_entities {
    let time = (index.to_double() + 1.0) * AIM_DOT_TIME_STEP
    let offset = velocity.scalar_mul(time) +
      @math.Vec2D(0.0, GRAVITY * 0.5 * time * time)
    @transform.positions().set(
      entity,
      center_to_circle_position(rabbit_center.val + offset, AIM_DOT_RADIUS),
    )
    @sprite.sprites().set(
      entity,
      @sprite.Sprite::from_color_circle(
        @sprite.ColorCircle::new(
          AIM_DOT_RADIUS,
          "rgba(255,255,255,0.85)",
          stroke_color="rgba(0,0,0,0.0)",
        ),
        120,
      ),
    )
  }
}

///|
fn set_text_entity(
  entity : @entity.Entity,
  text : String,
  position : @math.Vec2D,
  font : String,
  color : String,
  zindex : Int,
) -> Unit {
  ensure_entity_alive(entity)
  @sprite.sprites().set(
    entity,
    @sprite.Sprite::from_text(
      @sprite.Text::new(text, color~, font~, baseline=Top, align=Left),
      zindex,
    ),
  )
  @transform.positions().set(entity, position)
}

///|
fn sync_static_visuals() -> Unit {
  let anchor = slingshot_anchor()
  let level = current_level.val
  let background = level.background_rect
  let ground = level.ground_rect
  let hill = level.hill_circle
  @sprite.sprites().set(
    background_entity,
    @sprite.Sprite::from_color_rect(
      @sprite.ColorRect::new(background.size, background.color),
      background.zindex,
    ),
  )
  @transform.positions().set(background_entity, background.position)

  @sprite.sprites().set(
    hill_entity,
    @sprite.Sprite::from_color_circle(
      @sprite.ColorCircle::new(hill.radius, hill.color),
      hill.zindex,
    ),
  )
  @transform.positions().set(
    hill_entity,
    center_to_circle_position(hill.center, hill.radius),
  )

  @sprite.sprites().set(
    ground_entity,
    @sprite.Sprite::from_color_rect(
      @sprite.ColorRect::new(ground.size, ground.color),
      ground.zindex,
    ),
  )
  @transform.positions().set(ground_entity, ground.position)

  @sprite.sprites().set(
    slingshot_left_entity,
    @sprite.Sprite::from_color_rect(
      @sprite.ColorRect::new(@math.Vec2D(16.0, 96.0), "rgb(122, 76, 39)"),
      30,
    ),
  )
  @transform.positions().set(
    slingshot_left_entity,
    anchor + @math.Vec2D(-26.0, -8.0),
  )

  @sprite.sprites().set(
    slingshot_right_entity,
    @sprite.Sprite::from_color_rect(
      @sprite.ColorRect::new(@math.Vec2D(16.0, 112.0), "rgb(101, 61, 28)"),
      31,
    ),
  )
  @transform.positions().set(
    slingshot_right_entity,
    anchor + @math.Vec2D(6.0, -24.0),
  )

  @sprite.sprites().set(
    slingshot_base_entity,
    @sprite.Sprite::from_color_rect(
      @sprite.ColorRect::new(@math.Vec2D(54.0, 18.0), "rgb(133, 86, 45)"),
      29,
    ),
  )
  @transform.positions().set(
    slingshot_base_entity,
    anchor + @math.Vec2D(-38.0, 70.0),
  )
}

///|
fn sync_dynamic_visuals() -> Unit {
  let rabbit_color = match phase.val {
    Won => "rgb(250, 244, 230)"
    Lost => "rgb(188, 188, 188)"
    _ => "rgb(246, 244, 238)"
  }
  @sprite.sprites().set(
    rabbit_entity,
    @sprite.Sprite::from_color_circle(
      @sprite.ColorCircle::new(
        RABBIT_RADIUS,
        rabbit_color,
        stroke_color="rgb(64, 48, 42)",
      ),
      70,
    ),
  )
  @transform.positions().set(rabbit_entity, rabbit_center_top_left())
  if @sprite.sprites().get(rabbit_entity) is Some(sprite) {
    sprite.visible = rabbit_visible.val
  }

  @sprite.sprites().set(
    rabbit_eye_entity,
    @sprite.Sprite::from_color_circle(
      @sprite.ColorCircle::new(3.2, "rgb(36, 32, 31)"),
      71,
    ),
  )
  @transform.positions().set(
    rabbit_eye_entity,
    center_to_circle_position(rabbit_center.val + @math.Vec2D(6.0, -3.0), 3.2),
  )
  if @sprite.sprites().get(rabbit_eye_entity) is Some(sprite) {
    sprite.visible = rabbit_visible.val
  }

  for block in blocks {
    @sprite.sprites().set(
      block.entity,
      @sprite.Sprite::from_color_rect(
        @sprite.ColorRect::new(
          block.size,
          block.color,
          stroke_color="rgb(92, 58, 26)",
        ),
        60,
      ),
    )
    @transform.positions().set(
      block.entity,
      center_to_rect_position(block.center, block.size),
    )
    if @sprite.sprites().get(block.entity) is Some(sprite) {
      sprite.visible = block.alive
    }
  }

  for target in targets {
    @sprite.sprites().set(
      target.entity,
      @sprite.Sprite::from_color_circle(
        @sprite.ColorCircle::new(
          target.radius,
          target.color,
          stroke_color="rgb(54, 112, 45)",
        ),
        65,
      ),
    )
    @transform.positions().set(
      target.entity,
      center_to_circle_position(target.center, target.radius),
    )
    if @sprite.sprites().get(target.entity) is Some(sprite) {
      sprite.visible = target.alive
    }
  }

  refresh_aim_dots()
}

///|
fn status_text() -> String {
  match phase.val {
    Ready => "Drag the rabbit backward with the mouse, then release."
    Dragging => "Release to launch. Rabbit speed scales with stretch."
    Flying => "Break every green target before you run out of rabbits."
    Won => "Stage cleared. Press Enter or R to play again."
    Lost => "Out of rabbits. Press Enter or R to retry."
  }
}

///|
fn score_text() -> String {
  let remaining_targets = targets.filter(fn(target) { target.alive }).length()
  "Rabbits: \{shots_remaining.val}   Targets: \{remaining_targets}"
}

///|
fn sync_ui() -> Unit {
  set_text_entity(
    title_entity,
    "ANGRY RABBITS",
    @math.Vec2D(20.0, 16.0),
    "32px \{ANGRYRABBITS_FONT_FAMILY}",
    "rgb(84, 48, 22)",
    220,
  )
  set_text_entity(
    hint_entity,
    "Mouse drag/release launch   R/Enter restart   ESC back",
    @math.Vec2D(20.0, VIEWPORT_HEIGHT - 28.0),
    "16px \{ANGRYRABBITS_FONT_FAMILY}",
    "rgb(77, 74, 66)",
    220,
  )
  set_text_entity(
    score_entity,
    score_text(),
    @math.Vec2D(20.0, 54.0),
    "20px \{ANGRYRABBITS_FONT_FAMILY}",
    "rgb(66, 52, 32)",
    220,
  )
  set_text_entity(
    status_entity,
    status_text(),
    @math.Vec2D(20.0, 82.0),
    "18px \{ANGRYRABBITS_FONT_FAMILY}",
    if phase.val == Won {
      "rgb(32, 112, 48)"
    } else if phase.val == Lost {
      "rgb(161, 54, 44)"
    } else {
      "rgb(72, 60, 44)"
    },
    220,
  )
}

///|
fn reset_level() -> Unit {
  let level = load_current_level()
  current_level.val = level
  register_scene_entities()
  register_level_entities(level)
  register_angryrabbits_font_once()
  sync_static_visuals()
  instantiate_level(level)
  shots_remaining.val = level.max_shots
  phase.val = Ready
  rabbit_center.val = rabbit_spawn_point()
  rabbit_velocity.val = @math.Vec2D::zero()
  rabbit_visible.val = true
  rabbit_flight_time.val = 0.0
  sync_dynamic_visuals()
  sync_ui()
}

///|
fn setup_scene_if_needed() -> Unit {
  if !scene_initialized.val {
    register_scene_entities()
    scene_initialized.val = true
  }
}

///|
fn startup_system(_world : @ecs.World) -> Unit {
  setup_scene_if_needed()
  reset_level()
}
