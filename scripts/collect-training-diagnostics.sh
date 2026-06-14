#!/usr/bin/env bash
set -euo pipefail

WORKSPACE_ROOT="${WORKSPACE_ROOT:-/workspace}"
DATASETS_DIR="${DATASETS_DIR:-${WORKSPACE_ROOT}/datasets}"
SCENES_DIR="${SCENES_DIR:-${WORKSPACE_ROOT}/scenes}"
OUTPUTS_DIR="${OUTPUTS_DIR:-${WORKSPACE_ROOT}/outputs}"
LOGS_DIR="${LOGS_DIR:-${WORKSPACE_ROOT}/logs}"
CHECKPOINTS_DIR="${CHECKPOINTS_DIR:-${WORKSPACE_ROOT}/checkpoints}"
DIAGNOSTICS_DIR="${DIAGNOSTICS_DIR:-${LOGS_DIR}/diagnostics}"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
RUN_DIR="${DIAGNOSTICS_DIR}/training-diagnostics-${STAMP}"
ARCHIVE="${RUN_DIR}.tar.gz"

mkdir -p "${RUN_DIR}"

write_command() {
  local output_file="$1"
  shift

  {
    echo "===== command ====="
    printf '%q ' "$@"
    echo
    echo
    "$@"
  } > "${output_file}" 2>&1 || {
    local status=$?
    {
      echo
      echo "===== exit_status ====="
      echo "${status}"
    } >> "${output_file}"
    return 0
  }
}

copy_if_exists() {
  local src="$1"
  local dst="$2"

  if [ -e "${src}" ]; then
    mkdir -p "$(dirname "${dst}")"
    cp -a "${src}" "${dst}"
  fi
}

{
  echo "collected_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "training_image_version=${TRAINING_IMAGE_VERSION:-unknown}"
  echo "workspace_root=${WORKSPACE_ROOT}"
  echo "datasets_dir=${DATASETS_DIR}"
  echo "scenes_dir=${SCENES_DIR}"
  echo "outputs_dir=${OUTPUTS_DIR}"
  echo "logs_dir=${LOGS_DIR}"
  echo "checkpoints_dir=${CHECKPOINTS_DIR}"
} > "${RUN_DIR}/metadata.env"

write_command "${RUN_DIR}/uname.txt" uname -a
copy_if_exists /etc/os-release "${RUN_DIR}/os-release"
write_command "${RUN_DIR}/disk-usage.txt" df -h "${WORKSPACE_ROOT}"
write_command "${RUN_DIR}/workspace-tree.txt" find "${WORKSPACE_ROOT}" -maxdepth 4 -mindepth 1 -print
write_command "${RUN_DIR}/processes.txt" ps auxww
write_command "${RUN_DIR}/environment.txt" env

if command -v nvidia-smi >/dev/null 2>&1; then
  write_command "${RUN_DIR}/nvidia-smi.txt" nvidia-smi
  write_command "${RUN_DIR}/nvidia-smi-query.txt" nvidia-smi --query-gpu=name,driver_version,memory.total,memory.used,memory.free,utilization.gpu,temperature.gpu --format=csv
else
  echo "nvidia-smi unavailable" > "${RUN_DIR}/nvidia-smi.txt"
fi

python - <<'PY' > "${RUN_DIR}/python-torch-cuda.txt" 2>&1 || true
import sys

print(f"python={sys.version.split()[0]}")

try:
    import torch
except Exception as exc:
    print(f"torch_import_error={exc}")
    raise SystemExit(0)

print(f"torch={torch.__version__}")
print(f"torch_cuda={torch.version.cuda}")
print(f"cuda_available={torch.cuda.is_available()}")

if torch.cuda.is_available():
    device_index = torch.cuda.current_device()
    print(f"cuda_device_index={device_index}")
    print(f"cuda_device_name={torch.cuda.get_device_name(device_index)}")
    print(f"cuda_memory_allocated={torch.cuda.memory_allocated(device_index)}")
    print(f"cuda_memory_reserved={torch.cuda.memory_reserved(device_index)}")
PY

python -m pip freeze > "${RUN_DIR}/pip-freeze.txt" 2>&1 || true

mkdir -p "${RUN_DIR}/workspace-snapshots"
for path in "${DATASETS_DIR}" "${SCENES_DIR}" "${OUTPUTS_DIR}" "${LOGS_DIR}" "${CHECKPOINTS_DIR}"; do
  name="$(basename "${path}")"
  if [ -d "${path}" ]; then
    find "${path}" -maxdepth 4 -print > "${RUN_DIR}/workspace-snapshots/${name}.txt" 2>&1 || true
  else
    echo "missing: ${path}" > "${RUN_DIR}/workspace-snapshots/${name}.txt"
  fi
done

mkdir -p "${RUN_DIR}/recent-logs"
if [ -d "${LOGS_DIR}" ]; then
  find "${LOGS_DIR}" -type f \
    ! -path "${DIAGNOSTICS_DIR}/*" \
    \( -name '*.log' -o -name '*.txt' -o -name '*.out' -o -name '*.err' \) \
    -print | sort | tail -50 > "${RUN_DIR}/recent-log-files.txt"

  while IFS= read -r log_file; do
    [ -n "${log_file}" ] || continue
    safe_name="$(echo "${log_file#${LOGS_DIR}/}" | tr '/ ' '__')"
    tail -200 "${log_file}" > "${RUN_DIR}/recent-logs/${safe_name}" 2>&1 || true
  done < "${RUN_DIR}/recent-log-files.txt"
else
  echo "logs dir missing: ${LOGS_DIR}" > "${RUN_DIR}/recent-log-files.txt"
fi

tar -C "${DIAGNOSTICS_DIR}" -czf "${ARCHIVE}" "$(basename "${RUN_DIR}")"

echo "${ARCHIVE}"
