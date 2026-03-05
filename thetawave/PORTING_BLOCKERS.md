# Thetawave Porting Blockers (Selene vs Upstream Bevy)

Last updated: 2026-03-04

## Confirmed engine/API gaps

1. Selene picture sprite currently has no runtime tint/alpha field for texture sprites.
   - Upstream border gradient effect animates alpha with sine easing.
   - Current port can only approximate with height pulse + visibility toggle on gradient textures.
   - Upstream source: `upstream-rust/src/ui/game/border_gradient.rs`.

2. 3D scene/model parity is still not complete even after moving to Selene 0.22.2.
   - Port now uses Selene 3D pipeline (textured quad + star + rotating planet sphere), but upstream uses random planet model scenes, bloom-driven star lighting, and richer PBR behavior.
   - Current `scene3d` loader path in Selene is JSON glTF-oriented (`load_scene_gltf` parses textual JSON scene bytes). Upstream asset usage includes binary `.glb` model pipelines (`assets/models/earth.glb`, `assets/models/sun.glb`) and Bevy scene behavior not yet mirrored 1:1 here.
   - Upstream source: `upstream-rust/src/background/mod.rs`.

## Resolved by Selene 0.22.x adoption

1. `backend.request_close()` is available.
   - Port now maps main menu `Exit Game` to `@system.exit()`.
   - Upstream source: `upstream-rust/src/ui/button.rs`.

2. Gamepad abstraction and input queries are available.
   - Port now supports gamepad navigation in menu/character-selection/in-game pause flow and gameplay control.
   - Upstream sources: `upstream-rust/src/ui/character_selection.rs`, `upstream-rust/src/options/input.ron`.

3. `ui` button interaction system is available.
   - Port now uses Selene UI button interactions for main menu hover/press behavior instead of manual mouse-position heuristics.

4. `KeyQ` keyboard input is available.
   - Port now maps slot-two ability to `Q` (while keeping mouse/gamepad mappings aligned).
   - Upstream source: `upstream-rust/src/options/input.ron`.

5. Selene 3D rendering pipeline is available.
   - Port now renders game background with 3D assets (textured quad, star body, rotating planet body) and randomization semantics aligned to upstream parameters.
   - Upstream source: `upstream-rust/src/background/mod.rs`.

## High-cost non-blocking gaps (possible, not yet fully ported)

1. Bevy UI node/flex hierarchy and per-widget interaction are not yet fully reconstructed in Selene.
   - Current implementation uses manual pixel layout and sprite/text composition.
   - Character-selection dual-column slot content/join-ready flow is now mirrored, but it is still not a Bevy-style flex tree with per-widget button entities.
   - Current run loop remains single-player; if multiple players are marked ready, port still starts with player-1 character only.
   - Top phase row text still cannot fully match Bevy `NodeBundle` clipping/wrapping semantics (especially tutorial phase data lists) because Selene text sprites are drawn without parent layout clipping; current port uses split anchors + dedicated tutorial line entities as an approximation.
   - Upstream sources: `upstream-rust/src/ui/game/phase.rs`, `upstream-rust/src/ui/game/parent.rs`.

2. Composite boss/mob behavioral parity is still incomplete.
   - Port now includes synchronized multi-part visuals plus Ferritharax/MechaFerritharax/MechaSaucetron phase sequences (stage movement, side mob spawners, arm missiles/weapon cadence) mapped from upstream `assets/data/*.ron`.
   - Upstream segment-level HP/collision/joint graph/disconnect behavior (`disconnected_behaviors`, `DisableWeapons`, per-segment damage routing) is still not 1:1 because Selene port currently models these bosses as single enemy entities with visual attachments only.
   - Upstream sources: `upstream-rust/src/spawnable/mob/mod.rs`, `upstream-rust/src/spawnable/mob/mob_segment/mod.rs`.
