# Mooncraft

`mooncraft` is a Selene ECS rewrite of the Mooncraft prototype for the `gameparty` repository.

The package keeps `mooncraft_core` as a pure MoonBit logic layer for world generation, block and item registries, placement rules, and chunk mesh construction. The runtime layer in this package is a separate native desktop implementation built on top of Selene and raylib.

## Scope

This first stage is a first-person creative prototype. It includes:

- four world types
- chunk streaming around the player
- textured block rendering
- ground movement with gravity and jumping
- raycast block selection, breaking, placing, and middle-click sampling
- a 9-slot hotbar and a creative inventory catalog
- demo glTF entities with looping animation
- no save system

It does **not** reuse the upstream browser runtime, JavaScript renderer, DOM UI, or localStorage logic.

## Packages

- `mooncraft_core/`: pure world/block/item/generation logic reused by the runtime
- `mooncraft/`: Selene ECS runtime, assets, systems, and tests
- `cmd/mooncraft`: native entry point

## Run

```bash
moon run cmd/mooncraft
```

## Controls

### Camera and movement

- `Left Mouse`: lock the mouse cursor and enable first-person look
- `W A S D`: move
- `Space`: jump
- `Left Shift`: slow walk
- `Esc`: if the inventory is open, close it; otherwise release the mouse first, then exit on the next press

### Block interaction

- `Left Mouse`: break the targeted block
- `Right Mouse`: place the currently selected block against the targeted face
- `Middle Mouse`: sample the targeted block into the current hotbar slot

### Hotbar and inventory

- `Mouse Wheel`: cycle hotbar slots
- `Tab`: cycle hotbar slots, reverse when `Left Shift` is held
- `E`: open or close the inventory catalog
- `Left Mouse` in inventory: put the clicked catalog item into the current hotbar slot

### World management

- `Q`: regenerate as `Infinite`
- `Z`: regenerate as `Finite`
- `X`: regenerate as `Flat`
- `C`: regenerate as `PreClassic`
- `R`: regenerate the current world type with the current seed

These shortcuts use the keys currently exposed by Selene's input API. The intended `F1-F4` and digit hotbar bindings are not available yet in the current engine surface.

## Runtime Notes

- World edits are stored only in memory for the current process.
- Breaking or placing a block marks only the affected chunk and its boundary neighbors dirty.
- Chunk generation, rebuild, and unload are budgeted across frames to avoid rebuilding the whole world every tick.
- The current player controller is ground-based; there is no survival mode, health, crafting, or persistence.

## Assets and Notices

Runtime textures, GUI images, and demo assets are copied from the upstream Mooncraft project into `mooncraft/assets/` for compatibility with the native prototype.

See [assets/README.md](/Users/zhengyu/Documents/projects/gameparty/mooncraft/assets/README.md) for the Minecraft EULA and upstream asset notice.

## Verification

```bash
moon check mooncraft
moon check cmd/mooncraft
moon test mooncraft -v
```
