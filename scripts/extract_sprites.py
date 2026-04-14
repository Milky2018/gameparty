#!/usr/bin/env python3
"""Deterministic sprite extractor.

Extracts sprite subsets from large atlas images according to a single JSON spec.
"""

from __future__ import annotations

import argparse
import json
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

from PIL import Image


SPEC_VERSION = "sprite-extractor-v1"


@dataclass
class RemoveBgConfig:
    rgb: Tuple[int, int, int]
    tolerance: int


@dataclass
class PadConfig:
    width: int
    height: int


@dataclass
class PostProcessConfig:
    remove_bg: Optional[RemoveBgConfig]
    trim: bool
    pad: Optional[PadConfig]


@dataclass
class ExtractTask:
    source_key: str
    source_path: Path
    output_name: str
    rect: Tuple[int, int, int, int]  # x, y, w, h
    postprocess: PostProcessConfig


@dataclass
class CompileResult:
    tasks: List[ExtractTask]
    errors: List[str]
    warnings: List[str]


def _error(errors: List[str], message: str) -> None:
    errors.append(message)


def _warn(warnings: List[str], message: str) -> None:
    warnings.append(message)


def _as_int(value: Any, field: str, errors: List[str]) -> Optional[int]:
    if isinstance(value, bool) or not isinstance(value, int):
        _error(errors, f"{field} must be an integer")
        return None
    return value


def _normalize_output_filename(name: Any, field: str, errors: List[str]) -> Optional[str]:
    if not isinstance(name, str):
        _error(errors, f"{field} must be a string")
        return None
    value = name.strip()
    if value == "":
        _error(errors, f"{field} must not be empty")
        return None
    if "/" in value or "\\" in value:
        _error(errors, f"{field} must not contain path separators")
        return None
    if value.lower().endswith(".png"):
        return value
    return value + ".png"


def _parse_remove_bg(
    value: Any, field: str, errors: List[str]
) -> Optional[RemoveBgConfig]:
    if value is None:
        return None
    if value is False:
        return None
    if not isinstance(value, dict):
        _error(errors, f"{field} must be an object, false, or omitted")
        return None
    rgb = value.get("rgb")
    tolerance = value.get("tolerance", 0)
    if not isinstance(rgb, list) or len(rgb) != 3 or any(not isinstance(v, int) for v in rgb):
        _error(errors, f"{field}.rgb must be [r, g, b] integers")
        return None
    if any(v < 0 or v > 255 for v in rgb):
        _error(errors, f"{field}.rgb values must be in [0,255]")
        return None
    if isinstance(tolerance, bool) or not isinstance(tolerance, int):
        _error(errors, f"{field}.tolerance must be an integer")
        return None
    if tolerance < 0 or tolerance > 255:
        _error(errors, f"{field}.tolerance must be in [0,255]")
        return None
    return RemoveBgConfig(rgb=(rgb[0], rgb[1], rgb[2]), tolerance=tolerance)


def _parse_pad(value: Any, field: str, errors: List[str]) -> Optional[PadConfig]:
    if value is None:
        return None
    if value is False:
        return None
    if not isinstance(value, dict):
        _error(errors, f"{field} must be an object, false, or omitted")
        return None
    width = _as_int(value.get("width"), f"{field}.width", errors)
    height = _as_int(value.get("height"), f"{field}.height", errors)
    if width is None or height is None:
        return None
    if width <= 0 or height <= 0:
        _error(errors, f"{field}.width/height must be > 0")
        return None
    return PadConfig(width=width, height=height)


def _parse_postprocess(
    value: Any, field: str, errors: List[str]
) -> Dict[str, Any]:
    if value is None:
        return {}
    if not isinstance(value, dict):
        _error(errors, f"{field} must be an object when provided")
        return {}

    result: Dict[str, Any] = {}
    if "remove_bg" in value:
        result["remove_bg"] = _parse_remove_bg(
            value.get("remove_bg"), f"{field}.remove_bg", errors
        )
    if "trim" in value:
        trim_value = value.get("trim")
        if not isinstance(trim_value, bool):
            _error(errors, f"{field}.trim must be a boolean")
        else:
            result["trim"] = trim_value
    if "pad" in value:
        result["pad"] = _parse_pad(value.get("pad"), f"{field}.pad", errors)
    return result


def _merge_postprocess(
    base: Dict[str, Any], override: Dict[str, Any]
) -> PostProcessConfig:
    merged: Dict[str, Any] = dict(base)
    merged.update(override)
    return PostProcessConfig(
        remove_bg=merged.get("remove_bg"),
        trim=bool(merged.get("trim", False)),
        pad=merged.get("pad"),
    )


def _resolve_sources(
    spec: Dict[str, Any], spec_path: Path, errors: List[str]
) -> Dict[str, Path]:
    sources = spec.get("sources")
    if not isinstance(sources, dict) or len(sources) == 0:
        _error(errors, "sources must be a non-empty object")
        return {}

    resolved: Dict[str, Path] = {}
    for key, value in sources.items():
        if not isinstance(key, str) or key.strip() == "":
            _error(errors, "sources keys must be non-empty strings")
            continue
        if not isinstance(value, str) or value.strip() == "":
            _error(errors, f"sources.{key} must be a non-empty string path")
            continue
        source_path = Path(value)
        if not source_path.is_absolute():
            source_path = (spec_path.parent / source_path).resolve()
        if not source_path.exists():
            _error(errors, f"sources.{key} path does not exist: {source_path}")
            continue
        if not source_path.is_file():
            _error(errors, f"sources.{key} path is not a file: {source_path}")
            continue
        resolved[key] = source_path
    return resolved


def _build_grid_rect(
    job: Dict[str, Any], frame: Dict[str, Any], errors: List[str], context: str
) -> Optional[Tuple[int, int, int, int]]:
    origin_x = _as_int(job.get("origin_x"), f"{context}.origin_x", errors)
    origin_y = _as_int(job.get("origin_y"), f"{context}.origin_y", errors)
    step_x = _as_int(job.get("step_x"), f"{context}.step_x", errors)
    step_y = _as_int(job.get("step_y"), f"{context}.step_y", errors)
    frame_w = _as_int(job.get("frame_w"), f"{context}.frame_w", errors)
    frame_h = _as_int(job.get("frame_h"), f"{context}.frame_h", errors)
    col = _as_int(frame.get("col"), f"{context}.frames[].col", errors)
    row = _as_int(frame.get("row"), f"{context}.frames[].row", errors)
    if None in (origin_x, origin_y, step_x, step_y, frame_w, frame_h, col, row):
        return None
    if frame_w <= 0 or frame_h <= 0:
        _error(errors, f"{context}.frame_w/frame_h must be > 0")
        return None
    if col < 0 or row < 0:
        _error(errors, f"{context}.frames[].col/row must be >= 0")
        return None
    x = origin_x + col * step_x
    y = origin_y + row * step_y
    return (x, y, frame_w, frame_h)


def _build_rect_rect(
    frame: Dict[str, Any], errors: List[str], context: str
) -> Optional[Tuple[int, int, int, int]]:
    x = _as_int(frame.get("x"), f"{context}.outputs[].x", errors)
    y = _as_int(frame.get("y"), f"{context}.outputs[].y", errors)
    w = _as_int(frame.get("w"), f"{context}.outputs[].w", errors)
    h = _as_int(frame.get("h"), f"{context}.outputs[].h", errors)
    if None in (x, y, w, h):
        return None
    if w <= 0 or h <= 0:
        _error(errors, f"{context}.outputs[].w/h must be > 0")
        return None
    if x < 0 or y < 0:
        _error(errors, f"{context}.outputs[].x/y must be >= 0")
        return None
    return (x, y, w, h)


def _rect_in_bounds(rect: Tuple[int, int, int, int], width: int, height: int) -> bool:
    x, y, w, h = rect
    return x >= 0 and y >= 0 and x + w <= width and y + h <= height


def compile_spec(spec_path: Path, strict: bool) -> CompileResult:
    errors: List[str] = []
    warnings: List[str] = []
    tasks: List[ExtractTask] = []

    try:
        spec = json.loads(spec_path.read_text(encoding="utf-8"))
    except Exception as exc:
        return CompileResult(tasks=[], errors=[f"failed to parse spec: {exc}"], warnings=[])

    if not isinstance(spec, dict):
        return CompileResult(tasks=[], errors=["spec root must be an object"], warnings=[])

    version = spec.get("version")
    if version != SPEC_VERSION:
        _error(errors, f"version must be '{SPEC_VERSION}'")

    source_paths = _resolve_sources(spec, spec_path, errors)

    source_images: Dict[str, Image.Image] = {}
    for key, source_path in source_paths.items():
        try:
            source_images[key] = Image.open(source_path).convert("RGBA")
        except Exception as exc:
            _error(errors, f"failed to open source {key} ({source_path}): {exc}")

    jobs = spec.get("jobs")
    if not isinstance(jobs, list) or len(jobs) == 0:
        _error(errors, "jobs must be a non-empty array")
        return CompileResult(tasks=[], errors=errors, warnings=warnings)

    seen_outputs: Dict[str, str] = {}
    for job_index, job in enumerate(jobs):
        context = f"jobs[{job_index}]"
        if not isinstance(job, dict):
            _error(errors, f"{context} must be an object")
            continue

        source_key = job.get("source")
        if not isinstance(source_key, str) or source_key.strip() == "":
            _error(errors, f"{context}.source must be a non-empty string")
            continue
        source_path = source_paths.get(source_key)
        source_image = source_images.get(source_key)
        if source_path is None or source_image is None:
            _error(errors, f"{context}.source references unknown or invalid source: {source_key}")
            continue

        mode = job.get("mode")
        if mode not in ("grid", "rects"):
            _error(errors, f"{context}.mode must be 'grid' or 'rects'")
            continue

        outputs = job.get("outputs")
        if not isinstance(outputs, list) or len(outputs) == 0:
            _error(errors, f"{context}.outputs must be a non-empty array")
            continue

        job_pp = _parse_postprocess(job.get("postprocess"), f"{context}.postprocess", errors)
        image_w, image_h = source_image.size

        for output_index, frame in enumerate(outputs):
            frame_ctx = f"{context}.outputs[{output_index}]"
            if not isinstance(frame, dict):
                _error(errors, f"{frame_ctx} must be an object")
                continue

            out_name = _normalize_output_filename(
                frame.get("name"), f"{frame_ctx}.name", errors
            )
            if out_name is None:
                continue
            if out_name in seen_outputs:
                _error(
                    errors,
                    f"duplicate output filename '{out_name}' in {frame_ctx} (already used by {seen_outputs[out_name]})",
                )
                continue
            seen_outputs[out_name] = frame_ctx

            if mode == "grid":
                rect = _build_grid_rect(job, frame, errors, context)
            else:
                rect = _build_rect_rect(frame, errors, context)
            if rect is None:
                continue

            if not _rect_in_bounds(rect, image_w, image_h):
                message = (
                    f"{frame_ctx} rect {rect} is out of bounds for source '{source_key}' size {image_w}x{image_h}"
                )
                if strict:
                    _error(errors, message)
                else:
                    _warn(warnings, f"skip: {message}")
                continue

            output_pp = _parse_postprocess(frame.get("postprocess"), f"{frame_ctx}.postprocess", errors)
            tasks.append(
                ExtractTask(
                    source_key=source_key,
                    source_path=source_path,
                    output_name=out_name,
                    rect=rect,
                    postprocess=_merge_postprocess(job_pp, output_pp),
                )
            )

    return CompileResult(tasks=tasks, errors=errors, warnings=warnings)


def apply_remove_bg(image: Image.Image, config: RemoveBgConfig) -> Image.Image:
    rgba = image.convert("RGBA")
    px = rgba.load()
    assert px is not None
    tr, tg, tb = config.rgb
    t = config.tolerance
    for y in range(rgba.height):
        for x in range(rgba.width):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            if abs(r - tr) <= t and abs(g - tg) <= t and abs(b - tb) <= t:
                px[x, y] = (r, g, b, 0)
    return rgba


def apply_trim(image: Image.Image) -> Optional[Image.Image]:
    rgba = image.convert("RGBA")
    alpha = rgba.getchannel("A")
    bbox = alpha.getbbox()
    if bbox is None:
        return None
    return rgba.crop(bbox)


def apply_pad(image: Image.Image, config: PadConfig) -> Optional[Image.Image]:
    if image.width > config.width or image.height > config.height:
        return None
    canvas = Image.new("RGBA", (config.width, config.height), (0, 0, 0, 0))
    offset_x = (config.width - image.width) // 2
    offset_y = (config.height - image.height) // 2
    canvas.paste(image, (offset_x, offset_y))
    return canvas


def process_one(task: ExtractTask, strict: bool) -> Tuple[Optional[Image.Image], Optional[str], Dict[str, Any]]:
    image = Image.open(task.source_path).convert("RGBA")
    x, y, w, h = task.rect
    current = image.crop((x, y, x + w, y + h))

    pp_index: Dict[str, Any] = {
        "remove_bg": None,
        "trim": task.postprocess.trim,
        "pad": None,
    }
    if task.postprocess.remove_bg is not None:
        current = apply_remove_bg(current, task.postprocess.remove_bg)
        pp_index["remove_bg"] = {
            "rgb": list(task.postprocess.remove_bg.rgb),
            "tolerance": task.postprocess.remove_bg.tolerance,
        }
    if task.postprocess.trim:
        trimmed = apply_trim(current)
        if trimmed is None:
            message = f"{task.output_name}: trim produced empty image"
            if strict:
                return None, message, pp_index
            return None, f"skip: {message}", pp_index
        current = trimmed
    if task.postprocess.pad is not None:
        padded = apply_pad(current, task.postprocess.pad)
        if padded is None:
            message = (
                f"{task.output_name}: pad target {task.postprocess.pad.width}x{task.postprocess.pad.height} "
                f"is smaller than current {current.width}x{current.height}"
            )
            if strict:
                return None, message, pp_index
            return None, f"skip: {message}", pp_index
        current = padded
        pp_index["pad"] = {
            "width": task.postprocess.pad.width,
            "height": task.postprocess.pad.height,
        }

    return current, None, pp_index


def cmd_validate(spec_path: Path, strict: bool) -> int:
    result = compile_spec(spec_path, strict=strict)
    for warning in result.warnings:
        print(f"[warn] {warning}")
    if result.errors:
        for error in result.errors:
            print(f"[error] {error}")
        print(f"[fail] {len(result.errors)} error(s), {len(result.warnings)} warning(s)")
        return 1 if strict else 0
    print(f"[ok] spec valid: tasks={len(result.tasks)}")
    return 0


def cmd_run(spec_path: Path, out_dir: Path, strict: bool, dry_run: bool, overwrite: bool) -> int:
    result = compile_spec(spec_path, strict=strict)
    for warning in result.warnings:
        print(f"[warn] {warning}")
    if result.errors:
        for error in result.errors:
            print(f"[error] {error}")
        print(f"[fail] {len(result.errors)} error(s), {len(result.warnings)} warning(s)")
        if strict:
            return 1

    if dry_run:
        print(f"[ok] dry-run: would export {len(result.tasks)} frame(s) to {out_dir}")
        return 0

    out_dir.mkdir(parents=True, exist_ok=True)

    index_items: List[Dict[str, Any]] = []
    exported = 0
    skipped = 0
    failed = 0

    for task in result.tasks:
        output_path = out_dir / task.output_name
        if output_path.exists() and not overwrite:
            message = f"{task.output_name}: output already exists ({output_path})"
            if strict:
                print(f"[error] {message}")
                return 1
            print(f"[warn] skip: {message}")
            skipped += 1
            continue

        processed, process_error, pp_index = process_one(task, strict=strict)
        if process_error is not None:
            if process_error.startswith("skip:"):
                print(f"[warn] {process_error}")
                skipped += 1
            else:
                print(f"[error] {process_error}")
                failed += 1
                if strict:
                    return 1
            continue
        assert processed is not None

        processed.save(output_path)
        exported += 1
        index_items.append(
            {
                "output_path": str(output_path),
                "output_name": task.output_name,
                "source_key": task.source_key,
                "source_path": str(task.source_path),
                "rect": {"x": task.rect[0], "y": task.rect[1], "w": task.rect[2], "h": task.rect[3]},
                "postprocess": pp_index,
                "final_size": {"width": processed.width, "height": processed.height},
            }
        )

    index_payload = {
        "schema": "sprite-extract-index-v1",
        "spec_path": str(spec_path),
        "strict": strict,
        "dry_run": dry_run,
        "overwrite": overwrite,
        "items": index_items,
        "summary": {"exported": exported, "skipped": skipped, "failed": failed},
    }
    index_path = out_dir / "extract_index.json"
    index_path.write_text(json.dumps(index_payload, indent=2), encoding="utf-8")

    print(f"[ok] exported={exported} skipped={skipped} failed={failed}")
    print(f"[ok] index={index_path}")
    return 0 if failed == 0 else 1


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Extract sprite subsets from atlas images.")
    sub = parser.add_subparsers(dest="command", required=True)

    validate = sub.add_parser("validate", help="Validate spec file only.")
    validate.add_argument("--spec", required=True, help="Path to spec.json")
    validate.add_argument("--strict", action=argparse.BooleanOptionalAction, default=True)

    run = sub.add_parser("run", help="Extract sprites based on spec.")
    run.add_argument("--spec", required=True, help="Path to spec.json")
    run.add_argument("--out", required=True, help="Output directory for extracted png files")
    run.add_argument("--strict", action=argparse.BooleanOptionalAction, default=True)
    run.add_argument("--dry-run", action="store_true", help="Validate and print plan without writing files")
    run.add_argument(
        "--overwrite",
        action="store_true",
        help="Allow replacing existing output files (default: fail if exists)",
    )
    return parser


def main(argv: Optional[List[str]] = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)

    spec_path = Path(args.spec).resolve()
    if not spec_path.exists():
        print(f"[error] spec file does not exist: {spec_path}")
        return 1

    if args.command == "validate":
        return cmd_validate(spec_path, strict=args.strict)
    if args.command == "run":
        out_dir = Path(args.out).resolve()
        return cmd_run(
            spec_path=spec_path,
            out_dir=out_dir,
            strict=args.strict,
            dry_run=args.dry_run,
            overwrite=args.overwrite,
        )

    print("[error] unknown command")
    return 1


if __name__ == "__main__":
    sys.exit(main())
