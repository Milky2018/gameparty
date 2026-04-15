///|
fn minimal_plugin() -> TopDownShooterPluginDef {
  let legend : Map[Char, ShooterMapCellRule] = Map::new()
  legend.set('.', cell_rule(Floor, rgb(40U, 44U, 50U)))
  legend.set('#', cell_rule(Wall, rgb(70U, 76U, 84U), blocks=true))
  legend.set('P', cell_rule(PlayerSpawn, rgb(40U, 44U, 50U)))
  legend.set('B', cell_rule(BotSpawn, rgb(40U, 44U, 50U)))
  legend.set(
    'W',
    cell_rule(
      WeaponSpawn,
      rgb(40U, 44U, 50U),
      overlay_color=Some(rgb(120U, 180U, 255U)),
      pickup_id=Some("weapon_smg"),
    ),
  )
  plugin(
    meta("test", "Test"),
    map_def(["#####", "#PWB#", "#####"], legend, tile_size=32.0),
    "marine",
    "pistol",
    [
      actor_archetype(
        "marine",
        14.0,
        180.0,
        10,
        rgb(90U, 170U, 255U),
        rgb(240U, 246U, 255U),
      ),
    ],
    [
      weapon(
        "pistol",
        2,
        420.0,
        4.0,
        0.8,
        0.25,
        0.0,
        1,
        8,
        16,
        rgb(255U, 255U, 120U),
        rgb(255U, 255U, 120U),
      ),
      weapon(
        "smg",
        1,
        480.0,
        3.0,
        0.7,
        0.12,
        8.0,
        1,
        20,
        40,
        rgb(255U, 180U, 90U),
        rgb(255U, 180U, 90U),
      ),
    ],
    [
      pickup_spawn(
        "weapon_smg",
        Weapon,
        rgb(255U, 180U, 90U),
        "SMG",
        weapon_id=Some("smg"),
      ),
    ],
    respawn_rule(),
    [bot_profile("grunt", "marine", "pistol", 1, 240.0, 260.0, 220.0, 0.8, 0.4)],
    score_rules(match_seconds=60.0),
    ui_theme("TEST"),
  )
}

///|
test "validate_plugin accepts minimal shooter plugin" {
  assert_eq(validate_plugin(minimal_plugin()), None)
}

///|
test "validate_plugin rejects missing pickup definition" {
  let legend : Map[Char, ShooterMapCellRule] = Map::new()
  legend.set('.', cell_rule(Floor, rgb(20U, 20U, 20U)))
  legend.set('P', cell_rule(PlayerSpawn, rgb(20U, 20U, 20U)))
  legend.set(
    'W',
    cell_rule(WeaponSpawn, rgb(20U, 20U, 20U), pickup_id=Some("missing")),
  )
  let broken = plugin(
    meta("broken", "Broken"),
    map_def(["PW"], legend),
    "marine",
    "pistol",
    [
      actor_archetype(
        "marine",
        12.0,
        100.0,
        6,
        rgb(0U, 0U, 0U),
        rgb(255U, 255U, 255U),
      ),
    ],
    [
      weapon(
        "pistol",
        1,
        320.0,
        3.0,
        0.5,
        0.2,
        0.0,
        1,
        8,
        8,
        rgb(255U, 255U, 255U),
        rgb(255U, 255U, 255U),
      ),
    ],
    [],
    respawn_rule(),
    [],
    score_rules(),
    ui_theme("BROKEN"),
  )
  assert_true(validate_plugin(broken) is Some(_))
}

///|
test "try_reload refills from reserve only when magazine is empty" {
  let weapon = weapon(
    "pistol",
    1,
    1.0,
    1.0,
    1.0,
    1.0,
    0.0,
    1,
    12,
    24,
    rgb(1U, 1U, 1U),
    rgb(1U, 1U, 1U),
  )
  assert_eq(try_reload(3, 10, weapon), (3, 10))
  assert_eq(try_reload(0, 5, weapon), (5, 0))
}

///|
test "line_blocked detects a wall between points" {
  let rects : Array[@math.Rect] = [
    { position: @math.Vec2(20.0, 10.0), size: @math.Vec2(12.0, 20.0) },
  ]
  assert_true(
    line_blocked(rects, @math.Vec2(0.0, 20.0), @math.Vec2(60.0, 20.0)),
  )
  assert_false(line_blocked(rects, @math.Vec2(0.0, 0.0), @math.Vec2(10.0, 0.0)))
}
