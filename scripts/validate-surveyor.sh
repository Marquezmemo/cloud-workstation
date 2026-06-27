#!/usr/bin/env bash
set -euo pipefail

# Purpose: Validate Surveyor image tools and writable workspace paths.
# Input:   Optional workspace directory overrides through environment variables.
# Output:  Tool, NVIDIA, and workspace diagnostics on stdout.

# Workspace configuration
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
  gdown
  jq
  preparar-escena
  python3
  rsync
  runpodctl
  sha256sum
  sqlite3
  tar
  unzip
)

# Required tools
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
preparar-escena --help >/dev/null
echo "preparar_escena_help=success"

COLMAP_HELP="$(colmap -h 2>&1)"
COLMAP_HEADER="$(grep -m1 -E '^COLMAP [0-9]' <<< "${COLMAP_HELP}" || true)"
EXPECTED_COLMAP_VERSION="${SURVEYOR_COLMAP_VERSION:-3.10}"
EXPECTED_CUDA_VERSION="${SURVEYOR_CUDA_VERSION:-12.3.1}"
EXPECTED_UBUNTU_VERSION="${SURVEYOR_UBUNTU_VERSION:-22.04}"
EXPECTED_GDOWN_VERSION="${SURVEYOR_GDOWN_VERSION:-6.1.0}"
OS_VERSION="$(. /etc/os-release && printf '%s' "${VERSION_ID:-unknown}")"

[[ "${COLMAP_HEADER}" == *"COLMAP ${EXPECTED_COLMAP_VERSION}"* ]] || {
  echo "ERROR: expected COLMAP ${EXPECTED_COLMAP_VERSION}, got: ${COLMAP_HEADER}" >&2
  exit 1
}
[[ "${CUDA_VERSION:-unknown}" == "${EXPECTED_CUDA_VERSION}" ]] || {
  echo "ERROR: expected CUDA_VERSION=${EXPECTED_CUDA_VERSION}, got: ${CUDA_VERSION:-unknown}" >&2
  exit 1
}
[[ "${OS_VERSION}" == "${EXPECTED_UBUNTU_VERSION}" ]] || {
  echo "ERROR: expected Ubuntu ${EXPECTED_UBUNTU_VERSION}, got: ${OS_VERSION}" >&2
  exit 1
}
[[ "${NVIDIA_REQUIRE_CUDA:-}" == *"cuda>=12.3"* ]] || {
  echo "ERROR: expected NVIDIA_REQUIRE_CUDA to include cuda>=12.3, got: ${NVIDIA_REQUIRE_CUDA:-unset}" >&2
  exit 1
}

for colmap_command in \
  feature_extractor \
  exhaustive_matcher \
  sequential_matcher \
  mapper \
  model_analyzer; do
  colmap "${colmap_command}" -h >/dev/null
  echo "colmap_command_${colmap_command}=present"
done

FEATURE_HELP="$(colmap feature_extractor -h 2>&1)"
MATCH_HELP="$(colmap exhaustive_matcher -h 2>&1)"
for required_option in \
  --ImageReader.camera_model \
  --ImageReader.single_camera \
  --SiftExtraction.use_gpu; do
  grep -Fq -- "${required_option}" <<< "${FEATURE_HELP}" || {
    echo "ERROR: missing COLMAP feature option: ${required_option}" >&2
    exit 1
  }
done
grep -Fq -- '--SiftMatching.use_gpu' <<< "${MATCH_HELP}" || {
  echo "ERROR: missing COLMAP matching option: --SiftMatching.use_gpu" >&2
  exit 1
}

GDOWN_VERSION_OUTPUT="$(gdown --version 2>&1)"
[[ "${GDOWN_VERSION_OUTPUT}" == *"${EXPECTED_GDOWN_VERSION}"* ]] || {
  echo "ERROR: expected gdown ${EXPECTED_GDOWN_VERSION}, got: ${GDOWN_VERSION_OUTPUT}" >&2
  exit 1
}

echo "colmap_version=${COLMAP_HEADER}"
echo "colmap_commit=${SURVEYOR_COLMAP_COMMIT:-unknown}"
echo "cuda_version=${CUDA_VERSION}"
echo "ubuntu_version=${OS_VERSION}"
echo "nvidia_require_cuda=${NVIDIA_REQUIRE_CUDA}"
echo "gdown_version=${GDOWN_VERSION_OUTPUT}"
echo "runpodctl_version=$(runpodctl version 2>&1 | tr '\n' ' ')"

# Optional NVIDIA diagnostics
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

# Writable workspace
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
