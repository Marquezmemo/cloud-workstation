# Validation

Validation record for `headless-surveyor-v0.1-dev`.

This branch is the Surveyor COLMAP image line. Trainer and `gsplat` validation records belong to the Trainer branch and are not active validation evidence for this image.

## Image Under Validation

```text
docker.io/${DOCKERHUB_USERNAME}/cloud-workstation:headless-surveyor-v0.1-dev
```

Base image:

```text
colmap/colmap@sha256:187ca5ec98e55ed8fbec5f43f9d8f78b7a322b3b7413356634191f7a43c1efcf
```

## Local Validation Completed

The Surveyor implementation report states that these local checks passed:

- `docker build --platform linux/amd64` completed successfully.
- `validate-surveyor.sh` passed inside the container.
- `survey-scene.sh --help` works.
- `package-surveyor-scene.sh --help` works.
- `package-surveyor-scene.sh` packaged a synthetic scene and generated a checksum.
- The default `CMD` starts `runpod-keepalive.sh`, not the inherited COLMAP entrypoint.

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
/workspace/logs/<scene>/surveyor.summary
```

Packaging evidence:

```text
/workspace/archives/<scene>/<scene>-surveyor-scene.tar.gz
/workspace/archives/<scene>/<scene>-surveyor-scene.tar.gz.sha256
```

## Pending RunPod Validation

- Start `headless-surveyor-v0.1-dev` on RunPod.
- Confirm `validate-surveyor.sh` passes on RunPod.
- Confirm COLMAP sees expected GPU/runtime state.
- Run `survey-scene.sh <scene>` against a real image set.
- Confirm `COLMAP_USE_GPU=1` behavior.
- If GPU mode fails, confirm `COLMAP_USE_GPU=0` fallback.
- Confirm `MATCHER=sequential` on a video-like capture set.
- Confirm package archive and checksum on a real scene.
- Confirm the generated scene passes `train-scene.sh --check <scene>` in the Trainer image.

## Known Risks

- The official COLMAP image still needs RunPod GPU validation.
- SIFT GPU extraction or matching may fail without visible NVIDIA runtime.
- `exhaustive_matcher` scales poorly for larger image sets.
- COLMAP may produce multiple sparse components; v0.1 expects `sparse/0`.
- Dense reconstruction is intentionally excluded from v0.1.
- Capture quality requirements are not formalized yet.
