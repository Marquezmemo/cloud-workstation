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

The current output shape is a COLMAP sparse reconstruction under:

```text
/workspace/scenes/<scene>/
+-- images/
+-- database.db
+-- sparse/
    +-- 0/
        +-- cameras.bin
        +-- images.bin
        +-- points3D.bin
    +-- possible additional models
+-- surveyor-manifest.json
```

Surveyor selects the sparse model with the highest registered-image count, normalizes it to `sparse/0`, and validates the resulting handoff contract. The Trainer check is:

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
/workspace/incoming/<scene>/source/<archive.zip>
```

Expected output:

```text
/workspace/scenes/<scene>/
├── images/
├── database.db
├── sparse/
│   ├── 0/
│   └── possible additional models
└── surveyor-manifest.json
```

## Commands

Full command reference:

[docs/command-reference.md](docs/command-reference.md)

Validate the image:

```bash
validate-surveyor.sh
```

The image includes pinned `runpodctl v2.5.0` for manual Mac/pod transfers and pinned `gdown 6.1.0` for one-way downloads from temporarily shared Google Drive links. Successful end-to-end transfer still requires preserved evidence.

Download a ZIP from Google Drive and prepare it atomically:

```bash
gdown '<shared-drive-url>' \
  -O /workspace/<scene>.zip
sha256sum /workspace/<scene>.zip
preparar-escena /workspace/<scene>.zip
```

With exactly one ZIP directly under `/workspace`, `preparar-escena` can be invoked without an argument. It verifies and extracts into a temporary directory, ignores macOS metadata, requires at least two supported images, rejects name collisions and existing scenes, and only publishes a complete incoming scene. The downloaded ZIP remains in place and an identical copy is preserved under `source/`.

Do not bake Google credentials or cookies into the image.

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

`runpodctl send` can then export the scene archive, evidence archive, and both checksum files. The first real run confirmed sender-side progress, speed, transferred bytes, and percentage. Receiving and destination checksum verification remain separate evidence requirements.

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

## Real Validation Runs

The first real RunPod run is recorded in [docs/validation-runs/2026-06-27-prueba-01-real-run.md](docs/validation-runs/2026-06-27-prueba-01-real-run.md).

Validated with evidence for `prueba-01`:

- 30 prepared input images and 30 images in `database.db`
- exhaustive matching, GPU enabled, single camera, and `OPENCV`
- COLMAP `3.10-dev`, CUDA `12.3.1`, Ubuntu `22.04`, `gdown 6.1.0`, and `runpodctl 2.5.0-2fac5fb`
- successful ZIP preparation, reconstruction execution, package generation, portable checksums, and `runpodctl send`
- GPU telemetry from an NVIDIA GeForce RTX 4090

Historical limitation: `model-analyzer.txt` reported only 2 registered images in `sparse/0`, while the mapper log later reached 30 registered images in another reconstruction. The scripts used for that run assumed `sparse/0`; therefore its Trainer handoff was not validated.

That limitation is historical. The corrected `Prueba02` run is recorded in [docs/validation-runs/2026-06-29-prueba02-surveyor.md](docs/validation-runs/2026-06-29-prueba02-surveyor.md).

Validated with evidence for `Prueba02`:

- two sparse candidates evaluated automatically
- original model `1` selected with 30 registered images and 4,555 points
- selected model normalized to `sparse/0`
- manifest, model analyzer, and validator agree on 30 registered images
- scene and evidence packages verified
- scene received by Trainer, checksum verified, dataset check passed, and a 300-step training run completed

## Validation Status

Implemented and directly verifiable in the repository:

- COLMAP 3.10/CUDA 12.3.1 base pinned by digest
- pinned `runpodctl v2.5.0` and hashed `gdown 6.1.0` dependency lock
- transactional ZIP preparation with `preparar-escena`
- complete scene validator and validation-before-packaging gate
- portable scene and evidence packages
- default `CMD ["runpod-keepalive.sh"]`

Locally verified on 2026-06-27:

- `bash tests/test-surveyor-contract.sh`
- `bash tests/test-preparar-escena.sh`
- valid scene packaging, negative fixtures, and portable checksum verification

Reported by earlier implementation work without preserved logs:

- `docker build --platform linux/amd64`
- `validate-surveyor.sh`
- `survey-scene.sh --help`
- `package-surveyor-scene.sh --help`

Pending real validation:

- repeat the corrected handoff with additional capture sets
- define capture-quality thresholds and reconstruction-quality acceptance criteria

Known usability gap: packaging may remain silent while compressing. Stage messages and byte-based progress are proposed but not implemented.

## Boundaries

This image intentionally does not include:

- `gsplat`
- Trainer scripts
- dense reconstruction as a default pipeline step
- desktop, display manager, VNC, viewer, Blender, or streaming dependencies

The Eye owns official project documentation. Surveyor findings should be recorded as technical proposals under `docs/proposals/` for review.
