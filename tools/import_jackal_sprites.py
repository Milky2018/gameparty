#!/usr/bin/env python3
from __future__ import annotations

from collections import Counter, deque
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, Iterable, List, Sequence, Tuple

from PIL import Image

Color = Tuple[int, int, int]


ROOT = Path(__file__).resolve().parents[1]
ASSET_DIR = ROOT / "assets" / "jackal"
CELL_SIZE = 32
CELL_STRIDE = 33
FRAMES = 4


@dataclass(frozen=True)
class SheetSpec:
    filename: str
    bg_top_n: int
    start_x: int
    start_y: int
    direction_rows: Dict[str, int]
    col_start: int = 0


SPECS: Dict[str, SheetSpec] = {
    "jeep": SheetSpec(
        filename="NES - Jackal - Enemies - Grenadier Jeep.png",
        bg_top_n=8,
        start_x=10,
        start_y=1,
        direction_rows={"up": 2, "down": 3, "left": 2, "right": 3},
    ),
    "soldier": SheetSpec(
        filename="NES - Jackal - Miscellaneous - POWs.png",
        bg_top_n=6,
        start_x=10,
        start_y=1,
        direction_rows={"up": 1, "down": 2, "left": 3, "right": 4},
    ),
    "turret": SheetSpec(
        filename="NES - Jackal - Enemies - BM-13 Katyusha.png",
        bg_top_n=6,
        start_x=10,
        start_y=1,
        direction_rows={"up": 0, "down": 1, "left": 2, "right": 3},
    ),
    "vehicle": SheetSpec(
        filename="NES - Jackal - Enemies - Light Tank.png",
        bg_top_n=10,
        start_x=10,
        start_y=1,
        direction_rows={"up": 0, "down": 1, "left": 4, "right": 5},
    ),
    "fort": SheetSpec(
        filename="NES - Jackal - Enemies - Heavy Tank.png",
        bg_top_n=6,
        start_x=10,
        start_y=25,
        direction_rows={"up": 0, "down": 1, "left": 4, "right": 5},
    ),
}


DIRECTION_TO_FILENAME = {
    "up": "Back - Running.png",
    "down": "Front - Running.png",
    "left": "Left - Running.png",
    "right": "Right - Running.png",
}


def _border_pixels(img: Image.Image) -> Iterable[Color]:
    px = img.load()
    w, h = img.size
    for x in range(w):
        yield px[x, 0]
        yield px[x, h - 1]
    for y in range(h):
        yield px[0, y]
        yield px[w - 1, y]


def keyed_alpha(img: Image.Image, bg_top_n: int) -> Image.Image:
    rgb = img.convert("RGB")
    w, h = rgb.size
    px = rgb.load()

    palette = Counter(rgb.getdata())
    bg_colors = {color for color, _ in palette.most_common(bg_top_n)}

    transparent = [[False] * w for _ in range(h)]
    q: deque[Tuple[int, int]] = deque()

    for x in range(w):
        if px[x, 0] in bg_colors:
            q.append((x, 0))
        if px[x, h - 1] in bg_colors:
            q.append((x, h - 1))
    for y in range(h):
        if px[0, y] in bg_colors:
            q.append((0, y))
        if px[w - 1, y] in bg_colors:
            q.append((w - 1, y))

    while q:
        x, y = q.popleft()
        if transparent[y][x] or px[x, y] not in bg_colors:
            continue
        transparent[y][x] = True
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if (
                0 <= nx < w
                and 0 <= ny < h
                and not transparent[ny][nx]
                and px[nx, ny] in bg_colors
            ):
                q.append((nx, ny))

    rgba = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    out = rgba.load()
    for y in range(h):
        for x in range(w):
            r, g, b = px[x, y]
            if transparent[y][x]:
                out[x, y] = (r, g, b, 0)
            else:
                out[x, y] = (r, g, b, 255)
    return rgba


def extract_strip(
    sheet_rgba: Image.Image,
    start_x: int,
    start_y: int,
    row: int,
    col_start: int,
) -> Image.Image:
    strip = Image.new("RGBA", (CELL_SIZE * FRAMES, CELL_SIZE), (0, 0, 0, 0))
    y0 = start_y + row * CELL_STRIDE
    for i in range(FRAMES):
        x0 = start_x + (col_start + i) * CELL_STRIDE
        tile = sheet_rgba.crop((x0, y0, x0 + CELL_SIZE, y0 + CELL_SIZE))
        strip.paste(tile, (i * CELL_SIZE, 0))
    return strip


def write_actor(actor: str, spec: SheetSpec) -> None:
    src = ASSET_DIR / spec.filename
    if not src.exists():
        raise FileNotFoundError(f"missing source sheet: {src}")

    sheet = Image.open(src).convert("RGB")
    sheet_rgba = keyed_alpha(sheet, spec.bg_top_n)

    target_dir = ASSET_DIR / actor
    target_dir.mkdir(parents=True, exist_ok=True)

    for direction, row in spec.direction_rows.items():
        filename = DIRECTION_TO_FILENAME[direction]
        out_path = target_dir / filename
        strip = extract_strip(
            sheet_rgba,
            spec.start_x,
            spec.start_y,
            row,
            spec.col_start,
        )
        strip.save(out_path)
        print(f"[write] {out_path.relative_to(ROOT)}")


def main() -> None:
    for actor, spec in SPECS.items():
        write_actor(actor, spec)
    print("[done] jackal sprite strips regenerated")


if __name__ == "__main__":
    main()

