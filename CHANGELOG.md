# Changelog

## Headless Gaussian Splatting Pivot — Phase 4 gsplat Import Baseline

Added the first minimal `gsplat` installation for import and CUDA compatibility validation.

### Added

- Pinned `gsplat==1.5.3` from PyPI.
- Added `requirements-gsplat.txt` for the pinned minimal `gsplat` install set.
- Added GitHub Actions workflow to publish the dev image as `cloud-workstation:headless-gsplat-v0.1-dev`.
- `GSPLAT_VERSION=1.5.3` image environment variable.
- Docker image labels recording the `gsplat` version and source.
- `scripts/validate-gpu.sh` now checks:
  - Python import of `gsplat`
  - installed `gsplat` package version
  - existing PyTorch/CUDA smoke validation

### Source Registration

- Source: PyPI
- Package: `gsplat`
- Version: `1.5.3`
- PyPI wheel SHA256: `515a3773641f5e7f7717acab6276c0b1d6dbcad087b7968ca653337c3189a982`
- Pinned pip install set:
  - `gsplat==1.5.3`
  - `jaxtyping==0.3.11`
  - `markdown-it-py==4.2.0`
  - `mdurl==0.1.2`
  - `ninja==1.13.0`
  - `rich==15.0.0`
  - `wadler-lindig==0.1.7`

### Constraints

- No training pipeline.
- No large training run.
- No Nerfstudio installation.
- No COLMAP installation.
- No viewer.
- No desktop packages.
- No optimization work.

### Pending Validation

- Run a local container import smoke test, if desired.
- Run `validate-gpu.sh` on RunPod with NVIDIA GPU access.
- Confirm `gsplat` import, PyTorch CUDA availability, GPU name, and simple CUDA operation.

### Build Observation

- Local Docker build completed successfully with `requirements-gsplat.txt`.
- Existing Phase 3 system packages still need a later review because Ubuntu dependency resolution pulled multimedia/display-adjacent libraries and reported some system package upgrades despite `--no-upgrade`.

## Headless Gaussian Splatting Pivot — Phase 3.6

Added headless training diagnostics.

### Added

- `scripts/collect-training-diagnostics.sh`
- `/usr/local/bin/collect-training-diagnostics.sh` inside the image

### Diagnostics Coverage

The diagnostics collector captures:

- metadata and workspace paths
- OS/kernel information
- `/workspace` disk usage and tree
- process list and environment
- `nvidia-smi` when available
- GPU memory/utilization query when available
- Python/PyTorch/CUDA versions
- `pip freeze`
- snapshots of datasets, scenes, outputs, logs, and checkpoints
- recent training log tails

### Constraints

- No `gsplat` installation.
- No training implementation.
- No Nerfstudio installation.
- No COLMAP installation.
- No desktop packages.
- `CMD ["/bin/bash"]` retained.

### Local Validation

- `collect-training-diagnostics.sh` passed shell syntax validation.
- It ran successfully against a temporary local workspace.
- It produced a `.tar.gz` diagnostics archive with metadata, Python/PyTorch/CUDA report, workspace snapshots, and recent logs.
- `docker build --check` loaded the Dockerfile and base metadata, but reported the expected local host platform warning: RunPod base is `linux/amd64`, local Mac/OrbStack host is `linux/arm64`.

## Headless Gaussian Splatting Pivot — Phase 3

Added minimal headless base tooling for future GPU training work.

### Added

- Installed base tooling only:
  - `git`
  - `cmake`
  - `ninja-build`
  - `build-essential`
  - `ffmpeg`
  - `wget`
  - `curl`
  - `unzip`
  - `nano`
  - `htop`
  - `tmux`
  - `ca-certificates`
- Added `scripts/validate-gpu.sh`.
- Copied `validate-gpu.sh` into the image as `/usr/local/bin/validate-gpu.sh`.

### Validation Coverage

`validate-gpu.sh` checks:

- `nvidia-smi`
- Python import of `torch`
- `torch.__version__`
- `torch.version.cuda`
- `torch.cuda.is_available()`
- CUDA GPU name
- simple CUDA matrix multiplication

### Constraints

- No desktop packages added.
- No `gsplat` installation.
- No Nerfstudio installation.
- No COLMAP installation.
- No `apt upgrade` or `apt dist-upgrade`.
- `CMD ["/bin/bash"]` retained.

### Local Validation

- Local `linux/amd64` Docker build completed successfully.
- Local non-GPU smoke test confirmed:
  - container starts
  - `WORKDIR` is `/workspace`
  - persistent workspace directories exist
  - PyTorch imports
  - `torch.__version__` is `2.4.1+cu124`
  - `torch.version.cuda` is `12.4`
- `torch.cuda.is_available()` returned `False` locally because the Mac host does not expose an NVIDIA GPU.
- Local `--gpus all` validation could not run because Docker reported no known GPU vendor from CDI.
- Full GPU validation remains pending on RunPod.

## Headless Gaussian Splatting Pivot — Phase 2

Prepared the active branch for a headless training image.

### Changed

- Updated `Dockerfile` identity to `headless-gsplat-v0.1-dev`.
- Corrected active base image references to the platform manifest digest:
  `sha256:61a4aafb0094cd773f11eefa378929d5a687bd775febeb78eac62fc824141fb5`
- Replaced active remote-workstation description with headless Gaussian Splatting training image description.
- Created persistent workspace directories:
  - `/workspace/datasets`
  - `/workspace/scenes`
  - `/workspace/outputs`
  - `/workspace/logs`
  - `/workspace/checkpoints`
- Set `WORKDIR /workspace`.
- Updated active documentation to remove the desktop/workstation objective.

### Confirmed Removed / Not Present

- No `ubuntu-desktop-minimal`
- No GDM/GDM3
- No Xorg/X11
- No `dbus-x11`
- No `mesa-utils` / `glxinfo`
- No supervisor for graphical services
- No VNC, NoMachine, streaming, Blender GUI, Nerfstudio, or `gsplat` installation

### Deferred

- `gsplat` installation and training scripts remain for a later phase.
- COLMAP remains optional and was not added in this phase.
- Nerfstudio remains a future benchmark placeholder only.

## Headless Gaussian Splatting Pivot — Phase 1

Started the pivot from remote interactive workstation to headless Gaussian Splatting training image.

### Added

- Phase 1 audit report: `docs/pivot-headless-gaussian-splatting.md`
- Minimal active-agent state for the headless pivot: `docs/agents/README.md`

### Decisions

- New objective is headless Gaussian Splatting training on NVIDIA GPUs, primarily RTX 4090 on RunPod.
- `gsplat` is the initial technical baseline.
- Training backend design must remain configurable and not hardcoded to one repository or command.
- Nerfstudio/Splatfacto remains a future benchmark placeholder only.
- COLMAP is optional for the first image and should be moved to a later phase if it introduces heavy desktop dependencies or build complexity.
- Desktop Integration / Deky is paused and legacy.

### Not Changed In This Phase

- No aggressive Dockerfile/runtime rewrite.
- No desktop removal yet.
- No Nerfstudio installation.
- No benchmark dependencies.
- No GDM/Xorg/XFCE/VNC/streaming repair.

## Workstation_v0.1 Frozen Baseline

Baseline officially frozen and marked immutable.

### Validated

- Baseline officially frozen
- Base image pinned by SHA256
- Ubuntu 22.04.5 LTS validated
- CUDA toolkit 12.4.131 validated
- CUDA host runtime 13.0 validated
- NVIDIA GeForce RTX 4090 validated
- NVIDIA driver 580.126.20 validated
- SSH validated
- Networking validated
- Runpod compatibility validated

### Freeze Artifacts

- `docs/baseline.md`
- `docs/image-digest.md`
- `docs/gpu-validation.md`
- `docs/nvidia-smi.txt`
- `docs/evidence/nvidia-smi-2026-06-02.png`
- `docs/pip-freeze.txt`
- `docs/dpkg-freeze.txt`
- `docs/freeze-policy.md`

### Pending

- Desktop layer
- X11
- XFCE
- Streaming layer
- Blender
- Audio stack

## v0.1

Baseline inicial congelada para `Workstation_v0.1`.

### Validado

- Imagen base congelada:
  `runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04`
- CUDA validado
- GPU NVIDIA validada
- NVENC validado
- SSH validado
- networking validado
- Runpod compatibility validada

### Pendiente

- OpenGL pendiente
- Desktop layer pendiente
- Streaming layer pendiente
- X11 pendiente
- Desktop session pendiente
- Audio stack pendiente
- Blender pendiente
- Houdini support pendiente
