# cloud-workstation

Headless Docker image for Gaussian Splatting training on NVIDIA GPUs in RunPod, primarily RTX 4090.

This repository is no longer targeting a remote desktop workstation. The active goal is a reproducible CUDA/PyTorch training image with persistent datasets, outputs, logs, and checkpoints.

## Priorities

1. Stable Gaussian Splatting training
2. Correct CUDA/GPU usage
3. Clear logs
4. Persistent datasets and outputs
5. Zero graphical desktop environment

## Current Phase

The active branch is:

```text
headless-gsplat-v0.1-dev
```

Phase 4 installs the minimal pinned `gsplat` baseline and validates import/CUDA compatibility. RunPod GPU validation has passed on an NVIDIA GeForce RTX 4090. It does not implement training, install Nerfstudio, install COLMAP, add a viewer, or add benchmark dependencies.

The image starts with a minimal RunPod keepalive command so non-interactive pods remain running for SSH and manual validation.

Phase 5A adopts the official `nerfstudio-project/gsplat` `examples/simple_trainer.py` as the first training backend baseline. It remains headless and uses `--disable_viewer`.

## Base Image

The current headless development image derives from the validated RunPod PyTorch CUDA image:

```text
runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04@sha256:61a4aafb0094cd773f11eefa378929d5a687bd775febeb78eac62fc824141fb5
```

Do not use `latest`.

## Persistent Workspace Layout

The container prepares:

```text
/workspace/datasets
/workspace/scenes
/workspace/outputs
/workspace/logs
/workspace/checkpoints
```

Important data must live in mounted volumes or persistent RunPod storage. Do not rely on ephemeral container paths for datasets, outputs, logs, or checkpoints.

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

COLMAP is optional for the first image.

It should be added only if it does not introduce heavy desktop dependencies or build complexity. If it complicates the image, move it to a later phase and document the decision.

## GPU Validation

After starting the container on a GPU RunPod instance, run:

```bash
validate-gpu.sh
```

This validates `nvidia-smi`, PyTorch import, CUDA availability, GPU name, and a simple CUDA operation.

It also validates that `gsplat` imports successfully and reports the installed package version.

Latest RunPod validation result:

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
- real `gsplat` training reached 30,000 iterations
- checkpoints/tensors were generated successfully

The missing `.ply` in the 30,000-step run was an export invocation issue, not a training failure.

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

## Training Workflow

The initial training wrapper expects a COLMAP-prepared dataset. COLMAP is not installed in this image yet.

Prepare the scene skeleton:

```bash
prepare-dataset.sh <scene-name>
```

Validate paths without starting training:

```bash
train-scene.sh --check <scene-name>
```

Launch the official `gsplat` simple trainer in headless mode:

```bash
MAX_STEPS=100 train-scene.sh <scene-name>
```

Logs and outputs are written under:

```text
/workspace/logs/<scene>/train.log
/workspace/logs/<scene>/run.env
/workspace/logs/<scene>/run.summary
/workspace/outputs/<scene>
/workspace/checkpoints/<scene>
```

This phase does not promise final quality. It only establishes the first official training backend path.

Phase 5A local smoke validation passed for image build, trainer help, absence of viewer dependencies, and `train-scene.sh --check`. A real COLMAP-prepared training run on RunPod remains pending.

## PLY Export

Generate PLY files from existing checkpoints with:

```bash
Generar
```

If more than one scene exists, pass the scene explicitly:

```bash
Generar --scene truck
```

Advanced explicit checkpoint:

```bash
Generar --checkpoint /workspace/outputs/truck/ckpts/ckpt_30000.pt
```

Exports are written under:

```text
/workspace/outputs/<scene>/exports
```

`Generar` uses the native `gsplat.export_splats` exporter and writes both standard PLY and compressed PLY when supported. It does not upload files or run a complete pipeline.

Prepare generated PLY files for manual download:

```bash
PrepararDescarga truck
```

See `docs/ply-export.md`.

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

Current empty folders remain as placeholders until the headless training scripts are introduced in later phases.
