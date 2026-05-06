#!/usr/bin/env python3
from __future__ import annotations

import random
from pathlib import Path
from typing import Callable, Dict, Iterable, List, Tuple

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
ASSET_DIR = ROOT / "assets" / "jackal"
FRAME_SIZE = 32
STRIP_FRAMES = 4
TILE_SIZE = 64

Color = Tuple[int, int, int, int]
Point = Tuple[int, int]


TRANSPARENT: Color = (0, 0, 0, 0)
INK: Color = (18, 20, 20, 255)
OUTLINE: Color = (7, 9, 9, 255)
TIRE: Color = (22, 25, 24, 255)
TIRE_HI: Color = (55, 59, 56, 255)
GLASS: Color = (186, 230, 230, 255)
GLASS_DARK: Color = (81, 130, 130, 255)
JACKAL_GREEN: Color = (86, 116, 36, 255)
JACKAL_GREEN_HI: Color = (142, 169, 67, 255)
JACKAL_GREEN_DARK: Color = (34, 52, 24, 255)
FIELD_DARK: Color = (31, 62, 38, 255)
FIELD_MID: Color = (43, 82, 45, 255)
FIELD_HI: Color = (67, 110, 54, 255)
DIRT_DARK: Color = (91, 69, 35, 255)
DIRT_MID: Color = (130, 91, 42, 255)
DIRT_HI: Color = (166, 124, 57, 255)


def ensure_dirs() -> None:
    for name in (
        "jeep",
        "soldier",
        "turret",
        "vehicle",
        "fort",
        "roles",
        "terrain",
        "objectives",
    ):
        (ASSET_DIR / name).mkdir(parents=True, exist_ok=True)


def new_frame() -> Image.Image:
    return Image.new("RGBA", (FRAME_SIZE, FRAME_SIZE), TRANSPARENT)


def rect(draw: ImageDraw.ImageDraw, box: Tuple[int, int, int, int], fill: Color) -> None:
    draw.rectangle(box, fill=fill)


def poly(draw: ImageDraw.ImageDraw, points: Iterable[Point], fill: Color) -> None:
    draw.polygon(list(points), fill=fill)


def rotate(frame: Image.Image, direction: str) -> Image.Image:
    if direction == "up":
        return frame
    if direction == "right":
        return frame.transpose(Image.Transpose.ROTATE_270)
    if direction == "down":
        return frame.transpose(Image.Transpose.ROTATE_180)
    if direction == "left":
        return frame.transpose(Image.Transpose.ROTATE_90)
    raise ValueError(f"unknown direction: {direction}")


def direction_angle(direction: str) -> float:
    angles = {
        "up": 0.0,
        "up_right": -45.0,
        "right": -90.0,
        "down_right": -135.0,
        "down": 180.0,
        "down_left": 135.0,
        "left": 90.0,
        "up_left": 45.0,
    }
    return angles[direction]


def rotate_to_direction(frame: Image.Image, direction: str) -> Image.Image:
    if direction == "up":
        return frame
    return frame.rotate(
        direction_angle(direction),
        resample=Image.Resampling.NEAREST,
        center=(FRAME_SIZE / 2, FRAME_SIZE / 2),
    )


def write_strip(
    actor: str,
    direction: str,
    frames: List[Image.Image],
) -> None:
    names = {
        "up": "Back - Running.png",
        "up_right": "UpRight - Running.png",
        "down": "Front - Running.png",
        "down_right": "DownRight - Running.png",
        "left": "Left - Running.png",
        "down_left": "DownLeft - Running.png",
        "right": "Right - Running.png",
        "up_left": "UpLeft - Running.png",
    }
    strip = Image.new("RGBA", (FRAME_SIZE * STRIP_FRAMES, FRAME_SIZE), TRANSPARENT)
    for index, frame in enumerate(frames):
        strip.paste(frame, (index * FRAME_SIZE, 0), frame)
    out_path = ASSET_DIR / actor / names[direction]
    strip.save(out_path)
    print(f"[write] {out_path.relative_to(ROOT)}")


def write_role_sheet(actor: str, frames_by_direction: Dict[str, List[Image.Image]]) -> None:
    row_order = (
        "up",
        "up_right",
        "right",
        "down_right",
        "down",
        "down_left",
        "left",
        "up_left",
    )
    sheet = Image.new(
        "RGBA",
        (FRAME_SIZE * STRIP_FRAMES, FRAME_SIZE * len(row_order)),
        TRANSPARENT,
    )
    for row, direction in enumerate(row_order):
        frames = frames_by_direction[direction]
        for col, frame in enumerate(frames):
            sheet.paste(frame, (col * FRAME_SIZE, row * FRAME_SIZE), frame)
    out_path = ASSET_DIR / "roles" / f"{actor}.png"
    sheet.save(out_path)
    print(f"[write] {out_path.relative_to(ROOT)}")


def draw_jeep_frame(step: int) -> Image.Image:
    img = new_frame()
    d = ImageDraw.Draw(img)
    body = JACKAL_GREEN
    body_hi = JACKAL_GREEN_HI
    body_shadow = JACKAL_GREEN_DARK
    wheel_tick = step % 2

    rect(d, (7, 7, 24, 27), OUTLINE)
    rect(d, (9, 6, 22, 27), body)
    rect(d, (10, 7, 21, 10), body_hi)
    rect(d, (11, 20, 20, 25), body_shadow)
    rect(d, (9, 12, 22, 18), (22, 33, 25, 255))
    rect(d, (10, 13, 15, 16), GLASS)
    rect(d, (17, 13, 21, 16), GLASS)
    rect(d, (13, 2, 18, 8), OUTLINE)
    rect(d, (14, 1, 17, 7), (170, 183, 76, 255))
    rect(d, (6, 10, 8, 18), TIRE)
    rect(d, (23, 10, 25, 18), TIRE)
    rect(d, (7, 21, 9, 27), TIRE)
    rect(d, (22, 21, 24, 27), TIRE)
    rect(d, (7, 11 + wheel_tick, 8, 14 + wheel_tick), TIRE_HI)
    rect(d, (23, 12 - wheel_tick, 24, 15 - wheel_tick), TIRE_HI)
    rect(d, (8, 28, 10, 29), (207, 47, 39, 255))
    rect(d, (21, 28, 23, 29), (207, 47, 39, 255))
    rect(d, (14, 27, 17, 29), (29, 30, 28, 255))
    return img


def draw_tank_frame(step: int) -> Image.Image:
    img = new_frame()
    d = ImageDraw.Draw(img)
    body = (81, 105, 43, 255)
    body_hi = (137, 157, 66, 255)
    body_dark = (31, 45, 28, 255)
    tread = step % 2

    rect(d, (6, 8, 25, 25), OUTLINE)
    rect(d, (8, 7, 23, 25), body)
    rect(d, (10, 8, 21, 11), body_hi)
    rect(d, (11, 16, 20, 22), body_dark)
    rect(d, (6, 10, 8, 24), TIRE)
    rect(d, (23, 10, 25, 24), TIRE)
    for y in range(10 + tread, 25, 5):
        rect(d, (8, y, 9, y + 1), TIRE_HI)
        rect(d, (22, y, 23, y + 1), TIRE_HI)
    rect(d, (12, 11, 19, 17), (55, 72, 38, 255))
    rect(d, (14, 1, 17, 12), OUTLINE)
    rect(d, (15, 0, 16, 11), body_hi)
    rect(d, (13, 12, 18, 15), body_hi)
    return img


def draw_fort_frame(step: int) -> Image.Image:
    img = new_frame()
    d = ImageDraw.Draw(img)
    stone = (78, 84, 70, 255)
    stone_hi = (127, 132, 101, 255)
    stone_dark = (36, 43, 36, 255)
    pulse = step % 2

    rect(d, (4, 12, 27, 27), OUTLINE)
    rect(d, (6, 14, 25, 26), stone)
    rect(d, (8, 14, 23, 16), stone_hi)
    rect(d, (8, 22, 23, 25), stone_dark)
    rect(d, (10, 8, 21, 14), OUTLINE)
    rect(d, (12, 9, 19, 13), stone_hi)
    rect(d, (14, 2, 17, 12), OUTLINE)
    rect(d, (15, 1, 16, 11), (160, 159, 112, 255))
    rect(d, (9, 17, 13, 20), stone_dark)
    rect(d, (18, 17, 22, 20), stone_dark)
    if pulse == 1:
        rect(d, (14, 1, 17, 2), (248, 188, 70, 255))
    return img


def draw_turret_frame(step: int) -> Image.Image:
    img = new_frame()
    d = ImageDraw.Draw(img)
    metal = (76, 87, 67, 255)
    metal_hi = (128, 142, 91, 255)
    recoil = 1 if step == 1 else 0

    rect(d, (9, 13, 22, 23), OUTLINE)
    rect(d, (11, 14, 20, 22), metal)
    rect(d, (13, 15, 18, 19), (39, 46, 39, 255))
    rect(d, (14, 5 + recoil, 17, 15 + recoil), OUTLINE)
    rect(d, (15, 3 + recoil, 16, 14 + recoil), metal_hi)
    rect(d, (7, 23, 24, 25), OUTLINE)
    rect(d, (9, 24, 22, 24), metal_hi)
    return img


def draw_soldier_frame(direction: str, step: int) -> Image.Image:
    img = new_frame()
    d = ImageDraw.Draw(img)
    uniform = (74, 89, 48, 255)
    uniform_hi = (121, 132, 63, 255)
    skin = (177, 121, 71, 255)
    leg_phase = step % 2
    side = 1 if "right" in direction else -1 if "left" in direction else 0

    head_x = 14 + side
    rect(d, (head_x, 7, head_x + 4, 11), OUTLINE)
    rect(d, (head_x + 1, 8, head_x + 3, 10), skin)
    rect(d, (head_x - 1, 5, head_x + 5, 7), OUTLINE)
    rect(d, (head_x, 4, head_x + 4, 6), uniform_hi)
    rect(d, (12, 12, 20, 20), OUTLINE)
    rect(d, (13, 13, 19, 19), uniform)
    rect(d, (14, 14, 18, 15), uniform_hi)
    if direction == "left" or direction == "up_left" or direction == "down_left":
        rect(d, (9, 13, 13, 17), uniform)
        rect(d, (5, 14, 11, 15), (43, 46, 34, 255))
        rect(d, (20, 13, 22, 17), uniform)
    elif direction == "right" or direction == "up_right" or direction == "down_right":
        rect(d, (19, 13, 23, 17), uniform)
        rect(d, (21, 14, 27, 15), (43, 46, 34, 255))
        rect(d, (10, 13, 12, 17), uniform)
    elif direction == "up":
        rect(d, (10, 13, 13, 17), uniform)
        rect(d, (19, 13, 22, 17), uniform)
        rect(d, (15, 1, 16, 7), (43, 46, 34, 255))
    else:
        rect(d, (10, 13, 13, 17), uniform)
        rect(d, (19, 13, 22, 17), uniform)
        rect(d, (15, 18, 16, 24), (43, 46, 34, 255))
    if leg_phase == 0:
        rect(d, (13, 20, 14, 25), uniform)
        rect(d, (18, 20, 19, 24), uniform)
        rect(d, (12, 25, 14, 26), OUTLINE)
        rect(d, (18, 24, 20, 25), OUTLINE)
    else:
        rect(d, (12, 20, 13, 24), uniform)
        rect(d, (18, 20, 20, 25), uniform)
        rect(d, (11, 24, 13, 25), OUTLINE)
        rect(d, (18, 25, 21, 26), OUTLINE)
    return img


def rotated_actor_frames(
    draw_up: Callable[[int], Image.Image],
    direction: str,
) -> List[Image.Image]:
    return [rotate_to_direction(draw_up(step), direction) for step in range(STRIP_FRAMES)]


def soldier_actor_frames(direction: str) -> List[Image.Image]:
    return [draw_soldier_frame(direction, step) for step in range(STRIP_FRAMES)]


def write_actor_strips() -> None:
    actors: Dict[str, Callable[[str], List[Image.Image]]] = {
        "jeep": lambda direction: rotated_actor_frames(draw_jeep_frame, direction),
        "soldier": soldier_actor_frames,
        "turret": lambda direction: rotated_actor_frames(draw_turret_frame, direction),
        "vehicle": lambda direction: rotated_actor_frames(draw_tank_frame, direction),
        "fort": lambda direction: rotated_actor_frames(draw_fort_frame, direction),
    }
    for actor, build_frames in actors.items():
        frames_by_direction: Dict[str, List[Image.Image]] = {}
        for direction in (
            "up",
            "up_right",
            "right",
            "down_right",
            "down",
            "down_left",
            "left",
            "up_left",
        ):
            frames_by_direction[direction] = build_frames(direction)
        write_role_sheet(actor, frames_by_direction)
        for direction, frames in frames_by_direction.items():
            write_strip(actor, direction, frames)


def make_floor(path: Path, seed: int, base: Color, accent: Color) -> None:
    rng = random.Random(seed)
    img = Image.new("RGBA", (TILE_SIZE, TILE_SIZE), base)
    d = ImageDraw.Draw(img)
    for _ in range(42):
        x = rng.randrange(0, TILE_SIZE)
        y = rng.randrange(0, TILE_SIZE)
        length = rng.randrange(2, 8)
        if rng.randrange(2) == 0:
            rect(d, (x, y, min(TILE_SIZE - 1, x + length), y), accent)
        else:
            rect(d, (x, y, x, min(TILE_SIZE - 1, y + length)), accent)
    img.save(path)
    print(f"[write] {path.relative_to(ROOT)}")


def write_grass(path: Path) -> None:
    img = Image.new("RGBA", (TILE_SIZE, TILE_SIZE), FIELD_MID)
    d = ImageDraw.Draw(img)
    for y in range(0, TILE_SIZE, 8):
        for x in range(0, TILE_SIZE, 8):
            variant = (x // 8 + y // 8) % 3
            if variant == 0:
                rect(d, (x + 2, y + 1, x + 2, y + 5), FIELD_HI)
                rect(d, (x + 5, y + 3, x + 6, y + 3), FIELD_DARK)
            elif variant == 1:
                rect(d, (x + 1, y + 5, x + 4, y + 5), FIELD_DARK)
                rect(d, (x + 6, y + 1, x + 6, y + 4), FIELD_HI)
            else:
                rect(d, (x + 3, y + 2, x + 5, y + 2), FIELD_DARK)
                rect(d, (x + 1, y + 6, x + 1, y + 7), FIELD_HI)
    img.save(path)
    print(f"[write] {path.relative_to(ROOT)}")


def write_dirt(path: Path) -> None:
    img = Image.new("RGBA", (TILE_SIZE, TILE_SIZE), DIRT_MID)
    d = ImageDraw.Draw(img)
    for y in range(0, TILE_SIZE, 8):
        for x in range(0, TILE_SIZE, 8):
            rect(d, (x + 1, y + 6, x + 5, y + 6), DIRT_DARK)
            rect(d, (x + 5, y + 2, x + 6, y + 4), DIRT_HI)
            if (x + y) % 16 == 0:
                rect(d, (x + 2, y + 2, x + 3, y + 2), (102, 75, 36, 255))
    img.save(path)
    print(f"[write] {path.relative_to(ROOT)}")


def write_wall() -> None:
    img = Image.new("RGBA", (TILE_SIZE, TILE_SIZE), TRANSPARENT)
    d = ImageDraw.Draw(img)
    rect(d, (2, 4, 61, 59), OUTLINE)
    rect(d, (5, 7, 58, 56), (73, 75, 58, 255))
    colors = [
        (92, 89, 67, 255),
        (126, 116, 76, 255),
        (65, 69, 55, 255),
    ]
    for row, y in enumerate(range(8, 56, 8)):
        offset = 0 if row % 2 == 0 else 7
        for x in range(6 - offset, 59, 14):
            fill = colors[(row + x // 14) % len(colors)]
            rect(d, (x, y, min(57, x + 13), y + 7), fill)
            rect(d, (x, y, min(57, x + 13), y + 1), (158, 145, 91, 255))
    img.save(ASSET_DIR / "terrain" / "wall.png")
    print(f"[write] {(ASSET_DIR / 'terrain' / 'wall.png').relative_to(ROOT)}")


def write_water() -> None:
    img = Image.new("RGBA", (TILE_SIZE, TILE_SIZE), (17, 42, 54, 255))
    d = ImageDraw.Draw(img)
    for y in range(8, TILE_SIZE, 14):
        rect(d, (4, y, 25, y + 1), (42, 93, 109, 255))
        rect(d, (33, y + 5, 58, y + 6), (33, 77, 96, 255))
    for x in range(8, TILE_SIZE, 18):
        rect(d, (x, 21, x + 1, 25), (61, 119, 128, 255))
        rect(d, (x + 7, 45, x + 8, 49), (36, 86, 105, 255))
    out_path = ASSET_DIR / "terrain" / "water.png"
    img.save(out_path)
    print(f"[write] {out_path.relative_to(ROOT)}")


def write_bridge() -> None:
    img = Image.new("RGBA", (TILE_SIZE, TILE_SIZE), (60, 45, 31, 255))
    d = ImageDraw.Draw(img)
    rect(d, (0, 9, 63, 16), (37, 30, 23, 255))
    rect(d, (0, 48, 63, 55), (37, 30, 23, 255))
    for x in range(0, TILE_SIZE, 10):
        rect(d, (x, 17, min(63, x + 7), 47), (104, 78, 45, 255))
        rect(d, (x, 17, min(63, x + 7), 20), (154, 117, 63, 255))
    rect(d, (0, 31, 63, 33), (47, 34, 23, 255))
    out_path = ASSET_DIR / "terrain" / "bridge.png"
    img.save(out_path)
    print(f"[write] {out_path.relative_to(ROOT)}")


def write_terrain() -> None:
    write_grass(ASSET_DIR / "terrain" / "floor.png")
    write_dirt(ASSET_DIR / "terrain" / "floor_alt.png")
    write_wall()
    write_water()
    write_bridge()


def write_camp(path: Path, tint: Color, flag: Color) -> None:
    img = Image.new("RGBA", (TILE_SIZE, TILE_SIZE), TRANSPARENT)
    d = ImageDraw.Draw(img)
    rect(d, (11, 37, 53, 47), (55, 41, 24, 255))
    rect(d, (13, 23, 51, 40), OUTLINE)
    poly(d, [(11, 24), (32, 12), (53, 24)], OUTLINE)
    poly(d, [(15, 24), (32, 15), (49, 24)], tint)
    rect(d, (16, 25, 48, 39), (111, 76, 38, 255))
    rect(d, (26, 29, 37, 39), (31, 27, 21, 255))
    rect(d, (18, 29, 24, 34), (222, 196, 111, 255))
    rect(d, (40, 29, 46, 34), (222, 196, 111, 255))
    rect(d, (51, 10, 53, 31), (220, 209, 143, 255))
    poly(d, [(53, 11), (61, 15), (53, 19)], flag)
    rect(d, (20, 18, 44, 20), (177, 126, 54, 255))
    img.save(path)
    print(f"[write] {path.relative_to(ROOT)}")


def write_exit(path: Path) -> None:
    img = Image.new("RGBA", (TILE_SIZE, TILE_SIZE), TRANSPARENT)
    d = ImageDraw.Draw(img)
    rect(d, (8, 20, 56, 44), OUTLINE)
    rect(d, (10, 22, 54, 42), (62, 82, 72, 255))
    rect(d, (12, 24, 52, 26), (166, 212, 172, 255))
    rect(d, (12, 38, 52, 40), (166, 212, 172, 255))
    rect(d, (29, 12, 35, 52), (229, 230, 186, 255))
    rect(d, (18, 29, 46, 35), (229, 230, 186, 255))
    rect(d, (2, 29, 12, 35), (246, 189, 69, 255))
    rect(d, (52, 29, 62, 35), (246, 189, 69, 255))
    img.save(path)
    print(f"[write] {path.relative_to(ROOT)}")


def write_objectives() -> None:
    specs = [
        ("camp_alpha.png", (103, 130, 58, 255), (216, 75, 52, 255)),
        ("camp_bravo.png", (119, 101, 53, 255), (227, 186, 64, 255)),
        ("camp_charlie.png", (89, 119, 112, 255), (86, 176, 224, 255)),
        ("camp_delta.png", (121, 76, 66, 255), (220, 96, 164, 255)),
    ]
    for filename, tint, flag in specs:
        write_camp(ASSET_DIR / "objectives" / filename, tint, flag)
    write_exit(ASSET_DIR / "objectives" / "exit.png")


def main() -> None:
    ensure_dirs()
    write_actor_strips()
    write_terrain()
    write_objectives()
    print("[done] generated jackal runtime assets")


if __name__ == "__main__":
    main()
