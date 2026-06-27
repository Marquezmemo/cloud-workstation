# Training Workflow

Phase 5A adopts the official `gsplat` example trainer instead of creating a custom trainer.

Official source:

```text
repo: https://github.com/nerfstudio-project/gsplat
tag: v1.5.3
commit: 937e29912570c372bed6747a5c9bf85fed877bae
trainer: /opt/gsplat/examples/simple_trainer.py
```

The image installs the official repository under `/opt/gsplat` and runs the example in headless mode.
The examples are pinned to the same release line as `gsplat==1.5.3` to avoid trainer/runtime API drift.

A small build-time patch removes the official example's top-level viewer imports. This keeps the backend based on the official trainer while avoiding `nerfview`, `viser`, `splines`, desktop, or virtual monitor dependencies.

## Backend Contract

The wrapper remains backend-configurable through explicit paths and variables:

- `SCENE_NAME`
- `SCENE_PATH`
- `OUTPUT_PATH`
- `CHECKPOINT_PATH`
- `LOG_PATH`
- `MAX_STEPS`
- `TRAINER_CONFIG`
- `DISABLE_VIEWER=true`

Default paths:

```text
SCENE_PATH=/workspace/scenes/<scene>
OUTPUT_PATH=/workspace/outputs/<scene>
CHECKPOINT_PATH=/workspace/checkpoints/<scene>
LOG_PATH=/workspace/logs/<scene>/train.log
```

`CHECKPOINT_PATH` is a symlink to the official trainer checkpoint directory under:

```text
/workspace/outputs/<scene>/ckpts
```

## Commands

Complete command syntax is maintained in [command-reference.md](command-reference.md).

Create a dataset skeleton:

```bash
prepare-dataset.sh <scene-name>
```

Validate paths without training:

```bash
train-scene.sh --check <scene-name>
```

Run a short training command:

```bash
MAX_STEPS=100 train-scene.sh <scene-name>
```

Supported run depths include:

```bash
MAX_STEPS=100 train-scene.sh room
MAX_STEPS=1000 train-scene.sh room
MAX_STEPS=10000 train-scene.sh room
```

Only the 100-step run is part of the next evidence-backed smoke test. Longer runs must not be described as validated without their logs and artifacts.

Scenes are trained individually. The wrapper does not train every scene automatically:

```bash
MAX_STEPS=100 train-scene.sh bonsai
MAX_STEPS=1000 train-scene.sh room
MAX_STEPS=10000 train-scene.sh truck
```

Pass additional official trainer flags after `--`:

```bash
MAX_STEPS=100 train-scene.sh <scene-name> -- --data_factor 2 --test_every 12
```

## Logs

Each run writes:

```text
/workspace/logs/<scene>/train.log
/workspace/logs/<scene>/run.env
/workspace/logs/<scene>/run.summary
/workspace/logs/<scene>/error.tail
```

`error.tail` is written only when the trainer exits with an error.

## PLY Export After Training

The official trainer can save checkpoints without writing a `.ply` unless PLY export is requested during training. For existing checkpoints, use:

```bash
generar --scene <scene>
```

Default outputs:

```text
/workspace/outputs/<scene>/exports/<scene>.ply
/workspace/outputs/<scene>/exports/<scene>.compressed.ply
```

The export command uses `gsplat.export_splats` and runs on CPU by default. It does not upload files or start a pipeline.

Package exports for manual transfer:

```bash
empaquetar <scene>
```

Alias:

```bash
comprimir <scene>
```

`empaquetar` creates a `.tar.gz` and `.sha256` under `/workspace/outputs/<scene>/exports`. It does not transfer files.

Package existing scene logs for review:

```bash
empaquetar-logs <scene>
```

The log package excludes datasets, checkpoints, and PLY files. It can include optional scene-scoped GPU telemetry only when that telemetry already exists.

## Transfer After Packaging

`runpodctl v2.5.0` is installed in the image from the official GitHub release with checksum verification during build. The transfer path still needs end-to-end smoke testing against the active RunPod pod and the receiving Mac.

Pod-to-Mac command shape:

```bash
runpodctl send /workspace/outputs/room/exports/room-ply-exports.tar.gz
runpodctl send /workspace/outputs/room/exports/room-ply-exports.tar.gz.sha256
runpodctl receive <transfer-code>
```

The checksum written by `empaquetar` currently contains an absolute pod path. After download, calculate the received archive hash and compare the digest manually. `empaquetar-logs` writes a portable relative checksum.

## Full Manual Flow

Use [command-reference.md](command-reference.md) for the complete one-scene and multi-scene command sequences.

## Headless Mode

The wrapper always passes:

```text
--disable_viewer
```

The upstream trainer includes viewer support, but this image removes viewer imports at build time. The wrapper still passes `--disable_viewer` and rejects `DISABLE_VIEWER=false`.

## Current Limits

This phase does not include:

- custom trainer implementation
- long training validation
- quality benchmark
- Nerfstudio
- COLMAP installation
- viewer workflow
- desktop environment
