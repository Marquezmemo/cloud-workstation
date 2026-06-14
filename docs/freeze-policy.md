# Workstation_v0.1 Freeze Policy

`Workstation_v0.1` is an immutable restoration point for the project.

## Rules

- Do not modify the `Workstation_v0.1` baseline.
- Do not move historical tags.
- Do not replace published artifacts.
- Do not update existing dependencies in place.
- Do not execute `apt upgrade`.
- Do not execute `apt dist-upgrade`.
- Do not use mutable tags such as `latest`.
- Every functional change requires a new version.
- Every new baseline requires new fingerprinting.
- Future development must happen in new branches, new versions, and new tags.

## Required Baseline Artifacts

Before any version is treated as a frozen baseline, it must include:

- Exact image digest
- `baseline.md`
- `pip-freeze.txt`
- `dpkg-freeze.txt`
- GPU validation record
- Changelog entry

## Current Development Direction

The active development direction is `headless-gsplat-v0.1-dev`.

Its first goal is to create a headless CUDA/PyTorch image for Gaussian Splatting training:

- no desktop
- no display manager
- no Xorg/X11
- no VNC or NoMachine
- no interactive streaming
- persistent `/workspace` datasets, logs, outputs, and checkpoints

Do not install Nerfstudio or benchmark dependencies until a future benchmark branch explicitly requires them.
