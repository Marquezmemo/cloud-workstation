# Architecture

`headless-surveyor-v0.1-dev` is the headless COLMAP image line for the pre-training reconstruction phase.

Surveyor prepares COLMAP scenes for the Trainer. It is not the Trainer image and does not install `gsplat`.

## Image Role

```text
raw images
|
/workspace/incoming/<scene>/images
|
Surveyor COLMAP sparse reconstruction
|
/workspace/scenes/<scene>
|
Trainer validation with train-scene.sh --check <scene>
```

## Runtime Base

The image is based on the pinned official COLMAP image:

```text
colmap/colmap@sha256:187ca5ec98e55ed8fbec5f43f9d8f78b7a322b3b7413356634191f7a43c1efcf
```

The default command is `runpod-keepalive.sh`, not the inherited COLMAP entrypoint.

## Workspace Contract

```text
/workspace/incoming/<scene>/images
/workspace/scenes/<scene>
/workspace/logs/<scene>
/workspace/archives/<scene>
/workspace/temp
```

`/workspace/incoming/<scene>/images` is the source image directory.

`/workspace/scenes/<scene>` is the Trainer-ready scene output.

`/workspace/logs/<scene>` contains Surveyor/COLMAP logs and summaries.

`/workspace/archives/<scene>` contains packaged scene archives and checksums.

## Surveyor To Trainer Contract

The generated scene must include:

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

The Trainer handoff check is:

```bash
train-scene.sh --check <scene>
```

That check runs in the Trainer image, not in Surveyor.

## COLMAP Pipeline

`survey-scene.sh <scene>` runs:

```text
colmap feature_extractor
colmap exhaustive_matcher or sequential_matcher
colmap mapper
colmap model_analyzer
```

`MATCHER=exhaustive` is the default. `MATCHER=sequential` is available for video-like capture sets.

`COLMAP_USE_GPU=1` is the default. `COLMAP_USE_GPU=0` is the documented fallback when GPU visibility or SIFT GPU behavior fails.

## Boundaries

Surveyor does not include:

- `gsplat`
- Trainer scripts
- dense reconstruction as a default v0.1 pipeline step
- PLY export
- desktop, display manager, VNC, viewer, Blender, or streaming dependencies
