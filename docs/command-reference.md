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

### Download a shared Drive archive

Create an archive whose top-level entry is `images/`, record its SHA-256 before uploading it to Drive, and temporarily enable link-based read access. In the pod:

```bash
mkdir -p /workspace/incoming/room
gdown '<shared-drive-url>' \
  -O /workspace/incoming/room/room-input.tar.gz
sha256sum /workspace/incoming/room/room-input.tar.gz
tar -xzf /workspace/incoming/room/room-input.tar.gz \
  -C /workspace/incoming/room
```

Compare the downloaded SHA-256 with the source value before extraction. Do not store Drive URLs, cookies, or credentials in Git. `gdown` does not upload results.

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
+-- surveyor-manifest.json
```

## Inspect Logs

```bash
ls -lah /workspace/logs/room
cat /workspace/logs/room/surveyor.summary
cat /workspace/logs/room/model-analyzer.txt
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

`runpodctl` installation is implemented, but transfer behavior is pending evidence-backed validation. Record direction, exact command shape, file size, hashes at both ends, duration, result, and any retry. Do not store credentials or ephemeral transfer codes in Git.

## Trainer Handoff

After the packaged scene is transferred and unpacked into the Trainer workspace, validate it from the Trainer image:

```bash
train-scene.sh --check room
MAX_STEPS=100 train-scene.sh room
```

`train-scene.sh` is not included in the Surveyor image.

## Full Smoke Sequence

```bash
validate-surveyor.sh
COLMAP_USE_GPU=1 survey-scene.sh room
validate-surveyor-scene.sh room
package-surveyor-scene.sh room
cd /workspace/archives/room
sha256sum -c room-surveyor-scene.tar.gz.sha256
sha256sum -c room-surveyor-evidence.tar.gz.sha256
```

Run this final command in the Trainer image after handoff:

```bash
train-scene.sh --check room
MAX_STEPS=100 train-scene.sh room
```
