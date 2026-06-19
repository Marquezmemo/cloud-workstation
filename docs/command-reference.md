# Command Reference

Operator command reference for `headless-surveyor-v0.1-dev`.

## Validate Image

```bash
validate-surveyor.sh
```

This checks required commands, COLMAP help, optional `nvidia-smi`, and writable workspace paths.

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

## Run Sparse Reconstruction

Default exhaustive matching with GPU enabled:

```bash
survey-scene.sh room
```

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

```bash
package-surveyor-scene.sh room
```

Expected outputs:

```text
/workspace/archives/room/room-surveyor-scene.tar.gz
/workspace/archives/room/room-surveyor-scene.tar.gz.sha256
```

## Verify Package Checksum

```bash
cd /workspace/archives/room
sha256sum -c room-surveyor-scene.tar.gz.sha256
```

## Trainer Handoff

After the packaged scene is transferred and unpacked into the Trainer workspace, validate it from the Trainer image:

```bash
train-scene.sh --check room
```

`train-scene.sh` is not included in the Surveyor image.

## Full Smoke Sequence

```bash
validate-surveyor.sh
survey-scene.sh room
package-surveyor-scene.sh room
cd /workspace/archives/room
sha256sum -c room-surveyor-scene.tar.gz.sha256
```

Run this final command in the Trainer image after handoff:

```bash
train-scene.sh --check room
```
