# Workstation_v0.1 Baseline

`Workstation_v0.1` is the officially frozen baseline for this project.

This version is immutable. Do not modify it directly, move its historical tags, replace its published artifacts, or update its dependencies in place.

## Base Image

- Image tag: `runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04`
- SHA256 manifest digest: `sha256:61a4aafb0094cd773f11eefa378929d5a687bd775febeb78eac62fc824141fb5`
- Dockerfile source:
  `runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04@sha256:61a4aafb0094cd773f11eefa378929d5a687bd775febeb78eac62fc824141fb5`

## System Fingerprint

- Ubuntu version: `22.04.5 LTS (Jammy Jellyfish)`
- Python version: `3.11.10`
- CUDA toolkit: `12.4.131`
- NVIDIA driver: `580.126.20`
- CUDA host runtime: `13.0`

## GPU Validation

- GPU: `NVIDIA GeForce RTX 4090`
- VRAM: `24564 MiB`
- Bus ID: `00000000:81:00.0`
- Persistence mode: `On`
- Display active: `Off`
- GPU utilization during validation: `0%`
- GPU memory usage during validation: `1 MiB / 24564 MiB`
- Compute mode: `Default`
- MIG mode: `N/A`
- Processes: `No running processes found`

See `docs/gpu-validation.md`, `docs/nvidia-smi.txt`, and `docs/evidence/nvidia-smi-2026-06-02.png`.

## Runtime Validation

- CUDA validated
- NVIDIA GPU validated
- NVENC previously validated
- SSH validated
- Networking validated
- Runpod deployment validated

## Current Layer Status

- Desktop layer: not implemented
- X11: absent
- XFCE: absent
- OpenGL: pending validation
- Streaming layer: not implemented
- Audio stack: absent
- Blender: absent
- Houdini: absent

## Freeze Artifacts

- `docs/image-digest.md`
- `docs/gpu-validation.md`
- `docs/nvidia-smi.txt`
- `docs/pip-freeze.txt`
- `docs/dpkg-freeze.txt`
- `docs/freeze-policy.md`

All future functional changes must happen in a new version, starting with `Workstation_v0.2-dev`.

## Digest Correction

The freeze record was corrected to use the platform manifest digest. The previously recorded index digest was not usable for the `v0.2-dev` build path.
