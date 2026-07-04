# Changelog

## Prueba02 Surveyor Validation

- Recorded the corrected real run with 30 input and database images.
- Validated two-model enumeration, original model `1` selection, and normalization to `sparse/0`.
- Recorded 30 registered images, 4,555 points, 19,928 observations, mean track length `4.374973`, and reprojection error `1.133537 px`.
- Recorded valid manifest generation, contract validation, packaging, checksums, transfer, Trainer receipt, dataset acceptance, and 300-step training.
- Preserved `prueba-01` as the historical evidence that motivated best-model selection.

## Validación downstream posterior confirmada por el operador

```text
handoff_status: passed
validation_authority: repository-owner-operator
evidence_level: operator-confirmed
primary_execution_records: not-preserved
trainer_runtime: 221c4ef76a1ff5bfa8a9f45e5e9a084e8fbedfe3
```

The repository owner and operator confirmed that a later run of the final Trainer runtime, which includes `preparar-escena`, successfully consumed the Surveyor contract:

- the Surveyor package was compatible with Trainer's `preparar-escena`;
- its checksum was accepted and the scene was installed correctly;
- `train-scene.sh --check` passed;
- CUDA training completed and generated a checkpoint;
- a PLY was generated, packaged, and opened in a viewer.

These were downstream Trainer stages; Surveyor did not execute training, PLY export, packaging of the PLY, or the viewer. Primary records from this later run were not preserved, so this operator-confirmed record supplements and does not replace or downgrade the preserved Prueba02 evidence.

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
