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
- Trainer handoff remains blocked because `sparse/0` reports 2 registered images while a later mapper reconstruction reaches 30.

## Immediate Next Steps

1. Enumerate and analyze every `sparse/*` model from the first real run.
2. Define and implement the best-model selection rule outside this documentation update.
3. Normalize the selected sparse path across output, manifest, validation, and packaging contracts.
4. Permanently correct manifest newline generation and repeat a clean real run.
5. Receive exported packages and verify their checksums at the destination.
6. Complete `train-scene.sh --check <scene>` and a 100-step training run only after model selection is resolved.
7. Preserve the resulting commands, hashes, logs, manifests, and summaries for The Eye.

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
