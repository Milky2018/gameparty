///|
const SPAWN_SEARCH_RADIUS : Int = 96

///|
const SPAWN_SEARCH_STEP : Int = 4

///|
const SPAWN_TARGET_HEIGHT : Int = SEA_LEVEL + 2

///|
const SPAWN_MIN_HEIGHT : Int = SEA_LEVEL - 6

///|
const SPAWN_MAX_HEIGHT : Int = SEA_LEVEL + 28

///|
const SPAWN_HEADROOM : Int = 4

///|
const SPAWN_GOOD_HEIGHT_DELTA : Int = 6

///|
const SPAWN_GOOD_SLOPE_MAX : Int = 12

///|
const SPAWN_FOOT_HALF_WIDTH : Float = 0.34F

///|
fn world_block_long_id(world : World, wx : Int, wy : Int, wz : Int) -> UInt {
  let chunk_x = wx >> SHIFT_X
  let chunk_y = wy >> SHIFT_Y
  let chunk_z = wz >> SHIFT_Z
  let chunk = world.generate_chunk(chunk_x, chunk_y, chunk_z)
  let (rx, ry, rz) = get_relative_block_xyz(wx, wy, wz)
  chunk.get_tile(rx, ry, rz)
}

///|
fn spawn_surface_is_walkable(
  world : World,
  wx : Int,
  wz : Int,
  surface : Int,
) -> Bool {
  let min_x = 0.5F - SPAWN_FOOT_HALF_WIDTH
  let max_x = 0.5F + SPAWN_FOOT_HALF_WIDTH
  let min_z = 0.5F - SPAWN_FOOT_HALF_WIDTH
  let max_z = 0.5F + SPAWN_FOOT_HALF_WIDTH
  let long_id = world_block_long_id(world, wx, surface, wz)
  guard @block.get_shape_desc(long_id) is Some(shape) else { return false }
  for box in shape.boxes {
    if min_x >= box.min[0] &&
      max_x <= box.max[0] &&
      min_z >= box.min[2] &&
      max_z <= box.max[2] &&
      box.max[1] > 0.0F {
      return true
    }
  }
  false
}

///|
fn spawn_has_headroom(world : World, wx : Int, wz : Int, surface : Int) -> Bool {
  for dy in 1..<=SPAWN_HEADROOM {
    if world_block_long_id(world, wx, surface + dy, wz) != @block.AIR_LONG_ID {
      return false
    }
  }
  world_block_long_id(world, wx, surface, wz) != @block.AIR_LONG_ID &&
  spawn_surface_is_walkable(world, wx, wz, surface)
}

///|
fn spawn_height_penalty(surface : Int) -> Int {
  (surface - SPAWN_TARGET_HEIGHT).abs()
}

///|
fn spawn_slope_penalty(world : World, wx : Int, wz : Int, surface : Int) -> Int {
  let north = surface_height(world, wx, wz - SPAWN_SEARCH_STEP)
  let south = surface_height(world, wx, wz + SPAWN_SEARCH_STEP)
  let west = surface_height(world, wx - SPAWN_SEARCH_STEP, wz)
  let east = surface_height(world, wx + SPAWN_SEARCH_STEP, wz)
  (north - surface).abs() +
  (south - surface).abs() +
  (west - surface).abs() +
  (east - surface).abs()
}

///|
pub fn find_spawn_column(world : World) -> (Int, Int, Int) {
  let fallback_surface = surface_height(world, 0, 0)
  let mut best_wx = 0
  let mut best_wz = 0
  let mut best_surface = fallback_surface
  let mut best_score = 1 << 30
  let mut found = false
  let ring_count = SPAWN_SEARCH_RADIUS / SPAWN_SEARCH_STEP
  for ring in 0..<=ring_count {
    let radius = ring * SPAWN_SEARCH_STEP
    for wx in -radius..<=radius {
      if wx % SPAWN_SEARCH_STEP != 0 {
        continue
      }
      for wz in -radius..<=radius {
        if wz % SPAWN_SEARCH_STEP != 0 {
          continue
        }
        if radius > 0 && wx.abs() != radius && wz.abs() != radius {
          continue
        }
        let surface = surface_height(world, wx, wz)
        if surface < SPAWN_MIN_HEIGHT || surface > SPAWN_MAX_HEIGHT {
          continue
        }
        if !spawn_has_headroom(world, wx, wz, surface) {
          continue
        }
        let slope = spawn_slope_penalty(world, wx, wz, surface)
        let height_penalty = spawn_height_penalty(surface)
        let score = height_penalty * 10 + slope * 3 + wx.abs() + wz.abs()
        if !found || score < best_score {
          best_wx = wx
          best_wz = wz
          best_surface = surface
          best_score = score
          found = true
        }
        if height_penalty <= SPAWN_GOOD_HEIGHT_DELTA &&
          slope <= SPAWN_GOOD_SLOPE_MAX {
          return (wx, wz, surface)
        }
      }
    }
  }
  if found {
    (best_wx, best_wz, best_surface)
  } else {
    (0, 0, fallback_surface)
  }
}
