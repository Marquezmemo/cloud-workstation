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

extract_analyzer_metric() {
  local analyzer_path="$1"
  local metric_name="$2"

  sed -n -E "s/.*${metric_name}:[[:space:]]*([0-9]+).*/\\1/p" "${analyzer_path}" \
    | tail -n 1
}

read_evidence_value() {
  local evidence_path="$1"
  local key="$2"

  sed -n "s/^${key}=//p" "${evidence_path}" | tail -n 1
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

MODEL_ANALYZER_PATH="${LOG_DIR}/model-analyzer.txt"
SELECTION_EVIDENCE_PATH="${LOG_DIR}/sparse-selection.txt"
require_nonempty_file "${MODEL_ANALYZER_PATH}"
require_nonempty_file "${SELECTION_EVIDENCE_PATH}"

REGISTERED_IMAGES="$(extract_analyzer_metric "${MODEL_ANALYZER_PATH}" "Registered images")"
SELECTED_POINTS="$(extract_analyzer_metric "${MODEL_ANALYZER_PATH}" "Points")"
[[ "${REGISTERED_IMAGES}" =~ ^[0-9]+$ ]] || fail "model analyzer has an invalid Registered images metric"
[[ "${SELECTED_POINTS}" =~ ^[0-9]+$ ]] || fail "model analyzer has an invalid Points metric"
(( REGISTERED_IMAGES >= 2 )) || fail "selected sparse model has fewer than 2 registered images: ${REGISTERED_IMAGES}"
(( REGISTERED_IMAGES <= DATABASE_IMAGES )) \
  || fail "registered image count exceeds database image count: registered=${REGISTERED_IMAGES}, database=${DATABASE_IMAGES}"

EVIDENCE_MODEL_COUNT="$(read_evidence_value "${SELECTION_EVIDENCE_PATH}" "model_count")"
EVIDENCE_SELECTED_INDEX="$(read_evidence_value "${SELECTION_EVIDENCE_PATH}" "selected_original_index")"
EVIDENCE_REGISTERED_IMAGES="$(read_evidence_value "${SELECTION_EVIDENCE_PATH}" "selected_registered_images")"
EVIDENCE_SELECTED_POINTS="$(read_evidence_value "${SELECTION_EVIDENCE_PATH}" "selected_points")"
EVIDENCE_FINAL_PATH="$(read_evidence_value "${SELECTION_EVIDENCE_PATH}" "selected_final_path")"
EVIDENCE_CANDIDATE_COUNT="$(grep -c '^candidate_index=' "${SELECTION_EVIDENCE_PATH}" || true)"
ACTUAL_SPARSE_MODEL_COUNT=0
for sparse_model_path in "${SCENE_PATH}/sparse"/*; do
  [[ -d "${sparse_model_path}" ]] || continue
  sparse_model_index="$(basename "${sparse_model_path}")"
  [[ "${sparse_model_index}" =~ ^(0|[1-9][0-9]*)$ ]] || continue
  ACTUAL_SPARSE_MODEL_COUNT=$((ACTUAL_SPARSE_MODEL_COUNT + 1))
done

[[ "${EVIDENCE_MODEL_COUNT}" =~ ^[1-9][0-9]*$ ]] || fail "selection evidence has an invalid model_count"
[[ "${EVIDENCE_SELECTED_INDEX}" =~ ^(0|[1-9][0-9]*)$ ]] || fail "selection evidence has an invalid selected_original_index"
[[ "${EVIDENCE_REGISTERED_IMAGES}" == "${REGISTERED_IMAGES}" ]] \
  || fail "selection evidence registered image count does not match model analyzer"
[[ "${EVIDENCE_SELECTED_POINTS}" == "${SELECTED_POINTS}" ]] \
  || fail "selection evidence point count does not match model analyzer"
[[ "${EVIDENCE_CANDIDATE_COUNT}" == "${EVIDENCE_MODEL_COUNT}" ]] \
  || fail "selection evidence candidate count does not match model_count"
[[ "${ACTUAL_SPARSE_MODEL_COUNT}" == "${EVIDENCE_MODEL_COUNT}" ]] \
  || fail "numeric sparse directory count does not match model_count"
grep -qx "candidate_index=${EVIDENCE_SELECTED_INDEX}" "${SELECTION_EVIDENCE_PATH}" \
  || fail "selected sparse index is not listed as a candidate"
[[ "${EVIDENCE_FINAL_PATH}" == "${SCENE_PATH}/sparse/0" ]] \
  || fail "selection evidence final path is invalid: ${EVIDENCE_FINAL_PATH}"

# Manifest consistency
MANIFEST_PATH="${SCENE_PATH}/surveyor-manifest.json"
require_nonempty_file "${MANIFEST_PATH}"
jq -e \
  --arg scene "${SCENE_NAME}" \
  --arg trainer_ready_sparse_path "${SCENE_PATH}/sparse/0" \
  --arg selected_sparse_original_index "${EVIDENCE_SELECTED_INDEX}" \
  --argjson image_count "${IMAGE_COUNT}" \
  --argjson database_images "${DATABASE_IMAGES}" \
  --argjson registered_images "${REGISTERED_IMAGES}" \
  --argjson sparse_model_count "${EVIDENCE_MODEL_COUNT}" \
  '
    .schema == "cloud-workstation.surveyor.v0.1" and
    .scene == $scene and
    (.image_count | tonumber) == $image_count and
    (.database_images | tonumber) == $database_images and
    (.registered_images | type) == "number" and
    .registered_images == $registered_images and
    (.sparse_model_count | type) == "number" and
    .sparse_model_count == $sparse_model_count and
    .selected_sparse_original_index == $selected_sparse_original_index and
    .trainer_ready_sparse_path == $trainer_ready_sparse_path and
    (.colmap_use_gpu == "0" or .colmap_use_gpu == "1")
  ' "${MANIFEST_PATH}" >/dev/null || fail "manifest is invalid or inconsistent: ${MANIFEST_PATH}"

# Reconstruction evidence
for log_name in \
  surveyor.env \
  colmap-feature.log \
  colmap-match.log \
  colmap-mapper.log \
  model-analyzer.txt \
  sparse-selection.txt; do
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
echo "registered_images=${REGISTERED_IMAGES}"
echo "sparse_model_count=${EVIDENCE_MODEL_COUNT}"
echo "selected_sparse_original_index=${EVIDENCE_SELECTED_INDEX}"
echo "colmap_use_gpu=${COLMAP_USE_GPU}"
