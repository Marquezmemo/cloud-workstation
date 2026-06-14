# Pivot: Headless Gaussian Splatting

## Phase 1 Status

This document is the Phase 1 audit for reorienting the project from a remote interactive workstation into a headless Docker image for Gaussian Splatting training on NVIDIA GPUs, primarily RTX 4090 on RunPod.

Phase 1 is intentionally documentation-first. It does not aggressively modify the Dockerfile or runtime.

## Phase 2 Status

Phase 2 removes the active desktop/workstation objective and prepares the headless persistent workspace layout.

Phase 2 still does not install `gsplat`, implement training, install Nerfstudio, or add benchmark dependencies.

## Phase 3 Status

Phase 3 adds minimal headless base tools and `scripts/validate-gpu.sh`.

Phase 3 still does not install `gsplat`, implement training, install Nerfstudio, install COLMAP, or add benchmark dependencies.

## Phase 4 Status

Phase 3.6 added diagnostics for the headless training environment.

Phase 4 adds a minimal pinned `gsplat` installation and import validation.

Phase 4 still does not implement training, install Nerfstudio, install COLMAP, add a viewer, or add benchmark dependencies.

## New Objective

Build a reproducible headless training image for Gaussian Splatting.

Priority order:

1. Stable Gaussian Splatting training
2. Correct CUDA/GPU usage
3. Clear logs
4. Persistent datasets and outputs
5. Zero graphical desktop environment

## Explicit Non-Goals

Do not build, repair, or install:

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

The previous desktop workstation line is paused and should be treated as legacy.

## Branching Decision

The pivot branch starts from `main` / `workstation-v0.1`, not from `workstation-v0.2-dev`.

Reason:

- `main` is closer to the frozen baseline and does not include desktop bring-up scripts.
- The desktop branch remains available as historical work, but it should not shape the headless training image.

Target branch:

```text
headless-gsplat-v0.1-dev
```

Do not move or rewrite:

- `v0.1`
- `workstation-v0.1`
- `workstation-v0.2-dev`

## Gaussian Splatting Backend Decision

`gsplat` is the initial technical baseline.

Reason:

- It is headless by design.
- It provides direct CUDA/Python control.
- It avoids viewer/SIBR/desktop assumptions.
- It keeps the first training image focused and debuggable.

The design must not hardcode the entire workflow to one repository or command. Future scripts should allow a backend wrapper pattern, for example:

```text
TRAINING_BACKEND=gsplat
TRAINING_ENTRYPOINT=<command-or-script>
SCENE_PATH=/workspace/scenes/<scene>
OUTPUT_PATH=/workspace/outputs/<scene>
LOG_PATH=/workspace/logs/<scene>.log
CHECKPOINT_PATH=/workspace/checkpoints/<scene>
```

Nerfstudio/Splatfacto is not part of this phase. It remains a future benchmark placeholder for comparing workflow, training time, VRAM, debugability, and output quality against the `gsplat` baseline.

## COLMAP Policy

COLMAP is not mandatory for the first image.

Policy:

- Attempt to include COLMAP only if it does not introduce heavy desktop dependencies or complicate the build.
- If COLMAP complicates the image, document the decision and move it to a later phase.
- The first image may assume datasets are already prepared.

## Target Persistent Layout

The future headless image should use:

```text
/workspace/datasets
/workspace/scenes
/workspace/outputs
/workspace/logs
/workspace/checkpoints
```

Nothing important should exist only inside ephemeral container paths.

## File Classification

### Conserve

These remain useful as historical baseline or project governance:

- `docs/baseline.md`
- `docs/image-digest.md`
- `docs/freeze-policy.md`
- `docs/gpu-validation.md`
- `docs/nvidia-smi.txt`
- `docs/evidence/nvidia-smi-2026-06-02.png`
- `docs/pip-freeze.txt`
- `docs/dpkg-freeze.txt`
- `.gitignore`
- `logs/.gitkeep`
- `scripts/.gitkeep`
- `startup/.gitkeep`
- `healthchecks/.gitkeep`

### Adapt

These must be rewritten for the headless training objective:

- `Dockerfile`
- `README.md`
- `CHANGELOG.md`
- `docs/architecture.md`
- `docs/roadmap.md`
- `docs/validation.md`
- `.github/workflows/publish-v0.1.yml`

Expected adaptation:

- remove workstation/desktop language
- define headless training image behavior
- define `gsplat` as initial backend
- define RunPod training workflow
- define persistent `/workspace` directories

### Eliminate In Cleanup Phase

These are not present on `main`, but exist in the legacy desktop branch and must not be carried into the headless pivot:

- `ubuntu-desktop-minimal`
- `dbus-x11`
- `xorg`
- `x11-utils`
- `supervisor` when used only for desktop process orchestration
- GDM/GDM3 startup scripts
- desktop probes
- GLX/X11 healthchecks
- `/var/log/workstation` desktop log assumptions

Specific legacy files from `workstation-v0.2-dev` to eliminate or avoid in the pivot:

- `startup/workstation-entrypoint.sh`
- `startup/start-gdm.sh`
- `startup/desktop-probe-loop.sh`
- `startup/supervisord.conf`
- `healthchecks/desktop-probe.sh`
- desktop-specific content in `scripts/collect-diagnostics.sh`
- `docs/workstation-v0.2-dev.md`
- `docs/error-log.md` as a desktop bring-up journal

### Archive As Legacy

Do not delete the historical branch or tags. Treat these as legacy references:

- branch `workstation-v0.2-dev`
- tag `workstation-v0.1`
- tag `v0.1`
- previous desktop integration docs and scripts in the legacy branch

If a future cleanup removes tracked files from the pivot branch, record it in `CHANGELOG.md`.

### Repo Hygiene Cleanup Candidate

The desktop branch contains accidental tracked artifacts that should be removed in a cleanup commit if present in the pivot working tree:

- `0`
- `N`
- `.!88950!.DS_Store`
- `.DS_Store` variants

Keep this cleanup separate from functional Docker changes.

## Agent State

Active:

- Core Infrastructure
- Observability / The Eye
- Release Governance

Paused / legacy:

- Desktop Integration / Deky
- Streaming & UX

Desktop Integration must not repair GDM, Xorg, XFCE, VNC, NoMachine, or streaming unless explicitly reactivated.

## Phase Gate Status

Phase 1 gate was satisfied before Phase 2 cleanup began.

Phase 1 completion criteria:

- pivot objective is documented
- repo files are classified
- `gsplat` baseline is documented
- backend configurability is documented
- COLMAP optional policy is documented
- agent state is documented
- `CHANGELOG.md` records the pivot start
- Dockerfile/runtime was not aggressively changed in Phase 1

Phase 2 completion criteria:

- active Dockerfile has no desktop dependencies
- persistent `/workspace` directories are prepared
- `WORKDIR /workspace` is set
- active docs no longer present the project as a remote desktop workstation
- `CHANGELOG.md` records the cleanup

## Next Phase Preview

Phase 3 should add headless CUDA/PyTorch system dependencies required for later Gaussian Splatting work. It should not install Nerfstudio or benchmark dependencies.

## Phase 2 Cleanup Record

Desktop packages were not present in this branch because the pivot starts from `main` / `workstation-v0.1`, not from `workstation-v0.2-dev`.

Explicitly not present in the active Dockerfile after Phase 2:

- `ubuntu-desktop-minimal`
- `gdm` / `gdm3`
- `xorg`
- `dbus-x11`
- `mesa-utils`
- `glxinfo`
- `supervisor`

The active Dockerfile now only prepares the headless persistent `/workspace` directory layout and starts `/bin/bash`.
