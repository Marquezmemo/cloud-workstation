# Surveyor Startup CUDA Compatibility

Status: `operator reported`

Date: 2026-06-27, Aguascalientes local-time convention

## Purpose

Start the published `headless-surveyor-v0.1-dev` image on RunPod before the real reconstruction smoke test.

## Reported Image

- Image: `marquezmemo/cloud-workstation:headless-surveyor-v0.1-dev`
- Reported project digest: `sha256:1d571a05...` (partial only)
- Base digest: `sha256:187ca5ec98e55ed8fbec5f43f9d8f78b7a322b3b7413356634191f7a43c1efcf`
- Base CUDA requirement: `cuda>=12.9`

## Observed Result

The image downloaded successfully, but the NVIDIA container runtime rejected every startup attempt before the container command ran:

```text
nvidia-container-cli: requirement error:
unsatisfied condition: cuda>=12.9
```

Consequently, `runpod-keepalive.sh`, `validate-surveyor.sh`, `runpodctl`, and COLMAP were not executed. No workspace, reconstruction, package, or Trainer behavior was tested.

## Classification

- Docker Hub image download: operator-reported success
- Container startup: operator-reported failure
- Surveyor smoke test: not started
- Root cause: image CUDA requirement incompatible with the selected RunPod host driver

## Missing Evidence

- Full project image digest
- Raw startup log stored with the repository evidence
- Pod identifier, GPU model, and exact NVIDIA driver version
- Exact retry commands and timestamps

## Required Follow-up

Publish and test the pinned COLMAP 3.10/CUDA 12.3.1 replacement. Do not bypass `NVIDIA_REQUIRE_CUDA`. The next run must preserve the complete image digest, startup log, GPU/driver fingerprint, and `validate-surveyor.sh` output before proceeding to reconstruction.
