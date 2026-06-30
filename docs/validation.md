# Validation

Registro inicial de validaciones manuales realizadas sobre la imagen base oficial.

## Evidence Status

Use these states consistently:

- `implemented`: directly verifiable in the current repository
- `locally verified`: command executed locally with date and command recorded
- `operator reported`: manual result without sufficient preserved evidence
- `validated with evidence`: operator questionnaire, logs, versions, commands, outputs, and hashes agree
- `pending`: not executed or insufficient evidence

Dates in validation questionnaires use Aguascalientes local time by convention.

The historical 30,000-iteration training result below is `operator reported`. Its original logs, checkpoints, run metadata, and diagnostics archive were not preserved, so it does not validate the current image.

## Manual Validation Protocol

The Eye interviews the operator after each manual RunPod test and checks the answers against preserved evidence. Record:

1. local date in Aguascalientes and test purpose
2. branch, commit, image tag, and image digest when available
3. pod/GPU, NVIDIA driver, CUDA, Python, PyTorch, and `gsplat` versions
4. scene name, source, and image count
5. exact commands in execution order and relevant environment variables
6. exit status, observed result, retries, errors, and manual interventions
7. paths and sizes for logs, summaries, checkpoints, PLY files, and packages
8. SHA-256 values before and after transfer, transfer direction, and duration
9. capabilities that passed, failed, or remain inconclusive

Run `empaquetar-logs <scene>` after the test. Large evidence archives stay outside Git; a validation record stores their location, size, SHA-256, and the small sanitized evidence needed to support the conclusion. Do not commit credentials or ephemeral transfer codes.

Store each accepted report under:

```text
docs/validation-runs/YYYY-MM-DD-<scene>-<purpose>.md
```

## Imagen base

```text
runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04@sha256:61a4aafb0094cd773f11eefa378929d5a687bd775febeb78eac62fc824141fb5
```

## Historical Operator-Reported Results

- `nvidia-smi` exitoso
- CUDA funcional
- GPU NVIDIA detectada correctamente
- RunPod headless keepalive startup validado
- PyTorch CUDA smoke operation validada en RunPod
- `gsplat` import validado en RunPod
- diagnostics archive generado correctamente en RunPod
- NVENC previamente validado
- SSH funcional
- networking funcional en Runpod
- compatibilidad general con Runpod validada

## Estado actual pendiente

- `Prueba02` ya valida con evidencia el check de escena, entrenamiento GPU de 300 pasos, checkpoint, exportación PLY, empaquetado, transferencia y carga en SuperSplat. Ver [el registro completo](validation-runs/2026-06-29-prueba02-trainer-e2e.md).
- Automatizar la extracción y preparación segura de escenas recibidas.
- Mejorar el mensaje correctivo para el orden `generar --scene <scene>` y después `empaquetar <scene>`.
- Repetir la verificación de checksum en ambos extremos para cada artefacto.
- Probar transferencia de archivo superior a 1 GB.
- Medir velocidad de transferencia.
- Probar interrupcion y confirmar si puede reanudarse.
- Evaluar OPENCV frente a PINHOLE o undistortion.
- Validar densificación, métricas de calidad y captura profesional.

## Current Operational Decisions

`runpodctl v2.5.0` is installed in the image from the official GitHub release with checksum verification during build. `Prueba02` records successful real transfers in both directions across the Surveyor/Trainer workflow. Transfer robustness above 1 GB, interruption, resume behavior, and systematic end-to-end checksum capture remain pending.

Expected use cases:

- upload compressed datasets from the Mac
- download result packages from the pod
- avoid SCP through `ssh.runpod.io`
- handle PLY packages and archives that may exceed 1 GB

Implementation evidence:

- exact `runpodctl` version: `v2.5.0`
- official download URL: `https://github.com/runpod/runpodctl/releases/download/v2.5.0/runpodctl-linux-amd64`
- binary checksum: `f484ce7d790ddc6b4a63363f3c975c70fa87bf3be1bcbad019812f6e3f4ba54e`
- image build command check: `runpodctl version`

Transfer evidence still required for the robust baseline:

- systematic checksum capture before and after every transfer
- files larger than 1 GB
- interruption and resume behavior
- measured throughput

## Current Command Smoke Matrix

The canonical operator syntax is maintained in [command-reference.md](command-reference.md). The matrix below lists the smoke-test surfaces that must keep producing evidence.

GPU/runtime:

```bash
validate-gpu.sh
```

Scene validation:

```bash
train-scene.sh --check room
```

Training:

```bash
MAX_STEPS=100 train-scene.sh room
MAX_STEPS=1000 train-scene.sh room
MAX_STEPS=10000 train-scene.sh room
```

PLY export:

```bash
generar
generar --scene room
generar --checkpoint /workspace/outputs/room/ckpts/ckpt_999_rank0.pt
generar --ckpt-dir /workspace/outputs/room/ckpts
generar --scene room --format both
generar --scene room --device cuda --fallback-cpu
```

Packaging and checksum:

```bash
empaquetar room
comprimir room
cd /workspace/outputs/room/exports
sha256sum -c room-ply-exports.tar.gz.sha256
empaquetar-logs room
```

## Known Operator Errors

- `generar --room` is invalid; use `generar --scene room`.
- `generar /room` is invalid; use `generar --scene room` or an explicit checkpoint argument.
- `generar --/workspace/checkpoints/room` is invalid; use `generar --ckpt-dir /workspace/outputs/room/ckpts`.
- Multiple scenes with checkpoints require `generar --scene <scene>` or `generar --checkpoint <path>`.
- Missing exports require running `generar --scene <scene>` before `empaquetar <scene>`.
- Files on external Mac storage should be moved to local storage such as `~/Downloads/` before using `runpodctl`.

## Phase 4 RunPod GPU Validation

Conclusion:

```text
Phase 4 RunPod GPU validation passed.
```

The headless image can start on RunPod, keep the container alive, detect an RTX 4090, import `gsplat`, use PyTorch CUDA, execute a CUDA smoke operation, and generate diagnostics.

Operator-reported observations from RunPod; original evidence was not preserved:

- `validate-gpu.sh` executed successfully inside the pod.
- GPU detected: `NVIDIA GeForce RTX 4090`
- NVIDIA-SMI: `550.127.05`
- CUDA visible through `nvidia-smi`: `12.4`
- Python: `3.11.10`
- `torch`: `2.4.1+cu124`
- `torch.version.cuda`: `12.4`
- `gsplat`: `1.5.3`
- `gsplat_import=success`
- `cuda_available=True`
- `cuda_device_index=0`
- `cuda_device_name=NVIDIA GeForce RTX 4090`
- `cuda_operation=success`
- `collect-training-diagnostics.sh` executed successfully.
- Diagnostics archive generated:

```text
/workspace/logs/diagnostics/training-diagnostics-20260616T023550Z.tar.gz
```
- The operator reported that a `gsplat` training run reached 30,000 iterations on RunPod RTX 4090.
- The operator reported that training generated checkpoints/tensors successfully.
- The operator reported that the missing `.ply` was caused by not invoking PLY export.
- The original evidence was not preserved; these statements are historical context rather than validation of the current image.

Interpretation:

- CUDA is visible to Python/PyTorch inside RunPod.
- The pinned `gsplat` package imports successfully in the GPU environment.
- The CUDA smoke operation succeeds on the RTX 4090.
- Diagnostics collection works and writes under persistent workspace logs.

Not validated in this phase:

- no automatic PLY export during training
- no upload pipeline

## PLY Export From Checkpoints

Manual PLY export is handled by:

```text
Generar
generar
```

The command uses native `gsplat.export_splats`, loads checkpoints on CPU by default, writes logs to `/workspace/logs/<scene>/generate-ply.log`, and writes outputs to `/workspace/outputs/<scene>/exports`.

Expected outputs when supported:

```text
<scene>.ply
<scene>.compressed.ply
```

Packaging for manual transfer is handled by:

```text
empaquetar
comprimir
```

This packages exports and prints final archive/checksum paths. It does not transfer files automatically.

The accepted transfer method is `runpodctl`; real use is validated by `Prueba02`, while large-file and recovery behavior remain pending.

Local validation completed:

- Docker build completed successfully.
- `/usr/local/bin/Generar` exists and is executable.
- `/usr/local/bin/generar` exists and is executable.
- `/usr/local/bin/empaquetar` exists and is executable.
- `/usr/local/bin/comprimir` exists and is executable.
- `/usr/local/bin/PrepararDescarga` is no longer installed.
- `/usr/local/bin/descarga` is no longer installed.

PLY generation from a real checkpoint was validated by `Prueba02`, including independent structural inspection and loading in SuperSplat v2.27.4.

## Phase 5A Official gsplat Trainer Adoption

Phase 5A adopts the official `gsplat` example trainer as the initial backend path.

Official source:

```text
repo: https://github.com/nerfstudio-project/gsplat
tag: v1.5.3
commit: 937e29912570c372bed6747a5c9bf85fed877bae
trainer: /opt/gsplat/examples/simple_trainer.py
```

Integration decision:

- install the official repo under `/opt/gsplat`
- keep `examples/simple_trainer.py` as the training backend baseline
- apply a minimal build-time headless patch that removes top-level viewer imports
- pin the official examples to the `v1.5.3` release line matching the installed PyPI wheel
- install a reduced dependency set for the COLMAP-prepared headless path
- include `fused-ssim` because the official `v1.5.3` trainer imports it directly
- do not install `nerfview`, `viser`, `splines`, desktop, or virtual monitor dependencies
- keep the PyPI `gsplat==1.5.3` package as the core installed package

Wrapper scripts:

- `prepare-dataset.sh`
- `train-scene.sh`

Expected validation before a real dataset:

- `prepare-dataset.sh --help`: passed locally in Docker image
- `train-scene.sh --help`: passed locally in Docker image
- `train-scene.sh --check <scene>` reports valid paths clearly: passed locally in Docker image
- official trainer help can be displayed from `/opt/gsplat/examples/simple_trainer.py`: passed locally in Docker image
- `nerfview`, `viser`, and `splines` are not installed: passed locally in Docker image

Expected validation with a real dataset:

- input is a COLMAP-prepared scene under `/workspace/scenes/<scene>`
- `train-scene.sh <scene>` launches the official trainer
- command includes `--disable_viewer`
- logs are written under `/workspace/logs/<scene>`
- outputs are written under `/workspace/outputs/<scene>`
- checkpoints are discoverable through `/workspace/checkpoints/<scene>`

Not included:

- no custom trainer
- no long training validation
- no COLMAP installation
- no Nerfstudio
- no viewer workflow or viewer dependency stack
- no desktop stack

### Phase 5A Local Smoke Validation

Local Docker build completed successfully:

```text
docker build --platform linux/amd64 -t cloud-workstation:headless-gsplat-v0.1-dev .
```

Validated inside the image:

- `torch` imports successfully
- `gsplat==1.5.3` imports successfully
- `fused_ssim` imports successfully
- `nerfview=not_installed`
- `viser=not_installed`
- `splines=not_installed`
- patched `/opt/gsplat/examples/simple_trainer.py default --help` loads successfully
- `prepare-dataset.sh --help` works
- `train-scene.sh --help` works
- `train-scene.sh --check smoke` passed against a synthetic COLMAP directory skeleton
- `run.env` and `run.summary` were generated by the wrapper

Local Docker validation was run on macOS without NVIDIA Container Toolkit GPU access, so CUDA device execution remains validated from the earlier RunPod RTX 4090 Phase 4 run and must be rechecked on RunPod after publishing this Phase 5A image.

## RunPod Keepalive Startup

RunPod may start a container without an interactive shell. In that mode, `CMD ["/bin/bash"]` can exit immediately, causing RunPod to report:

```text
Container ... is not running
```

This is not evidence of a CUDA or `gsplat` failure by itself.

The image now uses:

```text
CMD ["runpod-keepalive.sh"]
```

The keepalive script:

- creates `/workspace/logs`
- prints startup context
- prints the validation commands:
  - `validate-gpu.sh`
  - `collect-training-diagnostics.sh`
- remains alive with `sleep infinity`

Expected validation on RunPod:

- pod remains running after startup: passed
- SSH/manual shell access is possible: passed
- `validate-gpu.sh` can be run manually on the RTX 4090 pod: passed
- `collect-training-diagnostics.sh` can collect logs under `/workspace/logs`: passed

## Phase 3 Validation Script

`scripts/validate-gpu.sh` was added to validate the headless training base.

It checks:

- `nvidia-smi`
- Python import of `torch`
- `torch.__version__`
- `torch.version.cuda`
- Python import of `gsplat`
- installed `gsplat` package version
- `torch.cuda.is_available()`
- CUDA GPU name
- a simple CUDA matrix multiplication

Expected use inside a RunPod GPU container:

```bash
validate-gpu.sh
```

## Phase 3.6 Training Diagnostics

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

## Phase 4 Minimal gsplat Installation

`gsplat` is now installed as the first technical Gaussian Splatting backend baseline.

Installation source:

- Package index: PyPI
- Package: `gsplat`
- Pinned version: `1.5.3`
- PyPI wheel SHA256 reported by PyPI: `515a3773641f5e7f7717acab6276c0b1d6dbcad087b7968ca653337c3189a982`

Pinned install set:

- `gsplat==1.5.3`
- `jaxtyping==0.3.11`
- `markdown-it-py==4.2.0`
- `mdurl==0.1.2`
- `ninja==1.13.0`
- `rich==15.0.0`
- `wadler-lindig==0.1.7`

`torch` and `numpy` are provided by the pinned RunPod PyTorch base image.

The Dockerfile installs from:

```text
requirements-gsplat.txt
```

using:

```bash
python -m pip install --no-cache-dir --upgrade-strategy only-if-needed -r /tmp/requirements-gsplat.txt
```

This phase validates package availability and import compatibility only.

Explicitly not included:

- no training pipeline
- no large training run
- no Nerfstudio
- no COLMAP
- no viewer
- no desktop stack

`scripts/validate-gpu.sh` now verifies:

- `import gsplat`
- installed `gsplat` package version
- PyTorch CUDA availability
- simple CUDA operation

RunPod validation passed on an RTX 4090 pod.

Local build validation:

- `docker build --platform linux/amd64 -t cloud-workstation:headless-gsplat-v0.1-dev .` completed successfully with the final `requirements-gsplat.txt` install path.
- The pip install step installed `gsplat-1.5.3` plus the pinned dependencies listed above.
- No Nerfstudio, COLMAP, viewer, desktop service, or training pipeline was installed.
- Local container runtime import smoke test was not executed in this pass.

Build observation:

- The existing Phase 3 `ffmpeg` system dependency pulls multimedia/display-adjacent libraries through Ubuntu packages.
- The build log also showed some existing system packages being upgraded as dependency resolution side effects despite `--no-upgrade`.
- This is not caused by `gsplat`, but it should be reviewed before freezing the headless baseline.

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
