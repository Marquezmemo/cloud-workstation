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

cleanup() {
  stop_gpu_monitor
  if [[ -n "${SPARSE_SELECTION_TMP:-}" && -f "${SPARSE_SELECTION_TMP}" ]]; then
    rm -f "${SPARSE_SELECTION_TMP}"
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

extract_analyzer_metric() {
  local analyzer_output="$1"
  local metric_name="$2"

  printf '%s\n' "${analyzer_output}" \
    | sed -n -E "s/.*${metric_name}:[[:space:]]*([0-9]+).*/\\1/p" \
    | tail -n 1
}

swap_sparse_models() {
  local selected_index="$1"

  [[ "${selected_index}" != "0" ]] || return 0

  python3 - "${SPARSE_DIR}" "${selected_index}" <<'PY'
import os
import sys
import uuid

sparse_dir, selected_index = sys.argv[1:]
zero_path = os.path.join(sparse_dir, "0")
selected_path = os.path.join(sparse_dir, selected_index)
temporary_path = os.path.join(
    sparse_dir, f".surveyor-sparse-swap-{uuid.uuid4().hex}"
)

if not os.path.isdir(zero_path):
    raise SystemExit(f"ERROR: missing sparse model for swap: {zero_path}")
if not os.path.isdir(selected_path):
    raise SystemExit(f"ERROR: missing selected sparse model for swap: {selected_path}")
if os.path.lexists(temporary_path):
    raise SystemExit(f"ERROR: sparse swap temporary path already exists: {temporary_path}")

state = 0
try:
    os.rename(zero_path, temporary_path)
    state = 1
    os.rename(selected_path, zero_path)
    state = 2
    os.rename(temporary_path, selected_path)
    state = 3
except OSError as error:
    rollback_errors = []
    if state == 2:
        try:
            os.rename(zero_path, selected_path)
        except OSError as rollback_error:
            rollback_errors.append(str(rollback_error))
    if state in (1, 2) and os.path.lexists(temporary_path):
        try:
            os.rename(temporary_path, zero_path)
        except OSError as rollback_error:
            rollback_errors.append(str(rollback_error))

    message = f"ERROR: sparse model swap failed: {error}"
    if rollback_errors:
        message += "; rollback errors: " + "; ".join(rollback_errors)
    raise SystemExit(message)
PY
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
SPARSE_SELECTION_TMP=""

trap cleanup EXIT

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

# Sparse model discovery and normalization
CANDIDATE_INDICES=()
CANDIDATE_REGISTERED_IMAGES=()
CANDIDATE_POINTS=()
SELECTED_POSITION=-1
SELECTED_ORIGINAL_INDEX=""
SELECTED_REGISTERED_IMAGES=-1
SELECTED_POINTS=-1
HAS_SPARSE_ZERO=false

while IFS= read -r candidate_index; do
  candidate_path="${SPARSE_DIR}/${candidate_index}"
  [[ "${candidate_index}" == "0" ]] && HAS_SPARSE_ZERO=true

  for name in cameras images points3D; do
    [[ -s "${candidate_path}/${name}.bin" ]] \
      || fail "sparse model ${candidate_index} is missing a non-empty ${name}.bin"
  done

  if ! candidate_analysis="$(colmap model_analyzer --path "${candidate_path}" 2>&1)"; then
    printf '%s\n' "${candidate_analysis}" >&2
    fail "could not analyze sparse model ${candidate_index}"
  fi
  candidate_registered_images="$(extract_analyzer_metric "${candidate_analysis}" "Registered images")"
  candidate_points="$(extract_analyzer_metric "${candidate_analysis}" "Points")"
  [[ "${candidate_registered_images}" =~ ^[0-9]+$ ]] \
    || fail "invalid Registered images metric for sparse model ${candidate_index}"
  [[ "${candidate_points}" =~ ^[0-9]+$ ]] \
    || fail "invalid Points metric for sparse model ${candidate_index}"

  CANDIDATE_INDICES+=("${candidate_index}")
  CANDIDATE_REGISTERED_IMAGES+=("${candidate_registered_images}")
  CANDIDATE_POINTS+=("${candidate_points}")
  candidate_position=$((${#CANDIDATE_INDICES[@]} - 1))

  if (( SELECTED_POSITION < 0 \
      || candidate_registered_images > SELECTED_REGISTERED_IMAGES \
      || (candidate_registered_images == SELECTED_REGISTERED_IMAGES \
          && candidate_points > SELECTED_POINTS) \
      || (candidate_registered_images == SELECTED_REGISTERED_IMAGES \
          && candidate_points == SELECTED_POINTS \
          && candidate_index < SELECTED_ORIGINAL_INDEX) )); then
    SELECTED_POSITION="${candidate_position}"
    SELECTED_ORIGINAL_INDEX="${candidate_index}"
    SELECTED_REGISTERED_IMAGES="${candidate_registered_images}"
    SELECTED_POINTS="${candidate_points}"
  fi
done < <(
  for candidate_path in "${SPARSE_DIR}"/*; do
    [[ -d "${candidate_path}" ]] || continue
    candidate_index="$(basename "${candidate_path}")"
    [[ "${candidate_index}" =~ ^(0|[1-9][0-9]*)$ ]] || continue
    printf '%s\n' "${candidate_index}"
  done | sort -n
)

SPARSE_MODEL_COUNT="${#CANDIDATE_INDICES[@]}"
(( SPARSE_MODEL_COUNT > 0 )) || fail "COLMAP did not produce a valid numeric sparse model"
[[ "${HAS_SPARSE_ZERO}" == "true" ]] || fail "COLMAP did not produce ${SPARSE_DIR}/0"
(( SELECTED_REGISTERED_IMAGES >= 2 )) \
  || fail "best sparse model has fewer than 2 registered images: ${SELECTED_REGISTERED_IMAGES}"

SPARSE_SELECTION_TMP="${LOG_DIR}/.sparse-selection.$$.tmp"
{
  echo "model_count=${SPARSE_MODEL_COUNT}"
  for ((candidate_position = 0; candidate_position < SPARSE_MODEL_COUNT; candidate_position++)); do
    echo
    echo "candidate_index=${CANDIDATE_INDICES[candidate_position]}"
    echo "registered_images=${CANDIDATE_REGISTERED_IMAGES[candidate_position]}"
    echo "points=${CANDIDATE_POINTS[candidate_position]}"
  done
} > "${SPARSE_SELECTION_TMP}"

swap_sparse_models "${SELECTED_ORIGINAL_INDEX}"

if ! FINAL_MODEL_ANALYSIS="$(colmap model_analyzer --path "${SPARSE_DIR}/0" 2>&1)"; then
  printf '%s\n' "${FINAL_MODEL_ANALYSIS}" >&2
  fail "could not analyze normalized sparse model: ${SPARSE_DIR}/0"
fi
printf '%s\n' "${FINAL_MODEL_ANALYSIS}" | tee "${LOG_DIR}/model-analyzer.txt"
REGISTERED_IMAGES="$(extract_analyzer_metric "${FINAL_MODEL_ANALYSIS}" "Registered images")"
FINAL_MODEL_POINTS="$(extract_analyzer_metric "${FINAL_MODEL_ANALYSIS}" "Points")"
[[ "${REGISTERED_IMAGES}" == "${SELECTED_REGISTERED_IMAGES}" ]] \
  || fail "normalized sparse model registered image count changed: selected=${SELECTED_REGISTERED_IMAGES}, final=${REGISTERED_IMAGES}"
[[ "${FINAL_MODEL_POINTS}" == "${SELECTED_POINTS}" ]] \
  || fail "normalized sparse model point count changed: selected=${SELECTED_POINTS}, final=${FINAL_MODEL_POINTS}"

{
  echo
  echo "selected_original_index=${SELECTED_ORIGINAL_INDEX}"
  echo "selected_registered_images=${REGISTERED_IMAGES}"
  echo "selected_points=${FINAL_MODEL_POINTS}"
  echo "selected_final_path=${SPARSE_DIR}/0"
} >> "${SPARSE_SELECTION_TMP}"
mv "${SPARSE_SELECTION_TMP}" "${LOG_DIR}/sparse-selection.txt"
SPARSE_SELECTION_TMP=""

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
  "${SPARSE_DIR}/0" \
  "${SPARSE_MODEL_COUNT}" \
  "${SELECTED_ORIGINAL_INDEX}" \
  "${REGISTERED_IMAGES}" <<'PY'
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
    "sparse_model_count": int(sys.argv[12]),
    "selected_sparse_original_index": sys.argv[13],
    "registered_images": int(sys.argv[14]),
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
