///|
pub fn startup_system(_world : @ecs.World) -> Unit {
  if !ui_initialized.val {
    install_embedded_assets()
    preload_assets()
    initialize_scene()
    initialize_ui()
    ui_initialized.val = true
  }
  enter_main_menu()
}

///|
let game_background_textures : Array[String] = [
  "thetawave/assets/texture/backgrounds/background_1.png", "thetawave/assets/texture/backgrounds/background_2.png",
  "thetawave/assets/texture/backgrounds/background_3.png",
]

///|
const GAME_BACKGROUND_LEVEL1_STAGE_END : Int = 7

///|
const GAME_BACKGROUND_LEVEL2_STAGE_END : Int = 14

///|
const BG3D_BACKGROUND_ALPHA : Double = 0.06

///|
const BG3D_QUAD_Z : Double = -300.0

///|
const BG3D_QUAD_SCALE_X : Double = 1.5

///|
const BG3D_QUAD_SCALE_Y : Double = 1.5

///|
const BG3D_QUAD_WIDTH : Double = 375.0

///|
const BG3D_QUAD_HEIGHT : Double = 375.0

///|
const BG3D_PLANET_RADIUS : Double = 10.0

///|
const BG3D_STAR_RADIUS : Double = 10.0

///|
const BG3D_PLANET_X : Double = 8.0

///|
const BG3D_PLANET_Y : Double = -8.0

///|
const BG3D_PLANET_Z : Double = 30.0

///|
const BG3D_STAR_X_MIN : Double = -90.0

///|
const BG3D_STAR_X_MAX : Double = -30.0

///|
const BG3D_STAR_Z_MIN : Double = -250.0

///|
const BG3D_STAR_Z_MAX : Double = -150.0

///|
const BG3D_ROTATE_SPEED_MIN : Double = 0.01

///|
const BG3D_ROTATE_SPEED_MAX : Double = 0.05

///|
const BG3D_STAR_LIGHT_INTENSITY : Double = 100000000.0

///|
const BG3D_STAR_LIGHT_RANGE : Double = 10000.0

///|
const BG3D_ENABLE_FALLBACK_BODIES : Bool = false

///|
let background3d_initialized : Ref[Bool] = { val: false }

///|
let background3d_active : Ref[Bool] = { val: false }

///|
let background3d_camera_entity : @entity.Entity = @entity.Entity::new()

///|
let background3d_quad_entity : @entity.Entity = @entity.Entity::new()

///|
let background3d_planet_entity : @entity.Entity = @entity.Entity::new()

///|
let background3d_star_entity : @entity.Entity = @entity.Entity::new()

///|
let background3d_star_light_entity : @entity.Entity = @entity.Entity::new()

///|
let background3d_quad_mesh : Ref[@render3d.MeshHandle?] = { val: None }

///|
let background3d_planet_mesh : Ref[@render3d.MeshHandle?] = { val: None }

///|
let background3d_star_mesh : Ref[@render3d.MeshHandle?] = { val: None }

///|
let background3d_quad_image : Ref[@render3d.ImageHandle?] = { val: None }

///|
let background3d_quad_material : Ref[@render3d.MaterialHandle?] = { val: None }

///|
let background3d_planet_material : Ref[@render3d.MaterialHandle?] = {
  val: None,
}

///|
let background3d_star_material : Ref[@render3d.MaterialHandle?] = { val: None }

///|
let background3d_planet_rotation_speed : Ref[Double] = {
  val: BG3D_ROTATE_SPEED_MIN,
}

///|
let character_left_portrait_ui : @entity.Entity = @entity.Entity::new()

///|
let character_right_portrait_ui : @entity.Entity = @entity.Entity::new()

///|
let character_name_ui : @entity.Entity = @entity.Entity::new()

///|
let character_ability_slot1_ui : @entity.Entity = @entity.Entity::new()

///|
let character_ability_slot1_icon_ui : @entity.Entity = @entity.Entity::new()

///|
let character_ability_slot1_text_ui : @entity.Entity = @entity.Entity::new()

///|
let character_ability_slot2_ui : @entity.Entity = @entity.Entity::new()

///|
let character_ability_slot2_icon_ui : @entity.Entity = @entity.Entity::new()

///|
let character_ability_slot2_text_ui : @entity.Entity = @entity.Entity::new()

///|
let character_join_prompt_ui : @entity.Entity = @entity.Entity::new()

///|
let character_ready_text_ui : @entity.Entity = @entity.Entity::new()

///|
let character_stats_order : Array[CharacterStatType] = [
  Damage,
  Health,
  Range,
  FireRate,
  Size,
  Speed,
]

///|
let character_stat_icon_uis : Array[@entity.Entity] = [
  @entity.Entity::new(),
  @entity.Entity::new(),
  @entity.Entity::new(),
  @entity.Entity::new(),
  @entity.Entity::new(),
  @entity.Entity::new(),
]

///|
let character_stat_bg_uis : Array[@entity.Entity] = [
  @entity.Entity::new(),
  @entity.Entity::new(),
  @entity.Entity::new(),
  @entity.Entity::new(),
  @entity.Entity::new(),
  @entity.Entity::new(),
]

///|
let character_stat_fill_uis : Array[@entity.Entity] = [
  @entity.Entity::new(),
  @entity.Entity::new(),
  @entity.Entity::new(),
  @entity.Entity::new(),
  @entity.Entity::new(),
  @entity.Entity::new(),
]

///|
let character_p2_center_portrait_ui : @entity.Entity = @entity.Entity::new()

///|
let character_p2_left_portrait_ui : @entity.Entity = @entity.Entity::new()

///|
let character_p2_right_portrait_ui : @entity.Entity = @entity.Entity::new()

///|
let character_p2_name_ui : @entity.Entity = @entity.Entity::new()

///|
let character_p2_ability_slot1_ui : @entity.Entity = @entity.Entity::new()

///|
let character_p2_ability_slot1_icon_ui : @entity.Entity = @entity.Entity::new()

///|
let character_p2_ability_slot1_text_ui : @entity.Entity = @entity.Entity::new()

///|
let character_p2_ability_slot2_ui : @entity.Entity = @entity.Entity::new()

///|
let character_p2_ability_slot2_icon_ui : @entity.Entity = @entity.Entity::new()

///|
let character_p2_ability_slot2_text_ui : @entity.Entity = @entity.Entity::new()

///|
let character_p2_join_prompt_ui : @entity.Entity = @entity.Entity::new()

///|
let character_p2_ready_text_ui : @entity.Entity = @entity.Entity::new()

///|
let character_p2_stat_icon_uis : Array[@entity.Entity] = [
  @entity.Entity::new(),
  @entity.Entity::new(),
  @entity.Entity::new(),
  @entity.Entity::new(),
  @entity.Entity::new(),
  @entity.Entity::new(),
]

///|
let character_p2_stat_bg_uis : Array[@entity.Entity] = [
  @entity.Entity::new(),
  @entity.Entity::new(),
  @entity.Entity::new(),
  @entity.Entity::new(),
  @entity.Entity::new(),
  @entity.Entity::new(),
]

///|
let character_p2_stat_fill_uis : Array[@entity.Entity] = [
  @entity.Entity::new(),
  @entity.Entity::new(),
  @entity.Entity::new(),
  @entity.Entity::new(),
  @entity.Entity::new(),
  @entity.Entity::new(),
]

///|
const TUTORIAL_PHASE_DATA_LINE_COUNT : Int = 8

///|
let tutorial_phase_data_line_uis : Array[@entity.Entity] = [
  @entity.Entity::new(),
  @entity.Entity::new(),
  @entity.Entity::new(),
  @entity.Entity::new(),
  @entity.Entity::new(),
  @entity.Entity::new(),
  @entity.Entity::new(),
  @entity.Entity::new(),
]

///|
fn ensure_entity_alive(entity : @entity.Entity) -> Unit {
  if !entity.is_alive() {
    entity.respawn()
  }
}

///|
fn color_u8(r : UInt, g : UInt, b : UInt, a : Double) -> @render.Color {
  @render.Color::{ r, g, b, a }
}

///|
fn random_range(min : Double, max : Double) -> Double {
  min + (max - min) * game_state.rand.double()
}

///|
fn random_channel(min : Int, max : Int) -> UInt {
  let span = @cmp.maximum(1, max - min + 1)
  let raw = min + (game_state.rand.double() * span.to_double()).to_int()
  clamp_int(raw, min, max).reinterpret_as_uint()
}

///|
fn uses_3d_background(kind : BackgroundKind) -> Bool {
  ignore(kind)
  false
}

///|
fn set_background_sprite_visible(visible : Bool) -> Unit {
  if @sprite.sprites().get(game_state.background) is Some(sprite) {
    sprite.visible = visible
  }
}

///|
fn set_mesh3d_visible(entity : @entity.Entity, visible : Bool) -> Unit {
  if @render3d.mesh3d_renderers().get(entity) is Some(renderer) {
    renderer.visible = visible
  }
}

///|
fn set_background3d_active(active : Bool) -> Unit {
  background3d_active.val = active
  if !background3d_initialized.val {
    return
  }
  if @camera3d.cameras3d().get(background3d_camera_entity) is Some(camera) {
    camera.enabled = active
  }
  set_mesh3d_visible(background3d_quad_entity, active)
  if BG3D_ENABLE_FALLBACK_BODIES {
    set_mesh3d_visible(background3d_planet_entity, active)
    set_mesh3d_visible(background3d_star_entity, active)
  } else {
    // Some backends ignore `visible` for 3D meshes; remove fallback bodies entirely.
    @render3d.mesh3d_renderers().remove(background3d_planet_entity)
    @render3d.mesh3d_renderers().remove(background3d_star_entity)
  }
  if !active || !BG3D_ENABLE_FALLBACK_BODIES {
    @render3d.point_lights3d().remove(background3d_star_light_entity)
  }
  if active {
    let ambient_intensity = if BG3D_ENABLE_FALLBACK_BODIES { 0.35 } else { 1.0 }
    @render3d.set_ambient_light3d(
      Some({
        color: color_u8(255U, 255U, 255U, 1.0),
        intensity: ambient_intensity,
      }),
    )
  } else {
    @render3d.set_ambient_light3d(None)
  }
}

///|
fn background3d_quad_mesh_asset() -> @render3d.MeshAsset {
  let half_w = BG3D_QUAD_WIDTH / 2.0
  let half_h = BG3D_QUAD_HEIGHT / 2.0
  let positions = [
    @math.Vec3::new(-half_w, -half_h, 0.0),
    @math.Vec3::new(half_w, -half_h, 0.0),
    @math.Vec3::new(half_w, half_h, 0.0),
    @math.Vec3::new(-half_w, -half_h, 0.0),
    @math.Vec3::new(half_w, half_h, 0.0),
    @math.Vec3::new(-half_w, half_h, 0.0),
  ]
  let uvs = [
    @math.Vec2D(0.0, 1.0),
    @math.Vec2D(1.0, 1.0),
    @math.Vec2D(1.0, 0.0),
    @math.Vec2D(0.0, 1.0),
    @math.Vec2D(1.0, 0.0),
    @math.Vec2D(0.0, 0.0),
  ]
  @render3d.triangle_mesh(positions, uvs=Some(uvs))
}

///|
fn refresh_background3d_assets() -> Unit {
  guard background3d_quad_mesh.val is Some(quad_mesh) else { return }
  guard background3d_planet_mesh.val is Some(planet_mesh) else { return }
  guard background3d_star_mesh.val is Some(star_mesh) else { return }

  ensure_entity_alive(background3d_quad_entity)
  ensure_entity_alive(background3d_planet_entity)
  ensure_entity_alive(background3d_star_entity)
  ensure_entity_alive(background3d_star_light_entity)

  let old_quad_image = background3d_quad_image.val
  let old_quad_material = background3d_quad_material.val
  let old_planet_material = background3d_planet_material.val
  let old_star_material = background3d_star_material.val

  let quad_image = @render3d.register_image_asset({
    path: game_background_texture_for_stage(game_state.stage_index),
  })
  let quad_alpha = if BG3D_ENABLE_FALLBACK_BODIES {
    BG3D_BACKGROUND_ALPHA
  } else {
    1.0
  }
  let quad_material = @render3d.default_standard_material3d()
  let quad_material = {
    ..quad_material,
    base_color_texture: Some(@render3d.texture_binding3d(quad_image)),
    base_color: color_u8(255U, 255U, 255U, quad_alpha),
    alpha_mode: Blend,
  }
  let quad_material = @render3d.register_material_asset(quad_material)

  let star_color = color_u8(
    random_channel(220, 255),
    random_channel(220, 255),
    random_channel(180, 255),
    1.0,
  )
  let star_material = @render3d.default_standard_material3d()
  let star_material = { ..star_material, base_color: star_color }
  let star_material = @render3d.register_material_asset(star_material)

  let planet_material = @render3d.default_standard_material3d()
  let planet_material = {
    ..planet_material,
    base_color: color_u8(255U, 255U, 255U, 1.0),
  }
  let planet_material = @render3d.register_material_asset(planet_material)

  @render3d.mesh3d_renderers().set(background3d_quad_entity, {
    mesh: quad_mesh,
    material: quad_material,
    visible: background3d_active.val,
    cast_shadows: false,
    receive_shadows: false,
  })
  @transform3d.transforms3d().set(background3d_quad_entity, {
    translation: @math.Vec3::new(0.0, 0.0, BG3D_QUAD_Z),
    rotation: @math.Quat::identity(),
    scale: @math.Vec3::new(BG3D_QUAD_SCALE_X, BG3D_QUAD_SCALE_Y, 1.0),
  })

  if BG3D_ENABLE_FALLBACK_BODIES {
    @render3d.mesh3d_renderers().set(background3d_planet_entity, {
      mesh: planet_mesh,
      material: planet_material,
      visible: background3d_active.val,
      cast_shadows: false,
      receive_shadows: false,
    })
    @transform3d.transforms3d().set(background3d_planet_entity, {
      translation: @math.Vec3::new(BG3D_PLANET_X, BG3D_PLANET_Y, BG3D_PLANET_Z),
      rotation: @math.Quat::from_axis_angle(
        @math.Vec3::new(0.0, 1.0, 0.0),
        random_range(0.0, @cmath.PI * 2.0),
      ),
      scale: @math.Vec3::one(),
    })
  } else {
    @render3d.mesh3d_renderers().remove(background3d_planet_entity)
  }

  let star_x = random_range(BG3D_STAR_X_MIN, BG3D_STAR_X_MAX)
  let star_z = random_range(BG3D_STAR_Z_MIN, BG3D_STAR_Z_MAX)
  let star_translation = @math.Vec3::new(star_x, 0.0, star_z)
  if BG3D_ENABLE_FALLBACK_BODIES {
    @render3d.mesh3d_renderers().set(background3d_star_entity, {
      mesh: star_mesh,
      material: star_material,
      visible: background3d_active.val,
      cast_shadows: false,
      receive_shadows: false,
    })
    @transform3d.transforms3d().set(background3d_star_entity, {
      translation: star_translation,
      rotation: @math.Quat::identity(),
      scale: @math.Vec3::one(),
    })
  } else {
    @render3d.mesh3d_renderers().remove(background3d_star_entity)
  }
  if BG3D_ENABLE_FALLBACK_BODIES {
    @render3d.point_lights3d().set(background3d_star_light_entity, {
      ..@render3d.default_point_light3d(),
      color: star_color,
      intensity: BG3D_STAR_LIGHT_INTENSITY,
      range: BG3D_STAR_LIGHT_RANGE,
    })
  } else {
    @render3d.point_lights3d().remove(background3d_star_light_entity)
  }
  @transform3d.transforms3d().set(background3d_star_light_entity, {
    translation: star_translation,
    rotation: @math.Quat::identity(),
    scale: @math.Vec3::one(),
  })

  background3d_quad_image.val = Some(quad_image)
  background3d_quad_material.val = Some(quad_material)
  background3d_planet_material.val = Some(planet_material)
  background3d_star_material.val = Some(star_material)
  background3d_planet_rotation_speed.val = random_range(
    BG3D_ROTATE_SPEED_MIN,
    BG3D_ROTATE_SPEED_MAX,
  )

  if old_quad_material is Some(handle) {
    @render3d.release_material_asset(handle)
  }
  if old_quad_image is Some(handle) {
    @render3d.release_image_asset(handle)
  }
  if old_planet_material is Some(handle) {
    @render3d.release_material_asset(handle)
  }
  if old_star_material is Some(handle) {
    @render3d.release_material_asset(handle)
  }
}

///|
fn ensure_background3d_initialized() -> Unit {
  if background3d_initialized.val {
    return
  }

  ensure_entity_alive(background3d_camera_entity)
  ensure_entity_alive(background3d_quad_entity)
  ensure_entity_alive(background3d_planet_entity)
  ensure_entity_alive(background3d_star_entity)
  ensure_entity_alive(background3d_star_light_entity)

  @camera3d.cameras3d().set(
    background3d_camera_entity,
    @camera3d.Camera3DComponent::default(),
  )
  @transform3d.transforms3d().set(background3d_camera_entity, {
    translation: @math.Vec3::new(0.0, 0.0, 60.0),
    rotation: @math.Quat::identity(),
    scale: @math.Vec3::one(),
  })

  background3d_quad_mesh.val = Some(
    @render3d.register_mesh_asset(background3d_quad_mesh_asset()),
  )
  background3d_planet_mesh.val = Some(
    @render3d.register_mesh_asset(@render3d.sphere_mesh(BG3D_PLANET_RADIUS)),
  )
  background3d_star_mesh.val = Some(
    @render3d.register_mesh_asset(@render3d.sphere_mesh(BG3D_STAR_RADIUS)),
  )

  background3d_initialized.val = true
  refresh_background3d_assets()
  set_background3d_active(false)
}

///|
fn preload_assets() -> Unit {
  let image_paths = [
    MENU_BG_TEXTURE,
    GAME_BG_TEXTURE,
    GAME_OVER_BG_TEXTURE,
    VICTORY_BG_TEXTURE,
    THETAWAVE_LOGO_TEXTURE,
    MENU_BUTTON_SPRITESHEET_TEXTURE,
    CAPTAIN_TEXTURE,
    JUGGERNAUT_TEXTURE,
    CAPTAIN_OUTLINE_TEXTURE,
    JUGGERNAUT_OUTLINE_TEXTURE,
    CAPTAIN_DESCRIPTION_TEXTURE,
    JUGGERNAUT_DESCRIPTION_TEXTURE,
    RESTART_GAME_PROMPT_TEXTURE,
    PAWN_TEXTURE,
    DRONE_TEXTURE,
    TUTORIAL_DRONE_TEXTURE,
    SHELLY_TEXTURE,
    STRAFER_TEXTURE,
    MISSILE_LAUNCHER_TEXTURE,
    MISSILE_TEXTURE,
    MONEY_ASTEROID_TEXTURE,
    HAULER_TEXTURE,
    HAULER_MIDDLE_TEXTURE,
    HAULER_BACK_TEXTURE,
    HAULER_THRUSTERS_TEXTURE,
    CRUSTLING_TEXTURE,
    FERRITHARAX_TEXTURE,
    FERRITHARAX_BODY_TEXTURE,
    FERRITHARAX_LEFT_SHOULDER_TEXTURE,
    FERRITHARAX_RIGHT_SHOULDER_TEXTURE,
    FERRITHARAX_LEFT_ARM_TEXTURE,
    FERRITHARAX_RIGHT_ARM_TEXTURE,
    FERRITHARAX_LEFT_CLAW_TEXTURE,
    FERRITHARAX_RIGHT_CLAW_TEXTURE,
    MECHA_FERRITHARAX_TEXTURE,
    MECHA_FERRITHARAX_BODY_TEXTURE,
    MECHA_FERRITHARAX_LEFT_SHOULDER_TEXTURE,
    MECHA_FERRITHARAX_RIGHT_SHOULDER_TEXTURE,
    MECHA_FERRITHARAX_LEFT_ARM_TEXTURE,
    MECHA_FERRITHARAX_RIGHT_ARM_TEXTURE,
    MECHA_FERRITHARAX_LEFT_CLAW_TEXTURE,
    MECHA_FERRITHARAX_RIGHT_CLAW_TEXTURE,
    MECHA_SAUCETRON_TEXTURE,
    MECHA_SAUCETRON_BODY_TEXTURE,
    MECHA_SAUCETRON_LEFT_SHOULDER_TEXTURE,
    MECHA_SAUCETRON_RIGHT_SHOULDER_TEXTURE,
    MECHA_SAUCETRON_LEFT_ARM_TEXTURE,
    MECHA_SAUCETRON_RIGHT_ARM_TEXTURE,
    MECHA_SAUCETRON_LEFT_CLAW_TEXTURE,
    MECHA_SAUCETRON_RIGHT_CLAW_TEXTURE,
    PLAYER_BULLET_TEXTURE,
    PLAYER_BLAST_TEXTURE,
    ENEMY_BULLET_TEXTURE,
    ENEMY_BLAST_TEXTURE,
    CONSUMABLE_MONEY_TEXTURE,
    CONSUMABLE_MONEY3_TEXTURE,
    CONSUMABLE_HEALTH_TEXTURE,
    CONSUMABLE_ARMOR_TEXTURE,
    CONSUMABLE_GAIN_PROJECTILES_TEXTURE,
    ITEM_ENHANCED_PLATING_TEXTURE,
    HEALTH_BAR_LABEL_TEXTURE,
    DEFENSE_BAR_LABEL_TEXTURE,
    WARNING_GRADIENT_TEXTURE,
    DEFENSE_GRADIENT_TEXTURE,
    ABILITY_SQUARE_LEFT_TEXTURE,
    BLAST_ABILITY_TEXTURE,
    BULLET_ABILITY_TEXTURE,
    MEGABLAST_ABILITY_TEXTURE,
    CHARGE_ABILITY_TEXTURE,
    DAMAGE_ICON_TEXTURE,
    HEALTH_ICON_TEXTURE,
    RANGE_ICON_TEXTURE,
    FIRE_RATE_ICON_TEXTURE,
    SIZE_ICON_TEXTURE,
    SPEED_ICON_TEXTURE,
  ]
  for path in image_paths {
    ignore(@asset.load_image(path))
  }
  for texture in game_background_textures {
    ignore(@asset.load_image(texture))
  }

  ignore(@asset.load_font(FONT_LUNCHDS_PATH, family=FONT_LUNCHDS_ALIAS))
  ignore(
    @asset.load_font(FONT_SPACE_MADNESS_PATH, family=FONT_SPACE_MADNESS_ALIAS),
  )
  ignore(@asset.load_font(FONT_WIBLETOWN_PATH, family=FONT_WIBLETOWN_ALIAS))

  let audio_paths = [
    MUSIC_GAME_LOOP,
    SFX_PLAYER_FIRE,
    SFX_ENEMY_FIRE,
    SFX_PLAYER_HIT,
    SFX_DEFENSE_DAMAGE,
    SFX_DEFENSE_HEAL,
    SFX_MEGABLAST,
    SFX_CONSUMABLE_PICKUP,
    SFX_MENU_INPUT_SUCCESS,
  ]
  for path in audio_paths {
    ignore(@asset.load_audio(path))
  }
}

///|
fn initialize_scene() -> Unit {
  let entity = game_state.background
  if !entity.is_alive() {
    entity.respawn()
  }
  set_background(Menu)
}

///|
fn set_background(kind : BackgroundKind) -> Unit {
  game_state.background_kind = kind
  ignore(game_state.background_kind)
  if uses_3d_background(kind) {
    ensure_background3d_initialized()
    if kind is Menu || kind is Game {
      refresh_background3d_assets()
    }
    set_background3d_active(true)
    set_background_sprite_visible(false)
    return
  }

  set_background3d_active(false)
  let sprite = if kind is Game {
    background_sprite_by_texture(
      game_background_texture_for_stage(game_state.stage_index),
    )
  } else {
    background_sprite(kind)
  }
  @sprite.sprites().set(game_state.background, sprite)
  @transform.positions().set(game_state.background, @math.Vec2D(0.0, 0.0))
  set_background_sprite_visible(true)
}

///|
fn game_background_texture_for_stage(stage_index : Int) -> String {
  let len = game_background_textures.length()
  if len <= 0 {
    return GAME_BG_TEXTURE
  }
  let idx = if stage_index <= GAME_BACKGROUND_LEVEL1_STAGE_END {
    0
  } else if stage_index <= GAME_BACKGROUND_LEVEL2_STAGE_END {
    1
  } else {
    2
  }
  let idx = clamp_int(idx, 0, len - 1)
  game_background_textures[idx]
}

///|
fn initialize_ui() -> Unit {
  setup_text_entity(
    game_state.score_ui,
    game_state.score_text,
    @math.Vec2D(8.0, 8.0),
  )
  setup_text_entity(
    game_state.hull_ui,
    game_state.hull_text,
    @math.Vec2D(8.0, 28.0),
  )
  setup_text_entity(
    game_state.shield_ui,
    game_state.shield_text,
    @math.Vec2D(8.0, 48.0),
  )
  setup_text_entity(
    game_state.defense_ui,
    game_state.defense_text,
    @math.Vec2D(8.0, 68.0),
  )
  setup_text_entity(
    game_state.stage_ui,
    game_state.stage_text,
    @math.Vec2D(8.0, 88.0),
  )
  setup_text_entity(
    game_state.timer_ui,
    game_state.timer_text,
    @math.Vec2D(VIEWPORT_WIDTH - 150.0, 8.0),
  )
  for i in 0..<TUTORIAL_PHASE_DATA_LINE_COUNT {
    setup_text_entity(
      tutorial_phase_data_line_uis[i],
      @sprite.Text::new(
        "",
        color="white",
        font=TUTORIAL_PHASE_LINE_FONT,
        baseline=Top,
        align=Left,
      ),
      @math.Vec2D(HUD_TOP_RIGHT_PANEL_X, 8.0 + i.to_double() * 12.0),
    )
  }
  setup_text_entity(
    game_state.banner_ui,
    game_state.banner_text,
    @math.Vec2D(40.0, VIEWPORT_HEIGHT - 20.0),
  )
  setup_picture_entity(
    game_state.menu_logo_ui,
    menu_logo_sprite(),
    @math.Vec2D(58.0, 16.0),
  )
  setup_picture_entity(
    game_state.menu_button_start_ui,
    menu_button_background_sprite(false),
    @math.Vec2D(160.0, 176.0),
  )
  setup_button_entity(game_state.menu_button_start_ui, @math.Vec2D(160.0, 22.0))
  setup_picture_entity(
    game_state.menu_button_options_ui,
    menu_button_background_sprite(false),
    @math.Vec2D(160.0, 198.0),
  )
  setup_button_entity(
    game_state.menu_button_options_ui,
    @math.Vec2D(160.0, 22.0),
  )
  setup_picture_entity(
    game_state.menu_button_compendium_ui,
    menu_button_background_sprite(false),
    @math.Vec2D(160.0, 220.0),
  )
  setup_button_entity(
    game_state.menu_button_compendium_ui,
    @math.Vec2D(160.0, 22.0),
  )
  setup_picture_entity(
    game_state.menu_button_exit_ui,
    menu_button_background_sprite(false),
    @math.Vec2D(160.0, 242.0),
  )
  setup_button_entity(game_state.menu_button_exit_ui, @math.Vec2D(160.0, 22.0))
  setup_picture_entity(
    game_state.character_portrait_ui,
    character_portrait_sprite(Captain),
    @math.Vec2D(240.0, 118.0),
  )
  setup_picture_entity(
    game_state.character_description_ui,
    character_description_sprite(Captain),
    @math.Vec2D(240.0, 242.0),
  )
  setup_picture_entity(
    character_left_portrait_ui,
    character_carousel_portrait_sprite(Juggernaut, false),
    @math.Vec2D(172.0, 132.0),
  )
  setup_picture_entity(
    character_right_portrait_ui,
    character_carousel_portrait_sprite(Juggernaut, false),
    @math.Vec2D(308.0, 132.0),
  )
  setup_text_entity(
    character_name_ui,
    @sprite.Text::new(
      "Captain",
      color="rgb(255, 215, 0)",
      font=UI_FONT_MEDIUM,
      baseline=Top,
      align=Center,
    ),
    @math.Vec2D(240.0, 178.0),
  )
  setup_picture_entity(
    character_ability_slot1_ui,
    character_ability_slot_sprite(),
    @math.Vec2D(130.0, 210.0),
  )
  setup_picture_entity(
    character_ability_slot1_icon_ui,
    character_ability_icon_sprite(Captain, 1),
    @math.Vec2D(130.0, 210.0),
  )
  setup_text_entity(
    character_ability_slot1_text_ui,
    @sprite.Text::new(
      "Fires energy blasts.",
      color="white",
      font="14px Lunchds",
      baseline=Top,
      align=Left,
    ),
    @math.Vec2D(162.0, 202.0),
  )
  setup_picture_entity(
    character_ability_slot2_ui,
    character_ability_slot_sprite(),
    @math.Vec2D(130.0, 244.0),
  )
  setup_picture_entity(
    character_ability_slot2_icon_ui,
    character_ability_icon_sprite(Captain, 2),
    @math.Vec2D(130.0, 244.0),
  )
  setup_text_entity(
    character_ability_slot2_text_ui,
    @sprite.Text::new(
      "Fires large, high damage, blasts.",
      color="white",
      font="14px Lunchds",
      baseline=Top,
      align=Left,
    ),
    @math.Vec2D(162.0, 236.0),
  )
  for i in 0..<character_stats_order.length() {
    setup_picture_entity(
      character_stat_icon_uis[i],
      character_stat_icon_sprite(character_stats_order[i]),
      @math.Vec2D(346.0, 202.0 + i.to_double() * 18.0),
    )
    setup_picture_entity(
      character_stat_bg_uis[i],
      @sprite.Sprite::from_color_rect(
        @sprite.ColorRect::new(@math.Vec2D(72.0, 7.0), "rgba(255,255,255,0.15)"),
        89,
      ),
      @math.Vec2D(388.0, 202.0 + i.to_double() * 18.0),
    )
    setup_picture_entity(
      character_stat_fill_uis[i],
      @sprite.Sprite::from_color_rect(
        @sprite.ColorRect::new(@math.Vec2D(0.0, 5.0), "rgba(255,255,255,0.95)"),
        90,
      ),
      @math.Vec2D(353.0, 203.0 + i.to_double() * 18.0),
    )
  }
  setup_text_entity(
    character_join_prompt_ui,
    @sprite.Text::new(
      "P1 Press Enter to Join",
      color="white",
      font=UI_FONT_SMALL,
      baseline=Top,
      align=Center,
    ),
    @math.Vec2D(120.0, 188.0),
  )
  setup_text_entity(
    character_ready_text_ui,
    @sprite.Text::new(
      "Not Ready",
      color="rgb(220,220,220)",
      font=UI_FONT_SMALL,
      baseline=Top,
      align=Center,
    ),
    @math.Vec2D(120.0, 282.0),
  )

  setup_picture_entity(
    character_p2_center_portrait_ui,
    character_carousel_portrait_sprite(Juggernaut, true),
    @math.Vec2D(360.0, 130.0),
  )
  setup_picture_entity(
    character_p2_left_portrait_ui,
    character_carousel_portrait_sprite(Captain, false),
    @math.Vec2D(316.0, 132.0),
  )
  setup_picture_entity(
    character_p2_right_portrait_ui,
    character_carousel_portrait_sprite(Captain, false),
    @math.Vec2D(404.0, 132.0),
  )
  setup_text_entity(
    character_p2_name_ui,
    @sprite.Text::new(
      "Juggernaut",
      color="rgb(255, 215, 0)",
      font=UI_FONT_MEDIUM,
      baseline=Top,
      align=Center,
    ),
    @math.Vec2D(360.0, 176.0),
  )
  setup_picture_entity(
    character_p2_ability_slot1_ui,
    character_ability_slot_sprite(),
    @math.Vec2D(302.0, 210.0),
  )
  setup_picture_entity(
    character_p2_ability_slot1_icon_ui,
    character_ability_icon_sprite(Juggernaut, 1),
    @math.Vec2D(302.0, 210.0),
  )
  setup_text_entity(
    character_p2_ability_slot1_text_ui,
    @sprite.Text::new(
      "Fires lead bullets.",
      color="white",
      font="14px Lunchds",
      baseline=Top,
      align=Left,
    ),
    @math.Vec2D(334.0, 202.0),
  )
  setup_picture_entity(
    character_p2_ability_slot2_ui,
    character_ability_slot_sprite(),
    @math.Vec2D(302.0, 244.0),
  )
  setup_picture_entity(
    character_p2_ability_slot2_icon_ui,
    character_ability_icon_sprite(Juggernaut, 2),
    @math.Vec2D(302.0, 244.0),
  )
  setup_text_entity(
    character_p2_ability_slot2_text_ui,
    @sprite.Text::new(
      "Charge in a direction.",
      color="white",
      font="14px Lunchds",
      baseline=Top,
      align=Left,
    ),
    @math.Vec2D(334.0, 236.0),
  )
  for i in 0..<character_stats_order.length() {
    setup_picture_entity(
      character_p2_stat_icon_uis[i],
      character_stat_icon_sprite(character_stats_order[i]),
      @math.Vec2D(410.0, 202.0 + i.to_double() * 18.0),
    )
    setup_picture_entity(
      character_p2_stat_bg_uis[i],
      @sprite.Sprite::from_color_rect(
        @sprite.ColorRect::new(@math.Vec2D(56.0, 7.0), "rgba(255,255,255,0.15)"),
        89,
      ),
      @math.Vec2D(442.0, 202.0 + i.to_double() * 18.0),
    )
    setup_picture_entity(
      character_p2_stat_fill_uis[i],
      @sprite.Sprite::from_color_rect(
        @sprite.ColorRect::new(@math.Vec2D(0.0, 5.0), "rgba(255,255,255,0.95)"),
        90,
      ),
      @math.Vec2D(414.0, 203.0 + i.to_double() * 18.0),
    )
  }
  setup_text_entity(
    character_p2_join_prompt_ui,
    @sprite.Text::new(
      "P2 Press A/Start to Join",
      color="white",
      font=UI_FONT_SMALL,
      baseline=Top,
      align=Center,
    ),
    @math.Vec2D(360.0, 188.0),
  )
  setup_text_entity(
    character_p2_ready_text_ui,
    @sprite.Text::new(
      "Not Ready",
      color="rgb(220,220,220)",
      font=UI_FONT_SMALL,
      baseline=Top,
      align=Center,
    ),
    @math.Vec2D(360.0, 282.0),
  )
  setup_picture_entity(
    game_state.phase_prompt_ui,
    restart_prompt_sprite(),
    @math.Vec2D(240.0, 244.0),
  )
  setup_picture_entity(
    game_state.warning_gradient_ui,
    border_gradient_sprite(WARNING_GRADIENT_TEXTURE, 0.0),
    @math.Vec2D(0.0, VIEWPORT_HEIGHT),
  )
  setup_picture_entity(
    game_state.defense_gradient_ui,
    border_gradient_sprite(DEFENSE_GRADIENT_TEXTURE, 0.0),
    @math.Vec2D(0.0, VIEWPORT_HEIGHT),
  )
  setup_picture_entity(
    game_state.hud_health_label_ui,
    hud_health_label_sprite(),
    @math.Vec2D(16.0, 160.0),
  )
  setup_picture_entity(
    game_state.hud_health_bar_bg_ui,
    @sprite.Sprite::from_color_rect(
      @sprite.ColorRect::new(
        @math.Vec2D(12.0, 120.0),
        "rgba(128, 16, 24, 0.18)",
      ),
      91,
    ),
    @math.Vec2D(HUD_HEALTH_BAR_BG_X, 98.0),
  )
  setup_picture_entity(
    game_state.hud_health_bar_fill_ui,
    @sprite.Sprite::from_color_rect(
      @sprite.ColorRect::new(
        @math.Vec2D(10.0, 116.0),
        "rgba(220, 20, 60, 0.85)",
      ),
      92,
    ),
    @math.Vec2D(HUD_HEALTH_BAR_FILL_X, 100.0),
  )
  setup_picture_entity(
    game_state.hud_shield_bar_bg_ui,
    @sprite.Sprite::from_color_rect(
      @sprite.ColorRect::new(@math.Vec2D(12.0, 120.0), "rgba(0, 96, 128, 0.18)"),
      91,
    ),
    @math.Vec2D(HUD_SHIELD_BAR_BG_X, 98.0),
  )
  setup_picture_entity(
    game_state.hud_shield_bar_fill_ui,
    @sprite.Sprite::from_color_rect(
      @sprite.ColorRect::new(
        @math.Vec2D(10.0, 116.0),
        "rgba(0, 255, 255, 0.75)",
      ),
      92,
    ),
    @math.Vec2D(HUD_SHIELD_BAR_FILL_X, 100.0),
  )
  setup_picture_entity(
    game_state.hud_defense_label_ui,
    hud_defense_label_sprite(),
    @math.Vec2D(240.0, 300.0),
  )
  setup_picture_entity(
    game_state.hud_defense_bar_bg_ui,
    @sprite.Sprite::from_color_rect(
      @sprite.ColorRect::new(@math.Vec2D(120.0, 8.0), "rgba(18, 24, 78, 0.55)"),
      93,
    ),
    @math.Vec2D(180.0, 295.0),
  )
  setup_picture_entity(
    game_state.hud_defense_bar_fill_ui,
    @sprite.Sprite::from_color_rect(
      @sprite.ColorRect::new(@math.Vec2D(120.0, 8.0), "rgba(40, 110, 255, 0.9)"),
      94,
    ),
    @math.Vec2D(180.0, 295.0),
  )
  setup_picture_entity(
    game_state.hud_slot1_bg_ui,
    hud_ability_slot_sprite(),
    @math.Vec2D(HUD_ABILITY_SLOT_CENTER_X, HUD_ABILITY_SLOT1_CENTER_Y),
  )
  setup_picture_entity(
    game_state.hud_slot1_icon_ui,
    hud_ability_icon_sprite(Captain, 1),
    @math.Vec2D(HUD_ABILITY_SLOT_CENTER_X, HUD_ABILITY_SLOT1_CENTER_Y),
  )
  setup_picture_entity(
    game_state.hud_slot1_fill_ui,
    @sprite.Sprite::from_color_rect(
      @sprite.ColorRect::new(
        @math.Vec2D(HUD_ABILITY_SLOT_FILL_WIDTH, 0.0),
        "rgba(0, 0, 0, 0.55)",
      ),
      95,
    ),
    @math.Vec2D(HUD_ABILITY_SLOT_LEFT_X, HUD_ABILITY_SLOT1_FILL_BOTTOM_Y),
  )
  setup_picture_entity(
    game_state.hud_slot2_bg_ui,
    hud_ability_slot_sprite(),
    @math.Vec2D(HUD_ABILITY_SLOT_CENTER_X, HUD_ABILITY_SLOT2_CENTER_Y),
  )
  setup_picture_entity(
    game_state.hud_slot2_icon_ui,
    hud_ability_icon_sprite(Captain, 2),
    @math.Vec2D(HUD_ABILITY_SLOT_CENTER_X, HUD_ABILITY_SLOT2_CENTER_Y),
  )
  setup_picture_entity(
    game_state.hud_slot2_fill_ui,
    @sprite.Sprite::from_color_rect(
      @sprite.ColorRect::new(
        @math.Vec2D(HUD_ABILITY_SLOT_FILL_WIDTH, 0.0),
        "rgba(0, 0, 0, 0.55)",
      ),
      95,
    ),
    @math.Vec2D(HUD_ABILITY_SLOT_LEFT_X, HUD_ABILITY_SLOT2_FILL_BOTTOM_Y),
  )
  if @sprite.sprites().get(game_state.character_portrait_ui) is Some(sprite) {
    sprite.visible = false
  }
  if @sprite.sprites().get(game_state.character_description_ui) is Some(sprite) {
    sprite.visible = false
  }
  if @sprite.sprites().get(character_left_portrait_ui) is Some(sprite) {
    sprite.visible = false
  }
  if @sprite.sprites().get(character_right_portrait_ui) is Some(sprite) {
    sprite.visible = false
  }
  if @sprite.sprites().get(character_name_ui) is Some(sprite) {
    sprite.visible = false
  }
  if @sprite.sprites().get(character_ability_slot1_ui) is Some(sprite) {
    sprite.visible = false
  }
  if @sprite.sprites().get(character_ability_slot1_icon_ui) is Some(sprite) {
    sprite.visible = false
  }
  if @sprite.sprites().get(character_ability_slot1_text_ui) is Some(sprite) {
    sprite.visible = false
  }
  if @sprite.sprites().get(character_ability_slot2_ui) is Some(sprite) {
    sprite.visible = false
  }
  if @sprite.sprites().get(character_ability_slot2_icon_ui) is Some(sprite) {
    sprite.visible = false
  }
  if @sprite.sprites().get(character_ability_slot2_text_ui) is Some(sprite) {
    sprite.visible = false
  }
  if @sprite.sprites().get(character_join_prompt_ui) is Some(sprite) {
    sprite.visible = false
  }
  if @sprite.sprites().get(character_ready_text_ui) is Some(sprite) {
    sprite.visible = false
  }
  for entity in character_stat_icon_uis {
    if @sprite.sprites().get(entity) is Some(sprite) {
      sprite.visible = false
    }
  }
  for entity in character_stat_bg_uis {
    if @sprite.sprites().get(entity) is Some(sprite) {
      sprite.visible = false
    }
  }
  for entity in character_stat_fill_uis {
    if @sprite.sprites().get(entity) is Some(sprite) {
      sprite.visible = false
    }
  }
  if @sprite.sprites().get(character_p2_center_portrait_ui) is Some(sprite) {
    sprite.visible = false
  }
  if @sprite.sprites().get(character_p2_left_portrait_ui) is Some(sprite) {
    sprite.visible = false
  }
  if @sprite.sprites().get(character_p2_right_portrait_ui) is Some(sprite) {
    sprite.visible = false
  }
  if @sprite.sprites().get(character_p2_name_ui) is Some(sprite) {
    sprite.visible = false
  }
  if @sprite.sprites().get(character_p2_ability_slot1_ui) is Some(sprite) {
    sprite.visible = false
  }
  if @sprite.sprites().get(character_p2_ability_slot1_icon_ui) is Some(sprite) {
    sprite.visible = false
  }
  if @sprite.sprites().get(character_p2_ability_slot1_text_ui) is Some(sprite) {
    sprite.visible = false
  }
  if @sprite.sprites().get(character_p2_ability_slot2_ui) is Some(sprite) {
    sprite.visible = false
  }
  if @sprite.sprites().get(character_p2_ability_slot2_icon_ui) is Some(sprite) {
    sprite.visible = false
  }
  if @sprite.sprites().get(character_p2_ability_slot2_text_ui) is Some(sprite) {
    sprite.visible = false
  }
  if @sprite.sprites().get(character_p2_join_prompt_ui) is Some(sprite) {
    sprite.visible = false
  }
  if @sprite.sprites().get(character_p2_ready_text_ui) is Some(sprite) {
    sprite.visible = false
  }
  for entity in character_p2_stat_icon_uis {
    if @sprite.sprites().get(entity) is Some(sprite) {
      sprite.visible = false
    }
  }
  for entity in character_p2_stat_bg_uis {
    if @sprite.sprites().get(entity) is Some(sprite) {
      sprite.visible = false
    }
  }
  for entity in character_p2_stat_fill_uis {
    if @sprite.sprites().get(entity) is Some(sprite) {
      sprite.visible = false
    }
  }
  if @sprite.sprites().get(game_state.phase_prompt_ui) is Some(sprite) {
    sprite.visible = false
  }
  if @sprite.sprites().get(game_state.warning_gradient_ui) is Some(sprite) {
    sprite.visible = false
  }
  if @sprite.sprites().get(game_state.defense_gradient_ui) is Some(sprite) {
    sprite.visible = false
  }
  if @sprite.sprites().get(game_state.hud_health_label_ui) is Some(sprite) {
    sprite.visible = false
  }
  if @sprite.sprites().get(game_state.hud_health_bar_bg_ui) is Some(sprite) {
    sprite.visible = false
  }
  if @sprite.sprites().get(game_state.hud_health_bar_fill_ui) is Some(sprite) {
    sprite.visible = false
  }
  if @sprite.sprites().get(game_state.hud_shield_bar_bg_ui) is Some(sprite) {
    sprite.visible = false
  }
  if @sprite.sprites().get(game_state.hud_shield_bar_fill_ui) is Some(sprite) {
    sprite.visible = false
  }
  if @sprite.sprites().get(game_state.hud_defense_label_ui) is Some(sprite) {
    sprite.visible = false
  }
  if @sprite.sprites().get(game_state.hud_defense_bar_bg_ui) is Some(sprite) {
    sprite.visible = false
  }
  if @sprite.sprites().get(game_state.hud_defense_bar_fill_ui) is Some(sprite) {
    sprite.visible = false
  }
  if @sprite.sprites().get(game_state.hud_slot1_bg_ui) is Some(sprite) {
    sprite.visible = false
  }
  if @sprite.sprites().get(game_state.hud_slot1_icon_ui) is Some(sprite) {
    sprite.visible = false
  }
  if @sprite.sprites().get(game_state.hud_slot1_fill_ui) is Some(sprite) {
    sprite.visible = false
  }
  if @sprite.sprites().get(game_state.hud_slot2_bg_ui) is Some(sprite) {
    sprite.visible = false
  }
  if @sprite.sprites().get(game_state.hud_slot2_icon_ui) is Some(sprite) {
    sprite.visible = false
  }
  if @sprite.sprites().get(game_state.hud_slot2_fill_ui) is Some(sprite) {
    sprite.visible = false
  }
  for entity in tutorial_phase_data_line_uis {
    if @sprite.sprites().get(entity) is Some(sprite) {
      sprite.visible = false
    }
  }
}

///|
fn setup_text_entity(
  entity : @entity.Entity,
  text : @sprite.Text,
  position : @math.Vec2D,
) -> Unit {
  if !entity.is_alive() {
    entity.respawn()
  }
  @sprite.sprites().set(entity, @sprite.Sprite::from_text(text, 100))
  @transform.positions().set(entity, position)
}

///|
fn setup_picture_entity(
  entity : @entity.Entity,
  sprite : @sprite.Sprite,
  position : @math.Vec2D,
) -> Unit {
  if !entity.is_alive() {
    entity.respawn()
  }
  @sprite.sprites().set(entity, sprite)
  @transform.positions().set(entity, position)
}

///|
fn setup_button_entity(entity : @entity.Entity, hit_size : @math.Vec2D) -> Unit {
  let position = @transform.positions()
    .get(entity)
    .map_or(@math.Vec2D::zero(), position => position.0)
  @ui.nodes().set(entity, @ui.Node::absolute(position, size=hit_size))
  @ui.buttons().set(entity, @ui.Button::new())
  @ui.interactions().set(entity, @ui.None)
}

///|
fn enter_main_menu() -> Unit {
  clear_dynamic_entities()
  game_state.screen = MainMenu
  game_state.phase = Playing
  game_state.main_menu_selected = 0
  set_background(Menu)
  if !game_state.music_started {
    play_audio(MUSIC_GAME_LOOP, volume=0.35, loop_=true)
    game_state.music_started = true
  }
}

///|
fn enter_character_selection() -> Unit {
  clear_dynamic_entities()
  game_state.screen = CharacterSelection
  game_state.phase = Playing
  game_state.cs_p1_joined = false
  game_state.cs_p1_ready = false
  game_state.cs_p1_character = Captain
  game_state.cs_p2_joined = false
  game_state.cs_p2_ready = false
  game_state.cs_p2_character = Juggernaut
  set_background(CharacterSelection)
}

///|
fn start_game_with_selected_character() -> Unit {
  game_state.screen = InGame
  reset_run()
}

///|
fn reset_run() -> Unit {
  clear_dynamic_entities()
  reset_game_state_data()
  apply_character(game_state.selected_character)
  spawn_player()
  enter_stage()
}

///|
fn clear_dynamic_entities() -> Unit {
  let enemies_to_clear = []
  for enemy_entity, _ in enemies {
    enemies_to_clear.push(enemy_entity)
  }
  for enemy_entity in enemies_to_clear {
    despawn_enemy(enemy_entity)
  }
  let part_hosts_to_clear = []
  for host_entity, _ in enemy_visual_parts {
    part_hosts_to_clear.push(host_entity)
  }
  for host_entity in part_hosts_to_clear {
    despawn_enemy_visual_parts(host_entity)
  }

  let bullets_to_clear = []
  for bullet_entity, _ in bullets {
    bullets_to_clear.push(bullet_entity)
  }
  for bullet_entity in bullets_to_clear {
    despawn_bullet(bullet_entity)
  }

  let consumables_to_clear = []
  for consumable_entity, _ in consumables {
    consumables_to_clear.push(consumable_entity)
  }
  for consumable_entity in consumables_to_clear {
    despawn_consumable(consumable_entity)
  }

  let items_to_clear = []
  for item_entity, _ in items {
    items_to_clear.push(item_entity)
  }
  for item_entity in items_to_clear {
    despawn_item(item_entity)
  }
}

///|
fn reset_game_state_data() -> Unit {
  game_state.phase = Playing
  game_state.score = 0
  game_state.shots_fired = 0
  game_state.shots_hit = 0
  game_state.enemies_destroyed = 0
  game_state.money = 0
  game_state.armor = 0
  game_state.defense = 100
  game_state.elapsed = 0.0
  game_state.stage_index = 0
  game_state.stage_elapsed = 0.0
  game_state.stage_spawn_timer = 0.0
  game_state.stage_label = ""
  game_state.boss_spawned = false
  game_state.plating_count = 0
  game_state.allow_move = true
  game_state.allow_main_attack = true
  game_state.allow_special = true
  game_state.tutorial_lesson = 0
  game_state.tutorial_up_progress = 0.0
  game_state.tutorial_down_progress = 0.0
  game_state.tutorial_left_progress = 0.0
  game_state.tutorial_right_progress = 0.0
  game_state.tutorial_up_left_progress = 0.0
  game_state.tutorial_up_right_progress = 0.0
  game_state.tutorial_down_left_progress = 0.0
  game_state.tutorial_down_right_progress = 0.0
  game_state.tutorial_slot1_destroy = 0
  game_state.tutorial_slot1_protect = 0
  game_state.tutorial_slot2_destroy = 0
  game_state.tutorial_spawn_timer = 0.0
  game_state.center_intro_text = ""
  game_state.center_intro_timer = 0.0
  game_state.warning_gradient_timer = 0.0
  game_state.defense_gradient_timer = 0.0
  game_state.shoot_cooldown = 0.0
  game_state.special_cooldown = 0.0
  game_state.player_invulnerable = 0.0
  game_state.charge_time_left = 0.0
  game_state.charge_velocity = @math.Vec2D(0.0, 0.0)
}

///|
fn apply_character(character : CharacterType) -> Unit {
  let config = character_config(character)
  game_state.max_hull = config.max_hull
  game_state.hull = config.max_hull
  game_state.max_shield = config.max_shield
  game_state.shield = config.max_shield
  game_state.shield_recharge_rate = config.shield_recharge_rate
  game_state.shield_recharge_delay = 0.0
  game_state.shield_recharge_progress = 0.0
  game_state.attraction_distance = config.attraction_distance
  game_state.attraction_acceleration = config.attraction_acceleration
  game_state.base_cooldown_multiplier = config.base_cooldown_multiplier
  game_state.cooldown_multiplier = config.base_cooldown_multiplier
  game_state.player_speed = config.speed
  game_state.shoot_interval = config.shoot_interval
  game_state.special_cooldown_base = config.special_cooldown
  game_state.projectile_kind = config.projectile_kind
  game_state.projectile_speed = config.projectile_speed
  game_state.projectile_damage = config.projectile_damage
  game_state.projectile_ttl = config.projectile_ttl
  game_state.special_ability = config.special_ability
  game_state.projectile_count = if character is Juggernaut { 3 } else { 1 }
  refresh_cooldown_multiplier()
}

///|
fn spawn_player() -> Unit {
  let entity = game_state.player
  if !entity.is_alive() {
    entity.respawn()
  }
  @sprite.sprites().set(entity, player_sprite(game_state.selected_character))
  @transform.positions().set(entity, initial_player_position())
}

///|
priv struct EnemyPartTemplate {
  sprite : @sprite.Sprite
  offset : @math.Vec2D
  bob_amp : Double
  bob_speed : Double
  bob_phase : Double
}

///|
fn enemy_part_picture(
  texture : String,
  size : @math.Vec2D,
  zindex : Int,
) -> @sprite.Sprite {
  @sprite.Sprite::from_picture(
    @sprite.Picture::new(size, texture),
    zindex,
    offset=@math.Vec2D(-size[X] / 2.0, -size[Y] / 2.0),
  )
}

///|
fn enemy_part_templates(kind : EnemyKind) -> Array[EnemyPartTemplate] {
  match kind {
    Hauler =>
      [
        {
          sprite: enemy_part_picture(
            HAULER_MIDDLE_TEXTURE,
            @math.Vec2D(18.0, 26.0),
            10,
          ),
          offset: @math.Vec2D(0.0, 18.0),
          bob_amp: 0.0,
          bob_speed: 0.0,
          bob_phase: 0.0,
        },
        {
          sprite: enemy_part_picture(
            HAULER_BACK_TEXTURE,
            @math.Vec2D(18.0, 24.0),
            9,
          ),
          offset: @math.Vec2D(0.0, 35.0),
          bob_amp: 0.0,
          bob_speed: 0.0,
          bob_phase: 0.0,
        },
        {
          sprite: animated_sprite(
            HAULER_THRUSTERS_TEXTURE,
            20.0,
            9.0,
            3,
            8.0,
            8,
          ),
          offset: @math.Vec2D(0.0, 51.0),
          bob_amp: 0.0,
          bob_speed: 0.0,
          bob_phase: 0.0,
        },
      ]
    Ferritharax =>
      [
        {
          sprite: animated_sprite(
            FERRITHARAX_BODY_TEXTURE,
            70.0,
            43.0,
            3,
            4.0,
            11,
          ),
          offset: @math.Vec2D(0.0, 34.0),
          bob_amp: 0.0,
          bob_speed: 0.0,
          bob_phase: 0.0,
        },
        {
          sprite: animated_sprite(
            FERRITHARAX_LEFT_SHOULDER_TEXTURE,
            58.0,
            64.0,
            3,
            4.0,
            11,
          ),
          offset: @math.Vec2D(-34.0, 8.0),
          bob_amp: 0.0,
          bob_speed: 0.0,
          bob_phase: 0.0,
        },
        {
          sprite: animated_sprite(
            FERRITHARAX_RIGHT_SHOULDER_TEXTURE,
            58.0,
            64.0,
            3,
            4.0,
            11,
          ),
          offset: @math.Vec2D(34.0, 8.0),
          bob_amp: 0.0,
          bob_speed: 0.0,
          bob_phase: 0.0,
        },
        {
          sprite: animated_sprite(
            FERRITHARAX_LEFT_ARM_TEXTURE,
            41.0,
            62.0,
            3,
            4.0,
            10,
          ),
          offset: @math.Vec2D(-50.0, 14.0),
          bob_amp: 2.0,
          bob_speed: 2.1,
          bob_phase: 0.0,
        },
        {
          sprite: animated_sprite(
            FERRITHARAX_RIGHT_ARM_TEXTURE,
            41.0,
            62.0,
            3,
            4.0,
            10,
          ),
          offset: @math.Vec2D(50.0, 14.0),
          bob_amp: 2.0,
          bob_speed: 2.1,
          bob_phase: 3.141592653589793,
        },
        {
          sprite: animated_sprite(
            FERRITHARAX_LEFT_CLAW_TEXTURE,
            36.0,
            35.0,
            3,
            4.0,
            10,
          ),
          offset: @math.Vec2D(-62.0, 24.0),
          bob_amp: 2.5,
          bob_speed: 2.7,
          bob_phase: 1.2,
        },
        {
          sprite: animated_sprite(
            FERRITHARAX_RIGHT_CLAW_TEXTURE,
            36.0,
            35.0,
            3,
            4.0,
            10,
          ),
          offset: @math.Vec2D(62.0, 24.0),
          bob_amp: 2.5,
          bob_speed: 2.7,
          bob_phase: 4.3,
        },
      ]
    MechaFerritharax =>
      [
        {
          sprite: animated_sprite(
            MECHA_FERRITHARAX_BODY_TEXTURE,
            80.0,
            43.0,
            3,
            4.0,
            11,
          ),
          offset: @math.Vec2D(0.0, 34.0),
          bob_amp: 0.0,
          bob_speed: 0.0,
          bob_phase: 0.0,
        },
        {
          sprite: animated_sprite(
            MECHA_FERRITHARAX_LEFT_SHOULDER_TEXTURE,
            62.0,
            66.0,
            3,
            4.0,
            11,
          ),
          offset: @math.Vec2D(-36.0, 9.0),
          bob_amp: 0.0,
          bob_speed: 0.0,
          bob_phase: 0.0,
        },
        {
          sprite: animated_sprite(
            MECHA_FERRITHARAX_RIGHT_SHOULDER_TEXTURE,
            62.0,
            66.0,
            3,
            4.0,
            11,
          ),
          offset: @math.Vec2D(36.0, 9.0),
          bob_amp: 0.0,
          bob_speed: 0.0,
          bob_phase: 0.0,
        },
        {
          sprite: animated_sprite(
            MECHA_FERRITHARAX_LEFT_ARM_TEXTURE,
            40.0,
            57.0,
            3,
            4.0,
            10,
          ),
          offset: @math.Vec2D(-52.0, 16.0),
          bob_amp: 1.8,
          bob_speed: 2.0,
          bob_phase: 0.0,
        },
        {
          sprite: animated_sprite(
            MECHA_FERRITHARAX_RIGHT_ARM_TEXTURE,
            40.0,
            57.0,
            3,
            4.0,
            10,
          ),
          offset: @math.Vec2D(52.0, 16.0),
          bob_amp: 1.8,
          bob_speed: 2.0,
          bob_phase: 3.141592653589793,
        },
        {
          sprite: animated_sprite(
            MECHA_FERRITHARAX_LEFT_CLAW_TEXTURE,
            44.0,
            39.0,
            3,
            4.0,
            10,
          ),
          offset: @math.Vec2D(-66.0, 25.0),
          bob_amp: 2.3,
          bob_speed: 2.8,
          bob_phase: 0.8,
        },
        {
          sprite: animated_sprite(
            MECHA_FERRITHARAX_RIGHT_CLAW_TEXTURE,
            44.0,
            39.0,
            3,
            4.0,
            10,
          ),
          offset: @math.Vec2D(66.0, 25.0),
          bob_amp: 2.3,
          bob_speed: 2.8,
          bob_phase: 3.9,
        },
      ]
    MechaSaucetron =>
      [
        {
          sprite: animated_sprite(
            MECHA_SAUCETRON_BODY_TEXTURE,
            80.0,
            43.0,
            3,
            4.0,
            11,
          ),
          offset: @math.Vec2D(0.0, 34.0),
          bob_amp: 0.0,
          bob_speed: 0.0,
          bob_phase: 0.0,
        },
        {
          sprite: animated_sprite(
            MECHA_SAUCETRON_LEFT_SHOULDER_TEXTURE,
            62.0,
            66.0,
            3,
            4.0,
            11,
          ),
          offset: @math.Vec2D(-36.0, 10.0),
          bob_amp: 0.0,
          bob_speed: 0.0,
          bob_phase: 0.0,
        },
        {
          sprite: animated_sprite(
            MECHA_SAUCETRON_RIGHT_SHOULDER_TEXTURE,
            62.0,
            66.0,
            3,
            4.0,
            11,
          ),
          offset: @math.Vec2D(36.0, 10.0),
          bob_amp: 0.0,
          bob_speed: 0.0,
          bob_phase: 0.0,
        },
        {
          sprite: animated_sprite(
            MECHA_SAUCETRON_LEFT_ARM_TEXTURE,
            40.0,
            57.0,
            3,
            4.0,
            10,
          ),
          offset: @math.Vec2D(-52.0, 18.0),
          bob_amp: 1.8,
          bob_speed: 2.2,
          bob_phase: 0.0,
        },
        {
          sprite: animated_sprite(
            MECHA_SAUCETRON_RIGHT_ARM_TEXTURE,
            40.0,
            57.0,
            3,
            4.0,
            10,
          ),
          offset: @math.Vec2D(52.0, 18.0),
          bob_amp: 1.8,
          bob_speed: 2.2,
          bob_phase: 3.141592653589793,
        },
        {
          sprite: animated_sprite(
            MECHA_SAUCETRON_LEFT_CLAW_TEXTURE,
            44.0,
            39.0,
            3,
            4.0,
            10,
          ),
          offset: @math.Vec2D(-66.0, 27.0),
          bob_amp: 2.3,
          bob_speed: 2.9,
          bob_phase: 1.0,
        },
        {
          sprite: animated_sprite(
            MECHA_SAUCETRON_RIGHT_CLAW_TEXTURE,
            44.0,
            39.0,
            3,
            4.0,
            10,
          ),
          offset: @math.Vec2D(66.0, 27.0),
          bob_amp: 2.3,
          bob_speed: 2.9,
          bob_phase: 4.1,
        },
      ]
    _ => []
  }
}

///|
fn enemy_part_role(kind : EnemyKind, index : Int) -> EnemyPartRole {
  match kind {
    Ferritharax =>
      match index {
        1 => PartShoulderLeft
        2 => PartShoulderRight
        3 => PartArmLeft
        4 => PartArmRight
        5 => PartClawLeft
        6 => PartClawRight
        _ => PartGeneric
      }
    MechaFerritharax =>
      match index {
        1 => PartShoulderLeft
        2 => PartShoulderRight
        3 => PartArmLeft
        4 => PartArmRight
        5 => PartClawLeft
        6 => PartClawRight
        _ => PartGeneric
      }
    MechaSaucetron =>
      match index {
        1 => PartShoulderLeft
        2 => PartShoulderRight
        3 => PartArmLeft
        4 => PartArmRight
        5 => PartClawLeft
        6 => PartClawRight
        _ => PartGeneric
      }
    _ => PartGeneric
  }
}

///|
fn ferritharax_protect_pose_offset(role : EnemyPartRole) -> @math.Vec2D {
  let angle = match role {
    PartShoulderLeft => 0.15
    PartShoulderRight => 0.15
    PartArmLeft => 0.5
    PartArmRight => 0.5
    PartClawLeft => 1.0
    PartClawRight => 1.0
    PartGeneric => 0.0
  }
  let dir_x = match role {
    PartShoulderLeft => 1.0
    PartArmLeft => 1.0
    PartClawLeft => 1.0
    PartShoulderRight => -1.0
    PartArmRight => -1.0
    PartClawRight => -1.0
    PartGeneric => 0.0
  }
  @math.Vec2D(dir_x * angle * 18.0, -angle * 24.0)
}

///|
fn spawn_enemy_visual_parts(
  enemy_entity : @entity.Entity,
  kind : EnemyKind,
  origin : @math.Vec2D,
) -> Unit {
  let templates = enemy_part_templates(kind)
  if templates.length() <= 0 {
    enemy_visual_parts.remove(enemy_entity)
    return
  }
  let links = []
  for i in 0..<templates.length() {
    let template = templates[i]
    let part_entity = @entity.Entity::new()
    @sprite.sprites().set(part_entity, template.sprite)
    @transform.positions().set(part_entity, origin + template.offset)
    links.push({
      entity: part_entity,
      role: enemy_part_role(kind, i),
      offset: template.offset,
      bob_amp: template.bob_amp,
      bob_speed: template.bob_speed,
      bob_phase: template.bob_phase,
    })
  }
  enemy_visual_parts.set(enemy_entity, links)
}

///|
fn sync_enemy_visual_parts(
  enemy_entity : @entity.Entity,
  origin : @math.Vec2D,
) -> Unit {
  if enemy_visual_parts.get(enemy_entity) is Some(parts) {
    let protect_mode = if enemies.get(enemy_entity) is Some(enemy) {
      is_ferritharax_family(enemy.kind) &&
      (enemy.boss_phase == 1 || enemy.boss_phase == 3)
    } else {
      false
    }
    for part in parts {
      let bob_y = if part.bob_amp > 0.0 {
        @cmath.sin(game_state.elapsed * part.bob_speed + part.bob_phase) *
        part.bob_amp
      } else {
        0.0
      }
      let pose_offset = if protect_mode {
        ferritharax_protect_pose_offset(part.role)
      } else {
        @math.Vec2D(0.0, 0.0)
      }
      @transform.positions().set(
        part.entity,
        origin + part.offset + pose_offset + @math.Vec2D(0.0, bob_y),
      )
    }
  }
}

///|
fn despawn_enemy_visual_parts(enemy_entity : @entity.Entity) -> Unit {
  if enemy_visual_parts.get(enemy_entity) is Some(parts) {
    for part in parts {
      @sprite.sprites().remove(part.entity)
      @transform.positions().remove(part.entity)
      if part.entity.is_alive() {
        part.entity.destroy()
      }
    }
  }
  enemy_visual_parts.remove(enemy_entity)
}

///|
fn spawn_enemy(kind : EnemyKind, spawn_pos : @math.Vec2D) -> Unit {
  let enemy_entity = @entity.Entity::new()
  let archetype = enemy_archetype(kind)
  let hp_bonus = if kind is Missile ||
    kind is MoneyAsteroid ||
    kind is TutorialDrone ||
    kind is Hauler ||
    kind is Ferritharax ||
    kind is MechaFerritharax ||
    kind is MechaSaucetron {
    0
  } else {
    (game_state.elapsed / 45.0).to_int() * 3
  }
  let speed_bonus = game_state.stage_index.to_double() * 4.0
  let speed_x = if archetype.speed_x <= 0.0 {
    0.0
  } else {
    archetype.speed_x + speed_bonus
  }
  let speed_y = if kind is Missile {
    archetype.speed_y + game_state.stage_index.to_double() * 8.0
  } else if kind is Ferritharax ||
    kind is MechaFerritharax ||
    kind is MechaSaucetron {
    archetype.speed_y
  } else {
    archetype.speed_y + speed_bonus
  }
  @sprite.sprites().set(enemy_entity, enemy_sprite(kind))
  @transform.positions().set(enemy_entity, spawn_pos)
  spawn_enemy_visual_parts(enemy_entity, kind, spawn_pos)
  enemies.set(enemy_entity, {
    kind,
    hp: archetype.hp + hp_bonus,
    speed_x,
    speed_y,
    collision_damage: archetype.collision_damage,
    escape_defense_delta: archetype.escape_defense_delta,
    movement: archetype.movement,
    horizontal_dir: archetype.horizontal_dir,
    shooter: archetype.shooter,
    shoot_interval: archetype.shoot_interval,
    shoot_cooldown: archetype.initial_shoot_delay,
    boss_phase: 0,
    boss_phase_elapsed: 0.0,
    boss_left_pawn_timer: 7.0,
    boss_left_drone_timer: 5.0,
    boss_right_pawn_timer: 7.0,
    boss_right_drone_timer: 5.0,
    boss_left_missile_timer: ferritharax_missile_period(kind),
    boss_right_missile_timer: ferritharax_missile_period(kind),
    boss_left_weapon_timer: if has_ferritharax_arm_weapons(kind) {
      3.0
    } else {
      9999.0
    },
    boss_right_weapon_timer: if has_ferritharax_arm_weapons(kind) {
      3.0
    } else {
      9999.0
    },
  })
}

///|
fn spawn_player_burst() -> Unit {
  guard @transform.positions().get(game_state.player) is Some(player_position)
  let projectile_count = @cmp.maximum(1, game_state.projectile_count)
  let base = @math.Vec2D(
    player_position.0[X],
    player_position.0[Y] - PLAYER_HALF_SIZE - 2.0,
  )
  match game_state.projectile_kind {
    Blast => {
      let spread = 1.5708
      for i in 0..<projectile_count {
        let t = if projectile_count <= 1 {
          0.5
        } else {
          i.to_double() / (projectile_count - 1).to_double()
        }
        let angle = -1.5708 + (t - 0.5) * spread
        let velocity = @math.Vec2D(
          @cmath.cos(angle) * game_state.projectile_speed,
          @cmath.sin(angle) * game_state.projectile_speed,
        )
        spawn_player_projectile(
          base + @math.Vec2D((t - 0.5) * 8.0, 0.0),
          velocity,
          game_state.projectile_damage,
          Blast,
          game_state.projectile_ttl,
        )
      }
    }
    Bullet =>
      for i in 0..<projectile_count {
        let offset = (i.to_double() - (projectile_count - 1).to_double() / 2.0) *
          1.5
        let angle = -1.5708 + (game_state.rand.double() - 0.5) * 0.1884
        let speed = game_state.projectile_speed *
          (0.75 + game_state.rand.double() * 0.5)
        let velocity = @math.Vec2D(
          @cmath.cos(angle) * speed,
          @cmath.sin(angle) * speed,
        )
        spawn_player_projectile(
          base + @math.Vec2D(offset, 0.0),
          velocity,
          game_state.projectile_damage,
          Bullet,
          game_state.projectile_ttl,
        )
      }
  }
  play_audio(SFX_PLAYER_FIRE, volume=0.18)
}

///|
fn spawn_player_projectile(
  start_pos : @math.Vec2D,
  velocity : @math.Vec2D,
  damage : Int,
  kind : ProjectileKind,
  ttl : Double,
) -> Unit {
  game_state.shots_fired += 1
  spawn_projectile(start_pos, velocity, damage, kind, Ally, ttl)
}

///|
fn spawn_enemy_projectile(
  start_pos : @math.Vec2D,
  velocity : @math.Vec2D,
  damage : Int,
  kind : ProjectileKind,
  ttl : Double,
) -> Unit {
  spawn_projectile(start_pos, velocity, damage, kind, Enemy, ttl)
}

///|
fn spawn_projectile(
  start_pos : @math.Vec2D,
  velocity : @math.Vec2D,
  damage : Int,
  kind : ProjectileKind,
  faction : BulletFaction,
  ttl : Double,
) -> Unit {
  let bullet_entity = @entity.Entity::new()
  @sprite.sprites().set(bullet_entity, projectile_sprite(kind, faction))
  @transform.positions().set(bullet_entity, start_pos)
  let radius = if kind is Blast { 5.0 } else { 4.0 }
  bullets.set(bullet_entity, { ttl, velocity, damage, faction, radius })
}

///|
fn spawn_consumable(kind : ConsumableKind, position : @math.Vec2D) -> Unit {
  let entity = @entity.Entity::new()
  @sprite.sprites().set(entity, consumable_sprite(kind))
  @transform.positions().set(entity, position)
  consumables.set(entity, { kind, speed: 105.0 })
}

///|
fn spawn_item(kind : ItemKind, position : @math.Vec2D) -> Unit {
  let entity = @entity.Entity::new()
  @sprite.sprites().set(entity, item_sprite(kind))
  @transform.positions().set(entity, position)
  items.set(entity, { kind, speed: 105.0 })
}

///|
fn despawn_enemy(enemy_entity : @entity.Entity) -> Unit {
  despawn_enemy_visual_parts(enemy_entity)
  enemies.remove(enemy_entity)
  @sprite.sprites().remove(enemy_entity)
  @transform.positions().remove(enemy_entity)
  if enemy_entity.is_alive() {
    enemy_entity.destroy()
  }
}

///|
fn despawn_bullet(bullet_entity : @entity.Entity) -> Unit {
  bullets.remove(bullet_entity)
  @sprite.sprites().remove(bullet_entity)
  @transform.positions().remove(bullet_entity)
  if bullet_entity.is_alive() {
    bullet_entity.destroy()
  }
}

///|
fn despawn_consumable(entity : @entity.Entity) -> Unit {
  consumables.remove(entity)
  @sprite.sprites().remove(entity)
  @transform.positions().remove(entity)
  if entity.is_alive() {
    entity.destroy()
  }
}

///|
fn despawn_item(entity : @entity.Entity) -> Unit {
  items.remove(entity)
  @sprite.sprites().remove(entity)
  @transform.positions().remove(entity)
  if entity.is_alive() {
    entity.destroy()
  }
}
