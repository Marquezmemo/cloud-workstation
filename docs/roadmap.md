# Roadmap

Roadmap for the headless Surveyor COLMAP image.

## Current Status

- Surveyor v0.1 branch created the inherited runtime; active v0.2 work continues on `headless-surveyor-v0.2-dev`.
- Dockerfile uses a pinned COLMAP 3.10/CUDA 12.3.1 image digest.
- `validate-surveyor.sh`, `survey-scene.sh`, and `package-surveyor-scene.sh` exist.
- Docker Hub publish workflow still describes the inherited `headless-surveyor-v0.1-dev` image line and is not changed by this documentation branch.
- Pinned `runpodctl v2.5.0`, hashed `gdown 6.1.0`, and complete scene/evidence validation are implemented.
- Trainer and `gsplat` runtime scripts were removed from this branch.
- Synthetic contract tests are locally verified. Earlier image-build and container checks remain operator-reported because their logs were not preserved.
- The first real `prueba-01` run validated RunPod startup, 30-image intake, GPU reconstruction execution, packaging, checksums, and `runpodctl send`.
- The `prueba-01` Trainer handoff was blocked because `sparse/0` reported 2 registered images while a later mapper reconstruction reached 30.
- `Prueba02` validated the corrected best-model selection: original model `1`, 30 registered images, 4,555 points, normalized to `sparse/0`.
- The `Prueba02` package was received and checksum-verified by Trainer; dataset validation and a 300-step run completed.
- A later two-pod `Prueba02` flow confirmed Trainer-side `preparar-escena`, dataset acceptance, 5000-step downstream training, checkpoint creation, PLY export, PLY packaging, transfer, and viewer opening. Those downstream stages remain Trainer responsibilities.
- The local Surveyor/Trainer multiagent setup is functional manually with separate checkouts and branches; automatic orchestration is not implemented.

## Validación downstream posterior confirmada por el operador

```text
handoff_status: passed
validation_authority: repository-owner-operator
evidence_level: operator-confirmed
primary_execution_records: not-preserved
trainer_runtime: 221c4ef76a1ff5bfa8a9f45e5e9a084e8fbedfe3
```

The repository owner and operator confirmed that the final Trainer runtime incorporating `preparar-escena` consumed the Surveyor package successfully: the package was compatible with the preparation command, the checksum was accepted, the scene was installed, and `train-scene.sh --check` passed. Downstream Trainer then completed CUDA training, generated a checkpoint, generated and packaged a PLY, and opened the result in a viewer.

Surveyor did not execute those Trainer stages. The primary records from this later execution were not preserved, so the result is classified as operator-confirmed and does not replace or downgrade the preserved Prueba02 evidence.

## Immediate Next Steps

1. Repeat the corrected Surveyor flow with additional capture sets.
2. Define registered-image and reconstruction-quality acceptance thresholds.
3. Evaluate OPENCV distortion handling versus an undistorted/PINHOLE handoff.
4. Preserve each new run's commands, hashes, logs, manifest, selection report, and downstream handoff result.

## Later Work

- Decide whether additional capture guidance is needed after real dataset tests.
- Evaluate when `MATCHER=sequential` should become the recommended path.
- Decide if dense reconstruction belongs in a future Surveyor phase.
- Add packaging stage messages and real byte-based progress, preferably with `pv` or equivalent; never display invented percentages.
- Create the future Full image only after Surveyor and Trainer handoff contracts are stable.

## Criteria

Surveyor progress must be evidence-based:

- no desktop, viewer, VNC, Blender, or streaming work
- no `gsplat` or Trainer runtime added back to this branch
- no dense reconstruction as default inherited runtime behavior
- every real scene smoke test records logs, manifest, package, checksum, and Trainer handoff result
