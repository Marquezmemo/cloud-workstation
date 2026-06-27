# Trainer Handoff

Surveyor does not train Gaussian Splatting models.

This branch prepares COLMAP sparse candidates for the Trainer image. The Trainer workflow remains owned by the Trainer branch.

## Surveyor Responsibility

Surveyor produces:

```text
/workspace/scenes/<scene>/
+-- images/
+-- database.db
+-- sparse/
    +-- 0/
        +-- cameras.bin
        +-- images.bin
        +-- points3D.bin
    +-- possible additional models
+-- surveyor-manifest.json
```

The first real run generated multiple reconstruction attempts. `sparse/0` contains only 2 registered images even though the mapper log later reached 30. The current output must not be called Trainer-ready until the best sparse model is selected and normalized.

Surveyor can package that scene as:

```text
/workspace/archives/<scene>/<scene>-surveyor-scene.tar.gz
/workspace/archives/<scene>/<scene>-surveyor-scene.tar.gz.sha256
```

## Trainer Acceptance Check

After best-model selection is resolved, transfer and unpack the scene into the Trainer workspace and validate it:

```bash
train-scene.sh --check <scene>
```

This command is not present in Surveyor.

## Pending Handoff Validation

- Identify the sparse model with the highest registered-image count.
- Normalize the selected model in the Surveyor output contract and manifest.
- Repeat a clean Surveyor run after the permanent manifest correction.
- Package it with `package-surveyor-scene.sh <scene>`.
- Move or unpack it into the Trainer workspace.
- Confirm `train-scene.sh --check <scene>` passes.
- Confirm a 100-step training run succeeds.
- Record the exact package path, checksum, Trainer image tag, and validation result.
