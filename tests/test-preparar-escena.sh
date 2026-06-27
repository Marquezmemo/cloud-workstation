#!/usr/bin/env bash
set -euo pipefail

# Purpose: Exercise transactional ZIP preparation, metadata filtering, and failures.
# Input:   preparar-escena available in PATH or under the repository scripts/.
# Output:  Test names and a final success marker on stdout.

fail() {
  echo "TEST ERROR: $*" >&2
  exit 1
}

cleanup() {
  rm -rf "${TEST_ROOT}"
}

resolve_command() {
  local command_name="$1"
  local repository_root

  if command -v "${command_name}" >/dev/null 2>&1; then
    command -v "${command_name}"
    return
  fi

  repository_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
  [[ -x "${repository_root}/scripts/${command_name}" ]] || fail "missing command: ${command_name}"
  echo "${repository_root}/scripts/${command_name}"
}

create_zip() {
  local archive_path="$1"
  local fixture_type="$2"

  python3 - "${archive_path}" "${fixture_type}" <<'PY'
import sys
import zipfile

archive_path, fixture_type = sys.argv[1:]
fixtures = {
    "macos": {
        "fotos/IMG_001.JPG": b"image-one\n",
        "fotos/IMG_002.png": b"image-two\n",
        "__MACOSX/fotos/._IMG_001.JPG": b"resource-fork\n",
        "fotos/.DS_Store": b"metadata\n",
        "notas.txt": b"ignore me\n",
    },
    "valid": {
        "nested/001.jpg": b"image-one\n",
        "nested/002.jpeg": b"image-two\n",
    },
    "single": {
        "nested/001.jpg": b"image-one\n",
    },
    "collision": {
        "camera-a/IMG_001.JPG": b"image-one\n",
        "camera-b/img_001.jpg": b"image-two\n",
        "camera-b/IMG_002.png": b"image-three\n",
    },
    "traversal": {
        "../escape.jpg": b"unsafe\n",
        "001.jpg": b"image-one\n",
        "002.jpg": b"image-two\n",
    },
}

entries = list(fixtures[fixture_type].items())
with zipfile.ZipFile(archive_path, "w", compression=zipfile.ZIP_DEFLATED) as archive:
    for name, content in entries:
        print(f"fixture_entry={name!r} size={len(content)}")
        archive.writestr(name, content)

supported = {".jpg", ".jpeg", ".png", ".tif", ".tiff"}
with zipfile.ZipFile(archive_path) as archive:
    for info in archive.infolist():
        extension = info.filename.rsplit(".", 1)[-1].casefold()
        is_supported = f".{extension}" in supported
        print(
            f"zip_entry={info.filename!r} size={info.file_size} "
            f"supported_image={str(is_supported).lower()}"
        )
PY
}

expect_failure() {
  local workspace="$1"
  shift

  if WORKSPACE_ROOT="${workspace}" "${PREPARER}" "$@" >"${workspace}/failure.out" 2>&1; then
    fail "preparation unexpectedly passed: $*"
  fi
}

assert_no_preparation_residue() {
  local workspace="$1"

  if [[ -d "${workspace}/temp" ]] && find "${workspace}/temp" -mindepth 1 -print -quit | grep -q .; then
    fail "temporary extraction residue remains under ${workspace}/temp"
  fi
  if [[ -d "${workspace}/incoming" ]] && find "${workspace}/incoming" -maxdepth 1 -name '.*.preparing.*' -print -quit | grep -q .; then
    fail "staging residue remains under ${workspace}/incoming"
  fi
}

print_incoming_tree() {
  local incoming_path="$1"

  echo "incoming_tree_begin"
  if [[ ! -e "${incoming_path}" ]]; then
    echo "missing_incoming_path=${incoming_path}"
  elif find "${incoming_path}" -maxdepth 0 -printf '' >/dev/null 2>&1; then
    find "${incoming_path}" -maxdepth 6 -printf '%y %p\n' | sort
  else
    find "${incoming_path}" -maxdepth 6 -print | sort
  fi
  echo "incoming_tree_end"
}

TEST_ROOT="$(mktemp -d /tmp/preparar-escena-test.XXXXXX)"
trap cleanup EXIT
PREPARER="$(resolve_command preparar-escena)"

echo "test=zip_with_macos_metadata"
MACOS_ROOT="${TEST_ROOT}/macos"
mkdir -p "${MACOS_ROOT}"
ZIP_PATH="${MACOS_ROOT}/prueba.zip"
STDOUT_FILE="${MACOS_ROOT}/preparar.stdout"
STDERR_FILE="${MACOS_ROOT}/preparar.stderr"
EXPECTED_FIRST_IMAGE="${MACOS_ROOT}/incoming/prueba/images/IMG_001.JPG"
EXPECTED_SECOND_IMAGE="${MACOS_ROOT}/incoming/prueba/images/IMG_002.png"

create_zip "${ZIP_PATH}" macos
unzip -l "${ZIP_PATH}"

if WORKSPACE_ROOT="${MACOS_ROOT}" "${PREPARER}" \
    >"${STDOUT_FILE}" 2>"${STDERR_FILE}"; then
  PREPARE_EXIT_CODE=0
else
  PREPARE_EXIT_CODE=$?
fi

echo "prepare_exit_code=${PREPARE_EXIT_CODE}"
echo "prepare_stdout_begin"
cat "${STDOUT_FILE}"
echo "prepare_stdout_end"
echo "prepare_stderr_begin"
cat "${STDERR_FILE}"
echo "prepare_stderr_end"

printf 'expected_image=%q\n' "${EXPECTED_FIRST_IMAGE}"
printf 'expected_image=%q\n' "${EXPECTED_SECOND_IMAGE}"
if [[ -d "$(dirname -- "${EXPECTED_FIRST_IMAGE}")" ]]; then
  ls -lb "$(dirname -- "${EXPECTED_FIRST_IMAGE}")"
else
  echo "missing_expected_directory=$(dirname -- "${EXPECTED_FIRST_IMAGE}")"
fi
print_incoming_tree "${MACOS_ROOT}/incoming"

test "${PREPARE_EXIT_CODE}" -eq 0 || fail "preparar-escena exited with ${PREPARE_EXIT_CODE}"
MACOS_OUTPUT="$(<"${STDOUT_FILE}")"
[[ -f "${MACOS_ROOT}/prueba.zip" ]] || fail "original ZIP was moved"
[[ -f "${EXPECTED_FIRST_IMAGE}" ]] || fail "missing first image"
[[ -f "${EXPECTED_SECOND_IMAGE}" ]] || fail "missing second image"
[[ "$(find "${MACOS_ROOT}/incoming/prueba/images" -type f | wc -l | tr -d ' ')" == "2" ]] || fail "unexpected image count"
[[ ! -e "${MACOS_ROOT}/incoming/prueba/images/._IMG_001.JPG" ]] || fail "macOS resource fork was copied"
[[ ! -e "${MACOS_ROOT}/scenes/prueba" ]] || fail "processed scene was created"
cmp -s "${MACOS_ROOT}/prueba.zip" "${MACOS_ROOT}/incoming/prueba/source/prueba.zip" || fail "saved ZIP differs"
grep -q '^Escena: prueba$' <<< "${MACOS_OUTPUT}" || fail "missing scene success message"
grep -q '^Imágenes encontradas: 2$' <<< "${MACOS_OUTPUT}" || fail "missing image count message"
grep -q '^  survey-scene.sh prueba$' <<< "${MACOS_OUTPUT}" || fail "missing next-command hint"

echo "test=no_zip"
NO_ZIP_ROOT="${TEST_ROOT}/no-zip"
mkdir -p "${NO_ZIP_ROOT}"
expect_failure "${NO_ZIP_ROOT}"
grep -q 'no se encontró ningún archivo .zip' "${NO_ZIP_ROOT}/failure.out" || fail "missing no-ZIP error"

echo "test=multiple_zips"
MULTIPLE_ROOT="${TEST_ROOT}/multiple"
mkdir -p "${MULTIPLE_ROOT}"
create_zip "${MULTIPLE_ROOT}/one.zip" valid
create_zip "${MULTIPLE_ROOT}/two.zip" valid
expect_failure "${MULTIPLE_ROOT}"
grep -q 'one.zip' "${MULTIPLE_ROOT}/failure.out" || fail "first ZIP was not listed"
grep -q 'two.zip' "${MULTIPLE_ROOT}/failure.out" || fail "second ZIP was not listed"

echo "test=corrupt_zip"
CORRUPT_ROOT="${TEST_ROOT}/corrupt"
mkdir -p "${CORRUPT_ROOT}"
printf 'not-a-zip\n' > "${CORRUPT_ROOT}/corrupt.zip"
expect_failure "${CORRUPT_ROOT}" "${CORRUPT_ROOT}/corrupt.zip"
[[ ! -e "${CORRUPT_ROOT}/incoming/corrupt" ]] || fail "corrupt ZIP left a partial scene"

echo "test=insufficient_images"
SINGLE_ROOT="${TEST_ROOT}/single"
mkdir -p "${SINGLE_ROOT}"
create_zip "${SINGLE_ROOT}/single.zip" single
expect_failure "${SINGLE_ROOT}" "${SINGLE_ROOT}/single.zip"
[[ ! -e "${SINGLE_ROOT}/incoming/single" ]] || fail "single image left a partial scene"
assert_no_preparation_residue "${SINGLE_ROOT}"

echo "test=case_insensitive_collision"
COLLISION_ROOT="${TEST_ROOT}/collision"
mkdir -p "${COLLISION_ROOT}"
create_zip "${COLLISION_ROOT}/collision.zip" collision
expect_failure "${COLLISION_ROOT}" "${COLLISION_ROOT}/collision.zip"
grep -q 'colisión al aplanar imágenes' "${COLLISION_ROOT}/failure.out" || fail "missing collision error"
[[ ! -e "${COLLISION_ROOT}/incoming/collision" ]] || fail "collision left a partial scene"
assert_no_preparation_residue "${COLLISION_ROOT}"

echo "test=existing_incoming_scene"
EXISTING_ROOT="${TEST_ROOT}/existing"
mkdir -p "${EXISTING_ROOT}/incoming/existing"
printf 'keep\n' > "${EXISTING_ROOT}/incoming/existing/marker"
create_zip "${EXISTING_ROOT}/existing.zip" valid
expect_failure "${EXISTING_ROOT}" "${EXISTING_ROOT}/existing.zip"
grep -qx 'keep' "${EXISTING_ROOT}/incoming/existing/marker" || fail "existing scene was modified"

echo "test=existing_processed_scene"
PROCESSED_ROOT="${TEST_ROOT}/processed"
mkdir -p "${PROCESSED_ROOT}/scenes/processed"
printf 'keep\n' > "${PROCESSED_ROOT}/scenes/processed/marker"
create_zip "${PROCESSED_ROOT}/processed.zip" valid
expect_failure "${PROCESSED_ROOT}" "${PROCESSED_ROOT}/processed.zip"
grep -qx 'keep' "${PROCESSED_ROOT}/scenes/processed/marker" || fail "processed scene was modified"
[[ ! -e "${PROCESSED_ROOT}/incoming/processed" ]] || fail "incoming scene was created beside processed scene"

echo "test=unsafe_archive_path"
TRAVERSAL_ROOT="${TEST_ROOT}/traversal"
mkdir -p "${TRAVERSAL_ROOT}"
create_zip "${TRAVERSAL_ROOT}/traversal.zip" traversal
expect_failure "${TRAVERSAL_ROOT}" "${TRAVERSAL_ROOT}/traversal.zip"
[[ ! -e "${TRAVERSAL_ROOT}/escape.jpg" ]] || fail "unsafe archive escaped extraction root"
[[ ! -e "${TRAVERSAL_ROOT}/incoming/traversal" ]] || fail "unsafe archive left a partial scene"

echo "preparar_escena_tests=passed"
