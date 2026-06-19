# Dataset Format

Surveyor converts input images into a COLMAP sparse scene that the Trainer can validate.

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

The script only reads files directly under `images/`; nested image folders are not part of v0.1.

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
+-- surveyor-manifest.json
```

This output is the handoff contract for the Trainer.

## Logs

Surveyor writes reconstruction evidence under:

```text
/workspace/logs/<scene>/
+-- surveyor.env
+-- colmap-feature.log
+-- colmap-match.log
+-- colmap-mapper.log
+-- model-analyzer.txt
+-- surveyor.summary
```

## Packaging

`package-surveyor-scene.sh <scene>` writes:

```text
/workspace/archives/<scene>/<scene>-surveyor-scene.tar.gz
/workspace/archives/<scene>/<scene>-surveyor-scene.tar.gz.sha256
```

## Trainer Handoff

After moving or unpacking the scene into the Trainer workspace, the expected handoff check is:

```bash
train-scene.sh --check <scene>
```

That command is not available in the Surveyor image.

## Current Limits

- Surveyor v0.1 accepts only the first sparse component at `sparse/0`.
- Dense reconstruction is not part of the default v0.1 output.
- Frame extraction from video is not implemented.
- Automatic ZIP unpacking is not implemented.
- Capture quality rules are pending real dataset validation.
