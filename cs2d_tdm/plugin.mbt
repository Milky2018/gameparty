///|
fn build_legend() -> Map[Char, @topdown_shooter.ShooterMapCellRule] {
  let legend : Map[Char, @topdown_shooter.ShooterMapCellRule] = Map::new()
  legend.set(
    '.',
    @topdown_shooter.cell_rule(Floor, @topdown_shooter.rgb(26U, 31U, 38U)),
  )
  legend.set(
    ',',
    @topdown_shooter.cell_rule(Floor, @topdown_shooter.rgb(30U, 36U, 44U)),
  )
  legend.set(
    '#',
    @topdown_shooter.cell_rule(
      Wall,
      @topdown_shooter.rgb(55U, 64U, 78U),
      blocks=true,
      overlay_color=Some(@topdown_shooter.rgb(88U, 100U, 118U)),
    ),
  )
  legend.set(
    'C',
    @topdown_shooter.cell_rule(
      Cover,
      @topdown_shooter.rgb(40U, 47U, 57U),
      blocks=true,
      overlay_color=Some(@topdown_shooter.rgb(120U, 132U, 148U)),
    ),
  )
  legend.set(
    'P',
    @topdown_shooter.cell_rule(
      PlayerSpawn,
      @topdown_shooter.rgb(26U, 31U, 38U),
      overlay_color=Some(@topdown_shooter.rgb(74U, 164U, 255U)),
    ),
  )
  legend.set(
    'B',
    @topdown_shooter.cell_rule(
      BotSpawn,
      @topdown_shooter.rgb(26U, 31U, 38U),
      overlay_color=Some(@topdown_shooter.rgb(255U, 104U, 94U)),
      spawn_tag=Some("main"),
    ),
  )
  legend.set(
    'W',
    @topdown_shooter.cell_rule(
      WeaponSpawn,
      @topdown_shooter.rgb(26U, 31U, 38U),
      overlay_color=Some(@topdown_shooter.rgb(255U, 182U, 82U)),
      pickup_id=Some("weapon_smg"),
    ),
  )
  legend.set(
    'S',
    @topdown_shooter.cell_rule(
      WeaponSpawn,
      @topdown_shooter.rgb(26U, 31U, 38U),
      overlay_color=Some(@topdown_shooter.rgb(255U, 126U, 76U)),
      pickup_id=Some("weapon_shotgun"),
    ),
  )
  legend.set(
    'A',
    @topdown_shooter.cell_rule(
      AmmoSpawn,
      @topdown_shooter.rgb(26U, 31U, 38U),
      overlay_color=Some(@topdown_shooter.rgb(255U, 242U, 105U)),
      pickup_id=Some("ammo_box"),
    ),
  )
  legend.set(
    'H',
    @topdown_shooter.cell_rule(
      HealSpawn,
      @topdown_shooter.rgb(26U, 31U, 38U),
      overlay_color=Some(@topdown_shooter.rgb(95U, 226U, 128U)),
      pickup_id=Some("medkit"),
    ),
  )
  legend
}

///|
fn on_match_start(snapshot : @topdown_shooter.ShooterRuntimeSnapshot) -> Unit {
  println("[cs2d_tdm] start time=\{snapshot.time_left.to_int()}")
}

///|
fn on_actor_killed(
  snapshot : @topdown_shooter.ShooterRuntimeSnapshot,
  label : String,
) -> Unit {
  println(
    "[cs2d_tdm] killed=\{label} score=\{snapshot.score} kills=\{snapshot.kills} deaths=\{snapshot.deaths}",
  )
}

///|
fn on_pickup(
  snapshot : @topdown_shooter.ShooterRuntimeSnapshot,
  id : String,
) -> Unit {
  println(
    "[cs2d_tdm] pickup=\{id} weapon=\{snapshot.active_weapon_id} ammo=\{snapshot.ammo_in_magazine}/\{snapshot.reserve_ammo}",
  )
}

///|
pub let plugin : @topdown_shooter.TopDownShooterPluginDef = @topdown_shooter.plugin(
  @topdown_shooter.meta("cs2d_tdm", "CS2D TDM Proto"),
  @topdown_shooter.map_def(
    [
      "########################", "#P..,....C....,....B...#", "#..####.....####....A..#",
      "#..#..#........#..C....#", "#..#..#..W.....#.......#", "#..####....C...####..B.#",
      "#.............,....S...#", "#.B..####.....####.....#", "#....#..#..H.....#..C..#",
      "#....#..#........#.....#", "#..A.####....C...####B.#", "#....,......W........,.#",
      "########################",
    ],
    build_legend(),
    tile_size=46.0,
  ),
  "marine",
  "pistol",
  [
    @topdown_shooter.actor_archetype(
      "marine",
      15.0,
      212.0,
      10,
      @topdown_shooter.rgb(76U, 158U, 255U),
      @topdown_shooter.rgb(235U, 243U, 255U),
    ),
    @topdown_shooter.actor_archetype(
      "bot_light",
      14.0,
      186.0,
      7,
      @topdown_shooter.rgb(244U, 96U, 82U),
      @topdown_shooter.rgb(255U, 236U, 220U),
    ),
    @topdown_shooter.actor_archetype(
      "bot_heavy",
      16.0,
      154.0,
      12,
      @topdown_shooter.rgb(255U, 145U, 54U),
      @topdown_shooter.rgb(255U, 246U, 214U),
    ),
  ],
  [
    @topdown_shooter.weapon(
      "pistol",
      2,
      520.0,
      4.0,
      1.1,
      0.28,
      2.0,
      1,
      12,
      36,
      @topdown_shooter.rgb(255U, 243U, 133U),
      @topdown_shooter.rgb(255U, 243U, 133U),
    ),
    @topdown_shooter.weapon(
      "smg",
      1,
      560.0,
      3.0,
      0.95,
      0.12,
      10.0,
      1,
      24,
      72,
      @topdown_shooter.rgb(255U, 192U, 92U),
      @topdown_shooter.rgb(255U, 182U, 82U),
    ),
    @topdown_shooter.weapon(
      "shotgun",
      1,
      450.0,
      3.5,
      0.52,
      0.78,
      24.0,
      5,
      6,
      24,
      @topdown_shooter.rgb(255U, 126U, 76U),
      @topdown_shooter.rgb(255U, 126U, 76U),
    ),
  ],
  [
    @topdown_shooter.pickup_spawn(
      "weapon_smg",
      Weapon,
      @topdown_shooter.rgb(255U, 182U, 82U),
      "SMG",
      weapon_id=Some("smg"),
      respawn_seconds=10.0,
    ),
    @topdown_shooter.pickup_spawn(
      "weapon_shotgun",
      Weapon,
      @topdown_shooter.rgb(255U, 126U, 76U),
      "SG",
      weapon_id=Some("shotgun"),
      respawn_seconds=13.0,
    ),
    @topdown_shooter.pickup_spawn(
      "ammo_box",
      Ammo,
      @topdown_shooter.rgb(255U, 242U, 105U),
      "AM",
      ammo_amount=18,
      respawn_seconds=8.0,
    ),
    @topdown_shooter.pickup_spawn(
      "medkit",
      Heal,
      @topdown_shooter.rgb(95U, 226U, 128U),
      "HP",
      heal_amount=4,
      respawn_seconds=12.0,
    ),
  ],
  @topdown_shooter.respawn_rule(delay_seconds=2.4, invuln_seconds=1.0),
  [
    @topdown_shooter.bot_profile(
      "skirmisher",
      "bot_light",
      "pistol",
      3,
      280.0,
      320.0,
      240.0,
      1.0,
      0.5,
      spawn_tag=Some("main"),
    ),
    @topdown_shooter.bot_profile(
      "bruiser",
      "bot_heavy",
      "smg",
      2,
      260.0,
      300.0,
      210.0,
      0.85,
      0.65,
      spawn_tag=Some("main"),
    ),
  ],
  @topdown_shooter.score_rules(
    match_seconds=180.0,
    kill_score=100,
    death_penalty=25,
    streak_bonus_step=3,
  ),
  @topdown_shooter.ui_theme(
    "CS2D TDM PROTO",
    hud_hint="WASD move  Mouse aim  LMB fire  R restart  ESC quit",
    background_color=@topdown_shooter.rgb(18U, 26U, 38U),
    panel_color=@topdown_shooter.rgb(10U, 16U, 24U, a=0.84),
    accent_color=@topdown_shooter.rgb(231U, 241U, 252U),
  ),
  hooks=Some(
    @topdown_shooter.hooks(
      on_match_start=Some(on_match_start),
      on_actor_killed=Some(on_actor_killed),
      on_pickup_taken=Some(on_pickup),
    ),
  ),
)
