///|
priv enum DebugLightMode {
  All
  Ambient
  Directional
  Player
  Dot
  GhostPoint
  GhostSpot
}

///|
priv enum DebugMaterialMode {
  Scene
  Neutral
  WorldTextureFlat
  WorldBrdfOnly
  WorldActorsNeutral
  WorldActorsColor
}

///|
priv struct LightingDebugState {
  mut enabled : Bool
  mut scene_enabled : Bool
  mut freeze_ghosts : Bool
  mut bobbing_enabled : Bool
  mut material_mode : DebugMaterialMode
  mut show_ghost_spot_rays : Bool
  mut center_ghost_spot_origin : Bool
  mut light_mode : DebugLightMode
  mut tracked_ghost_index : Int
}

///|
let lighting_debug : LightingDebugState = {
  enabled: false,
  scene_enabled: false,
  freeze_ghosts: false,
  bobbing_enabled: true,
  material_mode: Scene,
  show_ghost_spot_rays: false,
  center_ghost_spot_origin: false,
  light_mode: All,
  tracked_ghost_index: 0,
}

///|
let lighting_debug_level : Level = [
  [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
  [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
  [1, 1, 0, 0, 0, 0, 0, 0, 0, 1, 1],
  [1, 1, 0, 0, 0, 5, 0, 0, 0, 1, 1],
  [1, 1, 2, 0, 0, 0, 0, 0, 0, 1, 1],
  [1, 1, 0, 0, 0, 5, 0, 0, 0, 1, 1],
  [1, 1, 0, 0, 0, 0, 0, 0, 0, 1, 1],
  [1, 1, 0, 0, 0, 0, 0, 0, 0, 1, 1],
  [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
  [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
  [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
]

///|
fn debug_light_mode_name(mode : DebugLightMode) -> String {
  match mode {
    All => "all"
    Ambient => "ambient"
    Directional => "directional"
    Player => "player"
    Dot => "dot"
    GhostPoint => "ghost_point"
    GhostSpot => "ghost_spot"
  }
}

///|
fn next_debug_light_mode(mode : DebugLightMode) -> DebugLightMode {
  match mode {
    All => Ambient
    Ambient => Directional
    Directional => Player
    Player => Dot
    Dot => GhostPoint
    GhostPoint => GhostSpot
    GhostSpot => All
  }
}

///|
fn debug_material_mode_name(mode : DebugMaterialMode) -> String {
  match mode {
    Scene => "scene"
    Neutral => "neutral"
    WorldTextureFlat => "world-tex-flat"
    WorldBrdfOnly => "world-brdf"
    WorldActorsNeutral => "world+actors-neutral"
    WorldActorsColor => "world+actors-color"
  }
}

///|
fn next_debug_material_mode(mode : DebugMaterialMode) -> DebugMaterialMode {
  match mode {
    Scene => Neutral
    Neutral => WorldTextureFlat
    WorldTextureFlat => WorldBrdfOnly
    WorldBrdfOnly => WorldActorsNeutral
    WorldActorsNeutral => WorldActorsColor
    WorldActorsColor => Scene
  }
}

///|
fn debug_mode_allows_ambient() -> Bool {
  if !lighting_debug.enabled {
    return true
  }
  match lighting_debug.light_mode {
    All => true
    Ambient => true
    _ => false
  }
}

///|
fn debug_mode_allows_directional() -> Bool {
  if !lighting_debug.enabled {
    return true
  }
  match lighting_debug.light_mode {
    All => true
    Directional => true
    _ => false
  }
}

///|
fn debug_mode_allows_player_light() -> Bool {
  if !lighting_debug.enabled {
    return true
  }
  match lighting_debug.light_mode {
    All => true
    Player => true
    _ => false
  }
}

///|
fn debug_mode_allows_dot_light() -> Bool {
  if !lighting_debug.enabled {
    return true
  }
  match lighting_debug.light_mode {
    All => true
    Dot => true
    _ => false
  }
}

///|
fn debug_mode_allows_ghost_point_light() -> Bool {
  if !lighting_debug.enabled {
    return false
  }
  match lighting_debug.light_mode {
    All => true
    GhostPoint => true
    _ => false
  }
}

///|
fn debug_mode_allows_ghost_spot_light() -> Bool {
  if !lighting_debug.enabled {
    return true
  }
  match lighting_debug.light_mode {
    All => true
    GhostSpot => true
    _ => false
  }
}

///|
fn debug_direction_name(direction : Direction) -> String {
  match direction {
    Up => "Up"
    Down => "Down"
    Left => "Left"
    Right => "Right"
  }
}

///|
fn debug_ghost_type_name(ghost_type : GhostType) -> String {
  match ghost_type {
    Fast => "Fast"
    Normal => "Normal"
    Slow => "Slow"
  }
}

///|
fn reset_lighting_debug_tracking() -> Unit {
  lighting_debug.tracked_ghost_index = 0
}

///|
fn apply_sandbox_debug_defaults() -> Unit {
  lighting_debug.enabled = true
  lighting_debug.freeze_ghosts = true
  lighting_debug.bobbing_enabled = false
  lighting_debug.material_mode = Scene
  lighting_debug.show_ghost_spot_rays = true
  lighting_debug.center_ghost_spot_origin = false
  lighting_debug.light_mode = GhostSpot
  lighting_debug.tracked_ghost_index = 0
}

///|
fn cycle_tracked_ghost() -> Unit {
  if ghosts.length() == 0 {
    lighting_debug.tracked_ghost_index = 0
  } else {
    lighting_debug.tracked_ghost_index = (
        lighting_debug.tracked_ghost_index + 1
      ) %
      ghosts.length()
  }
}

///|
fn tracked_ghost() -> Ghost? {
  if ghosts.length() == 0 {
    return None
  }
  let count = ghosts.length()
  let raw_index = lighting_debug.tracked_ghost_index % count
  let normalized = if raw_index < 0 { raw_index + count } else { raw_index }
  lighting_debug.tracked_ghost_index = normalized
  Some(ghosts[normalized])
}

///|
fn debug_vec3_string(vec : @math.Vec3) -> String {
  "(\{vec.x},\{vec.y},\{vec.z})"
}

///|
fn debug_status_text() -> String {
  let mode = debug_light_mode_name(lighting_debug.light_mode)
  let scene_name = if lighting_debug.scene_enabled {
    "sandbox"
  } else {
    "level"
  }
  let freeze_name = if lighting_debug.freeze_ghosts { "on" } else { "off" }
  let bob_name = if lighting_debug.bobbing_enabled { "on" } else { "off" }
  let material_name = debug_material_mode_name(lighting_debug.material_mode)
  let ray_name = if lighting_debug.show_ghost_spot_rays { "on" } else { "off" }
  let origin_name = if lighting_debug.center_ghost_spot_origin {
    "center"
  } else {
    "front"
  }
  let base = "DBG scene=\{scene_name} light=\{mode} freeze=\{freeze_name} bob=\{bob_name} mat=\{material_name} rays=\{ray_name} origin=\{origin_name}"
  match tracked_ghost() {
    Some(ghost) => {
      let light_transform = @transform3d.transforms3d
        .get(ghost.light_entity)
        .unwrap_or_default()
      let local_spot_direction = @render3d.spot_lights3d
        .get(ghost.light_entity)
        .map(fn(light) { light.direction })
        .unwrap_or(@math.Vec3::new(0.0, -GHOST_SPOT_LIGHT_DOWNWARD, -1.0))
      let world_spot_direction = light_transform.rotation
        .rotate_vec3(local_spot_direction)
        .normalize()
      let line2 = "ghost#\{lighting_debug.tracked_ghost_index} \{debug_ghost_type_name(ghost.ghost_type)} pos=(\{ghost.x.to_int()},\{ghost.z.to_int()}) dir=\{debug_direction_name(ghost.direction)}"
      let line3 = "light pos=\{debug_vec3_string(light_transform.translation)} spot world dir=\{debug_vec3_string(world_spot_direction)}"
      let line4 = "spot range=\{GHOST_SPOT_LIGHT_RANGE} inner=\{GHOST_SPOT_LIGHT_INNER_ANGLE} outer=\{GHOST_SPOT_LIGHT_OUTER_ANGLE}"
      let line5 = "player=(\{player_state.x.to_int()},\{player_state.z.to_int()}) yaw=\{player_state.yaw} dots=\{dots.length()} ghosts=\{ghosts.length()}"
      base + "\n" + line2 + "\n" + line3 + "\n" + line4 + "\n" + line5
    }
    None => {
      let line2 = "player=(\{player_state.x.to_int()},\{player_state.z.to_int()}) yaw=\{player_state.yaw} dots=\{dots.length()} ghosts=0"
      base + "\n" + line2
    }
  }
}

///|
fn debug_help_text() -> String {
  "F debug HUD  G light mode  H freeze ghosts  J bobbing  K sandbox scene  L spot rays  M material mode  O spot origin  Tab tracked ghost"
}

///|
fn sync_debug_light_state() -> Unit {
  @render3d.directional_lights3d.set(light_entity, {
    ..@render3d.default_directional_light3d(),
    direction: @math.Vec3::new(-0.45, -1.0, -0.3),
    color: color_rgba(255U, 250U, 245U, 1.0),
    intensity: if debug_mode_allows_directional() {
      DIRECTIONAL_LIGHT_INTENSITY
    } else {
      0.0
    },
  })
  @render3d.set_ambient_light3d(
    Some({
      color: color_rgba(190U, 205U, 240U, 1.0),
      intensity: if debug_mode_allows_ambient() {
        AMBIENT_LIGHT_INTENSITY
      } else {
        0.0
      },
    }),
  )
  for dot in dots {
    if !dot.collected && dot.entity.is_alive() {
      @render3d.point_lights3d.set(dot.entity, {
        ..@render3d.default_point_light3d(),
        color: color_rgba(245U, 227U, 92U, 1.0),
        intensity: if debug_mode_allows_dot_light() {
          DOT_LIGHT_INTENSITY
        } else {
          0.0
        },
        range: DOT_LIGHT_RANGE,
      })
    }
  }
}

///|
fn lighting_debug_system(_delta : Double) -> Unit {
  sync_debug_light_state()
  sync_camera_transform()
  for ghost in ghosts {
    sync_ghost_visuals(ghost)
  }
}
