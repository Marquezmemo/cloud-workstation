#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
package-surveyor-scene.sh <scene-name>

Packages a Surveyor-generated scene for transfer or Trainer handoff.

Default input:
  /workspace/scenes/<scene>

Default output:
  /workspace/archives/<scene>/<scene>-surveyor-scene.tar.gz
  /workspace/archives/<scene>/<scene>-surveyor-scene.tar.gz.sha256
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

WORKSPACE_ROOT="${WORKSPACE_ROOT:-/workspace}"
SCENE_PATH="${SCENE_PATH:-${WORKSPACE_ROOT}/scenes/${SCENE_NAME}}"
ARCHIVE_DIR="${ARCHIVE_DIR:-${WORKSPACE_ROOT}/archives/${SCENE_NAME}}"
ARCHIVE_PATH="${ARCHIVE_PATH:-${ARCHIVE_DIR}/${SCENE_NAME}-surveyor-scene.tar.gz}"

[[ -d "${SCENE_PATH}" ]] || {
  echo "ERROR: missing scene path: ${SCENE_PATH}" >&2
  exit 1
}

for path in \
  "${SCENE_PATH}/images" \
  "${SCENE_PATH}/sparse/0/cameras.bin" \
  "${SCENE_PATH}/sparse/0/images.bin" \
  "${SCENE_PATH}/sparse/0/points3D.bin"; do
  if [[ ! -e "${path}" ]]; then
    echo "ERROR: missing required scene artifact: ${path}" >&2
    exit 1
  fi
done

mkdir -p "${ARCHIVE_DIR}"
tar -C "$(dirname "${SCENE_PATH}")" -czf "${ARCHIVE_PATH}" "$(basename "${SCENE_PATH}")"
sha256sum "${ARCHIVE_PATH}" > "${ARCHIVE_PATH}.sha256"

echo "Surveyor scene package created:"
echo "  ${ARCHIVE_PATH}"
echo "  ${ARCHIVE_PATH}.sha256"
