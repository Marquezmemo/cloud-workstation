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
Generar --scene <scene>
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

`empaquetar` creates a `.tar.gz` and `.sha256` under `/workspace/outputs/<scene>/exports`. No transfer method is configured or validated yet.

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
