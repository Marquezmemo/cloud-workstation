#!/usr/bin/env bash
set -euo pipefail

# Purpose: Validate a complete Surveyor scene before packaging or handoff.
# Input:   A scene name plus the standard Surveyor workspace paths.
# Output:  A concise validation summary on stdout; no files are modified.

# Help and validation helpers
usage() {
  cat <<'EOF'
validate-surveyor-scene.sh <scene-name>

Validates the complete Surveyor scene contract, reconstruction evidence, and
manifest consistency before packaging or Trainer handoff.

Environment overrides:
  WORKSPACE_ROOT    Defaults to /workspace.
  SCENE_PATH        Defaults to /workspace/scenes/<scene>.
  LOG_DIR           Defaults to /workspace/logs/<scene>.
  REQUIRE_SUMMARY   true or false. Defaults to true.
EOF
}

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

require_nonempty_file() {
  local path="$1"
  [[ -f "${path}" && -s "${path}" ]] || fail "required file is missing or empty: ${path}"
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

# Arguments and configuration
SCENE_NAME="${1:-${SCENE_NAME:-}}"
[[ -n "${SCENE_NAME}" ]] || {
  usage >&2
  exit 2
}
[[ "${SCENE_NAME}" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]] || fail "invalid scene name: ${SCENE_NAME}"

WORKSPACE_ROOT="${WORKSPACE_ROOT:-/workspace}"
SCENE_PATH="${SCENE_PATH:-${WORKSPACE_ROOT}/scenes/${SCENE_NAME}}"
LOG_DIR="${LOG_DIR:-${WORKSPACE_ROOT}/logs/${SCENE_NAME}}"
REQUIRE_SUMMARY="${REQUIRE_SUMMARY:-true}"

case "${REQUIRE_SUMMARY}" in
  true|false) ;;
  *) fail "REQUIRE_SUMMARY must be true or false, got: ${REQUIRE_SUMMARY}" ;;
esac

# Scene structure
[[ -d "${SCENE_PATH}" ]] || fail "missing scene path: ${SCENE_PATH}"
[[ -d "${SCENE_PATH}/images" ]] || fail "missing images directory: ${SCENE_PATH}/images"

IMAGE_COUNT=0
while IFS= read -r -d '' image_path; do
  [[ -s "${image_path}" ]] || fail "image file is empty: ${image_path}"
  IMAGE_COUNT=$((IMAGE_COUNT + 1))
done < <(
  find "${SCENE_PATH}/images" -maxdepth 1 -type f \
    \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.tif' -o -iname '*.tiff' \) \
    -print0
)
(( IMAGE_COUNT >= 2 )) || fail "at least 2 non-empty supported images are required; found ${IMAGE_COUNT}"

DATABASE_PATH="${SCENE_PATH}/database.db"
require_nonempty_file "${DATABASE_PATH}"
[[ "$(sqlite3 "${DATABASE_PATH}" 'pragma integrity_check;' 2>/dev/null)" == "ok" ]] || fail "database integrity check failed: ${DATABASE_PATH}"
DATABASE_IMAGES="$(sqlite3 "${DATABASE_PATH}" 'select count(*) from images;' 2>/dev/null)" || fail "could not read images table: ${DATABASE_PATH}"
[[ "${DATABASE_IMAGES}" =~ ^[0-9]+$ ]] || fail "invalid database image count: ${DATABASE_IMAGES}"
(( DATABASE_IMAGES == IMAGE_COUNT )) || fail "image count mismatch: files=${IMAGE_COUNT}, database=${DATABASE_IMAGES}"

for name in cameras images points3D; do
  require_nonempty_file "${SCENE_PATH}/sparse/0/${name}.bin"
done

# Manifest consistency
MANIFEST_PATH="${SCENE_PATH}/surveyor-manifest.json"
require_nonempty_file "${MANIFEST_PATH}"
jq -e \
  --arg scene "${SCENE_NAME}" \
  --argjson image_count "${IMAGE_COUNT}" \
  --argjson database_images "${DATABASE_IMAGES}" \
  '
    .schema == "cloud-workstation.surveyor.v0.1" and
    .scene == $scene and
    (.image_count | tonumber) == $image_count and
    (.database_images | tonumber) == $database_images and
    (.colmap_use_gpu == "0" or .colmap_use_gpu == "1")
  ' "${MANIFEST_PATH}" >/dev/null || fail "manifest is invalid or inconsistent: ${MANIFEST_PATH}"

# Reconstruction evidence
for log_name in \
  surveyor.env \
  colmap-feature.log \
  colmap-match.log \
  colmap-mapper.log \
  model-analyzer.txt; do
  require_nonempty_file "${LOG_DIR}/${log_name}"
done

COLMAP_USE_GPU="$(jq -r '.colmap_use_gpu' "${MANIFEST_PATH}")"
if [[ "${COLMAP_USE_GPU}" == "1" ]]; then
  require_nonempty_file "${LOG_DIR}/surveyor-gpu.log"
  if ! grep -Eq \
    '^[^,]+,[^,]+,[^,]+,[[:space:]]*[0-9]+,[[:space:]]*[0-9]+$' \
    < <(tail -n +2 "${LOG_DIR}/surveyor-gpu.log"); then
    fail "GPU evidence does not contain a valid utilization sample"
  fi
fi

if [[ "${REQUIRE_SUMMARY}" == "true" ]]; then
  require_nonempty_file "${LOG_DIR}/surveyor.summary"
  grep -qx 'status=success' "${LOG_DIR}/surveyor.summary" || fail "surveyor summary does not report success"
fi

echo "surveyor_scene_validation=passed"
echo "scene=${SCENE_NAME}"
echo "image_count=${IMAGE_COUNT}"
echo "database_images=${DATABASE_IMAGES}"
echo "colmap_use_gpu=${COLMAP_USE_GPU}"
