#!/usr/bin/env bash
set -euo pipefail

# Purpose: Build and validate a sparse COLMAP scene for Trainer consumption.
# Input:   Supported images under /workspace/incoming/<scene>/images.
# Output:  A complete scene under /workspace/scenes and evidence under logs.

# Help and lifecycle helpers
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

stop_gpu_monitor() {
  if [[ -n "${GPU_MONITOR_PID:-}" ]]; then
    kill "${GPU_MONITOR_PID}" >/dev/null 2>&1 || true
    wait "${GPU_MONITOR_PID}" 2>/dev/null || true
    GPU_MONITOR_PID=""
  fi
}

start_gpu_monitor() {
  local output_path="$1"

  (
    echo "timestamp,index,name,utilization_gpu_percent,memory_used_mib"
    while true; do
      nvidia-smi \
        --query-gpu=timestamp,index,name,utilization.gpu,memory.used \
        --format=csv,noheader,nounits
      sleep 1
    done
  ) > "${output_path}" 2>&1 &
  GPU_MONITOR_PID=$!
}

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

# Arguments and configuration
SCENE_NAME="${1:-${SCENE_NAME:-}}"
if [[ -z "${SCENE_NAME}" ]]; then
  usage >&2
  exit 2
fi
[[ "${SCENE_NAME}" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]] || fail "invalid scene name: ${SCENE_NAME}"

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
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
VALIDATOR_PATH="${VALIDATOR_PATH:-${SCRIPT_DIR}/validate-surveyor-scene.sh}"
GPU_MONITOR_PID=""

trap stop_gpu_monitor EXIT

case "${MATCHER}" in
  exhaustive|sequential) ;;
  *) fail "MATCHER must be exhaustive or sequential, got: ${MATCHER}" ;;
esac

case "${COLMAP_USE_GPU}" in
  0|1) ;;
  *) fail "COLMAP_USE_GPU must be 1 or 0, got: ${COLMAP_USE_GPU}" ;;
esac

case "${SINGLE_CAMERA}" in
  0|1) ;;
  *) fail "SINGLE_CAMERA must be 1 or 0, got: ${SINGLE_CAMERA}" ;;
esac

case "${OVERWRITE}" in
  true|false) ;;
  *) fail "OVERWRITE must be true or false, got: ${OVERWRITE}" ;;
esac

if [[ -n "${MAX_IMAGE_SIZE}" && ! "${MAX_IMAGE_SIZE}" =~ ^[1-9][0-9]*$ ]]; then
  fail "MAX_IMAGE_SIZE must be a positive integer, got: ${MAX_IMAGE_SIZE}"
fi
[[ "${CAMERA_MODEL}" =~ ^[A-Z0-9_]+$ ]] || fail "invalid CAMERA_MODEL: ${CAMERA_MODEL}"

# Input and GPU preflight
[[ -d "${INPUT_IMAGES}" ]] || fail "missing input images directory: ${INPUT_IMAGES}"
INPUT_IMAGE_COUNT=0
while IFS= read -r -d '' input_image; do
  [[ -s "${input_image}" ]] || fail "input image is empty: ${input_image}"
  INPUT_IMAGE_COUNT=$((INPUT_IMAGE_COUNT + 1))
done < <(
  find "${INPUT_IMAGES}" -maxdepth 1 -type f \
    \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.tif' -o -iname '*.tiff' \) \
    -print0
)
(( INPUT_IMAGE_COUNT >= 2 )) || fail "at least 2 supported input images are required; found ${INPUT_IMAGE_COUNT}"

if [[ "${COLMAP_USE_GPU}" == "1" ]]; then
  command -v nvidia-smi >/dev/null 2>&1 || fail "COLMAP_USE_GPU=1 requires nvidia-smi"
  nvidia-smi >/dev/null 2>&1 || fail "COLMAP_USE_GPU=1 requires a visible NVIDIA GPU"
fi

if [[ -e "${SCENE_PATH}" && "${OVERWRITE}" != "true" ]]; then
  fail "scene output already exists: ${SCENE_PATH}. Set OVERWRITE=true to replace it."
fi

if [[ "${OVERWRITE}" == "true" ]]; then
  case "${SCENE_PATH}" in
    ""|/|"${WORKSPACE_ROOT}"|"${WORKSPACE_ROOT}/scenes")
      fail "refusing to overwrite unsafe scene path: ${SCENE_PATH}"
      ;;
  esac
  rm -rf "${SCENE_PATH}"
fi

mkdir -p "${SCENE_PATH}/images" "${SPARSE_DIR}" "${LOG_DIR}"
rsync -a --delete "${INPUT_IMAGES}/" "${SCENE_PATH}/images/"

# COLMAP command construction
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

# Environment evidence
COLMAP_VERSION_OUTPUT="$(colmap -h 2>&1 | grep -m1 -E '^COLMAP [0-9]' || true)"
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
  echo "input_image_count=${INPUT_IMAGE_COUNT}"
  echo "colmap_version=${COLMAP_VERSION_OUTPUT:-unknown}"
  echo "colmap_commit=${SURVEYOR_COLMAP_COMMIT:-unknown}"
  echo "cuda_version=${CUDA_VERSION:-unknown}"
  echo "ubuntu_version=${SURVEYOR_UBUNTU_VERSION:-unknown}"
  echo "nvidia_require_cuda=${NVIDIA_REQUIRE_CUDA:-unknown}"
  echo "gdown_version=$(gdown --version 2>&1 | tr '\n' ' ')"
  echo "runpodctl_version=$(runpodctl version 2>&1 | tr '\n' ' ')"
} > "${LOG_DIR}/surveyor.env"

if [[ "${COLMAP_USE_GPU}" == "1" ]]; then
  start_gpu_monitor "${LOG_DIR}/surveyor-gpu.log"
fi

# Sparse reconstruction
echo "Running COLMAP feature extraction..."
colmap "${FEATURE_ARGS[@]}" 2>&1 | tee "${LOG_DIR}/colmap-feature.log"

echo "Running COLMAP ${MATCHER} matching..."
colmap "${MATCH_ARGS[@]}" 2>&1 | tee "${LOG_DIR}/colmap-match.log"

stop_gpu_monitor

echo "Running COLMAP mapper..."
colmap "${MAPPER_ARGS[@]}" 2>&1 | tee "${LOG_DIR}/colmap-mapper.log"

[[ -d "${SPARSE_DIR}/0" ]] || fail "COLMAP did not produce ${SPARSE_DIR}/0"
for name in cameras images points3D; do
  [[ -f "${SPARSE_DIR}/0/${name}.bin" ]] || fail "missing ${SPARSE_DIR}/0/${name}.bin"
done

colmap model_analyzer --path "${SPARSE_DIR}/0" 2>&1 | tee "${LOG_DIR}/model-analyzer.txt"

# Manifest and contract validation
IMAGE_COUNT="$(find "${SCENE_PATH}/images" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.tif' -o -iname '*.tiff' \) | wc -l | tr -d ' ')"
DATABASE_IMAGES="$(sqlite3 "${DATABASE_PATH}" 'select count(*) from images;' 2>/dev/null)" || fail "could not read images table from ${DATABASE_PATH}"
[[ "${DATABASE_IMAGES}" =~ ^[0-9]+$ ]] || fail "invalid database image count: ${DATABASE_IMAGES}"

python3 - \
  "${SCENE_PATH}/surveyor-manifest.json" \
  "${SCENE_NAME}" \
  "$(timestamp)" \
  "${IMAGE_COUNT}" \
  "${DATABASE_IMAGES}" \
  "${MATCHER}" \
  "${COLMAP_USE_GPU}" \
  "${SINGLE_CAMERA}" \
  "${CAMERA_MODEL}" \
  "${SCENE_PATH}" \
  "${SPARSE_DIR}/0" <<'PY'
import json
import sys

manifest = {
    "schema": "cloud-workstation.surveyor.v0.1",
    "scene": sys.argv[2],
    "created_at": sys.argv[3],
    "image_count": int(sys.argv[4]),
    "database_images": int(sys.argv[5]),
    "matcher": sys.argv[6],
    "colmap_use_gpu": sys.argv[7],
    "single_camera": sys.argv[8],
    "camera_model": sys.argv[9],
    "scene_path": sys.argv[10],
    "trainer_ready_sparse_path": sys.argv[11],
}

with open(sys.argv[1], "w", encoding="utf-8") as f:
    json.dump(manifest, f, indent=2)
    f.write("\n")
PY

jq -e . "${SCENE_PATH}/surveyor-manifest.json" >/dev/null \
  || fail "generated manifest is not valid JSON: ${SCENE_PATH}/surveyor-manifest.json"

WORKSPACE_ROOT="${WORKSPACE_ROOT}" \
SCENE_PATH="${SCENE_PATH}" \
LOG_DIR="${LOG_DIR}" \
REQUIRE_SUMMARY=false \
  "${VALIDATOR_PATH}" "${SCENE_NAME}"

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
