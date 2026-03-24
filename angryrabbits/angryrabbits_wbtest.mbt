///|
fn utf8_bytes(source : String) -> Bytes {
  @utf8.encode(source)
}

///|
fn with_fake_asset_io(
  files : Map[String, Bytes],
  body : () -> Unit raise,
) -> Unit raise {
  @asset.set_io(fn(path) { files.get(path) })
  body()
  @asset.set_io(fn(_path) { None })
}

///|
test "load ldtk level from asset bytes" {
  let files : Map[String, Bytes] = Map::new()
  let level_json =
    #|{
    #|  "externalLevels": false,
    #|  "defs": {
    #|    "layers": [
    #|      {
    #|        "identifier": "Entities",
    #|        "uid": 201,
    #|        "type": "Entities",
    #|        "intGridValues": []
    #|      },
    #|      {
    #|        "identifier": "Decor",
    #|        "uid": 202,
    #|        "type": "Entities",
    #|        "intGridValues": [],
    #|        "uiColor": "#7ACB7A"
    #|      }
    #|    ],
    #|    "entities": [],
    #|    "enums": [],
    #|    "externalEnums": [],
    #|    "tilesets": []
    #|  },
    #|  "levels": [
    #|    {
    #|      "identifier": "Level_0",
    #|      "iid": "level-0",
    #|      "uid": 1,
    #|      "worldX": 0,
    #|      "worldY": 0,
    #|      "pxWid": 640,
    #|      "pxHei": 480,
    #|      "__neighbours": [],
    #|      "fieldInstances": [
    #|        {
    #|          "__identifier": "max_shots",
    #|          "__type": "Int",
    #|          "__value": 7
    #|        }
    #|      ],
    #|      "layerInstances": [
    #|        {
    #|          "iid": "layer-decor",
    #|          "__identifier": "Decor",
    #|          "__type": "Entities",
    #|          "levelId": 1,
    #|          "layerDefUid": 202,
    #|          "__cWid": 160,
    #|          "__cHei": 120,
    #|          "__gridSize": 4,
    #|          "__opacity": 1,
    #|          "visible": true,
    #|          "optionalRules": [],
    #|          "__pxTotalOffsetX": 0,
    #|          "__pxTotalOffsetY": 0,
    #|          "intGridCsv": [],
    #|          "autoLayerTiles": [],
    #|          "seed": 0,
    #|          "overrideTilesetUid": null,
    #|          "gridTiles": [],
    #|          "entityInstances": [
    #|            {
    #|              "iid": "background",
    #|              "__identifier": "BackgroundRect",
    #|              "defUid": 103,
    #|              "width": 640,
    #|              "height": 480,
    #|              "px": [
    #|                0,
    #|                0
    #|              ],
    #|              "__grid": [
    #|                0,
    #|                0
    #|              ],
    #|              "__pivot": [
    #|                0,
    #|                0
    #|              ],
    #|              "__tags": [],
    #|              "fieldInstances": [
    #|                {
    #|                  "__identifier": "color",
    #|                  "__type": "String",
    #|                  "__value": "rgb(183, 225, 255)"
    #|                },
    #|                {
    #|                  "__identifier": "zindex",
    #|                  "__type": "Int",
    #|                  "__value": 0
    #|                }
    #|              ]
    #|            },
    #|            {
    #|              "iid": "ground",
    #|              "__identifier": "GroundRect",
    #|              "defUid": 104,
    #|              "width": 640,
    #|              "height": 92,
    #|              "px": [
    #|                0,
    #|                388
    #|              ],
    #|              "__grid": [
    #|                0,
    #|                97
    #|              ],
    #|              "__pivot": [
    #|                0,
    #|                0
    #|              ],
    #|              "__tags": [],
    #|              "fieldInstances": [
    #|                {
    #|                  "__identifier": "color",
    #|                  "__type": "String",
    #|                  "__value": "rgb(156, 198, 104)"
    #|                },
    #|                {
    #|                  "__identifier": "zindex",
    #|                  "__type": "Int",
    #|                  "__value": 2
    #|                }
    #|              ]
    #|            },
    #|            {
    #|              "iid": "hill",
    #|              "__identifier": "HillCircle",
    #|              "defUid": 105,
    #|              "width": 200,
    #|              "height": 200,
    #|              "px": [
    #|                440,
    #|                188
    #|              ],
    #|              "__grid": [
    #|                110,
    #|                47
    #|              ],
    #|              "__pivot": [
    #|                0,
    #|                0
    #|              ],
    #|              "__tags": [],
    #|              "fieldInstances": [
    #|                {
    #|                  "__identifier": "color",
    #|                  "__type": "String",
    #|                  "__value": "rgb(154, 211, 132)"
    #|                },
    #|                {
    #|                  "__identifier": "zindex",
    #|                  "__type": "Int",
    #|                  "__value": 1
    #|                }
    #|              ]
    #|            }
    #|          ]
    #|        },
    #|        {
    #|          "iid": "layer-entities",
    #|          "__identifier": "Entities",
    #|          "__type": "Entities",
    #|          "levelId": 1,
    #|          "layerDefUid": 201,
    #|          "__cWid": 160,
    #|          "__cHei": 120,
    #|          "__gridSize": 4,
    #|          "__opacity": 1,
    #|          "visible": true,
    #|          "optionalRules": [],
    #|          "__pxTotalOffsetX": 0,
    #|          "__pxTotalOffsetY": 0,
    #|          "intGridCsv": [],
    #|          "autoLayerTiles": [],
    #|          "seed": 0,
    #|          "overrideTilesetUid": null,
    #|          "gridTiles": [],
    #|          "entityInstances": [
    #|            {
    #|              "iid": "slingshot",
    #|              "__identifier": "SlingshotAnchor",
    #|              "defUid": 101,
    #|              "width": 0,
    #|              "height": 0,
    #|              "px": [
    #|                120,
    #|                280
    #|              ],
    #|              "__grid": [
    #|                30,
    #|                70
    #|              ],
    #|              "__pivot": [
    #|                0,
    #|                0
    #|              ],
    #|              "__tags": [],
    #|              "fieldInstances": []
    #|            },
    #|            {
    #|              "iid": "rabbit",
    #|              "__identifier": "RabbitSpawn",
    #|              "defUid": 102,
    #|              "width": 0,
    #|              "height": 0,
    #|              "px": [
    #|                140,
    #|                280
    #|              ],
    #|              "__grid": [
    #|                35,
    #|                70
    #|              ],
    #|              "__pivot": [
    #|                0,
    #|                0
    #|              ],
    #|              "__tags": [],
    #|              "fieldInstances": []
    #|            },
    #|            {
    #|              "iid": "slingshot-front",
    #|              "__identifier": "SlingshotFrontStick",
    #|              "defUid": 108,
    #|              "width": 26,
    #|              "height": 94,
    #|              "px": [
    #|                127,
    #|                197
    #|              ],
    #|              "__grid": [
    #|                31,
    #|                49
    #|              ],
    #|              "__pivot": [
    #|                0,
    #|                0
    #|              ],
    #|              "__tags": [],
    #|              "fieldInstances": []
    #|            },
    #|            {
    #|              "iid": "slingshot-back",
    #|              "__identifier": "SlingshotBackStick",
    #|              "defUid": 109,
    #|              "width": 26,
    #|              "height": 57,
    #|              "px": [
    #|                127,
    #|                293
    #|              ],
    #|              "__grid": [
    #|                31,
    #|                73
    #|              ],
    #|              "__pivot": [
    #|                0,
    #|                0
    #|              ],
    #|              "__tags": [],
    #|              "fieldInstances": []
    #|            },
    #|            {
    #|              "iid": "block-1",
    #|              "__identifier": "Block",
    #|              "defUid": 106,
    #|              "width": 32,
    #|              "height": 64,
    #|              "px": [
    #|                400,
    #|                324
    #|              ],
    #|              "__grid": [
    #|                100,
    #|                81
    #|              ],
    #|              "__pivot": [
    #|                0,
    #|                0
    #|              ],
    #|              "__tags": [],
    #|              "fieldInstances": [
    #|                {
    #|                  "__identifier": "color",
    #|                  "__type": "String",
    #|                  "__value": "rgb(191,132,78)"
    #|                }
    #|              ]
    #|            },
    #|            {
    #|              "iid": "target-1",
    #|              "__identifier": "Target",
    #|              "defUid": 107,
    #|              "width": 40,
    #|              "height": 40,
    #|              "px": [
    #|                500,
    #|                348
    #|              ],
    #|              "__grid": [
    #|                125,
    #|                87
    #|              ],
    #|              "__pivot": [
    #|                0,
    #|                0
    #|              ],
    #|              "__tags": [],
    #|              "fieldInstances": [
    #|                {
    #|                  "__identifier": "color",
    #|                  "__type": "String",
    #|                  "__value": "rgb(112, 209, 115)"
    #|                },
    #|                {
    #|                  "__identifier": "radius",
    #|                  "__type": "Float",
    #|                  "__value": 20
    #|                }
    #|              ]
    #|            }
    #|          ]
    #|        }
    #|      ]
    #|    }
    #|  ]
    #|}
  files.set("levels/test.ldtk", utf8_bytes(level_json))
  with_fake_asset_io(files, fn() raise {
    let level = match load_level_from_path("levels/test.ldtk") {
      Ok(level) => level
      Err(message) => abort(message)
    }
    assert_eq(level.max_shots, 7)
    assert_eq(level.blocks.length(), 1)
    assert_eq(level.targets.length(), 1)
    assert_eq(level.background_rect.position[X], 0.0)
    assert_eq(level.background_rect.size[Y], 480.0)
    assert_eq(level.ground_rect.position[Y], 388.0)
    assert_eq(level.ground_rect.zindex, 2)
    assert_eq(level.hill_circle.center[X], 540.0)
    assert_eq(level.hill_circle.center[Y], 288.0)
    assert_eq(level.hill_circle.radius, 100.0)
    assert_eq(level.slingshot_anchor[X], 120.0)
    assert_eq(level.slingshot_anchor[Y], 280.0)
    assert_eq(level.slingshot_front_stick[X], 127.0)
    assert_eq(level.slingshot_front_stick[Y], 197.0)
    assert_eq(level.slingshot_back_stick[X], 127.0)
    assert_eq(level.slingshot_back_stick[Y], 293.0)
    assert_eq(level.rabbit_spawn[X], 140.0)
    assert_eq(level.rabbit_spawn[Y], 280.0)
    assert_eq(level.blocks[0].center[X], 416.0)
    assert_eq(level.blocks[0].center[Y], 356.0)
    assert_eq(level.blocks[0].size[X], 32.0)
    assert_eq(level.blocks[0].size[Y], 64.0)
    assert_eq(level.targets[0].center[X], 520.0)
    assert_eq(level.targets[0].center[Y], 368.0)
    assert_eq(level.targets[0].radius, 20.0)
  })
}

///|
test "reset_level enters error scene when level load fails" {
  with_test_world(fn() raise {
    let previous_path = current_level_path.val
    defer {
      current_level_path.val = previous_path
    }
    current_level_path.val = "levels/missing.ldtk"
    reset_level()
    assert_true(game_state.val is Error)
    assert_true(current_level.val is None)
    assert_true(load_error_message.val.contains("levels/missing.ldtk"))
  })
}

///|
test "missing block color field still loads level" {
  let files : Map[String, Bytes] = Map::new()
  let level_json =
    #|{
    #|  "externalLevels": false,
    #|  "defs": {
    #|    "layers": [
    #|      {
    #|        "identifier": "Entities",
    #|        "uid": 201,
    #|        "type": "Entities",
    #|        "intGridValues": []
    #|      },
    #|      {
    #|        "identifier": "Decor",
    #|        "uid": 202,
    #|        "type": "Entities",
    #|        "intGridValues": [],
    #|        "uiColor": "#7ACB7A"
    #|      }
    #|    ],
    #|    "entities": [],
    #|    "enums": [],
    #|    "externalEnums": [],
    #|    "tilesets": []
    #|  },
    #|  "levels": [
    #|    {
    #|      "identifier": "Level_0",
    #|      "iid": "level-0",
    #|      "uid": 1,
    #|      "worldX": 0,
    #|      "worldY": 0,
    #|      "pxWid": 640,
    #|      "pxHei": 480,
    #|      "__neighbours": [],
    #|      "fieldInstances": [
    #|        {
    #|          "__identifier": "max_shots",
    #|          "__type": "Int",
    #|          "__value": 7
    #|        }
    #|      ],
    #|      "layerInstances": [
    #|        {
    #|          "iid": "layer-decor",
    #|          "__identifier": "Decor",
    #|          "__type": "Entities",
    #|          "levelId": 1,
    #|          "layerDefUid": 202,
    #|          "__cWid": 160,
    #|          "__cHei": 120,
    #|          "__gridSize": 4,
    #|          "__opacity": 1,
    #|          "visible": true,
    #|          "optionalRules": [],
    #|          "__pxTotalOffsetX": 0,
    #|          "__pxTotalOffsetY": 0,
    #|          "intGridCsv": [],
    #|          "autoLayerTiles": [],
    #|          "seed": 0,
    #|          "overrideTilesetUid": null,
    #|          "gridTiles": [],
    #|          "entityInstances": [
    #|            {
    #|              "iid": "background",
    #|              "__identifier": "BackgroundRect",
    #|              "defUid": 103,
    #|              "width": 640,
    #|              "height": 480,
    #|              "px": [
    #|                0,
    #|                0
    #|              ],
    #|              "__grid": [
    #|                0,
    #|                0
    #|              ],
    #|              "__pivot": [
    #|                0,
    #|                0
    #|              ],
    #|              "__tags": [],
    #|              "fieldInstances": [
    #|                {
    #|                  "__identifier": "color",
    #|                  "__type": "String",
    #|                  "__value": "rgb(183, 225, 255)"
    #|                },
    #|                {
    #|                  "__identifier": "zindex",
    #|                  "__type": "Int",
    #|                  "__value": 0
    #|                }
    #|              ]
    #|            },
    #|            {
    #|              "iid": "ground",
    #|              "__identifier": "GroundRect",
    #|              "defUid": 104,
    #|              "width": 640,
    #|              "height": 92,
    #|              "px": [
    #|                0,
    #|                388
    #|              ],
    #|              "__grid": [
    #|                0,
    #|                97
    #|              ],
    #|              "__pivot": [
    #|                0,
    #|                0
    #|              ],
    #|              "__tags": [],
    #|              "fieldInstances": [
    #|                {
    #|                  "__identifier": "color",
    #|                  "__type": "String",
    #|                  "__value": "rgb(156, 198, 104)"
    #|                },
    #|                {
    #|                  "__identifier": "zindex",
    #|                  "__type": "Int",
    #|                  "__value": 2
    #|                }
    #|              ]
    #|            },
    #|            {
    #|              "iid": "hill",
    #|              "__identifier": "HillCircle",
    #|              "defUid": 105,
    #|              "width": 200,
    #|              "height": 200,
    #|              "px": [
    #|                440,
    #|                188
    #|              ],
    #|              "__grid": [
    #|                110,
    #|                47
    #|              ],
    #|              "__pivot": [
    #|                0,
    #|                0
    #|              ],
    #|              "__tags": [],
    #|              "fieldInstances": [
    #|                {
    #|                  "__identifier": "color",
    #|                  "__type": "String",
    #|                  "__value": "rgb(154, 211, 132)"
    #|                },
    #|                {
    #|                  "__identifier": "zindex",
    #|                  "__type": "Int",
    #|                  "__value": 1
    #|                }
    #|              ]
    #|            }
    #|          ]
    #|        },
    #|        {
    #|          "iid": "layer-entities",
    #|          "__identifier": "Entities",
    #|          "__type": "Entities",
    #|          "levelId": 1,
    #|          "layerDefUid": 201,
    #|          "__cWid": 160,
    #|          "__cHei": 120,
    #|          "__gridSize": 4,
    #|          "__opacity": 1,
    #|          "visible": true,
    #|          "optionalRules": [],
    #|          "__pxTotalOffsetX": 0,
    #|          "__pxTotalOffsetY": 0,
    #|          "intGridCsv": [],
    #|          "autoLayerTiles": [],
    #|          "seed": 0,
    #|          "overrideTilesetUid": null,
    #|          "gridTiles": [],
    #|          "entityInstances": [
    #|            {
    #|              "iid": "slingshot",
    #|              "__identifier": "SlingshotAnchor",
    #|              "defUid": 101,
    #|              "width": 0,
    #|              "height": 0,
    #|              "px": [
    #|                120,
    #|                280
    #|              ],
    #|              "__grid": [
    #|                30,
    #|                70
    #|              ],
    #|              "__pivot": [
    #|                0,
    #|                0
    #|              ],
    #|              "__tags": [],
    #|              "fieldInstances": []
    #|            },
    #|            {
    #|              "iid": "rabbit",
    #|              "__identifier": "RabbitSpawn",
    #|              "defUid": 102,
    #|              "width": 0,
    #|              "height": 0,
    #|              "px": [
    #|                140,
    #|                280
    #|              ],
    #|              "__grid": [
    #|                35,
    #|                70
    #|              ],
    #|              "__pivot": [
    #|                0,
    #|                0
    #|              ],
    #|              "__tags": [],
    #|              "fieldInstances": []
    #|            },
    #|            {
    #|              "iid": "slingshot-front",
    #|              "__identifier": "SlingshotFrontStick",
    #|              "defUid": 108,
    #|              "width": 26,
    #|              "height": 94,
    #|              "px": [
    #|                127,
    #|                197
    #|              ],
    #|              "__grid": [
    #|                31,
    #|                49
    #|              ],
    #|              "__pivot": [
    #|                0,
    #|                0
    #|              ],
    #|              "__tags": [],
    #|              "fieldInstances": []
    #|            },
    #|            {
    #|              "iid": "slingshot-back",
    #|              "__identifier": "SlingshotBackStick",
    #|              "defUid": 109,
    #|              "width": 26,
    #|              "height": 57,
    #|              "px": [
    #|                127,
    #|                293
    #|              ],
    #|              "__grid": [
    #|                31,
    #|                73
    #|              ],
    #|              "__pivot": [
    #|                0,
    #|                0
    #|              ],
    #|              "__tags": [],
    #|              "fieldInstances": []
    #|            },
    #|            {
    #|              "iid": "block-1",
    #|              "__identifier": "Block",
    #|              "defUid": 106,
    #|              "width": 32,
    #|              "height": 64,
    #|              "px": [
    #|                400,
    #|                324
    #|              ],
    #|              "__grid": [
    #|                100,
    #|                81
    #|              ],
    #|              "__pivot": [
    #|                0,
    #|                0
    #|              ],
    #|              "__tags": [],
    #|              "fieldInstances": []
    #|            }
    #|          ]
    #|        }
    #|      ]
    #|    }
    #|  ]
    #|}
  files.set("levels/missing_block_color.ldtk", utf8_bytes(level_json))
  with_fake_asset_io(files, fn() raise {
    match load_level_from_path("levels/missing_block_color.ldtk") {
      Err(message) =>
        abort(
          "expected level load success without Block.color, got: \{message}",
        )
      Ok(level) => {
        assert_eq(level.blocks.length(), 1)
        assert_eq(level.blocks[0].size, @math.Vec2D(32.0, 64.0))
      }
    }
  })
}

///|
fn with_test_world(body : () -> Unit raise) -> Unit raise {
  let previous = @ecs.current_world()
  let world = @ecs.World::new()
  @ecs.set_current_world(world)
  body()
  match previous {
    Some(world) => @ecs.set_current_world(world)
    None => @ecs.clear_current_world()
  }
}

///|
fn reset_mouse_state() -> Unit {
  @inputs.mouse.pos = @math.Vec2D::zero()
  @inputs.mouse.left_button = false
  @inputs.mouse.right_button = false
  @inputs.mouse.middle_button = false
  @inputs.just_pressed_mouse.left_button = false
  @inputs.just_pressed_mouse.right_button = false
  @inputs.just_pressed_mouse.middle_button = false
  @inputs.just_release_mouse.left_button = false
  @inputs.just_release_mouse.right_button = false
  @inputs.just_release_mouse.middle_button = false
}

///|
fn world_to_screen_for_test(world : @math.Vec2D) -> @math.Vec2D {
  (world - camera_anchor_position()).scalar_mul(ZOOM)
}

///|
test "launch_rabbit preserves horizontal velocity through physics step" {
  let files : Map[String, Bytes] = Map::new()
  let level_json =
    #|{
    #|  "externalLevels": false,
    #|  "defs": {
    #|    "layers": [
    #|      {
    #|        "identifier": "Entities",
    #|        "uid": 201,
    #|        "type": "Entities",
    #|        "intGridValues": []
    #|      },
    #|      {
    #|        "identifier": "Decor",
    #|        "uid": 202,
    #|        "type": "Entities",
    #|        "intGridValues": [],
    #|        "uiColor": "#7ACB7A"
    #|      }
    #|    ],
    #|    "entities": [],
    #|    "enums": [],
    #|    "externalEnums": [],
    #|    "tilesets": []
    #|  },
    #|  "levels": [
    #|    {
    #|      "identifier": "Level_0",
    #|      "iid": "level-0",
    #|      "uid": 1,
    #|      "worldX": 0,
    #|      "worldY": 0,
    #|      "pxWid": 640,
    #|      "pxHei": 480,
    #|      "__neighbours": [],
    #|      "fieldInstances": [
    #|        {
    #|          "__identifier": "max_shots",
    #|          "__type": "Int",
    #|          "__value": 5
    #|        }
    #|      ],
    #|      "layerInstances": [
    #|        {
    #|          "iid": "layer-decor",
    #|          "__identifier": "Decor",
    #|          "__type": "Entities",
    #|          "levelId": 1,
    #|          "layerDefUid": 202,
    #|          "__cWid": 160,
    #|          "__cHei": 120,
    #|          "__gridSize": 4,
    #|          "__opacity": 1,
    #|          "visible": true,
    #|          "optionalRules": [],
    #|          "__pxTotalOffsetX": 0,
    #|          "__pxTotalOffsetY": 0,
    #|          "intGridCsv": [],
    #|          "autoLayerTiles": [],
    #|          "seed": 0,
    #|          "overrideTilesetUid": null,
    #|          "gridTiles": [],
    #|          "entityInstances": [
    #|            {
    #|              "iid": "background",
    #|              "__identifier": "BackgroundRect",
    #|              "defUid": 103,
    #|              "width": 640,
    #|              "height": 480,
    #|              "px": [
    #|                0,
    #|                0
    #|              ],
    #|              "__grid": [
    #|                0,
    #|                0
    #|              ],
    #|              "__pivot": [
    #|                0,
    #|                0
    #|              ],
    #|              "__tags": [],
    #|              "fieldInstances": [
    #|                {
    #|                  "__identifier": "color",
    #|                  "__type": "String",
    #|                  "__value": "rgb(183, 225, 255)"
    #|                },
    #|                {
    #|                  "__identifier": "zindex",
    #|                  "__type": "Int",
    #|                  "__value": 0
    #|                }
    #|              ]
    #|            },
    #|            {
    #|              "iid": "ground",
    #|              "__identifier": "GroundRect",
    #|              "defUid": 104,
    #|              "width": 640,
    #|              "height": 92,
    #|              "px": [
    #|                0,
    #|                388
    #|              ],
    #|              "__grid": [
    #|                0,
    #|                97
    #|              ],
    #|              "__pivot": [
    #|                0,
    #|                0
    #|              ],
    #|              "__tags": [],
    #|              "fieldInstances": [
    #|                {
    #|                  "__identifier": "color",
    #|                  "__type": "String",
    #|                  "__value": "rgb(156, 198, 104)"
    #|                },
    #|                {
    #|                  "__identifier": "zindex",
    #|                  "__type": "Int",
    #|                  "__value": 2
    #|                }
    #|              ]
    #|            },
    #|            {
    #|              "iid": "hill",
    #|              "__identifier": "HillCircle",
    #|              "defUid": 105,
    #|              "width": 200,
    #|              "height": 200,
    #|              "px": [
    #|                440,
    #|                188
    #|              ],
    #|              "__grid": [
    #|                110,
    #|                47
    #|              ],
    #|              "__pivot": [
    #|                0,
    #|                0
    #|              ],
    #|              "__tags": [],
    #|              "fieldInstances": [
    #|                {
    #|                  "__identifier": "color",
    #|                  "__type": "String",
    #|                  "__value": "rgb(154, 211, 132)"
    #|                },
    #|                {
    #|                  "__identifier": "zindex",
    #|                  "__type": "Int",
    #|                  "__value": 1
    #|                }
    #|              ]
    #|            }
    #|          ]
    #|        },
    #|        {
    #|          "iid": "layer-entities",
    #|          "__identifier": "Entities",
    #|          "__type": "Entities",
    #|          "levelId": 1,
    #|          "layerDefUid": 201,
    #|          "__cWid": 160,
    #|          "__cHei": 120,
    #|          "__gridSize": 4,
    #|          "__opacity": 1,
    #|          "visible": true,
    #|          "optionalRules": [],
    #|          "__pxTotalOffsetX": 0,
    #|          "__pxTotalOffsetY": 0,
    #|          "intGridCsv": [],
    #|          "autoLayerTiles": [],
    #|          "seed": 0,
    #|          "overrideTilesetUid": null,
    #|          "gridTiles": [],
    #|          "entityInstances": [
    #|            {
    #|              "iid": "slingshot",
    #|              "__identifier": "SlingshotAnchor",
    #|              "defUid": 101,
    #|              "width": 0,
    #|              "height": 0,
    #|              "px": [
    #|                120,
    #|                280
    #|              ],
    #|              "__grid": [
    #|                30,
    #|                70
    #|              ],
    #|              "__pivot": [
    #|                0,
    #|                0
    #|              ],
    #|              "__tags": [],
    #|              "fieldInstances": []
    #|            },
    #|            {
    #|              "iid": "rabbit",
    #|              "__identifier": "RabbitSpawn",
    #|              "defUid": 102,
    #|              "width": 0,
    #|              "height": 0,
    #|              "px": [
    #|                120,
    #|                280
    #|              ],
    #|              "__grid": [
    #|                30,
    #|                70
    #|              ],
    #|              "__pivot": [
    #|                0,
    #|                0
    #|              ],
    #|              "__tags": [],
    #|              "fieldInstances": []
    #|            },
    #|            {
    #|              "iid": "slingshot-front",
    #|              "__identifier": "SlingshotFrontStick",
    #|              "defUid": 108,
    #|              "width": 26,
    #|              "height": 94,
    #|              "px": [
    #|                106,
    #|                179
    #|              ],
    #|              "__grid": [
    #|                26,
    #|                44
    #|              ],
    #|              "__pivot": [
    #|                0,
    #|                0
    #|              ],
    #|              "__tags": [],
    #|              "fieldInstances": []
    #|            },
    #|            {
    #|              "iid": "slingshot-back",
    #|              "__identifier": "SlingshotBackStick",
    #|              "defUid": 109,
    #|              "width": 26,
    #|              "height": 57,
    #|              "px": [
    #|                106,
    #|                274
    #|              ],
    #|              "__grid": [
    #|                26,
    #|                68
    #|              ],
    #|              "__pivot": [
    #|                0,
    #|                0
    #|              ],
    #|              "__tags": [],
    #|              "fieldInstances": []
    #|            }
    #|          ]
    #|        }
    #|      ]
    #|    }
    #|  ]
    #|}
  files.set("levels/launch.ldtk", utf8_bytes(level_json))
  with_fake_asset_io(files, fn() raise {
    with_test_world(fn() raise {
      let previous_path = current_level_path.val
      defer {
        current_level_path.val = previous_path
      }
      current_level_path.val = "levels/launch.ldtk"
      reset_level()
      let short_pull = slingshot_anchor() - @math.Vec2D(30.0, 0.0)
      let long_pull = slingshot_anchor() - @math.Vec2D(60.0, 0.0)
      let short_velocity = launch_velocity_from_rabbit(short_pull)
      let long_velocity = launch_velocity_from_rabbit(long_pull)
      launch_rabbit(long_pull, long_velocity)
      @physics2d.physics_step_system(1.0 / 60.0)
      sync_physics_snapshots()
      assert_true(long_velocity[X] > short_velocity[X] * 3.9)
      assert_true(rabbit_velocity.val[X] > 300.0)
      assert_true(rabbit_center.val[X] > long_pull[X] + 1.0)

      reset_level()
      let diagonal_pull = slingshot_anchor() + @math.Vec2D(-60.0, 60.0)
      let diagonal_velocity = launch_velocity_from_rabbit(diagonal_pull)
      launch_rabbit(diagonal_pull, diagonal_velocity)
      @time.set_delta(1.0 / 60.0)
      simulation_system(@ecs.require_current_world())
      @physics2d.physics_step_system(1.0 / 60.0)
      sync_physics_snapshots()
      assert_true(diagonal_velocity[X] > 0.0)
      assert_true(diagonal_velocity[Y] < 0.0)
      assert_true(rabbit_center.val[X] > diagonal_pull[X] + 1.0)
      assert_true(rabbit_center.val[Y] < diagonal_pull[Y] - 1.0)
    })
  })
}

///|
test "dynamic bodies allow rotation like upstream prefabs" {
  let rabbit = rabbit_flying_body()
  let block = block_body()
  let target = target_body()
  assert_true(!rabbit.lock_rotation)
  assert_true(!block.lock_rotation)
  assert_true(!target.lock_rotation)
}

///|
test "launch transition preserves velocity after synced ready body exists" {
  with_test_world(() => {
    @physics2d.configure_physics(
      gravity=@math.Vec2D(0.0, GRAVITY),
      pixels_per_meter=PHYSICS_PIXELS_PER_METER,
      max_ccd_substeps=PHYSICS_MAX_CCD_SUBSTEPS,
    )
    rabbits.clear()
    let entity = @entity.Entity::new()
    ensure_entity_alive(entity)
    rabbits.push({
      entity,
      center: @math.Vec2D(120.0, 280.0),
      velocity: @math.Vec2D::zero(),
      rotation: 0.0,
      visible: true,
      state: BeforeThrown,
      alive: true,
      sleep_time: 0.0,
    })
    current_rabbit_index.val = 0
    set_current_rabbit_ready_state(@math.Vec2D(120.0, 280.0))
    assert_true(@physics2d.velocities().contains(entity))
    @physics2d.physics_step_system(1.0 / 60.0)
    let launch_velocity = @math.Vec2D(640.0, -480.0)
    launch_rabbit_at(0, @math.Vec2D(90.0, 330.0), launch_velocity)
    assert_true(!@physics2d.velocities().contains(entity))
    let immediate_velocity = @physics2d.rigid_body_linear_velocity(entity).unwrap_or(
      @math.Vec2D::zero(),
    )
    assert_true(immediate_velocity[X] > 600.0)
    assert_true(immediate_velocity[Y] < -400.0)
    @physics2d.physics_step_system(1.0 / 60.0)
    sync_physics_snapshots()
    assert_true(rabbits[0].velocity[X] > 600.0)
    assert_true(rabbits[0].velocity[Y] < -350.0)
  })
}

///|
test "input release uses current mouse position for launch" {
  let files : Map[String, Bytes] = Map::new()
  let level_json =
    #|{
    #|  "externalLevels": false,
    #|  "defs": {
    #|    "layers": [
    #|      {
    #|        "identifier": "Entities",
    #|        "uid": 201,
    #|        "type": "Entities",
    #|        "intGridValues": []
    #|      },
    #|      {
    #|        "identifier": "Decor",
    #|        "uid": 202,
    #|        "type": "Entities",
    #|        "intGridValues": [],
    #|        "uiColor": "#7ACB7A"
    #|      }
    #|    ],
    #|    "entities": [],
    #|    "enums": [],
    #|    "externalEnums": [],
    #|    "tilesets": []
    #|  },
    #|  "levels": [
    #|    {
    #|      "identifier": "Level_0",
    #|      "iid": "level-0",
    #|      "uid": 1,
    #|      "worldX": 0,
    #|      "worldY": 0,
    #|      "pxWid": 640,
    #|      "pxHei": 480,
    #|      "__neighbours": [],
    #|      "fieldInstances": [
    #|        {
    #|          "__identifier": "max_shots",
    #|          "__type": "Int",
    #|          "__value": 5
    #|        }
    #|      ],
    #|      "layerInstances": [
    #|        {
    #|          "iid": "layer-decor",
    #|          "__identifier": "Decor",
    #|          "__type": "Entities",
    #|          "levelId": 1,
    #|          "layerDefUid": 202,
    #|          "__cWid": 160,
    #|          "__cHei": 120,
    #|          "__gridSize": 4,
    #|          "__opacity": 1,
    #|          "visible": true,
    #|          "optionalRules": [],
    #|          "__pxTotalOffsetX": 0,
    #|          "__pxTotalOffsetY": 0,
    #|          "intGridCsv": [],
    #|          "autoLayerTiles": [],
    #|          "seed": 0,
    #|          "overrideTilesetUid": null,
    #|          "gridTiles": [],
    #|          "entityInstances": [
    #|            {
    #|              "iid": "background",
    #|              "__identifier": "BackgroundRect",
    #|              "defUid": 103,
    #|              "width": 640,
    #|              "height": 480,
    #|              "px": [0, 0],
    #|              "__grid": [0, 0],
    #|              "__pivot": [0, 0],
    #|              "__tags": [],
    #|              "fieldInstances": [
    #|                { "__identifier": "color", "__type": "String", "__value": "rgb(183, 225, 255)" },
    #|                { "__identifier": "zindex", "__type": "Int", "__value": 0 }
    #|              ]
    #|            },
    #|            {
    #|              "iid": "ground",
    #|              "__identifier": "GroundRect",
    #|              "defUid": 104,
    #|              "width": 640,
    #|              "height": 92,
    #|              "px": [0, 388],
    #|              "__grid": [0, 97],
    #|              "__pivot": [0, 0],
    #|              "__tags": [],
    #|              "fieldInstances": [
    #|                { "__identifier": "color", "__type": "String", "__value": "rgb(156, 198, 104)" },
    #|                { "__identifier": "zindex", "__type": "Int", "__value": 2 }
    #|              ]
    #|            },
    #|            {
    #|              "iid": "hill",
    #|              "__identifier": "HillCircle",
    #|              "defUid": 105,
    #|              "width": 240,
    #|              "height": 240,
    #|              "px": [500, 268],
    #|              "__grid": [125, 67],
    #|              "__pivot": [0, 0],
    #|              "__tags": [],
    #|              "fieldInstances": [
    #|                { "__identifier": "color", "__type": "String", "__value": "rgb(154, 211, 132)" },
    #|                { "__identifier": "zindex", "__type": "Int", "__value": 1 }
    #|              ]
    #|            }
    #|          ]
    #|        },
    #|        {
    #|          "iid": "layer-entities",
    #|          "__identifier": "Entities",
    #|          "__type": "Entities",
    #|          "levelId": 1,
    #|          "layerDefUid": 201,
    #|          "__cWid": 160,
    #|          "__cHei": 120,
    #|          "__gridSize": 4,
    #|          "__opacity": 1,
    #|          "visible": true,
    #|          "optionalRules": [],
    #|          "__pxTotalOffsetX": 0,
    #|          "__pxTotalOffsetY": 0,
    #|          "intGridCsv": [],
    #|          "autoLayerTiles": [],
    #|          "seed": 0,
    #|          "overrideTilesetUid": null,
    #|          "gridTiles": [],
    #|          "entityInstances": [
    #|            {
    #|              "iid": "slingshot",
    #|              "__identifier": "SlingshotAnchor",
    #|              "defUid": 101,
    #|              "width": 0,
    #|              "height": 0,
    #|              "px": [120, 280],
    #|              "__grid": [30, 70],
    #|              "__pivot": [0, 0],
    #|              "__tags": [],
    #|              "fieldInstances": []
    #|            },
    #|            {
    #|              "iid": "rabbit",
    #|              "__identifier": "RabbitSpawn",
    #|              "defUid": 102,
    #|              "width": 0,
    #|              "height": 0,
    #|              "px": [120, 280],
    #|              "__grid": [30, 70],
    #|              "__pivot": [0, 0],
    #|              "__tags": [],
    #|              "fieldInstances": []
    #|            },
    #|            {
    #|              "iid": "slingshot-front",
    #|              "__identifier": "SlingshotFrontStick",
    #|              "defUid": 108,
    #|              "width": 26,
    #|              "height": 94,
    #|              "px": [106, 179],
    #|              "__grid": [26, 44],
    #|              "__pivot": [0, 0],
    #|              "__tags": [],
    #|              "fieldInstances": []
    #|            },
    #|            {
    #|              "iid": "slingshot-back",
    #|              "__identifier": "SlingshotBackStick",
    #|              "defUid": 109,
    #|              "width": 26,
    #|              "height": 57,
    #|              "px": [106, 274],
    #|              "__grid": [26, 68],
    #|              "__pivot": [0, 0],
    #|              "__tags": [],
    #|              "fieldInstances": []
    #|            }
    #|          ]
    #|        }
    #|      ]
    #|    }
    #|  ]
    #|}
  files.set("levels/input_release.ldtk", utf8_bytes(level_json))
  with_fake_asset_io(files, fn() raise {
    with_test_world(fn() raise {
      let previous_path = current_level_path.val
      defer {
        current_level_path.val = previous_path
        reset_mouse_state()
      }
      @system.configure_display(VIEWPORT_WIDTH, VIEWPORT_HEIGHT, ZOOM)
      reset_mouse_state()
      current_level_path.val = "levels/input_release.ldtk"
      reset_level()
      start_move_current_rabbit_to_slingshot()
      for _ in 0..<20 {
        @time.set_delta(1.0 / 60.0)
        simulation_system(@ecs.require_current_world())
      }
      let anchor_screen = world_to_screen_for_test(slingshot_anchor())
      let release_world = slingshot_anchor() + @math.Vec2D(-60.0, 60.0)
      let release_screen = world_to_screen_for_test(release_world)

      @inputs.mouse.pos = anchor_screen
      @inputs.mouse.left_button = true
      @inputs.advanced_mouse_system(0.0)
      input_system(@ecs.require_current_world())

      @inputs.mouse.pos = release_screen
      @inputs.mouse.left_button = true
      @inputs.advanced_mouse_system(0.0)
      input_system(@ecs.require_current_world())

      @inputs.mouse.pos = release_screen
      @inputs.mouse.left_button = false
      @inputs.advanced_mouse_system(0.0)
      input_system(@ecs.require_current_world())

      assert_true(slingshot_state.val is BirdFlying)
      assert_true(rabbit_velocity.val[X] > 0.0)
      assert_true(rabbit_velocity.val[Y] < 0.0)
      @time.set_delta(1.0 / 60.0)
      simulation_system(@ecs.require_current_world())
      @physics2d.physics_step_system(1.0 / 60.0)
      sync_physics_snapshots()
      assert_true(rabbit_velocity.val[X] > 0.0)
      assert_true(rabbit_velocity.val[Y] < 0.0)
    })
  })
}

///|
test "rabbit high-speed hit destroys block" {
  let files : Map[String, Bytes] = Map::new()
  let level_json =
    #|{
    #|  "externalLevels": false,
    #|  "defs": {
    #|    "layers": [
    #|      {
    #|        "identifier": "Entities",
    #|        "uid": 201,
    #|        "type": "Entities",
    #|        "intGridValues": []
    #|      },
    #|      {
    #|        "identifier": "Decor",
    #|        "uid": 202,
    #|        "type": "Entities",
    #|        "intGridValues": [],
    #|        "uiColor": "#7ACB7A"
    #|      }
    #|    ],
    #|    "entities": [],
    #|    "enums": [],
    #|    "externalEnums": [],
    #|    "tilesets": []
    #|  },
    #|  "levels": [
    #|    {
    #|      "identifier": "Level_0",
    #|      "iid": "level-0",
    #|      "uid": 1,
    #|      "worldX": 0,
    #|      "worldY": 0,
    #|      "pxWid": 640,
    #|      "pxHei": 480,
    #|      "__neighbours": [],
    #|      "fieldInstances": [
    #|        {
    #|          "__identifier": "max_shots",
    #|          "__type": "Int",
    #|          "__value": 5
    #|        }
    #|      ],
    #|      "layerInstances": [
    #|        {
    #|          "iid": "layer-decor",
    #|          "__identifier": "Decor",
    #|          "__type": "Entities",
    #|          "levelId": 1,
    #|          "layerDefUid": 202,
    #|          "__cWid": 160,
    #|          "__cHei": 120,
    #|          "__gridSize": 4,
    #|          "__opacity": 1,
    #|          "visible": true,
    #|          "optionalRules": [],
    #|          "__pxTotalOffsetX": 0,
    #|          "__pxTotalOffsetY": 0,
    #|          "intGridCsv": [],
    #|          "autoLayerTiles": [],
    #|          "seed": 0,
    #|          "overrideTilesetUid": null,
    #|          "gridTiles": [],
    #|          "entityInstances": [
    #|            {
    #|              "iid": "background",
    #|              "__identifier": "BackgroundRect",
    #|              "defUid": 103,
    #|              "width": 640,
    #|              "height": 480,
    #|              "px": [
    #|                0,
    #|                0
    #|              ],
    #|              "__grid": [
    #|                0,
    #|                0
    #|              ],
    #|              "__pivot": [
    #|                0,
    #|                0
    #|              ],
    #|              "__tags": [],
    #|              "fieldInstances": [
    #|                {
    #|                  "__identifier": "color",
    #|                  "__type": "String",
    #|                  "__value": "rgb(183, 225, 255)"
    #|                },
    #|                {
    #|                  "__identifier": "zindex",
    #|                  "__type": "Int",
    #|                  "__value": 0
    #|                }
    #|              ]
    #|            },
    #|            {
    #|              "iid": "ground",
    #|              "__identifier": "GroundRect",
    #|              "defUid": 104,
    #|              "width": 640,
    #|              "height": 92,
    #|              "px": [
    #|                0,
    #|                388
    #|              ],
    #|              "__grid": [
    #|                0,
    #|                97
    #|              ],
    #|              "__pivot": [
    #|                0,
    #|                0
    #|              ],
    #|              "__tags": [],
    #|              "fieldInstances": [
    #|                {
    #|                  "__identifier": "color",
    #|                  "__type": "String",
    #|                  "__value": "rgb(156, 198, 104)"
    #|                },
    #|                {
    #|                  "__identifier": "zindex",
    #|                  "__type": "Int",
    #|                  "__value": 2
    #|                }
    #|              ]
    #|            },
    #|            {
    #|              "iid": "hill",
    #|              "__identifier": "HillCircle",
    #|              "defUid": 105,
    #|              "width": 200,
    #|              "height": 200,
    #|              "px": [
    #|                440,
    #|                188
    #|              ],
    #|              "__grid": [
    #|                110,
    #|                47
    #|              ],
    #|              "__pivot": [
    #|                0,
    #|                0
    #|              ],
    #|              "__tags": [],
    #|              "fieldInstances": [
    #|                {
    #|                  "__identifier": "color",
    #|                  "__type": "String",
    #|                  "__value": "rgb(154, 211, 132)"
    #|                },
    #|                {
    #|                  "__identifier": "zindex",
    #|                  "__type": "Int",
    #|                  "__value": 1
    #|                }
    #|              ]
    #|            }
    #|          ]
    #|        },
    #|        {
    #|          "iid": "layer-entities",
    #|          "__identifier": "Entities",
    #|          "__type": "Entities",
    #|          "levelId": 1,
    #|          "layerDefUid": 201,
    #|          "__cWid": 160,
    #|          "__cHei": 120,
    #|          "__gridSize": 4,
    #|          "__opacity": 1,
    #|          "visible": true,
    #|          "optionalRules": [],
    #|          "__pxTotalOffsetX": 0,
    #|          "__pxTotalOffsetY": 0,
    #|          "intGridCsv": [],
    #|          "autoLayerTiles": [],
    #|          "seed": 0,
    #|          "overrideTilesetUid": null,
    #|          "gridTiles": [],
    #|          "entityInstances": [
    #|            {
    #|              "iid": "slingshot",
    #|              "__identifier": "SlingshotAnchor",
    #|              "defUid": 101,
    #|              "width": 0,
    #|              "height": 0,
    #|              "px": [
    #|                120,
    #|                280
    #|              ],
    #|              "__grid": [
    #|                30,
    #|                70
    #|              ],
    #|              "__pivot": [
    #|                0,
    #|                0
    #|              ],
    #|              "__tags": [],
    #|              "fieldInstances": []
    #|            },
    #|            {
    #|              "iid": "rabbit",
    #|              "__identifier": "RabbitSpawn",
    #|              "defUid": 102,
    #|              "width": 0,
    #|              "height": 0,
    #|              "px": [
    #|                120,
    #|                280
    #|              ],
    #|              "__grid": [
    #|                30,
    #|                70
    #|              ],
    #|              "__pivot": [
    #|                0,
    #|                0
    #|              ],
    #|              "__tags": [],
    #|              "fieldInstances": []
    #|            },
    #|            {
    #|              "iid": "slingshot-front",
    #|              "__identifier": "SlingshotFrontStick",
    #|              "defUid": 108,
    #|              "width": 26,
    #|              "height": 94,
    #|              "px": [
    #|                106,
    #|                179
    #|              ],
    #|              "__grid": [
    #|                26,
    #|                44
    #|              ],
    #|              "__pivot": [
    #|                0,
    #|                0
    #|              ],
    #|              "__tags": [],
    #|              "fieldInstances": []
    #|            },
    #|            {
    #|              "iid": "slingshot-back",
    #|              "__identifier": "SlingshotBackStick",
    #|              "defUid": 109,
    #|              "width": 26,
    #|              "height": 57,
    #|              "px": [
    #|                106,
    #|                274
    #|              ],
    #|              "__grid": [
    #|                26,
    #|                68
    #|              ],
    #|              "__pivot": [
    #|                0,
    #|                0
    #|              ],
    #|              "__tags": [],
    #|              "fieldInstances": []
    #|            },
    #|            {
    #|              "iid": "block-1",
    #|              "__identifier": "Block",
    #|              "defUid": 106,
    #|              "width": 32,
    #|              "height": 64,
    #|              "px": [
    #|                160,
    #|                248
    #|              ],
    #|              "__grid": [
    #|                40,
    #|                62
    #|              ],
    #|              "__pivot": [
    #|                0,
    #|                0
    #|              ],
    #|              "__tags": [],
    #|              "fieldInstances": [
    #|                {
    #|                  "__identifier": "color",
    #|                  "__type": "String",
    #|                  "__value": "rgb(191,132,78)"
    #|                }
    #|              ]
    #|            },
    #|            {
    #|              "iid": "target-1",
    #|              "__identifier": "Target",
    #|              "defUid": 107,
    #|              "width": 40,
    #|              "height": 40,
    #|              "px": [
    #|                500,
    #|                348
    #|              ],
    #|              "__grid": [
    #|                125,
    #|                87
    #|              ],
    #|              "__pivot": [
    #|                0,
    #|                0
    #|              ],
    #|              "__tags": [],
    #|              "fieldInstances": [
    #|                {
    #|                  "__identifier": "color",
    #|                  "__type": "String",
    #|                  "__value": "rgb(112, 209, 115)"
    #|                },
    #|                {
    #|                  "__identifier": "radius",
    #|                  "__type": "Float",
    #|                  "__value": 20
    #|                }
    #|              ]
    #|            }
    #|          ]
    #|        }
    #|      ]
    #|    }
    #|  ]
    #|}
  files.set("levels/block.ldtk", utf8_bytes(level_json))
  with_fake_asset_io(files, fn() raise {
    with_test_world(fn() raise {
      let previous_path = current_level_path.val
      defer {
        current_level_path.val = previous_path
      }
      current_level_path.val = "levels/block.ldtk"
      reset_level()
      rabbit_velocity.val = @math.Vec2D(1200.0, 0.0)
      rabbits[0] = { ..rabbits[0], velocity: @math.Vec2D(1200.0, 0.0) }
      apply_contact_damage(blocks[0].entity, rabbits[0].entity)
      assert_true(!blocks[0].alive)
    })
  })
}

///|
test "settled rabbit advances to next shot when targets remain" {
  let files : Map[String, Bytes] = Map::new()
  let level_json =
    #|{
    #|  "externalLevels": false,
    #|  "defs": {
    #|    "layers": [
    #|      {
    #|        "identifier": "Entities",
    #|        "uid": 201,
    #|        "type": "Entities",
    #|        "intGridValues": []
    #|      },
    #|      {
    #|        "identifier": "Decor",
    #|        "uid": 202,
    #|        "type": "Entities",
    #|        "intGridValues": [],
    #|        "uiColor": "#7ACB7A"
    #|      }
    #|    ],
    #|    "entities": [],
    #|    "enums": [],
    #|    "externalEnums": [],
    #|    "tilesets": []
    #|  },
    #|  "levels": [
    #|    {
    #|      "identifier": "Level_0",
    #|      "iid": "level-0",
    #|      "uid": 1,
    #|      "worldX": 0,
    #|      "worldY": 0,
    #|      "pxWid": 640,
    #|      "pxHei": 480,
    #|      "__neighbours": [],
    #|      "fieldInstances": [
    #|        {
    #|          "__identifier": "max_shots",
    #|          "__type": "Int",
    #|          "__value": 5
    #|        }
    #|      ],
    #|      "layerInstances": [
    #|        {
    #|          "iid": "layer-decor",
    #|          "__identifier": "Decor",
    #|          "__type": "Entities",
    #|          "levelId": 1,
    #|          "layerDefUid": 202,
    #|          "__cWid": 160,
    #|          "__cHei": 120,
    #|          "__gridSize": 4,
    #|          "__opacity": 1,
    #|          "visible": true,
    #|          "optionalRules": [],
    #|          "__pxTotalOffsetX": 0,
    #|          "__pxTotalOffsetY": 0,
    #|          "intGridCsv": [],
    #|          "autoLayerTiles": [],
    #|          "seed": 0,
    #|          "overrideTilesetUid": null,
    #|          "gridTiles": [],
    #|          "entityInstances": [
    #|            {
    #|              "iid": "background",
    #|              "__identifier": "BackgroundRect",
    #|              "defUid": 103,
    #|              "width": 640,
    #|              "height": 480,
    #|              "px": [
    #|                0,
    #|                0
    #|              ],
    #|              "__grid": [
    #|                0,
    #|                0
    #|              ],
    #|              "__pivot": [
    #|                0,
    #|                0
    #|              ],
    #|              "__tags": [],
    #|              "fieldInstances": [
    #|                {
    #|                  "__identifier": "color",
    #|                  "__type": "String",
    #|                  "__value": "rgb(183, 225, 255)"
    #|                },
    #|                {
    #|                  "__identifier": "zindex",
    #|                  "__type": "Int",
    #|                  "__value": 0
    #|                }
    #|              ]
    #|            },
    #|            {
    #|              "iid": "ground",
    #|              "__identifier": "GroundRect",
    #|              "defUid": 104,
    #|              "width": 640,
    #|              "height": 92,
    #|              "px": [
    #|                0,
    #|                388
    #|              ],
    #|              "__grid": [
    #|                0,
    #|                97
    #|              ],
    #|              "__pivot": [
    #|                0,
    #|                0
    #|              ],
    #|              "__tags": [],
    #|              "fieldInstances": [
    #|                {
    #|                  "__identifier": "color",
    #|                  "__type": "String",
    #|                  "__value": "rgb(156, 198, 104)"
    #|                },
    #|                {
    #|                  "__identifier": "zindex",
    #|                  "__type": "Int",
    #|                  "__value": 2
    #|                }
    #|              ]
    #|            },
    #|            {
    #|              "iid": "hill",
    #|              "__identifier": "HillCircle",
    #|              "defUid": 105,
    #|              "width": 200,
    #|              "height": 200,
    #|              "px": [
    #|                440,
    #|                188
    #|              ],
    #|              "__grid": [
    #|                110,
    #|                47
    #|              ],
    #|              "__pivot": [
    #|                0,
    #|                0
    #|              ],
    #|              "__tags": [],
    #|              "fieldInstances": [
    #|                {
    #|                  "__identifier": "color",
    #|                  "__type": "String",
    #|                  "__value": "rgb(154, 211, 132)"
    #|                },
    #|                {
    #|                  "__identifier": "zindex",
    #|                  "__type": "Int",
    #|                  "__value": 1
    #|                }
    #|              ]
    #|            }
    #|          ]
    #|        },
    #|        {
    #|          "iid": "layer-entities",
    #|          "__identifier": "Entities",
    #|          "__type": "Entities",
    #|          "levelId": 1,
    #|          "layerDefUid": 201,
    #|          "__cWid": 160,
    #|          "__cHei": 120,
    #|          "__gridSize": 4,
    #|          "__opacity": 1,
    #|          "visible": true,
    #|          "optionalRules": [],
    #|          "__pxTotalOffsetX": 0,
    #|          "__pxTotalOffsetY": 0,
    #|          "intGridCsv": [],
    #|          "autoLayerTiles": [],
    #|          "seed": 0,
    #|          "overrideTilesetUid": null,
    #|          "gridTiles": [],
    #|          "entityInstances": [
    #|            {
    #|              "iid": "slingshot",
    #|              "__identifier": "SlingshotAnchor",
    #|              "defUid": 101,
    #|              "width": 0,
    #|              "height": 0,
    #|              "px": [
    #|                120,
    #|                280
    #|              ],
    #|              "__grid": [
    #|                30,
    #|                70
    #|              ],
    #|              "__pivot": [
    #|                0,
    #|                0
    #|              ],
    #|              "__tags": [],
    #|              "fieldInstances": []
    #|            },
    #|            {
    #|              "iid": "rabbit",
    #|              "__identifier": "RabbitSpawn",
    #|              "defUid": 102,
    #|              "width": 0,
    #|              "height": 0,
    #|              "px": [
    #|                120,
    #|                280
    #|              ],
    #|              "__grid": [
    #|                30,
    #|                70
    #|              ],
    #|              "__pivot": [
    #|                0,
    #|                0
    #|              ],
    #|              "__tags": [],
    #|              "fieldInstances": []
    #|            },
    #|            {
    #|              "iid": "slingshot-front",
    #|              "__identifier": "SlingshotFrontStick",
    #|              "defUid": 108,
    #|              "width": 26,
    #|              "height": 94,
    #|              "px": [
    #|                106,
    #|                179
    #|              ],
    #|              "__grid": [
    #|                26,
    #|                44
    #|              ],
    #|              "__pivot": [
    #|                0,
    #|                0
    #|              ],
    #|              "__tags": [],
    #|              "fieldInstances": []
    #|            },
    #|            {
    #|              "iid": "slingshot-back",
    #|              "__identifier": "SlingshotBackStick",
    #|              "defUid": 109,
    #|              "width": 26,
    #|              "height": 57,
    #|              "px": [
    #|                106,
    #|                274
    #|              ],
    #|              "__grid": [
    #|                26,
    #|                68
    #|              ],
    #|              "__pivot": [
    #|                0,
    #|                0
    #|              ],
    #|              "__tags": [],
    #|              "fieldInstances": []
    #|            },
    #|            {
    #|              "iid": "target-1",
    #|              "__identifier": "Target",
    #|              "defUid": 107,
    #|              "width": 40,
    #|              "height": 40,
    #|              "px": [
    #|                320,
    #|                348
    #|              ],
    #|              "__grid": [
    #|                80,
    #|                87
    #|              ],
    #|              "__pivot": [
    #|                0,
    #|                0
    #|              ],
    #|              "__tags": [],
    #|              "fieldInstances": [
    #|                {
    #|                  "__identifier": "color",
    #|                  "__type": "String",
    #|                  "__value": "rgb(112, 209, 115)"
    #|                },
    #|                {
    #|                  "__identifier": "radius",
    #|                  "__type": "Float",
    #|                  "__value": 20
    #|                }
    #|              ]
    #|            }
    #|          ]
    #|        }
    #|      ]
    #|    }
    #|  ]
    #|}
  files.set("levels/settle.ldtk", utf8_bytes(level_json))
  with_fake_asset_io(files, fn() raise {
    with_test_world(fn() raise {
      let previous_path = current_level_path.val
      defer {
        current_level_path.val = previous_path
      }
      current_level_path.val = "levels/settle.ldtk"
      reset_level()
      game_state.val = Playing
      slingshot_state.val = BirdFlying
      shots_remaining.val = 3
      launch_rabbit(slingshot_anchor(), @math.Vec2D::zero())
      @time.set_delta(1.0 / 60.0)
      simulation_system(@ecs.require_current_world())
      assert_true(game_state.val is BirdMovingToSlingshot)
      assert_eq(shots_remaining.val, 3)
    })
  })
}

///|
test "moving block keeps shot active until world settles" {
  with_test_world(fn() raise {
    blocks.clear()
    targets.clear()
    game_state.val = Playing
    slingshot_state.val = BirdFlying
    shots_remaining.val = 2
    rabbit_visible.val = true
    rabbit_velocity.val = @math.Vec2D::zero()
    blocks.push({
      entity: @entity.Entity::new(),
      center: @math.Vec2D(280.0, 300.0),
      size: @math.Vec2D(40.0, 40.0),
      velocity: @math.Vec2D(STOP_SPEED + 20.0, 0.0),
      rotation: 0.0,
      health: BLOCK_HEALTH,
      alive: true,
    })
    targets.push({
      entity: @entity.Entity::new(),
      center: @math.Vec2D(420.0, 300.0),
      radius: 18.0,
      velocity: @math.Vec2D::zero(),
      rotation: 0.0,
      health: TARGET_HEALTH,
      alive: true,
    })
    @time.set_delta(1.0 / 60.0)
    simulation_system(@ecs.require_current_world())
    assert_true(game_state.val is Playing)
    assert_true(slingshot_state.val is BirdFlying)
  })
}

///|
test "out-of-bounds targets and blocks are cleaned up" {
  with_test_world(fn() raise {
    blocks.clear()
    targets.clear()
    blocks.push({
      entity: @entity.Entity::new(),
      center: @math.Vec2D(-OUT_OF_BOUNDS_MARGIN - 40.0, 200.0),
      size: @math.Vec2D(40.0, 40.0),
      velocity: @math.Vec2D::zero(),
      rotation: 0.0,
      health: BLOCK_HEALTH,
      alive: true,
    })
    targets.push({
      entity: @entity.Entity::new(),
      center: @math.Vec2D(200.0, VIEWPORT_HEIGHT + OUT_OF_BOUNDS_MARGIN + 30.0),
      radius: 18.0,
      velocity: @math.Vec2D::zero(),
      rotation: 0.0,
      health: TARGET_HEALTH,
      alive: true,
    })
    cleanup_out_of_bounds_bodies()
    assert_true(!blocks[0].alive)
    assert_true(!targets[0].alive)
  })
}

///|
test "rabbit contact event always destroys target" {
  with_test_world(fn() raise {
    rabbits.clear()
    targets.clear()
    blocks.clear()
    let rabbit_entity = @entity.Entity::new()
    let target_entity = @entity.Entity::new()
    rabbits.push({
      entity: rabbit_entity,
      center: @math.Vec2D(200.0, 200.0),
      velocity: @math.Vec2D(8.0, 0.0),
      rotation: 0.0,
      visible: true,
      state: Thrown,
      alive: true,
      sleep_time: 0.0,
    })
    current_rabbit_index.val = 0
    targets.push({
      entity: target_entity,
      center: @math.Vec2D(200.0, 200.0),
      radius: 18.0,
      velocity: @math.Vec2D::zero(),
      rotation: 0.0,
      health: TARGET_HEALTH,
      alive: true,
    })
    game_state.val = Playing
    slingshot_state.val = BirdFlying
    rabbit_velocity.val = @math.Vec2D(8.0, 0.0)
    apply_contact_damage(target_entity, rabbit_entity)
    assert_true(!targets[0].alive)
  })
}

///|
test "target takes upstream-style damage from moving block" {
  with_test_world(fn() raise {
    targets.clear()
    blocks.clear()
    let block_entity = @entity.Entity::new()
    let target_entity = @entity.Entity::new()
    blocks.push({
      entity: block_entity,
      center: @math.Vec2D(320.0, 300.0),
      size: @math.Vec2D(40.0, 40.0),
      velocity: @math.Vec2D(1600.0, 0.0),
      rotation: 0.0,
      health: BLOCK_HEALTH,
      alive: true,
    })
    targets.push({
      entity: target_entity,
      center: @math.Vec2D(320.0, 300.0),
      radius: 18.0,
      velocity: @math.Vec2D::zero(),
      rotation: 0.0,
      health: TARGET_HEALTH,
      alive: true,
    })
    apply_contact_damage(target_entity, block_entity)
    assert_true(!targets[0].alive)
  })
}
