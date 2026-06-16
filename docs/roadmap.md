# Roadmap

Roadmap for the headless Gaussian Splatting training pivot.

1. Audit pivot from remote workstation to headless training
2. Clean active image target and create persistent workspace layout
3. Add headless CUDA/PyTorch system dependencies
4. Add GPU validation, training diagnostics, and minimal pinned `gsplat` import validation
5. Add backend-configurable `gsplat` training workflow
6. Validate a minimal training run with persistent logs and outputs
7. Freeze a reproducible headless baseline
8. Optionally create a future Nerfstudio/Splatfacto benchmark branch

## Current Status

- Phase 1 complete: pivot audit documented.
- Phase 2 complete: headless cleanup and persistent `/workspace` structure.
- Phase 3 complete: minimal headless tooling and GPU validation script.
- Phase 4 complete: minimal pinned `gsplat` install/import validation passed on RunPod RTX 4090.

## Criteria

Each phase must remain reviewable as a logical commit.

Do not install desktop, viewer, streaming, or benchmark dependencies while the headless training baseline is still being established.
