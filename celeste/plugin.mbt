///|
const TILE_SIZE : Double = 48.0

///|
const GROUND_Y_TILE : Int = 10

///|
fn vec2(x : Double, y : Double) -> @math.Vec2D {
  @math.Vec2D(x, y)
}

///|
fn tile_center(tile_x : Int, tile_y : Int) -> @math.Vec2D {
  vec2(
    (tile_x.to_double() + 0.5) * TILE_SIZE,
    (tile_y.to_double() + 0.5) * TILE_SIZE,
  )
}

///|
fn push_tile(
  blocks : Array[@platformer_platform.SolidBlock],
  tile_x : Int,
  tile_y : Int,
  kind : @platformer_platform.TileKind,
) -> Unit {
  blocks.push(
    @platformer_platform.block(
      tile_center(tile_x, tile_y),
      vec2(TILE_SIZE, TILE_SIZE),
      kind,
    ),
  )
}

///|
fn push_range(
  blocks : Array[@platformer_platform.SolidBlock],
  start_x : Int,
  end_x_exclusive : Int,
  tile_y : Int,
  kind : @platformer_platform.TileKind,
) -> Unit {
  for tile_x in start_x..<end_x_exclusive {
    push_tile(blocks, tile_x, tile_y, kind)
  }
}

///|
fn build_level_forsaken_cliff() -> @platformer_platform.LevelSpec {
  let blocks : Array[@platformer_platform.SolidBlock] = []
  for tile_x in 0..<64 {
    if (tile_x >= 12 && tile_x <= 14) ||
      (tile_x >= 27 && tile_x <= 29) ||
      (tile_x >= 44 && tile_x <= 46) {
      continue
    }
    push_tile(blocks, tile_x, GROUND_Y_TILE, @platformer_platform.Ground)
  }

  push_range(blocks, 8, 12, 8, @platformer_platform.Brick)
  push_range(blocks, 16, 19, 7, @platformer_platform.Brick)
  push_range(blocks, 23, 27, 6, @platformer_platform.Brick)
  push_range(blocks, 31, 35, 8, @platformer_platform.Brick)
  push_range(blocks, 37, 41, 7, @platformer_platform.Brick)
  push_range(blocks, 49, 54, 7, @platformer_platform.Brick)
  push_range(blocks, 56, 60, 6, @platformer_platform.Brick)

  for tile_y in 6..<10 {
    push_tile(blocks, 20, tile_y, @platformer_platform.Brick)
    push_tile(blocks, 22, tile_y, @platformer_platform.Brick)
    push_tile(blocks, 47, tile_y, @platformer_platform.Brick)
    push_tile(blocks, 48, tile_y, @platformer_platform.Brick)
  }

  push_range(blocks, 12, 15, 9, @platformer_platform.Spike)
  push_range(blocks, 27, 30, 9, @platformer_platform.Spike)
  push_range(blocks, 44, 47, 9, @platformer_platform.Spike)
  push_range(blocks, 40, 44, 9, @platformer_platform.Spike)
  push_range(blocks, 60, 63, 9, @platformer_platform.Spike)
  push_tile(blocks, 19, 8, @platformer_platform.DashCrystal)
  push_tile(blocks, 35, 9, @platformer_platform.Spring)
  push_tile(blocks, 55, 5, @platformer_platform.DashCrystal)

  @platformer_platform.level(
    "Forsaken Cliff",
    tile_center(2, 9),
    tile_center(62, 8),
    vec2(34.0, 150.0),
    64.0 * TILE_SIZE,
    blocks,
  )
}

///|
fn build_level_mirror_temple() -> @platformer_platform.LevelSpec {
  let blocks : Array[@platformer_platform.SolidBlock] = []
  for tile_x in 0..<82 {
    if (tile_x >= 10 && tile_x <= 12) ||
      (tile_x >= 25 && tile_x <= 27) ||
      (tile_x >= 40 && tile_x <= 42) ||
      (tile_x >= 58 && tile_x <= 60) {
      continue
    }
    push_tile(blocks, tile_x, GROUND_Y_TILE, @platformer_platform.Ground)
  }

  push_range(blocks, 6, 10, 8, @platformer_platform.Brick)
  push_range(blocks, 14, 18, 7, @platformer_platform.Brick)
  push_range(blocks, 21, 25, 6, @platformer_platform.Brick)
  push_range(blocks, 30, 35, 8, @platformer_platform.Brick)
  push_range(blocks, 36, 40, 7, @platformer_platform.Brick)
  push_range(blocks, 45, 50, 6, @platformer_platform.Brick)
  push_range(blocks, 52, 58, 7, @platformer_platform.Brick)
  push_range(blocks, 63, 68, 6, @platformer_platform.Brick)
  push_range(blocks, 70, 76, 7, @platformer_platform.Brick)

  for tile_y in 5..<10 {
    push_tile(blocks, 18, tile_y, @platformer_platform.Brick)
    push_tile(blocks, 19, tile_y, @platformer_platform.Brick)
    push_tile(blocks, 50, tile_y, @platformer_platform.Brick)
    push_tile(blocks, 51, tile_y, @platformer_platform.Brick)
    push_tile(blocks, 68, tile_y, @platformer_platform.Brick)
  }

  push_range(blocks, 10, 13, 9, @platformer_platform.Spike)
  push_range(blocks, 25, 28, 9, @platformer_platform.Spike)
  push_range(blocks, 40, 43, 9, @platformer_platform.Spike)
  push_range(blocks, 58, 61, 9, @platformer_platform.Spike)
  push_range(blocks, 76, 81, 9, @platformer_platform.Spike)
  push_tile(blocks, 28, 8, @platformer_platform.Spring)
  push_tile(blocks, 43, 6, @platformer_platform.DashCrystal)
  push_tile(blocks, 61, 8, @platformer_platform.Spring)
  push_tile(blocks, 74, 5, @platformer_platform.DashCrystal)

  @platformer_platform.level(
    "Mirror Temple",
    tile_center(2, 9),
    tile_center(80, 8),
    vec2(34.0, 150.0),
    82.0 * TILE_SIZE,
    blocks,
  )
}

///|
fn all_levels() -> Array[@platformer_platform.LevelSpec] {
  [build_level_forsaken_cliff(), build_level_mirror_temple()]
}

///|
pub fn plugin_def() -> @platformer_platform.PlatformerPluginDef {
  @platformer_platform.plugin(
    @platformer_platform.meta("celeste", "Celeste"),
    all_levels(),
    @platformer_platform.ui_theme(
      "CELESTE CLASSIC",
      hud_hint="A/D move  SPACE/UP jump  C/Shift dash  R restart  F3 debug  ESC quit",
    ),
    movement=Some(
      @platformer_platform.movement_profile(
        move_speed=248.0,
        jump_speed=645.0,
        gravity=1760.0,
        max_fall_speed=1100.0,
        coyote_time=0.12,
        jump_buffer=0.14,
        max_air_dashes=1,
        dash_speed=690.0,
        dash_duration=0.16,
        dash_cooldown=0.08,
        allow_wall_jump=true,
        wall_slide_speed=165.0,
        wall_jump_speed_x=335.0,
        wall_jump_speed_y=640.0,
        wall_stamina_max=100.0,
        wall_stamina_drain_per_second=40.0,
        wall_jump_stamina_cost=25.0,
        spring_boost_speed=860.0,
      ),
    ),
  )
}
