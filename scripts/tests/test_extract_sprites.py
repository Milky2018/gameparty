#!/usr/bin/env python3

from __future__ import annotations

import json
import subprocess
import tempfile
import unittest
from pathlib import Path

from PIL import Image


REPO_ROOT = Path(__file__).resolve().parents[2]
SCRIPT = REPO_ROOT / "scripts" / "extract_sprites.py"


def run_cmd(args: list[str], cwd: Path) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["python3", str(SCRIPT), *args],
        cwd=str(cwd),
        capture_output=True,
        text=True,
    )


class ExtractSpritesTests(unittest.TestCase):
    def write_json(self, path: Path, payload: dict) -> None:
        path.write_text(json.dumps(payload, indent=2), encoding="utf-8")

    def test_validate_success(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            src = root / "src.png"
            Image.new("RGBA", (16, 16), (20, 30, 40, 255)).save(src)
            spec = root / "spec.json"
            self.write_json(
                spec,
                {
                    "version": "sprite-extractor-v1",
                    "sources": {"atlas": str(src)},
                    "jobs": [
                        {
                            "source": "atlas",
                            "mode": "rects",
                            "outputs": [{"name": "one", "x": 0, "y": 0, "w": 8, "h": 8}],
                        }
                    ],
                },
            )
            result = run_cmd(["validate", "--spec", str(spec)], cwd=root)
            self.assertEqual(result.returncode, 0, result.stderr + "\n" + result.stdout)
            self.assertIn("[ok] spec valid", result.stdout)

    def test_validate_fails_on_duplicate_output_name(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            src = root / "src.png"
            Image.new("RGBA", (16, 16), (0, 0, 0, 255)).save(src)
            spec = root / "spec.json"
            self.write_json(
                spec,
                {
                    "version": "sprite-extractor-v1",
                    "sources": {"atlas": str(src)},
                    "jobs": [
                        {
                            "source": "atlas",
                            "mode": "rects",
                            "outputs": [
                                {"name": "dup", "x": 0, "y": 0, "w": 8, "h": 8},
                                {"name": "dup", "x": 8, "y": 8, "w": 8, "h": 8},
                            ],
                        }
                    ],
                },
            )
            result = run_cmd(["validate", "--spec", str(spec)], cwd=root)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("duplicate output filename", result.stdout)

    def test_run_grid_and_rect_and_index(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            src = root / "atlas.png"
            img = Image.new("RGBA", (32, 16), (0, 0, 0, 0))
            for y in range(0, 8):
                for x in range(0, 8):
                    img.putpixel((x, y), (255, 0, 0, 255))
            for y in range(0, 8):
                for x in range(8, 16):
                    img.putpixel((x, y), (0, 255, 0, 255))
            for y in range(8, 16):
                for x in range(16, 24):
                    img.putpixel((x, y), (0, 0, 255, 255))
            img.save(src)

            spec = root / "spec.json"
            self.write_json(
                spec,
                {
                    "version": "sprite-extractor-v1",
                    "sources": {"atlas": str(src)},
                    "jobs": [
                        {
                            "source": "atlas",
                            "mode": "grid",
                            "origin_x": 0,
                            "origin_y": 0,
                            "step_x": 8,
                            "step_y": 8,
                            "frame_w": 8,
                            "frame_h": 8,
                            "outputs": [
                                {"name": "grid_red", "col": 0, "row": 0},
                                {"name": "grid_green", "col": 1, "row": 0},
                            ],
                        },
                        {
                            "source": "atlas",
                            "mode": "rects",
                            "outputs": [{"name": "rect_blue", "x": 16, "y": 8, "w": 8, "h": 8}],
                        },
                    ],
                },
            )
            out_dir = root / "out"
            result = run_cmd(["run", "--spec", str(spec), "--out", str(out_dir)], cwd=root)
            self.assertEqual(result.returncode, 0, result.stderr + "\n" + result.stdout)
            self.assertTrue((out_dir / "grid_red.png").exists())
            self.assertTrue((out_dir / "grid_green.png").exists())
            self.assertTrue((out_dir / "rect_blue.png").exists())
            index = json.loads((out_dir / "extract_index.json").read_text(encoding="utf-8"))
            self.assertEqual(index["summary"]["exported"], 3)
            self.assertEqual(len(index["items"]), 3)

    def test_postprocess_remove_bg_trim_pad(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            src = root / "atlas.png"
            img = Image.new("RGBA", (8, 8), (255, 0, 0, 255))
            for y in range(3, 5):
                for x in range(3, 5):
                    img.putpixel((x, y), (0, 255, 0, 255))
            img.save(src)

            spec = root / "spec.json"
            self.write_json(
                spec,
                {
                    "version": "sprite-extractor-v1",
                    "sources": {"atlas": str(src)},
                    "jobs": [
                        {
                            "source": "atlas",
                            "mode": "rects",
                            "postprocess": {
                                "remove_bg": {"rgb": [255, 0, 0], "tolerance": 0},
                                "trim": True,
                                "pad": {"width": 6, "height": 6},
                            },
                            "outputs": [{"name": "processed", "x": 0, "y": 0, "w": 8, "h": 8}],
                        }
                    ],
                },
            )
            out_dir = root / "out"
            result = run_cmd(["run", "--spec", str(spec), "--out", str(out_dir)], cwd=root)
            self.assertEqual(result.returncode, 0, result.stderr + "\n" + result.stdout)
            exported = Image.open(out_dir / "processed.png").convert("RGBA")
            self.assertEqual(exported.size, (6, 6))
            self.assertEqual(exported.getpixel((0, 0))[3], 0)
            center = exported.getpixel((3, 3))
            self.assertEqual(center[0:3], (0, 255, 0))

    def test_dry_run_creates_no_outputs(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            src = root / "atlas.png"
            Image.new("RGBA", (8, 8), (1, 2, 3, 255)).save(src)
            spec = root / "spec.json"
            self.write_json(
                spec,
                {
                    "version": "sprite-extractor-v1",
                    "sources": {"atlas": str(src)},
                    "jobs": [
                        {
                            "source": "atlas",
                            "mode": "rects",
                            "outputs": [{"name": "one", "x": 0, "y": 0, "w": 8, "h": 8}],
                        }
                    ],
                },
            )
            out_dir = root / "out"
            result = run_cmd(
                ["run", "--spec", str(spec), "--out", str(out_dir), "--dry-run"], cwd=root
            )
            self.assertEqual(result.returncode, 0, result.stderr + "\n" + result.stdout)
            self.assertFalse((out_dir / "one.png").exists())
            self.assertFalse((out_dir / "extract_index.json").exists())

    def test_overwrite_behavior(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            src = root / "atlas.png"
            Image.new("RGBA", (8, 8), (1, 2, 3, 255)).save(src)
            spec = root / "spec.json"
            self.write_json(
                spec,
                {
                    "version": "sprite-extractor-v1",
                    "sources": {"atlas": str(src)},
                    "jobs": [
                        {
                            "source": "atlas",
                            "mode": "rects",
                            "outputs": [{"name": "one", "x": 0, "y": 0, "w": 8, "h": 8}],
                        }
                    ],
                },
            )
            out_dir = root / "out"
            first = run_cmd(["run", "--spec", str(spec), "--out", str(out_dir)], cwd=root)
            self.assertEqual(first.returncode, 0, first.stderr + "\n" + first.stdout)
            second = run_cmd(["run", "--spec", str(spec), "--out", str(out_dir)], cwd=root)
            self.assertNotEqual(second.returncode, 0)
            third = run_cmd(
                ["run", "--spec", str(spec), "--out", str(out_dir), "--overwrite"], cwd=root
            )
            self.assertEqual(third.returncode, 0, third.stderr + "\n" + third.stdout)

    def test_no_strict_skips_out_of_bounds_frame(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            src = root / "atlas.png"
            Image.new("RGBA", (8, 8), (255, 255, 255, 255)).save(src)
            spec = root / "spec.json"
            self.write_json(
                spec,
                {
                    "version": "sprite-extractor-v1",
                    "sources": {"atlas": str(src)},
                    "jobs": [
                        {
                            "source": "atlas",
                            "mode": "rects",
                            "outputs": [
                                {"name": "good", "x": 0, "y": 0, "w": 8, "h": 8},
                                {"name": "bad", "x": 6, "y": 6, "w": 8, "h": 8},
                            ],
                        }
                    ],
                },
            )
            out_dir = root / "out"
            result = run_cmd(
                ["run", "--spec", str(spec), "--out", str(out_dir), "--no-strict"], cwd=root
            )
            self.assertEqual(result.returncode, 0, result.stderr + "\n" + result.stdout)
            self.assertTrue((out_dir / "good.png").exists())
            self.assertFalse((out_dir / "bad.png").exists())
            index = json.loads((out_dir / "extract_index.json").read_text(encoding="utf-8"))
            self.assertEqual(index["summary"]["exported"], 1)
            self.assertEqual(index["summary"]["skipped"], 0)


if __name__ == "__main__":
    unittest.main()
