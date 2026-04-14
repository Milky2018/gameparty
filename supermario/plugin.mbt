///|
const TILE_SIZE : Double = 48.0

///|
const SUPERMARIO_JUMP_SPEED : Double = 720.0

///|
const EXTRACTED_SPRITES_DIR : String = "assets/supermario/extracted"

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
fn extracted_frame(
  name : String,
  width : Double,
  height : Double,
) -> @platformer_platform.SpriteRegion {
  atlas("\{EXTRACTED_SPRITES_DIR}/\{name}.png", 0.0, 0.0, width, height)
}

///|
fn vec2(x : Double, y : Double) -> @math.Vec2 {
  @math.Vec2(x, y)
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
        player_idle_left_region=Some(extracted_frame("player_idle_left", 16.0, 28.0)),
        player_idle_right_region=Some(
          extracted_frame("player_idle_right", 16.0, 28.0),
        ),
        player_run_left_regions=Some([
          extracted_frame("player_run_left_0", 16.0, 28.0),
          extracted_frame("player_run_left_1", 16.0, 28.0),
          extracted_frame("player_run_left_2", 16.0, 28.0),
        ]),
        player_run_right_regions=Some([
          extracted_frame("player_run_right_0", 16.0, 28.0),
          extracted_frame("player_run_right_1", 16.0, 28.0),
          extracted_frame("player_run_right_2", 16.0, 28.0),
        ]),
        enemy_goomba_regions=Some([
          extracted_frame("enemy_goomba_walk_0", 16.0, 16.0),
          extracted_frame("enemy_goomba_walk_1", 16.0, 16.0),
        ]),
        enemy_koopa_regions=Some([
          extracted_frame("enemy_koopa_walk_0", 16.0, 27.0),
          extracted_frame("enemy_koopa_walk_1", 16.0, 27.0),
        ]),
        tile_ground_region=Some(extracted_frame("tile_ground", 16.0, 16.0)),
        tile_brick_region=Some(extracted_frame("tile_brick", 16.0, 16.0)),
        tile_pipe_region=Some(extracted_frame("tile_pipe_top", 16.0, 16.0)),
        tile_pipe_body_region=Some(extracted_frame("tile_pipe_body", 16.0, 16.0)),
        tile_spike_region=Some(extracted_frame("tile_spike", 16.0, 16.0)),
        tile_question_region=Some(extracted_frame("tile_question", 16.0, 16.0)),
        tile_used_region=Some(extracted_frame("tile_used", 16.0, 16.0)),
        background_path=Some("\{EXTRACTED_SPRITES_DIR}/background_02.png"),
      ),
    ),
    movement=Some(
      @platformer_platform.movement_profile(jump_speed=SUPERMARIO_JUMP_SPEED),
    ),
  )
}
