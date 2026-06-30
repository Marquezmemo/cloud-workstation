#!/usr/bin/env bash
set -euo pipefail

# Purpose:
#   Verify and import one Surveyor scene package into the Trainer workspace.
# Input:
#   preparar-escena <scene>-surveyor-scene.tar.gz
# Output:
#   A validated scene under /workspace/scenes/<scene>.

usage() {
  cat <<'EOF'
preparar-escena <surveyor-scene.tar.gz>

Verifies the adjacent portable SHA-256 record, validates the Surveyor archive
and manifest, installs the scene transactionally, and runs train-scene.sh --check.

Environment overrides:
  WORKSPACE_ROOT    Defaults to /workspace.
  OVERWRITE         true to replace an existing validated scene. Defaults to false.
  TRAIN_SCENE_PATH  Overrides the productive train-scene.sh command for tests.
EOF
}

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

select_python() {
  if command -v python >/dev/null 2>&1; then
    command -v python
  elif command -v python3 >/dev/null 2>&1; then
    command -v python3
  else
    fail "python or python3 is required"
  fi
}

safe_remove_tree() {
  local path="$1"

  [[ -n "${path}" ]] || fail "refusing to remove an empty path"
  [[ "${path}" != "/" && "${path}" != "${WORKSPACE_ROOT}" && "${path}" != "${SCENES_DIR}" ]] \
    || fail "refusing to remove protected path: ${path}"
  case "${path}" in
    "${SCENES_DIR}/"*|"${TEMP_DIR}/"*) ;;
    *) fail "refusing to remove path outside managed directories: ${path}" ;;
  esac
  rm -rf -- "${path}"
}

verify_checksum_record() {
  local archive_dir="$1"
  local archive_name="$2"
  local checksum_name="$3"
  local output

  "${PYTHON_BIN}" - "${archive_dir}/${checksum_name}" "${archive_name}" <<'PY'
import re
import sys

checksum_path, archive_name = sys.argv[1:]
try:
    with open(checksum_path, "r", encoding="utf-8") as handle:
        records = [line.rstrip("\n") for line in handle if line.strip()]
except (OSError, UnicodeError) as exc:
    raise SystemExit(f"ERROR: could not read checksum file: {exc}")

if len(records) != 1:
    raise SystemExit("ERROR: checksum file must contain exactly one non-empty record")

match = re.fullmatch(r"([0-9A-Fa-f]{64}) ([ *])(.+)", records[0])
if not match:
    raise SystemExit("ERROR: checksum record is not valid sha256sum format")
if match.group(3) != archive_name:
    raise SystemExit(
        f"ERROR: checksum filename mismatch: expected {archive_name}, got {match.group(3)}"
    )
PY

  if command -v sha256sum >/dev/null 2>&1; then
    if ! output="$(cd "${archive_dir}" && sha256sum -c "${checksum_name}" 2>&1)"; then
      printf '%s\n' "${output}" >&2
      fail "checksum verification failed: ${archive_dir}/${archive_name}"
    fi
  elif command -v shasum >/dev/null 2>&1; then
    if ! output="$(cd "${archive_dir}" && shasum -a 256 -c "${checksum_name}" 2>&1)"; then
      printf '%s\n' "${output}" >&2
      fail "checksum verification failed: ${archive_dir}/${archive_name}"
    fi
  else
    fail "sha256sum or shasum is required"
  fi
}

inspect_or_extract_archive() {
  local action="$1"
  local archive_path="$2"
  local expected_scene="$3"
  local extraction_dir="${4:-}"

  "${PYTHON_BIN}" - "${action}" "${archive_path}" "${expected_scene}" "${extraction_dir}" <<'PY'
import re
import sys
import tarfile
from pathlib import PurePosixPath

action, archive_path, expected_scene, extraction_dir = sys.argv[1:]

def abort(message: str) -> None:
    raise SystemExit(f"ERROR: {message}")

try:
    archive = tarfile.open(archive_path, "r:gz")
except (OSError, tarfile.TarError) as exc:
    abort(f"could not read tar archive: {exc}")

with archive:
    members = archive.getmembers()
    if not members:
        abort("tar archive is empty")

    roots: set[str] = set()
    normalized_names: set[str] = set()
    root_directories: set[str] = set()

    for member in members:
        raw_name = member.name
        if not raw_name:
            abort("tar contains an empty entry name")
        if raw_name.startswith(("/", "\\")) or re.match(r"^[A-Za-z]:", raw_name):
            abort(f"tar contains an absolute path: {raw_name}")
        if "\\" in raw_name:
            abort(f"tar contains a non-POSIX path separator: {raw_name}")

        raw_parts = raw_name.rstrip("/").split("/")
        if not raw_parts or any(part in ("", ".", "..") for part in raw_parts):
            abort(f"tar contains an unsafe path: {raw_name}")

        normalized = str(PurePosixPath(*raw_parts))
        if normalized in normalized_names:
            abort(f"tar contains a duplicate path: {normalized}")
        normalized_names.add(normalized)
        roots.add(raw_parts[0])

        if len(raw_parts) == 1 and member.isdir():
            root_directories.add(raw_parts[0])
        if not (member.isdir() or member.isfile()):
            abort(f"tar contains a link or special entry: {raw_name}")

    if len(roots) != 1:
        abort("tar must contain exactly one root scene directory")

    root = next(iter(roots))
    if root not in root_directories:
        abort(f"tar root is not an explicit directory: {root}")
    if root != expected_scene:
        abort(f"archive scene name mismatch: filename={expected_scene}, root={root}")

    if action == "extract":
        if not extraction_dir:
            abort("internal extraction directory is missing")
        try:
            archive.extractall(path=extraction_dir, filter="data")
        except (OSError, tarfile.TarError) as exc:
            abort(f"could not extract tar archive: {exc}")
    elif action != "inspect":
        abort(f"unknown archive action: {action}")

    print(root)
PY
}

validate_manifest() {
  local manifest_path="$1"
  local scene_name="$2"

  "${PYTHON_BIN}" - "${manifest_path}" "${scene_name}" <<'PY'
import json
import sys

manifest_path, scene = sys.argv[1:]

def abort(message: str) -> None:
    raise SystemExit(f"ERROR: manifest {message}")

try:
    with open(manifest_path, "r", encoding="utf-8") as handle:
        manifest = json.load(handle)
except (OSError, UnicodeError, json.JSONDecodeError) as exc:
    abort(f"is not valid JSON: {exc}")

if not isinstance(manifest, dict):
    abort("root must be a JSON object")
if manifest.get("scene") != scene:
    abort(f"scene mismatch: expected {scene}, got {manifest.get('scene')!r}")

if "trainer_ready_sparse_path" in manifest:
    value = manifest["trainer_ready_sparse_path"]
    expected_suffix = f"/workspace/scenes/{scene}/sparse/0"
    if not isinstance(value, str) or not value.endswith(expected_suffix):
        abort(
            "trainer_ready_sparse_path must end with "
            f"{expected_suffix}, got {value!r}"
        )

numeric_values = {}
for key in ("registered_images", "database_images"):
    if key not in manifest:
        continue
    value = manifest[key]
    if isinstance(value, bool) or not isinstance(value, int) or value < 0:
        abort(f"{key} must be a non-negative integer, got {value!r}")
    numeric_values[key] = value

if (
    "registered_images" in numeric_values
    and "database_images" in numeric_values
    and numeric_values["registered_images"] > numeric_values["database_images"]
):
    abort("registered_images cannot exceed database_images")
PY
}

cleanup() {
  local status=$?
  local rollback_failed=false
  trap - EXIT

  if [[ "${COMPLETED}" != "true" ]]; then
    if [[ "${BACKUP_ACTIVE}" == "true" && -e "${BACKUP_PATH}" ]]; then
      if [[ -e "${DESTINATION_PATH}" || -L "${DESTINATION_PATH}" ]]; then
        safe_remove_tree "${DESTINATION_PATH}" || rollback_failed=true
      fi
      if [[ ! -e "${DESTINATION_PATH}" && ! -L "${DESTINATION_PATH}" ]]; then
        mv "${BACKUP_PATH}" "${DESTINATION_PATH}" || rollback_failed=true
      fi
    elif [[ "${DESTINATION_INSTALLED}" == "true" \
        && ( -e "${DESTINATION_PATH}" || -L "${DESTINATION_PATH}" ) ]]; then
      safe_remove_tree "${DESTINATION_PATH}" || rollback_failed=true
    fi
  fi

  if [[ -n "${CANDIDATE_PATH}" && ( -e "${CANDIDATE_PATH}" || -L "${CANDIDATE_PATH}" ) ]]; then
    safe_remove_tree "${CANDIDATE_PATH}" || rollback_failed=true
  fi
  if [[ -n "${STAGING_DIR}" && -d "${STAGING_DIR}" ]]; then
    safe_remove_tree "${STAGING_DIR}" || rollback_failed=true
  fi

  if [[ "${rollback_failed}" == "true" ]]; then
    echo "ERROR: cleanup or rollback failed; inspect ${SCENES_DIR} and ${TEMP_DIR}" >&2
    exit 1
  fi
  exit "${status}"
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

ARCHIVE_ARGUMENT="${1:-}"
[[ -n "${ARCHIVE_ARGUMENT}" ]] || {
  usage >&2
  exit 2
}
[[ "$#" -eq 1 ]] || fail "expected exactly one archive argument"

WORKSPACE_ROOT="${WORKSPACE_ROOT:-/workspace}"
SCENES_DIR="${SCENES_DIR:-${WORKSPACE_ROOT}/scenes}"
LOGS_DIR="${LOGS_DIR:-${WORKSPACE_ROOT}/logs}"
OUTPUTS_DIR="${OUTPUTS_DIR:-${WORKSPACE_ROOT}/outputs}"
CHECKPOINTS_DIR="${CHECKPOINTS_DIR:-${WORKSPACE_ROOT}/checkpoints}"
TEMP_DIR="${TEMP_DIR:-${WORKSPACE_ROOT}/temp}"
OVERWRITE="${OVERWRITE:-false}"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PYTHON_BIN="$(select_python)"

case "${OVERWRITE}" in
  true|false) ;;
  *) fail "OVERWRITE must be true or false, got: ${OVERWRITE}" ;;
esac

[[ -f "${ARCHIVE_ARGUMENT}" && -s "${ARCHIVE_ARGUMENT}" ]] \
  || fail "archive is missing or empty: ${ARCHIVE_ARGUMENT}"
[[ ! -L "${ARCHIVE_ARGUMENT}" ]] || fail "archive must not be a symlink: ${ARCHIVE_ARGUMENT}"

ARCHIVE_DIR="$(cd -- "$(dirname -- "${ARCHIVE_ARGUMENT}")" && pwd -P)" \
  || fail "could not resolve archive directory: ${ARCHIVE_ARGUMENT}"
ARCHIVE_NAME="$(basename -- "${ARCHIVE_ARGUMENT}")"
ARCHIVE_PATH="${ARCHIVE_DIR}/${ARCHIVE_NAME}"
ARCHIVE_SUFFIX="-surveyor-scene.tar.gz"
[[ "${ARCHIVE_NAME}" == *"${ARCHIVE_SUFFIX}" ]] \
  || fail "archive filename must match <scene>-surveyor-scene.tar.gz: ${ARCHIVE_NAME}"
EXPECTED_SCENE="${ARCHIVE_NAME%${ARCHIVE_SUFFIX}}"
[[ -n "${EXPECTED_SCENE}" && "${EXPECTED_SCENE}" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]] \
  || fail "archive contains an invalid scene name: ${EXPECTED_SCENE}"

CHECKSUM_NAME="${ARCHIVE_NAME}.sha256"
CHECKSUM_PATH="${ARCHIVE_DIR}/${CHECKSUM_NAME}"
[[ -f "${CHECKSUM_PATH}" && -s "${CHECKSUM_PATH}" ]] \
  || fail "checksum is missing or empty: ${CHECKSUM_PATH}"
[[ ! -L "${CHECKSUM_PATH}" ]] || fail "checksum must not be a symlink: ${CHECKSUM_PATH}"

verify_checksum_record "${ARCHIVE_DIR}" "${ARCHIVE_NAME}" "${CHECKSUM_NAME}"
SCENE_NAME="$(inspect_or_extract_archive inspect "${ARCHIVE_PATH}" "${EXPECTED_SCENE}")"

DESTINATION_PATH="${SCENES_DIR}/${SCENE_NAME}"
[[ "${DESTINATION_PATH}" == "${SCENES_DIR}/"* && "${DESTINATION_PATH}" != "${SCENES_DIR}/" ]] \
  || fail "unsafe scene destination: ${DESTINATION_PATH}"
if [[ ( -e "${DESTINATION_PATH}" || -L "${DESTINATION_PATH}" ) && "${OVERWRITE}" != "true" ]]; then
  fail "scene already exists: ${DESTINATION_PATH}"
fi
if [[ -L "${DESTINATION_PATH}" ]]; then
  fail "existing scene destination must not be a symlink: ${DESTINATION_PATH}"
fi

mkdir -p "${SCENES_DIR}" "${LOGS_DIR}" "${OUTPUTS_DIR}" "${CHECKPOINTS_DIR}" "${TEMP_DIR}"

STAGING_DIR=""
CANDIDATE_PATH=""
BACKUP_PATH=""
BACKUP_ACTIVE=false
DESTINATION_INSTALLED=false
COMPLETED=false
trap cleanup EXIT

STAGING_DIR="$(mktemp -d "${TEMP_DIR}/${SCENE_NAME}-trainer-import.XXXXXX")"
inspect_or_extract_archive extract "${ARCHIVE_PATH}" "${SCENE_NAME}" "${STAGING_DIR}" >/dev/null
STAGED_SCENE_PATH="${STAGING_DIR}/${SCENE_NAME}"

[[ -d "${STAGED_SCENE_PATH}/images" ]] \
  || fail "COLMAP contract missing images directory: ${STAGED_SCENE_PATH}/images"
for name in cameras images points3D; do
  [[ -f "${STAGED_SCENE_PATH}/sparse/0/${name}.bin" \
      && -s "${STAGED_SCENE_PATH}/sparse/0/${name}.bin" ]] \
    || fail "COLMAP contract missing or empty: ${STAGED_SCENE_PATH}/sparse/0/${name}.bin"
done
MANIFEST_PATH="${STAGED_SCENE_PATH}/surveyor-manifest.json"
[[ -f "${MANIFEST_PATH}" && -s "${MANIFEST_PATH}" ]] \
  || fail "manifest is missing or empty: ${MANIFEST_PATH}"
validate_manifest "${MANIFEST_PATH}" "${SCENE_NAME}"

CANDIDATE_PATH="${SCENES_DIR}/.${SCENE_NAME}.preparing.$$"
BACKUP_PATH="${SCENES_DIR}/.${SCENE_NAME}.backup.$$"
[[ ! -e "${CANDIDATE_PATH}" && ! -L "${CANDIDATE_PATH}" ]] \
  || fail "temporary scene candidate already exists: ${CANDIDATE_PATH}"
[[ ! -e "${BACKUP_PATH}" && ! -L "${BACKUP_PATH}" ]] \
  || fail "temporary scene backup already exists: ${BACKUP_PATH}"

mv "${STAGED_SCENE_PATH}" "${CANDIDATE_PATH}"
if [[ -e "${DESTINATION_PATH}" ]]; then
  mv "${DESTINATION_PATH}" "${BACKUP_PATH}"
  BACKUP_ACTIVE=true
fi
mv "${CANDIDATE_PATH}" "${DESTINATION_PATH}"
DESTINATION_INSTALLED=true

TRAIN_SCENE_PATH="${TRAIN_SCENE_PATH:-}"
if [[ -z "${TRAIN_SCENE_PATH}" ]]; then
  if command -v train-scene.sh >/dev/null 2>&1; then
    TRAIN_SCENE_PATH="$(command -v train-scene.sh)"
  else
    TRAIN_SCENE_PATH="${SCRIPT_DIR}/train-scene.sh"
  fi
fi
[[ -x "${TRAIN_SCENE_PATH}" ]] || fail "train-scene.sh command is not executable: ${TRAIN_SCENE_PATH}"

CHECK_OUTPUT="${STAGING_DIR}/train-scene-check.out"
if ! SCENE_PATH="${DESTINATION_PATH}" \
  OUTPUT_PATH="${OUTPUTS_DIR}/${SCENE_NAME}" \
  CHECKPOINT_PATH="${CHECKPOINTS_DIR}/${SCENE_NAME}" \
  LOG_PATH="${LOGS_DIR}/${SCENE_NAME}/train.log" \
  "${TRAIN_SCENE_PATH}" --check "${SCENE_NAME}" > "${CHECK_OUTPUT}" 2>&1; then
  cat "${CHECK_OUTPUT}" >&2
  fail "train-scene.sh --check failed for scene: ${SCENE_NAME}"
fi

if [[ "${BACKUP_ACTIVE}" == "true" ]]; then
  safe_remove_tree "${BACKUP_PATH}"
  BACKUP_ACTIVE=false
fi
COMPLETED=true

echo "Escena preparada correctamente."
echo "Scene: ${SCENE_NAME}"
echo "Path: ${DESTINATION_PATH}"
echo "Checksum: OK"
cat "${CHECK_OUTPUT}"
echo
echo "Siguiente comando:"
echo "  MAX_STEPS=<qtysteps> train-scene.sh ${SCENE_NAME}"
