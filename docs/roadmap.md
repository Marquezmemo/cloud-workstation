# Roadmap

Roadmap for the headless Surveyor COLMAP image.

## Current Status

- Surveyor branch created: `headless-surveyor-v0.1-dev`.
- Dockerfile uses pinned `colmap/colmap` image digest.
- `validate-surveyor.sh`, `survey-scene.sh`, and `package-surveyor-scene.sh` exist.
- Docker Hub publish workflow exists for `headless-surveyor-v0.1-dev`.
- Trainer and `gsplat` runtime scripts were removed from this branch.
- Local build and local script smoke checks passed according to the Surveyor handoff.

## Immediate Next Steps

1. Run the Surveyor image on RunPod.
2. Execute `validate-surveyor.sh` in the pod.
3. Confirm COLMAP GPU visibility and behavior.
4. Run `survey-scene.sh <scene>` on a real image set.
5. Package the generated scene with `package-surveyor-scene.sh <scene>`.
6. Move the generated scene package to the Trainer workflow.
7. Confirm `train-scene.sh --check <scene>` passes in the Trainer image.
8. Record real RunPod logs, model analyzer output, package path, and checksum.

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
