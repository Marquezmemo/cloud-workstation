# cloud-workstation Surveyor

Headless COLMAP image for the photogrammetry reconstruction phase before Gaussian Splatting training.

Active branch:

```text
headless-surveyor-v0.1-dev
```

Published development image target:

```text
docker.io/${DOCKERHUB_USERNAME}/cloud-workstation:headless-surveyor-v0.1-dev
```

## Role

Surveyor prepares datasets for the Trainer. It is not the Trainer image and does not install `gsplat`.

The first contract is a COLMAP sparse reconstruction under:

```text
/workspace/scenes/<scene>/
+-- images/
+-- database.db
+-- sparse/
    +-- 0/
        +-- cameras.bin
        +-- images.bin
        +-- points3D.bin
+-- surveyor-manifest.json
```

The Trainer should be able to validate the generated scene with:

```bash
train-scene.sh --check <scene>
```

## Workspace

```text
/workspace/incoming
/workspace/scenes
/workspace/logs
/workspace/archives
/workspace/temp
```

Expected input:

```text
/workspace/incoming/<scene>/images
```

Expected output:

```text
/workspace/scenes/<scene>
```

## Commands

Full command reference:

[docs/command-reference.md](docs/command-reference.md)

Validate the image:

```bash
validate-surveyor.sh
```

The image includes pinned `runpodctl v2.5.0` for manual Mac/pod transfers and pinned `gdown 6.1.0` for one-way downloads from temporarily shared Google Drive links. Successful end-to-end transfer still requires preserved evidence.

Download a prepared input archive from Google Drive:

```bash
mkdir -p /workspace/incoming/<scene>
gdown '<shared-drive-url>' \
  -O /workspace/incoming/<scene>/<scene>-input.tar.gz
```

Verify its SHA-256 before extracting it. Do not bake Google credentials or cookies into the image.

Run a minimal sparse reconstruction:

```bash
survey-scene.sh <scene>
```

Validate a completed scene contract:

```bash
validate-surveyor-scene.sh <scene>
```

Useful overrides:

```bash
COLMAP_USE_GPU=0 survey-scene.sh <scene>
MATCHER=sequential survey-scene.sh <scene>
OVERWRITE=true survey-scene.sh <scene>
```

Package a reconstructed scene:

```bash
package-surveyor-scene.sh <scene>
```

Packaging produces separate scene and evidence archives with portable SHA-256 records.

## Build

```bash
docker build --platform linux/amd64 \
  -t cloud-workstation:headless-surveyor-v0.1-dev .
```

Local validation:

```bash
docker run --rm --platform linux/amd64 \
  cloud-workstation:headless-surveyor-v0.1-dev \
  validate-surveyor.sh
```

## Validation Status

Implemented and directly verifiable in the repository:

- COLMAP 3.10/CUDA 12.3.1 base pinned by digest
- pinned `runpodctl v2.5.0` and hashed `gdown 6.1.0` dependency lock
- complete scene validator and validation-before-packaging gate
- portable scene and evidence packages
- default `CMD ["runpod-keepalive.sh"]`

Locally verified on 2026-06-27:

- `bash tests/test-surveyor-contract.sh`
- valid scene packaging, negative fixtures, and portable checksum verification

Reported by earlier implementation work without preserved logs:

- `docker build --platform linux/amd64`
- `validate-surveyor.sh`
- `survey-scene.sh --help`
- `package-surveyor-scene.sh --help`

Pending real validation:

- RunPod startup compatibility with the COLMAP 3.10/CUDA 12.3.1 image
- one shared-link `gdown` download with checksum evidence
- RunPod smoke test with real images
- COLMAP GPU visibility on RunPod
- real sparse reconstruction under `/workspace/scenes/<scene>/sparse/0`
- package and checksum for a real scene
- proof of GPU activity during COLMAP feature extraction or matching
- Trainer acceptance plus a real 100-step training run

## Boundaries

This image intentionally does not include:

- `gsplat`
- Trainer scripts
- dense reconstruction as a default pipeline step
- desktop, display manager, VNC, viewer, Blender, or streaming dependencies

The Eye owns official project documentation. Surveyor findings should be recorded as technical proposals under `docs/proposals/` for review.
