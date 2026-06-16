#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
prepare-dataset.sh <scene-name>

Creates the expected directory skeleton for a COLMAP-prepared scene.
COLMAP is not installed in this image. Prepare reconstruction outside this
container, then place images and sparse reconstruction files here.

Environment overrides:
  SCENE_NAME   Scene name when no positional argument is provided.
  SCENE_PATH   Scene directory. Defaults to /workspace/scenes/${SCENE_NAME}.

Expected layout:
  /workspace/scenes/<scene>/
  ├── images/
  └── sparse/0/
      ├── cameras.bin or cameras.txt
      ├── images.bin or images.txt
      └── points3D.bin or points3D.txt
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

SCENE_NAME="${1:-${SCENE_NAME:-}}"
if [[ -z "${SCENE_NAME}" ]]; then
  usage >&2
  exit 2
fi

SCENE_PATH="${SCENE_PATH:-/workspace/scenes/${SCENE_NAME}}"

mkdir -p "${SCENE_PATH}/images" "${SCENE_PATH}/sparse/0"

cat > "${SCENE_PATH}/README.dataset.txt" <<EOF
Scene: ${SCENE_NAME}
Path: ${SCENE_PATH}

This directory is prepared for a COLMAP-ready dataset.

Required before training:
- images/ contains the input images referenced by COLMAP.
- sparse/0/ contains COLMAP cameras, images, and points3D files.

COLMAP is intentionally not installed in this image yet.
EOF

echo "Prepared scene skeleton:"
echo "  SCENE_NAME=${SCENE_NAME}"
echo "  SCENE_PATH=${SCENE_PATH}"
echo
echo "Next step after copying a valid COLMAP-prepared dataset:"
echo "  train-scene.sh ${SCENE_NAME}"
