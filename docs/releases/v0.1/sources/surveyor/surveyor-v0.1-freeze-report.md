# The Surveyor v0.1 - Freeze and Forensic Baseline Report

Status: proposed functional freeze dossier for The Eye
Inspection date: 2026-06-29T22:00:19-06:00
Source branch: `headless-surveyor-v0.1-dev`
Frozen source commit: `01b7f6876f0af933e610eb67a3583cb628ea2ddd`
Audit branch: `audit/surveyor-v0.1-freeze`

## Executive Summary

The Surveyor v0.1 is a headless COLMAP workstation image that accepts image sets, builds one or more sparse reconstructions, selects the best candidate, normalizes that candidate to `sparse/0`, validates the Trainer handoff contract, and creates portable scene and evidence archives with SHA-256 records.

The source commit inspected here has a clean Git tree and passed the existing local non-GPU test suite. The latest existing GitHub Actions workflow for the same commit also completed successfully and reported a Docker Hub push. No runtime, dependency, workflow, script, test, Dockerfile, or contract change is introduced by this dossier.

The published-image digest cannot be independently verified on this Mac because Docker and Docker Buildx are unavailable. CI reported `sha256:51e9a9236cdc8c8351195709e5f0a864a01c62d4a79251f71e182219acdeb7d8`; this is retained as CI-reported evidence, not promoted to an independently verified digest.

Proposed identifiers, not created by this audit:

- Git tag: `surveyor-v0.1.0-smoke-validated`
- Docker tag: `headless-surveyor-v0.1.0`

The stable Docker tag must be attached to the already-published verified digest. It must not be produced by rebuilding the image.

## 1. Immutable Git Identity

| Field | Recorded value |
|---|---|
| Remote fetch | `https://github.com/Marquezmemo/cloud-workstation.git` |
| Remote push | `https://github.com/Marquezmemo/cloud-workstation.git` |
| Source branch | `headless-surveyor-v0.1-dev` |
| Source commit | `01b7f6876f0af933e610eb67a3583cb628ea2ddd` |
| Source tree | Clean; no staged, modified, or untracked files |
| `git diff` | Empty |
| `git diff --stat` | Empty |
| Existing matching Git tag | None |
| Audit branch | `audit/surveyor-v0.1-freeze` |

Commands captured before creating the audit branch:

```bash
git switch headless-surveyor-v0.1-dev
git status --short --branch
git rev-parse HEAD
git remote -v
git diff
git diff --stat
```

Observed branch status:

```text
## headless-surveyor-v0.1-dev...origin/headless-surveyor-v0.1-dev
```

## 2. Docker Identity

| Field | Recorded value |
|---|---|
| Current development tag | `docker.io/marquezmemo/cloud-workstation:headless-surveyor-v0.1-dev` |
| Proposed stable tag | `docker.io/marquezmemo/cloud-workstation:headless-surveyor-v0.1.0` |
| Independent digest verification | `PENDING` |
| Pending reason | `docker`, `docker image inspect`, and `docker buildx imagetools inspect` are unavailable in the inspection environment |
| CI-reported pushed digest | `sha256:51e9a9236cdc8c8351195709e5f0a864a01c62d4a79251f71e182219acdeb7d8` |
| CI run | `28411071377`, successful, HEAD `01b7f6876f0af933e610eb67a3583cb628ea2ddd` |
| CI job | `84183939795`, successful |

The CI-reported digest is useful corroborating evidence but does not satisfy the requested independent `pull`/`inspect`/`imagetools inspect` verification. The stable tag must remain uncreated until that verification is performed from a Docker-capable host.

### OCI Labels

```text
org.opencontainers.image.title=cloud-workstation
org.opencontainers.image.version=headless-surveyor-v0.1-dev
org.opencontainers.image.description=Headless COLMAP image for photogrammetry reconstruction before Gaussian Splatting training.
org.opencontainers.image.base.name=colmap/colmap:20240723.601@sha256:73003557e3ffa36d801e71b7630c117f9d373c55f24e3afc6791b9b3d1ec01da
io.cloud-workstation.colmap.version=3.10
io.cloud-workstation.colmap.commit=0bd66d901c7549051e21e8f648777f802eb20a73
io.cloud-workstation.cuda.version=12.3.1
io.cloud-workstation.ubuntu.version=22.04
io.cloud-workstation.gdown.version=6.1.0
```

## 3. Runtime Architecture

```text
ZIP or image files
       |
       v
/workspace/incoming/<scene>/images
       |
       v
COLMAP feature extraction -> matching -> mapper
       |
       v
/workspace/scenes/<scene>/sparse/{0,1,...}
       |
       v
rank by registered images, then points, then original index
       |
       v
safe normalization of winner to sparse/0
       |
       v
manifest + validator + packages + SHA-256
       |
       v
Trainer: train-scene.sh --check <scene>
```

The image is intentionally headless. It includes no desktop, X11, VNC, viewer, Blender, Trainer, `gsplat`, or default dense-reconstruction pipeline.

The Docker entrypoint is cleared. The default command is:

```json
["runpod-keepalive.sh"]
```

`runpod-keepalive.sh` creates the workspace roots, prints operator hints, and holds the container with `sleep infinity`.

## 4. Fixed Dependencies

| Component | Frozen identity |
|---|---|
| Base image | `colmap/colmap:20240723.601@sha256:73003557e3ffa36d801e71b7630c117f9d373c55f24e3afc6791b9b3d1ec01da` |
| COLMAP | `3.10` / runtime evidence `3.10-dev` |
| COLMAP commit | `0bd66d901c7549051e21e8f648777f802eb20a73` |
| CUDA image runtime | `12.3.1` |
| Ubuntu | `22.04` |
| gdown | `6.1.0`, installed from a fully hashed Python lock |
| runpodctl | `2.5.0`, binary SHA-256 `f484ce7d790ddc6b4a63363f3c975c70fa87bf3be1bcbad019812f6e3f4ba54e` |

The image also installs Bash, CA certificates, coreutils, curl, ffmpeg, findutils, gzip, jq, Python 3 and pip, rsync, SQLite, tar, and unzip. No package upgrade command is used.

## 5. Workspace Structure

```text
/workspace/
+-- incoming/
|   +-- <scene>/
|       +-- images/
|       +-- source/<archive.zip>
+-- scenes/
|   +-- <scene>/
|       +-- images/
|       +-- database.db
|       +-- sparse/
|       |   +-- 0/
|       |   +-- optional additional numeric models
|       +-- surveyor-manifest.json
+-- logs/<scene>/
+-- archives/<scene>/
+-- temp/
```

`sparse/0` is the normalized Trainer-ready model. Secondary sparse models remain present under their displaced numeric indices.

## 6. Operational Scripts And Public Commands

| Script | Public command | Input | Primary output |
|---|---|---|---|
| `runpod-keepalive.sh` | container default | none | persistent headless process and hints |
| `preparar-escena` | `preparar-escena [archivo.zip]` | explicit ZIP or exactly one ZIP under `/workspace` | transactional `incoming/<scene>/{images,source}` |
| `validate-surveyor.sh` | `validate-surveyor.sh` | image runtime | tool/version/workspace validation |
| `survey-scene.sh` | `survey-scene.sh <scene>` | supported images under `incoming/<scene>/images` | database, sparse models, normalized `sparse/0`, manifest, logs |
| `validate-surveyor-scene.sh` | `validate-surveyor-scene.sh <scene>` | complete scene and evidence | contract result on stdout |
| `package-surveyor-scene.sh` | `package-surveyor-scene.sh <scene>` | validated scene and logs | scene/evidence archives and SHA-256 files |

Additional operator commands include `gdown`, `runpodctl`, `sha256sum`, `colmap model_analyzer`, and Trainer-side `train-scene.sh --check <scene>` after transfer.

## 7. Environment Variables

### Image-level

```text
SURVEYOR_IMAGE_VERSION
SURVEYOR_COLMAP_VERSION
SURVEYOR_COLMAP_COMMIT
SURVEYOR_CUDA_VERSION
SURVEYOR_UBUNTU_VERSION
SURVEYOR_GDOWN_VERSION
WORKSPACE_ROOT
INCOMING_DIR
SCENES_DIR
LOGS_DIR
ARCHIVES_DIR
TEMP_DIR
```

### Reconstruction

```text
SCENE_NAME
INPUT_IMAGES
SCENE_PATH
LOG_DIR
MATCHER                 exhaustive | sequential; default exhaustive
COLMAP_USE_GPU          1 | 0; default 1
SINGLE_CAMERA           1 | 0; default 1
CAMERA_MODEL            default OPENCV
MAX_IMAGE_SIZE          optional positive integer
OVERWRITE               true | false; default false
VALIDATOR_PATH          test/advanced override
```

### Validation and packaging

```text
REQUIRE_SUMMARY
ARCHIVE_DIR
ARCHIVE_PATH
EVIDENCE_PATH
TEMP_DIR
OVERWRITE
VALIDATOR_PATH
```

The frozen defaults include `CAMERA_MODEL=OPENCV` and `SINGLE_CAMERA=1`. This dossier does not recommend changing them inside v0.1.

## 8. Data And Processing Contracts

### ZIP preparation

`preparar-escena` validates ZIP integrity with `unzip -t`, rejects unsafe paths and symbolic links, extracts to temporary storage, ignores `__MACOSX`, `.DS_Store`, and `._*`, accepts `.jpg`, `.jpeg`, `.png`, `.tif`, and `.tiff`, requires at least two non-empty images, detects case-insensitive basename collisions, and atomically publishes the incoming scene. Existing incoming or processed scenes are not overwritten.

### `database.db`

COLMAP feature extraction creates the SQLite database. Surveyor and its validator distinguish:

- `database_images`: rows in the database image table.
- `registered_images`: images registered in the selected sparse reconstruction.

These values are not interchangeable. Validation enforces `registered_images <= database_images`.

### Extraction, matching, and mapper

The frozen reconstruction sequence is:

```text
colmap feature_extractor
colmap exhaustive_matcher | colmap sequential_matcher
colmap mapper
colmap model_analyzer
```

Feature extraction uses the configured camera model, single-camera policy, optional maximum image size, and GPU flag. Matching uses the selected matcher and GPU flag. The mapper may produce multiple numeric sparse-model directories.

### Sparse candidate selection

Surveyor discovers canonical numeric directories under `sparse/`, requires non-empty `cameras.bin`, `images.bin`, and `points3D.bin`, and analyzes every candidate. Ranking is:

1. Highest `Registered images`.
2. Highest `Points`.
3. Lowest original numeric index for a complete tie.

If a non-zero model wins, Surveyor exchanges it with model `0` using same-filesystem temporary renames and rollback handling. The original model `0` is preserved under the winner's former index. No secondary model is deleted.

Selection evidence is written atomically to `logs/<scene>/sparse-selection.txt`. The definitive `model-analyzer.txt` is generated from normalized `sparse/0`.

### Manifest

`surveyor-manifest.json` includes the schema, scene, timestamp, image/database counts, matcher, GPU flag, single-camera flag, camera model, scene path, Trainer-ready path, sparse-model count, original selected index, and registered-image count. A direct `jq -e` gate validates generated JSON before the scene validator runs.

### Validation

The scene validator requires supported non-empty images, a healthy SQLite database, normalized sparse binaries, final model-analyzer metrics, selection evidence, manifest consistency, `registered_images >= 2`, `registered_images <= database_images`, candidate/model-count agreement, and GPU evidence when GPU mode was used.

### Packaging and checksums

The packager first invokes the complete validator. It creates:

```text
<scene>-surveyor-scene.tar.gz
<scene>-surveyor-scene.tar.gz.sha256
<scene>-surveyor-evidence.tar.gz
<scene>-surveyor-evidence.tar.gz.sha256
```

Scene archives retain normalized `sparse/0` and secondary models. Evidence archives include the manifest and logs. Checksum records contain relative filenames and are verified immediately with `sha256sum -c`.

### Trainer handoff

Trainer receives and extracts the scene archive, verifies its checksum, and runs:

```bash
train-scene.sh --check <scene>
```

Training and PLY export are outside Surveyor.

## 9. Publication Workflow And Tests

Workflow: `.github/workflows/publish-headless-surveyor-dev.yml`

Trigger:

- Push to `headless-surveyor-v0.1-dev`.
- Manual `workflow_dispatch`.

The workflow checks shell syntax, builds `linux/amd64`, validates the image without GPU, runs contract, sparse-selection/manifest, and ZIP tests, and pushes `headless-surveyor-v0.1-dev` only after all gates pass.

Latest existing run for the frozen source commit:

```text
Run: 28411071377
Job: 84183939795
Commit: 01b7f6876f0af933e610eb67a3583cb628ea2ddd
Conclusion: success
```

No workflow was triggered by this audit branch.

## 10. Prueba02 Evidence

Evidence source: `docs/validation-runs/2026-06-29-prueba02-surveyor.md`, committed in the frozen source HEAD. The external evidence attachments named by that record were not present in this inspection environment and were not re-hashed here.

Evidence-backed facts:

- 30 input images.
- 30 images in `database.db`.
- Camera model `OPENCV`.
- `SINGLE_CAMERA=1`.
- Two sparse candidates.
- Original candidate `1` selected with 30 registered images.
- 4,555 points.
- 19,928 observations.
- Mean track length `4.374973`.
- Mean reprojection error `1.133537 px`.
- Selected candidate normalized to `/workspace/scenes/Prueba02/sparse/0`.
- Manifest and scene validation passed.
- Scene and evidence packages were created.
- Portable checksums passed in Surveyor.
- Trainer received the scene archive and checksum, verified the checksum, extracted the scene, passed `train-scene.sh --check Prueba02`, and completed a 300-step run.

The versioned evidence record reports an evidence archive SHA-256 of `03d4f4f764e8dc4a53cff4b029781cd31877ec5c795db9f39b6e962dfed21157` and size of 5,802 bytes. This audit records that statement but does not claim a new local verification because the archive was unavailable.

**Esta evidencia valida funcionalidad, reconstrucción sparse y handoff. No valida calidad profesional ni comercial.**

## 11. Non-Destructive Tests Executed By This Audit

Environment:

```text
Date interval: 2026-06-29T22:03:31-06:00 to 2026-06-29T22:03:54-06:00
Host: macOS 26.5.1 (25F80), Darwin 25.5.0, ARM64
Bash: 3.2.57
Python: 3.14.6
jq: 1.8.2
SQLite: 3.51.0
GPU: not used
Docker: unavailable
```

| Command | Exit | Result |
|---|---:|---|
| `bash -n scripts/*.sh scripts/preparar-escena tests/*.sh` | 0 | Shell syntax passed; no output |
| `tests/test-surveyor-contract.sh` | 0 | Valid scene, packages, GPU evidence fixture, and negative contract cases passed |
| `tests/test-survey-scene-manifest.sh` | 0 | Registered-image selection, point tiebreak, keep-zero, validation, and packaging passed |
| `tests/test-preparar-escena.sh` | 0 | ZIP/macOS metadata, autodetection, corruption, collision, existing-scene, and unsafe-path cases passed |

No GPU run, image build, Docker pull, Docker tag, Docker push, or new publication workflow was executed.

## 12. Limitations

- No professional or commercial quality threshold is defined.
- `OPENCV` distortion versus a PINHOLE/undistorted workflow remains unevaluated.
- Trainer-side archive extraction remains manual.
- Dense reconstruction and PLY export are outside Surveyor v0.1.
- Video frame extraction is not implemented.
- The stable image digest still requires independent verification with Docker-capable tooling.
- The Prueba02 attachments were not locally present for independent re-verification.

## 13. Accidental Reconstruction And Publication Risks

- Any commit pushed to `headless-surveyor-v0.1-dev` triggers a build and overwrites the mutable development tag.
- Rebuilding from the same Git commit can produce a different image digest because external build tooling, timestamps, or registry metadata may differ.
- Creating `headless-surveyor-v0.1.0` through a new build would violate the freeze requirement.
- Moving the proposed Git tag after creation would destroy source immutability.
- Retagging before independently verifying the existing digest could freeze the wrong artifact.
- Editing official documentation from the audit branch would mix evidence preparation with canonical documentation ownership.

## 14. Recovery Procedure

1. Confirm the approved Git tag points exactly to `01b7f6876f0af933e610eb67a3583cb628ea2ddd`.
2. From a Docker-capable host, inspect the current development tag without rebuilding:

   ```bash
   docker buildx imagetools inspect \
     docker.io/marquezmemo/cloud-workstation:headless-surveyor-v0.1-dev
   ```

3. Confirm the returned digest against the CI-reported digest and record the independently verified value.
4. Create `headless-surveyor-v0.1.0` by registry retag/copy of that exact digest. Do not run `docker build`.
5. Pull the stable tag and confirm the same digest with `docker image inspect` or `docker buildx imagetools inspect`.
6. Run `validate-surveyor.sh` in the pulled image. A new GPU reconstruction is not required for restoration if Prueba02 evidence remains accepted.
7. Restore scenes from verified scene/evidence archives and run their `.sha256` checks before Trainer handoff.

The exact registry-retag command depends on the approved registry tooling and credentials. The Eye should document the authorized operational command after digest verification.

## 15. Handoff To The Eye

The Eye should integrate:

1. Frozen Git identity and clean-tree evidence.
2. Independently verified Docker digest once obtained.
3. Approval and creation status for the proposed Git and Docker tags.
4. Runtime architecture, fixed dependency table, workspace contract, and public commands.
5. Distinction between `database_images` and `registered_images`.
6. Sparse ranking and normalization contract.
7. Manifest, validator, package, checksum, and Trainer handoff contracts.
8. Prueba02 facts and the explicit non-commercial-quality disclaimer.
9. Local test record and latest successful CI record.
10. Recovery procedure and warning against rebuilding or pushing to the development branch.

## 16. Freeze Declaration

This audit branch adds only proposal documents and generated forensic artifacts. It makes no functional change to The Surveyor v0.1. The source commit remains `01b7f6876f0af933e610eb67a3583cb628ea2ddd`; runtime files, workflows, dependencies, contracts, and behavior remain untouched.
