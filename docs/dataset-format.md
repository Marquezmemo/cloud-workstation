# Dataset Format

Surveyor converts input images into one or more COLMAP sparse models, selects the best candidate, and normalizes it for Trainer.

## Input Layout

Place images under:

```text
/workspace/incoming/<scene>/images
```

Supported image extensions in `survey-scene.sh`:

```text
.jpg
.jpeg
.png
.tif
.tiff
```

The script only reads files directly under `images/`; nested image folders are not part of the inherited runtime contract.

`preparar-escena [archivo.zip]` bridges nested ZIP input into this flat contract. It derives the scene name from the ZIP filename, recursively selects only the supported extensions, rejects case-insensitive basename collisions, and atomically writes:

```text
/workspace/incoming/<scene>/
+-- images/
+-- source/
    +-- <scene>.zip
```

The input ZIP remains at its original path. Existing incoming or processed scenes are never overwritten.

## Output Layout

Surveyor writes:

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

The normalized best model is always placed at `sparse/0`. The manifest records the total model count, original selected index, registered-image count, and normalized Trainer path.

## Logs

Surveyor writes reconstruction evidence under:

```text
/workspace/logs/<scene>/
+-- surveyor.env
+-- colmap-feature.log
+-- colmap-match.log
+-- colmap-mapper.log
+-- model-analyzer.txt
+-- surveyor-gpu.log          # required when COLMAP_USE_GPU=1
+-- surveyor.summary
```

## Packaging

`package-surveyor-scene.sh <scene>` writes:

```text
/workspace/archives/<scene>/<scene>-surveyor-scene.tar.gz
/workspace/archives/<scene>/<scene>-surveyor-scene.tar.gz.sha256
/workspace/archives/<scene>/<scene>-surveyor-evidence.tar.gz
/workspace/archives/<scene>/<scene>-surveyor-evidence.tar.gz.sha256
```

The scene package contains the normalized Trainer handoff. The evidence package contains the manifest, reconstruction logs, and sparse-selection report. Checksum records use relative file names so they remain valid after transfer.

## Trainer Handoff

After moving or unpacking the scene into the Trainer workspace, run:

```bash
train-scene.sh --check <scene>
MAX_STEPS=100 train-scene.sh <scene>
```

Those commands are not available in the Surveyor image. The 100-step run is required because the path-only check does not prove that the Trainer can parse and consume the dataset.

## Current Limits

- Best-model selection optimizes registration count and point count; it does not itself define a quality threshold.
- Dense reconstruction is not part of the default inherited runtime output.
- Frame extraction from video is not implemented.
- ZIP preparation is implemented through `preparar-escena`; automatic download is not part of that command.
- Capture quality rules are pending real dataset validation.
