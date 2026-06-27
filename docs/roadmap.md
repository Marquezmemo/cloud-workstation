# Roadmap

Roadmap for the headless Surveyor COLMAP image.

## Current Status

- Surveyor branch created: `headless-surveyor-v0.1-dev`.
- Dockerfile uses a pinned COLMAP 3.10/CUDA 12.3.1 image digest.
- `validate-surveyor.sh`, `survey-scene.sh`, and `package-surveyor-scene.sh` exist.
- Docker Hub publish workflow exists for `headless-surveyor-v0.1-dev`.
- Pinned `runpodctl v2.5.0`, hashed `gdown 6.1.0`, and complete scene/evidence validation are implemented.
- Trainer and `gsplat` runtime scripts were removed from this branch.
- Synthetic contract tests are locally verified. Earlier image-build and container checks remain operator-reported because their logs were not preserved.

## Immediate Next Steps

1. Publish the COLMAP 3.10/CUDA 12.3.1 Surveyor image after its workflow gates pass.
2. Confirm the image starts on RunPod and record pod/GPU/driver/image fingerprints.
3. Download a shared-link input archive with `gdown` or transfer it with `runpodctl`; verify SHA-256 before extraction.
4. Execute `validate-surveyor.sh` and confirm NVIDIA visibility.
5. Run `COLMAP_USE_GPU=1 survey-scene.sh <scene>` on 20–30 real images.
6. Confirm GPU activity and inspect `model-analyzer.txt` without imposing quality thresholds yet.
7. Validate and package the scene and evidence.
8. Transfer the scene package to Trainer and verify its checksum.
9. Complete `train-scene.sh --check <scene>` and a 100-step training run.
10. Complete The Eye questionnaire and preserve commands, hashes, logs, manifests, and summaries.

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
