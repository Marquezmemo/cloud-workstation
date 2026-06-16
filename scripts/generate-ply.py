#!/usr/bin/env python3
"""Generate PLY exports from gsplat checkpoints using gsplat's native exporter."""

from __future__ import annotations

import argparse
import gc
import os
import re
import sys
import traceback
from contextlib import contextmanager
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterable

import torch
from gsplat import export_splats


WORKSPACE = Path("/workspace")
OUTPUTS_ROOT = WORKSPACE / "outputs"
CHECKPOINTS_ROOT = WORKSPACE / "checkpoints"
LOGS_ROOT = WORKSPACE / "logs"

CHECKPOINT_RE = re.compile(r"ckpt_(\d+)")
ALIASES = {
    "means": ("means", "xyz", "means3d"),
    "opacities": ("opacities", "opacity"),
    "scales": ("scales", "scaling"),
    "quats": ("quats", "rotation", "rotations"),
    "sh0": ("sh0", "f_dc"),
    "shN": ("shN", "f_rest"),
}


@dataclass(frozen=True)
class Candidate:
    scene: str
    checkpoint: Path
    step: int | None
    mtime: float


class ExportError(RuntimeError):
    pass


class Logger:
    def __init__(self, path: Path | None):
        self.path = path
        if self.path is not None:
            self.path.parent.mkdir(parents=True, exist_ok=True)

    def write(self, message: str) -> None:
        line = f"{timestamp()} {message}"
        print(line)
        if self.path is not None:
            with self.path.open("a", encoding="utf-8") as handle:
                handle.write(line + "\n")

    def set_path(self, path: Path) -> None:
        if self.path is None:
            self.path = path
            self.path.parent.mkdir(parents=True, exist_ok=True)
            self.write(f"log_file={self.path}")

    def exception(self, exc: BaseException) -> None:
        if self.path is not None:
            with self.path.open("a", encoding="utf-8") as handle:
                handle.write(traceback.format_exc())
                handle.write("\n")
        print(f"{timestamp()} ERROR: {exc}", file=sys.stderr)


def timestamp() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Generate standard and compressed PLY files from gsplat checkpoints."
    )
    parser.add_argument("--scene", help="Scene name under /workspace/outputs/<scene>.")
    parser.add_argument("--checkpoint", help="Explicit checkpoint file to export.")
    parser.add_argument("--ckpt-dir", help="Directory containing ckpt_*.pt files.")
    parser.add_argument("--output-dir", help="Directory where PLY files will be written.")
    parser.add_argument("--log-dir", help="Directory where generate-ply.log will be written.")
    parser.add_argument(
        "--format",
        choices=("both", "ply", "ply_compressed"),
        default="both",
        help="Export format. Default: both.",
    )
    parser.add_argument(
        "--device",
        choices=("cpu", "cuda"),
        default="cpu",
        help="Device used to load checkpoint tensors. Default: cpu.",
    )
    parser.add_argument(
        "--fallback-cpu",
        action="store_true",
        help="If --device cuda fails, retry once on CPU.",
    )
    return parser.parse_args()


def parse_step(path: Path) -> int | None:
    match = CHECKPOINT_RE.search(path.name)
    if not match:
        return None
    return int(match.group(1))


def infer_scene_from_path(path: Path) -> str | None:
    parts = path.resolve().parts
    for index, part in enumerate(parts):
        if part == "outputs" and index + 1 < len(parts):
            return parts[index + 1]
    return None


def candidate_from_path(scene: str, checkpoint: Path) -> Candidate:
    return Candidate(
        scene=scene,
        checkpoint=checkpoint,
        step=parse_step(checkpoint),
        mtime=checkpoint.stat().st_mtime,
    )


def dedupe_paths(paths: Iterable[Path]) -> list[Path]:
    seen: set[str] = set()
    result: list[Path] = []
    for path in paths:
        try:
            key = str(path.resolve())
        except FileNotFoundError:
            continue
        if key in seen:
            continue
        seen.add(key)
        result.append(path)
    return result


def discover_candidates(scene: str | None = None) -> list[Candidate]:
    candidates: list[Candidate] = []
    if scene:
        paths = list((OUTPUTS_ROOT / scene / "ckpts").glob("ckpt_*.pt"))
        paths.extend((CHECKPOINTS_ROOT / scene).glob("ckpt_*.pt"))
        return [candidate_from_path(scene, path) for path in dedupe_paths(paths)]

    paths = list(OUTPUTS_ROOT.glob("*/ckpts/ckpt_*.pt"))
    paths.extend(CHECKPOINTS_ROOT.glob("*/ckpt_*.pt"))
    for path in dedupe_paths(paths):
        inferred_scene = infer_scene_from_path(path)
        if inferred_scene is None and path.parent.parent == CHECKPOINTS_ROOT:
            inferred_scene = path.parent.name
        if inferred_scene is None:
            inferred_scene = "manual"
        candidates.append(candidate_from_path(inferred_scene, path))
    return candidates


def latest_candidate(candidates: list[Candidate]) -> Candidate:
    if not candidates:
        raise ExportError("No checkpoints found.")

    stepped = [candidate for candidate in candidates if candidate.step is not None]
    if stepped:
        max_step = max(candidate.step for candidate in stepped)
        latest = [candidate for candidate in stepped if candidate.step == max_step]
        if len(latest) > 1:
            joined = "\n".join(f"  - {item.checkpoint}" for item in latest)
            raise ExportError(
                "Multiple checkpoint files share the latest step. Multi-rank merge is "
                f"outside this phase; pass --checkpoint explicitly.\n{joined}"
            )
        return latest[0]

    return max(candidates, key=lambda candidate: candidate.mtime)


def resolve_checkpoint(args: argparse.Namespace) -> Candidate:
    if args.checkpoint:
        checkpoint = Path(args.checkpoint)
        if not checkpoint.is_file():
            raise ExportError(f"Checkpoint does not exist: {checkpoint}")
        scene = args.scene or infer_scene_from_path(checkpoint) or checkpoint.stem
        return candidate_from_path(scene, checkpoint)

    if args.ckpt_dir:
        ckpt_dir = Path(args.ckpt_dir)
        if not ckpt_dir.is_dir():
            raise ExportError(f"Checkpoint directory does not exist: {ckpt_dir}")
        scene = args.scene or infer_scene_from_path(ckpt_dir) or ckpt_dir.parent.name
        return latest_candidate(
            [candidate_from_path(scene, path) for path in sorted(ckpt_dir.glob("ckpt_*.pt"))]
        )

    candidates = discover_candidates(args.scene)
    if args.scene:
        return latest_candidate(candidates)

    scenes = sorted({candidate.scene for candidate in candidates})
    if not scenes:
        raise ExportError("No checkpoints found under /workspace/outputs/*/ckpts.")
    if len(scenes) > 1:
        lines = ["Multiple scenes contain checkpoints. Please pass --scene or --checkpoint:"]
        for scene in scenes:
            scene_candidates = [item for item in candidates if item.scene == scene]
            try:
                latest = latest_candidate(scene_candidates)
                lines.append(f"  - {scene}: {latest.checkpoint}")
            except ExportError:
                lines.append(f"  - {scene}: multiple latest checkpoints")
        raise ExportError("\n".join(lines))

    return latest_candidate(candidates)


def log_checkpoint_summary(logger: Logger, checkpoint: dict[str, Any]) -> None:
    logger.write("checkpoint_keys=" + ",".join(sorted(map(str, checkpoint.keys()))))
    splats = select_splats_dict(checkpoint)
    logger.write("splat_keys=" + ",".join(sorted(map(str, splats.keys()))))
    for key in sorted(splats.keys()):
        value = splats[key]
        if isinstance(value, torch.Tensor):
            logger.write(f"tensor {key} shape={tuple(value.shape)} dtype={value.dtype}")
        else:
            logger.write(f"value {key} type={type(value).__name__}")


def select_splats_dict(checkpoint: Any) -> dict[str, Any]:
    if not isinstance(checkpoint, dict):
        raise ExportError(f"Checkpoint root must be a dict, got {type(checkpoint).__name__}")
    splats = checkpoint.get("splats", checkpoint)
    if not isinstance(splats, dict):
        raise ExportError(f"Checkpoint splats must be a dict, got {type(splats).__name__}")
    return splats


def get_tensor(splats: dict[str, Any], canonical: str) -> torch.Tensor:
    for alias in ALIASES[canonical]:
        value = splats.get(alias)
        if isinstance(value, torch.Tensor):
            return value.detach().cpu()
    raise ExportError(
        f"Missing tensor for {canonical}. Tried aliases: {', '.join(ALIASES[canonical])}"
    )


def normalize_sh0(tensor: torch.Tensor) -> torch.Tensor:
    if tensor.ndim == 2 and tensor.shape[1] == 3:
        return tensor.reshape(tensor.shape[0], 1, 3)
    if tensor.ndim == 3 and tensor.shape[1:] == (1, 3):
        return tensor
    if tensor.ndim == 3 and tensor.shape[0] == 1 and tensor.shape[2] == 3:
        return tensor.permute(1, 0, 2)
    raise ExportError(f"sh0/f_dc must normalize to (N, 1, 3), got {tuple(tensor.shape)}")


def normalize_shn(tensor: torch.Tensor, n: int) -> torch.Tensor:
    if tensor.ndim == 3 and tensor.shape[0] == n and tensor.shape[2] == 3:
        return tensor
    if tensor.ndim == 2 and tensor.shape[0] == n and tensor.shape[1] % 3 == 0:
        return tensor.reshape(n, tensor.shape[1] // 3, 3)
    if tensor.numel() == 0:
        return tensor.reshape(n, 0, 3)
    raise ExportError(f"shN/f_rest must normalize to (N, K, 3), got {tuple(tensor.shape)}")


def normalize_splats(splats: dict[str, Any], logger: Logger) -> dict[str, torch.Tensor]:
    means = get_tensor(splats, "means").float()
    opacities = get_tensor(splats, "opacities").float()
    scales = get_tensor(splats, "scales").float()
    quats = get_tensor(splats, "quats").float()
    sh0 = get_tensor(splats, "sh0").float()
    shN = get_tensor(splats, "shN").float()

    if means.ndim != 2 or means.shape[1] != 3:
        raise ExportError(f"means/xyz must have shape (N, 3), got {tuple(means.shape)}")
    n = means.shape[0]

    if opacities.ndim == 2 and opacities.shape[1] == 1:
        opacities = opacities[:, 0]
    elif opacities.ndim != 1:
        raise ExportError(
            f"opacities/opacity must normalize to (N, 1), got {tuple(opacities.shape)}"
        )

    if scales.ndim != 2 or scales.shape[1] != 3:
        raise ExportError(f"scales/scaling must have shape (N, 3), got {tuple(scales.shape)}")
    if quats.ndim != 2 or quats.shape[1] != 4:
        raise ExportError(f"quats/rotation must have shape (N, 4), got {tuple(quats.shape)}")

    sh0 = normalize_sh0(sh0)
    shN = normalize_shn(shN, n)

    tensors = {
        "means": means,
        "opacities": opacities,
        "scales": scales,
        "quats": quats,
        "sh0": sh0,
        "shN": shN,
    }
    for key, value in tensors.items():
        if value.shape[0] != n:
            raise ExportError(f"{key} has N={value.shape[0]}, expected N={n}")
        logger.write(f"normalized {key} shape={tuple(value.shape)} dtype={value.dtype}")
    return tensors


def prepare_cuda(logger: Logger) -> None:
    if not torch.cuda.is_available():
        raise ExportError("--device cuda requested, but torch.cuda.is_available() is false.")
    gc.collect()
    torch.cuda.empty_cache()
    if hasattr(torch.cuda, "ipc_collect"):
        torch.cuda.ipc_collect()
    logger.write(f"cuda_memory_before={torch.cuda.memory_allocated()}")


@contextmanager
def cuda_logging(device: str, logger: Logger):
    try:
        yield
    finally:
        if device == "cuda" and torch.cuda.is_available():
            logger.write(f"cuda_memory_after={torch.cuda.memory_allocated()}")


def load_checkpoint(path: Path, device: str, logger: Logger) -> dict[str, Any]:
    logger.write(f"loading_checkpoint={path}")
    if device == "cuda":
        prepare_cuda(logger)
    checkpoint = torch.load(path, map_location=device, weights_only=True)
    if not isinstance(checkpoint, dict):
        raise ExportError(f"Loaded checkpoint must be a dict, got {type(checkpoint).__name__}")
    return checkpoint


def read_ply_header(path: Path) -> tuple[list[str], int | None]:
    header: list[str] = []
    with path.open("rb") as handle:
        for raw_line in handle:
            line = raw_line.decode("ascii", errors="replace").strip()
            header.append(line)
            if line == "end_header":
                break
    vertex_count = None
    for line in header:
        if line.startswith("element vertex "):
            vertex_count = int(line.split()[-1])
            break
    return header, vertex_count


def validate_ply(path: Path, expected_n: int, export_format: str, logger: Logger) -> None:
    if not path.is_file():
        raise ExportError(f"Output file was not created: {path}")
    if path.stat().st_size <= 0:
        raise ExportError(f"Output file is empty: {path}")
    header, vertex_count = read_ply_header(path)
    if not header or header[0] != "ply":
        raise ExportError(f"Output does not start with PLY header: {path}")
    if "format binary_little_endian 1.0" not in header:
        raise ExportError(f"Output is not binary_little_endian PLY: {path}")
    if vertex_count is None:
        raise ExportError(f"Output PLY has no element vertex declaration: {path}")
    if export_format == "ply" and vertex_count != expected_n:
        raise ExportError(f"PLY vertex count {vertex_count} does not match N={expected_n}")
    if export_format == "ply_compressed" and vertex_count > expected_n:
        raise ExportError(f"Compressed PLY vertex count {vertex_count} exceeds N={expected_n}")
    logger.write(
        f"validated {export_format} path={path} size={path.stat().st_size} "
        f"original_N={expected_n} exported_vertices={vertex_count}"
    )


def atomic_export(
    tensors: dict[str, torch.Tensor],
    output: Path,
    export_format: str,
    logger: Logger,
) -> None:
    output.parent.mkdir(parents=True, exist_ok=True)
    tmp = output.with_name(output.name + ".tmp")
    if tmp.exists():
        tmp.unlink()
    logger.write(f"native_exporter=gsplat.export_splats format={export_format}")
    try:
        export_splats(
            means=tensors["means"],
            scales=tensors["scales"],
            quats=tensors["quats"],
            opacities=tensors["opacities"],
            sh0=tensors["sh0"],
            shN=tensors["shN"],
            format=export_format,
            save_to=str(tmp),
        )
        os.replace(tmp, output)
    except Exception:
        if tmp.exists():
            tmp.unlink()
        raise
    validate_ply(output, tensors["means"].shape[0], export_format, logger)


def default_paths(scene: str, args: argparse.Namespace) -> tuple[Path, Path]:
    output_dir = Path(args.output_dir) if args.output_dir else OUTPUTS_ROOT / scene / "exports"
    log_dir = Path(args.log_dir) if args.log_dir else LOGS_ROOT / scene
    return output_dir, log_dir


def output_path(output_dir: Path, scene: str, export_format: str) -> Path:
    if export_format == "ply":
        return output_dir / f"{scene}.ply"
    return output_dir / f"{scene}.compressed.ply"


def export_once(args: argparse.Namespace, device: str, logger: Logger) -> list[Path]:
    candidate = resolve_checkpoint(args)
    _, log_dir = default_paths(candidate.scene, args)
    logger.set_path(log_dir / "generate-ply.log")
    logger.write(f"scene={candidate.scene}")
    logger.write(f"checkpoint={candidate.checkpoint}")
    logger.write(f"step={candidate.step if candidate.step is not None else 'unknown'}")

    with cuda_logging(device, logger):
        checkpoint = load_checkpoint(candidate.checkpoint, device, logger)
        log_checkpoint_summary(logger, checkpoint)
        tensors = normalize_splats(select_splats_dict(checkpoint), logger)

    output_dir, _ = default_paths(candidate.scene, args)
    formats = ("ply", "ply_compressed") if args.format == "both" else (args.format,)
    outputs: list[Path] = []
    for export_format in formats:
        target = output_path(output_dir, candidate.scene, export_format)
        atomic_export(tensors, target, export_format, logger)
        outputs.append(target)
    return outputs


def initial_log_path(args: argparse.Namespace) -> Path | None:
    if args.log_dir:
        return Path(args.log_dir) / "generate-ply.log"
    if args.scene:
        return LOGS_ROOT / args.scene / "generate-ply.log"
    if args.checkpoint:
        scene = infer_scene_from_path(Path(args.checkpoint)) or Path(args.checkpoint).stem
        return LOGS_ROOT / scene / "generate-ply.log"
    return None


def main() -> int:
    args = parse_args()
    logger = Logger(initial_log_path(args))
    try:
        logger.write("generate-ply start")
        try:
            outputs = export_once(args, args.device, logger)
        except Exception as exc:
            if args.device == "cuda" and args.fallback_cpu:
                logger.write(f"cuda_export_failed_retrying_cpu error={exc}")
                outputs = export_once(args, "cpu", logger)
            else:
                raise
        logger.write("generated_files=" + ",".join(str(path) for path in outputs))
        for path in outputs:
            print(path)
        return 0
    except Exception as exc:
        logger.exception(exc)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
