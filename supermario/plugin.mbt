///|
const TILE_SIZE : Double = 48.0

///|
const SUPERMARIO_JUMP_SPEED : Double = 720.0

///|
const SFC_MARIO_SHEET_PATH : String = "assets/supermario/sfc/runtime_mario.png"

///|
const SFC_ENEMIES_SHEET_PATH : String = "assets/supermario/sfc/runtime_enemies.png"

///|
const SFC_TILES_SHEET_PATH : String = "assets/supermario/sfc/runtime_tiles.png"

///|
const SFC_PIPES_SHEET_PATH : String = "assets/supermario/sfc/runtime_pipes.png"

///|
const SFC_GROUND_SHEET_PATH : String = "assets/supermario/sfc/tiles-ground_keyed.png"

///|
const SFC_BACKGROUND_PATH : String = "assets/supermario/sfc/runtime_background_02.png"

///|
const MARIO_FRAME_ORIGIN_X : Double = 8.0

///|
const MARIO_FRAME_ORIGIN_Y : Double = 76.0

///|
const MARIO_FRAME_STEP_X : Double = 40.0

///|
const MARIO_FRAME_STEP_Y : Double = 40.0

///|
const ENEMY_FRAME_ORIGIN_X : Double = 12.0

///|
const ENEMY_FRAME_ORIGIN_Y : Double = 160.0

///|
const ENEMY_FRAME_STEP_X : Double = 40.0

///|
const ENEMY_FRAME_STEP_Y : Double = 40.0

///|
fn atlas(
  path : String,
  x : Double,
  y : Double,
  w : Double,
  h : Double,
) -> @platformer_platform.SpriteRegion {
  @platformer_platform.sprite_region(path, x, y, w, h)
}

///|
fn vec2(x : Double, y : Double) -> @math.Vec2 {
  @math.Vec2(x, y)
}

///|
fn frame_from_grid(
  path : String,
  origin_x : Double,
  origin_y : Double,
  step_x : Double,
  step_y : Double,
  col : Int,
  row : Int,
  width? : Double = 16.0,
  height? : Double = 16.0,
) -> @platformer_platform.SpriteRegion {
  atlas(
    path,
    origin_x + col.to_double() * step_x,
    origin_y + row.to_double() * step_y,
    width,
    height,
  )
}

///|
fn mario_frame(
  col : Int,
  row : Int,
  width? : Double = 16.0,
  height? : Double = 28.0,
) -> @platformer_platform.SpriteRegion {
  frame_from_grid(
    SFC_MARIO_SHEET_PATH,
    MARIO_FRAME_ORIGIN_X,
    MARIO_FRAME_ORIGIN_Y,
    MARIO_FRAME_STEP_X,
    MARIO_FRAME_STEP_Y,
    col,
    row,
    width~,
    height~,
  )
}

///|
fn enemy_frame(
  col : Int,
  row : Int,
  width? : Double = 16.0,
  height? : Double = 16.0,
) -> @platformer_platform.SpriteRegion {
  frame_from_grid(
    SFC_ENEMIES_SHEET_PATH,
    ENEMY_FRAME_ORIGIN_X,
    ENEMY_FRAME_ORIGIN_Y,
    ENEMY_FRAME_STEP_X,
    ENEMY_FRAME_STEP_Y,
    col,
    row,
    width~,
    height~,
  )
}

///|
fn tile_frame(
  col : Int,
  row : Int,
  width? : Double = 16.0,
  height? : Double = 16.0,
) -> @platformer_platform.SpriteRegion {
  frame_from_grid(
    SFC_TILES_SHEET_PATH,
    0.0,
    0.0,
    16.0,
    16.0,
    col,
    row,
    width~,
    height~,
  )
}

///|
fn tile_frame_with_offset(
  x : Double,
  y : Double,
  width? : Double = 16.0,
  height? : Double = 16.0,
) -> @platformer_platform.SpriteRegion {
  atlas(SFC_TILES_SHEET_PATH, x, y, width, height)
}

///|
fn pipe_frame(
  col : Int,
  row : Int,
  width? : Double = 16.0,
  height? : Double = 16.0,
) -> @platformer_platform.SpriteRegion {
  frame_from_grid(
    SFC_PIPES_SHEET_PATH,
    0.0,
    0.0,
    16.0,
    16.0,
    col,
    row,
    width~,
    height~,
  )
}

///|
fn pipe_frame_with_offset(
  x : Double,
  y : Double,
  width? : Double = 16.0,
  height? : Double = 16.0,
) -> @platformer_platform.SpriteRegion {
  atlas(SFC_PIPES_SHEET_PATH, x, y, width, height)
}

///|
fn ground_frame(
  col : Int,
  row : Int,
  width? : Double = 16.0,
  height? : Double = 16.0,
) -> @platformer_platform.SpriteRegion {
  frame_from_grid(
    SFC_GROUND_SHEET_PATH,
    0.0,
    0.0,
    16.0,
    16.0,
    col,
    row,
    width~,
    height~,
  )
}

///|
fn build_level_one() -> @platformer_platform.LevelSpec {
  let blocks : Array[@platformer_platform.SolidBlock] = []
  let ground_y = 10.0 * TILE_SIZE
  for i in 0..<90 {
    blocks.push(
      @platformer_platform.block(
        vec2((i.to_double() + 0.5) * TILE_SIZE, ground_y + TILE_SIZE * 0.5),
        vec2(TILE_SIZE, TILE_SIZE),
        @platformer_platform.Ground,
      ),
    )
  }
  for i in 14..<21 {
    blocks.push(
      @platformer_platform.block(
        vec2((i.to_double() + 0.5) * TILE_SIZE, 7.6 * TILE_SIZE),
        vec2(TILE_SIZE, TILE_SIZE),
        @platformer_platform.Brick,
      ),
    )
  }
  for i in 27..<31 {
    blocks.push(
      @platformer_platform.block(
        vec2((i.to_double() + 0.5) * TILE_SIZE, 6.2 * TILE_SIZE),
        vec2(TILE_SIZE, TILE_SIZE),
        @platformer_platform.Brick,
      ),
    )
  }
  for i in 40..<44 {
    blocks.push(
      @platformer_platform.block(
        vec2((i.to_double() + 0.5) * TILE_SIZE, 8.1 * TILE_SIZE),
        vec2(TILE_SIZE, TILE_SIZE),
        @platformer_platform.Brick,
      ),
    )
  }
  for i in 54..<60 {
    blocks.push(
      @platformer_platform.block(
        vec2((i.to_double() + 0.5) * TILE_SIZE, 6.2 * TILE_SIZE),
        vec2(TILE_SIZE, TILE_SIZE),
        @platformer_platform.Brick,
      ),
    )
  }
  for i in 67..<72 {
    blocks.push(
      @platformer_platform.block(
        vec2((i.to_double() + 0.5) * TILE_SIZE, 7.2 * TILE_SIZE),
        vec2(TILE_SIZE, TILE_SIZE),
        @platformer_platform.Brick,
      ),
    )
  }
  blocks.push(
    @platformer_platform.block(
      vec2(19.5 * TILE_SIZE, 6.6 * TILE_SIZE),
      vec2(TILE_SIZE, TILE_SIZE),
      @platformer_platform.QuestionMushroom,
      payload=Some(@platformer_platform.Mushroom),
    ),
  )
  blocks.push(
    @platformer_platform.block(
      vec2(29.5 * TILE_SIZE, 5.2 * TILE_SIZE),
      vec2(TILE_SIZE, TILE_SIZE),
      @platformer_platform.QuestionCoin,
      payload=Some(@platformer_platform.Coin),
    ),
  )
  blocks.push(
    @platformer_platform.block(
      vec2(58.5 * TILE_SIZE, 5.2 * TILE_SIZE),
      vec2(TILE_SIZE, TILE_SIZE),
      @platformer_platform.QuestionFlower,
      payload=Some(@platformer_platform.FireFlower),
    ),
  )
  for y in 8..<10 {
    blocks.push(
      @platformer_platform.block(
        vec2(9.5 * TILE_SIZE, (y.to_double() + 0.5) * TILE_SIZE),
        vec2(TILE_SIZE, TILE_SIZE),
        @platformer_platform.Pipe,
      ),
    )
    blocks.push(
      @platformer_platform.block(
        vec2(73.5 * TILE_SIZE, (y.to_double() + 0.5) * TILE_SIZE),
        vec2(TILE_SIZE, TILE_SIZE),
        @platformer_platform.Pipe,
      ),
    )
  }
  let enemy_spawns : Array[@platformer_platform.EnemySpawn] = [
    @platformer_platform.enemy_spawn(
      vec2(380.0, 9.2 * TILE_SIZE),
      320.0,
      620.0,
      facing_right=true,
    ),
    @platformer_platform.enemy_spawn(
      vec2(1120.0, 9.2 * TILE_SIZE),
      980.0,
      1360.0,
      facing_right=false,
      kind=@platformer_platform.Koopa,
    ),
    @platformer_platform.enemy_spawn(
      vec2(1730.0, 9.2 * TILE_SIZE),
      1600.0,
      1900.0,
      facing_right=true,
    ),
  ]
  @platformer_platform.level(
    "Green Plains",
    vec2(2.0 * TILE_SIZE, 8.8 * TILE_SIZE),
    vec2(86.8 * TILE_SIZE, 7.9 * TILE_SIZE),
    vec2(42.0, 180.0),
    90.0 * TILE_SIZE,
    blocks,
    enemy_spawns~,
  )
}

///|
fn build_level_two() -> @platformer_platform.LevelSpec {
  let blocks : Array[@platformer_platform.SolidBlock] = []
  let ground_y = 10.0 * TILE_SIZE
  for i in 0..<96 {
    if i >= 17 && i <= 20 {
      continue
    }
    if i >= 33 && i <= 35 {
      continue
    }
    if i >= 58 && i <= 61 {
      continue
    }
    blocks.push(
      @platformer_platform.block(
        vec2((i.to_double() + 0.5) * TILE_SIZE, ground_y + TILE_SIZE * 0.5),
        vec2(TILE_SIZE, TILE_SIZE),
        @platformer_platform.Ground,
      ),
    )
  }
  for i in 15..<22 {
    blocks.push(
      @platformer_platform.block(
        vec2((i.to_double() + 0.5) * TILE_SIZE, 7.8 * TILE_SIZE),
        vec2(TILE_SIZE, TILE_SIZE),
        @platformer_platform.Brick,
      ),
    )
  }
  for i in 31..<37 {
    blocks.push(
      @platformer_platform.block(
        vec2((i.to_double() + 0.5) * TILE_SIZE, 6.7 * TILE_SIZE),
        vec2(TILE_SIZE, TILE_SIZE),
        @platformer_platform.Brick,
      ),
    )
  }
  for i in 49..<55 {
    blocks.push(
      @platformer_platform.block(
        vec2((i.to_double() + 0.5) * TILE_SIZE, 7.2 * TILE_SIZE),
        vec2(TILE_SIZE, TILE_SIZE),
        @platformer_platform.Brick,
      ),
    )
  }
  for i in 64..<70 {
    blocks.push(
      @platformer_platform.block(
        vec2((i.to_double() + 0.5) * TILE_SIZE, 5.9 * TILE_SIZE),
        vec2(TILE_SIZE, TILE_SIZE),
        @platformer_platform.Brick,
      ),
    )
  }
  blocks.push(
    @platformer_platform.block(
      vec2(18.5 * TILE_SIZE, 6.8 * TILE_SIZE),
      vec2(TILE_SIZE, TILE_SIZE),
      @platformer_platform.QuestionCoin,
      payload=Some(@platformer_platform.Coin),
    ),
  )
  blocks.push(
    @platformer_platform.block(
      vec2(35.5 * TILE_SIZE, 5.8 * TILE_SIZE),
      vec2(TILE_SIZE, TILE_SIZE),
      @platformer_platform.QuestionMushroom,
      payload=Some(@platformer_platform.Mushroom),
    ),
  )
  blocks.push(
    @platformer_platform.block(
      vec2(67.5 * TILE_SIZE, 5.0 * TILE_SIZE),
      vec2(TILE_SIZE, TILE_SIZE),
      @platformer_platform.QuestionFlower,
      payload=Some(@platformer_platform.FireFlower),
    ),
  )
  for y in 8..<10 {
    blocks.push(
      @platformer_platform.block(
        vec2(10.5 * TILE_SIZE, (y.to_double() + 0.5) * TILE_SIZE),
        vec2(TILE_SIZE, TILE_SIZE),
        @platformer_platform.Pipe,
      ),
    )
    blocks.push(
      @platformer_platform.block(
        vec2(44.5 * TILE_SIZE, (y.to_double() + 0.5) * TILE_SIZE),
        vec2(TILE_SIZE, TILE_SIZE),
        @platformer_platform.Pipe,
      ),
    )
    blocks.push(
      @platformer_platform.block(
        vec2(78.5 * TILE_SIZE, (y.to_double() + 0.5) * TILE_SIZE),
        vec2(TILE_SIZE, TILE_SIZE),
        @platformer_platform.Pipe,
      ),
    )
  }
  let enemy_spawns : Array[@platformer_platform.EnemySpawn] = [
    @platformer_platform.enemy_spawn(
      vec2(420.0, 9.2 * TILE_SIZE),
      320.0,
      620.0,
      facing_right=true,
    ),
    @platformer_platform.enemy_spawn(
      vec2(970.0, 9.2 * TILE_SIZE),
      860.0,
      1180.0,
      facing_right=false,
      kind=@platformer_platform.Koopa,
    ),
    @platformer_platform.enemy_spawn(
      vec2(1560.0, 9.2 * TILE_SIZE),
      1450.0,
      1760.0,
      facing_right=true,
    ),
    @platformer_platform.enemy_spawn(
      vec2(2360.0, 9.2 * TILE_SIZE),
      2250.0,
      2600.0,
      facing_right=false,
      kind=@platformer_platform.Koopa,
    ),
  ]
  @platformer_platform.level(
    "Castle Gauntlet",
    vec2(2.0 * TILE_SIZE, 8.8 * TILE_SIZE),
    vec2(92.8 * TILE_SIZE, 7.9 * TILE_SIZE),
    vec2(42.0, 180.0),
    96.0 * TILE_SIZE,
    blocks,
    enemy_spawns~,
  )
}

///|
fn all_levels() -> Array[@platformer_platform.LevelSpec] {
  [build_level_one(), build_level_two()]
}

///|
pub fn plugin_def() -> @platformer_platform.PlatformerPluginDef {
  @platformer_platform.plugin(
    @platformer_platform.meta("supermario", "Super Mario"),
    all_levels(),
    @platformer_platform.ui_theme(
      "SUPER MARIO",
      hud_hint="A/D or arrows: move  SPACE/UP: jump  X/CTRL: fire  R: restart  F3: debug  ESC: quit",
    ),
    sprites=Some(
      @platformer_platform.sprite_pack(
        player_idle_region=Some(mario_frame(4, 0)),
        player_run_regions=Some([
          mario_frame(3, 1),
          mario_frame(4, 1),
          mario_frame(5, 1),
        ]),
        enemy_goomba_regions=Some([
          enemy_frame(0, 4, height=16.0),
          enemy_frame(1, 4, height=16.0),
        ]),
        enemy_koopa_regions=Some([
          enemy_frame(1, 0, height=27.0),
          enemy_frame(2, 0, height=27.0),
        ]),
        tile_ground_region=Some(ground_frame(44, 3)),
        tile_brick_region=Some(tile_frame(4, 0)),
        tile_pipe_region=Some(pipe_frame_with_offset(16.0, 81.0)),
        tile_pipe_body_region=Some(pipe_frame(1, 6)),
        tile_spike_region=Some(tile_frame(7, 16)),
        tile_question_region=Some(tile_frame_with_offset(207.0, 181.0)),
        tile_used_region=Some(tile_frame_with_offset(176.0, 160.0)),
        background_path=Some(SFC_BACKGROUND_PATH),
      ),
    ),
    movement=Some(
      @platformer_platform.movement_profile(jump_speed=SUPERMARIO_JUMP_SPEED),
    ),
  )
}
