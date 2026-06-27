# Changelog

## Documentation Correction And Evidence Policy

- Corrected current Trainer documentation to match the implemented workspace and command surface.
- Removed `generar --list`; it is not implemented or planned for the current phase.
- Removed Trainer references to `/workspace/incoming`, `/workspace/archives`, and `/workspace/temp`.
- Recorded `runpodctl v2.5.0` as installed while keeping transfer validation pending.
- Documented `empaquetar-logs` as scene-scoped evidence packaging.
- Reclassified the reported 30,000-iteration run as a historical operator report because its original evidence was not preserved.

Correction to the earlier "runpodctl and Trainer Usability" entry: the current image does not implement Python binary fallback, `generar --list`, the three removed workspace paths, portable checksums in `empaquetar`, or automatic transfer messaging. The current Dockerfile does install pinned `runpodctl v2.5.0`.

## Headless Gaussian Splatting Pivot - Command Reference

Added a single operator command guide for the current headless Trainer workflow.

### Added

- `docs/command-reference.md`
- README link to the full command reference

### Documented

- dataset preparation and scene validation commands
- short training commands and trainer passthrough arguments
- current `generar` syntax for scene, checkpoint, checkpoint directory, format, and device selection
- `empaquetar` / `comprimir` packaging commands
- checksum verification commands
- `runpodctl send` / `runpodctl receive` transfer command shape

### Not Changed

- No Dockerfile changes in this documentation pass.
- No script changes in this documentation pass.
- No command behavior changes.

## Headless Gaussian Splatting Pivot — runpodctl and Trainer Usability

Implemented the small Trainer usability pass for the current headless image.

### Changed

- Installed fixed-version `runpodctl v2.5.0` during image build.
- Verified the Linux amd64 `runpodctl` binary checksum during build.
- Added standard workspace directories `incoming`, `archives`, and `temp`.
- Added Python binary fallback support for trainer/export/diagnostic wrappers.
- Added `generar --list` for checkpoint discovery without export.
- Improved `generar` error messages for common invalid scene/path forms.
- Updated `empaquetar` to write portable checksum files and print `runpodctl` transfer commands.

### Not Changed

- No `gsplat` version change.
- No COLMAP installation.
- No desktop, viewer, VNC, GDM, XFCE, or streaming work.

## Headless Gaussian Splatting Pivot — Documentation Alignment

Updated documentation and validation records for the current headless operating flow.

### Documented

- At that point, `runpodctl` was selected as the transfer tool before fixed-version image implementation and smoke test.
- SCP through `ssh.runpod.io` remains discarded for the PLY/package transfer workflow.
- `generar` already supports the required explicit syntax and should not be changed before the next smoke test.
- Official export syntax is `generar --scene <scene>`, `generar --checkpoint <path>`, or `generar --ckpt-dir <path>`.
- `generar <scene>` is only a possible future ergonomic shortcut.
- `empaquetar <scene>` and `comprimir <scene>` package exports and checksums; they do not transfer files.
- Standard workspace directories `incoming`, `archives`, `scenes`, `outputs`, `logs`, and `temp` are recorded as pending implementation targets.

### Not Changed

- No Dockerfile changes.
- No script changes.
- No `runpodctl` installation.
- No `gsplat` update.
- No COLMAP or Full image implementation.
- No desktop, viewer, VNC, GDM, XFCE, or streaming work.

## Headless Gaussian Splatting Pivot — Package Transfer Messaging

Adjusted the PLY export packaging command after validating that the previous `scp -O` template through `ssh.runpod.io` did not work for this RunPod transfer.

### Changed

- Renamed `PrepararDescarga` to `empaquetar`.
- Renamed `descarga` to `comprimir`.
- Kept PLY localization, `.tar.gz` packaging, checksum generation, and final path output.
- Removed the unvalidated `scp -O` / `ssh.runpod.io` transfer template.
- The command now states that the package is ready for manual transfer and that no transfer method is configured or validated yet.

## Headless Gaussian Splatting Pivot — Manual PLY Export

Added manual PLY generation from existing `gsplat` checkpoints.

### Confirmed

- `headless-gsplat-v0.1-dev` starts successfully on RunPod.
- RTX 4090 validation passed.
- PyTorch CUDA validation passed.
- `gsplat==1.5.3` import validation passed.
- A real `gsplat` training run reached 30,000 iterations.
- Checkpoints/tensors were generated successfully.
- The missing `.ply` was caused by not invoking PLY export during training.

### Added

- `scripts/generate-ply.py`
- `scripts/Generar`
- `scripts/generar`
- `scripts/empaquetar`
- `scripts/comprimir`
- `docs/ply-export.md`

### Behavior

- `Generar` uses native `gsplat.export_splats`.
- Default export format is both standard PLY and compressed PLY.
- Checkpoints are loaded on CPU by default.
- Logs are written to `/workspace/logs/<scene>/generate-ply.log`.
- Outputs are written to `/workspace/outputs/<scene>/exports`.
- `empaquetar` packages existing PLY exports, writes a checksum, and prints final paths without suggesting an unvalidated transfer method.

### Not Included

- No upload automation.
- No HTTP server.
- No tunnel to the Mac.
- No supervisor.
- No fire-and-forget pipeline.
- No Nerfstudio.
- No COLMAP.
- No viewer.
- No desktop.

## Headless Gaussian Splatting Pivot — Phase 5A Official Trainer Baseline

Adopted the official `nerfstudio-project/gsplat` `examples/simple_trainer.py` as the first training backend baseline.

### Added

- Installed official `gsplat` source under `/opt/gsplat`.
- Pinned official examples to tag `v1.5.3` at commit:
  `937e29912570c372bed6747a5c9bf85fed877bae`
- Added `requirements-gsplat-trainer.txt` for the reduced headless COLMAP-prepared simple trainer path.
- Added `scripts/prepare-dataset.sh`.
- Added `scripts/train-scene.sh`.
- Added `scripts/patch-gsplat-simple-trainer-headless.sh` to remove top-level viewer imports from the official example during image build.
- Added `docs/dataset-format.md`.
- Added `docs/training-workflow.md`.
- Kept the validated PyPI `gsplat==1.5.3` wheel as the installed runtime and aligned the official examples to the same release line.
- Kept the trainer dependency set strictly headless: no `nerfview`, `viser`, `splines`, desktop, or virtual monitor stack.

### Training Wrapper

`train-scene.sh` wraps the official trainer with explicit variables:

- `SCENE_NAME`
- `SCENE_PATH`
- `OUTPUT_PATH`
- `CHECKPOINT_PATH`
- `LOG_PATH`
- `MAX_STEPS`
- `TRAINER_CONFIG`
- `DISABLE_VIEWER=true`

The command always uses:

```text
--disable_viewer
```

### Logs

Training runs write:

- `/workspace/logs/<scene>/train.log`
- `/workspace/logs/<scene>/run.env`
- `/workspace/logs/<scene>/run.summary`
- `/workspace/logs/<scene>/error.tail` on failure

### Dataset Scope

- Initial expected dataset format is COLMAP-prepared.
- COLMAP preparation occurs outside this image for now.
- `pycolmap` is included only as the Python parser dependency required by the official trainer.

### Validated

- Local Docker build completed successfully.
- `simple_trainer.py default --help` loads after the headless viewer patch.
- `nerfview`, `viser`, and `splines` are not installed.
- `prepare-dataset.sh --help` works.
- `train-scene.sh --help` works.
- `train-scene.sh --check` passed against a synthetic COLMAP directory skeleton.
- `run.env` and `run.summary` are generated by the wrapper.

### Not Included

- No custom trainer implementation.
- No long training validation.
- No Nerfstudio.
- No COLMAP binary/toolchain installation.
- No viewer workflow or viewer dependency stack.
- No desktop.

## Headless Gaussian Splatting Pivot — Phase 4 RunPod GPU Validation

Registered successful RunPod GPU validation for the headless `gsplat` image.

### Validated

- `validate-gpu.sh` executed successfully inside RunPod.
- Headless container startup/keepalive works in RunPod.
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
  `/workspace/logs/diagnostics/training-diagnostics-20260616T023550Z.tar.gz`

### Conclusion

Phase 4 RunPod GPU validation passed. The headless image can start on RunPod, detect RTX 4090, import `gsplat`, use PyTorch CUDA, execute a CUDA smoke operation, and generate diagnostics.

### Not Included

- No training implementation.
- No Nerfstudio.
- No COLMAP.
- No viewer.
- No desktop.

## Headless Gaussian Splatting Pivot — RunPod Keepalive

Fixed RunPod startup behavior for non-interactive pods.

### Changed

- Added `scripts/runpod-keepalive.sh`.
- Copied it into the image as `/usr/local/bin/runpod-keepalive.sh`.
- Changed default command from `CMD ["/bin/bash"]` to `CMD ["runpod-keepalive.sh"]`.

### Behavior

- Creates `/workspace/logs` on startup.
- Prints the main manual validation commands:
  - `validate-gpu.sh`
  - `collect-training-diagnostics.sh`
- Keeps the foreground container process alive with `sleep infinity`.

### Reason

RunPod can start containers without an interactive shell. In that mode, `bash` may exit immediately, causing the pod to stop even when CUDA and `gsplat` are not the failing layer.

### Constraints

- No desktop.
- No Nerfstudio.
- No COLMAP.
- No viewer.
- No `latest` publication.

## Headless Gaussian Splatting Pivot — Phase 4 gsplat Import Baseline

Added the first minimal `gsplat` installation for import and CUDA compatibility validation.

### Added

- Pinned `gsplat==1.5.3` from PyPI.
- Added `requirements-gsplat.txt` for the pinned minimal `gsplat` install set.
- Added GitHub Actions workflow to publish the dev image as `cloud-workstation:headless-gsplat-v0.1-dev`.
- `GSPLAT_VERSION=1.5.3` image environment variable.
- Docker image labels recording the `gsplat` version and source.
- `scripts/validate-gpu.sh` now checks:
  - Python import of `gsplat`
  - installed `gsplat` package version
  - existing PyTorch/CUDA smoke validation

### Source Registration

- Source: PyPI
- Package: `gsplat`
- Version: `1.5.3`
- PyPI wheel SHA256: `515a3773641f5e7f7717acab6276c0b1d6dbcad087b7968ca653337c3189a982`
- Pinned pip install set:
  - `gsplat==1.5.3`
  - `jaxtyping==0.3.11`
  - `markdown-it-py==4.2.0`
  - `mdurl==0.1.2`
  - `ninja==1.13.0`
  - `rich==15.0.0`
  - `wadler-lindig==0.1.7`

### Constraints

- No training pipeline.
- No large training run.
- No Nerfstudio installation.
- No COLMAP installation.
- No viewer.
- No desktop packages.
- No optimization work.

### Pending Validation

- Run a local container import smoke test, if desired.
- Run `validate-gpu.sh` on RunPod with NVIDIA GPU access.
- Confirm `gsplat` import, PyTorch CUDA availability, GPU name, and simple CUDA operation.

### Build Observation

- Local Docker build completed successfully with `requirements-gsplat.txt`.
- Existing Phase 3 system packages still need a later review because Ubuntu dependency resolution pulled multimedia/display-adjacent libraries and reported some system package upgrades despite `--no-upgrade`.

## Headless Gaussian Splatting Pivot — Phase 3.6

Added headless training diagnostics.

### Added

- `scripts/collect-training-diagnostics.sh`
- `/usr/local/bin/collect-training-diagnostics.sh` inside the image

### Diagnostics Coverage

The diagnostics collector captures:

- metadata and workspace paths
- OS/kernel information
- `/workspace` disk usage and tree
- process list and environment
- `nvidia-smi` when available
- GPU memory/utilization query when available
- Python/PyTorch/CUDA versions
- `pip freeze`
- snapshots of datasets, scenes, outputs, logs, and checkpoints
- recent training log tails

### Constraints

- No `gsplat` installation.
- No training implementation.
- No Nerfstudio installation.
- No COLMAP installation.
- No desktop packages.
- `CMD ["/bin/bash"]` retained.

### Local Validation

- `collect-training-diagnostics.sh` passed shell syntax validation.
- It ran successfully against a temporary local workspace.
- It produced a `.tar.gz` diagnostics archive with metadata, Python/PyTorch/CUDA report, workspace snapshots, and recent logs.
- `docker build --check` loaded the Dockerfile and base metadata, but reported the expected local host platform warning: RunPod base is `linux/amd64`, local Mac/OrbStack host is `linux/arm64`.

## Headless Gaussian Splatting Pivot — Phase 3

Added minimal headless base tooling for future GPU training work.

### Added

- Installed base tooling only:
  - `git`
  - `cmake`
  - `ninja-build`
  - `build-essential`
  - `ffmpeg`
  - `wget`
  - `curl`
  - `unzip`
  - `nano`
  - `htop`
  - `tmux`
  - `ca-certificates`
- Added `scripts/validate-gpu.sh`.
- Copied `validate-gpu.sh` into the image as `/usr/local/bin/validate-gpu.sh`.

### Validation Coverage

`validate-gpu.sh` checks:

- `nvidia-smi`
- Python import of `torch`
- `torch.__version__`
- `torch.version.cuda`
- `torch.cuda.is_available()`
- CUDA GPU name
- simple CUDA matrix multiplication

### Constraints

- No desktop packages added.
- No `gsplat` installation.
- No Nerfstudio installation.
- No COLMAP installation.
- No `apt upgrade` or `apt dist-upgrade`.
- `CMD ["/bin/bash"]` retained.

### Local Validation

- Local `linux/amd64` Docker build completed successfully.
- Local non-GPU smoke test confirmed:
  - container starts
  - `WORKDIR` is `/workspace`
  - persistent workspace directories exist
  - PyTorch imports
  - `torch.__version__` is `2.4.1+cu124`
  - `torch.version.cuda` is `12.4`
- `torch.cuda.is_available()` returned `False` locally because the Mac host does not expose an NVIDIA GPU.
- Local `--gpus all` validation could not run because Docker reported no known GPU vendor from CDI.
- Full GPU validation was pending at this phase and later passed in Phase 4.

## Headless Gaussian Splatting Pivot — Phase 2

Prepared the active branch for a headless training image.

### Changed

- Updated `Dockerfile` identity to `headless-gsplat-v0.1-dev`.
- Corrected active base image references to the platform manifest digest:
  `sha256:61a4aafb0094cd773f11eefa378929d5a687bd775febeb78eac62fc824141fb5`
- Replaced active remote-workstation description with headless Gaussian Splatting training image description.
- Created persistent workspace directories:
  - `/workspace/datasets`
  - `/workspace/scenes`
  - `/workspace/outputs`
  - `/workspace/logs`
  - `/workspace/checkpoints`
- Set `WORKDIR /workspace`.
- Updated active documentation to remove the desktop/workstation objective.

### Confirmed Removed / Not Present

- No `ubuntu-desktop-minimal`
- No GDM/GDM3
- No Xorg/X11
- No `dbus-x11`
- No `mesa-utils` / `glxinfo`
- No supervisor for graphical services
- No VNC, NoMachine, streaming, Blender GUI, Nerfstudio, or `gsplat` installation

### Deferred

- `gsplat` installation and training scripts remain for a later phase.
- COLMAP remains optional and was not added in this phase.
- Nerfstudio remains a future benchmark placeholder only.

## Headless Gaussian Splatting Pivot — Phase 1

Started the pivot from remote interactive workstation to headless Gaussian Splatting training image.

### Added

- Phase 1 audit report: `docs/pivot-headless-gaussian-splatting.md`
- Minimal active-agent state for the headless pivot: `docs/agents/README.md`

### Decisions

- New objective is headless Gaussian Splatting training on NVIDIA GPUs, primarily RTX 4090 on RunPod.
- `gsplat` is the initial technical baseline.
- Training backend design must remain configurable and not hardcoded to one repository or command.
- Nerfstudio/Splatfacto remains a future benchmark placeholder only.
- COLMAP is optional for the first image and should be moved to a later phase if it introduces heavy desktop dependencies or build complexity.
- Desktop Integration / Deky is paused and legacy.

### Not Changed In This Phase

- No aggressive Dockerfile/runtime rewrite.
- No desktop removal yet.
- No Nerfstudio installation.
- No benchmark dependencies.
- No GDM/Xorg/XFCE/VNC/streaming repair.

## Workstation_v0.1 Frozen Baseline

Baseline officially frozen and marked immutable.

### Validated

- Baseline officially frozen
- Base image pinned by SHA256
- Ubuntu 22.04.5 LTS validated
- CUDA toolkit 12.4.131 validated
- CUDA host runtime 13.0 validated
- NVIDIA GeForce RTX 4090 validated
- NVIDIA driver 580.126.20 validated
- SSH validated
- Networking validated
- Runpod compatibility validated

### Freeze Artifacts

- `docs/baseline.md`
- `docs/image-digest.md`
- `docs/gpu-validation.md`
- `docs/nvidia-smi.txt`
- `docs/evidence/nvidia-smi-2026-06-02.png`
- `docs/pip-freeze.txt`
- `docs/dpkg-freeze.txt`
- `docs/freeze-policy.md`

### Pending

- Desktop layer
- X11
- XFCE
- Streaming layer
- Blender
- Audio stack

## v0.1

Baseline inicial congelada para `Workstation_v0.1`.

### Validado

- Imagen base congelada:
  `runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04`
- CUDA validado
- GPU NVIDIA validada
- NVENC validado
- SSH validado
- networking validado
- Runpod compatibility validada

### Pendiente

- OpenGL pendiente
- Desktop layer pendiente
- Streaming layer pendiente
- X11 pendiente
- Desktop session pendiente
- Audio stack pendiente
- Blender pendiente
- Houdini support pendiente
