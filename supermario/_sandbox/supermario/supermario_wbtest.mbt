///|
test "rect intersection works for overlap and separation" {
  let a : @math.Rect = { position: @math.Vec2(0.0, 0.0), size: @math.Vec2(10.0, 10.0) }
  let b : @math.Rect = { position: @math.Vec2(5.0, 5.0), size: @math.Vec2(10.0, 10.0) }
  let c : @math.Rect = { position: @math.Vec2(20.0, 20.0), size: @math.Vec2(4.0, 4.0) }
  inspect(a.intersects(b), content="true")
  inspect(a.intersects(c), content="false")
}

///|
test "stomp logic only triggers when landing from above" {
  let player_before : @math.Rect = { position: @math.Vec2(0.0, 0.0), size: @math.Vec2(30.0, 40.0) }
  let player_after : @math.Rect = { position: @math.Vec2(0.0, 20.0), size: @math.Vec2(30.0, 40.0) }
  let enemy = {
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
