# Surveyor Real Run: prueba-01

Status: partial validation with evidence. Surveyor execution and export succeeded, but Trainer handoff is blocked pending best sparse model selection.

## Evidence Sources

- `prueba-01-surveyor-evidence.tar.gz`
- `prueba-01-surveyor-evidence.tar.gz.sha256`
- `prueba-01-surveyor-scene.tar.gz.sha256`
- operator-provided `runpodctl send` capture
- commits `771107f` and `946b732`
- successful workflow run `28295373995`

Observed checksums:

```text
7c3129ed0c26ce6eee9b2df160cae5af97077dbfe74619085b8dce93086af1cd  prueba-01-surveyor-evidence.tar.gz
12b89e5d3c54270c71b2c03b8b81beb547cf1bf16f28331405489c93afd02dbc  prueba-01-surveyor-scene.tar.gz
```

The evidence archive checksum was independently recalculated before this record was written and matched its checksum file.

## Runtime And Input

Evidence from `surveyor.env` and the repaired manifest:

```text
scene=prueba-01
input_image_count=30
database_images=30
matcher=exhaustive
colmap_use_gpu=1
single_camera=1
camera_model=OPENCV
colmap_version=COLMAP 3.10-dev
colmap_commit=0bd66d901c7549051e21e8f648777f802eb20a73
cuda_version=12.3.1
ubuntu_version=22.04
gdown_version=gdown 6.1.0
runpodctl_version=runpodctl 2.5.0-2fac5fb
```

The preparation flow successfully downloaded and prepared a ZIP with 30 supported images. Synthetic tests cover filtering of `__MACOSX`, `.DS_Store`, and AppleDouble `._*` metadata.

## GPU Evidence

`surveyor-gpu.log` identifies an NVIDIA GeForce RTX 4090. During feature extraction and matching, samples reached 60% GPU utilization and approximately 5088 MiB memory usage. This supports GPU activity for the Surveyor run; it is not a reconstruction-quality measurement.

## Sparse Reconstruction Conflict

`model-analyzer.txt` analyzes:

```text
/workspace/scenes/prueba-01/sparse/0
```

and reports:

```text
Cameras: 1
Images: 2
Registered images: 2
Points: 219
Mean reprojection error: 0.452271px
```

In contrast, `colmap-mapper.log` later reaches:

```text
Registering image #30 (30)
```

This is consistent with multiple sparse reconstruction attempts. It does not prove that `sparse/0` contains the 30-image model. The current script runs `model_analyzer` on `sparse/0`, the manifest points to `sparse/0`, and the validator checks that directory structurally without comparing other models.

Critical pending item: identify the model with the highest registered-image count and normalize the Surveyor output contract before Trainer handoff.

## Manifest Repair

The initial run manifest ended with literal `\n` and was invalid for `jq`. The scene artifact was repaired manually and then passed:

```text
surveyor_scene_validation=passed
scene=prueba-01
image_count=30
database_images=30
colmap_use_gpu=1
```

The manifest included in the evidence archive is the repaired, valid JSON file. This proves the manual repair, not a permanent repository correction. Commit `946b732` still contains the source form that produced the issue; a code fix and clean rerun remain pending.

## Packaging And Export

Scene and evidence archives plus relative checksum files were generated successfully. The operator-provided capture confirms sender-side `runpodctl send` progress with speed, transferred bytes, and percentage.

Validated:

- package creation
- portable checksum generation
- evidence archive checksum match
- sender-side `runpodctl send`

Not yet evidenced:

- package reception at the destination
- destination checksum verification
- Trainer consumption

Packaging may remain silent during compression. Stage messages and real byte-based progress are a pending usability improvement, not existing behavior.

## Preparation Test Correction

GitHub Actions initially failed because the test isolated only `WORKSPACE_ROOT` while the image environment already defined `INCOMING_DIR`, `SCENES_DIR`, and `TEMP_DIR`. Commit `771107f` introduced a helper that isolates all four paths. Commit `946b732` removed temporary diagnostics after the correction. Workflow run `28295373995` is recorded as successful.

## Verdict

Validated with evidence:

- RunPod startup and expected runtime
- real 30-image intake and database population
- GPU-enabled COLMAP feature extraction and matching
- mapper execution reaching a 30-image reconstruction attempt
- package and checksum generation
- sender-side `runpodctl send`

Pending and blocking Trainer handoff:

- select and validate the best sparse model
- normalize the selected model path
- permanently correct manifest generation
- repeat a clean run
- receive and verify transferred packages
- run Trainer path validation and a 100-step smoke test
