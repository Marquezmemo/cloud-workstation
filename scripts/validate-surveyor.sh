#!/usr/bin/env bash
set -euo pipefail

WORKSPACE_ROOT="${WORKSPACE_ROOT:-/workspace}"
INCOMING_DIR="${INCOMING_DIR:-${WORKSPACE_ROOT}/incoming}"
SCENES_DIR="${SCENES_DIR:-${WORKSPACE_ROOT}/scenes}"
LOGS_DIR="${LOGS_DIR:-${WORKSPACE_ROOT}/logs}"
ARCHIVES_DIR="${ARCHIVES_DIR:-${WORKSPACE_ROOT}/archives}"
TEMP_DIR="${TEMP_DIR:-${WORKSPACE_ROOT}/temp}"

required_commands=(
  bash
  colmap
  ffmpeg
  jq
  python3
  rsync
  sha256sum
  sqlite3
  tar
)

echo "surveyor_image_version=${SURVEYOR_IMAGE_VERSION:-unknown}"
echo "timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
echo

for command_name in "${required_commands[@]}"; do
  if ! command -v "${command_name}" >/dev/null 2>&1; then
    echo "ERROR: missing required command: ${command_name}" >&2
    exit 1
  fi
  echo "command_${command_name}=present"
done

echo
colmap -h >/dev/null
echo "colmap_help=success"

if command -v nvidia-smi >/dev/null 2>&1; then
  if nvidia-smi >/tmp/surveyor-nvidia-smi.txt 2>&1; then
    echo "nvidia_smi=success"
    head -n 12 /tmp/surveyor-nvidia-smi.txt
  else
    echo "nvidia_smi=failed"
  fi
else
  echo "nvidia_smi=not_installed"
fi

echo
for dir in "${INCOMING_DIR}" "${SCENES_DIR}" "${LOGS_DIR}" "${ARCHIVES_DIR}" "${TEMP_DIR}"; do
  mkdir -p "${dir}"
  if [[ ! -w "${dir}" ]]; then
    echo "ERROR: workspace path is not writable: ${dir}" >&2
    exit 1
  fi
  echo "workspace_path=${dir}"
done

echo
echo "surveyor_validation=passed"
