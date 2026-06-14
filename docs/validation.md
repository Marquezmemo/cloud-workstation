# Validation

Registro inicial de validaciones manuales realizadas sobre la imagen base oficial.

## Imagen base

```text
runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04@sha256:61a4aafb0094cd773f11eefa378929d5a687bd775febeb78eac62fc824141fb5
```

## Resultados validados

- `nvidia-smi` exitoso
- CUDA funcional
- GPU NVIDIA detectada correctamente
- NVENC previamente validado
- SSH funcional
- networking funcional en Runpod
- compatibilidad general con Runpod validada

## Estado actual pendiente

- Headless CUDA validation with `scripts/validate-gpu.sh` pending on RunPod
- PyTorch CUDA operation validation with `scripts/validate-gpu.sh` pending on RunPod
- `gsplat` import/build validation pending
- Training log/output persistence validation pending

## Phase 3 Validation Script

`scripts/validate-gpu.sh` was added to validate the headless training base.

It checks:

- `nvidia-smi`
- Python import of `torch`
- `torch.__version__`
- `torch.version.cuda`
- `torch.cuda.is_available()`
- CUDA GPU name
- a simple CUDA matrix multiplication

Expected use inside a RunPod GPU container:

```bash
validate-gpu.sh
```

## Phase 4 Training Diagnostics

`scripts/collect-training-diagnostics.sh` was added to collect training-environment evidence without requiring a training implementation.

It collects:

- timestamp and image/workspace metadata
- OS and kernel information
- `/workspace` disk usage
- `/workspace` tree
- process list
- environment variables
- `nvidia-smi` output when available
- GPU memory/utilization query when available
- Python/PyTorch/CUDA versions
- `pip freeze`
- snapshots of datasets, scenes, outputs, logs, and checkpoints
- recent training log tails from `/workspace/logs`

Expected use inside the container:

```bash
collect-training-diagnostics.sh
```

The script writes a `.tar.gz` archive under:

```text
/workspace/logs/diagnostics
```

Local script validation:

- Ran successfully against a temporary workspace under `/tmp`.
- Produced a diagnostics archive.
- Archive included:
  - `metadata.env`
  - `nvidia-smi.txt`
  - `python-torch-cuda.txt`
  - `pip-freeze.txt`
  - `workspace-tree.txt`
  - `workspace-snapshots/`
  - `recent-logs/`

This local validation does not replace RunPod GPU validation.

Dockerfile check note:

- `docker build --check` was able to load the Dockerfile and base image metadata.
- On the local Mac/OrbStack environment it reported `InvalidBaseImagePlatform` because the host is `linux/arm64` and the pinned RunPod base image is `linux/amd64`.
- This warning is expected for the local host architecture and does not contradict the prior successful `linux/amd64` build.

## Phase 3 Local Validation

Host:

- MacBook Air
- Host platform: `linux/arm64/v8` through Docker/OrbStack
- Target image platform: `linux/amd64`

Build command:

```bash
docker build --platform linux/amd64 \
  -t cloud-workstation:headless-gsplat-v0.1-dev .
```

Result:

- Build completed successfully.
- Build duration: `106.5s`
- Build steps completed: `11/11`
- Image tag created locally:
  `cloud-workstation:headless-gsplat-v0.1-dev`

Smoke test command without GPU:

```bash
docker run --rm --platform linux/amd64 \
  cloud-workstation:headless-gsplat-v0.1-dev \
  bash -lc "pwd && ls -la /workspace && python -c 'import torch; print(torch.__version__); print(torch.version.cuda); print(torch.cuda.is_available())'"
```

Observed result:

- Container started.
- `WORKDIR` was `/workspace`.
- Persistent directories existed:
  - `/workspace/checkpoints`
  - `/workspace/datasets`
  - `/workspace/logs`
  - `/workspace/outputs`
  - `/workspace/scenes`
- PyTorch imported successfully.
- `torch.__version__`: `2.4.1+cu124`
- `torch.version.cuda`: `12.4`
- `torch.cuda.is_available()`: `False`

Interpretation:

- This is expected on the local Mac host without NVIDIA GPU passthrough.
- NVIDIA container startup warned that no NVIDIA driver was detected.
- This does not indicate a known Dockerfile error.

GPU validation attempt on local Mac:

```bash
docker run --rm --gpus all \
  cloud-workstation:headless-gsplat-v0.1-dev \
  bash scripts/validate-gpu.sh
```

Observed result:

```text
docker: Error response from daemon: failed to discover GPU vendor from CDI: no known GPU vendor found
```

Interpretation:

- Local GPU validation did not run because the host has no NVIDIA GPU/CDI vendor available.
- `scripts/validate-gpu.sh` still needs to be run inside a RunPod GPU container.
- This is a host capability limitation, not a known Dockerfile error.

## Notas

Estas validaciones corresponden al baseline previo al pivot headless. En el fingerprint final de `Workstation_v0.1`, `ffmpeg` no estaba instalado en la imagen base, por lo que NVENC queda registrado como validacion previa y no como prueba reproducida por `ffmpeg` dentro del snapshot final.

Para la validacion oficial congelada historica de `Workstation_v0.1`, ver:

- `docs/baseline.md`
- `docs/gpu-validation.md`
- `docs/nvidia-smi.txt`
- `docs/freeze-policy.md`
