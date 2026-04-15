///|
test "circle-rect collision hits overlapping target" {
  let rect : @math.Rect = {
    position: @math.Vec2(10.0, 10.0),
    size: @math.Vec2(20.0, 20.0),
  }
  assert_true(rect_intersects_circle(rect, @math.Vec2(0.0, 0.0), 5.0) is false)
  assert_true(rect_intersects_circle(rect, @math.Vec2(18.0, 18.0), 5.0))
}

///|
test "wave counts grow by stage" {
  assert_true(wave_enemy_count(0) < wave_enemy_count(2))
  assert_true(wave_spawn_interval(0) > wave_spawn_interval(3))
}

///|
test "bullets can hit circles" {
  enemy_states.clear()
  bullet_states.clear()
  let enemy : EnemyState = {
    entity: @entity.Entity::new(),
    kind: Soldier,
    pos: @math.Vec2(100.0, 100.0),
    facing: Down,
    hp: 1,
    fire_cd: 0.0,
    alive: true,
  }
  enemy_states.push(enemy)
  let bullet : BulletState = {
    entity: @entity.Entity::new(),
    owner: Player,
    pos: @math.Vec2(102.0, 100.0),
    vel: @math.Vec2::zero(),
    ttl: 1.0,
    alive: true,
  }
  bullet_states.push(bullet)
  assert_true(bullet_hits_enemy(bullet) is Some(_))
  enemy_states.clear()
  bullet_states.clear()
}
