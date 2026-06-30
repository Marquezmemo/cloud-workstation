# Command Reference

Operator command reference for `headless-surveyor-v0.1-dev`.

## Validate Image

```bash
validate-surveyor.sh
```

This checks COLMAP 3.10/CUDA 12.3.1, required COLMAP commands and SIFT flags, pinned `gdown` and `runpodctl`, optional `nvidia-smi`, and writable workspace paths.

Confirm the transfer client directly:

```bash
runpodctl version
gdown --version
```

## Prepare Input Images

Place source images under:

```text
/workspace/incoming/<scene>/images
```

Example:

```bash
mkdir -p /workspace/incoming/room/images
```

Copy image files into that directory before running Surveyor.

### Download and prepare a shared Drive ZIP

Create a ZIP containing at least two supported images, record its SHA-256 before uploading it to Drive, and temporarily enable link-based read access. Images may be nested inside the ZIP. In the pod:

```bash
gdown '<shared-drive-url>' \
  -O /workspace/room.zip
sha256sum /workspace/room.zip
preparar-escena /workspace/room.zip
```

When exactly one ZIP exists directly under `/workspace`, this is also valid:

```bash
preparar-escena
```

The command derives `room` from `room.zip` and creates:

```text
/workspace/incoming/room/
+-- images/
+-- source/
    +-- room.zip
```

It recursively finds supported images and places them directly under `images/`. It ignores `__MACOSX`, `.DS_Store`, and `._*`; rejects corrupt or unsafe ZIPs, fewer than two images, flattened-name collisions, and existing incoming or processed scenes. Failures leave the original ZIP unchanged and do not leave a partial destination. The original downloaded ZIP is also retained after success.

Compare the downloaded SHA-256 with the source value before preparation. Do not store Drive URLs, cookies, or credentials in Git. `gdown` does not upload results.

## Run Sparse Reconstruction

Default exhaustive matching with GPU enabled:

```bash
COLMAP_USE_GPU=1 survey-scene.sh room
```

GPU mode fails before reconstruction when NVIDIA is not visible and writes utilization evidence to `/workspace/logs/room/surveyor-gpu.log`.

CPU fallback:

```bash
COLMAP_USE_GPU=0 survey-scene.sh room
```

Sequential matcher:

```bash
MATCHER=sequential survey-scene.sh room
```

Overwrite an existing scene intentionally:

```bash
OVERWRITE=true survey-scene.sh room
```

Optional image-size limit:

```bash
MAX_IMAGE_SIZE=1600 survey-scene.sh room
```

## Expected Output

```text
/workspace/scenes/room/
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

COLMAP may create more than one numeric subdirectory under `sparse/`. Surveyor analyzes all candidates, selects the best one, and normalizes it to `sparse/0`. Inspect `sparse-selection.txt` to audit the decision.

## Inspect Logs

```bash
ls -lah /workspace/logs/room
cat /workspace/logs/room/surveyor.summary
cat /workspace/logs/room/model-analyzer.txt
```

Inspect the selection evidence and normalized model:

```bash
cat /workspace/logs/room/sparse-selection.txt
colmap model_analyzer --path /workspace/scenes/room/sparse/0
```

Key logs:

```text
/workspace/logs/<scene>/colmap-feature.log
/workspace/logs/<scene>/colmap-match.log
/workspace/logs/<scene>/colmap-mapper.log
/workspace/logs/<scene>/model-analyzer.txt
```

## Package Scene

Validate the complete scene first:

```bash
validate-surveyor-scene.sh room
```

This validates the normalized `sparse/0`, database, manifest, logs, and sparse-selection metrics.

```bash
package-surveyor-scene.sh room
```

Expected outputs:

```text
/workspace/archives/room/room-surveyor-scene.tar.gz
/workspace/archives/room/room-surveyor-scene.tar.gz.sha256
/workspace/archives/room/room-surveyor-evidence.tar.gz
/workspace/archives/room/room-surveyor-evidence.tar.gz.sha256
```

## Verify Package Checksum

```bash
cd /workspace/archives/room
sha256sum -c room-surveyor-scene.tar.gz.sha256
sha256sum -c room-surveyor-evidence.tar.gz.sha256
```

## Transfer With runpodctl

Mac to pod: run `runpodctl send <input-archive>` on the Mac, then run `runpodctl receive <transfer-code>` from `/workspace/incoming/<scene>` in the Surveyor pod. Record and compare the archive SHA-256 at both ends before extraction.

Pod to Trainer or Mac: send each scene/evidence archive and its `.sha256` file from the Surveyor pod, receive it at the destination, then run `sha256sum -c` beside the received archive.

`Prueba02` validated sender-side transfer, Trainer receipt, and destination checksum verification. Record direction, command shape, file size, hashes at both ends, duration, result, and any retry. Do not store credentials or ephemeral transfer codes in Git.

For a completed Surveyor scene:

```bash
runpodctl send /workspace/archives/room/room-surveyor-scene.tar.gz
runpodctl send /workspace/archives/room/room-surveyor-scene.tar.gz.sha256
runpodctl send /workspace/archives/room/room-surveyor-evidence.tar.gz
runpodctl send /workspace/archives/room/room-surveyor-evidence.tar.gz.sha256
```

## Trainer Handoff

After transfer and unpacking in Trainer, run:

```bash
train-scene.sh --check room
MAX_STEPS=100 train-scene.sh room
```

`train-scene.sh` is not included in the Surveyor image.

## Full Smoke Sequence

The historical `prueba-01` run required manual manifest repair. Current Surveyor generates valid JSON and normalizes the selected sparse model automatically.

```bash
cd /workspace
validate-surveyor.sh
gdown 'URL_DE_GOOGLE_DRIVE' -O prueba-01.zip
preparar-escena /workspace/prueba-01.zip
survey-scene.sh prueba-01
validate-surveyor-scene.sh prueba-01
package-surveyor-scene.sh prueba-01
cd /workspace/archives/prueba-01
sha256sum -c prueba-01-surveyor-scene.tar.gz.sha256
sha256sum -c prueba-01-surveyor-evidence.tar.gz.sha256
runpodctl send /workspace/archives/prueba-01/prueba-01-surveyor-scene.tar.gz
runpodctl send /workspace/archives/prueba-01/prueba-01-surveyor-scene.tar.gz.sha256
runpodctl send /workspace/archives/prueba-01/prueba-01-surveyor-evidence.tar.gz
runpodctl send /workspace/archives/prueba-01/prueba-01-surveyor-evidence.tar.gz.sha256
```

Run the Trainer commands only after best-model selection is resolved:

```bash
train-scene.sh --check room
MAX_STEPS=100 train-scene.sh room
```

## Troubleshooting

### Historical manifest rejection

`prueba-01` produced a manifest ending in literal `\n`; commit `8409125` corrected manifest generation. If current validation reports invalid JSON, preserve the artifact as a regression rather than applying the old manual repair.

### Mapper reaches more images than model-analyzer

`database_images=30` means the database contains 30 images; it does not by itself prove registration. Current validation also reports `registered_images` and sparse-selection metadata. `Prueba02` validated 30 database and 30 registered images.

### Packaging appears idle

Compression may take seconds or minutes without output. Final files and checksums are still printed when it completes. Stage messages and byte-based progress, preferably using `pv` or equivalent real byte counts, are proposed but not implemented. Do not infer a percentage without measured bytes.
