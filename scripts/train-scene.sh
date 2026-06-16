#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
train-scene.sh <scene-name> [-- extra simple_trainer args]

Wraps the official gsplat examples/simple_trainer.py in headless mode.

Required dataset:
  A COLMAP-prepared scene. COLMAP itself is not installed in this image.

Environment overrides:
  SCENE_NAME        Scene name when no positional argument is provided.
  SCENE_PATH        Defaults to /workspace/scenes/${SCENE_NAME}.
  OUTPUT_PATH       Defaults to /workspace/outputs/${SCENE_NAME}.
  CHECKPOINT_PATH   Defaults to /workspace/checkpoints/${SCENE_NAME}.
  LOG_PATH          Defaults to /workspace/logs/${SCENE_NAME}/train.log.
  MAX_STEPS         Defaults to 100 for short validation runs.
  DATA_FACTOR       Defaults to 1.
  TEST_EVERY        Defaults to 8.
  TRAINER_CONFIG    Defaults to default.
  DISABLE_VIEWER    Must remain true. Defaults to true.

Utility modes:
  --help            Show this help.
  --check <scene>   Validate paths and write run metadata without training.
EOF
}

timestamp() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

CHECK_ONLY=false
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi
if [[ "${1:-}" == "--check" ]]; then
  CHECK_ONLY=true
  shift
fi

SCENE_NAME="${1:-${SCENE_NAME:-}}"
if [[ -z "${SCENE_NAME}" ]]; then
  usage >&2
  exit 2
fi
shift || true
if [[ "${1:-}" == "--" ]]; then
  shift
fi

SCENE_PATH="${SCENE_PATH:-/workspace/scenes/${SCENE_NAME}}"
OUTPUT_PATH="${OUTPUT_PATH:-/workspace/outputs/${SCENE_NAME}}"
CHECKPOINT_PATH="${CHECKPOINT_PATH:-/workspace/checkpoints/${SCENE_NAME}}"
LOG_DIR="$(dirname "${LOG_PATH:-/workspace/logs/${SCENE_NAME}/train.log}")"
LOG_PATH="${LOG_PATH:-${LOG_DIR}/train.log}"
MAX_STEPS="${MAX_STEPS:-100}"
DATA_FACTOR="${DATA_FACTOR:-1}"
TEST_EVERY="${TEST_EVERY:-8}"
TRAINER_CONFIG="${TRAINER_CONFIG:-default}"
DISABLE_VIEWER="${DISABLE_VIEWER:-true}"
TRAINER_PATH="${GSPLAT_SIMPLE_TRAINER:-/opt/gsplat/examples/simple_trainer.py}"
TRAINER_DIR="$(dirname "${TRAINER_PATH}")"

if [[ "${DISABLE_VIEWER}" != "true" ]]; then
  echo "ERROR: DISABLE_VIEWER must remain true for this headless image." >&2
  exit 2
fi

mkdir -p "${OUTPUT_PATH}" "${LOG_DIR}" "$(dirname "${CHECKPOINT_PATH}")"
ln -sfn "${OUTPUT_PATH}/ckpts" "${CHECKPOINT_PATH}"

RUN_ENV="${LOG_DIR}/run.env"
RUN_SUMMARY="${LOG_DIR}/run.summary"
ERROR_TAIL="${LOG_DIR}/error.tail"

write_run_env() {
  {
    echo "SCENE_NAME=${SCENE_NAME}"
    echo "SCENE_PATH=${SCENE_PATH}"
    echo "OUTPUT_PATH=${OUTPUT_PATH}"
    echo "CHECKPOINT_PATH=${CHECKPOINT_PATH}"
    echo "LOG_PATH=${LOG_PATH}"
    echo "MAX_STEPS=${MAX_STEPS}"
    echo "DATA_FACTOR=${DATA_FACTOR}"
    echo "TEST_EVERY=${TEST_EVERY}"
    echo "TRAINER_CONFIG=${TRAINER_CONFIG}"
    echo "DISABLE_VIEWER=${DISABLE_VIEWER}"
    echo "TRAINER_PATH=${TRAINER_PATH}"
    echo "GSPLAT_EXAMPLES_REF=${GSPLAT_EXAMPLES_REF:-unknown}"
    echo "timestamp=$(timestamp)"
  } > "${RUN_ENV}"
}

validate_dataset() {
  local sparse_dir=""

  if [[ ! -d "${SCENE_PATH}" ]]; then
    echo "ERROR: SCENE_PATH does not exist: ${SCENE_PATH}" >&2
    return 1
  fi
  if [[ ! -d "${SCENE_PATH}/images" ]]; then
    echo "ERROR: missing images directory: ${SCENE_PATH}/images" >&2
    return 1
  fi
  if [[ -d "${SCENE_PATH}/sparse/0" ]]; then
    sparse_dir="${SCENE_PATH}/sparse/0"
  elif [[ -d "${SCENE_PATH}/sparse" ]]; then
    sparse_dir="${SCENE_PATH}/sparse"
  else
    echo "ERROR: missing COLMAP sparse directory: ${SCENE_PATH}/sparse or ${SCENE_PATH}/sparse/0" >&2
    return 1
  fi

  for name in cameras images points3D; do
    if [[ ! -f "${sparse_dir}/${name}.bin" && ! -f "${sparse_dir}/${name}.txt" ]]; then
      echo "ERROR: missing COLMAP ${name}.bin or ${name}.txt in ${sparse_dir}" >&2
      return 1
    fi
  done
}

write_run_env

if "${CHECK_ONLY}"; then
  if validate_dataset; then
    echo "dataset_check=passed" > "${RUN_SUMMARY}"
    echo "Dataset paths look ready for simple_trainer.py."
  else
    echo "dataset_check=failed" > "${RUN_SUMMARY}"
    exit 1
  fi
  exit 0
fi

validate_dataset

COMMAND=(
  python "${TRAINER_PATH}" "${TRAINER_CONFIG}"
  --disable_viewer
  --data_dir "${SCENE_PATH}"
  --result_dir "${OUTPUT_PATH}"
  --max_steps "${MAX_STEPS}"
  --data_factor "${DATA_FACTOR}"
  --test_every "${TEST_EVERY}"
)

if [[ "$#" -gt 0 ]]; then
  COMMAND+=("$@")
fi

{
  echo "status=running"
  echo "started_at=$(timestamp)"
  echo "command=${COMMAND[*]}"
} > "${RUN_SUMMARY}"

set +e
(
  cd "${TRAINER_DIR}"
  "${COMMAND[@]}"
) 2>&1 | tee "${LOG_PATH}"
STATUS=${PIPESTATUS[0]}
set -e

{
  echo "status=$([[ "${STATUS}" -eq 0 ]] && echo success || echo failed)"
  echo "exit_code=${STATUS}"
  echo "finished_at=$(timestamp)"
  echo "scene=${SCENE_NAME}"
  echo "log=${LOG_PATH}"
  echo "outputs=${OUTPUT_PATH}"
  echo "checkpoints=${CHECKPOINT_PATH}"
} >> "${RUN_SUMMARY}"

if [[ "${STATUS}" -ne 0 ]]; then
  tail -n 200 "${LOG_PATH}" > "${ERROR_TAIL}" || true
  echo "Training failed. Error tail written to ${ERROR_TAIL}" >&2
  exit "${STATUS}"
fi

echo "Training command completed."
echo "Log: ${LOG_PATH}"
echo "Outputs: ${OUTPUT_PATH}"
echo "Checkpoints: ${CHECKPOINT_PATH}"
