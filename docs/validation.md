# Validation

Validation record for `headless-surveyor-v0.1-dev`.

This branch is the Surveyor COLMAP image line. Trainer and `gsplat` validation records belong to the Trainer branch and are not active validation evidence for this image.

## Evidence Status

Use these states consistently:

- `implemented`: directly verifiable in the current repository
- `locally verified`: command executed locally with date and command recorded
- `operator reported`: manual result without sufficient preserved evidence
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

Critical evidence conflict: `model-analyzer.txt` reports 2 registered images in `sparse/0`, while `colmap-mapper.log` later reaches 30 registered images. `database_images=30` does not resolve this conflict. The current validator checks `sparse/0` structurally but does not compare sparse models.

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

The current scripts accept a Surveyor scene when all of these exist:

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

Passing this gate does not prove that `sparse/0` is the best reconstruction or that it contains every database image. It is sufficient for packaging, not for declaring Trainer handoff validated.

Packaging evidence:

```text
/workspace/archives/<scene>/<scene>-surveyor-scene.tar.gz
/workspace/archives/<scene>/<scene>-surveyor-scene.tar.gz.sha256
/workspace/archives/<scene>/<scene>-surveyor-evidence.tar.gz
/workspace/archives/<scene>/<scene>-surveyor-evidence.tar.gz.sha256
```

## Pending Validation

- Identify every sparse model generated for `prueba-01` and select the one with the highest registered-image count.
- Normalize the selected model path in the scene contract, manifest, analyzer, and validator.
- Apply the permanent manifest newline correction; the evidence package contains the manually repaired manifest, not proof of the repository fix.
- Repeat a clean real run after those corrections.
- Receive the `runpodctl` exports and verify checksums at the destination.
- Confirm the generated scene passes `train-scene.sh --check <scene>` and a 100-step training run in the Trainer image.

## Known Risks

- SIFT GPU extraction or matching may fail without visible NVIDIA runtime.
- `exhaustive_matcher` scales poorly for larger image sets.
- COLMAP can produce multiple sparse components; v0.1 analyzes and validates `sparse/0` without proving it is the best model.
- The current manifest source can emit literal `\n`; the first run was repaired manually and the permanent correction remains pending.
- Packaging can remain silent during compression; byte-based progress is not implemented.
- Dense reconstruction is intentionally excluded from v0.1.
- Capture quality requirements are not formalized yet.
