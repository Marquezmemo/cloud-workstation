# Surveyor v0.1 Technical Proposal

Status: reviewed by The Eye; official project documentation has been updated separately.

This proposal remains a technical handoff record. Use `README.md`, `docs/architecture.md`, `docs/validation.md`, `docs/dataset-format.md`, and `docs/command-reference.md` as the active documentation.

## Summary

Surveyor should own the pre-training phase: image/frame intake, dataset preparation, sparse COLMAP reconstruction, validation, packaging, and handoff to the Trainer.

The first implementation is intentionally minimal. It uses COLMAP CLI headlessly and produces the existing Trainer dataset contract:

```text
/workspace/scenes/<scene>/images
/workspace/scenes/<scene>/sparse/0/cameras.bin
/workspace/scenes/<scene>/sparse/0/images.bin
/workspace/scenes/<scene>/sparse/0/points3D.bin
```

## Proposed Workspace

```text
/workspace/incoming/<scene>/images   # source images for reconstruction
/workspace/scenes/<scene>            # Trainer-ready scene
/workspace/logs/<scene>              # Surveyor and COLMAP logs
/workspace/archives/<scene>          # packaged scene archives and checksums
/workspace/temp                      # scratch space
```

## Initial Commands

```bash
validate-surveyor.sh
survey-scene.sh <scene>
package-surveyor-scene.sh <scene>
```

The first reconstruction command runs:

```bash
colmap feature_extractor
colmap exhaustive_matcher
colmap mapper
colmap model_analyzer
```

`MATCHER=sequential` is available for video-like capture sets.

## Initial Validation

A Surveyor scene is minimally valid when:

- `images/` exists and contains supported image files.
- `sparse/0/cameras.bin` exists.
- `sparse/0/images.bin` exists.
- `sparse/0/points3D.bin` exists.
- `train-scene.sh --check <scene>` passes in the Trainer image.

Recommended smoke threshold before broader use:

- 10 to 30 input images.
- At least one sparse model generated under `sparse/0`.
- `model_analyzer.txt` recorded under `/workspace/logs/<scene>`.

## Known Risks

- The official COLMAP image must be validated on RunPod with GPU access.
- SIFT GPU extraction or matching can fail without visible NVIDIA runtime; use `COLMAP_USE_GPU=0` as a fallback.
- `exhaustive_matcher` scales poorly; larger or video-derived sets should use `MATCHER=sequential`.
- COLMAP may produce multiple sparse components; v0.1 only accepts `sparse/0`.
- Dense reconstruction is intentionally excluded from v0.1 because the Trainer does not require it.
- Capture quality requirements are not yet formalized and should be documented after first real dataset tests.

## Proposed Documentation Updates For The Eye

- Add Surveyor as the owner of capture, preparation, reconstruction, validation, and packaging before training.
- Document `/workspace/incoming`, `/workspace/scenes`, `/workspace/logs`, `/workspace/archives`, and `/workspace/temp` as the Surveyor workspace contract.
- Document the Surveyor-to-Trainer artifact contract.
- Record COLMAP CLI limitations and GPU/CPU fallback behavior.
- Keep Trainer free of COLMAP until the Full image phase is explicitly created.
