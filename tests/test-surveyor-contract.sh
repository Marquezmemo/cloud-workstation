#!/usr/bin/env bash
set -euo pipefail

# Purpose: Exercise Surveyor contract validation and portable packaging locally.
# Input:   Production scripts available in PATH or under the repository scripts/.
# Output:  Test results on stdout; all fixtures are isolated under a temporary path.

fail() {
  echo "TEST ERROR: $*" >&2
  exit 1
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

expect_validation_failure() {
  local scene_name="$1"
  local scene_path="$2"
  local log_dir="$3"

  if WORKSPACE_ROOT="${TEST_ROOT}" SCENE_PATH="${scene_path}" LOG_DIR="${log_dir}" \
    "${VALIDATOR}" "${scene_name}" >/dev/null 2>&1; then
    fail "validation unexpectedly passed for ${scene_name}"
  fi
}

create_valid_fixture() {
  local scene_name="$1"
  local scene_path="${TEST_ROOT}/scenes/${scene_name}"
  local log_dir="${TEST_ROOT}/logs/${scene_name}"

  mkdir -p "${scene_path}/images" "${scene_path}/sparse/0" "${log_dir}"
  printf 'image-one\n' > "${scene_path}/images/001.jpg"
  printf 'image-two\n' > "${scene_path}/images/002.jpg"
  printf 'camera-model\n' > "${scene_path}/sparse/0/cameras.bin"
  printf 'registered-images\n' > "${scene_path}/sparse/0/images.bin"
  printf 'sparse-points\n' > "${scene_path}/sparse/0/points3D.bin"

  sqlite3 "${scene_path}/database.db" <<'SQL'
CREATE TABLE images(image_id INTEGER PRIMARY KEY, name TEXT NOT NULL);
INSERT INTO images(name) VALUES ('001.jpg'), ('002.jpg');
SQL

  jq -n \
    --arg scene "${scene_name}" \
    '{
      schema: "cloud-workstation.surveyor.v0.1",
      scene: $scene,
      created_at: "2026-01-01T00:00:00Z",
      image_count: 2,
      database_images: 2,
      matcher: "exhaustive",
      colmap_use_gpu: "0",
      single_camera: "1",
      camera_model: "OPENCV",
      scene_path: "/workspace/scenes/test",
      trainer_ready_sparse_path: "/workspace/scenes/test/sparse/0"
    }' > "${scene_path}/surveyor-manifest.json"

  for log_name in \
    surveyor.env \
    colmap-feature.log \
    colmap-match.log \
    colmap-mapper.log \
    model-analyzer.txt; do
    printf '%s=synthetic\n' "${log_name}" > "${log_dir}/${log_name}"
  done
  printf 'status=success\n' > "${log_dir}/surveyor.summary"
}

TEST_ROOT="$(mktemp -d /tmp/surveyor-contract-test.XXXXXX)"
trap 'rm -rf "${TEST_ROOT}"' EXIT

VALIDATOR="$(resolve_command validate-surveyor-scene.sh)"
PACKAGER="$(resolve_command package-surveyor-scene.sh)"

echo "test=valid_scene"
create_valid_fixture valid
WORKSPACE_ROOT="${TEST_ROOT}" "${VALIDATOR}" valid >/dev/null

echo "test=portable_packages"
WORKSPACE_ROOT="${TEST_ROOT}" "${PACKAGER}" valid >/dev/null
TRANSFER_DIR="${TEST_ROOT}/transfer"
mkdir -p "${TRANSFER_DIR}"
cp "${TEST_ROOT}/archives/valid/"* "${TRANSFER_DIR}/"
(
  cd "${TRANSFER_DIR}"
  sha256sum -c valid-surveyor-scene.tar.gz.sha256 >/dev/null
  sha256sum -c valid-surveyor-evidence.tar.gz.sha256 >/dev/null
)
grep -q '^valid/database.db$' < <(tar -tzf "${TRANSFER_DIR}/valid-surveyor-scene.tar.gz")
grep -q '^valid-surveyor-evidence/logs/model-analyzer.txt$' \
  < <(tar -tzf "${TRANSFER_DIR}/valid-surveyor-evidence.tar.gz")
grep -q '^valid-surveyor-evidence/surveyor-manifest.json$' \
  < <(tar -tzf "${TRANSFER_DIR}/valid-surveyor-evidence.tar.gz")

echo "test=gpu_evidence"
create_valid_fixture gpu-evidence
jq '.colmap_use_gpu = "1"' \
  "${TEST_ROOT}/scenes/gpu-evidence/surveyor-manifest.json" \
  > "${TEST_ROOT}/scenes/gpu-evidence/surveyor-manifest.json.tmp"
mv \
  "${TEST_ROOT}/scenes/gpu-evidence/surveyor-manifest.json.tmp" \
  "${TEST_ROOT}/scenes/gpu-evidence/surveyor-manifest.json"
{
  echo 'timestamp,index,name,utilization_gpu_percent,memory_used_mib'
  echo '2026/01/01 00:00:00.000, 0, Test GPU, 25, 512'
} > "${TEST_ROOT}/logs/gpu-evidence/surveyor-gpu.log"
WORKSPACE_ROOT="${TEST_ROOT}" "${VALIDATOR}" gpu-evidence >/dev/null

echo "test=missing_database"
create_valid_fixture missing-database
rm "${TEST_ROOT}/scenes/missing-database/database.db"
expect_validation_failure missing-database "${TEST_ROOT}/scenes/missing-database" "${TEST_ROOT}/logs/missing-database"

echo "test=invalid_manifest"
create_valid_fixture invalid-manifest
printf '{invalid-json\n' > "${TEST_ROOT}/scenes/invalid-manifest/surveyor-manifest.json"
expect_validation_failure invalid-manifest "${TEST_ROOT}/scenes/invalid-manifest" "${TEST_ROOT}/logs/invalid-manifest"

echo "test=missing_manifest"
create_valid_fixture missing-manifest
rm "${TEST_ROOT}/scenes/missing-manifest/surveyor-manifest.json"
expect_validation_failure missing-manifest "${TEST_ROOT}/scenes/missing-manifest" "${TEST_ROOT}/logs/missing-manifest"

echo "test=empty_sparse_model"
create_valid_fixture empty-model
: > "${TEST_ROOT}/scenes/empty-model/sparse/0/points3D.bin"
expect_validation_failure empty-model "${TEST_ROOT}/scenes/empty-model" "${TEST_ROOT}/logs/empty-model"

echo "test=empty_images"
create_valid_fixture empty-images
: > "${TEST_ROOT}/scenes/empty-images/images/001.jpg"
expect_validation_failure empty-images "${TEST_ROOT}/scenes/empty-images" "${TEST_ROOT}/logs/empty-images"

echo "surveyor_contract_tests=passed"
