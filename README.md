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

Phase 4 installs the minimal pinned `gsplat` baseline and validates import/CUDA compatibility. It does not implement training, install Nerfstudio, install COLMAP, add a viewer, or add benchmark dependencies.

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
```

The pinned install set is recorded in:

```text
requirements-gsplat.txt
```

Future scripts should keep scene path, output path, log path, checkpoint path, and backend entrypoint explicit. The design should not be hardcoded to a single repo or command.

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

## Training Diagnostics

To collect environment, GPU, PyTorch/CUDA, workspace, logs, outputs, and checkpoint diagnostics:

```bash
collect-training-diagnostics.sh
```

The script writes a compressed archive under:

```text
/workspace/logs/diagnostics
```

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
