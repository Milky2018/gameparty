///|
test "rect intersection works for overlap and separation" {
  let a : @math.Rect = {
    position: @math.Vec2(0.0, 0.0),
    size: @math.Vec2(10.0, 10.0),
  }
  let b : @math.Rect = {
    position: @math.Vec2(5.0, 5.0),
    size: @math.Vec2(10.0, 10.0),
  }
  let c : @math.Rect = {
    position: @math.Vec2(20.0, 20.0),
    size: @math.Vec2(4.0, 4.0),
  }
  inspect(a.intersects(b), content="true")
  inspect(a.intersects(c), content="false")
}

///|
test "stomp logic only triggers when landing from above" {
  let player_before : @math.Rect = {
    position: @math.Vec2(0.0, 0.0),
    size: @math.Vec2(30.0, 40.0),
  }
  let player_after : @math.Rect = {
    position: @math.Vec2(0.0, 20.0),
    size: @math.Vec2(30.0, 40.0),
  }
  let enemy = {
    kind: Goomba,
    center: @math.Vec2(10.0, 55.0),
    velocity: @math.Vec2::zero(),
    facing_right: true,
    on_ground: true,
    alive: true,
    patrol_left: 0.0,
    patrol_right: 100.0,
  }
  player_state.val.velocity = @math.Vec2(0.0, 10.0)
  inspect(stomp_check(player_before, player_after, enemy), content="true")
  player_state.val.velocity = @math.Vec2(0.0, -10.0)
  inspect(stomp_check(player_before, player_after, enemy), content="false")
}

///|
test "enemy patrol turn helper respects bounds" {
  let enemy = {
    kind: Goomba,
    center: @math.Vec2(50.0, 50.0),
    velocity: @math.Vec2::zero(),
    facing_right: true,
    on_ground: true,
    alive: true,
    patrol_left: 20.0,
    patrol_right: 60.0,
  }
  inspect(enemy_should_turn(enemy, 61.0), content="true")
  inspect(enemy_should_turn(enemy, 40.0), content="false")
}

///|
test "special tiles collision classification is correct" {
  inspect(block_is_solid(Ground), content="true")
  inspect(block_is_solid(Spike), content="false")
  inspect(block_is_solid(DashCrystal), content="false")
  inspect(block_is_solid(Spring), content="false")
}

///|
test "damage player shrinks before losing" {
  player_state.val = {
    center: @math.Vec2(0.0, 0.0),
    velocity: @math.Vec2::zero(),
    facing_right: true,
    on_ground: true,
    coyote_timer: 0.0,
    jump_buffer: 0.0,
    hurt_timer: 0.0,
    startup_grace_timer: 0.0,
    fire_cooldown_timer: 0.0,
    dash_timer: 0.0,
    dash_cooldown_timer: 0.0,
    air_dashes_left: 0,
    wall_contact_dir: 0,
    dash_dir: @math.Vec2::zero(),
    wall_stamina: 0.0,
    spring_cooldown_timer: 0.0,
    power: Big,
    score: 0,
    coin_count: 0,
    alive: true,
  }
  game_phase.val = Playing
  damage_player()
  assert_true(player_state.val.power is Small)
  inspect(player_state.val.alive, content="true")
  player_state.val.hurt_timer = 0.0
  damage_player()
  assert_true(game_phase.val is Lost)
}

///|
test "default movement profile keeps mario baseline" {
  let movement = default_movement_profile()
  inspect(movement.max_air_dashes, content="0")
  inspect(movement.allow_wall_jump, content="false")
}

///|
test "apply item effect updates power and score counters" {
  player_state.val = {
    center: @math.Vec2(0.0, 0.0),
    velocity: @math.Vec2::zero(),
    facing_right: true,
    on_ground: true,
    coyote_timer: 0.0,
    jump_buffer: 0.0,
    hurt_timer: 0.0,
    startup_grace_timer: 0.0,
    fire_cooldown_timer: 0.0,
    dash_timer: 0.0,
    dash_cooldown_timer: 0.0,
    air_dashes_left: 0,
    wall_contact_dir: 0,
    dash_dir: @math.Vec2::zero(),
    wall_stamina: 0.0,
    spring_cooldown_timer: 0.0,
    power: Small,
    score: 0,
    coin_count: 0,
    alive: true,
  }
  apply_item_effect(Mushroom)
  assert_true(player_state.val.power is Big)
  apply_item_effect(FireFlower)
  assert_true(player_state.val.power is Fire)
  apply_item_effect(Coin)
  inspect(player_state.val.coin_count, content="1")
  inspect(player_state.val.score, content="100")
}
