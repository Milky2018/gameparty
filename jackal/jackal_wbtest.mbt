///|
fn assert_rect_map(rows : Array[String]) -> Unit raise {
  assert_true(rows.length() > 0)
  let width = rows[0].length()
  for row in rows {
    assert_eq(row.length(), width)
  }
}

///|
test "stage maps are rectangular" {
  for stage in plugin.campaign.stages {
    assert_rect_map(stage.map.rows)
  }
}

///|
test "jackal campaign plugin validates" {
  assert_eq(@topdown_action.validate_campaign_plugin(plugin), None)
}
