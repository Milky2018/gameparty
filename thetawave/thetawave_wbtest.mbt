///|
fn is_entity_visible(entity : @entity.Entity) -> Bool {
  @visibility.visibilities().get(entity).unwrap_or(Visible) is Visible
}

///|
fn assert_entity_visible(
  entity : @entity.Entity,
  expected : Bool,
) -> Unit raise {
  assert_eq(is_entity_visible(entity), expected)
}

///|
fn setup_test_text_entity(entity : @entity.Entity, text : TextState) -> Unit {
  setup_text_entity(entity, text, @math.Vec2::zero())
}

///|
fn assert_vec2_eq(
  actual : @math.Vec2,
  expected_x : Double,
  expected_y : Double,
) -> Unit raise {
  assert_eq(actual[X], expected_x)
  assert_eq(actual[Y], expected_y)
}

///|
test "clamp keeps value inside bounds" {
  assert_eq(clamp(5.0, 0.0, 10.0), 5.0)
  assert_eq(clamp(-1.0, 0.0, 10.0), 0.0)
  assert_eq(clamp(42.0, 0.0, 10.0), 10.0)
}

///|
test "overlaps checks circle intersection" {
  assert_true(overlaps(@math.Vec2(0.0, 0.0), 3.0, @math.Vec2(5.0, 0.0), 2.0))
  assert_true(!overlaps(@math.Vec2(0.0, 0.0), 2.0, @math.Vec2(5.1, 0.0), 2.0))
}

///|
test "campaign includes three ordered boss stages" {
  let boss_kinds = []
  for stage in run_stages {
    if stage.kind is Boss && stage.boss_kind is Some(kind) {
      boss_kinds.push(kind)
    }
  }
  assert_eq(boss_kinds.length(), 3)
  assert_true(boss_kinds[0] is Ferritharax)
  assert_true(boss_kinds[1] is MechaFerritharax)
  assert_true(boss_kinds[2] is MechaSaucetron)
}

///|
test "campaign starts with tutorial stage" {
  assert_true(run_stages.length() >= 1)
  assert_true(run_stages[0].kind is Tutorial)
  assert_true(run_stages[0].label == "Tutorial")
}

///|
test "all boss kinds use boss drop list with gain projectiles" {
  assert_true(drop_list_for_enemy(Ferritharax) is Boss)
  assert_true(drop_list_for_enemy(MechaFerritharax) is Boss)
  assert_true(drop_list_for_enemy(MechaSaucetron) is Boss)
  let mut has_gain_projectiles = false
  for rule in drop_rules(Boss) {
    if rule.kind is GainProjectiles {
      has_gain_projectiles = true
      break
    }
  }
  assert_true(has_gain_projectiles)
  assert_eq(boss_item_drops.length(), 1)
  assert_true(boss_item_drops[0] is EnhancedPlating)
}

///|
test "campaign includes asteroid and hard phases before final boss" {
  assert_true(run_stages.length() >= 24)
  assert_true(run_stages[15].label == "Harvest the Asteroids!")
  assert_true(run_stages[17].label == "Destroy the invaders!")
  assert_true(run_stages[23].boss_kind is Some(MechaSaucetron))
}

///|
test "medium formations include money3 consumable ambush" {
  let mut found_money3 = false
  for formation in medium_formations {
    for spawn in formation.members {
      if spawn.kind is Consumable(Money3) {
        found_money3 = true
        break
      }
    }
    if found_money3 {
      break
    }
  }
  assert_true(found_money3)
}

///|
test "boss enemies use larger collision radius" {
  assert_eq(enemy_radius(Pawn), ENEMY_HALF_SIZE)
  assert_eq(enemy_radius(Hauler), 10.0)
  assert_eq(enemy_radius(Ferritharax), 22.0)
  assert_eq(enemy_radius(MechaFerritharax), 22.0)
  assert_eq(enemy_radius(MechaSaucetron), 22.0)
}

///|
test "enhanced plating increases max hull and fully heals" {
  let old_max_hull = game_state.max_hull
  let old_hull = game_state.hull
  let old_plating_count = game_state.plating_count
  game_state.max_hull = 80
  game_state.hull = 24
  game_state.plating_count = 0

  apply_item(EnhancedPlating)

  assert_eq(game_state.max_hull, 180)
  assert_eq(game_state.hull, 180)
  assert_eq(game_state.plating_count, 1)

  game_state.max_hull = old_max_hull
  game_state.hull = old_hull
  game_state.plating_count = old_plating_count
}

///|
test "cooldown multiplier decays as money increases" {
  let old_money = game_state.money
  let old_base = game_state.base_cooldown_multiplier
  let old_cooldown = game_state.cooldown_multiplier

  game_state.base_cooldown_multiplier = 2.0
  game_state.money = 0
  refresh_cooldown_multiplier()
  let cooldown_at_zero = game_state.cooldown_multiplier

  game_state.money = 30
  refresh_cooldown_multiplier()
  let cooldown_at_thirty = game_state.cooldown_multiplier

  assert_true(cooldown_at_zero > cooldown_at_thirty)
  assert_true(cooldown_at_thirty > 1.0)

  game_state.money = old_money
  game_state.base_cooldown_multiplier = old_base
  game_state.cooldown_multiplier = old_cooldown
}

///|
test "tutorial parameters match upstream baseline" {
  assert_eq(TUTORIAL_DIRECTION_SECONDS, 0.5)
  assert_eq(TUTORIAL_SPAWN_DELAY_SECONDS, 2.0)

  let old_slot1_destroy = game_state.tutorial_slot1_destroy
  let old_slot1_protect = game_state.tutorial_slot1_protect
  let old_slot2_destroy = game_state.tutorial_slot2_destroy

  reset_tutorial_lesson()
  assert_eq(game_state.tutorial_slot1_destroy, 3)
  assert_eq(game_state.tutorial_slot1_protect, 1)
  assert_eq(game_state.tutorial_slot2_destroy, 3)

  game_state.tutorial_slot1_destroy = old_slot1_destroy
  game_state.tutorial_slot1_protect = old_slot1_protect
  game_state.tutorial_slot2_destroy = old_slot2_destroy
}

///|
test "enemy atlas frame sizing never exceeds source spritesheet bounds" {
  let s = GAMEPLAY_SPRITE_SCALE

  // 3-frame atlases
  assert_true(20.0 * s * 3.0 <= 60.0) // pawn
  assert_true(20.0 * s * 3.0 <= 60.0) // drone
  assert_true(20.0 * s * 3.0 <= 60.0) // tutorial drone
  assert_true(24.0 * s * 3.0 <= 72.0) // shelly
  assert_true(26.0 * s * 3.0 <= 78.0) // strafer
  assert_true(23.0 * s * 3.0 <= 69.0) // missile launcher
  assert_true(38.0 * s * 3.0 <= 114.0) // crustling
  assert_true(68.0 * s * 3.0 <= 204.0) // ferritharax
  assert_true(42.0 * s * 3.0 <= 126.0) // mecha ferritharax
  assert_true(46.0 * s * 3.0 <= 138.0) // mecha saucetron

  // 4-frame atlas
  assert_true(11.0 * s * 4.0 <= 44.0) // missile

  // Height checks
  assert_true(20.0 * s <= 20.0)
  assert_true(20.0 * s <= 20.0)
  assert_true(21.0 * s <= 21.0)
  assert_true(25.0 * s <= 25.0)
  assert_true(14.0 * s <= 14.0)
  assert_true(28.0 * s <= 28.0)
  assert_true(20.0 * s <= 20.0)
  assert_true(29.0 * s <= 29.0)
  assert_true(49.0 * s <= 49.0)
  assert_true(48.0 * s <= 48.0)
  assert_true(50.0 * s <= 50.0)
}

///|
fn clear_enemies_for_test() -> Unit {
  let entities = []
  for entity, _ in enemies {
    entities.push(entity)
  }
  for entity in entities {
    enemies.remove(entity)
  }
}

///|
fn make_enemy_for_test(kind : EnemyKind, hp : Int) -> Enemy {
  let archetype = enemy_archetype(kind)
  {
    kind,
    hp,
    speed_x: archetype.speed_x,
    speed_y: archetype.speed_y,
    collision_damage: archetype.collision_damage,
    escape_defense_delta: archetype.escape_defense_delta,
    movement: archetype.movement,
    horizontal_dir: archetype.horizontal_dir,
    shooter: archetype.shooter,
    shoot_interval: archetype.shoot_interval,
    shoot_cooldown: archetype.initial_shoot_delay,
    boss_phase: 0,
    boss_phase_elapsed: 0.0,
    boss_left_pawn_timer: 7.0,
    boss_left_drone_timer: 5.0,
    boss_right_pawn_timer: 7.0,
    boss_right_drone_timer: 5.0,
    boss_left_missile_timer: ferritharax_missile_period(kind),
    boss_right_missile_timer: ferritharax_missile_period(kind),
    boss_left_weapon_timer: if has_ferritharax_arm_weapons(kind) {
      3.0
    } else {
      9999.0
    },
    boss_right_weapon_timer: if has_ferritharax_arm_weapons(kind) {
      3.0
    } else {
      9999.0
    },
  }
}

///|
fn absd(value : Double) -> Double {
  if value < 0.0 {
    -value
  } else {
    value
  }
}

///|
test "clamp_int keeps integer value inside bounds" {
  assert_eq(clamp_int(3, 0, 10), 3)
  assert_eq(clamp_int(-5, 0, 10), 0)
  assert_eq(clamp_int(99, 0, 10), 10)
}

///|
test "move_towards helpers cap travel distance per tick" {
  assert_eq(move_towards_axis(0.0, 10.0, 3.0), 3.0)
  assert_eq(move_towards_axis(10.0, 0.0, 3.0), 7.0)
  assert_eq(move_towards_axis(0.0, 2.0, 3.0), 2.0)

  let next = move_towards(
    @math.Vec2(0.0, 0.0),
    @math.Vec2(10.0, -10.0),
    3.0,
    4.0,
  )
  assert_eq(next[X], 3.0)
  assert_eq(next[Y], -4.0)
}

///|
test "advance_periodic_timer supports zero and multi trigger cases" {
  let (timer1, count1) = advance_periodic_timer(1.0, 0.5, 0.2)
  assert_eq(timer1, 0.8)
  assert_eq(count1, 0)

  let (timer2, count2) = advance_periodic_timer(0.1, 0.5, 1.2)
  assert_true(absd(timer2 - 0.4) < 0.0000001)
  assert_eq(count2, 3)
}

///|
test "character config values match intended archetypes" {
  let captain = character_config(Captain)
  assert_eq(captain.name, "Captain")
  assert_eq(captain.speed, 300.0)
  assert_eq(captain.max_hull, 80)
  assert_true(captain.projectile_kind is Blast)
  assert_true(captain.special_ability is MegaBlast)

  let juggernaut = character_config(Juggernaut)
  assert_eq(juggernaut.name, "Juggernaut")
  assert_eq(juggernaut.speed, 250.0)
  assert_eq(juggernaut.max_hull, 140)
  assert_true(juggernaut.projectile_kind is Bullet)
  assert_true(juggernaut.special_ability is Charge)
}

///|
test "character stat percents are normalized and distinct" {
  let stats : Array[CharacterStatType] = [
    Damage,
    Health,
    Range,
    FireRate,
    Size,
    Speed,
  ]
  for stat in stats {
    let captain = character_stat_percent(Captain, stat)
    let juggernaut = character_stat_percent(Juggernaut, stat)
    assert_true(captain >= 0.0 && captain <= 1.0)
    assert_true(juggernaut >= 0.0 && juggernaut <= 1.0)
  }
  assert_true(
    character_stat_percent(Captain, Range) >
    character_stat_percent(Juggernaut, Range),
  )
  assert_true(
    character_stat_percent(Juggernaut, Health) >
    character_stat_percent(Captain, Health),
  )
}

///|
test "character carousel neighbors wrap correctly for two characters" {
  let (left_captain, center_captain, right_captain) = character_carousel_neighbors(
    Captain,
  )
  assert_true(left_captain is Juggernaut)
  assert_true(center_captain is Captain)
  assert_true(right_captain is Juggernaut)

  let (left_juggernaut, center_juggernaut, right_juggernaut) = character_carousel_neighbors(
    Juggernaut,
  )
  assert_true(left_juggernaut is Captain)
  assert_true(center_juggernaut is Juggernaut)
  assert_true(right_juggernaut is Captain)
}

///|
test "ferritharax family helper functions remain internally consistent" {
  assert_true(is_ferritharax_family(Ferritharax))
  assert_true(is_ferritharax_family(MechaFerritharax))
  assert_true(is_ferritharax_family(MechaSaucetron))
  assert_true(!is_ferritharax_family(Pawn))

  assert_eq(ferritharax_attack_duration(Ferritharax), 10.0)
  assert_eq(ferritharax_attack_duration(MechaFerritharax), 8.0)
  assert_eq(ferritharax_attack_duration(MechaSaucetron), 7.0)

  assert_eq(ferritharax_missile_period(Ferritharax), 5.0)
  assert_eq(ferritharax_missile_period(MechaFerritharax), 7.0)
  assert_eq(ferritharax_missile_period(MechaSaucetron), 5.5)

  assert_true(!has_ferritharax_arm_weapons(Ferritharax))
  assert_true(has_ferritharax_arm_weapons(MechaFerritharax))
  assert_true(has_ferritharax_arm_weapons(MechaSaucetron))
}

///|
test "ferritharax phase logic uses protect windows and deterministic targets" {
  assert_true(!ferritharax_phase_is_protect(0))
  assert_true(ferritharax_phase_is_protect(1))
  assert_true(!ferritharax_phase_is_protect(2))
  assert_true(ferritharax_phase_is_protect(3))

  assert_eq(
    ferritharax_phase_duration(Ferritharax, 1),
    FERRITHARAX_PROTECT_DURATION,
  )
  assert_eq(ferritharax_phase_duration(MechaSaucetron, 0), 7.0)

  let center = ferritharax_phase_target(Ferritharax, 0)
  let left = ferritharax_phase_target(Ferritharax, 3)
  let right = ferritharax_phase_target(Ferritharax, 1)
  assert_true(left[X] < center[X])
  assert_true(right[X] > center[X])
}

///|
test "ferritharax arm offsets differ by side and variant" {
  assert_vec2_eq(
    ferritharax_arm_missile_offset(Ferritharax, true),
    -80.0,
    -76.0,
  )
  assert_vec2_eq(
    ferritharax_arm_missile_offset(Ferritharax, false),
    80.0,
    -76.0,
  )
  assert_vec2_eq(
    ferritharax_arm_missile_offset(MechaSaucetron, true),
    -82.0,
    -72.0,
  )

  assert_vec2_eq(
    ferritharax_arm_weapon_offset(MechaFerritharax, true),
    -77.0,
    -54.0,
  )
  assert_vec2_eq(
    ferritharax_arm_weapon_offset(MechaSaucetron, false),
    77.0,
    -52.0,
  )
}

///|
test "spawn_from_world clamps x into viewport bounds" {
  let left = spawn_from_world(@math.Vec2(-9999.0, 500.0), 20.0)
  assert_eq(left[X], 20.0)
  assert_eq(left[Y], -40.0)

  let right = spawn_from_world(@math.Vec2(9999.0, 500.0), 20.0)
  assert_eq(right[X], VIEWPORT_WIDTH - 20.0)
  assert_eq(right[Y], -40.0)

  let center = spawn_from_world(@math.Vec2(0.0, 350.0), 12.0)
  assert_eq(center[X], VIEWPORT_WIDTH / 2.0)
  assert_eq(center[Y], 5.0)
}

///|
test "current_stage reflects stage_index validity" {
  let old_stage_index = game_state.stage_index

  game_state.stage_index = 0
  assert_true(current_stage() is Some(_))

  game_state.stage_index = run_stages.length()
  assert_true(current_stage() is None)

  game_state.stage_index = old_stage_index
}

///|
test "current level name follows stage bands" {
  let old_stage_index = game_state.stage_index

  game_state.stage_index = 0
  assert_eq(current_level_name(), "Tutorial")

  game_state.stage_index = 1
  assert_eq(current_level_name(), "Test Level I: Defense")

  game_state.stage_index = 8
  assert_eq(current_level_name(), "Test Level II: Defense")

  game_state.stage_index = 15
  assert_eq(current_level_name(), "Test Level III: Defense")

  game_state.stage_index = run_stages.length()
  assert_eq(current_level_name(), "Run Complete")

  game_state.stage_index = old_stage_index
}

///|
test "tutorial stage hides top and bottom header labels" {
  let old_screen = game_state.screen
  let old_phase = game_state.phase
  let old_stage_index = game_state.stage_index
  let old_stage_elapsed = game_state.stage_elapsed
  let old_tutorial_lesson = game_state.tutorial_lesson
  let old_score_content = game_state.score_text.content
  let old_stage_content = game_state.stage_text.content

  game_state.screen = InGame
  game_state.phase = Playing
  game_state.stage_elapsed = 0.0
  game_state.tutorial_lesson = 0
  setup_test_text_entity(game_state.score_ui, game_state.score_text)
  setup_test_text_entity(game_state.stage_ui, game_state.stage_text)
  setup_test_text_entity(game_state.timer_ui, game_state.timer_text)

  game_state.stage_index = 0
  ui_in_game()
  assert_eq(game_state.score_text.content, "")
  assert_eq(game_state.stage_text.content, "")
  assert_true(!show_tutorial_header_labels())
  assert_entity_visible(game_state.score_ui, false)
  assert_entity_visible(game_state.stage_ui, false)
  assert_entity_visible(game_state.timer_ui, false)

  game_state.stage_index = 1
  ui_in_game()
  assert_true(game_state.score_text.content != "")
  assert_true(game_state.stage_text.content != "")
  assert_true(show_tutorial_header_labels())

  game_state.screen = old_screen
  game_state.phase = old_phase
  game_state.stage_index = old_stage_index
  game_state.stage_elapsed = old_stage_elapsed
  game_state.tutorial_lesson = old_tutorial_lesson
  game_state.score_text.content = old_score_content
  game_state.stage_text.content = old_stage_content
}

///|
test "tutorial lesson naming and movement completion counter stay coherent" {
  let old_lesson = game_state.tutorial_lesson
  let old_up = game_state.tutorial_up_progress
  let old_down = game_state.tutorial_down_progress
  let old_left = game_state.tutorial_left_progress
  let old_right = game_state.tutorial_right_progress
  let old_ul = game_state.tutorial_up_left_progress
  let old_ur = game_state.tutorial_up_right_progress
  let old_dl = game_state.tutorial_down_left_progress
  let old_dr = game_state.tutorial_down_right_progress

  game_state.tutorial_lesson = 0
  assert_eq(tutorial_lesson_name(), "Movement")
  game_state.tutorial_lesson = 1
  assert_eq(tutorial_lesson_name(), "Ability Slot One")
  game_state.tutorial_lesson = 2
  assert_eq(tutorial_lesson_name(), "Ability Slot Two")
  game_state.tutorial_lesson = 99
  assert_eq(tutorial_lesson_name(), "Complete")

  game_state.tutorial_up_progress = 0.5
  game_state.tutorial_down_progress = 0.49
  game_state.tutorial_left_progress = 0.51
  game_state.tutorial_right_progress = 0.5
  game_state.tutorial_up_left_progress = 0.0
  game_state.tutorial_up_right_progress = 0.0
  game_state.tutorial_down_left_progress = 0.0
  game_state.tutorial_down_right_progress = 0.0
  assert_eq(tutorial_movement_completed_count(), 3)

  game_state.tutorial_lesson = old_lesson
  game_state.tutorial_up_progress = old_up
  game_state.tutorial_down_progress = old_down
  game_state.tutorial_left_progress = old_left
  game_state.tutorial_right_progress = old_right
  game_state.tutorial_up_left_progress = old_ul
  game_state.tutorial_up_right_progress = old_ur
  game_state.tutorial_down_left_progress = old_dl
  game_state.tutorial_down_right_progress = old_dr
}

///|
test "tutorial phase data text switches branches by lesson counters" {
  let old_lesson = game_state.tutorial_lesson
  let old_slot1_destroy = game_state.tutorial_slot1_destroy
  let old_slot1_protect = game_state.tutorial_slot1_protect
  let old_slot2_destroy = game_state.tutorial_slot2_destroy

  game_state.tutorial_lesson = 1
  game_state.tutorial_slot1_destroy = 2
  game_state.tutorial_slot1_protect = 1
  assert_eq(tutorial_phase_data_text(), "Destroy drones: 2")

  game_state.tutorial_slot1_destroy = 0
  game_state.tutorial_slot1_protect = 3
  assert_eq(tutorial_phase_data_text(), "Protect haulers: 3")

  game_state.tutorial_lesson = 2
  game_state.tutorial_slot2_destroy = 4
  assert_eq(tutorial_phase_data_text(), "Destroy drones: 4")

  game_state.tutorial_lesson = old_lesson
  game_state.tutorial_slot1_destroy = old_slot1_destroy
  game_state.tutorial_slot1_protect = old_slot1_protect
  game_state.tutorial_slot2_destroy = old_slot2_destroy
}

///|
test "tutorial phase data lines expose expected line count and completion flags" {
  let old_lesson = game_state.tutorial_lesson
  let old_up = game_state.tutorial_up_progress
  let old_down = game_state.tutorial_down_progress
  let old_left = game_state.tutorial_left_progress
  let old_right = game_state.tutorial_right_progress
  let old_ul = game_state.tutorial_up_left_progress
  let old_ur = game_state.tutorial_up_right_progress
  let old_dl = game_state.tutorial_down_left_progress
  let old_dr = game_state.tutorial_down_right_progress
  let old_slot1_destroy = game_state.tutorial_slot1_destroy
  let old_slot1_protect = game_state.tutorial_slot1_protect
  let old_slot2_destroy = game_state.tutorial_slot2_destroy

  game_state.tutorial_lesson = 0
  game_state.tutorial_up_progress = 0.5
  game_state.tutorial_down_progress = 0.0
  game_state.tutorial_left_progress = 0.0
  game_state.tutorial_right_progress = 0.0
  game_state.tutorial_up_left_progress = 0.0
  game_state.tutorial_up_right_progress = 0.0
  game_state.tutorial_down_left_progress = 0.0
  game_state.tutorial_down_right_progress = 0.0
  let movement_lines = tutorial_phase_data_lines()
  assert_eq(movement_lines.length(), 8)
  assert_true(movement_lines[0].1)
  assert_true(!movement_lines[1].1)

  game_state.tutorial_lesson = 1
  game_state.tutorial_slot1_destroy = 1
  game_state.tutorial_slot1_protect = 0
  let slot1_lines = tutorial_phase_data_lines()
  assert_eq(slot1_lines.length(), 2)
  assert_true(!slot1_lines[0].1)
  assert_true(slot1_lines[1].1)

  game_state.tutorial_lesson = 2
  game_state.tutorial_slot2_destroy = 0
  let slot2_lines = tutorial_phase_data_lines()
  assert_eq(slot2_lines.length(), 1)
  assert_true(slot2_lines[0].1)

  game_state.tutorial_lesson = old_lesson
  game_state.tutorial_up_progress = old_up
  game_state.tutorial_down_progress = old_down
  game_state.tutorial_left_progress = old_left
  game_state.tutorial_right_progress = old_right
  game_state.tutorial_up_left_progress = old_ul
  game_state.tutorial_up_right_progress = old_ur
  game_state.tutorial_down_left_progress = old_dl
  game_state.tutorial_down_right_progress = old_dr
  game_state.tutorial_slot1_destroy = old_slot1_destroy
  game_state.tutorial_slot1_protect = old_slot1_protect
  game_state.tutorial_slot2_destroy = old_slot2_destroy
}

///|
test "format_tutorial_progress clamps and formats to one decimal place" {
  assert_eq(format_tutorial_progress(-1.0), "0.0")
  assert_eq(format_tutorial_progress(0.11), "0.1")
  assert_eq(format_tutorial_progress(0.29), "0.2")
  assert_eq(format_tutorial_progress(0.5), "0.5")
  assert_eq(format_tutorial_progress(2.0), "0.5")

  let (line, done) = tutorial_direction_progress_line("Left", 0.51)
  assert_eq(line, "Left: 0.5/0.5")
  assert_true(done)
}

///|
test "shoot and special cooldown calculations obey floors" {
  let old_shoot_interval = game_state.shoot_interval
  let old_cooldown_multiplier = game_state.cooldown_multiplier
  let old_special_cooldown_base = game_state.special_cooldown_base

  game_state.shoot_interval = 0.01
  game_state.cooldown_multiplier = 2.0
  assert_eq(current_shoot_interval(), 0.08)

  game_state.shoot_interval = 0.2
  game_state.cooldown_multiplier = 2.0
  assert_eq(current_shoot_interval(), 0.4)

  game_state.special_cooldown_base = 0.2
  game_state.cooldown_multiplier = 2.0
  assert_eq(special_cooldown_duration(), 0.6)

  game_state.special_cooldown_base = 1.0
  game_state.cooldown_multiplier = 2.0
  assert_eq(special_cooldown_duration(), 2.0)

  game_state.shoot_interval = old_shoot_interval
  game_state.cooldown_multiplier = old_cooldown_multiplier
  game_state.special_cooldown_base = old_special_cooldown_base
}

///|
test "enemy archetypes preserve shooter and movement semantics" {
  let pawn = enemy_archetype(Pawn)
  assert_true(pawn.movement is DownBrake)
  assert_true(pawn.shooter is PawnBlaster)

  let strafer_left = enemy_archetype(StraferLeft)
  assert_true(strafer_left.movement is DownHorizontal)
  assert_eq(strafer_left.horizontal_dir, -1.0)

  let missile = enemy_archetype(Missile)
  assert_true(missile.movement is Homing)
  assert_eq(missile.collision_damage, 30)

  let saucetron = enemy_archetype(MechaSaucetron)
  assert_true(saucetron.movement is BossHover)
  assert_true(saucetron.shooter is BossSpawner)

  let hauler = enemy_archetype(Hauler)
  assert_eq(hauler.collision_damage, 0)
  assert_eq(hauler.escape_defense_delta, 5)
}

///|
test "apply_consumable updates resources and clamps gameplay limits" {
  let old_money = game_state.money
  let old_score = game_state.score
  let old_base = game_state.base_cooldown_multiplier
  let old_cooldown = game_state.cooldown_multiplier
  let old_hull = game_state.hull
  let old_max_hull = game_state.max_hull
  let old_armor = game_state.armor
  let old_projectile_count = game_state.projectile_count

  game_state.base_cooldown_multiplier = 2.0
  game_state.cooldown_multiplier = 2.0
  game_state.money = 0
  game_state.score = 0
  game_state.max_hull = 100
  game_state.hull = 90
  game_state.armor = 0
  game_state.projectile_count = MAX_PROJECTILE_COUNT

  apply_consumable(Money1)
  assert_eq(game_state.money, 1)
  assert_eq(game_state.score, 1)

  apply_consumable(Money3)
  assert_eq(game_state.money, 4)
  assert_eq(game_state.score, 4)
  assert_true(game_state.cooldown_multiplier < 2.0)

  apply_consumable(HealthWrench)
  assert_eq(game_state.hull, 100)

  apply_consumable(Armor)
  assert_eq(game_state.armor, 1)

  apply_consumable(GainProjectiles)
  assert_eq(game_state.projectile_count, MAX_PROJECTILE_COUNT)

  game_state.projectile_count = 1
  apply_consumable(GainProjectiles)
  assert_eq(game_state.projectile_count, 2)

  game_state.money = old_money
  game_state.score = old_score
  game_state.base_cooldown_multiplier = old_base
  game_state.cooldown_multiplier = old_cooldown
  game_state.hull = old_hull
  game_state.max_hull = old_max_hull
  game_state.armor = old_armor
  game_state.projectile_count = old_projectile_count
}

///|
test "damage_player consumes armor then shield then hull" {
  let old_screen = game_state.screen
  let old_phase = game_state.phase
  let old_player_invulnerable = game_state.player_invulnerable
  let old_armor = game_state.armor
  let old_shield = game_state.shield
  let old_hull = game_state.hull
  let old_max_hull = game_state.max_hull
  let old_background_kind = game_state.background_kind
  let old_shield_recharge_delay = game_state.shield_recharge_delay
  let old_shield_recharge_progress = game_state.shield_recharge_progress

  game_state.screen = InGame
  game_state.phase = Playing
  game_state.player_invulnerable = 0.0
  game_state.armor = 1
  game_state.shield = 5
  game_state.max_hull = 50
  game_state.hull = 50
  game_state.shield_recharge_delay = 0.0
  game_state.shield_recharge_progress = 1.0

  damage_player(3)
  assert_eq(game_state.armor, 0)
  assert_eq(game_state.shield, 5)
  assert_eq(game_state.hull, 50)

  game_state.player_invulnerable = 0.0
  damage_player(4)
  assert_eq(game_state.shield, 1)
  assert_eq(game_state.hull, 50)

  game_state.player_invulnerable = 0.0
  damage_player(10)
  assert_eq(game_state.shield, 0)
  assert_eq(game_state.hull, 41)
  assert_eq(game_state.shield_recharge_delay, SHIELD_RECHARGE_DELAY_SECONDS)
  assert_eq(game_state.shield_recharge_progress, 0.0)

  game_state.player_invulnerable = 0.0
  damage_player(100)
  assert_eq(game_state.hull, 0)
  assert_true(game_state.phase is GameOver)

  game_state.screen = old_screen
  game_state.phase = old_phase
  game_state.player_invulnerable = old_player_invulnerable
  game_state.armor = old_armor
  game_state.shield = old_shield
  game_state.hull = old_hull
  game_state.max_hull = old_max_hull
  game_state.background_kind = old_background_kind
  game_state.shield_recharge_delay = old_shield_recharge_delay
  game_state.shield_recharge_progress = old_shield_recharge_progress
}

///|
test "apply_defense_delta clamps and enters game over at zero" {
  let old_screen = game_state.screen
  let old_phase = game_state.phase
  let old_defense = game_state.defense
  let old_warning = game_state.warning_gradient_timer
  let old_defense_gradient = game_state.defense_gradient_timer
  let old_background_kind = game_state.background_kind

  game_state.screen = InGame
  game_state.phase = Playing
  game_state.defense = 2
  game_state.warning_gradient_timer = 0.0
  game_state.defense_gradient_timer = 0.0

  apply_defense_delta(-1)
  assert_eq(game_state.defense, 1)
  assert_eq(game_state.warning_gradient_timer, 0.4)

  apply_defense_delta(5)
  assert_eq(game_state.defense, 6)
  assert_eq(game_state.defense_gradient_timer, 0.4)

  apply_defense_delta(-100)
  assert_eq(game_state.defense, 0)
  assert_true(game_state.phase is GameOver)

  game_state.screen = old_screen
  game_state.phase = old_phase
  game_state.defense = old_defense
  game_state.warning_gradient_timer = old_warning
  game_state.defense_gradient_timer = old_defense_gradient
  game_state.background_kind = old_background_kind
}

///|
test "phase name and phase data reflect current stage kind" {
  let old_stage_index = game_state.stage_index
  let old_stage_elapsed = game_state.stage_elapsed
  let old_tutorial_lesson = game_state.tutorial_lesson
  let old_slot1_destroy = game_state.tutorial_slot1_destroy
  let old_slot1_protect = game_state.tutorial_slot1_protect

  game_state.stage_index = 0
  game_state.tutorial_lesson = 1
  game_state.tutorial_slot1_destroy = 2
  game_state.tutorial_slot1_protect = 1
  assert_eq(current_phase_name(), "Ability Slot One")
  assert_eq(current_phase_data(), "Destroy drones: 2")

  game_state.stage_index = 1
  game_state.stage_elapsed = 3.2
  assert_eq(current_phase_name(), "Formation Invasion")
  assert_eq(current_phase_data(), "17")

  game_state.stage_index = 2
  game_state.stage_elapsed = 8.6
  assert_eq(current_phase_name(), "Break")
  assert_eq(current_phase_data(), "1")

  game_state.stage_index = old_stage_index
  game_state.stage_elapsed = old_stage_elapsed
  game_state.tutorial_lesson = old_tutorial_lesson
  game_state.tutorial_slot1_destroy = old_slot1_destroy
  game_state.tutorial_slot1_protect = old_slot1_protect
}

///|
test "boss phase data reads hp from enemy state map" {
  let old_stage_index = game_state.stage_index
  clear_enemies_for_test()
  game_state.stage_index = 7

  let boss = @entity.Entity::new()
  enemies.set(boss, make_enemy_for_test(Ferritharax, 777))
  assert_eq(current_phase_name(), "Boss: Ferritharax")
  assert_eq(current_phase_data(), "777/1200")

  if enemies.get(boss) is Some(enemy) {
    enemy.hp = 9000
  }
  assert_eq(current_phase_data(), "1200/1200")

  clear_enemies_for_test()
  game_state.stage_index = old_stage_index
}

///|
test "gradient_height scales linearly then clamps to max height" {
  assert_eq(gradient_height(-0.1), 0.0)
  assert_eq(gradient_height(0.0), 0.0)
  assert_eq(gradient_height(0.2), 48.0)
  assert_true(absd(gradient_height(0.4)) < 0.0000001)
  assert_true(absd(gradient_height(2.0)) < 0.0000001)
}

///|
test "victory_system requires finished stages and no living enemies" {
  let old_screen = game_state.screen
  let old_phase = game_state.phase
  let old_stage_index = game_state.stage_index
  let old_background_kind = game_state.background_kind

  clear_enemies_for_test()
  game_state.screen = InGame
  game_state.phase = Playing
  game_state.stage_index = run_stages.length()

  victory_system(@ecs.require_current_world())
  assert_true(game_state.phase is Victory)

  game_state.phase = Playing
  let blocker = @entity.Entity::new()
  enemies.set(blocker, make_enemy_for_test(Pawn, 1))
  victory_system(@ecs.require_current_world())
  assert_true(game_state.phase is Playing)

  clear_enemies_for_test()
  game_state.screen = old_screen
  game_state.phase = old_phase
  game_state.stage_index = old_stage_index
  game_state.background_kind = old_background_kind
}

///|
test "background mode policy keeps all screens on 2d background" {
  assert_true(!uses_3d_background(Menu))
  assert_true(!uses_3d_background(CharacterSelection))
  assert_true(!uses_3d_background(Game))
  assert_true(!uses_3d_background(GameOver))
  assert_true(!uses_3d_background(Victory))
}

///|
test "game background texture uses fixed stage bands" {
  assert_eq(game_background_texture_for_stage(0), game_background_textures[0])
  assert_eq(game_background_texture_for_stage(7), game_background_textures[0])

  let mid_idx = clamp_int(1, 0, game_background_textures.length() - 1)
  assert_eq(
    game_background_texture_for_stage(8),
    game_background_textures[mid_idx],
  )
  assert_eq(
    game_background_texture_for_stage(14),
    game_background_textures[mid_idx],
  )

  let late_idx = clamp_int(2, 0, game_background_textures.length() - 1)
  assert_eq(
    game_background_texture_for_stage(15),
    game_background_textures[late_idx],
  )
}

///|
test "set_background game path binds stage-selected texture sprite" {
  let old_stage_index = game_state.stage_index
  let old_kind = game_state.background_kind

  game_state.stage_index = 0
  set_background(Game)

  if uses_3d_background(Game) {
    assert_true(background3d_active.val)
    assert_true(
      @render3d.mesh3d_renderers().get(background3d_quad_entity) is Some(_),
    )
    if @sprite.sprites().get(game_state.background) is Some(_) {
      assert_entity_visible(game_state.background, false)
    } else {
      fail("missing gameplay background sprite")
    }
  } else if @sprite.sprites().get(game_state.background) is Some(sprite) {
    assert_eq(
      sprite.image.bind(fn(image) { @asset.image_path(image) }),
      Some(game_background_texture_for_stage(0)),
    )
  } else {
    fail("missing gameplay background sprite")
  }

  game_state.stage_index = old_stage_index
  set_background(old_kind)
}

///|
test "3d background fallback bodies stay detached from renderer components" {
  let old_active = background3d_active.val
  let old_ambient = @render3d.get_ambient_light3d()
  ensure_background3d_initialized()
  set_background3d_active(true)

  assert_true(
    @render3d.mesh3d_renderers().get(background3d_quad_entity) is Some(_),
  )
  assert_true(
    @render3d.mesh3d_renderers().get(background3d_planet_entity) is None,
  )
  assert_true(
    @render3d.mesh3d_renderers().get(background3d_star_entity) is None,
  )
  assert_true(
    @render3d.point_lights3d().get(background3d_star_light_entity) is None,
  )
  if @render3d.get_ambient_light3d() is Some(light) {
    assert_true(light.intensity > 0.0)
  } else {
    fail("expected ambient light for 3d background")
  }

  set_background3d_active(old_active)
  @render3d.set_ambient_light3d(old_ambient)
}

///|
test "initial player position is centered near bottom edge" {
  let pos = initial_player_position()
  assert_eq(pos[X], VIEWPORT_WIDTH / 2.0)
  assert_eq(pos[Y], VIEWPORT_HEIGHT - 34.0)
}

///|
test "character selection horizontal lanes reserve non-overlap spacing" {
  let left_slot_right = CS_LEFT_ABILITY_SLOT_X + CS_ABILITY_SLOT_SIZE / 2.0
  let right_slot_right = CS_RIGHT_ABILITY_SLOT_X + CS_ABILITY_SLOT_SIZE / 2.0

  assert_true(
    CS_LEFT_ABILITY_TEXT_X >=
    left_slot_right + CS_ABILITY_TEXT_MIN_GAP_FROM_SLOT,
  )
  assert_true(
    CS_RIGHT_ABILITY_TEXT_X >=
    right_slot_right + CS_ABILITY_TEXT_MIN_GAP_FROM_SLOT,
  )

  assert_true(
    CS_LEFT_ABILITY_TEXT_X +
    CS_LEFT_ABILITY_TEXT_MAX_WIDTH +
    CS_ABILITY_TEXT_GAP_TO_STAT_ICON <=
    CS_LEFT_STAT_ICON_X,
  )
  assert_true(
    CS_RIGHT_ABILITY_TEXT_X +
    CS_RIGHT_ABILITY_TEXT_MAX_WIDTH +
    CS_ABILITY_TEXT_GAP_TO_STAT_ICON <=
    CS_RIGHT_STAT_ICON_X,
  )

  // Ensure the 3-item carousel has explicit spacing and does not overlap.
  let center_max_half_width = 20.0 * 4.0 / 2.0
  let side_max_half_width = 20.0 * 3.0 / 2.0
  assert_true(
    CS_CAROUSEL_SIDE_OFFSET_X >= center_max_half_width + side_max_half_width,
  )
  assert_true(
    CS_P1_CAROUSEL_CENTER_X - CS_CAROUSEL_SIDE_OFFSET_X - side_max_half_width >=
    0.0,
  )
  assert_true(
    CS_P2_CAROUSEL_CENTER_X + CS_CAROUSEL_SIDE_OFFSET_X + side_max_half_width <=
    VIEWPORT_WIDTH,
  )
}

///|
test "character selection text clipping respects lane width constraints" {
  let long_line = "Fires extremely long ability text that must be clipped to fit lane."
  let left = clip_text_to_width(
    long_line,
    "7px MGS1Codec",
    CS_LEFT_ABILITY_TEXT_MAX_WIDTH,
  )
  let right = clip_text_to_width(
    long_line,
    "7px MGS1Codec",
    CS_RIGHT_ABILITY_TEXT_MAX_WIDTH,
  )

  assert_true(
    text_with_font_width(left, "7px MGS1Codec") <=
    CS_LEFT_ABILITY_TEXT_MAX_WIDTH,
  )
  assert_true(
    text_with_font_width(right, "7px MGS1Codec") <=
    CS_RIGHT_ABILITY_TEXT_MAX_WIDTH,
  )
  assert_true(
    CS_NAME_Y >=
    CS_PORTRAIT_CENTER_Y +
    CS_MAX_PORTRAIT_HALF_HEIGHT +
    CS_NAME_MIN_GAP_FROM_PORTRAIT,
  )
}

///|
test "menu button text center uses button rect and fallback anchor" {
  let button = @entity.Entity::new()
  set_entity_position(button, @math.Vec2(100.0, 200.0))
  let center = text_center_for_menu_button(button)
  assert_eq(center[X], 100.0 + MENU_BUTTON_WIDTH / 2.0)
  assert_eq(
    center[Y],
    200.0 + MENU_BUTTON_HEIGHT / 2.0 + MENU_BUTTON_TEXT_Y_TWEAK,
  )

  let fallback = text_center_for_menu_button(@entity.Entity::new())
  assert_eq(fallback[X], 240.0)
  assert_eq(fallback[Y], 193.0)
}

///|
test "main menu mouse click uses cursor hit test instead of stale interaction state" {
  let start_entity = game_state.menu_button_start_ui
  let exit_entity = game_state.menu_button_exit_ui

  let old_mouse_pos = @inputs.mouse.pos
  let old_just_pressed_left = @inputs.just_pressed_mouse.left_button
  let old_start_interaction = @ui.interactions().get(start_entity)
  let old_exit_interaction = @ui.interactions().get(exit_entity)
  let old_start_position = entity_position(start_entity)
  let old_exit_position = entity_position(exit_entity)
  let old_start_button = @ui.buttons().get(start_entity)
  let old_exit_button = @ui.buttons().get(exit_entity)

  set_entity_position(start_entity, @math.Vec2(160.0, 176.0))
  set_entity_position(exit_entity, @math.Vec2(160.0, 242.0))
  @ui.buttons().set(start_entity, @ui.Button::new())
  @ui.buttons().set(exit_entity, @ui.Button::new())
  @ui.nodes().set(
    start_entity,
    @ui.Node::absolute(@math.Vec2::zero(), size=@math.Vec2(160.0, 22.0)),
  )
  @ui.nodes().set(
    exit_entity,
    @ui.Node::absolute(@math.Vec2::zero(), size=@math.Vec2(160.0, 22.0)),
  )

  let exit_position = menu_entity_virtual_position(exit_entity)
  let exit_size = menu_button_hit_size(exit_entity)
  let exit_center_virtual = @math.Vec2(
    exit_position[X] + exit_size[X] / 2.0,
    exit_position[Y] + exit_size[Y] / 2.0,
  )
  @inputs.mouse.pos = @system.ui_virtual_to_screen(exit_center_virtual)
  @inputs.just_pressed_mouse.left_button = true

  // Simulate stale previous-frame interaction still pointing to Start.
  @ui.interactions().set(start_entity, @ui.Pressed)
  @ui.interactions().set(exit_entity, @ui.None)

  assert_eq(main_menu_pressed_index(), Some(3))

  @inputs.mouse.pos = old_mouse_pos
  @inputs.just_pressed_mouse.left_button = old_just_pressed_left
  match old_start_position {
    Some(position) => set_entity_position(start_entity, position)
    None => remove_entity_position(start_entity)
  }
  match old_exit_position {
    Some(position) => set_entity_position(exit_entity, position)
    None => remove_entity_position(exit_entity)
  }
  match old_start_button {
    Some(button) => @ui.buttons().set(start_entity, button)
    None => @ui.buttons().remove(start_entity)
  }
  match old_exit_button {
    Some(button) => @ui.buttons().set(exit_entity, button)
    None => @ui.buttons().remove(exit_entity)
  }
  match old_start_interaction {
    Some(interaction) => @ui.interactions().set(start_entity, interaction)
    None => @ui.interactions().remove(start_entity)
  }
  match old_exit_interaction {
    Some(interaction) => @ui.interactions().set(exit_entity, interaction)
    None => @ui.interactions().remove(exit_entity)
  }
}

///|
test "apply_character_selection_layout keeps canonical anchor positions" {
  apply_character_selection_layout()

  if entity_position(game_state.stage_ui) is Some(pos) {
    assert_eq(pos[X], 240.0)
    assert_eq(pos[Y], 8.0)
  } else {
    fail("missing position for stage ui")
  }
  if entity_position(game_state.timer_ui) is Some(pos) {
    assert_eq(pos[X], 240.0)
    assert_eq(pos[Y], 20.0)
  } else {
    fail("missing position for timer ui")
  }
  if entity_position(game_state.banner_ui) is Some(pos) {
    assert_eq(pos[X], 240.0)
    assert_eq(pos[Y], 302.0)
  } else {
    fail("missing position for banner ui")
  }

  if entity_position(game_state.character_portrait_ui) is Some(pos) {
    assert_eq(pos[X], CS_P1_CAROUSEL_CENTER_X)
    assert_eq(pos[Y], CS_PORTRAIT_CENTER_Y)
  } else {
    fail("missing position for p1 portrait ui")
  }
  if entity_position(character_left_portrait_ui) is Some(pos) {
    assert_eq(pos[X], CS_P1_CAROUSEL_CENTER_X - CS_CAROUSEL_SIDE_OFFSET_X)
    assert_eq(pos[Y], CS_PORTRAIT_CENTER_Y)
  } else {
    fail("missing position for p1 left portrait ui")
  }
  if entity_position(character_right_portrait_ui) is Some(pos) {
    assert_eq(pos[X], CS_P1_CAROUSEL_CENTER_X + CS_CAROUSEL_SIDE_OFFSET_X)
    assert_eq(pos[Y], CS_PORTRAIT_CENTER_Y)
  } else {
    fail("missing position for p1 right portrait ui")
  }
  if entity_position(character_name_ui) is Some(pos) {
    assert_eq(pos[X], CS_P1_CAROUSEL_CENTER_X)
    assert_eq(pos[Y], CS_NAME_Y)
  } else {
    fail("missing position for p1 name ui")
  }
  if entity_position(character_ability_slot1_ui) is Some(pos) {
    assert_eq(pos[X], CS_LEFT_ABILITY_SLOT_X)
    assert_eq(pos[Y], 212.0)
  } else {
    fail("missing position for p1 ability slot1 ui")
  }
  if entity_position(character_ability_slot2_ui) is Some(pos) {
    assert_eq(pos[X], CS_LEFT_ABILITY_SLOT_X)
    assert_eq(pos[Y], 246.0)
  } else {
    fail("missing position for p1 ability slot2 ui")
  }
  if entity_position(character_ability_slot1_text_ui) is Some(pos) {
    assert_eq(pos[X], CS_LEFT_ABILITY_TEXT_X)
    assert_eq(pos[Y], 206.0)
  } else {
    fail("missing position for p1 ability text1 ui")
  }
  if entity_position(character_ability_slot2_text_ui) is Some(pos) {
    assert_eq(pos[X], CS_LEFT_ABILITY_TEXT_X)
    assert_eq(pos[Y], 240.0)
  } else {
    fail("missing position for p1 ability text2 ui")
  }

  if entity_position(character_p2_center_portrait_ui) is Some(pos) {
    assert_eq(pos[X], CS_P2_CAROUSEL_CENTER_X)
    assert_eq(pos[Y], CS_PORTRAIT_CENTER_Y)
  } else {
    fail("missing position for p2 portrait ui")
  }
  if entity_position(character_p2_left_portrait_ui) is Some(pos) {
    assert_eq(pos[X], CS_P2_CAROUSEL_CENTER_X - CS_CAROUSEL_SIDE_OFFSET_X)
    assert_eq(pos[Y], CS_PORTRAIT_CENTER_Y)
  } else {
    fail("missing position for p2 left portrait ui")
  }
  if entity_position(character_p2_right_portrait_ui) is Some(pos) {
    assert_eq(pos[X], CS_P2_CAROUSEL_CENTER_X + CS_CAROUSEL_SIDE_OFFSET_X)
    assert_eq(pos[Y], CS_PORTRAIT_CENTER_Y)
  } else {
    fail("missing position for p2 right portrait ui")
  }
  if entity_position(character_p2_name_ui) is Some(pos) {
    assert_eq(pos[X], CS_P2_CAROUSEL_CENTER_X)
    assert_eq(pos[Y], CS_NAME_Y)
  } else {
    fail("missing position for p2 name ui")
  }
  if entity_position(character_p2_ability_slot1_ui) is Some(pos) {
    assert_eq(pos[X], CS_RIGHT_ABILITY_SLOT_X)
    assert_eq(pos[Y], 212.0)
  } else {
    fail("missing position for p2 ability slot1 ui")
  }
  if entity_position(character_p2_ability_slot2_ui) is Some(pos) {
    assert_eq(pos[X], CS_RIGHT_ABILITY_SLOT_X)
    assert_eq(pos[Y], 246.0)
  } else {
    fail("missing position for p2 ability slot2 ui")
  }
  if entity_position(character_p2_ability_slot1_text_ui) is Some(pos) {
    assert_eq(pos[X], CS_RIGHT_ABILITY_TEXT_X)
    assert_eq(pos[Y], 206.0)
  } else {
    fail("missing position for p2 ability text1 ui")
  }
  if entity_position(character_p2_ability_slot2_text_ui) is Some(pos) {
    assert_eq(pos[X], CS_RIGHT_ABILITY_TEXT_X)
    assert_eq(pos[Y], 240.0)
  } else {
    fail("missing position for p2 ability text2 ui")
  }
}

///|
test "character selection ability descriptions fit both player lanes for all characters" {
  assert_eq(CS_LEFT_ABILITY_TEXT_MAX_WIDTH, CS_RIGHT_ABILITY_TEXT_MAX_WIDTH)

  for character in [Captain, Juggernaut] {
    for slot in 1..<3 {
      let desc = character_slot_ability_description(character, slot)
      let left = clip_text_to_width(
        desc,
        "7px MGS1Codec",
        CS_LEFT_ABILITY_TEXT_MAX_WIDTH,
      )
      let right = clip_text_to_width(
        desc,
        "7px MGS1Codec",
        CS_RIGHT_ABILITY_TEXT_MAX_WIDTH,
      )
      assert_true(left.length() > 0)
      assert_true(right.length() > 0)
      assert_true(
        text_with_font_width(left, "7px MGS1Codec") <=
        CS_LEFT_ABILITY_TEXT_MAX_WIDTH,
      )
      assert_true(
        text_with_font_width(right, "7px MGS1Codec") <=
        CS_RIGHT_ABILITY_TEXT_MAX_WIDTH,
      )
    }
  }
}

///|
test "character selection stat bars and rows stay readable and in viewport" {
  let left_icon_right = CS_LEFT_STAT_ICON_X + 8.0
  let right_icon_right = CS_RIGHT_STAT_ICON_X + 8.0
  let left_bg_x = 216.0
  let right_bg_x = 456.0
  let bar_total_width = CS_STAT_FILL_WIDTH + 8.0

  assert_true(left_bg_x >= left_icon_right + 8.0)
  assert_true(right_bg_x >= right_icon_right + 8.0)
  assert_true(left_bg_x + bar_total_width <= VIEWPORT_WIDTH)
  assert_true(right_bg_x + bar_total_width <= VIEWPORT_WIDTH)

  let portrait_bottom = CS_PORTRAIT_CENTER_Y + CS_MAX_PORTRAIT_HALF_HEIGHT
  let name_bottom = CS_NAME_Y + 9.0
  let first_slot_top = 212.0 - CS_ABILITY_SLOT_SIZE / 2.0
  let first_text_top = 206.0
  let second_text_top = 240.0
  assert_true(CS_NAME_Y >= portrait_bottom + CS_NAME_MIN_GAP_FROM_PORTRAIT)
  assert_true(first_slot_top >= name_bottom + 4.0)
  assert_true(first_text_top >= name_bottom + 8.0)
  assert_true(second_text_top >= first_text_top + 12.0)
}

///|
test "in-game left column lanes keep ability slots separated from health bars" {
  let slot_right = HUD_ABILITY_SLOT_LEFT_X + HUD_ABILITY_SLOT_SIZE

  assert_true(slot_right <= HUD_HEALTH_BAR_FILL_X)
  assert_true(slot_right <= HUD_SHIELD_BAR_FILL_X)
  assert_true(HUD_ABILITY_SLOT1_FILL_BOTTOM_Y > HUD_ABILITY_SLOT2_FILL_BOTTOM_Y)
}

///|
test "sync_text_ui_sprites preserves explicit visibility flags" {
  setup_test_text_entity(game_state.timer_ui, game_state.timer_text)
  set_ui_visible(game_state.timer_ui, false)
  game_state.timer_text.content = "Movement: 1/8"
  sync_text_ui_sprites()
  assert_entity_visible(game_state.timer_ui, false)

  set_ui_visible(game_state.timer_ui, true)
  sync_text_ui_sprites()
  assert_entity_visible(game_state.timer_ui, true)
}

///|
test "character slot visibility follows joined state for carousel portraits" {
  let center_portrait = @entity.Entity::new()
  let left_portrait = @entity.Entity::new()
  let right_portrait = @entity.Entity::new()
  let name_ui = @entity.Entity::new()
  let ability_slot1_ui = @entity.Entity::new()
  let ability_slot1_icon_ui = @entity.Entity::new()
  let ability_slot1_text_ui = @entity.Entity::new()
  let ability_slot2_ui = @entity.Entity::new()
  let ability_slot2_icon_ui = @entity.Entity::new()
  let ability_slot2_text_ui = @entity.Entity::new()
  let join_prompt_ui = @entity.Entity::new()
  let ready_text_ui = @entity.Entity::new()
  let stat_icon_uis = [@entity.Entity::new(), @entity.Entity::new()]
  let stat_bg_uis = [@entity.Entity::new(), @entity.Entity::new()]
  let stat_fill_uis = [@entity.Entity::new(), @entity.Entity::new()]

  let all_entities = [
    center_portrait, left_portrait, right_portrait, name_ui, ability_slot1_ui, ability_slot1_icon_ui,
    ability_slot1_text_ui, ability_slot2_ui, ability_slot2_icon_ui, ability_slot2_text_ui,
    join_prompt_ui, ready_text_ui,
  ]
  for entity in all_entities {
    @sprite.sprites().set(
      entity,
      color_rect_sprite(@math.Vec2(1.0, 1.0), "white", 1),
    )
  }
  for entity in stat_icon_uis {
    @sprite.sprites().set(
      entity,
      color_rect_sprite(@math.Vec2(1.0, 1.0), "white", 1),
    )
  }
  for entity in stat_bg_uis {
    @sprite.sprites().set(
      entity,
      color_rect_sprite(@math.Vec2(1.0, 1.0), "white", 1),
    )
  }
  for entity in stat_fill_uis {
    @sprite.sprites().set(
      entity,
      color_rect_sprite(@math.Vec2(1.0, 1.0), "white", 1),
    )
  }

  set_character_slot_joined_visibility(
    false, center_portrait, left_portrait, right_portrait, name_ui, ability_slot1_ui,
    ability_slot1_icon_ui, ability_slot1_text_ui, ability_slot2_ui, ability_slot2_icon_ui,
    ability_slot2_text_ui, stat_icon_uis, stat_bg_uis, stat_fill_uis, join_prompt_ui,
    ready_text_ui,
  )
  assert_entity_visible(center_portrait, false)
  assert_entity_visible(left_portrait, false)
  assert_entity_visible(right_portrait, false)
  assert_entity_visible(join_prompt_ui, true)
  assert_entity_visible(ready_text_ui, false)

  set_character_slot_joined_visibility(
    true, center_portrait, left_portrait, right_portrait, name_ui, ability_slot1_ui,
    ability_slot1_icon_ui, ability_slot1_text_ui, ability_slot2_ui, ability_slot2_icon_ui,
    ability_slot2_text_ui, stat_icon_uis, stat_bg_uis, stat_fill_uis, join_prompt_ui,
    ready_text_ui,
  )
  assert_entity_visible(center_portrait, true)
  assert_entity_visible(left_portrait, true)
  assert_entity_visible(right_portrait, true)
  assert_entity_visible(join_prompt_ui, false)
  assert_entity_visible(ready_text_ui, true)
}
