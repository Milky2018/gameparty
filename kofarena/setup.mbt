///|
let text_content_cache : Map[@entity.Entity, String] = Map::new()

///|
let text_style_cache : Map[@entity.Entity, String] = Map::new()

///|
fn color_rgba(r : UInt, g : UInt, b : UInt, a : Double) -> @render.Color {
  { r, g, b, a }
}

///|
fn ensure_entity_alive(entity : @entity.Entity) -> Unit {
  if !entity.is_alive() {
    entity.respawn()
  }
}

///|
fn set_entity_visibility(entity : @entity.Entity, visible : Bool) -> Unit {
  @visibility.visibilities().set(entity, if visible { Visible } else { Hidden })
}

///|
fn transform_2d(center : @math.Vec2D, zindex : Int) -> @transform.Transform {
  {
    translation: @math.Vec3::new(center[X], center[Y], zindex.to_double()),
    rotation: @math.Quat::identity(),
    scale: @math.Vec3::one(),
  }
}

///|
fn set_rect_entity(
  entity : @entity.Entity,
  center : @math.Vec2D,
  size : @math.Vec2D,
  color : @render.Color,
  zindex : Int,
) -> Unit {
  ensure_entity_alive(entity)
  let sprite = @sprite.Sprite::from_color(color, size)
  sprite.anchor = @sprite.Anchor(@math.Vec2D(-0.5, 0.5))
  let top_left = @math.Vec2D(
    center[X] - size[X] * 0.5,
    center[Y] - size[Y] * 0.5,
  )
  @sprite.sprites().set(entity, sprite)
  @transform.transforms().set(entity, transform_2d(top_left, zindex))
  set_entity_visibility(entity, true)
}

///|
fn set_text_entity(
  entity : @entity.Entity,
  content : String,
  center : @math.Vec2D,
  color : String,
  font? : String = "28px sans-serif",
  zindex? : Int = UI_ZINDEX,
) -> Unit {
  ensure_entity_alive(entity)
  let style_key = color + "|" + font
  let style_changed = match text_style_cache.get(entity) {
    Some(existing) => existing != style_key
    None => true
  }
  if style_changed {
    @ui.text_fonts().set(entity, @ui.TextFont::from_css(font))
    @ui.text_colors().set(entity, @ui.TextColor::from_css(color))
    @ui.text_layouts().set(
      entity,
      @ui.TextLayout::new(align=Center, baseline=Center, wrap=NoWrap),
    )
    @text2d.text2ds().set(entity, @text2d.Text2d::new())
    @text2d.text_anchors().set(entity, @sprite.Anchor(@math.Vec2D(0.0, 0.0)))
    text_style_cache.set(entity, style_key)
  }
  let content_changed = match text_content_cache.get(entity) {
    Some(existing) => existing != content
    None => true
  }
  if content_changed {
    @ui.texts().set(entity, @ui.Text::new(content))
    text_content_cache.set(entity, content)
  }
  @transform.transforms().set(entity, transform_2d(center, zindex))
  set_entity_visibility(entity, true)
}

///|
fn show_menu_entities(visible : Bool) -> Unit {
  set_entity_visibility(title_entity, visible)
  set_entity_visibility(menu_entity, visible)
  set_entity_visibility(info_entity, visible)
}

///|
fn show_play_entities(visible : Bool) -> Unit {
  set_entity_visibility(timer_entity, visible)
  set_entity_visibility(debug_entity, visible)
  set_entity_visibility(banner_entity, visible)
  set_entity_visibility(p1_bar_back, visible)
  set_entity_visibility(p1_bar_fill, visible)
  set_entity_visibility(p2_bar_back, visible)
  set_entity_visibility(p2_bar_fill, visible)
}

///|
fn set_stage_object_visual(entity : @entity.Entity, obj : StageObject) -> Unit {
  let color = match obj.kind {
    Ground => color_rgba(44U, 54U, 74U, 1.0)
    Platform => color_rgba(69U, 78U, 98U, 1.0)
    Pillar => color_rgba(33U, 40U, 58U, 1.0)
  }
  set_rect_entity(
    entity,
    @math.Vec2D(obj.rect.x + obj.rect.w * 0.5, obj.rect.y + obj.rect.h * 0.5),
    @math.Vec2D(obj.rect.w, obj.rect.h),
    color,
    20,
  )
}

///|
fn stage_rects() -> Array[StageObject] {
  [
    {
      kind: Ground,
      rect: {
        x: 0.0,
        y: GROUND_Y,
        w: VIEWPORT_WIDTH,
        h: VIEWPORT_HEIGHT - GROUND_Y,
      },
    },
    { kind: Platform, rect: { x: 470.0, y: 470.0, w: 340.0, h: 22.0 } },
    { kind: Pillar, rect: { x: 220.0, y: 515.0, w: 70.0, h: 105.0 } },
    { kind: Pillar, rect: { x: 990.0, y: 515.0, w: 70.0, h: 105.0 } },
  ]
}

///|
fn fighter_start_x(id : PlayerId) -> Double {
  match id {
    P1 => 250.0
    P2 => 1030.0
  }
}

///|
fn fighter_start_facing(id : PlayerId) -> Facing {
  match id {
    P1 => Right
    P2 => Left
  }
}

///|
fn reset_fighter(fighter : FighterState) -> Unit {
  fighter.x = fighter_start_x(fighter.id)
  fighter.y = GROUND_Y - HURTBOX_HEIGHT
  fighter.vx = 0.0
  fighter.vy = 0.0
  fighter.facing = fighter_start_facing(fighter.id)
  fighter.pose = Idle
  fighter.on_ground = true
  fighter.crouching = false
  fighter.health = MAX_HEALTH
  fighter.attack_kind = None
  fighter.attack_elapsed = 0.0
  fighter.attack_cooldown = 0.0
  fighter.attack_hit = false
  fighter.hitstun = 0.0
  fighter.invuln = 0.0
  fighter.backstep_timer = 0.0
  fighter.ai_timer = 0.0
  fighter.last_human_input = -1000.0
  fighter.input_mode = if fighter.id == P2 && !game_state.p2_human_enabled {
    AI
  } else {
    Human
  }
}

///|
fn reset_round() -> Unit {
  game_state.phase = Playing
  game_state.round_time = ROUND_TIME_SECONDS
  game_state.round_outcome = None
  game_state.round_banner_timer = 0.0
  profile_started_at.val = @time.elapsed()
  profile_last_report_at.val = profile_started_at.val
  profile_frame_count.val = 0
  profile_delta_accum.val = 0.0
  reset_fighter(p1)
  reset_fighter(p2)
  show_menu_entities(false)
  show_play_entities(true)
}

///|
fn enter_menu() -> Unit {
  game_state.phase = MainMenu
  game_state.round_outcome = None
  game_state.round_banner_timer = 0.0
  show_menu_entities(true)
  show_play_entities(false)
}

///|
fn enter_round_over(outcome : RoundOutcome) -> Unit {
  game_state.phase = RoundOver
  game_state.round_outcome = Some(outcome)
  game_state.round_banner_timer = 0.0
  play_ko_sound()
}

///|
fn build_stage() -> Unit {
  stage_objects.clear()
  for obj in stage_rects() {
    stage_objects.push(obj)
  }
  set_rect_entity(
    stage_bg_entity,
    @math.Vec2D(VIEWPORT_WIDTH * 0.5, VIEWPORT_HEIGHT * 0.5),
    @math.Vec2D(VIEWPORT_WIDTH, VIEWPORT_HEIGHT),
    color_rgba(16U, 22U, 40U, 1.0),
    0,
  )
  set_stage_object_visual(floor_entity, stage_objects[0])
  set_stage_object_visual(platform_entity, stage_objects[1])
  set_stage_object_visual(left_pillar_entity, stage_objects[2])
  set_stage_object_visual(right_pillar_entity, stage_objects[3])
}

///|
fn setup_hud_entities() -> Unit {
  set_text_entity(
    title_entity,
    "KOF ARENA",
    @math.Vec2D(VIEWPORT_WIDTH * 0.5, 68.0),
    "rgb(255,248,238)",
    font="52px sans-serif",
    zindex=UI_ZINDEX + 20,
  )
  set_text_entity(
    menu_entity,
    "ENTER START  F2 P2 MODE  F3 FPS  ESC EXIT",
    @math.Vec2D(VIEWPORT_WIDTH * 0.5, 126.0),
    "rgb(222,231,242)",
    font="16px monospace",
    zindex=UI_ZINDEX + 20,
  )
  set_text_entity(
    info_entity,
    "",
    @math.Vec2D(VIEWPORT_WIDTH * 0.5, 154.0),
    "rgb(198,210,225)",
    font="14px monospace",
    zindex=UI_ZINDEX + 20,
  )
  set_text_entity(
    timer_entity,
    "",
    @math.Vec2D(VIEWPORT_WIDTH * 0.5, 30.0),
    "rgb(255,248,238)",
    font="32px sans-serif",
    zindex=UI_ZINDEX + 20,
  )
  set_text_entity(
    debug_entity,
    "",
    @math.Vec2D(26.0, 26.0),
    "rgb(210,220,230)",
    font="20px sans-serif",
    zindex=UI_ZINDEX + 20,
  )
  set_text_entity(
    banner_entity,
    "",
    @math.Vec2D(VIEWPORT_WIDTH * 0.5, 240.0),
    "rgb(255,244,210)",
    font="50px sans-serif",
    zindex=UI_ZINDEX + 20,
  )
  set_rect_entity(
    p1_bar_back,
    @math.Vec2D(42.0, 58.0),
    @math.Vec2D(360.0, 26.0),
    color_rgba(24U, 30U, 44U, 0.9),
    UI_ZINDEX + 10,
  )
  set_rect_entity(
    p1_bar_fill,
    @math.Vec2D(46.0, 62.0),
    @math.Vec2D(352.0, 18.0),
    color_rgba(232U, 70U, 76U, 1.0),
    UI_ZINDEX + 11,
  )
  set_rect_entity(
    p2_bar_back,
    @math.Vec2D(VIEWPORT_WIDTH - 402.0, 58.0),
    @math.Vec2D(360.0, 26.0),
    color_rgba(24U, 30U, 44U, 0.9),
    UI_ZINDEX + 10,
  )
  set_rect_entity(
    p2_bar_fill,
    @math.Vec2D(VIEWPORT_WIDTH - 398.0, 62.0),
    @math.Vec2D(352.0, 18.0),
    color_rgba(66U, 152U, 244U, 1.0),
    UI_ZINDEX + 11,
  )
  show_menu_entities(true)
  show_play_entities(false)
}

///|
fn assign_fighter_entities() -> Unit {
  set_rect_entity(
    left_fighter_entity,
    @math.Vec2D(p1.x, p1.y),
    @math.Vec2D(HURTBOX_WIDTH, HURTBOX_HEIGHT),
    color_rgba(246U, 88U, 80U, 1.0),
    40,
  )
  set_rect_entity(
    right_fighter_entity,
    @math.Vec2D(p2.x, p2.y),
    @math.Vec2D(HURTBOX_WIDTH, HURTBOX_HEIGHT),
    color_rgba(88U, 164U, 255U, 1.0),
    40,
  )
  set_rect_entity(
    left_attack_entity,
    @math.Vec2D(-100.0, -100.0),
    @math.Vec2D(1.0, 1.0),
    color_rgba(255U, 198U, 72U, 0.35),
    41,
  )
  set_rect_entity(
    right_attack_entity,
    @math.Vec2D(-100.0, -100.0),
    @math.Vec2D(1.0, 1.0),
    color_rgba(255U, 198U, 72U, 0.35),
    41,
  )
  set_rect_entity(
    left_crouch_entity,
    @math.Vec2D(-100.0, -100.0),
    @math.Vec2D(1.0, 1.0),
    color_rgba(255U, 255U, 255U, 0.12),
    39,
  )
  set_rect_entity(
    right_crouch_entity,
    @math.Vec2D(-100.0, -100.0),
    @math.Vec2D(1.0, 1.0),
    color_rgba(255U, 255U, 255U, 0.12),
    39,
  )
}

///|
pub fn startup_system(_world : @ecs.World) -> Unit {
  capture_enabled.val = match @env.get_env_var(CAPTURE_ENV) {
    Some(value) => value == "1" || value == "true" || value == "TRUE"
    None => false
  }
  profile_enabled.val = match @env.get_env_var(PROFILE_ENV) {
    Some(value) => value == "1" || value == "true" || value == "TRUE"
    None => false
  }
  capture_started_at.val = @time.elapsed()
  register_sounds_once()
  build_stage()
  setup_hud_entities()
  assign_fighter_entities()
  if capture_enabled.val {
    reset_round()
  } else {
    reset_round()
    enter_menu()
  }
}
