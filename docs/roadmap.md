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
- The original `Prueba02` validates an earlier runtime with preserved evidence: manual scene extraction, a real Surveyor-to-Trainer handoff, 300-step GPU training, checkpoint, standard/compressed PLY export, packaging, transfer, independent PLY inspection, and SuperSplat v2.27.4 loading.
- The final v0.1 operator attestation records that runtime `221c4ef` and image digest `sha256:726ac98c9678431fc34fbcc1de0bf07b71adbff215d672f04740a95999a6bf98` passed the real flow with automatic transactional `preparar-escena`. Its evidence level is `operator-confirmed`; primary execution records were not preserved.
- The standard PLY contained 4,555 vertices and loaded as 4,555 splats; professional and commercial quality remain unvalidated.

## Immediate Priorities

1. Improve corrective messaging for export-before-packaging order.
2. Investigate first-run CUDA compilation and AlexNet download costs.
3. Address the future `torch.load` warning.
4. Evaluate OPENCV input against PINHOLE or undistortion.
5. Validate densification and Gaussian growth.
6. Add PSNR, SSIM, LPIPS, and comparable renders.
7. Test a file larger than 1 GB and record interruption/resume behavior.
8. Preserve complete primary records for future runtime validations.
9. Define the reproducible Trainer baseline release process.
10. Validate professional capture and commercial output quality.

## Recently Implemented

- Included fixed-version `runpodctl v2.5.0` in the Trainer image build.
- Added scene-scoped evidence packaging with `empaquetar-logs`.
- Added and regression-tested transactional Surveyor scene installation with `preparar-escena`.

## Accepted But Pending

- Validate transfer behavior above 1 GB and under interruption.
- Measure transfer speed and interruption behavior.

Basic real transfer is validated by `Prueba02`; robustness is not.

## Criteria

Each phase must remain reviewable as a logical commit.

Do not install desktop, viewer, streaming, or benchmark dependencies while the headless training baseline is still being established.

Do not modify `generar` before the next smoke test. The current syntax is valid:

```bash
generar --scene <scene>
```

The future shortcut `generar <scene>` is optional and not required for current validation.
