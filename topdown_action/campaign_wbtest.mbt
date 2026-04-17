///|
fn campaign_test_visual(path : String) -> @topdown_platform.ImageVisualDef {
  { path, scale: 1.0, y_offset: 0.0 }
}

///|
fn campaign_test_strip(path : String) -> @topdown_platform.SpriteAnimDef {
  {
    image: path,
    frame_width: 480.0,
    frame_height: 480.0,
    columns: 4,
    frame_count: 12,
    fps: 12.0,
    scale: 1.2,
  }
}

///|
fn campaign_test_sprites() -> @topdown_platform.DirectionalSprites {
  {
    up: campaign_test_strip("assets/assassin/Back - Running.png"),
    down: campaign_test_strip("assets/assassin/Front - Running.png"),
    left: campaign_test_strip("assets/assassin/Left - Running.png"),
    right: campaign_test_strip("assets/assassin/Right - Running.png"),
  }
}

///|
fn campaign_test_plugin() -> TopDownCampaignPluginDef {
  let legend : Map[Char, @topdown_platform.TileOrSpawnRule] = Map::new()
  legend.set('.', {
    kind: @topdown_platform.Floor,
    floor_image: Some(
      campaign_test_visual(
        "assets/top-down-summer/Top-Down Simple Summer_Ground 01.png",
      ),
    ),
    prop_image: None,
    blocks: false,
    actor_spawn_tag: None,
    point_tag: None,
  })
  legend.set('#', {
    kind: @topdown_platform.Wall,
    floor_image: Some(
      campaign_test_visual(
        "assets/top-down-summer/Top-Down Simple Summer_Ground 05.png",
      ),
    ),
    prop_image: None,
    blocks: true,
    actor_spawn_tag: None,
    point_tag: None,
  })
  legend.set('P', {
    kind: @topdown_platform.PlayerSpawn,
    floor_image: Some(
      campaign_test_visual(
        "assets/top-down-summer/Top-Down Simple Summer_Ground 02.png",
      ),
    ),
    prop_image: None,
    blocks: false,
    actor_spawn_tag: None,
    point_tag: None,
  })
  legend.set('N', {
    kind: @topdown_platform.ActorSpawn,
    floor_image: Some(
      campaign_test_visual(
        "assets/top-down-summer/Top-Down Simple Summer_Ground 03.png",
      ),
    ),
    prop_image: None,
    blocks: false,
    actor_spawn_tag: Some("north"),
    point_tag: None,
  })
  legend.set('C', {
    kind: @topdown_platform.Interact,
    floor_image: Some(
      campaign_test_visual(
        "assets/top-down-summer/Top-Down Simple Summer_Ground 04.png",
      ),
    ),
    prop_image: None,
    blocks: false,
    actor_spawn_tag: None,
    point_tag: Some("camp_alpha"),
  })
  legend.set('X', {
    kind: @topdown_platform.Interact,
    floor_image: Some(
      campaign_test_visual(
        "assets/top-down-summer/Top-Down Simple Summer_Ground 04.png",
      ),
    ),
    prop_image: None,
    blocks: false,
    actor_spawn_tag: None,
    point_tag: Some("exit_main"),
  })
  {
    meta: { id: "test_campaign", name: "test_campaign", version: "0.1.0" },
    archetypes: [
      {
        id: "player",
        ai_mode: Chase,
        preferred_range: 0.0,
        max_hp: 5,
        move_speed: 120.0,
        radius: 18.0,
        touch_damage: 0,
        score_value: 0,
        sprites: campaign_test_sprites(),
        drop_table_id: None,
        primary_skill_id: Some("shot"),
        secondary_skill_id: None,
      },
      {
        id: "enemy",
        ai_mode: Chase,
        preferred_range: 0.0,
        max_hp: 2,
        move_speed: 100.0,
        radius: 18.0,
        touch_damage: 1,
        score_value: 10,
        sprites: campaign_test_sprites(),
        drop_table_id: None,
        primary_skill_id: Some("shot"),
        secondary_skill_id: None,
      },
    ],
    skills: [
      {
        id: "shot",
        kind: Projectile,
        cooldown: 0.2,
        damage: 1,
        range: 200.0,
        projectile_speed: 360.0,
        projectile_radius: 4.0,
      },
    ],
    drops: [],
    player_archetype_id: "player",
    campaign: {
      stages: [
        {
          id: 1,
          title: "S1",
          map: {
            tile_size: 64.0,
            default_floor_image: campaign_test_visual(
              "assets/top-down-summer/Top-Down Simple Summer_Ground 01.png",
            ),
            rows: ["#####", "#P.N#", "#...#", "#C.X#", "#####"],
            legend,
          },
          waves: [
            {
              id: 1,
              start_delay: 0.0,
              entries: [
                {
                  archetype_id: "enemy",
                  count: 1,
                  spawn_interval: 0.1,
                  spawn_tag: Some("north"),
                },
              ],
            },
          ],
          objectives: [
            { kind: RescueCamp, tag: "camp_alpha", rescue_count: 2 },
            { kind: ExitZone, tag: "exit_main", rescue_count: 0 },
          ],
          required_rescued: 1,
        },
      ],
      lives: 3,
      intro_seconds: 0.4,
      clear_seconds: 0.4,
    },
    follower: { spacing_steps: 4, radius: 5.0, sprite_scale: 1.0 },
    ui_theme: {
      title: "test",
      font_path: "assets/shared/fonts/mgs1codec.ttf",
      font_family: "MGS1Codec",
      hud_color_css: "rgb(220,235,250)",
      control_hint: "WASD LMB SPACE",
    },
    hooks: None,
  }
}

///|
test "validate_campaign_plugin accepts a complete plugin" {
  assert_eq(validate_campaign_plugin(campaign_test_plugin()), None)
}

///|
test "validate_campaign_plugin rejects objective tags missing from map" {
  let plugin = campaign_test_plugin()
  let stage = plugin.campaign.stages[0]
  let bad_stage : CampaignStageDef = {
    id: stage.id,
    title: stage.title,
    map: stage.map,
    waves: stage.waves,
    objectives: [{ kind: ExitZone, tag: "missing", rescue_count: 0 }],
    required_rescued: stage.required_rescued,
  }
  let broken : TopDownCampaignPluginDef = {
    meta: plugin.meta,
    archetypes: plugin.archetypes,
    skills: plugin.skills,
    drops: plugin.drops,
    player_archetype_id: plugin.player_archetype_id,
    campaign: {
      stages: [bad_stage],
      lives: plugin.campaign.lives,
      intro_seconds: plugin.campaign.intro_seconds,
      clear_seconds: plugin.campaign.clear_seconds,
    },
    follower: plugin.follower,
    ui_theme: plugin.ui_theme,
    hooks: plugin.hooks,
  }
  assert_true(validate_campaign_plugin(broken) is Some(_))
}
