#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
survey-scene.sh <scene-name>

Builds a minimal COLMAP sparse reconstruction for Trainer consumption.

Required input:
  /workspace/incoming/<scene>/images

Default output:
  /workspace/scenes/<scene>/
  ├── images/
  ├── database.db
  ├── sparse/0/
  │   ├── cameras.bin
  │   ├── images.bin
  │   └── points3D.bin
  └── surveyor-manifest.json

Environment overrides:
  INPUT_IMAGES       Defaults to /workspace/incoming/<scene>/images
  SCENE_PATH         Defaults to /workspace/scenes/<scene>
  LOG_DIR            Defaults to /workspace/logs/<scene>
  MATCHER            exhaustive or sequential. Defaults to exhaustive.
  COLMAP_USE_GPU     1 or 0. Defaults to 1.
  SINGLE_CAMERA      1 or 0. Defaults to 1.
  CAMERA_MODEL       Defaults to OPENCV.
  MAX_IMAGE_SIZE     Optional COLMAP SIFT max image size.
  OVERWRITE          true to replace an existing scene output. Defaults to false.
EOF
}

timestamp() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

fail() {
  echo "ERROR: $*" >&2
  exit 1
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
INPUT_IMAGES="${INPUT_IMAGES:-${WORKSPACE_ROOT}/incoming/${SCENE_NAME}/images}"
SCENE_PATH="${SCENE_PATH:-${WORKSPACE_ROOT}/scenes/${SCENE_NAME}}"
LOG_DIR="${LOG_DIR:-${WORKSPACE_ROOT}/logs/${SCENE_NAME}}"
SPARSE_DIR="${SCENE_PATH}/sparse"
DATABASE_PATH="${SCENE_PATH}/database.db"
MATCHER="${MATCHER:-exhaustive}"
COLMAP_USE_GPU="${COLMAP_USE_GPU:-1}"
SINGLE_CAMERA="${SINGLE_CAMERA:-1}"
CAMERA_MODEL="${CAMERA_MODEL:-OPENCV}"
MAX_IMAGE_SIZE="${MAX_IMAGE_SIZE:-}"
OVERWRITE="${OVERWRITE:-false}"

case "${MATCHER}" in
  exhaustive|sequential) ;;
  *) fail "MATCHER must be exhaustive or sequential, got: ${MATCHER}" ;;
esac

[[ -d "${INPUT_IMAGES}" ]] || fail "missing input images directory: ${INPUT_IMAGES}"
if ! find "${INPUT_IMAGES}" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.tif' -o -iname '*.tiff' \) | grep -q .; then
  fail "no supported image files found in ${INPUT_IMAGES}"
fi

if [[ -e "${SCENE_PATH}" && "${OVERWRITE}" != "true" ]]; then
  fail "scene output already exists: ${SCENE_PATH}. Set OVERWRITE=true to replace it."
fi

if [[ "${OVERWRITE}" == "true" ]]; then
  rm -rf "${SCENE_PATH}"
fi

mkdir -p "${SCENE_PATH}/images" "${SPARSE_DIR}" "${LOG_DIR}"
rsync -a --delete "${INPUT_IMAGES}/" "${SCENE_PATH}/images/"

FEATURE_ARGS=(
  feature_extractor
  --database_path "${DATABASE_PATH}"
  --image_path "${SCENE_PATH}/images"
  --ImageReader.single_camera "${SINGLE_CAMERA}"
  --ImageReader.camera_model "${CAMERA_MODEL}"
  --SiftExtraction.use_gpu "${COLMAP_USE_GPU}"
)

if [[ -n "${MAX_IMAGE_SIZE}" ]]; then
  FEATURE_ARGS+=(--SiftExtraction.max_image_size "${MAX_IMAGE_SIZE}")
fi

MATCH_ARGS=(
  "${MATCHER}_matcher"
  --database_path "${DATABASE_PATH}"
  --SiftMatching.use_gpu "${COLMAP_USE_GPU}"
)

MAPPER_ARGS=(
  mapper
  --database_path "${DATABASE_PATH}"
  --image_path "${SCENE_PATH}/images"
  --output_path "${SPARSE_DIR}"
)

{
  echo "scene=${SCENE_NAME}"
  echo "started_at=$(timestamp)"
  echo "input_images=${INPUT_IMAGES}"
  echo "scene_path=${SCENE_PATH}"
  echo "matcher=${MATCHER}"
  echo "colmap_use_gpu=${COLMAP_USE_GPU}"
  echo "single_camera=${SINGLE_CAMERA}"
  echo "camera_model=${CAMERA_MODEL}"
  echo "max_image_size=${MAX_IMAGE_SIZE}"
} > "${LOG_DIR}/surveyor.env"

echo "Running COLMAP feature extraction..."
colmap "${FEATURE_ARGS[@]}" 2>&1 | tee "${LOG_DIR}/colmap-feature.log"

echo "Running COLMAP ${MATCHER} matching..."
colmap "${MATCH_ARGS[@]}" 2>&1 | tee "${LOG_DIR}/colmap-match.log"

echo "Running COLMAP mapper..."
colmap "${MAPPER_ARGS[@]}" 2>&1 | tee "${LOG_DIR}/colmap-mapper.log"

[[ -d "${SPARSE_DIR}/0" ]] || fail "COLMAP did not produce ${SPARSE_DIR}/0"
for name in cameras images points3D; do
  [[ -f "${SPARSE_DIR}/0/${name}.bin" ]] || fail "missing ${SPARSE_DIR}/0/${name}.bin"
done

colmap model_analyzer --path "${SPARSE_DIR}/0" 2>&1 | tee "${LOG_DIR}/model-analyzer.txt"

IMAGE_COUNT="$(find "${SCENE_PATH}/images" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.tif' -o -iname '*.tiff' \) | wc -l | tr -d ' ')"
DATABASE_IMAGES="$(sqlite3 "${DATABASE_PATH}" 'select count(*) from images;' 2>/dev/null || echo unknown)"

python3 - "${SCENE_PATH}/surveyor-manifest.json" <<EOF
import json
import sys

manifest = {
    "schema": "cloud-workstation.surveyor.v0.1",
    "scene": "${SCENE_NAME}",
    "created_at": "$(timestamp)",
    "image_count": "${IMAGE_COUNT}",
    "database_images": "${DATABASE_IMAGES}",
    "matcher": "${MATCHER}",
    "colmap_use_gpu": "${COLMAP_USE_GPU}",
    "single_camera": "${SINGLE_CAMERA}",
    "camera_model": "${CAMERA_MODEL}",
    "scene_path": "${SCENE_PATH}",
    "trainer_ready_sparse_path": "${SPARSE_DIR}/0",
}

with open(sys.argv[1], "w", encoding="utf-8") as f:
    json.dump(manifest, f, indent=2)
    f.write("\\n")
EOF

{
  echo "status=success"
  echo "finished_at=$(timestamp)"
  echo "scene=${SCENE_NAME}"
  echo "scene_path=${SCENE_PATH}"
  echo "trainer_check_hint=train-scene.sh --check ${SCENE_NAME}"
} > "${LOG_DIR}/surveyor.summary"

echo "Surveyor scene completed."
echo "Scene: ${SCENE_PATH}"
echo "Sparse model: ${SPARSE_DIR}/0"
echo "Logs: ${LOG_DIR}"
