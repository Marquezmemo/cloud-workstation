# Architecture

`headless-surveyor-v0.2-dev` is the active Surveyor documentation and governance branch.
It continues from the inherited `headless-surveyor-v0.1-dev` headless COLMAP runtime for the pre-training reconstruction phase.
Any v0.1 runtime identifiers still present in image labels, workflow names, or manifest schema describe that unchanged inherited runtime.

Surveyor prepares COLMAP scenes for the Trainer. It is not the Trainer image and does not install `gsplat`.

## Image Role

```text
raw images
|
/workspace/incoming/<scene>/images
|
Surveyor COLMAP sparse reconstruction
|
/workspace/scenes/<scene>/sparse/*
|
automatic best sparse model selection and normalization to sparse/0
|
conditional Trainer validation with train-scene.sh --check <scene>
```

## Runtime Base

The image is based on the pinned official COLMAP image:

```text
colmap/colmap:20240723.601@sha256:73003557e3ffa36d801e71b7630c117f9d373c55f24e3afc6791b9b3d1ec01da
```

This immutable base provides COLMAP 3.10, CUDA 12.3.1, and Ubuntu 22.04. The previous base required CUDA 12.9 and was rejected by the selected RunPod host before container startup.

The default command is `runpod-keepalive.sh`, not the inherited COLMAP entrypoint.

The image installs pinned `runpodctl v2.5.0` with build-time checksum verification for manual Mac/pod transfers.

The image installs `gdown 6.1.0` and all transitive Python dependencies from a hashed lock. `gdown` is limited to one-way downloads from temporarily shared links; it does not replace `runpodctl` for output transfer.

## Workspace Contract

```text
/workspace/incoming/<scene>/images
/workspace/incoming/<scene>/source/<archive.zip>
/workspace/scenes/<scene>
/workspace/logs/<scene>
/workspace/archives/<scene>
/workspace/temp
```

`/workspace/incoming/<scene>/images` is the source image directory.

`preparar-escena` validates a ZIP in temporary storage, flattens supported images without collisions, and atomically creates both `images/` and the preserved ZIP under `source/`. It never writes to `/workspace/scenes`.

`/workspace/scenes/<scene>` is the Trainer handoff. COLMAP may write multiple sparse models; Surveyor analyzes every candidate, selects by registered-image count, point count, and original index, then normalizes the winner to `sparse/0`.

`/workspace/logs/<scene>` contains Surveyor/COLMAP logs and summaries.

`/workspace/archives/<scene>` contains packaged scene archives and checksums.

`validate-surveyor-scene.sh <scene>` validates the normalized `sparse/0` files and checks manifest consistency for registered-image count, sparse-model count, and selected original index.

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
    +-- possible additional models
+-- surveyor-manifest.json
```

The historical `prueba-01` run demonstrated the original contract gap. `Prueba02` validated the correction by selecting original model `1` with 30 registered images and normalizing it to `sparse/0`.

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

`COLMAP_USE_GPU=1` is the default and requires a visible NVIDIA GPU before reconstruction starts. Surveyor records one-second GPU utilization and memory samples during feature extraction and matching. `COLMAP_USE_GPU=0` remains available for diagnostics, but it is not accepted for the first real smoke test.

## Boundaries

Surveyor does not include:

- `gsplat`
- Trainer scripts
- dense reconstruction as a default inherited runtime pipeline step
- PLY export
- desktop, display manager, VNC, viewer, Blender, or streaming dependencies
