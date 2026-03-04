# Thetawave Porting Blockers (Selene vs Upstream Bevy)

Last updated: 2026-03-04

## Confirmed engine/API gaps

1. Keyboard `ShiftLeft` input is unavailable in current Selene keycode API.
   - Upstream mapping uses `SlotTwoAbility = ShiftLeft`.
   - Current port can only keep mouse right click for slot two without a non-upstream keyboard remap.
   - Upstream source: `upstream-rust/src/options/input.ron`.

2. Upstream 3D background pipeline (mesh/material/scene/light) has no 1:1 feature in Selene 2D.
   - Upstream generates random 3D planets/stars/background quads and rotates models.
   - Current port can only use 2D texture backgrounds.
   - Upstream source: `upstream-rust/src/background/mod.rs`.

3. Selene picture sprite currently has no runtime tint/alpha field for texture sprites.
   - Upstream border gradient effect animates alpha with sine easing.
   - Current port can only approximate with height pulse + visibility toggle on gradient textures.
   - Upstream source: `upstream-rust/src/ui/game/border_gradient.rs`.

## Resolved by Selene 0.22.0 adoption

1. `backend.request_close()` is available.
   - Port now maps main menu `Exit Game` to `@backend.request_close()`.
   - Upstream source: `upstream-rust/src/ui/button.rs`.

2. Gamepad abstraction and input queries are available.
   - Port now supports gamepad navigation in menu/character-selection/in-game pause flow and gameplay control.
   - Upstream sources: `upstream-rust/src/ui/character_selection.rs`, `upstream-rust/src/options/input.ron`.

3. `ui` button interaction system is available.
   - Port now uses Selene UI button interactions for main menu hover/press behavior instead of manual mouse-position heuristics.

## High-cost non-blocking gaps (possible, not yet fully ported)

1. Bevy UI node/flex hierarchy and per-widget interaction are not yet fully reconstructed in Selene.
   - Current implementation uses manual pixel layout and sprite/text composition.
   - Remaining differences include exact multi-player character-selection UI hierarchy and bar widgets.

2. Composite boss/mob visual structure (multi-part entities with child transforms/animations) is simplified.
   - Current mobs use single-sprite approximations where upstream uses multiple synchronized parts.
