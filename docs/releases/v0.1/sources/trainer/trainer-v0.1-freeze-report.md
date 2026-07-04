# The Trainer v0.1 - Freeze and Forensic Dossier

Document status: functional baseline final amendment

Final amendment: 2026-07-04

Audit branch: `audit/trainer-v0.1-freeze`

Read-only source branch: `headless-gsplat-v0.1-dev`

## 1. Executive summary

The final Trainer v0.1 baseline is runtime commit `221c4ef76a1ff5bfa8a9f45e5e9a084e8fbedfe3`, tree `f26a1a2fddd2f0a3398b3b49b5fbb61ea24038d5`, and Docker digest `sha256:726ac98c9678431fc34fbcc1de0bf07b71adbff215d672f04740a95999a6bf98`.

Its real end-to-end execution was confirmed by the repository owner and operator:

```text
validation_status: passed
validation_authority: repository-owner-operator
evidence_level: operator-confirmed
primary_execution_records: not-preserved
```

The confirmed final flow includes Surveyor archive transfer, checksum verification, automatic transactional `preparar-escena`, dataset check, CUDA training, checkpoint, PLY generation, packaging, result transfer, and viewer load. Primary logs, transcript, checkpoint, packages, and PLY were not preserved, so this confirmation is not classified as primary evidence and carries no inferred metrics.

The original Prueba02 run remains separate primary evidence for an earlier runtime:

- source commit: `90196251d59907754cc19caf76b59a737752893b`;
- source tree: `9568224839eb12bfd0bfbca4625bdea3bfe7a8bb`;
- Docker digest associated by workflow chronology: `sha256:535822530f4b23fca3eee3970b147e3e979162a32c2e9de9f76a829836b63a89`;
- evidence: manual extraction, 300-step training, `ckpt_299_rank0.pt`, PLY inspection, packaging, transfer, and SuperSplat v2.27.4.

Prueba02 metrics are not inherited by the final run. The older digest remains a historical artifact and is not the stable Trainer v0.1 digest.

Proposed immutable identifiers:

- Git tag `trainer-v0.1.0-smoke-validated` targeting commit `221c4ef76a1ff5bfa8a9f45e5e9a084e8fbedfe3`;
- Docker tag `headless-gsplat-v0.1.0` targeting digest `sha256:726ac98c9678431fc34fbcc1de0bf07b71adbff215d672f04740a95999a6bf98` without rebuilding.

No Git tag or Docker tag was created by this audit.

## 2. Evidence language and confidence

This dossier uses four evidence levels:

- **Validated**: supported by versioned evidence, a preserved workflow log, an executable local test, or an inspected artifact.
- **Reported**: preserved as an operator observation, but the original raw artifact or log is unavailable.
- **Inferred**: derived from immutable chronology or source behavior and explicitly identified as inference.
- **Operator-confirmed**: pass/fail outcome confirmed by the repository owner and operator without preserved primary execution records.

This distinction is important because the repository preserves the Prueba02 report and screenshot, but not the large scene archive, checkpoint, PLY files, full pod transcript, or pod-side image digest.

## 3. Git identity and chain of custody

| Item | Value |
| --- | --- |
| Remote fetch/push | `https://github.com/Marquezmemo/cloud-workstation.git` |
| Source branch | `headless-gsplat-v0.1-dev` |
| Source HEAD recorded before audit | `221c4ef76a1ff5bfa8a9f45e5e9a084e8fbedfe3` |
| Source tree | `f26a1a2fddd2f0a3398b3b49b5fbb61ea24038d5` |
| Audit branch | `audit/trainer-v0.1-freeze` |
| Audit branch base | `221c4ef76a1ff5bfa8a9f45e5e9a084e8fbedfe3` |
| Final documentation commit | `123652ea97f549e1d06d3993f55c2bcab252f840` |
| Final baseline runtime commit | `221c4ef76a1ff5bfa8a9f45e5e9a084e8fbedfe3` |
| Final baseline runtime tree | `f26a1a2fddd2f0a3398b3b49b5fbb61ea24038d5` |
| Historical Prueba02 runtime | `90196251d59907754cc19caf76b59a737752893b` |

The tracked source tree had no diff at audit start. The original shared worktree contained an unrelated untracked `output/` directory with Surveyor freeze artifacts. It was not modified, moved, staged, or copied. The audit was created in an isolated worktree based on the exact source HEAD.

The audit changes only this dossier and its generated artifacts. Functional paths such as `Dockerfile`, workflows, requirements, scripts, tests, trainer, patch, exporter, and packaging remain byte-for-byte equal to source HEAD `221c4ef`.

## 4. Docker identity

### 4.1 Final v0.1 image

| Item | Value |
| --- | --- |
| Workflow | `Publish Headless gsplat Dev` |
| Workflow run | `https://github.com/Marquezmemo/cloud-workstation/actions/runs/28413758338` |
| Result | success |
| Source commit | `221c4ef76a1ff5bfa8a9f45e5e9a084e8fbedfe3` |
| Tag configured by workflow | `docker.io/${DOCKERHUB_USERNAME}/cloud-workstation:headless-gsplat-v0.1-dev` |
| Manifest digest | `sha256:726ac98c9678431fc34fbcc1de0bf07b71adbff215d672f04740a95999a6bf98` |
| Platform | `linux/amd64` |
| Validation | `operator-confirmed`; primary records not preserved |

### 4.2 Historical Prueba02 publication

| Item | Value |
| --- | --- |
| Workflow run | `https://github.com/Marquezmemo/cloud-workstation/actions/runs/28285526569` |
| Source commit | `90196251d59907754cc19caf76b59a737752893b` |
| Manifest digest | `sha256:535822530f4b23fca3eee3970b147e3e979162a32c2e9de9f76a829836b63a89` |
| Relationship to final baseline | historical runtime with preserved Prueba02 evidence |

The failed documentation-triggered workflow run `28411332932` did not replace the development tag. The next successful run published the final `221c4ef` image.

### 4.3 Base image

```text
runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04
@sha256:61a4aafb0094cd773f11eefa378929d5a687bd775febeb78eac62fc824141fb5
```

The base image is pinned by manifest digest. The Trainer does not use `latest`.

## 5. Runtime and fixed dependencies

### 5.1 Runtime identity

| Component | Identity | Evidence note |
| --- | --- | --- |
| Ubuntu | 22.04 base | Dockerfile/base identity |
| Python | 3.11 line; 3.11.10 previously observed | Earlier RunPod runtime evidence; not separately recaptured in the Prueba02 record |
| PyTorch | base 2.4.0 line; `2.4.1+cu124` previously observed | Earlier RunPod runtime evidence |
| CUDA toolkit/runtime in Trainer | 12.4 line | Base tag and earlier runtime evidence |
| GPU used by Prueba02 | NVIDIA GeForce RTX 4090 | Operator and validation record |
| gsplat | `1.5.3` | Exact requirement and build label |
| OpenCV | `opencv-python-headless==4.10.0.84` | Exact requirement |
| runpodctl | `2.5.0` | Docker build ARG and verified binary checksum |

The Surveyor runtime had a different CUDA stack. Its reported CUDA versions do not redefine the Trainer image identity.

### 5.2 Core Python requirements

```text
gsplat==1.5.3
jaxtyping==0.3.11
ninja==1.13.0
numpy==1.26.3
rich==14.3.4
typing_extensions==4.15.0
wadler-lindig==0.1.7
```

### 5.3 Official trainer requirements

```text
fused-ssim @ git+https://github.com/rahul-goel/fused-ssim@328dc9836f513d00c4b5bc38fe30478b4435cbb5
imageio[ffmpeg]==2.37.3
matplotlib==3.11.0
numpy==1.26.3
opencv-python-headless==4.10.0.84
piexif==1.1.3
pycolmap @ git+https://github.com/rmbrualla/pycolmap@cc7ea4b7301720ac29287dbe450952511b32125e
pyyaml==6.0.2
scikit-learn==1.4.2
scipy==1.12.0
tensorboard==2.20.0
torchmetrics[image]==1.9.0
tqdm==4.68.2
tyro==1.0.13
```

Direct dependencies are pinned, including both Git dependencies by commit. Transitive dependencies are not fully locked with hashes. Historical `pip-freeze.txt` and `dpkg-freeze.txt` belong to the earlier workstation baseline and are not treated as a complete freeze of the Prueba02 Trainer image.

### 5.4 System packages added by Trainer

```text
git cmake ninja-build build-essential ffmpeg wget curl unzip nano htop tmux ca-certificates
```

## 6. Official source and exact headless patch

The training backend is the official gsplat example:

```text
repository: https://github.com/nerfstudio-project/gsplat
release line: v1.5.3
commit: 937e29912570c372bed6747a5c9bf85fed877bae
path: examples/simple_trainer.py
installed path: /opt/gsplat/examples/simple_trainer.py
```

The build removes the cloned `.git` directory after checking out the fixed commit.

`patch-gsplat-simple-trainer-headless.sh` performs only these source substitutions:

1. Replaces `import viser` with `viser = None` and a headless comment.
2. Replaces `GsplatViewer` and `GsplatRenderTabState` imports with local stubs. Constructing the viewer stub raises an explicit headless error.
3. Replaces `CameraState`, `RenderTabState`, and `apply_float_colormap` imports with object/function stubs. Calling the colormap stub raises an explicit headless error.
4. Verifies that the three top-level viewer import forms no longer remain.

The patch does not alter training math, camera parsing, optimizer behavior, checkpoint serialization, PLY export, or dataset loading. The wrapper also passes `--disable_viewer` and rejects `DISABLE_VIEWER=false`.

## 7. Training architecture

```text
Surveyor package
  -> preparar-escena <scene>-surveyor-scene.tar.gz
  -> transactional /workspace/scenes/<scene>
  -> train-scene.sh --check <scene> (invoked by importer)
  -> official simple_trainer.py default --disable_viewer
  -> CUDA training
  -> /workspace/outputs/<scene>/ckpts/ckpt_<step>_rank<rank>.pt
  -> generar / generate-ply.py
  -> standard and compressed PLY
  -> empaquetar
  -> runpodctl transfer
  -> independent inspection / SuperSplat
```

The official trainer initializes CUDA device `cuda:<local_rank>`, parses COLMAP data, creates splats and optimizers, trains for `max_steps`, and writes the final checkpoint at `max_steps - 1`. This explains `MAX_STEPS=300` producing `ckpt_299_rank0.pt`.

The checkpoint contains at least:

```text
step
splats: means, scales, quats, opacities, sh0, shN
```

Optional pose or appearance state is added only when the corresponding features are enabled.

## 8. Workspace, command surface, and persistence

### 8.1 Final baseline layout at commit 221c4ef

```text
/workspace/datasets
/workspace/scenes
/workspace/outputs
/workspace/logs
/workspace/checkpoints
/workspace/temp
```

Persistence is not provided by directory creation alone. Datasets, scenes, outputs, logs, checkpoints, and transfer artifacts are persistent only when `/workspace` is backed by RunPod persistent storage or a mounted volume.

### 8.3 CMD

```text
CMD ["runpod-keepalive.sh"]
```

The keepalive command creates `/workspace/logs`, prints validation hints, and runs `sleep infinity` so a non-interactive pod remains available.

### 8.4 Commands

| Command | Responsibility | Final v0.1 image |
| --- | --- | --- |
| `prepare-dataset.sh` | Creates an empty COLMAP scene skeleton | present |
| `train-scene.sh --check` | Structural dataset gate and run metadata | present and exercised |
| `train-scene.sh` | Wraps official trainer, logs and checkpoint alias | present and exercised |
| `generar` / `Generar` | Calls `generate-ply.py` | present and exercised |
| `empaquetar` | Archives PLY exports and writes checksum | present and exercised |
| `comprimir` | Alias for `empaquetar` | present |
| `empaquetar-logs` | Packages scene-scoped existing evidence with portable checksum | present; not part of preserved Prueba02 sequence |
| `collect-training-diagnostics.sh` | Captures runtime, GPU, environment, trees and recent logs | present |
| `validate-gpu.sh` | Verifies NVIDIA, torch, CUDA operation and gsplat import | present |
| `preparar-escena` | Securely verifies and imports Surveyor archive | present; regression-tested; operator-confirmed |

## 9. Surveyor-to-Trainer scene contract

Prueba02 arrived as `Prueba02-surveyor-scene.tar.gz` with an adjacent portable checksum record. The checksum was verified in Surveyor and after receipt by Trainer. The exact scene archive SHA-256 was not preserved in the attachments and is not reconstructed here.

Minimum Trainer scene structure:

```text
/workspace/scenes/Prueba02/
  images/
  sparse/0/cameras.bin
  sparse/0/images.bin
  sparse/0/points3D.bin
  surveyor-manifest.json
```

Surveyor evidence records 30 input/database/registered images, one camera, `camera_model=OPENCV`, two sparse candidates, and selection of the 30-image, 4,555-point model normalized to `sparse/0`.

During Prueba02 original the archive was manually extracted before `train-scene.sh --check` passed. In the final baseline, `preparar-escena` verifies the portable checksum, inspects the tar and manifest, installs transactionally with rollback, and runs the productive dataset check. Its real use is operator-confirmed; primary execution records were not preserved.

## 10. Camera and real OPENCV undistortion behavior

Prueba02 used one COLMAP `OPENCV` camera. The fixed official parser does not ignore distortion.

For every camera it reads:

```text
fx, fy, cx, cy
```

For `OPENCV` it also reads:

```text
k1, k2, p1, p2
```

It constructs the initial intrinsic matrix `K`, then for perspective distortion:

1. Calls `cv2.getOptimalNewCameraMatrix(K, params, size, 0)`.
2. Calls `cv2.initUndistortRectifyMap(...)` with the corrected matrix.
3. Stores the corrected intrinsic matrix and valid ROI.
4. Updates the effective image size to the ROI dimensions.
5. In dataset loading, calls `cv2.remap(...)`.
6. Crops the remapped image to the valid ROI.
7. Supplies the corrected image and corrected `K` to training.

The warning `COLMAP Camera is not PINHOLE. Images have distortion.` reports the input model. It is not evidence that distortion is ignored.

Surveyor copies source images into the scene and runs feature extraction, matching, and mapping. It does not invoke COLMAP `image_undistorter`. Therefore v0.1 performs one undistortion in the fixed gsplat parser. It does not change the Surveyor camera to `PINHOLE`, and it does not perform a second undistortion.

**Double-undistortion risk:** a future implementation must change both halves of the contract together. If Surveyor starts delivering already-undistorted images but leaves OPENCV distortion parameters active, the Trainer parser will remap them again. If Surveyor changes the camera metadata without matching image geometry and corrected intrinsics, training will receive an inconsistent camera model.

Primary source:

```text
https://github.com/nerfstudio-project/gsplat/blob/937e29912570c372bed6747a5c9bf85fed877bae/examples/datasets/colmap.py
```

## 11. Checkpoints, outputs, and exports

`train-scene.sh` writes:

```text
/workspace/logs/<scene>/run.env
/workspace/logs/<scene>/run.summary
/workspace/logs/<scene>/train.log
/workspace/logs/<scene>/error.tail       # failure only
/workspace/outputs/<scene>/...
/workspace/checkpoints/<scene>           # symlink to outputs/<scene>/ckpts
```

The official trainer creates:

```text
ckpts/
stats/
renders/
ply/
tb/
```

`generate-ply.py` discovers or accepts an explicit checkpoint, loads tensors, normalizes required fields, uses `gsplat.export_splats`, and writes:

```text
/workspace/outputs/<scene>/exports/<scene>.ply
/workspace/outputs/<scene>/exports/<scene>.compressed.ply
/workspace/logs/<scene>/generate-ply.log
```

The standard PLY gate requires binary little endian encoding and a vertex count equal to the checkpoint splat count. The compressed gate rejects a count larger than the input count.

`empaquetar` includes existing `.ply` files in `<scene>-ply-exports.tar.gz`. Its checksum record contains the absolute pod path in the validated v0.1 behavior. It can be checked in place; after transfer the digest must be compared manually. `empaquetar-logs` uses a relative, portable checksum but does not generate telemetry.

## 12. Prueba02 evidence

| Observation | Result | Evidence level |
| --- | ---: | --- |
| Scene archive | `Prueba02-surveyor-scene.tar.gz`; checksum passed | Validated; exact archive digest not preserved |
| Scene archive size | 741.1 MB; transfer UI showed 777 MB | Reported and versioned in Surveyor record |
| Images | 30 | Validated |
| Camera | 1 x OPENCV | Validated |
| Training depth | `MAX_STEPS=300` | Validated |
| Duration | 2:20 | Validated record |
| Throughput | 2.13 it/s | Validated record |
| Final reported loss | 0.196 | Reproducibility observation only; not a quality score |
| Initial Gaussians | 4,555 | Validated record |
| Final Gaussians | 4,555 | Validated record |
| Checkpoint | `ckpt_299_rank0.pt` | Validated record |
| Reported GPU memory | 3.2356 GB | Validated record |
| Standard PLY | 1,076,455 bytes | Validated record |
| Compressed PLY | 280,894 bytes | Validated record |
| Standard vertices | 4,555 | Independently inspected |
| Compressed vertices | 4,555 | Export log/operator record |
| Standard non-finite values | 0 NaN, 0 infinities | Independently inspected |
| Compressed non-finite values | 0 NaN, 0 infinities | Operator assertion in freeze mission; raw compressed artifact/inspection output not versioned |
| SuperSplat | Standard PLY loaded and rendered as 4,555 splats in v2.27.4 | Validated screenshot |

The independently inspected standard PLY had SHA-256:

```text
f7acbb332667a028756f7f2426dd07bfde577f66f30ef0dfa27b02449eea5c71
```

It was binary little endian, contained 59 float properties, had an exact payload for its header and vertex count, and contained no NaN or infinite values.

![Prueba02 loaded in SuperSplat](../../evidence/prueba02/prueba02-supersplat.png)

The unchanged Gaussian count means the run did not validate densification. The screenshot proves compatibility and rendering, not professional geometry, commercial quality, capture quality, or production readiness.

## 12A. Final v0.1 Operator Validation

The repository owner and execution operator confirmed the final runtime flow for scene `Prueba02`:

```text
validation_status: passed
validation_authority: repository-owner-operator
evidence_level: operator-confirmed
primary_execution_records: not-preserved
```

| Field | Result |
| --- | --- |
| Runtime commit | `221c4ef76a1ff5bfa8a9f45e5e9a084e8fbedfe3` |
| Docker digest | `sha256:726ac98c9678431fc34fbcc1de0bf07b71adbff215d672f04740a95999a6bf98` |
| Transfer and checksum | passed |
| `preparar-escena` and transactional installation | passed |
| Dataset check and CUDA training | passed |
| Checkpoint and PLY | generated |
| Packaging, transfer and viewer load | passed |
| Primary logs, transcript and artifacts | not preserved |
| Professional/commercial quality | not evaluated |
| Densification | not certified |

This attestation validates the stated outcomes only. It does not inherit Prueba02 metrics and does not authorize inference of the exact execution date, training depth, duration, performance, hashes, sizes, counts, or quality.

## 13. Tests executed for this freeze

No GPU training, model download, image build, or image publication was performed.

Non-destructive checks executed from the audit worktree:

```text
bash -n for all existing Trainer shell entrypoints
bash tests/test-preparar-escena-trainer.sh
git diff --exit-code <source-head> -- Dockerfile workflows requirements scripts tests
```

Result:

```text
All 15 preparar-escena tests passed.
Functional diff against source HEAD: zero.
```

The suite covers help/arguments, success through the productive `train-scene.sh --check`, missing files, checksum mismatch, path traversal, absolute paths, multiple roots, filename/root mismatch, invalid manifest, manifest consistency, COLMAP structure, existing destination, safe overwrite, rollback, capitalization, and source archive preservation.

These tests validate final runtime `221c4ef`. Prueba02 original at `9019625` predates `preparar-escena` and remains a separate evidence-bearing execution.

## 14. Limitations

- Densification was not validated; the Gaussian count stayed at 4,555.
- Professional quality was not validated.
- Commercial quality was not validated.
- The loss value 0.196 is not a quality score.
- PSNR, SSIM, LPIPS, comparable renders, and a quality threshold were not preserved.
- The full scene archive, checkpoint, PLY files, compressed PLY inspector output, and full pod logs are outside Git.
- The exact scene archive digest was not preserved in the local attachments.
- The pod-side image digest was not captured. The validated digest association is based on immutable workflow chronology.
- Primary execution records for the final `221c4ef` validation were not preserved.
- `empaquetar` writes an absolute-path checksum in the validated image.
- GPU telemetry was not continuously packaged by Trainer.
- Files above 1 GB, interrupted transfers, resume behavior, and measured transfer throughput remain unvalidated.
- The first run downloaded a 233 MB AlexNet model and spent 61.61 seconds setting up a CUDA extension; these are operational observations, not frozen performance guarantees.

## 15. Risks

1. **Moving development tag.** `headless-gsplat-v0.1-dev` is mutable; restoration must use the final digest.
2. **Evidence-level confusion.** The final operator confirmation must not be presented as preserved primary evidence.
3. **Unpinned transitive dependencies.** Rebuilding the same Dockerfile can produce a different manifest digest.
4. **Double undistortion.** Changing only Surveyor image geometry or only camera metadata can cause a second remap or inconsistent intrinsics.
5. **Evidence gaps.** Missing large artifacts prevent independent replay of every numerical claim.
6. **Short smoke depth.** A 300-step run proves pipeline function, not convergence or final quality.
7. **Diagnostics sensitivity.** Global diagnostics can contain environment data and must be handled as potentially sensitive evidence.

## 16. Recovery procedure

To recover the final v0.1 runtime without rebuilding:

1. Resolve the proposed Git tag target to commit `221c4ef76a1ff5bfa8a9f45e5e9a084e8fbedfe3`.
2. Pull the image by digest, not by mutable development tag:

```text
docker.io/${DOCKERHUB_USERNAME}/cloud-workstation@sha256:726ac98c9678431fc34fbcc1de0bf07b71adbff215d672f04740a95999a6bf98
```

3. Mount persistent storage at `/workspace`.
4. Restore `Prueba02-surveyor-scene.tar.gz` and its adjacent checksum.
5. Run `preparar-escena /workspace/Prueba02-surveyor-scene.tar.gz`; it verifies the checksum and runs the dataset check.
6. Define an explicit `MAX_STEPS` for a new replay and preserve all primary records.
7. Export with `generar --scene Prueba02`, package with `empaquetar Prueba02`, and verify checksums at both ends.

To create the proposed stable Docker tag without rebuilding, an authorized registry operation should copy the existing digest to `headless-gsplat-v0.1.0`. The operation must verify the resulting tag resolves to the same manifest digest. This audit does not execute that mutation.

## 17. Handoff to The Eye

The Eye should integrate the following facts into official documentation without altering runtime behavior:

- freeze runtime source `221c4ef` and digest `sha256:726ac98...a6bf98` as the final baseline;
- retain `9019625` and `sha256:535822...b63a89` only as historical Prueba02 identity;
- record the OPENCV remap/crop behavior and remove any implication that the warning means distortion is ignored;
- preserve the double-undistortion warning;
- state that `preparar-escena` is regression-tested and operator-confirmed in real operation, without preserved primary records;
- preserve Prueba02 numbers with evidence grades and limitations;
- do not claim densification, professional quality, or commercial quality;
- do not claim the compressed PLY non-finite scan is independently reproducible unless its raw inspection evidence is preserved;
- adopt the proposed Git and Docker tags only after verifying their exact targets;
- retain this report, JSON manifest, PDF, and `SHA256SUMS` as one evidence set.

## 18. Primary references

- Repository: `https://github.com/Marquezmemo/cloud-workstation`
- Historical Prueba02 image workflow: `https://github.com/Marquezmemo/cloud-workstation/actions/runs/28285526569`
- Final baseline image workflow: `https://github.com/Marquezmemo/cloud-workstation/actions/runs/28413758338`
- Official trainer: `https://github.com/nerfstudio-project/gsplat/blob/937e29912570c372bed6747a5c9bf85fed877bae/examples/simple_trainer.py`
- Official COLMAP parser: `https://github.com/nerfstudio-project/gsplat/blob/937e29912570c372bed6747a5c9bf85fed877bae/examples/datasets/colmap.py`
- Versioned Prueba02 record: `docs/validation-runs/2026-06-29-prueba02-trainer-e2e.md`
- Final operator attestation: `docs/validation-runs/2026-07-04-trainer-v0.1-final-operator-attestation.md`
- Versioned SuperSplat evidence: `docs/evidence/prueba02-supersplat.png`

## 19. Freeze declaration

The Trainer v0.1 final baseline is runtime `221c4ef76a1ff5bfa8a9f45e5e9a084e8fbedfe3` under digest `sha256:726ac98c9678431fc34fbcc1de0bf07b71adbff215d672f04740a95999a6bf98`. Its real flow is operator-confirmed and its primary execution records were not preserved. Prueba02 original remains separate primary evidence for runtime `9019625` and historical digest `sha256:535822530f4b23fca3eee3970b147e3e979162a32c2e9de9f76a829836b63a89`.

This is a smoke-validated baseline, not a quality-certified release.
