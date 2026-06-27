# Roadmap

Roadmap for the headless Gaussian Splatting pipeline.

1. Audit pivot from remote workstation to headless training
2. Clean active image target and create persistent workspace layout
3. Add headless CUDA/PyTorch system dependencies
4. Add GPU validation, training diagnostics, and minimal pinned `gsplat` import validation
5. Add backend-configurable `gsplat` training workflow using the official simple trainer
6. Validate a minimal training run with persistent logs and outputs
7. Validate PLY generation, packaging, checksum, and transfer
8. Freeze a reproducible Trainer baseline
9. Stabilize the handoff with the existing Surveyor branch/image
10. Create the Full image after COLMAP and Trainer contracts are stable
11. Optionally create a future Nerfstudio/Splatfacto benchmark branch

## Current Status

- Phase 1 complete: pivot audit documented.
- Phase 2 complete: headless cleanup and persistent `/workspace` structure.
- Phase 3 complete: minimal headless tooling and GPU validation script.
- Phase 4 complete: minimal pinned `gsplat` install/import validation passed on RunPod RTX 4090.
- Phase 5A local implementation complete: official `gsplat` `examples/simple_trainer.py` adopted as the first backend, with viewer imports removed by a build-time headless patch.
- A 30,000-iteration RunPod training run was reported historically, but its evidence was not preserved and does not validate the current image.
- Manual PLY export and packaging commands exist; new GPU smoke test is pending.
- Scene-scoped log packaging exists through `empaquetar-logs`; its real RunPod use is pending.

## Immediate Priorities

1. Wait for GPU availability.
2. Run `validate-gpu.sh`.
3. Run `MAX_STEPS=100 train-scene.sh room`.
4. Run `generar --scene room`.
5. Run `empaquetar room`.
6. Transfer the package with `runpodctl`.
7. Verify checksum on the Mac.
8. Test a file larger than 1 GB.
9. Record exact working `runpodctl` commands.
10. Define the Trainer baseline.
11. Validate the Surveyor-to-Trainer handoff.

## Recently Implemented

- Included fixed-version `runpodctl v2.5.0` in the Trainer image build.
- Added scene-scoped evidence packaging with `empaquetar-logs`.

## Accepted But Pending

- Validate Mac-to-pod and pod-to-Mac transfer.
- Measure transfer speed and interruption behavior.

Transfer behavior is not fully validated by this image update.

## Criteria

Each phase must remain reviewable as a logical commit.

Do not install desktop, viewer, streaming, or benchmark dependencies while the headless training baseline is still being established.

Do not modify `generar` before the next smoke test. The current syntax is valid:

```bash
generar --scene <scene>
```

The future shortcut `generar <scene>` is optional and not required for current validation.
