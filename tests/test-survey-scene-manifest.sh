#!/usr/bin/env bash
set -euo pipefail

# Purpose: Exercise production sparse selection and manifest generation with COLMAP stubbed.
# Input:   Production Surveyor commands available in PATH or repository scripts/.
# Output:  Selection, validation, and packaging regression results on stdout.

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
mkdir -p "${MOCK_BIN}"

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

create_model() {
  local output_path="$1"
  local index="$2"
  local registered_images="$3"
  local points="$4"
  local model_path="${output_path}/${index}"

  mkdir -p "${model_path}"
  printf 'camera-model-%s\n' "${index}" > "${model_path}/cameras.bin"
  printf 'registered-images-%s\n' "${index}" > "${model_path}/images.bin"
  printf 'sparse-points-%s\n' "${index}" > "${model_path}/points3D.bin"
  printf '%s\n' "${index}" > "${model_path}/.original-index"
  printf '%s\n' "${registered_images}" > "${model_path}/.registered-images"
  printf '%s\n' "${points}" > "${model_path}/.points"
}

case "${command_name}" in
  -h|--help)
    echo 'COLMAP 3.10 -- test stub'
    ;;
  feature_extractor)
    database_path="$(option_value --database_path "$@")"
    image_path="$(option_value --image_path "$@")"
    sqlite3 "${database_path}" 'CREATE TABLE images(image_id INTEGER PRIMARY KEY, name TEXT NOT NULL);'
    while IFS= read -r image_file; do
      image_name="$(basename "${image_file}")"
      sqlite3 "${database_path}" "INSERT INTO images(name) VALUES ('${image_name}');"
    done < <(find "${image_path}" -maxdepth 1 -type f | sort)
    echo 'stub feature extraction complete'
    ;;
  exhaustive_matcher|sequential_matcher)
    echo 'stub matching complete'
    ;;
  mapper)
    output_path="$(option_value --output_path "$@")"
    create_model "${output_path}" 0 "${STUB_MODEL_0_REGISTERED}" "${STUB_MODEL_0_POINTS}"
    create_model "${output_path}" 1 "${STUB_MODEL_1_REGISTERED}" "${STUB_MODEL_1_POINTS}"
    echo 'stub mapper complete'
    ;;
  model_analyzer)
    model_path="$(option_value --path "$@")"
    registered_images="$(cat "${model_path}/.registered-images")"
    points="$(cat "${model_path}/.points")"
    echo 'I0000 00:00:00.000000 model.cc:438] Cameras: 1'
    echo "I0000 00:00:00.000000 model.cc:439] Images: ${registered_images}"
    echo "I0000 00:00:00.000000 model.cc:440] Registered images: ${registered_images}"
    echo "I0000 00:00:00.000000 model.cc:442] Points: ${points}"
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

chmod +x "${MOCK_BIN}/colmap" "${MOCK_BIN}/gdown" "${MOCK_BIN}/runpodctl"

SURVEYOR="$(resolve_command survey-scene.sh)"
VALIDATOR="$(resolve_command validate-surveyor-scene.sh)"
PACKAGER="$(resolve_command package-surveyor-scene.sh)"

run_selection_case() {
  local case_name="$1"
  local model_0_registered="$2"
  local model_0_points="$3"
  local model_1_registered="$4"
  local model_1_points="$5"
  local expected_original_index="$6"
  local expected_registered_images="$7"
  local expected_points="$8"
  local displaced_original_index
  local case_root="${TEST_ROOT}/${case_name}"
  local scene_name="selection-${case_name}"
  local input_images="${case_root}/incoming/${scene_name}/images"
  local scene_path="${case_root}/scenes/${scene_name}"
  local log_dir="${case_root}/logs/${scene_name}"
  local archive_dir="${case_root}/archives/${scene_name}"
  local manifest_path="${scene_path}/surveyor-manifest.json"
  local evidence_path="${log_dir}/sparse-selection.txt"
  local scene_archive="${archive_dir}/${scene_name}-surveyor-scene.tar.gz"

  mkdir -p "${input_images}"
  for image_number in $(seq -w 1 30); do
    printf 'image-%s\n' "${image_number}" > "${input_images}/${image_number}.jpg"
  done

  echo "test=${case_name}"
  PATH="${MOCK_BIN}:${PATH}" \
  WORKSPACE_ROOT="${case_root}" \
  INPUT_IMAGES="${input_images}" \
  SCENE_PATH="${scene_path}" \
  LOG_DIR="${log_dir}" \
  TEMP_DIR="${case_root}/temp" \
  VALIDATOR_PATH="${VALIDATOR}" \
  COLMAP_USE_GPU=0 \
  STUB_MODEL_0_REGISTERED="${model_0_registered}" \
  STUB_MODEL_0_POINTS="${model_0_points}" \
  STUB_MODEL_1_REGISTERED="${model_1_registered}" \
  STUB_MODEL_1_POINTS="${model_1_points}" \
    "${SURVEYOR}" "${scene_name}" >/dev/null

  [[ "$(cat "${scene_path}/sparse/0/.original-index")" == "${expected_original_index}" ]] \
    || fail "${case_name}: selected model was not normalized to sparse/0"
  if [[ "${expected_original_index}" == "0" ]]; then
    displaced_original_index=1
  else
    displaced_original_index=0
  fi
  [[ "$(cat "${scene_path}/sparse/1/.original-index")" == "${displaced_original_index}" ]] \
    || fail "${case_name}: displaced model was not preserved"
  [[ "$(find "${scene_path}/sparse" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')" == "2" ]] \
    || fail "${case_name}: sparse model count changed during normalization"

  grep -Eq "Registered images:[[:space:]]*${expected_registered_images}$" "${log_dir}/model-analyzer.txt" \
    || fail "${case_name}: final analyzer has the wrong registered image count"
  grep -Eq "Points:[[:space:]]*${expected_points}$" "${log_dir}/model-analyzer.txt" \
    || fail "${case_name}: final analyzer has the wrong point count"

  jq -e \
    --arg selected_index "${expected_original_index}" \
    --arg sparse_path "${scene_path}/sparse/0" \
    --argjson registered_images "${expected_registered_images}" \
    '
      .sparse_model_count == 2 and
      .selected_sparse_original_index == $selected_index and
      .registered_images == $registered_images and
      .database_images == 30 and
      .trainer_ready_sparse_path == $sparse_path
    ' "${manifest_path}" >/dev/null || fail "${case_name}: manifest selection fields are invalid"

  grep -qx 'model_count=2' "${evidence_path}" || fail "${case_name}: evidence model count is invalid"
  grep -qx "selected_original_index=${expected_original_index}" "${evidence_path}" \
    || fail "${case_name}: evidence selected index is invalid"
  grep -qx "selected_registered_images=${expected_registered_images}" "${evidence_path}" \
    || fail "${case_name}: evidence registered count is invalid"
  grep -qx "selected_points=${expected_points}" "${evidence_path}" \
    || fail "${case_name}: evidence point count is invalid"
  grep -qx "selected_final_path=${scene_path}/sparse/0" "${evidence_path}" \
    || fail "${case_name}: evidence final path is invalid"

  WORKSPACE_ROOT="${case_root}" \
  SCENE_PATH="${scene_path}" \
  LOG_DIR="${log_dir}" \
    "${VALIDATOR}" "${scene_name}" >/dev/null

  WORKSPACE_ROOT="${case_root}" \
  SCENE_PATH="${scene_path}" \
  LOG_DIR="${log_dir}" \
  ARCHIVE_DIR="${archive_dir}" \
  TEMP_DIR="${case_root}/temp" \
  VALIDATOR_PATH="${VALIDATOR}" \
    "${PACKAGER}" "${scene_name}" >/dev/null

  grep -q "^${scene_name}/sparse/0/cameras.bin$" < <(tar -tzf "${scene_archive}") \
    || fail "${case_name}: package is missing Trainer sparse/0"
  grep -q "^${scene_name}/sparse/1/cameras.bin$" < <(tar -tzf "${scene_archive}") \
    || fail "${case_name}: package lost the secondary sparse model"
  grep -q "^${scene_name}/surveyor-manifest.json$" < <(tar -tzf "${scene_archive}") \
    || fail "${case_name}: package is missing the manifest"

  LAST_BYTE="$(tail -c 1 "${manifest_path}" | od -An -t x1 | tr -d '[:space:]')"
  LAST_TWO_BYTES="$(tail -c 2 "${manifest_path}" | od -An -t x1 | tr -d '[:space:]')"
  [[ "${LAST_BYTE}" == "0a" ]] || fail "${case_name}: manifest does not end with a real newline"
  [[ "${LAST_TWO_BYTES}" != "5c6e" ]] || fail "${case_name}: manifest ends with literal backslash-n bytes"
}

run_selection_case registered-images 2 219 30 5000 1 30 5000
run_selection_case points-tiebreak 30 4000 30 5000 1 30 5000
run_selection_case keep-zero 30 5000 2 219 0 30 5000

echo "survey_scene_manifest_tests=passed"
