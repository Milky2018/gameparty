///|
const RABBIT_SCENE_PATH : String = "assets/mooncraft/models/rabbit.gltf"

///|
const SNOWMAN_SCENE_PATH : String = "assets/mooncraft/models/snowman_on.gltf"

///|
const ZOMBIE_SCENE_PATH : String = "assets/mooncraft/models/zombie.gltf"

///|
fn load_demo_scene_handles_once() -> Unit {
  let state = demo_entity_state.val
  if state.rabbit_scene is None {
    state.rabbit_scene = Some(@scene3d.load_scene_gltf(RABBIT_SCENE_PATH))
  }
  if state.snowman_scene is None {
    state.snowman_scene = Some(@scene3d.load_scene_gltf(SNOWMAN_SCENE_PATH))
  }
  if state.zombie_scene is None {
    state.zombie_scene = Some(@scene3d.load_scene_gltf(ZOMBIE_SCENE_PATH))
  }
}

///|
fn maybe_spawn_demo_entities() -> Unit {
  if !demo_spawn_pending.val {
    return
  }
  if demo_spawn_delay_frames.val > 0 {
    demo_spawn_delay_frames.val -= 1
    return
  }
  let load_started_at = profile_phase_begin("demo.load_scenes")
  load_demo_scene_handles_once()
  profile_phase_end("demo.load_scenes", load_started_at)

  let spawn_started_at = profile_phase_begin("demo.spawn_entities")
  spawn_demo_entities()
  profile_phase_end("demo.spawn_entities", spawn_started_at)
  demo_spawn_pending.val = false
}

///|
fn clear_demo_entities() -> Unit {
  for root in demo_entity_state.val.roots {
    if root.is_alive() {
      root.destroy()
    }
  }
  demo_entity_state.val.roots = []
}

///|
fn first_animation_node(
  instance : @scene3d.SceneInstance,
) -> @animation.AnimationNodeIndex? {
  for _, node in instance.animations {
    return Some(node)
  }
  None
}

///|
fn play_demo_animation(
  root : @entity.Entity,
  instance : @scene3d.SceneInstance,
) -> Unit {
  guard first_animation_node(instance) is Some(node) else { return }
  guard @animation.animation_players().get(root) is Some(player) else { return }
  guard @animation.animation_transitions().get(root) is Some(transitions) else {
    return
  }
  ignore(
    transitions.play(
      player,
      node,
      DEMO_ANIMATION_BLEND_DURATION,
      repeat=@animation.RepeatAnimation::Forever,
    ),
  )
}

///|
fn demo_world_position(
  wx : Int,
  wz : Int,
  y_offset? : Double = 0.0,
) -> @math.Vec3 {
  guard world_session.val is Some(session) else {
    return @math.Vec3::new(
      wx.to_double() + 0.5,
      80.0 + y_offset,
      wz.to_double() + 0.5,
    )
  }
  let y = @level.surface_height(session.world, wx, wz).to_double() +
    1.0 +
    y_offset
  @math.Vec3::new(wx.to_double() + 0.5, y, wz.to_double() + 0.5)
}

///|
fn spawn_demo_scene(
  scene : @render3d.SceneHandle?,
  translation : @math.Vec3,
  scale : Double,
) -> Unit {
  guard scene is Some(handle) else { return }
  let instance = @scene3d.instantiate_scene_instance(handle, {
    translation,
    rotation: @math.Quat::identity(),
    scale: @math.Vec3::new(scale, scale, scale),
  })
  demo_entity_state.val.roots.push(instance.root)
  play_demo_animation(instance.root, instance)
}

///|
fn spawn_demo_entities() -> Unit {
  clear_demo_entities()
  let rabbit_position = demo_world_position(
    SPAWN_BLOCK_X + 6,
    SPAWN_BLOCK_Z + 4,
  )
  let snowman_position = demo_world_position(
    SPAWN_BLOCK_X - 6,
    SPAWN_BLOCK_Z + 6,
  )
  let zombie_position = demo_world_position(
    SPAWN_BLOCK_X + 4,
    SPAWN_BLOCK_Z - 7,
  )
  spawn_demo_scene(demo_entity_state.val.rabbit_scene, rabbit_position, 0.9)
  spawn_demo_scene(demo_entity_state.val.snowman_scene, snowman_position, 0.92)
  spawn_demo_scene(demo_entity_state.val.zombie_scene, zombie_position, 1.0)
}
