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

Run a minimal sparse reconstruction:

```bash
survey-scene.sh <scene>
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

Validated locally:

- `docker build --platform linux/amd64`
- `validate-surveyor.sh`
- `survey-scene.sh --help`
- `package-surveyor-scene.sh --help`
- synthetic scene packaging with checksum
- default `CMD ["runpod-keepalive.sh"]`

Pending real validation:

- RunPod smoke test with real images
- COLMAP GPU visibility on RunPod
- real sparse reconstruction under `/workspace/scenes/<scene>/sparse/0`
- package and checksum for a real scene
- Trainer acceptance with `train-scene.sh --check <scene>`

## Boundaries

This image intentionally does not include:

- `gsplat`
- Trainer scripts
- dense reconstruction as a default pipeline step
- desktop, display manager, VNC, viewer, Blender, or streaming dependencies

The Eye owns official project documentation. Surveyor findings should be recorded as technical proposals under `docs/proposals/` for review.
