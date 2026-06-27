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
3. pod/GPU, NVIDIA driver, CUDA, COLMAP, and `runpodctl` versions
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
colmap/colmap@sha256:187ca5ec98e55ed8fbec5f43f9d8f78b7a322b3b7413356634191f7a43c1efcf
```

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

Implemented and directly verifiable: the default `CMD` starts `runpod-keepalive.sh`, not the inherited COLMAP entrypoint.

## Current Validation Commands

Validate image tools and workspace paths:

```bash
validate-surveyor.sh
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

## Minimum Successful Scene Evidence

A Surveyor scene is minimally valid when all of these exist:

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

Packaging evidence:

```text
/workspace/archives/<scene>/<scene>-surveyor-scene.tar.gz
/workspace/archives/<scene>/<scene>-surveyor-scene.tar.gz.sha256
/workspace/archives/<scene>/<scene>-surveyor-evidence.tar.gz
/workspace/archives/<scene>/<scene>-surveyor-evidence.tar.gz.sha256
```

## Pending RunPod Validation

- Start `headless-surveyor-v0.1-dev` on RunPod.
- Confirm `validate-surveyor.sh` passes on RunPod.
- Confirm COLMAP sees expected GPU/runtime state.
- Run `survey-scene.sh <scene>` against a real image set.
- Confirm `COLMAP_USE_GPU=1` behavior.
- Confirm `surveyor-gpu.log` records GPU utilization or memory activity during feature extraction or matching.
- Confirm package archive and checksum on a real scene.
- Transfer with `runpodctl` and record exact commands and hashes.
- Confirm the generated scene passes `train-scene.sh --check <scene>` and a 100-step training run in the Trainer image.

## Known Risks

- The official COLMAP image still needs RunPod GPU validation.
- SIFT GPU extraction or matching may fail without visible NVIDIA runtime.
- `exhaustive_matcher` scales poorly for larger image sets.
- COLMAP may produce multiple sparse components; v0.1 expects `sparse/0`.
- Dense reconstruction is intentionally excluded from v0.1.
- Capture quality requirements are not formalized yet.
