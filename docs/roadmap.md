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
- The first real `prueba-01` run validated RunPod startup, 30-image intake, GPU reconstruction execution, packaging, checksums, and `runpodctl send`.
- The `prueba-01` Trainer handoff was blocked because `sparse/0` reported 2 registered images while a later mapper reconstruction reached 30.
- `Prueba02` validated the corrected best-model selection: original model `1`, 30 registered images, 4,555 points, normalized to `sparse/0`.
- The `Prueba02` package was received and checksum-verified by Trainer; dataset validation and a 300-step run completed.

## Immediate Next Steps

1. Repeat the corrected Surveyor flow with additional capture sets.
2. Define registered-image and reconstruction-quality acceptance thresholds.
3. Evaluate OPENCV distortion handling versus an undistorted/PINHOLE handoff.
4. Preserve each run's commands, hashes, logs, manifest, selection report, and Trainer result.

## Later Work

- Decide whether additional capture guidance is needed after real dataset tests.
- Evaluate when `MATCHER=sequential` should become the recommended path.
- Decide if dense reconstruction belongs in a future Surveyor phase.
- Add packaging stage messages and real byte-based progress, preferably with `pv` or equivalent; never display invented percentages.
- Create the future Full image only after Surveyor and Trainer handoff contracts are stable.

## Criteria

Surveyor progress must be evidence-based:

- no desktop, viewer, VNC, Blender, or streaming work
- no `gsplat` or Trainer runtime added back to this branch
- no dense reconstruction as default v0.1 behavior
- every real scene smoke test records logs, manifest, package, checksum, and Trainer handoff result
