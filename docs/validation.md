# Validation

Validation record for `headless-surveyor-v0.1-dev`.

This branch is the Surveyor COLMAP image line. Trainer and `gsplat` validation records belong to the Trainer branch and are not active validation evidence for this image.

## Evidence Status

Use these states consistently:

- `implemented`: directly verifiable in the current repository
- `locally verified`: command executed locally with date and command recorded
- `operator reported`: manual result without sufficient preserved evidence
- `operator-confirmed`: result confirmed by the repository owner and operator, without preserved primary execution records
- `validated with evidence`: operator questionnaire, logs, versions, commands, outputs, and hashes agree
- `pending`: not executed or insufficient evidence

Dates in validation questionnaires use Aguascalientes local time by convention.

## Manual Validation Protocol

The Eye interviews the operator after each manual RunPod test and checks the answers against the Surveyor evidence package. Record:

1. local date and test purpose
2. branch, commit, image tag, and image digest when available
3. pod/GPU, NVIDIA driver, CUDA, COLMAP, `gdown`, and `runpodctl` versions
4. scene name, source, image count, and matcher
5. exact commands in execution order and relevant environment variables
6. exit status, observed result, retries, errors, and manual interventions
7. manifest, model analyzer, GPU log, summary, package paths, and sizes
8. SHA-256 values before and after transfer, transfer direction, and duration
9. Trainer handoff check and 100-step training outcome
10. capabilities that passed, failed, or remain inconclusive

Run `package-surveyor-scene.sh <scene>` after reconstruction. Large scene and evidence archives stay outside Git; a validation record stores their location, size, SHA-256, and small sanitized evidence needed to support the conclusion. Do not commit credentials or ephemeral transfer codes.

Store each accepted report under:

```text
docs/validation-runs/YYYY-MM-DD-<scene>-<purpose>.md
```

## Image Under Validation

```text
docker.io/${DOCKERHUB_USERNAME}/cloud-workstation:headless-surveyor-v0.1-dev
```

Base image:

```text
colmap/colmap:20240723.601@sha256:73003557e3ffa36d801e71b7630c117f9d373c55f24e3afc6791b9b3d1ec01da
```

Expected runtime fingerprint: COLMAP 3.10, CUDA 12.3.1, Ubuntu 22.04, `gdown 6.1.0`, and `runpodctl 2.5.0`.

## First Real Run: prueba-01

The evidence-backed record is [2026-06-27-prueba-01-real-run.md](validation-runs/2026-06-27-prueba-01-real-run.md).

Validated:

- RunPod startup and Surveyor runtime fingerprint
- 30 prepared input images and 30 images in `database.db`
- exhaustive matcher, GPU enabled, single camera, and `OPENCV`
- feature extraction and matching with RTX 4090 telemetry
- ZIP preparation, scene/evidence packaging, and portable checksums
- sender-side export with `runpodctl send`

Not validated:

- Trainer handoff
- receiving and checksum verification at the transfer destination
- automatic selection of the best sparse model

Historical evidence conflict: `model-analyzer.txt` reported 2 registered images in `sparse/0`, while `colmap-mapper.log` later reached 30 registered images. `database_images=30` did not resolve this conflict. The validator used for that run checked `sparse/0` structurally without comparing sparse models.

This remains the historical verdict for `prueba-01`; it is not the current implementation status.

## Corrected Real Run: Prueba02

The evidence-backed record is [2026-06-29-prueba02-surveyor.md](validation-runs/2026-06-29-prueba02-surveyor.md).

Validated:

- valid manifest generation
- two sparse candidates enumerated and analyzed
- original sparse model `1` selected with 30 registered images and 4,555 points
- selected model normalized to `sparse/0`
- 30/30 image registration, one camera, 19,928 observations, mean track length `4.374973`, and mean reprojection error `1.133537 px`
- GPU-enabled reconstruction on an RTX 4090
- scene/evidence packaging and checksum verification
- transfer, receipt, destination checksum verification, Trainer dataset check, and 300-step Trainer execution

## Validación downstream posterior confirmada por el operador

```text
handoff_status: passed
validation_authority: repository-owner-operator
evidence_level: operator-confirmed
primary_execution_records: not-preserved
trainer_runtime: 221c4ef76a1ff5bfa8a9f45e5e9a084e8fbedfe3
```

The repository owner and operator confirmed a second downstream execution against the final Trainer runtime that incorporates `preparar-escena`:

- the Surveyor package was compatible with Trainer's `preparar-escena`;
- the checksum was accepted;
- the scene was installed correctly;
- `train-scene.sh --check` passed;
- CUDA training completed;
- a checkpoint was generated;
- a PLY was generated and packaged;
- the result was opened in a viewer.

These outcomes demonstrate that the downstream Trainer stages consumed the Surveyor contract. They do not mean that Surveyor executed training, checkpoint generation, PLY export or packaging, or the viewer. Primary execution records from this second run were not preserved. Its evidence level is therefore `operator-confirmed`; it supplements and does not replace or downgrade the preserved Prueba02 evidence.

## Local And Reported Validation

Locally verified on 2026-06-27 against commit `12428f2`:

- `bash tests/test-surveyor-contract.sh` passed.
- Contract tests accepted a valid scene and rejected missing databases, malformed or missing manifests, empty images, and empty sparse models.
- Scene and evidence checksums remained valid after moving packages to another directory.

Reported by earlier implementation work without preserved logs:

- `docker build --platform linux/amd64` completed successfully.
- `validate-surveyor.sh` passed inside the container.
- `survey-scene.sh --help` works.
- `package-surveyor-scene.sh --help` works.
- `package-surveyor-scene.sh` packaged a synthetic scene and generated a checksum.

Operator-reported on 2026-06-27: the prior image downloaded successfully but the NVIDIA runtime rejected it before startup with `unsatisfied condition: cuda>=12.9`. No Surveyor script or COLMAP command executed, so that attempt is not a Surveyor smoke test. See `docs/validation-runs/2026-06-27-surveyor-startup-cuda-compatibility.md`.

Implemented and directly verifiable: the default `CMD` starts `runpod-keepalive.sh`, not the inherited COLMAP entrypoint.

## Current Validation Commands

Validate image tools and workspace paths:

```bash
validate-surveyor.sh
```

Prepare a downloaded ZIP without modifying COLMAP output:

```bash
preparar-escena /workspace/<scene>.zip
```

The synthetic preparation test covers automatic single-ZIP selection, `__MACOSX` filtering, ZIP preservation, corrupt archives, insufficient images, case-insensitive collisions, existing destinations, unsafe paths, and failure cleanup:

```bash
tests/test-preparar-escena.sh
```

Run sparse reconstruction:

```bash
survey-scene.sh <scene>
```

Use CPU fallback if GPU/COLMAP SIFT behavior fails:

```bash
COLMAP_USE_GPU=0 survey-scene.sh <scene>
```

Use sequential matching for video-like captures:

```bash
MATCHER=sequential survey-scene.sh <scene>
```

Overwrite an existing output scene intentionally:

```bash
OVERWRITE=true survey-scene.sh <scene>
```

Package a reconstructed scene:

```bash
package-surveyor-scene.sh <scene>
```

## Current Structural Validation Gate

The current scripts accept a Surveyor scene when all of these exist and the manifest/model-selection metrics agree:

```text
/workspace/scenes/<scene>/images
/workspace/scenes/<scene>/database.db
/workspace/scenes/<scene>/sparse/0/cameras.bin
/workspace/scenes/<scene>/sparse/0/images.bin
/workspace/scenes/<scene>/sparse/0/points3D.bin
/workspace/scenes/<scene>/surveyor-manifest.json
/workspace/logs/<scene>/surveyor.env
/workspace/logs/<scene>/colmap-feature.log
/workspace/logs/<scene>/colmap-match.log
/workspace/logs/<scene>/colmap-mapper.log
/workspace/logs/<scene>/model-analyzer.txt
/workspace/logs/<scene>/surveyor-gpu.log
/workspace/logs/<scene>/surveyor.summary
```

The current validator checks `registered_images`, `sparse_model_count`, and `selected_sparse_original_index`. `Prueba02` demonstrated that the selected best model is normalized to `sparse/0` before packaging.

Packaging evidence:

```text
/workspace/archives/<scene>/<scene>-surveyor-scene.tar.gz
/workspace/archives/<scene>/<scene>-surveyor-scene.tar.gz.sha256
/workspace/archives/<scene>/<scene>-surveyor-evidence.tar.gz
/workspace/archives/<scene>/<scene>-surveyor-evidence.tar.gz.sha256
```

## Pending Validation

- repeat corrected Surveyor-to-Trainer handoff with additional scenes
- define minimum acceptable registered-image ratio and reconstruction-quality thresholds
- compare `OPENCV` input against an undistorted/PINHOLE handoff before long Trainer runs

## Known Risks

- SIFT GPU extraction or matching may fail without visible NVIDIA runtime.
- `exhaustive_matcher` scales poorly for larger image sets.
- COLMAP can produce multiple sparse components; current selection prefers registered-image count, then point count, then original index.
- Packaging can remain silent during compression; byte-based progress is not implemented.
- Dense reconstruction is intentionally excluded from v0.1.
- Capture quality requirements are not formalized yet.
