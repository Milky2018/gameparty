///|
priv struct CombatInput {
  move_x : Double
  jump : Bool
  crouch : Bool
  light : Bool
  heavy : Bool
  backstep : Bool
}

///|
fn abs_double(value : Double) -> Double {
  if value < 0.0 {
    -value
  } else {
    value
  }
}

///|
fn clamp_double_game(value : Double, min_ : Double, max_ : Double) -> Double {
  if value < min_ {
    min_
  } else if value > max_ {
    max_
  } else {
    value
  }
}

///|
fn clamp_int(value : Int, min_ : Int, max_ : Int) -> Int {
  if value < min_ {
    min_
  } else if value > max_ {
    max_
  } else {
    value
  }
}

///|
fn rects_overlap(a : Rect, b : Rect) -> Bool {
  a.x < b.x + b.w && a.x + a.w > b.x && a.y < b.y + b.h && a.y + a.h > b.y
}

///|
fn rect_from_fighter(fighter : FighterState) -> Rect {
  let height = fighter_height(fighter)
  {
    x: fighter.x - HURTBOX_WIDTH * 0.5,
    y: fighter.y,
    w: HURTBOX_WIDTH,
    h: height,
  }
}

///|
fn fighter_height(fighter : FighterState) -> Double {
  if fighter.crouching && fighter.on_ground && fighter.attack_kind is None {
    CROUCH_HEIGHT
  } else {
    HURTBOX_HEIGHT
  }
}

///|
fn fighter_center(fighter : FighterState) -> @math.Vec2 {
  let height = fighter_height(fighter)
  @math.Vec2(fighter.x, fighter.y + height * 0.5)
}

///|
fn facing_sign(facing : Facing) -> Double {
  match facing {
    Left => -1.0
    Right => 1.0
  }
}

///|
fn attack_spec(kind : AttackKind) -> AttackSpec {
  match kind {
    Light =>
      {
        startup: LIGHT_STARTUP,
        active: LIGHT_ACTIVE,
        recovery: LIGHT_RECOVERY,
        damage: LIGHT_DAMAGE,
        range: LIGHT_RANGE,
        height: LIGHT_HEIGHT,
        knockback: KNOCKBACK_LIGHT,
        cooldown: LIGHT_COOLDOWN,
      }
    Heavy =>
      {
        startup: HEAVY_STARTUP,
        active: HEAVY_ACTIVE,
        recovery: HEAVY_RECOVERY,
        damage: HEAVY_DAMAGE,
        range: HEAVY_RANGE,
        height: HEAVY_HEIGHT,
        knockback: KNOCKBACK_HEAVY,
        cooldown: HEAVY_COOLDOWN,
      }
  }
}

///|
fn attack_total_time(kind : AttackKind) -> Double {
  let spec = attack_spec(kind)
  spec.startup + spec.active + spec.recovery
}

///|
fn attack_active(kind : AttackKind, elapsed : Double) -> Bool {
  let spec = attack_spec(kind)
  elapsed >= spec.startup && elapsed <= spec.startup + spec.active
}

///|
fn attack_box(fighter : FighterState, kind : AttackKind) -> Rect {
  let spec = attack_spec(kind)
  let body = rect_from_fighter(fighter)
  let attack_y = if fighter.crouching && fighter.on_ground {
    fighter.y + fighter_height(fighter) * 0.42 - spec.height * 0.5
  } else {
    fighter.y + fighter_height(fighter) * 0.30 - spec.height * 0.5
  }
  match fighter.facing {
    Right =>
      { x: body.x + body.w - 4.0, y: attack_y, w: spec.range, h: spec.height }
    Left =>
      {
        x: body.x - spec.range + 4.0,
        y: attack_y,
        w: spec.range,
        h: spec.height,
      }
  }
}

///|
fn surface_y_under_fighter(fighter : FighterState) -> Double? {
  let body = rect_from_fighter(fighter)
  let feet = body.y + body.h
  let mut best : Double? = None
  for obj in stage_objects {
    if body.x + body.w <= obj.rect.x || body.x >= obj.rect.x + obj.rect.w {
      continue
    }
    if feet >= obj.rect.y - 2.0 && feet <= obj.rect.y + 3.0 {
      match best {
        Some(current) => if obj.rect.y < current { best = Some(obj.rect.y) }
        None => best = Some(obj.rect.y)
      }
    }
  }
  best
}

///|
fn resolve_x_against_stage(
  fighter : FighterState,
  next_x : Double,
  height : Double,
) -> Double {
  let mut resolved = clamp_double_game(
    next_x,
    STAGE_LEFT + HURTBOX_WIDTH * 0.5,
    STAGE_RIGHT - HURTBOX_WIDTH * 0.5,
  )
  let mut body = {
    x: resolved - HURTBOX_WIDTH * 0.5,
    y: fighter.y,
    w: HURTBOX_WIDTH,
    h: height,
  }
  for obj in stage_objects {
    if !rects_overlap(body, obj.rect) {
      continue
    }
    if next_x > fighter.x {
      resolved = clamp_double_game(
        obj.rect.x - HURTBOX_WIDTH * 0.5,
        STAGE_LEFT + HURTBOX_WIDTH * 0.5,
        STAGE_RIGHT - HURTBOX_WIDTH * 0.5,
      )
    } else if next_x < fighter.x {
      resolved = clamp_double_game(
        obj.rect.x + obj.rect.w + HURTBOX_WIDTH * 0.5,
        STAGE_LEFT + HURTBOX_WIDTH * 0.5,
        STAGE_RIGHT - HURTBOX_WIDTH * 0.5,
      )
    }
    body = {
      x: resolved - HURTBOX_WIDTH * 0.5,
      y: fighter.y,
      w: HURTBOX_WIDTH,
      h: height,
    }
  }
  resolved
}

///|
fn resolve_y_against_stage(
  fighter : FighterState,
  next_y : Double,
  height : Double,
) -> (Double, Bool, Double?) {
  let mut resolved = next_y
  let mut grounded = false
  let mut support_y : Double? = None
  let mut body = {
    x: fighter.x - HURTBOX_WIDTH * 0.5,
    y: resolved,
    w: HURTBOX_WIDTH,
    h: height,
  }
  for obj in stage_objects {
    if !rects_overlap(body, obj.rect) {
      continue
    }
    if next_y > fighter.y {
      let candidate = obj.rect.y - height
      if candidate < resolved {
        resolved = candidate
        grounded = true
        support_y = Some(obj.rect.y)
      }
    } else if next_y < fighter.y {
      let candidate = obj.rect.y + obj.rect.h
      if candidate > resolved {
        resolved = candidate
      }
    }
    body = {
      x: fighter.x - HURTBOX_WIDTH * 0.5,
      y: resolved,
      w: HURTBOX_WIDTH,
      h: height,
    }
  }
  if grounded {
    (resolved, true, support_y)
  } else {
    (resolved, false, None)
  }
}

///|
fn start_attack(fighter : FighterState, kind : AttackKind) -> Unit {
  fighter.attack_kind = Some(kind)
  fighter.attack_elapsed = 0.0
  fighter.attack_hit = false
  fighter.attack_cooldown = attack_spec(kind).cooldown
  fighter.pose = Attack
  play_punch_sound()
}

///|
fn trigger_backstep(fighter : FighterState) -> Unit {
  if fighter.backstep_timer > 0.0 {
    return
  }
  fighter.backstep_timer = 0.18
  fighter.invuln = 0.12
}

///|
fn apply_damage(
  target : FighterState,
  attacker : FighterState,
  kind : AttackKind,
) -> Unit {
  if !target.alive || target.invuln > 0.0 {
    return
  }
  let spec = attack_spec(kind)
  target.health = clamp_int(target.health - spec.damage, 0, MAX_HEALTH)
  target.hitstun = HITSTUN_SECONDS
  target.invuln = 0.22
  target.attack_kind = None
  target.attack_elapsed = 0.0
  target.attack_hit = false
  target.backstep_timer = 0.0
  target.vx = spec.knockback * facing_sign(attacker.facing)
  target.vy = -120.0
  target.pose = Hit
  play_hit_sound()
  if target.health <= 0 {
    target.alive = false
    target.pose = KO
    target.vx = 0.0
    target.vy = 0.0
    play_ko_sound()
  }
}

///|
fn resolve_attack_hit(attacker : FighterState, defender : FighterState) -> Unit {
  match attacker.attack_kind {
    Some(kind) => {
      if attacker.attack_hit || !attacker.alive || !defender.alive {
        return
      }
      if !attack_active(kind, attacker.attack_elapsed) {
        return
      }
      let box = attack_box(attacker, kind)
      if rects_overlap(box, rect_from_fighter(defender)) {
        attacker.attack_hit = true
        apply_damage(defender, attacker, kind)
      }
    }
    None => ()
  }
}

///|
fn human_input_p1() -> CombatInput {
  let move_x = if @inputs.is_pressed(KeyA) || @inputs.is_pressed(ArrowLeft) {
    -1.0
  } else if @inputs.is_pressed(KeyD) || @inputs.is_pressed(ArrowRight) {
    1.0
  } else {
    0.0
  }
  {
    move_x,
    jump: @inputs.is_just_pressed(KeyW) || @inputs.is_just_pressed(ArrowUp),
    crouch: @inputs.is_pressed(KeyS) || @inputs.is_pressed(ArrowDown),
    light: @inputs.is_just_pressed(KeyJ),
    heavy: @inputs.is_just_pressed(KeyK),
    backstep: @inputs.is_just_pressed(KeyL),
  }
}

///|
fn human_input_p2() -> CombatInput {
  let move_x = if @inputs.is_pressed(KeyF) {
    -1.0
  } else if @inputs.is_pressed(KeyH) {
    1.0
  } else {
    0.0
  }
  {
    move_x,
    jump: @inputs.is_just_pressed(KeyT),
    crouch: @inputs.is_pressed(KeyG),
    light: @inputs.is_just_pressed(KeyY),
    heavy: @inputs.is_just_pressed(KeyU),
    backstep: @inputs.is_just_pressed(KeyI),
  }
}

///|
fn ai_input_for(fighter : FighterState, opponent : FighterState) -> CombatInput {
  let dx = opponent.x - fighter.x
  let distance = abs_double(dx)
  let mut move_x = 0.0
  let mut crouch = false
  let mut backstep = false
  let mut light = false
  let mut heavy = false
  let jump = fighter.on_ground &&
    distance > 170.0 &&
    rng.double() < AI_JUMP_CHANCE
  if distance > AI_PRESSURE_DISTANCE {
    move_x = if dx > 0.0 { 1.0 } else { -1.0 }
  } else if distance < AI_BACKSTEP_DISTANCE {
    backstep = true
  } else if fighter.on_ground && rng.double() < 0.2 {
    crouch = true
  }
  if distance < AI_ATTACK_DISTANCE &&
    fighter.attack_cooldown <= 0.0 &&
    fighter.hitstun <= 0.0 {
    if rng.double() < 0.66 {
      light = true
    } else {
      heavy = true
    }
  }
  { move_x, jump, crouch, light, heavy, backstep }
}

///|
fn command_for_fighter(
  fighter : FighterState,
  opponent : FighterState,
) -> CombatInput {
  match fighter.id {
    P1 => human_input_p1()
    P2 =>
      if game_state.p2_human_enabled {
        human_input_p2()
      } else {
        ai_input_for(fighter, opponent)
      }
  }
}

///|
fn command_requested_attack(cmd : CombatInput) -> AttackKind? {
  if cmd.heavy {
    Some(Heavy)
  } else if cmd.light {
    Some(Light)
  } else {
    None
  }
}

///|
fn update_fighter_motion(
  fighter : FighterState,
  cmd : CombatInput,
  delta : Double,
) -> Unit {
  if !fighter.alive {
    fighter.vx = 0.0
    fighter.vy = 0.0
    fighter.pose = KO
    return
  }

  fighter.attack_cooldown = clamp_double_game(
    fighter.attack_cooldown - delta,
    0.0,
    999.0,
  )
  fighter.invuln = clamp_double_game(fighter.invuln - delta, 0.0, 999.0)
  fighter.hitstun = clamp_double_game(fighter.hitstun - delta, 0.0, 999.0)

  if fighter.backstep_timer > 0.0 {
    fighter.backstep_timer = clamp_double_game(
      fighter.backstep_timer - delta,
      0.0,
      999.0,
    )
    fighter.vx = -facing_sign(fighter.facing) * BACKSTEP_SPEED
  }

  if fighter.hitstun > 0.0 {
    fighter.crouching = false
  } else if fighter.on_ground {
    fighter.crouching = cmd.crouch
  } else {
    fighter.crouching = false
  }

  if fighter.attack_kind is None &&
    fighter.hitstun <= 0.0 &&
    fighter.backstep_timer <= 0.0 {
    if cmd.backstep {
      trigger_backstep(fighter)
    }
    match command_requested_attack(cmd) {
      Some(kind) =>
        if fighter.attack_cooldown <= 0.0 {
          start_attack(fighter, kind)
        }
      None => ()
    }
  }

  if fighter.attack_kind is None &&
    fighter.hitstun <= 0.0 &&
    fighter.backstep_timer <= 0.0 {
    let speed = if fighter.crouching { CROUCH_SPEED } else { MOVE_SPEED }
    fighter.vx = cmd.move_x * speed
    if cmd.jump && fighter.on_ground {
      fighter.vy = -JUMP_VELOCITY
      fighter.on_ground = false
      fighter.pose = Jump
    }
  }

  if fighter.attack_kind is Some(_) && fighter.backstep_timer <= 0.0 {
    fighter.vx = cmd.move_x * MOVE_SPEED * 0.35
  }

  if fighter.on_ground &&
    fighter.vy == 0.0 &&
    fighter.attack_kind is None &&
    fighter.backstep_timer <= 0.0 {
    match surface_y_under_fighter(fighter) {
      Some(surface_y) => fighter.y = surface_y - fighter_height(fighter)
      None => fighter.on_ground = false
    }
  }

  fighter.vy = clamp_double_game(
    fighter.vy + GRAVITY * delta,
    -MAX_FALL_SPEED,
    MAX_FALL_SPEED,
  )

  let next_x = resolve_x_against_stage(
    fighter,
    fighter.x + fighter.vx * delta,
    fighter_height(fighter),
  )
  fighter.x = next_x

  let height_before_y = fighter_height(fighter)
  let (next_y, grounded, _) = resolve_y_against_stage(
    fighter,
    fighter.y + fighter.vy * delta,
    height_before_y,
  )
  fighter.y = next_y
  if grounded {
    fighter.on_ground = true
    fighter.vy = 0.0
  } else if fighter.y + height_before_y < FALL_KILL_Y {
    fighter.on_ground = false
  }

  if fighter.attack_kind is Some(kind) {
    fighter.attack_elapsed += delta
    if fighter.attack_elapsed >= attack_total_time(kind) {
      fighter.attack_kind = None
      fighter.attack_elapsed = 0.0
      fighter.attack_hit = false
    }
  }

  if fighter.attack_kind is None {
    if fighter.hitstun > 0.0 {
      fighter.pose = Hit
    } else if fighter.backstep_timer > 0.0 {
      fighter.pose = Run
    } else if !fighter.on_ground {
      fighter.pose = Jump
    } else if fighter.crouching {
      fighter.pose = Crouch
    } else if abs_double(fighter.vx) > 3.0 {
      fighter.pose = Run
    } else {
      fighter.pose = Idle
    }
  }

  if fighter.x < STAGE_LEFT + HURTBOX_WIDTH * 0.5 {
    fighter.x = STAGE_LEFT + HURTBOX_WIDTH * 0.5
  }
  if fighter.x > STAGE_RIGHT - HURTBOX_WIDTH * 0.5 {
    fighter.x = STAGE_RIGHT - HURTBOX_WIDTH * 0.5
  }
}

///|
fn update_attack_resolution() -> Unit {
  if p1.alive && p2.alive {
    resolve_attack_hit(p1, p2)
    resolve_attack_hit(p2, p1)
  }
}

///|
fn resolve_fighter_overlap() -> Unit {
  if !p1.alive || !p2.alive {
    return
  }
  let a = rect_from_fighter(p1)
  let b = rect_from_fighter(p2)
  if !rects_overlap(a, b) {
    return
  }
  let a_center = p1.x
  let b_center = p2.x
  let overlap = a.x + a.w - b.x
  if a_center < b_center {
    p1.x -= overlap * 0.5
    p2.x += overlap * 0.5
  } else {
    p1.x += overlap * 0.5
    p2.x -= overlap * 0.5
  }
  p1.x = clamp_double_game(
    p1.x,
    STAGE_LEFT + HURTBOX_WIDTH * 0.5,
    STAGE_RIGHT - HURTBOX_WIDTH * 0.5,
  )
  p2.x = clamp_double_game(
    p2.x,
    STAGE_LEFT + HURTBOX_WIDTH * 0.5,
    STAGE_RIGHT - HURTBOX_WIDTH * 0.5,
  )
}

///|
fn resolve_round_state() -> Unit {
  if game_state.phase != Playing {
    return
  }
  if p1.alive && p2.alive {
    if game_state.round_time <= 0.0 {
      if p1.health > p2.health {
        enter_round_over(P1Win)
      } else if p2.health > p1.health {
        enter_round_over(P2Win)
      } else {
        enter_round_over(Draw)
      }
    }
    return
  }
  if !p1.alive && !p2.alive {
    enter_round_over(Draw)
  } else if !p1.alive {
    enter_round_over(P2Win)
  } else if !p2.alive {
    enter_round_over(P1Win)
  }
}

///|
fn round_banner_text() -> String {
  match game_state.round_outcome {
    Some(P1Win) => "P1 WINS"
    Some(P2Win) => "P2 WINS"
    Some(Draw) => "DRAW"
    None => ""
  }
}

///|
fn round_status_text() -> String {
  let mode = if game_state.p2_human_enabled { "HUMAN" } else { "AI" }
  "MODE: P1 VS \{mode}  F2 P2  F3 FPS"
}

///|
fn menu_status_text() -> String {
  let p2 = if game_state.p2_human_enabled { "HUMAN" } else { "AI" }
  "ENTER START  F2 P2(\{p2})  F3 FPS  ESC EXIT"
}

///|
fn time_text() -> String {
  let seconds = @cmath.floor(game_state.round_time).to_int()
  let minutes = seconds / 60
  let rest = seconds % 60
  let rest_text = if rest < 10 { "0\{rest}" } else { rest.to_string() }
  "\{minutes}:\{rest_text}"
}

///|
pub fn input_system(_world : @ecs.World) -> Unit {
  if @host.is_key_pressed("F3") {
    game_state.debug_fps = !game_state.debug_fps
    fps_text_enabled.val = game_state.debug_fps
  }
  if @host.is_key_pressed("F2") {
    game_state.p2_human_enabled = !game_state.p2_human_enabled
    p2.input_mode = if game_state.p2_human_enabled { Human } else { AI }
  }

  if @inputs.is_just_pressed(Escape) {
    match game_state.phase {
      MainMenu => @system.exit()
      Playing => enter_menu()
      RoundOver => enter_menu()
    }
    return
  }

  match game_state.phase {
    MainMenu =>
      if @inputs.is_just_pressed(Enter) || @inputs.is_just_pressed(Space) {
        reset_round()
      }
    Playing => if @inputs.is_just_pressed(KeyR) { reset_round() }
    RoundOver =>
      if @inputs.is_just_pressed(Enter) ||
        @inputs.is_just_pressed(Space) ||
        @inputs.is_just_pressed(KeyR) {
        reset_round()
      }
  }
}

///|
fn update_round_timer(delta : Double) -> Unit {
  if game_state.phase != Playing {
    return
  }
  game_state.round_time = clamp_double_game(
    game_state.round_time - delta,
    0.0,
    ROUND_TIME_SECONDS,
  )
}

///|
fn update_attack_timers_and_hits() -> Unit {
  update_attack_resolution()
}

///|
pub fn gameplay_system(_world : @ecs.World) -> Unit {
  let delta = @time.delta()
  match game_state.phase {
    Playing => {
      update_round_timer(delta)
      let p1_cmd = command_for_fighter(p1, p2)
      let p2_cmd = command_for_fighter(p2, p1)
      update_fighter_motion(p1, p1_cmd, delta)
      update_fighter_motion(p2, p2_cmd, delta)
      resolve_fighter_overlap()
      update_attack_timers_and_hits()
      resolve_round_state()
    }
    RoundOver => game_state.round_banner_timer += delta
    MainMenu => ()
  }
  maybe_report_profile()
}

///|
fn fighter_visual_size(fighter : FighterState) -> @math.Vec2 {
  @math.Vec2(HURTBOX_WIDTH, fighter_height(fighter))
}

///|
fn fighter_visual_color(fighter : FighterState) -> @render.Color {
  match fighter.id {
    P1 =>
      if fighter.alive {
        color_rgba(244U, 86U, 86U, 1.0)
      } else {
        color_rgba(120U, 40U, 40U, 1.0)
      }
    P2 =>
      if fighter.alive {
        color_rgba(80U, 160U, 255U, 1.0)
      } else {
        color_rgba(44U, 80U, 132U, 1.0)
      }
  }
}

///|
fn attack_visual_rect(fighter : FighterState) -> (Bool, @math.Vec2, @math.Vec2) {
  match fighter.attack_kind {
    Some(kind) => {
      if !attack_active(kind, fighter.attack_elapsed) {
        return (false, @math.Vec2(0.0, 0.0), @math.Vec2(0.0, 0.0))
      }
      let box = attack_box(fighter, kind)
      (
        true,
        @math.Vec2(box.x + box.w * 0.5, box.y + box.h * 0.5),
        @math.Vec2(box.w, box.h),
      )
    }
    None => (false, @math.Vec2(0.0, 0.0), @math.Vec2(0.0, 0.0))
  }
}

///|
fn sync_bar(
  entity : @entity.Entity,
  center_x : Double,
  width : Double,
  color : @render.Color,
) -> Unit {
  set_rect_entity(
    entity,
    @math.Vec2(center_x, 62.0),
    @math.Vec2(width, 18.0),
    color,
    UI_ZINDEX + 11,
  )
}

///|
fn maybe_report_profile() -> Unit {
  if !profile_enabled.val {
    return
  }
  let now = @time.elapsed()
  if profile_frame_count.val == 0 {
    profile_started_at.val = now
    profile_last_report_at.val = now
  }
  profile_frame_count.val += 1
  let window_s = now - profile_last_report_at.val
  if window_s < PROFILE_REPORT_SECONDS {
    return
  }
  let frame_count = profile_frame_count.val.to_double()
  let sample_s = now - profile_started_at.val
  if sample_s < 0.5 {
    profile_frame_count.val = 0
    profile_last_report_at.val = now
    return
  }
  let fps_avg = if window_s <= 0.0001 { 0.0 } else { frame_count / window_s }
  let fps_window = fps_avg
  let fps_frame_dt = if window_s <= 0.0001 {
    0.0
  } else {
    frame_count / window_s
  }
  let fps = fps_avg.to_int()
  let avg_ms = if frame_count > 0.0 {
    window_s * 1000.0 / frame_count
  } else {
    0.0
  }
  let stage_preview = if stage_objects.length() > 0 {
    "\{stage_objects[0]}"
  } else {
    "none"
  }
  println(
    "[kofarena][profile] fps_avg=\{fps_avg} fps_window=\{fps_window} fps_frame_dt=\{fps_frame_dt} fps=\{fps} avg_ms=\{avg_ms} window_s=\{window_s} sample_s=\{sample_s} phase=\{game_state.phase} p1_hp=\{p1.health} p2_hp=\{p2.health} round=\{time_text()} outcome=\{round_status_text()} p1=\{p1} gs=\{game_state} stage0=\{stage_preview}",
  )
  profile_frame_count.val = 0
  profile_delta_accum.val = 0.0
  profile_last_report_at.val = now
}

///|
pub fn render_sync_system(_world : @ecs.World) -> Unit {
  show_menu_entities(game_state.phase == MainMenu)
  show_play_entities(game_state.phase != MainMenu)
  let fps_text = if @time.frame_delta() <= 0.0 {
    "0"
  } else {
    (1.0 / @time.frame_delta()).to_int().to_string()
  }
  let p2_state_text = if game_state.p2_human_enabled { "HUMAN" } else { "AI" }
  let debug_state_text = if game_state.debug_fps { "ON" } else { "OFF" }

  set_text_entity(
    title_entity,
    "KOF ARENA",
    @math.Vec2(VIEWPORT_WIDTH * 0.5, 68.0),
    "rgb(255,248,238)",
    font="52px \{KOF_FONT_FAMILY}",
    zindex=UI_ZINDEX + 20,
  )
  set_text_entity(
    menu_entity,
    if game_state.phase == MainMenu {
      menu_status_text()
    } else if game_state.phase == RoundOver {
      "ENTER/R: RESTART  ESC: MENU  " + round_status_text()
    } else {
      round_status_text()
    },
    @math.Vec2(VIEWPORT_WIDTH * 0.5, 126.0),
    "rgb(222,231,242)",
    font="16px \{KOF_FONT_FAMILY}",
    zindex=UI_ZINDEX + 20,
  )
  set_text_entity(
    info_entity,
    if game_state.phase == MainMenu {
      "P1 A/D MOVE  W JUMP  S CROUCH  J LIGHT  K HEAVY  L STEP"
    } else if game_state.phase == Playing {
      "A/D MOVE  W JUMP  S CROUCH  J LIGHT  K HEAVY  L STEP"
    } else {
      "PRESS ENTER OR R TO FIGHT AGAIN"
    },
    @math.Vec2(VIEWPORT_WIDTH * 0.5, 154.0),
    "rgb(198,210,225)",
    font="14px \{KOF_FONT_FAMILY}",
    zindex=UI_ZINDEX + 20,
  )
  set_text_entity(
    timer_entity,
    if game_state.phase == Playing || game_state.phase == RoundOver {
      "TIME " + time_text()
    } else {
      "READY"
    },
    @math.Vec2(VIEWPORT_WIDTH * 0.5, 30.0),
    "rgb(255,248,238)",
    font="32px \{KOF_FONT_FAMILY}",
    zindex=UI_ZINDEX + 20,
  )
  set_text_entity(
    debug_entity,
    if game_state.debug_fps {
      "FPS \{fps_text}  P2 " + p2_state_text + "  DEBUG " + debug_state_text
    } else {
      ""
    },
    @math.Vec2(26.0, 26.0),
    "rgb(210,220,230)",
    font="20px \{KOF_FONT_FAMILY}",
    zindex=UI_ZINDEX + 20,
  )
  set_text_entity(
    banner_entity,
    if game_state.phase == RoundOver {
      round_banner_text()
    } else {
      ""
    },
    @math.Vec2(VIEWPORT_WIDTH * 0.5, 240.0),
    "rgb(255,244,210)",
    font="50px \{KOF_FONT_FAMILY}",
    zindex=UI_ZINDEX + 20,
  )

  let p1_ratio = clamp_double_game(
    p1.health.to_double() / MAX_HEALTH.to_double(),
    0.0,
    1.0,
  )
  let p2_ratio = clamp_double_game(
    p2.health.to_double() / MAX_HEALTH.to_double(),
    0.0,
    1.0,
  )
  sync_bar(
    p1_bar_fill,
    46.0 + 352.0 * 0.5 * p1_ratio,
    352.0 * p1_ratio,
    color_rgba(232U, 70U, 76U, 1.0),
  )
  sync_bar(
    p2_bar_fill,
    VIEWPORT_WIDTH - 398.0 + 352.0 * 0.5 * p2_ratio,
    352.0 * p2_ratio,
    color_rgba(66U, 152U, 244U, 1.0),
  )
  set_rect_entity(
    left_fighter_entity,
    fighter_center(p1),
    fighter_visual_size(p1),
    fighter_visual_color(p1),
    40,
  )
  set_rect_entity(
    right_fighter_entity,
    fighter_center(p2),
    fighter_visual_size(p2),
    fighter_visual_color(p2),
    40,
  )

  let (p1_attack_visible, p1_attack_center, p1_attack_size) = attack_visual_rect(
    p1,
  )
  let (p2_attack_visible, p2_attack_center, p2_attack_size) = attack_visual_rect(
    p2,
  )
  if p1_attack_visible {
    set_rect_entity(
      left_attack_entity,
      p1_attack_center,
      p1_attack_size,
      color_rgba(255U, 198U, 72U, 0.35),
      41,
    )
  } else {
    set_entity_visibility(left_attack_entity, false)
  }
  if p2_attack_visible {
    set_rect_entity(
      right_attack_entity,
      p2_attack_center,
      p2_attack_size,
      color_rgba(255U, 198U, 72U, 0.35),
      41,
    )
  } else {
    set_entity_visibility(right_attack_entity, false)
  }

  if p1.crouching && p1.on_ground {
    set_rect_entity(
      left_crouch_entity,
      fighter_center(p1),
      fighter_visual_size(p1),
      color_rgba(255U, 255U, 255U, 0.10),
      39,
    )
  } else {
    set_entity_visibility(left_crouch_entity, false)
  }
  if p2.crouching && p2.on_ground {
    set_rect_entity(
      right_crouch_entity,
      fighter_center(p2),
      fighter_visual_size(p2),
      color_rgba(255U, 255U, 255U, 0.10),
      39,
    )
  } else {
    set_entity_visibility(right_crouch_entity, false)
  }
}

///|
pub fn capture_after_render_system(_world : @ecs.World) -> Unit {
  if !capture_enabled.val || capture_taken.val {
    return
  }
  if @time.elapsed() - capture_started_at.val < CAPTURE_DELAY_SECONDS {
    return
  }
  @host.take_screenshot(CAPTURE_PATH)
  println("[kofarena][capture] path=\{CAPTURE_PATH}")
  capture_taken.val = true
  @system.exit()
}
