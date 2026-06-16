# Dataset Format

The Phase 5A training path expects a dataset that has already been prepared with COLMAP outside this image.

COLMAP is intentionally not installed in this image yet.

## Expected Scene Layout

```text
/workspace/scenes/<scene>/
├── images/
└── sparse/
    └── 0/
        ├── cameras.bin or cameras.txt
        ├── images.bin or images.txt
        └── points3D.bin or points3D.txt
```

The official `gsplat` COLMAP parser also accepts `sparse/` directly when `sparse/0/` is absent.

## Prepare Skeleton

```bash
prepare-dataset.sh <scene-name>
```

This creates:

```text
/workspace/scenes/<scene>/images
/workspace/scenes/<scene>/sparse/0
```

It does not run COLMAP, copy images, extract frames, or generate reconstruction files.

## Validation

```bash
train-scene.sh --check <scene-name>
```

The check verifies that:

- the scene directory exists
- `images/` exists
- `sparse/0/` or `sparse/` exists
- COLMAP `cameras`, `images`, and `points3D` files exist as `.bin` or `.txt`

## Current Scope

Validated for the first training wrapper:

- COLMAP-prepared datasets
- official `gsplat` `examples/simple_trainer.py`
- headless execution with `--disable_viewer`

Not included yet:

- COLMAP installation
- frame extraction workflow
- dataset conversion pipeline
- quality benchmark
- Nerfstudio comparison
