# The Surveyor v0.2 Handoff

## 1. Purpose Of This Document

This document transfers the verified Surveyor v0.1 context to the agent that will continue work on Surveyor v0.2. It defines the inherited runtime, contracts, evidence boundaries, known limitations, and governance rules needed to avoid accidentally reinterpreting or modifying the v0.1 baseline.

Evidence labels used here:

- **Git fact:** directly inspectable in the repository at the stated commit.
- **Preserved evidence:** supported by the versioned validation record and its recorded artifacts.
- **Operator-confirmed:** confirmed by the repository owner and operator, but without preserved primary execution records.
- **Proposal:** an idea already recorded in repository documentation, not an approved commitment.

## 2. Inherited Identities

```text
v0.1 documentation head:
28731aed2ea8d4de9c4c9a308f61b66ef7753045

v0.1 runtime:
01b7f6876f0af933e610eb67a3583cb628ea2ddd

Docker digest:
sha256:51e9a9236cdc8c8351195709e5f0a864a01c62d4a79251f71e182219acdeb7d8

v0.2 starting branch:
headless-surveyor-v0.2-dev
```

The v0.1 documentation head and v0.2 starting point are Git-verifiable. The Docker digest is the inherited digest supplied for this freeze; this initialization mission did not rebuild, pull, publish, or independently re-inspect the image.

The first v0.2 commit adds only `AGENTS.md` and this handoff. The inherited Dockerfile, scripts, tests, workflow, dependencies, manifests, and runtime behavior remain unchanged from the v0.1 documentation head.

## 3. What v0.1 Demonstrated

### Preserved Prueba02 evidence

The versioned record is [`docs/validation-runs/2026-06-29-prueba02-surveyor.md`](../validation-runs/2026-06-29-prueba02-surveyor.md). It records:

- a ZIP downloaded with `gdown` and prepared as 30 input images;
- 30 images in `database.db`;
- `CAMERA_MODEL=OPENCV` and `SINGLE_CAMERA=1`;
- GPU feature extraction and matching;
- two numeric sparse candidates;
- original candidate `1` selected with 30 registered images and 4,555 points;
- normalization of the selected candidate to `sparse/0` while retaining the secondary model;
- a valid JSON manifest consistent with model-selection evidence;
- scene validation, scene/evidence packaging, portable checksums, transfer, Trainer receipt, destination checksum verification, Trainer dataset acceptance, and a 300-step downstream training run.

The final selected model record also reports 19,928 observations, mean track length `4.374973`, and mean reprojection error `1.133537 px`. The preserved evidence archive is recorded with SHA-256 `03d4f4f764e8dc4a53cff4b029781cd31877ec5c795db9f39b6e962dfed21157`.

### Later downstream validation

The repository owner and operator later confirmed that the final Trainer runtime `221c4ef76a1ff5bfa8a9f45e5e9a084e8fbedfe3`, which incorporates Trainer-side `preparar-escena`, consumed the Surveyor package successfully. The checksum was accepted, the scene was installed, `train-scene.sh --check` passed, CUDA training completed, a checkpoint was generated, a PLY was generated and packaged, and the result opened in a viewer.

That later result is classified as:

```text
handoff_status: passed
validation_authority: repository-owner-operator
evidence_level: operator-confirmed
primary_execution_records: not-preserved
```

Those operations were downstream Trainer responsibilities. Surveyor did not perform training, checkpoint generation, PLY export or PLY packaging, or viewing. The later operator-confirmed result supplements but does not replace or weaken the preserved Prueba02 evidence.

**Esta evidencia valida funcionalidad, reconstrucción sparse y handoff. No valida calidad profesional ni comercial.**

## 4. Input Contract

The direct image input is:

```text
/workspace/incoming/<scene>/images
```

[`scripts/survey-scene.sh`](../../scripts/survey-scene.sh) reads files directly under that directory. Supported extensions are case-insensitive:

```text
.jpg
.jpeg
.png
.tif
.tiff
```

At least two non-empty supported files are required. Nested directories are not read by `survey-scene.sh`.

[`scripts/preparar-escena`](../../scripts/preparar-escena) converts a ZIP into the flat input contract:

```bash
preparar-escena [archivo.zip]
```

- With an argument, the named ZIP must exist and use a `.zip` extension.
- Without an argument, exactly one ZIP must exist directly under `/workspace`; multiple ZIPs are listed and rejected rather than silently selected.
- The scene name is derived from the ZIP filename and must match the script's safe scene-name policy.
- ZIP integrity is checked before extraction.
- Absolute/traversal paths, encrypted entries, symbolic links, ambiguous duplicate entries, empty supported images, and case-insensitive flattened-name collisions are rejected.
- `__MACOSX`, `.DS_Store`, and `._*` metadata are ignored.
- Supported images may be nested in the ZIP; they are flattened into `images/` only after validation.
- Existing incoming or processed scenes are not overwritten.
- Extraction and publication use temporary/staging directories; failures clean up and leave the original ZIP unchanged.
- On success, the original ZIP stays in place and an identical copy is stored under `source/`.
- The command does not execute COLMAP or write under `/workspace/scenes`.

Successful preparation produces:

```text
/workspace/incoming/<scene>/
+-- images/
+-- source/
    +-- <archive.zip>
```

## 5. Output Contract

[`scripts/survey-scene.sh`](../../scripts/survey-scene.sh) writes the Trainer handoff scene as:

```text
/workspace/scenes/<scene>/
+-- images/
+-- database.db
+-- sparse/
|   +-- 0/
|   |   +-- cameras.bin
|   |   +-- images.bin
|   |   +-- points3D.bin
|   +-- optional additional numeric models
+-- surveyor-manifest.json
```

`sparse/0` is the normalized Trainer-ready model. Additional sparse components are preserved. The inherited manifest schema remains `cloud-workstation.surveyor.v0.1` until an explicitly approved contract change is implemented. Current fields include scene identity, timestamps, image and database counts, matcher, GPU flag, single-camera flag, camera model, scene path, Trainer-ready sparse path, sparse-model count, original selected index, and registered-image count.

Operational evidence is written under:

```text
/workspace/logs/<scene>/
+-- surveyor.env
+-- colmap-feature.log
+-- colmap-match.log
+-- colmap-mapper.log
+-- model-analyzer.txt
+-- sparse-selection.txt
+-- surveyor-gpu.log        # required when COLMAP_USE_GPU=1
+-- surveyor.summary
```

[`scripts/package-surveyor-scene.sh`](../../scripts/package-surveyor-scene.sh) validates before packaging and creates:

```text
/workspace/archives/<scene>/<scene>-surveyor-scene.tar.gz
/workspace/archives/<scene>/<scene>-surveyor-scene.tar.gz.sha256
/workspace/archives/<scene>/<scene>-surveyor-evidence.tar.gz
/workspace/archives/<scene>/<scene>-surveyor-evidence.tar.gz.sha256
```

The scene archive contains the normalized handoff and all retained sparse models. The evidence archive contains logs and the manifest. Checksum files use relative filenames and are verified immediately after creation.

## 6. Public Commands

These commands exist in the inherited Surveyor image and are copied or installed by [`Dockerfile`](../../Dockerfile):

| Command | Verified syntax | Responsibility |
|---|---|---|
| `validate-surveyor.sh` | `validate-surveyor.sh` | Validate runtime tools, pinned versions, COLMAP commands/SIFT flags, and workspace paths. |
| `preparar-escena` | `preparar-escena [archivo.zip]` | Transactionally prepare a flat incoming scene from a ZIP. |
| `survey-scene.sh` | `survey-scene.sh <scene-name>` | Run feature extraction, matching, mapper, sparse selection, manifest generation, and scene validation. |
| `validate-surveyor-scene.sh` | `validate-surveyor-scene.sh <scene-name>` | Validate images, database, normalized sparse model, evidence, and manifest consistency. |
| `package-surveyor-scene.sh` | `package-surveyor-scene.sh <scene-name>` | Validate and create scene/evidence archives plus SHA-256 records. |
| `runpod-keepalive.sh` | default container `CMD` | Create workspace roots, print operator hints, and keep the pod alive. |
| `gdown` | `gdown '<shared-drive-url>' -O /workspace/<scene>.zip` | Download from a temporarily shared Google Drive link; it does not upload. |
| `runpodctl` | `runpodctl send <path>` / `runpodctl receive <code>` | Manual transfer between Mac, pod, and downstream destinations. Do not preserve ephemeral codes in Git. |
| `sha256sum` | `sha256sum -c <archive>.sha256` | Verify downloaded or transferred artifacts. |

Supported `survey-scene.sh` overrides verified in the script are:

```bash
COLMAP_USE_GPU=0 survey-scene.sh <scene>
MATCHER=sequential survey-scene.sh <scene>
MAX_IMAGE_SIZE=1600 survey-scene.sh <scene>
OVERWRITE=true survey-scene.sh <scene>
```

`CAMERA_MODEL` and `SINGLE_CAMERA` are configurable implementation variables, but their inherited defaults are frozen decisions described below. `train-scene.sh` is not present in the Surveyor image.

## 7. Important Files

| Path | Responsibility | Modify when | Primary risk |
|---|---|---|---|
| `Dockerfile` | Pinned COLMAP/CUDA/Ubuntu base, tools, labels, workspace, and installed commands. | Only for an explicitly approved runtime/dependency mission. | Changes image identity, compatibility, and reproducibility. |
| `requirements-gdown.txt` | Fully hashed Python dependency lock for `gdown`. | Only with an approved dependency update. | Unreviewed dependency drift or non-reproducible installation. |
| `scripts/preparar-escena` | ZIP integrity, safety, filtering, flattening, and atomic incoming-scene publication. | When the input contract is explicitly changed. | Data loss, path traversal, collisions, or partial scenes. |
| `scripts/survey-scene.sh` | COLMAP execution, sparse discovery/ranking, normalization, manifest, and evidence. | For an approved reconstruction/contract change. | Wrong model selection, lost sparse models, invalid Trainer handoff. |
| `scripts/validate-surveyor.sh` | Runtime fingerprint and required-command validation. | With approved runtime/tool changes. | Image drift may pass unnoticed or valid images may be rejected. |
| `scripts/validate-surveyor-scene.sh` | Structural and metric consistency gate before handoff/package. | With an approved scene-contract change. | Invalid scenes may be packaged or valid scenes may be blocked. |
| `scripts/package-surveyor-scene.sh` | Scene/evidence archives and portable checksums. | With an approved packaging-contract change. | Broken transfer portability or incomplete evidence. |
| `scripts/runpod-keepalive.sh` | Default headless lifecycle and workspace creation. | Only for an approved lifecycle change. | Pod exits early or operator paths diverge. |
| `tests/test-preparar-escena.sh` | ZIP transaction, metadata, collision, corruption, overwrite, and cleanup regression coverage. | With input/preparation behavior. | ZIP safety regressions become undetected. |
| `tests/test-survey-scene-manifest.sh` | Real production path with COLMAP stub; sparse ranking, tie-break, normalization, manifest, and packaging. | With reconstruction/manifest behavior. | Best-model or manifest regressions become undetected. |
| `tests/test-surveyor-contract.sh` | Scene validator, negative fixtures, packaging, and portable checksums. | With validation/package contracts. | Invalid handoffs may be accepted. |
| `docs/architecture.md` | Surveyor role and Surveyor-to-Trainer boundary. | When approved architecture changes are implemented. | Documentation may assign responsibility to the wrong image. |
| `docs/dataset-format.md` | Input, output, logs, packages, and handoff layout. | With approved data-contract changes. | Operators and Trainer may consume incompatible layouts. |
| `docs/command-reference.md` | Existing operator commands and evidence workflow. | With implemented command changes. | Operators may run nonexistent or unsafe commands. |
| `docs/validation.md` | Evidence states, gates, preserved results, and pending validation. | When new evidence is actually collected. | Reported results may be mistaken for preserved evidence. |
| `docs/validation-runs/2026-06-29-prueba02-surveyor.md` | Preserved Prueba02 and later operator-confirmed downstream record. | Do not rewrite; append only with authorized, properly classified evidence. | Historical evidence can be weakened or misrepresented. |
| `docs/roadmap.md` | Existing priorities, limitations, and possible later work. | When priorities are approved or completed with evidence. | Proposals may be mistaken for commitments. |
| `.github/workflows/publish-headless-surveyor-dev.yml` | v0.1 build, tests, and Docker publication trigger. | Only in an explicit release/CI mission. | Accidental image build or publication; inherited YAML still names v0.1. |

## 8. Frozen v0.1 Decisions

Do not reinterpret these inherited decisions as accidental defaults:

- Surveyor and Trainer are separate images and responsibilities.
- Surveyor prepares a COLMAP sparse scene; it does not install `gsplat` or train.
- The current camera defaults are `CAMERA_MODEL=OPENCV` and `SINGLE_CAMERA=1`.
- Matching defaults to `exhaustive`; `sequential` is an explicit alternative.
- Sparse candidates are canonical numeric directories containing non-empty `cameras.bin`, `images.bin`, and `points3D.bin`.
- Selection ranks highest registered-image count, then highest point count, then lowest original numeric index for a complete tie.
- The selected model is normalized to `sparse/0`; a displaced original model `0` is preserved under the selected model's former index.
- `database_images` and `registered_images` are distinct metrics; validation requires registered images not to exceed database images.
- The manifest and `sparse-selection.txt` must agree with the normalized model.
- Packaging validates first, preserves secondary sparse models, and emits separate scene/evidence archives with portable checksum files.
- Evidence states must remain distinct; an operator-confirmed result without primary records is not preserved primary evidence.
- v0.1 has no professional or commercial quality certification.

Any proposed v0.2 change to these decisions requires owner approval and an explicit contract/migration analysis before implementation.

## 9. Known Limitations

The following limitations remain recorded in [`docs/roadmap.md`](../roadmap.md), [`docs/validation.md`](../validation.md), [`docs/dataset-format.md`](../dataset-format.md), and [`docs/command-reference.md`](../command-reference.md):

- minimum registered-image ratio and reconstruction-quality acceptance thresholds are not defined;
- capture-quality rules are not formalized;
- OPENCV distortion versus a PINHOLE/undistorted handoff remains unevaluated;
- corrected Surveyor-to-Trainer handoff should be repeated with additional scenes;
- SIFT GPU work requires a visible compatible NVIDIA runtime;
- exhaustive matching scales poorly for larger sets;
- packaging may be silent during compression and has no real byte-based progress display;
- dense reconstruction is intentionally excluded from the default pipeline;
- video frame extraction is not implemented;
- `preparar-escena` does not download automatically;
- the later Trainer-side preparation/training/PLY/viewer result is operator-confirmed because its primary records were not preserved.

None of these items is solved merely by creating the v0.2 branch.

## 10. Debt And Possible v0.2 Areas

### Confirmed debt

- Define evidence-backed capture and reconstruction acceptance thresholds.
- Repeat the corrected handoff with additional capture sets and preserve commands, hashes, logs, manifests, selection reports, and downstream results.
- Evaluate OPENCV distortion against an undistorted/PINHOLE handoff before long training runs.
- Improve packaging observability without inventing progress percentages.

### Possible improvement areas

- Determine when `MATCHER=sequential` should be recommended for video-like captures.
- Decide whether additional capture guidance is needed after more real datasets.
- Evaluate whether dense reconstruction belongs in a future Surveyor phase.

### Proposals not yet approved

- Add stage messages and real byte-based packaging progress, potentially with `pv` or an equivalent measured-byte mechanism.
- Change camera model or introduce an undistortion contract.
- Add dense reconstruction to Surveyor.
- Create or combine a future Full image after Surveyor and Trainer contracts are stable.

These are not v0.2 commitments. A new mission must authorize scope and acceptance criteria.

## 11. Boundary With Trainer

Surveyor responsibility ends after it has:

1. prepared or accepted source images;
2. generated `database.db` and one or more sparse models;
3. selected and normalized the Trainer-ready model to `sparse/0`;
4. generated and validated the manifest and evidence;
5. packaged the scene and evidence with verified checksums;
6. transferred or made the package available for handoff.

Trainer responsibility begins with receiving and verifying the package, installing/extracting the scene in its own workspace, and running its own compatibility check. Training, checkpoint management, PLY generation/packaging, and viewing belong to Trainer or later downstream tools. Surveyor must not modify those implementations or claim their outputs as Surveyor outputs.

Changes that affect both sides require a proposal describing the shared contract, compatibility impact, migration path, and evidence plan before either runtime is changed.

## 12. Recommended Workflow For A New Agent

1. Confirm branch, HEAD, status, and remotes using the entry gate in `AGENTS.md`.
2. Read `AGENTS.md` completely.
3. Read this handoff completely.
4. Inspect the explicit mission and identify its authority and prohibited scope.
5. Inspect the affected production files and their current tests before editing.
6. Run only the existing tests relevant to the changed area; add tests only when required by the mission.
7. Show the final diff, `git diff --check`, test commands, outputs, and exit codes before committing.
8. Do not rebuild or publish images without explicit authorization.
9. Do not touch frozen branches or use force-push.

## 13. Initial v0.2 State

`headless-surveyor-v0.2-dev` starts at v0.1 documentation HEAD `28731aed2ea8d4de9c4c9a308f61b66ef7753045`. This initialization adds only agent governance and handoff documentation.

No runtime version, Dockerfile label, workflow trigger, manifest schema, command, dependency, script, test, package name, checksum behavior, or Surveyor-to-Trainer contract changes in this initialization. Any inherited v0.1 identifiers still present in runtime files are accurate descriptions of the unchanged inherited runtime, not evidence that the branch creation failed.

## 14. Facts Not Verifiable From Git

The following is a statement from the repository owner, not a condition verifiable from the checked-out YAML:

> Los workflows de publicación v0.1 se encuentran desactivados en la interfaz de GitHub Actions.

The workflow file remains present and still describes the v0.1 branch trigger. Do not claim it was deleted or edited. Before any future push to a branch with publication behavior, obtain explicit authorization and verify the relevant GitHub Actions state through an approved mechanism.

## 15. Questions A New Agent Must Not Resolve Alone

The repository owner must authorize decisions about:

- changing any input, output, manifest, package, checksum, or Trainer handoff contract;
- changing `CAMERA_MODEL`, `SINGLE_CAMERA`, matching defaults, or sparse-selection policy;
- changing COLMAP, CUDA, Ubuntu, `gdown`, `runpodctl`, the base image, or other dependencies;
- rebuilding or publishing Docker images or moving/creating release tags;
- modifying Trainer integration, Trainer runtime behavior, training, checkpoints, PLY export, or viewers;
- merging into, documenting on, or otherwise changing frozen v0.1 branches;
- defining professional/commercial quality thresholds or claiming certification;
- expanding Surveyor into dense reconstruction, video extraction, GUI, desktop, streaming, or a combined Full image.

When a mission leaves any of these choices ambiguous, stop and request direction rather than choosing an implementation implicitly.
