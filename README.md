# cloud-workstation

Headless Docker images for a Gaussian Splatting pipeline on NVIDIA GPUs in RunPod, primarily RTX 4090.

This repository is no longer targeting a remote desktop workstation. The active goal is a reproducible headless pipeline with persistent inputs, outputs, logs, checkpoints, PLY exports, and transfer records.

## Priorities

1. Stable Gaussian Splatting training
2. Correct CUDA/GPU usage
3. Clear logs and evidence
4. Persistent datasets, outputs, and transfer packages
5. Zero graphical desktop environment

## Current Phase

The active branch is:

```text
headless-gsplat-v0.1-dev
```

The current implemented work is the headless `gsplat` Trainer image line. Earlier RunPod GPU checks and a 30,000-iteration training run were reported by the operator, but their original logs and artifacts were not preserved. They are historical observations, not evidence-backed validation of the current image.

The image starts with a minimal RunPod keepalive command so non-interactive pods remain running for SSH and manual validation.

Phase 5A adopts the official `nerfstudio-project/gsplat` `examples/simple_trainer.py` as the first training backend baseline. It remains headless and uses `--disable_viewer`.

The broader target is three headless image roles:

- `COLMAP`: prepare image datasets and generate reconstruction data.
- `Trainer`: train Gaussian Splatting with `gsplat`, then export and package PLY files.
- `Full`: combine COLMAP and Trainer in one heavier image for a complete single-image pipeline.

Trainer owns the `gsplat` workflow described below. COLMAP processing now belongs to the separate `headless-surveyor-v0.1-dev` image. Full remains a future combined-image target.

## Base Image

The current headless development image derives from the validated RunPod PyTorch CUDA image:

```text
runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04@sha256:61a4aafb0094cd773f11eefa378929d5a687bd775febeb78eac62fc824141fb5
```

Do not use `latest`.

## Persistent Workspace Layout

The current Trainer image prepares:

```text
/workspace/datasets
/workspace/scenes
/workspace/outputs
/workspace/logs
/workspace/checkpoints
```

Important data must live in mounted volumes or persistent RunPod storage. Do not rely on ephemeral container paths for datasets, outputs, logs, or checkpoints.

`/workspace/checkpoints` remains a current Trainer path because `train-scene.sh` exposes checkpoints there.

## Explicit Non-Goals

Do not add or repair:

- remote desktop
- GDM/GDM3
- XFCE
- Xorg/X11
- VNC
- NoMachine
- interactive streaming
- Blender GUI
- desktop GLX probes
- virtual monitor/viewer workflows

The previous desktop integration branch remains legacy only.

## Gaussian Splatting Backend

`gsplat` is the initial technical baseline, but the training workflow must remain backend-configurable.

Current pinned baseline:

```text
gsplat==1.5.3 from PyPI
official examples tag v1.5.3
```

The pinned install set is recorded in:

```text
requirements-gsplat.txt
requirements-gsplat-trainer.txt
```

Future scripts should keep scene path, output path, log path, checkpoint path, and backend entrypoint explicit. The design should not be hardcoded to a single repo or command.

Official trainer source:

```text
https://github.com/nerfstudio-project/gsplat
tag v1.5.3
commit 937e29912570c372bed6747a5c9bf85fed877bae
/opt/gsplat/examples/simple_trainer.py
```

The official examples are pinned to the same release line as the validated `gsplat==1.5.3` wheel to avoid API drift between the trainer and installed runtime.

Because this image is strictly headless, a small build-time patch removes the official example's top-level viewer imports. No `nerfview`, `viser`, `splines`, desktop, or virtual monitor dependency is installed.

Nerfstudio/Splatfacto is a future benchmark placeholder only. It is not installed in this phase.

## COLMAP Policy

COLMAP is not installed in the current Trainer image.

The current direction is to create a separate COLMAP image/branch first, then a Full image that combines COLMAP and Trainer. Do not add COLMAP to the Trainer image in this documentation-only update.

## GPU Validation

After starting the container on a GPU RunPod instance, run:

```bash
validate-gpu.sh
```

This validates `nvidia-smi`, PyTorch import, CUDA availability, GPU name, and a simple CUDA operation.

It also validates that `gsplat` imports successfully and reports the installed package version.

Historical operator report from an earlier RunPod execution:

- GPU: `NVIDIA GeForce RTX 4090`
- NVIDIA-SMI: `550.127.05`
- CUDA visible through `nvidia-smi`: `12.4`
- Python: `3.11.10`
- `torch`: `2.4.1+cu124`
- `torch.version.cuda`: `12.4`
- `gsplat`: `1.5.3`
- `gsplat_import=success`
- `cuda_available=True`
- `cuda_operation=success`
- diagnostics archive generated under `/workspace/logs/diagnostics`
- a `gsplat` training run reportedly reached 30,000 iterations
- checkpoints/tensors were reportedly generated

The original logs, run metadata, checkpoints, and diagnostics archive were not preserved. These observations must not be used to validate the current image. The operator reported that the missing `.ply` resulted from the export not being invoked.

## RunPod Startup

The default command is:

```text
runpod-keepalive.sh
```

This keeps a foreground process alive in non-interactive RunPod pods. It creates `/workspace/logs`, prints the main validation commands, and then sleeps indefinitely.

This replaces `CMD ["/bin/bash"]`, which can exit immediately when RunPod starts the container without an interactive shell.

## Training Diagnostics

To collect environment, GPU, PyTorch/CUDA, workspace, logs, outputs, and checkpoint diagnostics:

```bash
collect-training-diagnostics.sh
```

The script writes a compressed archive under:

```text
/workspace/logs/diagnostics
```

Package scene-scoped training and export logs for review with:

```bash
empaquetar-logs <scene>
```

This command packages existing evidence; it does not generate GPU telemetry. Optional telemetry must already exist under `/workspace/logs/<scene>`.

## Training Workflow

The initial training wrapper expects a COLMAP-prepared dataset. COLMAP is not installed in this image yet.

Use [docs/command-reference.md](docs/command-reference.md) for exact commands to prepare datasets, validate scenes, run smoke training, pass trainer arguments, export PLY, package results, verify checksums, and transfer packages.

Logs and outputs are written under:

```text
/workspace/logs/<scene>/train.log
/workspace/logs/<scene>/run.env
/workspace/logs/<scene>/run.summary
/workspace/outputs/<scene>
/workspace/checkpoints/<scene>
```

This phase does not promise final quality. It only establishes the first official training backend path.

Phase 5A local checks for image build, trainer help, absence of viewer dependencies, and `train-scene.sh --check` were reported as successful, but their original logs were not preserved. A current evidence-backed COLMAP training run on RunPod remains pending.

## PLY Export

PLY exports are generated from existing checkpoints with `generar`. Exports are written under:

```text
/workspace/outputs/<scene>/exports
```

`generar` uses the native `gsplat.export_splats` exporter and writes both standard PLY and compressed PLY when supported. It does not upload files or run a complete pipeline. The default export device is CPU.

See [docs/ply-export.md](docs/ply-export.md) for export behavior and [docs/command-reference.md](docs/command-reference.md) for exact command syntax.

## Transfer

`runpodctl v2.5.0` is installed in the image from the official GitHub release with checksum verification during build.

Selected flow:

```text
Mac -> runpodctl -> pod
pod -> runpodctl -> Mac
```

The previous SCP path through `ssh.runpod.io` is discarded for this workflow.

Installation is implemented; successful end-to-end transfer is not yet evidence-backed. Use [docs/command-reference.md](docs/command-reference.md) for the intended `runpodctl send` / `runpodctl receive` command shape. Mac-to-pod syntax and large-file behavior still need smoke testing and exact command capture.

## Current Command Reference

See the full operator guide:

[docs/command-reference.md](docs/command-reference.md)

```bash
validate-gpu.sh
train-scene.sh --check room
MAX_STEPS=100 train-scene.sh room
generar --scene room
empaquetar room
empaquetar-logs room
runpodctl send /workspace/outputs/room/exports/room-ply-exports.tar.gz
```

## Known Errors

- Multiple scenes contain checkpoints: pass `generar --scene <scene>` or `generar --checkpoint <path>`.
- Scene does not exist: check `ls -lah /workspace/scenes`.
- COLMAP layout is incomplete: run `train-scene.sh --check <scene>`.
- Checkpoint is missing: run `find /workspace/outputs -type f -name 'ckpt*.pt'`.
- Exports are missing: run `generar --scene <scene>` before `empaquetar <scene>`.
- File is on external Mac storage: move it to local storage such as `~/Downloads/` before using `runpodctl`.

## Pending Smoke Tests

- Run new GPU smoke test when GPU is available.
- Confirm `MAX_STEPS=100 train-scene.sh room`.
- Confirm `generar --scene room`.
- Confirm `empaquetar room`.
- Transfer package with `runpodctl`.
- Verify checksum on the Mac.
- Test a file larger than 1 GB.
- Measure transfer speed.
- Test interruption and whether resume is supported.
- Record exact working `runpodctl` syntax.

## Repository Structure

```text
cloud-workstation/
├── Dockerfile
├── README.md
├── CHANGELOG.md
├── docs/
├── scripts/
├── startup/
├── healthchecks/
├── logs/
└── .gitignore
```

Legacy placeholder folders remain only for repository continuity. Active headless operation is documented above.
