# Architecture

`cloud-workstation` is now oriented toward headless Gaussian Splatting training on NVIDIA GPUs in RunPod.

## Conceptual Architecture

```text
Headless Gaussian Splatting training image
↓
Ubuntu 22.04 / RunPod PyTorch base
↓
NVIDIA runtime + CUDA
↓
PyTorch
↓
Backend-configurable training wrapper
↓
/workspace persistent datasets, logs, outputs, checkpoints
```

## Principles

- Keep the container headless.
- Keep CUDA/GPU validation explicit.
- Keep datasets and outputs outside ephemeral container paths.
- Keep training logs easy to collect.
- Avoid desktop, display manager, viewer, VNC, NoMachine, streaming, and Blender GUI dependencies.
- Add training capabilities incrementally and document each phase.

## Backend Strategy

`gsplat` is the initial technical baseline.

Training scripts should be designed so the backend can be wrapped or replaced later without rewriting the whole project.

Nerfstudio/Splatfacto is reserved for a future benchmark branch, not for the first headless image.
