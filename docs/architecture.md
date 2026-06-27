# Architecture

`cloud-workstation` is now oriented toward a headless Gaussian Splatting pipeline on NVIDIA GPUs in RunPod.

## Conceptual Architecture

```text
Headless Gaussian Splatting pipeline
↓
COLMAP image
↓
COLMAP-prepared scene
↓
Trainer image
↓
checkpoints + PLY exports
↓
Full image target for single-image operation
```

## Image Roles

`COLMAP` image:

- prepares input image datasets
- is implemented separately as `headless-surveyor-v0.1-dev`
- generates sparse reconstruction and handoff evidence for Trainer

`Trainer` image:

- current validated line
- uses pinned `gsplat==1.5.3`
- trains with the official headless `examples/simple_trainer.py`
- exports standard and compressed PLY files from checkpoints
- packages outputs for transfer

`Full` image:

- future heavier image
- combines COLMAP and Trainer tooling
- should preserve the same workspace, logging, validation, and transfer evidence contracts

## Principles

- Keep the container headless.
- Keep CUDA/GPU validation explicit.
- Keep datasets and outputs outside ephemeral container paths.
- Keep training logs easy to collect.
- Avoid desktop, display manager, viewer, VNC, NoMachine, streaming, and Blender GUI dependencies.
- Add training capabilities incrementally and document each phase.

## Workspace Contract

Current Trainer paths:

```text
/workspace/datasets
/workspace/scenes
/workspace/outputs
/workspace/logs
/workspace/checkpoints
```

Do not delete, overwrite, move, or unpack user data automatically without explicit validation.

## Transfer Contract

`runpodctl v2.5.0` is installed in the Trainer image from the official GitHub release with checksum verification during build:

```text
Mac -> runpodctl -> pod
pod -> runpodctl -> Mac
```

Installation is implemented. It is intended for compressed datasets, PLY packages, and files that may exceed 1 GB. End-to-end Mac-to-pod and pod-to-Mac transfer still require evidence-backed smoke testing. SCP through `ssh.runpod.io` is not the selected transfer path.

Trainer evidence is scene-scoped under `/workspace/logs/<scene>`. `empaquetar-logs <scene>` packages existing training, export, and optional GPU logs with a portable checksum; it does not create telemetry.

## Backend Strategy

`gsplat` is the initial technical baseline.

Training scripts should be designed so the backend can be wrapped or replaced later without rewriting the whole project.

Nerfstudio/Splatfacto is reserved for a future benchmark branch, not for the first headless image.
