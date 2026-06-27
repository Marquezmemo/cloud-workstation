#!/usr/bin/env bash
set -euo pipefail

# Purpose: Validate and package a Surveyor scene plus its operational evidence.
# Input:   A completed scene and logs under the Surveyor workspace.
# Output:  Portable scene/evidence archives and relative SHA-256 records.

# Help and lifecycle helpers
usage() {
  cat <<'EOF'
package-surveyor-scene.sh <scene-name>

Validates and packages a Surveyor scene for transfer or Trainer handoff.

Default input:
  /workspace/scenes/<scene>
  /workspace/logs/<scene>

Default output:
  /workspace/archives/<scene>/<scene>-surveyor-scene.tar.gz
  /workspace/archives/<scene>/<scene>-surveyor-scene.tar.gz.sha256
  /workspace/archives/<scene>/<scene>-surveyor-evidence.tar.gz
  /workspace/archives/<scene>/<scene>-surveyor-evidence.tar.gz.sha256

Environment overrides:
  WORKSPACE_ROOT   Defaults to /workspace.
  SCENE_PATH       Defaults to /workspace/scenes/<scene>.
  LOG_DIR          Defaults to /workspace/logs/<scene>.
  ARCHIVE_DIR      Defaults to /workspace/archives/<scene>.
  ARCHIVE_PATH     Overrides the scene archive path.
  EVIDENCE_PATH    Overrides the evidence archive path.
  TEMP_DIR         Defaults to /workspace/temp.
  OVERWRITE        true to replace existing packages. Defaults to false.
EOF
}

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

write_and_verify_checksum() {
  local archive_path="$1"
  local archive_dir
  local archive_name

  archive_dir="$(dirname "${archive_path}")"
  archive_name="$(basename "${archive_path}")"

  (
    cd "${archive_dir}"
    sha256sum "${archive_name}" > "${archive_name}.sha256"
    sha256sum -c "${archive_name}.sha256"
  )
}

cleanup() {
  if [[ -n "${EVIDENCE_STAGING_DIR:-}" && -d "${EVIDENCE_STAGING_DIR}" ]]; then
    rm -rf "${EVIDENCE_STAGING_DIR}"
  fi
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
ARCHIVE_DIR="${ARCHIVE_DIR:-${WORKSPACE_ROOT}/archives/${SCENE_NAME}}"
ARCHIVE_PATH="${ARCHIVE_PATH:-${ARCHIVE_DIR}/${SCENE_NAME}-surveyor-scene.tar.gz}"
EVIDENCE_PATH="${EVIDENCE_PATH:-${ARCHIVE_DIR}/${SCENE_NAME}-surveyor-evidence.tar.gz}"
TEMP_DIR="${TEMP_DIR:-${WORKSPACE_ROOT}/temp}"
OVERWRITE="${OVERWRITE:-false}"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
VALIDATOR_PATH="${VALIDATOR_PATH:-${SCRIPT_DIR}/validate-surveyor-scene.sh}"
EVIDENCE_STAGING_DIR=""

trap cleanup EXIT

case "${OVERWRITE}" in
  true|false) ;;
  *) fail "OVERWRITE must be true or false, got: ${OVERWRITE}" ;;
esac
[[ "${ARCHIVE_PATH}" != "${EVIDENCE_PATH}" ]] || fail "scene and evidence archive paths must be different"

# Complete contract gate
WORKSPACE_ROOT="${WORKSPACE_ROOT}" \
SCENE_PATH="${SCENE_PATH}" \
LOG_DIR="${LOG_DIR}" \
  "${VALIDATOR_PATH}" "${SCENE_NAME}"

for output_path in \
  "${ARCHIVE_PATH}" \
  "${ARCHIVE_PATH}.sha256" \
  "${EVIDENCE_PATH}" \
  "${EVIDENCE_PATH}.sha256"; do
  if [[ -e "${output_path}" && "${OVERWRITE}" != "true" ]]; then
    fail "package output already exists: ${output_path}. Set OVERWRITE=true to replace it."
  fi
done

# Scene package
mkdir -p \
  "${ARCHIVE_DIR}" \
  "$(dirname "${ARCHIVE_PATH}")" \
  "$(dirname "${EVIDENCE_PATH}")" \
  "${TEMP_DIR}"

tar -C "$(dirname "${SCENE_PATH}")" -czf "${ARCHIVE_PATH}" "$(basename "${SCENE_PATH}")"
tar -tzf "${ARCHIVE_PATH}" >/dev/null
write_and_verify_checksum "${ARCHIVE_PATH}"

# Evidence package
EVIDENCE_STAGING_DIR="$(mktemp -d "${TEMP_DIR}/${SCENE_NAME}-surveyor-evidence.XXXXXX")"
EVIDENCE_ROOT="${EVIDENCE_STAGING_DIR}/${SCENE_NAME}-surveyor-evidence"
mkdir -p "${EVIDENCE_ROOT}/logs"
rsync -a "${LOG_DIR}/" "${EVIDENCE_ROOT}/logs/"
cp "${SCENE_PATH}/surveyor-manifest.json" "${EVIDENCE_ROOT}/surveyor-manifest.json"

tar -C "${EVIDENCE_STAGING_DIR}" -czf "${EVIDENCE_PATH}" "$(basename "${EVIDENCE_ROOT}")"
tar -tzf "${EVIDENCE_PATH}" >/dev/null
write_and_verify_checksum "${EVIDENCE_PATH}"

echo "Surveyor packages created:"
echo "  ${ARCHIVE_PATH}"
echo "  ${ARCHIVE_PATH}.sha256"
echo "  ${EVIDENCE_PATH}"
echo "  ${EVIDENCE_PATH}.sha256"
