#!/usr/bin/env bash
set -euo pipefail

# Purpose: Exercise the production survey-scene.sh manifest generation path with COLMAP stubbed.
# Input:   Production survey-scene.sh available in PATH or under repository scripts/.
# Output:  Manifest regression result on stdout; all fixtures remain under a temporary path.

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

cleanup() {
  rm -rf "${TEST_ROOT}"
}

TEST_ROOT="$(mktemp -d /tmp/survey-scene-manifest-test.XXXXXX)"
trap cleanup EXIT

MOCK_BIN="${TEST_ROOT}/bin"
INPUT_IMAGES="${TEST_ROOT}/incoming/manifest-regression/images"
SCENE_PATH="${TEST_ROOT}/scenes/manifest-regression"
LOG_DIR="${TEST_ROOT}/logs/manifest-regression"
VALIDATOR_MARKER="${TEST_ROOT}/validator-called"
mkdir -p "${MOCK_BIN}" "${INPUT_IMAGES}"
printf 'image-one\n' > "${INPUT_IMAGES}/001.jpg"
printf 'image-two\n' > "${INPUT_IMAGES}/002.jpg"

cat > "${MOCK_BIN}/colmap" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail

command_name="${1:-}"
shift || true

option_value() {
  local option_name="$1"
  shift
  while (( $# > 0 )); do
    if [[ "$1" == "${option_name}" ]]; then
      printf '%s\n' "$2"
      return 0
    fi
    shift
  done
  return 1
}

case "${command_name}" in
  -h|--help)
    echo 'COLMAP 3.10 -- test stub'
    ;;
  feature_extractor)
    database_path="$(option_value --database_path "$@")"
    sqlite3 "${database_path}" <<'SQL'
CREATE TABLE images(image_id INTEGER PRIMARY KEY, name TEXT NOT NULL);
INSERT INTO images(name) VALUES ('001.jpg'), ('002.jpg');
SQL
    echo 'stub feature extraction complete'
    ;;
  exhaustive_matcher|sequential_matcher)
    echo 'stub matching complete'
    ;;
  mapper)
    output_path="$(option_value --output_path "$@")"
    mkdir -p "${output_path}/0"
    printf 'camera-model\n' > "${output_path}/0/cameras.bin"
    printf 'registered-images\n' > "${output_path}/0/images.bin"
    printf 'sparse-points\n' > "${output_path}/0/points3D.bin"
    echo 'stub mapper complete'
    ;;
  model_analyzer)
    echo 'Registered images: 2'
    ;;
  *)
    echo "unexpected COLMAP command: ${command_name}" >&2
    exit 1
    ;;
esac
MOCK

cat > "${MOCK_BIN}/gdown" <<'MOCK'
#!/usr/bin/env bash
echo 'gdown 6.1.0 test stub'
MOCK

cat > "${MOCK_BIN}/runpodctl" <<'MOCK'
#!/usr/bin/env bash
echo 'runpodctl 2.5.0 test stub'
MOCK

cat > "${MOCK_BIN}/validate-surveyor-scene.sh" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
printf 'called\n' > "${VALIDATOR_MARKER}"
MOCK

chmod +x \
  "${MOCK_BIN}/colmap" \
  "${MOCK_BIN}/gdown" \
  "${MOCK_BIN}/runpodctl" \
  "${MOCK_BIN}/validate-surveyor-scene.sh"

SURVEYOR="$(resolve_command survey-scene.sh)"

echo "test=production_manifest_generation"
PATH="${MOCK_BIN}:${PATH}" \
WORKSPACE_ROOT="${TEST_ROOT}" \
INPUT_IMAGES="${INPUT_IMAGES}" \
SCENE_PATH="${SCENE_PATH}" \
LOG_DIR="${LOG_DIR}" \
VALIDATOR_PATH="${MOCK_BIN}/validate-surveyor-scene.sh" \
VALIDATOR_MARKER="${VALIDATOR_MARKER}" \
COLMAP_USE_GPU=0 \
  "${SURVEYOR}" manifest-regression >/dev/null

MANIFEST_PATH="${SCENE_PATH}/surveyor-manifest.json"
[[ -f "${MANIFEST_PATH}" ]] || fail "manifest was not generated"
jq -e \
  --arg scene_path "${SCENE_PATH}" \
  --arg sparse_path "${SCENE_PATH}/sparse/0" \
  '
    .schema == "cloud-workstation.surveyor.v0.1" and
    .scene == "manifest-regression" and
    .image_count == 2 and
    .database_images == 2 and
    .matcher == "exhaustive" and
    .colmap_use_gpu == "0" and
    .single_camera == "1" and
    .camera_model == "OPENCV" and
    .scene_path == $scene_path and
    .trainer_ready_sparse_path == $sparse_path
  ' "${MANIFEST_PATH}" >/dev/null || fail "generated manifest fields are invalid"

LAST_BYTE="$(tail -c 1 "${MANIFEST_PATH}" | od -An -t x1 | tr -d '[:space:]')"
LAST_TWO_BYTES="$(tail -c 2 "${MANIFEST_PATH}" | od -An -t x1 | tr -d '[:space:]')"
[[ "${LAST_BYTE}" == "0a" ]] || fail "manifest does not end with a real newline: ${LAST_BYTE}"
[[ "${LAST_TWO_BYTES}" != "5c6e" ]] || fail "manifest ends with literal backslash-n bytes"
[[ -f "${VALIDATOR_MARKER}" ]] || fail "production flow did not invoke the validator"

echo "survey_scene_manifest_tests=passed"
