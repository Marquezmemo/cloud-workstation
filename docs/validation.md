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

## Local Build Note

Before and during Phase 3, local Docker validation could not run because the Docker/OrbStack daemon was not active:

```text
failed to connect to the docker API at unix:///Users/guillermomarquez/.orbstack/run/docker.sock
```

This was an environment availability issue, not a known Dockerfile error.

## Notas

Estas validaciones corresponden al baseline previo al pivot headless. En el fingerprint final de `Workstation_v0.1`, `ffmpeg` no estaba instalado en la imagen base, por lo que NVENC queda registrado como validacion previa y no como prueba reproducida por `ffmpeg` dentro del snapshot final.

Para la validacion oficial congelada historica de `Workstation_v0.1`, ver:

- `docs/baseline.md`
- `docs/gpu-validation.md`
- `docs/nvidia-smi.txt`
- `docs/freeze-policy.md`
