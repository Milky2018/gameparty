///|
enum StageKind {
  Break
  Formation
  Boss
  Tutorial
} derive(Eq)

///|
priv enum FormationSpawnKind {
  Enemy(EnemyKind)
  Consumable(ConsumableKind)
}

///|
priv struct FormationSpawn {
  kind : FormationSpawnKind
  world_pos : @math.Vec2D
}

///|
priv struct Formation {
  members : Array[FormationSpawn]
  weight : Double
  period : Double
}

///|
priv struct RunStage {
  kind : StageKind
  label : String
  intro_text : String?
  duration : Double
  spawn_start_delay : Double
  formations : Array[Formation]
  boss_kind : EnemyKind?
  boss_world_pos : @math.Vec2D?
}

///|
fn spawn(kind : EnemyKind, x : Double, y : Double) -> FormationSpawn {
  { kind: Enemy(kind), world_pos: @math.Vec2D(x, y) }
}

///|
fn spawn_loot(kind : ConsumableKind, x : Double, y : Double) -> FormationSpawn {
  { kind: Consumable(kind), world_pos: @math.Vec2D(x, y) }
}

///|
fn formation(
  members : Array[FormationSpawn],
  period : Double,
  weight : Double,
) -> Formation {
  { members, period, weight }
}

///|
let easy_formations : Array[Formation] = [
  formation(
    [
      spawn(Pawn, -300.0, 500.0),
      spawn(Drone, 0.0, 1100.0),
      spawn(Pawn, 300.0, 800.0),
    ],
    9.0,
    1.0,
  ),
  formation(
    [
      spawn(StraferRight, 0.0, 800.0),
      spawn(StraferLeft, 0.0, 750.0),
      spawn(Pawn, 0.0, 1000.0),
      spawn(Hauler, 0.0, 500.0),
    ],
    9.0,
    1.0,
  ),
  formation(
    [
      spawn(Pawn, 300.0, 650.0),
      spawn(Pawn, 0.0, 600.0),
      spawn(Pawn, -300.0, 650.0),
    ],
    7.0,
    1.0,
  ),
  formation(
    [
      spawn(Drone, 0.0, 550.0),
      spawn(Drone, 50.0, 600.0),
      spawn(Drone, -50.0, 600.0),
    ],
    6.5,
    1.0,
  ),
  formation(
    [
      spawn(Pawn, 200.0, 600.0),
      spawn(Pawn, -200.0, 600.0),
      spawn(Drone, 0.0, 550.0),
    ],
    6.5,
    1.0,
  ),
  formation(
    [
      spawn(Drone, 200.0, 600.0),
      spawn(MoneyAsteroid, 0.0, 500.0),
      spawn(Pawn, 0.0, 650.0),
      spawn(Drone, -200.0, 600.0),
    ],
    6.5,
    1.0,
  ),
]

///|
let medium_formations : Array[Formation] = [
  formation(
    [
      spawn(Shelly, -150.0, 500.0),
      spawn(Pawn, 0.0, 500.0),
      spawn(Shelly, 150.0, 500.0),
    ],
    7.0,
    1.0,
  ),
  formation(
    [
      spawn(CrustlingRight, -150.0, 900.0),
      spawn(Shelly, 75.0, 800.0),
      spawn(CrustlingRight, 0.0, 700.0),
      spawn(Shelly, -75.0, 600.0),
      spawn(CrustlingRight, 150.0, 500.0),
    ],
    12.0,
    1.0,
  ),
  formation(
    [
      spawn(StraferRight, 0.0, 800.0),
      spawn(StraferLeft, 0.0, 750.0),
      spawn(Pawn, 0.0, 1000.0),
      spawn(Hauler, 0.0, 500.0),
    ],
    9.0,
    1.0,
  ),
  formation(
    [
      spawn(Pawn, 300.0, 650.0),
      spawn(Pawn, 200.0, 600.0),
      spawn(Pawn, -300.0, 650.0),
      spawn(Pawn, -200.0, 600.0),
    ],
    7.0,
    1.0,
  ),
  formation(
    [
      spawn(Drone, 0.0, 550.0),
      spawn(Drone, 100.0, 650.0),
      spawn(Drone, 50.0, 600.0),
      spawn(Drone, -100.0, 650.0),
      spawn(Drone, -50.0, 600.0),
    ],
    7.0,
    1.0,
  ),
  formation(
    [
      spawn(Pawn, 200.0, 600.0),
      spawn(Pawn, 250.0, 650.0),
      spawn(Pawn, -200.0, 600.0),
      spawn(Pawn, -250.0, 650.0),
      spawn(Drone, 0.0, 550.0),
    ],
    7.5,
    1.0,
  ),
  formation(
    [
      spawn(Drone, 180.0, 1000.0),
      spawn(Drone, -180.0, 1000.0),
      spawn(Hauler, 200.0, 500.0),
    ],
    6.5,
    0.5,
  ),
  formation(
    [
      spawn_loot(Money3, 0.0, 400.0),
      spawn(Missile, 0.0, 500.0),
      spawn(Missile, 200.0, 600.0),
      spawn(Missile, -200.0, 600.0),
      spawn(Missile, 400.0, 700.0),
      spawn(Missile, -400.0, 700.0),
    ],
    5.5,
    0.5,
  ),
  formation(
    [
      spawn(StraferRight, 200.0, 500.0),
      spawn(StraferRight, 250.0, 550.0),
      spawn(StraferRight, 300.0, 600.0),
      spawn(StraferRight, 350.0, 650.0),
      spawn(StraferLeft, -200.0, 525.0),
      spawn(StraferLeft, -250.0, 575.0),
      spawn(StraferLeft, -300.0, 625.0),
      spawn(StraferLeft, -350.0, 675.0),
    ],
    8.0,
    1.0,
  ),
  formation(
    [
      spawn(MissileLauncher, 200.0, 600.0),
      spawn(MoneyAsteroid, 0.0, 500.0),
      spawn(Pawn, 0.0, 650.0),
      spawn(MissileLauncher, -200.0, 600.0),
    ],
    6.5,
    1.0,
  ),
  formation(
    [
      spawn(Shelly, -125.0, 550.0),
      spawn(Shelly, -75.0, 500.0),
      spawn(Shelly, 75.0, 500.0),
      spawn(Shelly, 125.0, 550.0),
    ],
    13.0,
    1.0,
  ),
  formation(
    [
      spawn(Pawn, -400.0, 1000.0),
      spawn(Drone, 400.0, 1000.0),
      spawn(CrustlingLeft, 0.0, 950.0),
      spawn(CrustlingRight, 0.0, 800.0),
      spawn(CrustlingLeft, 0.0, 650.0),
      spawn(CrustlingRight, 0.0, 500.0),
    ],
    15.0,
    1.0,
  ),
  formation(
    [
      spawn(StraferRight, 0.0, 650.0),
      spawn(StraferLeft, 0.0, 600.0),
      spawn(MissileLauncher, 0.0, 550.0),
      spawn(Drone, 100.0, 550.0),
      spawn(Drone, -100.0, 550.0),
    ],
    6.5,
    1.0,
  ),
  formation(
    [
      spawn(Pawn, 300.0, 700.0),
      spawn(Pawn, 200.0, 650.0),
      spawn(Pawn, 100.0, 600.0),
      spawn(Pawn, -300.0, 700.0),
      spawn(Pawn, -200.0, 650.0),
      spawn(Pawn, -100.0, 600.0),
    ],
    6.5,
    1.0,
  ),
  formation(
    [
      spawn(Drone, 0.0, 550.0),
      spawn(Drone, 200.0, 700.0),
      spawn(Drone, 150.0, 675.0),
      spawn(Drone, 50.0, 600.0),
      spawn(Drone, -200.0, 700.0),
      spawn(Drone, -150.0, 675.0),
      spawn(Drone, -50.0, 600.0),
    ],
    8.0,
    1.0,
  ),
  formation(
    [
      spawn(Pawn, 200.0, 600.0),
      spawn(Drone, 200.0, 500.0),
      spawn(Pawn, -200.0, 600.0),
      spawn(Drone, -200.0, 500.0),
      spawn(MissileLauncher, 0.0, 550.0),
    ],
    7.5,
    1.0,
  ),
  formation(
    [
      spawn(MoneyAsteroid, 0.0, 500.0),
      spawn(MissileLauncher, 200.0, 600.0),
      spawn(MissileLauncher, -200.0, 600.0),
    ],
    5.5,
    0.2,
  ),
]

///|
let hard_formations : Array[Formation] = [
  formation(
    [
      spawn(Hauler, 0.0, 600.0),
      spawn(Shelly, 120.0, 1000.0),
      spawn(Shelly, -120.0, 1000.0),
      spawn(Shelly, 120.0, 900.0),
      spawn(Shelly, -120.0, 900.0),
      spawn(Shelly, 120.0, 800.0),
      spawn(Shelly, -120.0, 800.0),
      spawn(Pawn, -240.0, 700.0),
      spawn(Pawn, 240.0, 700.0),
    ],
    10.0,
    0.7,
  ),
  formation(
    [
      spawn(Drone, 0.0, 500.0),
      spawn(Shelly, 75.0, 525.0),
      spawn(Shelly, -75.0, 525.0),
      spawn(Drone, 150.0, 550.0),
      spawn(Drone, -150.0, 550.0),
      spawn(Shelly, 225.0, 575.0),
      spawn(Shelly, -225.0, 575.0),
      spawn(Drone, 300.0, 600.0),
      spawn(Drone, -300.0, 600.0),
    ],
    10.0,
    1.0,
  ),
  formation(
    [
      spawn(Pawn, 0.0, 500.0),
      spawn(Pawn, 75.0, 525.0),
      spawn(Pawn, -75.0, 525.0),
      spawn(Pawn, 150.0, 550.0),
      spawn(Pawn, -150.0, 550.0),
      spawn(Pawn, 225.0, 575.0),
      spawn(Pawn, -225.0, 575.0),
      spawn(Pawn, 300.0, 600.0),
      spawn(Pawn, -300.0, 600.0),
    ],
    10.0,
    1.0,
  ),
  formation(
    [
      spawn(Shelly, 50.0, 450.0),
      spawn(Shelly, -50.0, 450.0),
      spawn(Shelly, 200.0, 500.0),
      spawn(Shelly, 250.0, 450.0),
      spawn(Shelly, 150.0, 450.0),
      spawn(Shelly, -200.0, 500.0),
      spawn(Shelly, -250.0, 450.0),
      spawn(Shelly, -150.0, 450.0),
      spawn(Pawn, 0.0, 800.0),
    ],
    11.0,
    1.0,
  ),
  formation(
    [
      spawn(Drone, 0.0, 500.0),
      spawn(MissileLauncher, 120.0, 575.0),
      spawn(MissileLauncher, -120.0, 575.0),
      spawn(Pawn, 60.0, 700.0),
      spawn(Pawn, -60.0, 700.0),
    ],
    11.0,
    1.0,
  ),
  formation(
    [
      spawn(MoneyAsteroid, 0.0, 650.0),
      spawn(Shelly, 0.0, 550.0),
      spawn(Shelly, 0.0, 750.0),
      spawn(Shelly, 100.0, 650.0),
      spawn(Shelly, -100.0, 650.0),
      spawn(Drone, 75.0, 500.0),
      spawn(Drone, -75.0, 500.0),
    ],
    10.0,
    0.5,
  ),
  formation(
    [
      spawn(Missile, -400.0, 500.0),
      spawn(Missile, 400.0, 500.0),
      spawn(Missile, -200.0, 500.0),
      spawn(Missile, 200.0, 500.0),
      spawn(Missile, 0.0, 500.0),
      spawn(Drone, 0.0, 570.0),
      spawn(Drone, -80.0, 580.0),
      spawn(Drone, 80.0, 580.0),
      spawn(Drone, -160.0, 590.0),
      spawn(Drone, 160.0, 590.0),
    ],
    10.0,
    1.0,
  ),
  formation(
    [
      spawn(CrustlingRight, 100.0, 500.0),
      spawn(CrustlingLeft, -100.0, 500.0),
      spawn(CrustlingRight, 100.0, 650.0),
      spawn(CrustlingLeft, -100.0, 650.0),
      spawn(CrustlingRight, 100.0, 800.0),
      spawn(CrustlingLeft, -100.0, 800.0),
      spawn(Shelly, 0.0, 550.0),
      spawn(Shelly, 0.0, 625.0),
    ],
    13.0,
    1.0,
  ),
  formation(
    [
      spawn(StraferRight, 100.0, 500.0),
      spawn(StraferLeft, -100.0, 500.0),
      spawn(StraferRight, 100.0, 650.0),
      spawn(StraferLeft, -100.0, 650.0),
      spawn(StraferRight, 100.0, 800.0),
      spawn(StraferLeft, -100.0, 800.0),
      spawn(Pawn, 0.0, 550.0),
      spawn(Pawn, 0.0, 700.0),
      spawn(Pawn, 0.0, 850.0),
      spawn(Missile, 450.0, 500.0),
      spawn(Missile, -450.0, 500.0),
    ],
    11.0,
    1.0,
  ),
]

///|
let asteroid_formations : Array[Formation] = [
  formation(
    [
      spawn(MoneyAsteroid, 30.0, 430.0),
      spawn(MoneyAsteroid, 260.0, 580.0),
      spawn(MoneyAsteroid, -190.0, 520.0),
    ],
    2.5,
    1.0,
  ),
  formation(
    [
      spawn(MoneyAsteroid, 90.0, 470.0),
      spawn(MoneyAsteroid, 10.0, 490.0),
      spawn(MoneyAsteroid, 170.0, 570.0),
      spawn(MoneyAsteroid, -310.0, 560.0),
    ],
    2.5,
    1.0,
  ),
  formation(
    [spawn(MoneyAsteroid, 350.0, 450.0), spawn(MoneyAsteroid, -430.0, 530.0)],
    2.5,
    1.0,
  ),
  formation(
    [spawn(MoneyAsteroid, -290.0, 450.0), spawn(MoneyAsteroid, -350.0, 590.0)],
    2.5,
    1.0,
  ),
  formation(
    [
      spawn(MoneyAsteroid, 350.0, 510.0),
      spawn(MoneyAsteroid, 410.0, 540.0),
      spawn(MoneyAsteroid, 20.0, 450.0),
    ],
    2.5,
    1.0,
  ),
  formation(
    [
      spawn(MoneyAsteroid, 70.0, 590.0),
      spawn(MoneyAsteroid, -100.0, 440.0),
      spawn(MoneyAsteroid, 20.0, 510.0),
    ],
    2.5,
    1.0,
  ),
  formation(
    [
      spawn(MoneyAsteroid, 60.0, 440.0),
      spawn(MoneyAsteroid, -430.0, 490.0),
      spawn(MoneyAsteroid, -390.0, 560.0),
      spawn(MoneyAsteroid, 430.0, 570.0),
      spawn(MoneyAsteroid, -210.0, 550.0),
    ],
    2.5,
    1.0,
  ),
]

///|
fn formation_stage(
  label : String,
  duration : Double,
  formations : Array[Formation],
) -> RunStage {
  {
    kind: Formation,
    label,
    intro_text: None,
    duration,
    spawn_start_delay: 1.0,
    formations,
    boss_kind: None,
    boss_world_pos: None,
  }
}

///|
fn formation_stage_intro(
  label : String,
  intro_text : String,
  duration : Double,
  formations : Array[Formation],
) -> RunStage {
  {
    kind: Formation,
    label,
    intro_text: Some(intro_text),
    duration,
    spawn_start_delay: 1.0,
    formations,
    boss_kind: None,
    boss_world_pos: None,
  }
}

///|
fn break_stage(label : String, duration : Double) -> RunStage {
  {
    kind: Break,
    label,
    intro_text: None,
    duration,
    spawn_start_delay: 0.0,
    formations: [],
    boss_kind: None,
    boss_world_pos: None,
  }
}

///|
fn boss_stage(kind : EnemyKind) -> RunStage {
  {
    kind: Boss,
    label: "Destroy the command ship!",
    intro_text: Some("Destroy the command ship!"),
    duration: 180.0,
    spawn_start_delay: 5.0,
    formations: [],
    boss_kind: Some(kind),
    boss_world_pos: Some(@math.Vec2D(0.0, 600.0)),
  }
}

///|
fn tutorial_stage(label : String) -> RunStage {
  {
    kind: Tutorial,
    label,
    intro_text: None,
    duration: 0.0,
    spawn_start_delay: 0.0,
    formations: [],
    boss_kind: None,
    boss_world_pos: None,
  }
}

///|
let run_stages : Array[RunStage] = [
  tutorial_stage("Tutorial"),
  // test_level_1
  formation_stage_intro(
    "Destroy the invaders!", "Destroy the invaders!", 20.0, easy_formations,
  ),
  break_stage("Break", 9.0),
  formation_stage("Formation Invasion", 40.0, easy_formations),
  break_stage("Break", 9.0),
  formation_stage("Heavy Swarm", 60.0, medium_formations),
  break_stage("Prepare for command ship", 5.0),
  boss_stage(Ferritharax),
  // test_level_2
  formation_stage_intro(
    "Destroy the invaders!", "Destroy the invaders!", 20.0, medium_formations,
  ),
  break_stage("Break", 9.0),
  formation_stage("Formation Invasion", 40.0, medium_formations),
  break_stage("Break", 9.0),
  formation_stage("Heavy Swarm", 60.0, medium_formations),
  break_stage("Prepare for command ship", 5.0),
  boss_stage(MechaFerritharax),
  // test_level_3
  formation_stage_intro(
    "Harvest the Asteroids!", "Harvest the Asteroids!", 20.0, asteroid_formations,
  ),
  break_stage("Break", 9.0),
  formation_stage("Destroy the invaders!", 20.0, hard_formations),
  break_stage("Break", 9.0),
  formation_stage("Formation Invasion", 40.0, hard_formations),
  break_stage("Break", 9.0),
  formation_stage("Heavy Swarm", 60.0, hard_formations),
  break_stage("Prepare for command ship", 5.0),
  boss_stage(MechaSaucetron),
]

///|
fn current_stage() -> RunStage? {
  run_stages.get(game_state.stage_index)
}

///|
fn spawn_from_world(world_pos : @math.Vec2D, radius : Double) -> @math.Vec2D {
  let x = VIEWPORT_WIDTH / 2.0 + world_pos[X] * WORLD_X_SCALE
  let y = -40.0 - (world_pos[Y] - 500.0) * WORLD_Y_SCALE
  @math.Vec2D(clamp(x, radius, VIEWPORT_WIDTH - radius), y)
}

///|
fn spawn_from_world_for(
  kind : EnemyKind,
  world_pos : @math.Vec2D,
) -> @math.Vec2D {
  spawn_from_world(world_pos, enemy_radius(kind))
}

///|
fn enter_stage() -> Unit {
  if current_stage() is Some(stage) {
    game_state.stage_elapsed = 0.0
    game_state.stage_spawn_timer = stage.spawn_start_delay
    game_state.stage_label = stage.label
    game_state.boss_spawned = false
    if stage.intro_text is Some(intro_text) {
      game_state.center_intro_text = intro_text
      game_state.center_intro_timer = 5.0
    } else {
      game_state.center_intro_text = ""
      game_state.center_intro_timer = 0.0
    }
    if stage.kind is Tutorial {
      reset_tutorial_lesson()
    } else {
      game_state.allow_move = true
      game_state.allow_main_attack = true
      game_state.allow_special = true
    }
  } else {
    game_state.stage_elapsed = 0.0
    game_state.stage_spawn_timer = 0.0
    game_state.stage_label = "Run Clear"
    game_state.boss_spawned = false
    game_state.center_intro_text = ""
    game_state.center_intro_timer = 0.0
  }
  if game_state.screen is InGame {
    set_background(Game)
  }
}
