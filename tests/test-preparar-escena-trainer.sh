#!/usr/bin/env bash
set -euo pipefail

# Regression suite for the Trainer-side Surveyor package importer.
# Runs entirely in temporary local workspaces and does not require a GPU.

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
SUBJECT="${REPO_ROOT}/scripts/preparar-escena-trainer.sh"
TRAIN_SCENE="${REPO_ROOT}/scripts/train-scene.sh"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/test-preparar-escena.XXXXXX")"
PASS_COUNT=0

cleanup() {
  rm -rf "${TEST_ROOT}"
}
trap cleanup EXIT

pass() {
  PASS_COUNT=$((PASS_COUNT + 1))
  echo "PASS: $1"
}

fail_test() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_contains() {
  local content="$1"
  local expected="$2"
  grep -Fq -- "${expected}" <<< "${content}" \
    || fail_test "expected output to contain: ${expected}"
}

assert_exists() {
  local path="$1"
  [[ -e "${path}" || -L "${path}" ]] || fail_test "expected path to exist: ${path}"
}

assert_not_exists() {
  local path="$1"
  [[ ! -e "${path}" && ! -L "${path}" ]] || fail_test "expected path not to exist: ${path}"
}

hash_file() {
  local path="$1"
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "${path}" | awk '{print $1}'
  else
    shasum -a 256 "${path}" | awk '{print $1}'
  fi
}

write_checksum() {
  local archive="$1"
  local archive_dir
  local archive_name
  archive_dir="$(dirname "${archive}")"
  archive_name="$(basename "${archive}")"

  if command -v sha256sum >/dev/null 2>&1; then
    (cd "${archive_dir}" && sha256sum "${archive_name}" > "${archive_name}.sha256")
  else
    (cd "${archive_dir}" && shasum -a 256 "${archive_name}" > "${archive_name}.sha256")
  fi
}

make_scene_tree() {
  local parent="$1"
  local root_scene="$2"
  local manifest_scene="${3:-${root_scene}}"
  local sparse_path="${4:-/workspace/scenes/${root_scene}/sparse/0}"
  local scene_dir="${parent}/${root_scene}"

  mkdir -p "${scene_dir}/images" "${scene_dir}/sparse/0"
  printf 'image-01\n' > "${scene_dir}/images/image01.jpg"
  printf 'image-02\n' > "${scene_dir}/images/image02.jpg"
  printf 'camera-data\n' > "${scene_dir}/sparse/0/cameras.bin"
  printf 'image-data\n' > "${scene_dir}/sparse/0/images.bin"
  printf 'points-data\n' > "${scene_dir}/sparse/0/points3D.bin"
  cat > "${scene_dir}/surveyor-manifest.json" <<EOF
{
  "scene": "${manifest_scene}",
  "trainer_ready_sparse_path": "${sparse_path}",
  "registered_images": 2,
  "database_images": 2
}
EOF
}

make_archive() {
  local case_dir="$1"
  local filename_scene="$2"
  local root_scene="${3:-${filename_scene}}"
  local manifest_scene="${4:-${root_scene}}"
  local sparse_path="${5:-/workspace/scenes/${root_scene}/sparse/0}"
  local fixture_dir="${case_dir}/fixture"
  local package_dir="${case_dir}/packages"
  local archive="${package_dir}/${filename_scene}-surveyor-scene.tar.gz"

  mkdir -p "${fixture_dir}" "${package_dir}"
  make_scene_tree "${fixture_dir}" "${root_scene}" "${manifest_scene}" "${sparse_path}"
  COPYFILE_DISABLE=1 tar -C "${fixture_dir}" -czf "${archive}" "${root_scene}"
  write_checksum "${archive}"
  printf '%s\n' "${archive}"
}

run_import() {
  local workspace="$1"
  local archive="$2"
  shift 2
  WORKSPACE_ROOT="${workspace}" TRAIN_SCENE_PATH="${TRAIN_SCENE}" "$@" "${SUBJECT}" "${archive}"
}

expect_failure() {
  local expected_message="$1"
  shift
  local output
  local rc

  set +e
  output="$("$@" 2>&1)"
  rc=$?
  set -e
  [[ "${rc}" -ne 0 ]] || fail_test "command unexpectedly succeeded"
  assert_contains "${output}" "${expected_message}"
  printf '%s\n' "${output}"
}

test_help_and_missing_argument() {
  "${SUBJECT}" --help | grep -Fq 'preparar-escena <surveyor-scene.tar.gz>'

  local output
  local rc
  set +e
  output="$("${SUBJECT}" 2>&1)"
  rc=$?
  set -e
  [[ "${rc}" -eq 2 ]] || fail_test "missing argument should exit 2, got ${rc}"
  assert_contains "${output}" 'preparar-escena <surveyor-scene.tar.gz>'
  pass "help and required argument"
}

test_success() {
  local case_dir="${TEST_ROOT}/success"
  local workspace="${case_dir}/workspace"
  local archive
  local archive_hash_before
  local checksum_hash_before
  local output

  archive="$(make_archive "${case_dir}" Prueba02)"
  archive_hash_before="$(hash_file "${archive}")"
  checksum_hash_before="$(hash_file "${archive}.sha256")"
  output="$(run_import "${workspace}" "${archive}" env)"

  assert_contains "${output}" 'Escena preparada correctamente.'
  assert_contains "${output}" 'Scene: Prueba02'
  assert_contains "${output}" 'Dataset paths look ready for simple_trainer.py.'
  assert_contains "${output}" 'MAX_STEPS=<qtysteps> train-scene.sh Prueba02'
  assert_exists "${workspace}/scenes/Prueba02/images/image01.jpg"
  assert_exists "${workspace}/scenes/Prueba02/sparse/0/points3D.bin"
  [[ "$(basename "$(find "${workspace}/scenes" -mindepth 1 -maxdepth 1 -type d -print -quit)")" == "Prueba02" ]] \
    || fail_test "scene directory did not preserve exact capitalization"
  grep -qx 'dataset_check=passed' "${workspace}/logs/Prueba02/run.summary"
  [[ "$(hash_file "${archive}")" == "${archive_hash_before}" ]] \
    || fail_test "source archive changed after success"
  [[ "$(hash_file "${archive}.sha256")" == "${checksum_hash_before}" ]] \
    || fail_test "source checksum changed after success"

  printf '%s\n' "${output}" > "${TEST_ROOT}/successful-output.txt"
  pass "successful import with productive train-scene.sh --check"
}

test_missing_archive() {
  local workspace="${TEST_ROOT}/missing-archive/workspace"
  expect_failure 'archive is missing or empty' \
    env WORKSPACE_ROOT="${workspace}" TRAIN_SCENE_PATH="${TRAIN_SCENE}" \
    "${SUBJECT}" "${TEST_ROOT}/missing-archive/NoExiste-surveyor-scene.tar.gz" >/dev/null
  pass "missing archive"
}

test_missing_checksum() {
  local case_dir="${TEST_ROOT}/missing-checksum"
  local archive
  archive="$(make_archive "${case_dir}" Prueba02)"
  rm "${archive}.sha256"
  expect_failure 'checksum is missing or empty' \
    env WORKSPACE_ROOT="${case_dir}/workspace" TRAIN_SCENE_PATH="${TRAIN_SCENE}" \
    "${SUBJECT}" "${archive}" >/dev/null
  assert_exists "${archive}"
  pass "missing checksum"
}

test_bad_checksum() {
  local case_dir="${TEST_ROOT}/bad-checksum"
  local archive
  local archive_hash_before
  archive="$(make_archive "${case_dir}" Prueba02)"
  archive_hash_before="$(hash_file "${archive}")"
  printf '%064d  %s\n' 0 "$(basename "${archive}")" > "${archive}.sha256"

  expect_failure 'checksum verification failed' \
    env WORKSPACE_ROOT="${case_dir}/workspace" TRAIN_SCENE_PATH="${TRAIN_SCENE}" \
    "${SUBJECT}" "${archive}" >/dev/null
  assert_not_exists "${case_dir}/workspace/scenes/Prueba02"
  [[ "$(hash_file "${archive}")" == "${archive_hash_before}" ]] \
    || fail_test "source archive changed after checksum failure"
  assert_exists "${archive}.sha256"
  pass "incorrect checksum fails before extraction"
}

make_malicious_archive() {
  local archive="$1"
  local member_name="$2"
  mkdir -p "$(dirname "${archive}")"
  python3 - "${archive}" "${member_name}" <<'PY'
import io
import sys
import tarfile

archive_path, member_name = sys.argv[1:]
payload = b"escape"
with tarfile.open(archive_path, "w:gz") as archive:
    member = tarfile.TarInfo(member_name)
    member.size = len(payload)
    archive.addfile(member, io.BytesIO(payload))
PY
  write_checksum "${archive}"
}

test_unsafe_paths() {
  local case_dir="${TEST_ROOT}/unsafe-paths"
  local traversal_archive="${case_dir}/packages/Traversal-surveyor-scene.tar.gz"
  local absolute_archive="${case_dir}/packages/Absolute-surveyor-scene.tar.gz"

  make_malicious_archive "${traversal_archive}" '../escape'
  expect_failure 'tar contains an unsafe path' \
    env WORKSPACE_ROOT="${case_dir}/traversal-workspace" TRAIN_SCENE_PATH="${TRAIN_SCENE}" \
    "${SUBJECT}" "${traversal_archive}" >/dev/null
  assert_not_exists "${case_dir}/escape"

  make_malicious_archive "${absolute_archive}" '/absolute/path'
  expect_failure 'tar contains an absolute path' \
    env WORKSPACE_ROOT="${case_dir}/absolute-workspace" TRAIN_SCENE_PATH="${TRAIN_SCENE}" \
    "${SUBJECT}" "${absolute_archive}" >/dev/null
  pass "path traversal and absolute paths"
}

test_multiple_roots() {
  local case_dir="${TEST_ROOT}/multiple-roots"
  local fixture="${case_dir}/fixture"
  local archive="${case_dir}/packages/SceneA-surveyor-scene.tar.gz"
  mkdir -p "${fixture}/SceneA" "${fixture}/SceneB" "$(dirname "${archive}")"
  printf 'a\n' > "${fixture}/SceneA/file"
  printf 'b\n' > "${fixture}/SceneB/file"
  COPYFILE_DISABLE=1 tar -C "${fixture}" -czf "${archive}" SceneA SceneB
  write_checksum "${archive}"

  expect_failure 'tar must contain exactly one root scene directory' \
    env WORKSPACE_ROOT="${case_dir}/workspace" TRAIN_SCENE_PATH="${TRAIN_SCENE}" \
    "${SUBJECT}" "${archive}" >/dev/null
  pass "multiple archive roots"
}

test_filename_root_mismatch() {
  local case_dir="${TEST_ROOT}/name-mismatch"
  local archive
  archive="$(make_archive "${case_dir}" Prueba02 OtraEscena)"
  expect_failure 'archive scene name mismatch: filename=Prueba02, root=OtraEscena' \
    env WORKSPACE_ROOT="${case_dir}/workspace" TRAIN_SCENE_PATH="${TRAIN_SCENE}" \
    "${SUBJECT}" "${archive}" >/dev/null
  pass "filename and root mismatch"
}

test_invalid_manifest() {
  local case_dir="${TEST_ROOT}/invalid-manifest"
  local archive
  archive="$(make_archive "${case_dir}" Prueba02)"
  printf '{broken-json\n' > "${case_dir}/fixture/Prueba02/surveyor-manifest.json"
  COPYFILE_DISABLE=1 tar -C "${case_dir}/fixture" -czf "${archive}" Prueba02
  write_checksum "${archive}"

  expect_failure 'manifest is not valid JSON' \
    env WORKSPACE_ROOT="${case_dir}/workspace" TRAIN_SCENE_PATH="${TRAIN_SCENE}" \
    "${SUBJECT}" "${archive}" >/dev/null
  pass "invalid manifest JSON"
}

test_manifest_scene_mismatch() {
  local case_dir="${TEST_ROOT}/manifest-scene-mismatch"
  local archive
  archive="$(make_archive "${case_dir}" Prueba02 Prueba02 OtraEscena)"
  expect_failure 'manifest scene mismatch' \
    env WORKSPACE_ROOT="${case_dir}/workspace" TRAIN_SCENE_PATH="${TRAIN_SCENE}" \
    "${SUBJECT}" "${archive}" >/dev/null
  pass "manifest scene mismatch"
}

test_manifest_optional_contract() {
  local path_case="${TEST_ROOT}/manifest-sparse-path"
  local count_case="${TEST_ROOT}/manifest-counts"
  local path_archive
  local count_archive

  path_archive="$(make_archive \
    "${path_case}" Prueba02 Prueba02 Prueba02 /unsafe/scenes/Prueba02/sparse/0)"
  expect_failure 'manifest trainer_ready_sparse_path must end with' \
    env WORKSPACE_ROOT="${path_case}/workspace" TRAIN_SCENE_PATH="${TRAIN_SCENE}" \
    "${SUBJECT}" "${path_archive}" >/dev/null

  count_archive="$(make_archive "${count_case}" Prueba02)"
  "$(command -v python3)" - "${count_case}/fixture/Prueba02/surveyor-manifest.json" <<'PY'
import json
import sys

path = sys.argv[1]
with open(path, "r", encoding="utf-8") as handle:
    manifest = json.load(handle)
manifest["registered_images"] = 3
manifest["database_images"] = 2
with open(path, "w", encoding="utf-8") as handle:
    json.dump(manifest, handle)
PY
  COPYFILE_DISABLE=1 tar -C "${count_case}/fixture" -czf "${count_archive}" Prueba02
  write_checksum "${count_archive}"
  expect_failure 'manifest registered_images cannot exceed database_images' \
    env WORKSPACE_ROOT="${count_case}/workspace" TRAIN_SCENE_PATH="${TRAIN_SCENE}" \
    "${SUBJECT}" "${count_archive}" >/dev/null
  pass "optional manifest handoff fields"
}

test_incomplete_colmap() {
  local case_dir="${TEST_ROOT}/incomplete-colmap"
  local archive
  archive="$(make_archive "${case_dir}" Prueba02)"
  rm "${case_dir}/fixture/Prueba02/sparse/0/points3D.bin"
  COPYFILE_DISABLE=1 tar -C "${case_dir}/fixture" -czf "${archive}" Prueba02
  write_checksum "${archive}"

  expect_failure 'COLMAP contract missing or empty' \
    env WORKSPACE_ROOT="${case_dir}/workspace" TRAIN_SCENE_PATH="${TRAIN_SCENE}" \
    "${SUBJECT}" "${archive}" >/dev/null
  pass "incomplete COLMAP structure"
}

test_existing_destination() {
  local case_dir="${TEST_ROOT}/existing-destination"
  local workspace="${case_dir}/workspace"
  local archive
  archive="$(make_archive "${case_dir}" Prueba02)"
  mkdir -p "${workspace}/scenes/Prueba02"
  printf 'original\n' > "${workspace}/scenes/Prueba02/original.marker"

  expect_failure "scene already exists: ${workspace}/scenes/Prueba02" \
    env WORKSPACE_ROOT="${workspace}" TRAIN_SCENE_PATH="${TRAIN_SCENE}" \
    "${SUBJECT}" "${archive}" >/dev/null
  assert_exists "${workspace}/scenes/Prueba02/original.marker"
  pass "existing destination without overwrite"
}

test_overwrite_success() {
  local case_dir="${TEST_ROOT}/overwrite-success"
  local workspace="${case_dir}/workspace"
  local archive
  archive="$(make_archive "${case_dir}" Prueba02)"
  mkdir -p "${workspace}/scenes/Prueba02"
  printf 'original\n' > "${workspace}/scenes/Prueba02/original.marker"

  OVERWRITE=true run_import "${workspace}" "${archive}" env >/dev/null
  assert_not_exists "${workspace}/scenes/Prueba02/original.marker"
  assert_exists "${workspace}/scenes/Prueba02/images/image02.jpg"
  pass "safe overwrite after complete validation"
}

test_overwrite_rollback() {
  local case_dir="${TEST_ROOT}/overwrite-rollback"
  local workspace="${case_dir}/workspace"
  local archive
  local failing_trainer="${case_dir}/fail-train-check.sh"
  archive="$(make_archive "${case_dir}" Prueba02)"
  mkdir -p "${workspace}/scenes/Prueba02"
  printf 'original\n' > "${workspace}/scenes/Prueba02/original.marker"
  cat > "${failing_trainer}" <<'EOF'
#!/usr/bin/env bash
echo "simulated train-scene check failure" >&2
exit 77
EOF
  chmod +x "${failing_trainer}"

  expect_failure 'train-scene.sh --check failed for scene: Prueba02' \
    env OVERWRITE=true WORKSPACE_ROOT="${workspace}" TRAIN_SCENE_PATH="${failing_trainer}" \
    "${SUBJECT}" "${archive}" >/dev/null
  assert_exists "${workspace}/scenes/Prueba02/original.marker"
  assert_not_exists "${workspace}/scenes/Prueba02/images/image01.jpg"
  pass "overwrite rollback on train-scene check failure"
}

test_help_and_missing_argument
test_success
test_missing_archive
test_missing_checksum
test_bad_checksum
test_unsafe_paths
test_multiple_roots
test_filename_root_mismatch
test_invalid_manifest
test_manifest_scene_mismatch
test_manifest_optional_contract
test_incomplete_colmap
test_existing_destination
test_overwrite_success
test_overwrite_rollback

echo "All ${PASS_COUNT} preparar-escena tests passed."
echo "Successful case output:"
cat "${TEST_ROOT}/successful-output.txt"
