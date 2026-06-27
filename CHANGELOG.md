# Changelog

## First Real Surveyor Run Documentation

- Recorded evidence from `prueba-01`, the first real 30-image RunPod run.
- Validated the runtime fingerprint, ZIP intake, GPU execution, package/checksum generation, and sender-side `runpodctl send`.
- Recorded evidence checksums `7c3129ed0c26ce6eee9b2df160cae5af97077dbfe74619085b8dce93086af1cd` and `12b89e5d3c54270c71b2c03b8b81beb547cf1bf16f28331405489c93afd02dbc`.
- Blocked Trainer handoff because `sparse/0` reports 2 registered images while a later mapper reconstruction reaches 30.
- Distinguished the manually repaired run manifest from the permanent source correction, which remains pending.
- Recorded the successful preparation-test isolation in `771107f`, cleanup in `946b732`, and workflow run `28295373995`.
- Added packaging progress as a pending usability improvement; no progress feature is claimed as implemented.

## Transactional ZIP Scene Preparation

- Added `unzip` and the `preparar-escena [archivo.zip]` operator command.
- Added exact single-ZIP autodetection under `/workspace` without newest-file selection.
- Added integrity, archive-path, image-count, metadata-filtering, collision, and existing-scene gates.
- Added atomic incoming-scene publication with the original download retained and an identical ZIP copy under `source/`.
- Added synthetic success and failure tests, including a ZIP containing `__MACOSX` metadata.

## Surveyor CUDA Compatibility And Drive Intake

- Replaced the CUDA 12.9 COLMAP base with pinned COLMAP 3.10/CUDA 12.3.1 on Ubuntu 22.04.
- Added runtime fingerprint gates for COLMAP, CUDA, SIFT options, and required commands.
- Added pinned `gdown 6.1.0` with a fully hashed Linux/Python 3.10 dependency lock.
- Documented checksum-verified downloads from temporarily shared Google Drive links.
- Recorded the rejected CUDA 12.9 startup as operator-reported evidence, not a Surveyor smoke test.

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
