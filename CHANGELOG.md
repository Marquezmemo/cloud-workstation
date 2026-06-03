# Changelog

## Workstation_v0.2-dev

Desktop integration development branch.

### Fixed

- Replaced the mistakenly recorded base image index digest with the correct platform manifest digest:
  `sha256:61a4aafb0094cd773f11eefa378929d5a687bd775febeb78eac62fc824141fb5`

### Added

- Experimental Ubuntu desktop layer with `ubuntu-desktop-minimal`
- `mesa-utils`, `dbus-x11`, `xorg`, and `supervisor`
- Supervisor-based startup without introducing systemd
- Workstation logs under `/var/log/workstation/`
- Startup, GDM, dbus, GPU, Xorg, and desktop probe logging
- Diagnostic collection script
- Desktop healthcheck script
- Error journal for integration attempts
- Docker Hub development workflow for `cloud-workstation:v0.2-dev`

### Constraints

- Derived from frozen `Workstation_v0.1` digest
- No `apt upgrade`
- No `apt dist-upgrade`
- No forced X11 configuration
- No Wayland disablement
- No Blender, Houdini, Parsec, Sunshine, or audio stack

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
