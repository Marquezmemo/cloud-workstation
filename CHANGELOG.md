# Changelog

## Manual Validation Evidence Policy

- Separated implemented, locally verified, operator-reported, evidence-backed, and pending states.
- Recorded the current synthetic contract-test result without treating it as a real RunPod reconstruction.
- Added the operator questionnaire and evidence-package workflow for manual tests.
- Recorded `runpodctl v2.5.0` as installed while keeping transfer validation pending.
- Established Aguascalientes local time as the implicit date convention for validation records.

## Surveyor Contract And Transfer Hardening

- Added pinned `runpodctl v2.5.0` to the Surveyor image.
- Added complete scene, database, manifest, sparse model, and evidence validation.
- Added GPU preflight and utilization evidence for GPU reconstruction.
- Added portable scene and evidence packages with verified relative checksums.
- Added synthetic contract tests and validation-before-publish workflow gates.

## The Eye Documentation Review

Aligned active documentation with the Surveyor COLMAP branch.

### Updated

- Rewrote architecture, validation, roadmap, and dataset-format docs for Surveyor.
- Added `docs/command-reference.md` for Surveyor commands and evidence collection.
- Reclassified Trainer workflow and PLY export docs as handoff/non-Surveyor responsibilities.
- Updated agent ownership docs to include Surveyor.
- Added README links and validation status for local vs pending RunPod checks.

### Recorded Pending Evidence

- RunPod smoke test with real images.
- COLMAP GPU visibility in RunPod.
- Real sparse reconstruction under `/workspace/scenes/<scene>/sparse/0`.
- Package and checksum from a real scene.
- Trainer acceptance with `train-scene.sh --check <scene>`.

## headless-surveyor-v0.1-dev

Initial Surveyor branch implementation.

- Created a separate headless COLMAP image line.
- Switched the image base to the pinned official COLMAP image:
  `colmap/colmap@sha256:187ca5ec98e55ed8fbec5f43f9d8f78b7a322b3b7413356634191f7a43c1efcf`.
- Added `validate-surveyor.sh`.
- Added `survey-scene.sh`.
- Added `package-surveyor-scene.sh`.
- Added Docker Hub publish workflow for `headless-surveyor-v0.1-dev`.
- Removed Trainer-specific runtime scripts and `gsplat` requirements from this branch.
- Added a Surveyor technical proposal for The Eye review.
