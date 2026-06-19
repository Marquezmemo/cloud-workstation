# Trainer Handoff

Surveyor does not train Gaussian Splatting models.

This branch prepares COLMAP sparse scenes for the Trainer image. The Trainer workflow remains owned by the Trainer branch.

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
+-- surveyor-manifest.json
```

Surveyor can package that scene as:

```text
/workspace/archives/<scene>/<scene>-surveyor-scene.tar.gz
/workspace/archives/<scene>/<scene>-surveyor-scene.tar.gz.sha256
```

## Trainer Acceptance Check

After transfer and unpacking into the Trainer workspace, validate the scene in the Trainer image:

```bash
train-scene.sh --check <scene>
```

This command is not present in Surveyor.

## Pending Handoff Validation

- Generate a real Surveyor scene on RunPod.
- Package it with `package-surveyor-scene.sh <scene>`.
- Move or unpack it into the Trainer workspace.
- Confirm `train-scene.sh --check <scene>` passes.
- Record the exact package path, checksum, Trainer image tag, and validation result.
