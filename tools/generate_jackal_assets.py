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


def write_strip(
    actor: str,
    direction: str,
    frames: List[Image.Image],
) -> None:
    names = {
        "up": "Back - Running.png",
        "down": "Front - Running.png",
        "left": "Left - Running.png",
        "right": "Right - Running.png",
    }
    strip = Image.new("RGBA", (FRAME_SIZE * STRIP_FRAMES, FRAME_SIZE), TRANSPARENT)
    for index, frame in enumerate(frames):
        strip.paste(frame, (index * FRAME_SIZE, 0), frame)
    out_path = ASSET_DIR / actor / names[direction]
    strip.save(out_path)
    print(f"[write] {out_path.relative_to(ROOT)}")


def write_role_sheet(actor: str, frames_by_direction: Dict[str, List[Image.Image]]) -> None:
    row_order = ("up", "right", "down", "left")
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
    body = (87, 109, 38, 255)
    body_hi = (142, 160, 57, 255)
    body_shadow = (42, 51, 25, 255)
    wheel_tick = step % 2

    rect(d, (8, 8, 23, 26), OUTLINE)
    rect(d, (10, 6, 21, 27), body)
    rect(d, (11, 7, 20, 11), body_hi)
    rect(d, (11, 20, 20, 25), body_shadow)
    rect(d, (9, 12, 22, 18), INK)
    rect(d, (10, 13, 15, 16), GLASS)
    rect(d, (17, 13, 21, 16), GLASS)
    rect(d, (10, 17, 21, 19), (31, 33, 26, 255))
    rect(d, (13, 8, 18, 9), (214, 212, 137, 255))
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
    body = (88, 111, 55, 255)
    body_hi = (130, 153, 73, 255)
    body_dark = (39, 51, 34, 255)
    tread = step % 2

    rect(d, (7, 5, 24, 27), OUTLINE)
    rect(d, (9, 4, 22, 27), body)
    rect(d, (10, 5, 21, 9), body_hi)
    rect(d, (11, 15, 20, 24), body_dark)
    rect(d, (8, 9, 10, 26), TIRE)
    rect(d, (21, 9, 23, 26), TIRE)
    for y in range(10 + tread, 25, 5):
        rect(d, (8, y, 9, y + 1), TIRE_HI)
        rect(d, (22, y, 23, y + 1), TIRE_HI)
    rect(d, (12, 10, 19, 17), (67, 80, 43, 255))
    rect(d, (14, 2, 17, 12), OUTLINE)
    rect(d, (15, 1, 16, 11), (150, 161, 83, 255))
    rect(d, (13, 12, 18, 15), body_hi)
    return img


def draw_fort_frame(step: int) -> Image.Image:
    img = new_frame()
    d = ImageDraw.Draw(img)
    stone = (102, 108, 93, 255)
    stone_hi = (148, 153, 133, 255)
    stone_dark = (52, 56, 52, 255)
    pulse = step % 2

    rect(d, (5, 10, 26, 28), OUTLINE)
    rect(d, (7, 12, 24, 27), stone)
    rect(d, (8, 13, 23, 15), stone_hi)
    rect(d, (8, 21, 23, 26), stone_dark)
    rect(d, (10, 8, 21, 13), OUTLINE)
    rect(d, (11, 9, 20, 13), stone_hi)
    rect(d, (14, 2, 17, 13), OUTLINE)
    rect(d, (15, 1, 16, 12), (170, 171, 146, 255))
    rect(d, (9, 16, 12, 19), stone_dark)
    rect(d, (19, 16, 22, 19), stone_dark)
    rect(d, (13, 17, 18, 22), (32, 34, 34, 255))
    if pulse == 1:
        rect(d, (14, 1, 17, 2), (248, 188, 70, 255))
    return img


def draw_turret_frame(step: int) -> Image.Image:
    img = new_frame()
    d = ImageDraw.Draw(img)
    metal = (89, 99, 91, 255)
    metal_hi = (148, 154, 137, 255)
    recoil = 1 if step == 1 else 0

    rect(d, (10, 11, 21, 23), OUTLINE)
    rect(d, (11, 12, 20, 22), metal)
    rect(d, (13, 14, 18, 19), (45, 50, 48, 255))
    rect(d, (14, 4 + recoil, 17, 14 + recoil), OUTLINE)
    rect(d, (15, 2 + recoil, 16, 14 + recoil), metal_hi)
    rect(d, (8, 22, 23, 25), OUTLINE)
    rect(d, (9, 23, 22, 24), (62, 67, 61, 255))
    return img


def draw_soldier_frame(direction: str, step: int) -> Image.Image:
    img = new_frame()
    d = ImageDraw.Draw(img)
    uniform = (88, 108, 62, 255)
    uniform_hi = (134, 151, 82, 255)
    skin = (190, 131, 82, 255)
    leg_phase = step % 2
    side = 1 if direction == "right" else -1 if direction == "left" else 0

    head_x = 13 + side
    rect(d, (head_x, 5, head_x + 5, 10), OUTLINE)
    rect(d, (head_x + 1, 6, head_x + 4, 9), skin)
    rect(d, (head_x - 1, 4, head_x + 6, 6), OUTLINE)
    rect(d, (head_x, 3, head_x + 5, 5), uniform_hi)
    rect(d, (11, 10, 20, 20), OUTLINE)
    rect(d, (12, 11, 19, 19), uniform)
    rect(d, (13, 12, 18, 14), uniform_hi)
    if direction == "left":
        rect(d, (8, 12, 12, 17), uniform)
        rect(d, (4, 13, 10, 14), (48, 51, 43, 255))
        rect(d, (20, 12, 22, 17), uniform)
    elif direction == "right":
        rect(d, (19, 12, 23, 17), uniform)
        rect(d, (21, 13, 27, 14), (48, 51, 43, 255))
        rect(d, (9, 12, 11, 17), uniform)
    elif direction == "up":
        rect(d, (9, 12, 12, 17), uniform)
        rect(d, (19, 12, 22, 17), uniform)
        rect(d, (15, 0, 16, 5), (48, 51, 43, 255))
    else:
        rect(d, (9, 12, 12, 17), uniform)
        rect(d, (19, 12, 22, 17), uniform)
        rect(d, (15, 17, 16, 24), (48, 51, 43, 255))
    if leg_phase == 0:
        rect(d, (12, 20, 14, 26), uniform)
        rect(d, (17, 20, 19, 25), uniform)
        rect(d, (11, 26, 14, 27), OUTLINE)
        rect(d, (17, 25, 20, 26), OUTLINE)
    else:
        rect(d, (11, 20, 13, 25), uniform)
        rect(d, (18, 20, 20, 26), uniform)
        rect(d, (10, 25, 13, 26), OUTLINE)
        rect(d, (18, 26, 21, 27), OUTLINE)
    return img


def rotated_actor_frames(
    draw_up: Callable[[int], Image.Image],
    direction: str,
) -> List[Image.Image]:
    return [rotate(draw_up(step), direction) for step in range(STRIP_FRAMES)]


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
        for direction in ("up", "right", "down", "left"):
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


def write_wall() -> None:
    img = Image.new("RGBA", (TILE_SIZE, TILE_SIZE), TRANSPARENT)
    d = ImageDraw.Draw(img)
    rect(d, (5, 18, 58, 45), OUTLINE)
    colors = [
        (83, 82, 70, 255),
        (106, 104, 87, 255),
        (70, 72, 64, 255),
    ]
    for row, y in enumerate(range(20, 44, 8)):
        offset = 0 if row % 2 == 0 else 7
        for x in range(7 - offset, 57, 14):
            fill = colors[(row + x // 14) % len(colors)]
            rect(d, (x, y, min(57, x + 13), y + 7), fill)
            rect(d, (x, y, min(57, x + 13), y + 1), (136, 133, 108, 255))
    img.save(ASSET_DIR / "terrain" / "wall.png")
    print(f"[write] {(ASSET_DIR / 'terrain' / 'wall.png').relative_to(ROOT)}")


def write_terrain() -> None:
    make_floor(
        ASSET_DIR / "terrain" / "floor.png",
        17,
        (26, 39, 33, 255),
        (39, 58, 45, 255),
    )
    make_floor(
        ASSET_DIR / "terrain" / "floor_alt.png",
        23,
        (31, 43, 38, 255),
        (50, 66, 53, 255),
    )
    write_wall()


def write_camp(path: Path, tint: Color, flag: Color) -> None:
    img = Image.new("RGBA", (TILE_SIZE, TILE_SIZE), TRANSPARENT)
    d = ImageDraw.Draw(img)
    rect(d, (9, 38, 55, 48), (58, 42, 27, 255))
    rect(d, (12, 24, 52, 41), OUTLINE)
    poly(d, [(10, 25), (32, 10), (54, 25)], OUTLINE)
    poly(d, [(14, 25), (32, 13), (50, 25)], tint)
    rect(d, (15, 26, 49, 40), (79, 58, 36, 255))
    rect(d, (27, 29, 37, 40), (27, 24, 20, 255))
    rect(d, (18, 29, 24, 35), (214, 193, 117, 255))
    rect(d, (41, 29, 47, 35), (214, 193, 117, 255))
    rect(d, (50, 11, 52, 31), (214, 204, 154, 255))
    poly(d, [(52, 12), (61, 16), (52, 20)], flag)
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
