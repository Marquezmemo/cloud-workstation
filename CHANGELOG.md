# Changelog

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
