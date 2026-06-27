# Roadmap

Roadmap for the headless Surveyor COLMAP image.

## Current Status

- Surveyor branch created: `headless-surveyor-v0.1-dev`.
- Dockerfile uses pinned `colmap/colmap` image digest.
- `validate-surveyor.sh`, `survey-scene.sh`, and `package-surveyor-scene.sh` exist.
- Docker Hub publish workflow exists for `headless-surveyor-v0.1-dev`.
- Pinned `runpodctl v2.5.0` and complete scene/evidence validation are implemented.
- Trainer and `gsplat` runtime scripts were removed from this branch.
- Local build and local script smoke checks passed according to the Surveyor handoff.

## Immediate Next Steps

1. Publish the validated Surveyor image.
2. Transfer 20–30 real images to RunPod with `runpodctl`.
3. Execute `validate-surveyor.sh` and confirm NVIDIA visibility.
4. Run `COLMAP_USE_GPU=1 survey-scene.sh <scene>`.
5. Confirm GPU activity and inspect `model-analyzer.txt` without imposing quality thresholds yet.
6. Validate and package the scene and evidence.
7. Transfer the scene package to Trainer and verify its checksum.
8. Complete `train-scene.sh --check <scene>` and a 100-step training run.
9. Preserve all transfer commands, hashes, logs, manifests, and summaries for The Eye.

## Later Work

- Decide whether additional capture guidance is needed after real dataset tests.
- Evaluate when `MATCHER=sequential` should become the recommended path.
- Decide if dense reconstruction belongs in a future Surveyor phase.
- Create the future Full image only after Surveyor and Trainer handoff contracts are stable.

## Criteria

Surveyor progress must be evidence-based:

- no desktop, viewer, VNC, Blender, or streaming work
- no `gsplat` or Trainer runtime added back to this branch
- no dense reconstruction as default v0.1 behavior
- every real scene smoke test records logs, manifest, package, checksum, and Trainer handoff result
