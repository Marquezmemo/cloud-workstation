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

- Headless CUDA validation for the new training image pending
- PyTorch CUDA operation validation pending
- `gsplat` import/build validation pending
- Training log/output persistence validation pending

## Notas

Estas validaciones corresponden al baseline previo al pivot headless. En el fingerprint final de `Workstation_v0.1`, `ffmpeg` no estaba instalado en la imagen base, por lo que NVENC queda registrado como validacion previa y no como prueba reproducida por `ffmpeg` dentro del snapshot final.

Para la validacion oficial congelada historica de `Workstation_v0.1`, ver:

- `docs/baseline.md`
- `docs/gpu-validation.md`
- `docs/nvidia-smi.txt`
- `docs/freeze-policy.md`
