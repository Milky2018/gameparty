///|
pub(all) enum RunPhase {
  Boot
  Playing
  Dialogue
} derive(Eq, Debug)

///|
pub(all) struct DialogueLineDef {
  speaker : String
  text : String
}

///|
pub(all) struct DialogueScriptDef {
  id : String
  lines : Array[DialogueLineDef]
}

///|
pub(all) struct NpcDef {
  id : String
  archetype_id : String
  spawn_tag : String
  facing : @topdown_platform.Facing
  display_name : String
  dialogue_id : String
}

///|
pub(all) struct DialogueSettingsDef {
  interaction_radius : Double
  interact_prompt : String
  advance_hint : String
}

///|
pub(all) struct ColorDef {
  r : UInt
  g : UInt
  b : UInt
  a : Double
}

///|
pub(all) struct DialogueThemeDef {
  prompt_color_css : String
  speaker_color_css : String
  text_color_css : String
  hint_color_css : String
  panel_color : ColorDef
}

///|
pub(all) struct PluginRuntimeState {
  phase : RunPhase
  player_cell_x : Int
  player_cell_y : Int
  npc_count : Int
  active_npc_id : String?
  active_dialogue_id : String?
  active_line_index : Int
}

///|
pub(all) struct TopDownHooks {
  on_run_start : ((PluginRuntimeState) -> Unit)?
  on_dialogue_started : ((PluginRuntimeState, String, String) -> Unit)?
  on_dialogue_finished : ((PluginRuntimeState, String, String) -> Unit)?
}

///|
pub(all) struct TopDownPluginDef {
  meta : @topdown_platform.PluginMeta
  map : @topdown_platform.MapDef
  player_archetype_id : String
  archetypes : Array[@topdown_platform.ArchetypeDef]
  npcs : Array[NpcDef]
  dialogues : Array[DialogueScriptDef]
  settings : DialogueSettingsDef
  ui_theme : @topdown_platform.UiThemeDef
  dialogue_theme : DialogueThemeDef
  hooks : TopDownHooks?
}

///|
fn archetype_by_id(
  plugin : TopDownPluginDef,
  id : String,
) -> @topdown_platform.ArchetypeDef? {
  for archetype in plugin.archetypes {
    if archetype.id == id {
      return Some(archetype)
    }
  }
  None
}

///|
fn dialogue_by_id(plugin : TopDownPluginDef, id : String) -> DialogueScriptDef? {
  for dialogue in plugin.dialogues {
    if dialogue.id == id {
      return Some(dialogue)
    }
  }
  None
}
