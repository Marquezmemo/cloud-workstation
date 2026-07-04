# Surveyor Real Run: Prueba02

Status: validated with evidence through Surveyor packaging and Trainer handoff.

## Evidence

- `Surveyor test run.rtf`
- `Prueba02-surveyor-evidence.tar.gz`
- `Prueba02-surveyor-evidence.tar.gz.sha256`
- Trainer receipt/checksum transcript in `Trainer test run con notas.rtf`

Verified evidence archive:

```text
SHA-256: 03d4f4f764e8dc4a53cff4b029781cd31877ec5c795db9f39b6e962dfed21157
Size: 5,802 bytes
```

The full scene archive was reported as 741.1 MB (`777 MB` transfer display). Its checksum file passed both before sending and after receipt in Trainer. The actual scene digest was not included in the local attachments and is not reconstructed here.

## Runtime And Intake

```text
GPU: NVIDIA GeForce RTX 4090
Driver: 565.57.01
Host-visible CUDA: 12.7
Image CUDA: 12.3.1
COLMAP: 3.10-dev
COLMAP commit: 0bd66d901c7549051e21e8f648777f802eb20a73
Ubuntu: 22.04
gdown: 6.1.0
runpodctl: 2.5.0-2fac5fb
matcher: exhaustive
single_camera: 1
camera_model: OPENCV
input images: 30
database images: 30
```

`gdown` downloaded the 737 MB ZIP successfully. `preparar-escena` created `Prueba02` with 30 images and preserved the source ZIP.

## GPU Reconstruction

Feature extraction and matching used CUDA. Scene telemetry reached 95% GPU utilization and approximately 5,090 MiB during the monitored interval.

The mapper produced two sparse candidates:

```text
candidate 0: 2 registered images, 218 points
candidate 1: 30 registered images, 4555 points
```

The selection policy chose original model `1` and normalized it to:

```text
/workspace/scenes/Prueba02/sparse/0
```

Final analyzer result:

```text
Cameras: 1
Registered images: 30
Points: 4555
Observations: 19928
Mean track length: 4.374973
Mean observations per image: 664.266667
Mean reprojection error: 1.133537px
```

## Manifest And Contract

The generated manifest is valid JSON and records:

```text
registered_images=30
sparse_model_count=2
selected_sparse_original_index=1
trainer_ready_sparse_path=/workspace/scenes/Prueba02/sparse/0
```

`validate-surveyor-scene.sh Prueba02` passed with the same values. This confirms the manifest newline and best-model-selection corrections in a clean real run.

## Packaging And Handoff

Scene and evidence archives were created and their portable checksum files passed in Surveyor. Sender-side `runpodctl send` completed for all four files. One mistyped `runpod ctl` command failed with `command not found`, then the correct command succeeded; this was an operator typo, not a product failure.

Trainer subsequently:

- received the scene archive and checksum;
- verified `Prueba02-surveyor-scene.tar.gz: OK`;
- extracted the scene manually;
- passed `train-scene.sh --check Prueba02`;
- completed a 300-step training run.

## Validación downstream posterior confirmada por el operador

```text
handoff_status: passed
validation_authority: repository-owner-operator
evidence_level: operator-confirmed
primary_execution_records: not-preserved
trainer_runtime: 221c4ef76a1ff5bfa8a9f45e5e9a084e8fbedfe3
```

The repository owner and operator confirmed a later downstream execution using the final Trainer runtime that incorporates `preparar-escena`. In that execution:

- the Surveyor package was compatible with Trainer's `preparar-escena`;
- the checksum was accepted;
- the scene was installed correctly;
- `train-scene.sh --check` passed;
- CUDA training completed;
- a checkpoint was generated;
- a PLY was generated and packaged;
- the result was opened in a viewer.

These were downstream Trainer operations that consumed the contract produced by Surveyor. Surveyor did not execute training, checkpoint generation, PLY export or packaging, or the viewer. The primary execution records for this later run were not preserved, so its evidence level is operator-confirmed. This section supplements and does not replace, weaken, or reclassify the preserved Prueba02 evidence elsewhere in this record.

## Verdict

Validated with evidence:

- real ZIP intake and 30-image preparation
- GPU COLMAP execution
- automatic best sparse model selection
- normalization to the Trainer contract
- manifest and scene validation
- packaging and checksum verification
- transfer, receipt, and Trainer dataset acceptance

Still pending in the preserved Prueba02 execution:

- automated Trainer-side scene preparation
- quality thresholds for capture and reconstruction
- OPENCV distortion versus PINHOLE/undistorted workflow evaluation

The later operator-confirmed downstream validation above covers Trainer-side `preparar-escena` compatibility, but it does not convert that result into preserved primary evidence.
