#!/usr/bin/env python3
"""CPU-first conversion runner for The Converter v0.2."""

from __future__ import annotations

import argparse
import csv
import gzip
import hashlib
import html
import json
import re
import shutil
import subprocess
import sys
import tarfile
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
CONVERTER = ROOT / "converter"
CONFIG = CONVERTER / "config"
OUTPUT = CONVERTER / "output"
REPORTS = CONVERTER / "reports"
PACKAGES = CONVERTER / "packages"


def rel(path: Path) -> str:
    try:
        return str(path.resolve().relative_to(ROOT))
    except ValueError:
        return str(path)


def load_json(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def file_size(path: Path) -> int:
    return path.stat().st_size


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def format_bytes(size: int) -> str:
    units = ["B", "KB", "MB", "GB", "TB"]
    value = float(size)
    for unit in units:
        if value < 1024 or unit == units[-1]:
            return f"{value:.2f} {unit}" if unit != "B" else f"{int(value)} B"
        value /= 1024
    return f"{size} B"


def ensure_dirs() -> None:
    for path in (OUTPUT, REPORTS, PACKAGES):
        path.mkdir(parents=True, exist_ok=True)


def command_exists(command: str) -> bool:
    return shutil.which(command) is not None


def render_command(parts: list[str], input_path: Path, output_path: Path, scene_dir: Path) -> list[str]:
    values = {
        "{input}": str(input_path),
        "{output}": str(output_path),
        "{scene_dir}": str(scene_dir),
    }
    return [values.get(part, part) for part in parts]


def run_external_target(
    target_name: str,
    target: dict[str, Any],
    input_path: Path,
    output_path: Path,
    scene_dir: Path,
) -> dict[str, Any]:
    tool = target.get("tool", "unknown")
    if not command_exists(tool):
        return {
            "target": target_name,
            "label": target.get("label", target_name),
            "status": "skipped",
            "tool": tool,
            "reason": f"Required tool '{tool}' is not installed or not on PATH.",
        }

    attempts = []
    for variant in target.get("command_variants", []):
        command = render_command(variant, input_path, output_path, scene_dir)
        started = time.monotonic()
        process = subprocess.run(command, text=True, capture_output=True, check=False)
        elapsed = round(time.monotonic() - started, 3)
        attempts.append(
            {
                "command": command,
                "exit_code": process.returncode,
                "elapsed_seconds": elapsed,
                "stderr_tail": process.stderr[-1200:],
                "stdout_tail": process.stdout[-1200:],
            }
        )
        if process.returncode == 0 and output_path.exists() and output_path.stat().st_size > 0:
            return success_record(target_name, target, output_path, tool, attempts)

    return {
        "target": target_name,
        "label": target.get("label", target_name),
        "status": "failed",
        "tool": tool,
        "reason": "All configured command variants failed or produced no output.",
        "attempts": attempts,
    }


def run_builtin(
    builtin: str,
    target_name: str,
    input_path: Path,
    output_path: Path,
    scene_name: str,
    records: list[dict[str, Any]],
) -> dict[str, Any]:
    if builtin == "gzip_copy":
        return gzip_copy(input_path, output_path)
    if builtin == "html_viewer":
        return html_viewer(scene_name, output_path, records)
    if builtin == "voxel_collision":
        return voxel_collision(input_path, output_path, scene_name)
    return {
        "target": target_name,
        "status": "failed",
        "tool": "converter-builtin",
        "reason": f"Unknown builtin target '{builtin}'.",
    }


def success_record(
    target_name: str,
    target: dict[str, Any],
    output_path: Path,
    tool: str,
    attempts: list[dict[str, Any]] | None = None,
) -> dict[str, Any]:
    record: dict[str, Any] = {
        "target": target_name,
        "label": target.get("label", target_name),
        "status": "success",
        "tool": tool,
        "path": rel(output_path),
        "bytes": file_size(output_path),
        "size": format_bytes(file_size(output_path)),
        "sha256": sha256(output_path),
    }
    if attempts:
        record["attempts"] = attempts
    return record


def gzip_copy(input_path: Path, output_path: Path) -> dict[str, Any]:
    with input_path.open("rb") as src, gzip.open(output_path, "wb", compresslevel=9) as dst:
        shutil.copyfileobj(src, dst, length=1024 * 1024)
    return success_record("compressed-ply", {"label": "Compressed PLY"}, output_path, "python-gzip")


def html_viewer(scene_name: str, output_path: Path, records: list[dict[str, Any]]) -> dict[str, Any]:
    safe_scene_name = html.escape(scene_name)
    candidates = [
        record for record in records
        if record.get("status") == "success" and record.get("target") in {"sog", "streamed-sog", "spz", "splat", "ksplat", "compressed-ply"}
    ]
    rows = "\n".join(
        "<tr><td>{label}</td><td><code>{path}</code></td><td>{size}</td></tr>".format(
            label=html.escape(item["label"]),
            path=html.escape(item["path"]),
            size=html.escape(item["size"]),
        )
        for item in candidates
    )
    html = f"""<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>{safe_scene_name} - Converter Viewer</title>
  <style>
    body {{ font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; margin: 2rem; line-height: 1.5; }}
    table {{ border-collapse: collapse; width: 100%; max-width: 960px; }}
    th, td {{ border: 1px solid #d0d7de; padding: 0.5rem 0.65rem; text-align: left; }}
    th {{ background: #f6f8fa; }}
    code {{ word-break: break-all; }}
  </style>
</head>
<body>
  <h1>{safe_scene_name}</h1>
  <p>This lightweight bundle lists converted Gaussian Splatting artifacts produced by The Converter v0.2.</p>
  <table>
    <thead><tr><th>Format</th><th>Artifact</th><th>Size</th></tr></thead>
    <tbody>{rows or '<tr><td colspan="3">No viewer-compatible artifact was generated.</td></tr>'}</tbody>
  </table>
  <p>Open the generated SOG, SPZ, SPLAT, or KSPLAT artifact in a compatible Gaussian Splatting viewer.</p>
</body>
</html>
"""
    output_path.write_text(html, encoding="utf-8")
    return success_record("html-viewer", {"label": "HTML viewer"}, output_path, "converter-builtin")


def parse_ply_bounds(input_path: Path, sample_limit: int = 2_000_000) -> dict[str, Any]:
    with input_path.open("rb") as handle:
        header_lines: list[str] = []
        while True:
            line = handle.readline()
            if not line:
                raise ValueError("PLY header ended before end_header.")
            decoded = line.decode("utf-8", errors="replace").strip()
            header_lines.append(decoded)
            if decoded == "end_header":
                break

        fmt = next((line for line in header_lines if line.startswith("format ")), "")
        vertex_line = next((line for line in header_lines if line.startswith("element vertex ")), "")
        vertex_count = int(vertex_line.split()[-1]) if vertex_line else 0
        props = [line.split()[-1] for line in header_lines if line.startswith("property ")]
        x_idx = props.index("x") if "x" in props else 0
        y_idx = props.index("y") if "y" in props else 1
        z_idx = props.index("z") if "z" in props else 2

        if "ascii" not in fmt:
            return {
                "vertex_count": vertex_count,
                "bounds_available": False,
                "reason": "Binary PLY bounds are not parsed by the CPU-first builtin voxel helper.",
            }

        mins = [float("inf"), float("inf"), float("inf")]
        maxs = [float("-inf"), float("-inf"), float("-inf")]
        sampled = 0
        for raw in handle:
            if sampled >= min(vertex_count, sample_limit):
                break
            parts = raw.decode("utf-8", errors="ignore").split()
            if len(parts) <= max(x_idx, y_idx, z_idx):
                continue
            xyz = [float(parts[x_idx]), float(parts[y_idx]), float(parts[z_idx])]
            for idx, value in enumerate(xyz):
                mins[idx] = min(mins[idx], value)
                maxs[idx] = max(maxs[idx], value)
            sampled += 1

    return {
        "vertex_count": vertex_count,
        "sampled_vertices": sampled,
        "bounds_available": sampled > 0,
        "bounds": {
            "min": {"x": mins[0], "y": mins[1], "z": mins[2]},
            "max": {"x": maxs[0], "y": maxs[1], "z": maxs[2]},
        } if sampled > 0 else None,
    }


def voxel_collision(input_path: Path, output_path: Path, scene_name: str) -> dict[str, Any]:
    data = {
        "scene_name": scene_name,
        "source": rel(input_path),
        "type": "voxel-collision-placeholder",
        "cpu_first": True,
        "grid": {
            "resolution": [32, 32, 32],
            "note": "Broad-phase collision metadata only; not a visual editing mesh.",
        },
        "ply": parse_ply_bounds(input_path),
    }
    output_path.write_text(json.dumps(data, indent=2), encoding="utf-8")
    return success_record("voxel-collision", {"label": "Voxel collision"}, output_path, "converter-builtin")


def write_size_csv(rows: list[dict[str, Any]], path: Path) -> None:
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=["target", "status", "path", "bytes", "size", "sha256", "tool", "reason"])
        writer.writeheader()
        for row in rows:
            writer.writerow({
                "target": row.get("target", ""),
                "status": row.get("status", ""),
                "path": row.get("path", ""),
                "bytes": row.get("bytes", ""),
                "size": row.get("size", ""),
                "sha256": row.get("sha256", ""),
                "tool": row.get("tool", ""),
                "reason": row.get("reason", ""),
            })


def write_checksums(paths: list[Path], output_path: Path) -> None:
    lines = [f"{sha256(path)}  {rel(path)}" for path in sorted(paths)]
    output_path.write_text("\n".join(lines) + ("\n" if lines else ""), encoding="utf-8")


def write_markdown(report: dict[str, Any], path: Path) -> None:
    rows = []
    for item in report["targets"]:
        rows.append(
            "| {target} | {status} | {tool} | {size} | {path} | {reason} |".format(
                target=item.get("label", item.get("target", "")),
                status=item.get("status", ""),
                tool=item.get("tool", ""),
                size=item.get("size", ""),
                path=item.get("path", ""),
                reason=item.get("reason", ""),
            )
        )
    md = f"""# Conversion Report: {report['scene_name']}

- Preset: `{report['preset']}`
- Input: `{report['input']['path']}`
- Input size: {report['input']['size']}
- CPU-first: yes
- CUDA required: no
- Package: `{report['package']['path']}`

## Targets

| Target | Status | Tool | Size | Path | Reason |
| --- | --- | --- | --- | --- | --- |
{chr(10).join(rows)}

## Notes

{chr(10).join(f"- {note}" for note in report.get("notes", []))}
"""
    path.write_text(md, encoding="utf-8")


def package_results(scene_name: str, paths: list[Path], report_paths: list[Path]) -> dict[str, Any]:
    package_path = PACKAGES / f"{scene_name}-converter-results.tar.gz"
    with tarfile.open(package_path, "w:gz") as archive:
        for path in paths + report_paths:
            if path.exists():
                archive.add(path, arcname=rel(path))
    return {
        "path": rel(package_path),
        "bytes": file_size(package_path),
        "size": format_bytes(file_size(package_path)),
        "sha256": sha256(package_path),
    }


def convert(args: argparse.Namespace) -> int:
    ensure_dirs()
    formats = load_json(CONFIG / "converter-formats.json")
    presets = load_json(CONFIG / "converter-presets.json")["presets"]
    if args.preset not in presets:
        raise SystemExit(f"Unknown preset '{args.preset}'. Available: {', '.join(sorted(presets))}")
    if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._-]{0,127}", args.scene_name):
        raise SystemExit("Scene name must start with a letter or number and contain only letters, numbers, dots, underscores, or hyphens.")

    input_path = Path(args.input).expanduser()
    if not input_path.is_absolute():
        input_path = (ROOT / input_path).resolve()
    if not input_path.exists():
        raise SystemExit(f"Input file does not exist: {input_path}")
    if input_path.suffix.lower() != ".ply":
        raise SystemExit(f"Input must be a .ply file: {input_path}")

    scene_dir = OUTPUT / args.scene_name
    scene_dir.mkdir(parents=True, exist_ok=True)
    records: list[dict[str, Any]] = []
    output_paths: list[Path] = []

    if presets[args.preset].get("include_original"):
        copied = scene_dir / f"{args.scene_name}.master.ply"
        shutil.copy2(input_path, copied)
        records.append(success_record("original-ply", {"label": "Original PLY"}, copied, "converter-builtin"))
        output_paths.append(copied)

    for target_name in presets[args.preset]["targets"]:
        target = formats["targets"][target_name]
        target_dir = scene_dir / target.get("subdir", "")
        target_dir.mkdir(parents=True, exist_ok=True)
        output_path = target_dir / target.get("output_name", f"{args.scene_name}{target['extension']}")
        builtin = target.get("builtin")
        builtin_fallback = target.get("builtin_fallback")
        try:
            if builtin:
                record = run_builtin(builtin, target_name, input_path, output_path, args.scene_name, records)
            else:
                record = run_external_target(target_name, target, input_path, output_path, scene_dir)
                if record.get("status") != "success" and builtin_fallback:
                    fallback_record = run_builtin(builtin_fallback, target_name, input_path, output_path, args.scene_name, records)
                    fallback_record["fallback_for"] = record
                    record = fallback_record
        except Exception as exc:  # noqa: BLE001 - reports must capture failures without hiding other targets.
            record = {
                "target": target_name,
                "label": target.get("label", target_name),
                "status": "failed",
                "tool": target.get("tool", "unknown"),
                "reason": str(exc),
            }
        records.append(record)
        if record.get("status") == "success" and record.get("path"):
            output_paths.append(ROOT / record["path"])

    report_json = REPORTS / "conversion-report.json"
    report_md = REPORTS / "conversion-report.md"
    sizes_csv = REPORTS / "file-sizes.csv"
    checksums_path = REPORTS / "checksums.sha256"
    write_size_csv(records, sizes_csv)
    write_checksums(output_paths, checksums_path)
    report_paths = [report_json, report_md, sizes_csv, checksums_path]

    report = {
        "version": "0.2",
        "created_at": datetime.now(timezone.utc).isoformat(),
        "scene_name": args.scene_name,
        "preset": args.preset,
        "input": {
            "path": rel(input_path),
            "bytes": file_size(input_path),
            "size": format_bytes(file_size(input_path)),
            "sha256": sha256(input_path),
        },
        "targets": records,
        "package": {
            "path": rel(PACKAGES / f"{args.scene_name}-converter-results.tar.gz"),
            "bytes": 0,
            "size": "0 B",
            "sha256": "",
            "status": "pending",
        },
        "runtime": {
            "cpu_first": True,
            "cuda_required": False,
            "splat_transform_available": command_exists("splat-transform"),
        },
        "notes": [
            "External conversions are attempted only when their tools are present.",
            "CUDA is not required by the Converter scripts or Docker image.",
            "Voxel collision output is broad-phase metadata derived from PLY bounds, not a hand-edited mesh.",
        ],
    }
    report_json.write_text(json.dumps(report, indent=2), encoding="utf-8")
    write_markdown(report, report_md)
    package = package_results(args.scene_name, output_paths, report_paths)
    report["package"] = package
    report_json.write_text(json.dumps(report, indent=2), encoding="utf-8")
    write_markdown(report, report_md)

    print(json.dumps({"report": rel(report_json), "package": package}, indent=2))
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="Run CPU-first Gaussian Splatting conversions.")
    parser.add_argument("--input", required=True, help="Path to the Trainer .ply artifact.")
    parser.add_argument("--scene-name", required=True, help="Stable scene name for output filenames.")
    parser.add_argument("--preset", default="benchmark", help="Preset from converter-presets.json.")
    return convert(parser.parse_args())


if __name__ == "__main__":
    sys.exit(main())
