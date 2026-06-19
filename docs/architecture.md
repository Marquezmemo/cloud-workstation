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
- generates sparse/dense/reconstruction evidence according to the selected pipeline
- remains a future branch/image until implemented and validated

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

Accepted future standard paths, pending implementation:

```text
/workspace/incoming
/workspace/archives
/workspace/scenes
/workspace/outputs
/workspace/logs
/workspace/temp
```

Do not delete, overwrite, move, or unpack user data automatically without explicit validation.

## Transfer Contract

`runpodctl v2.5.0` is installed in the Trainer image from the official GitHub release with checksum verification during build:

```text
Mac -> runpodctl -> pod
pod -> runpodctl -> Mac
```

It is intended for compressed datasets, PLY packages, and files that may exceed 1 GB. End-to-end Mac-to-pod and pod-to-Mac transfer still require smoke testing. SCP through `ssh.runpod.io` is not the selected transfer path.

## Backend Strategy

`gsplat` is the initial technical baseline.

Training scripts should be designed so the backend can be wrapped or replaced later without rewriting the whole project.

Nerfstudio/Splatfacto is reserved for a future benchmark branch, not for the first headless image.
