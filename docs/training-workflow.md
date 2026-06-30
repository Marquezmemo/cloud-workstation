# Trainer Handoff

Surveyor does not train Gaussian Splatting models.

This branch prepares normalized COLMAP sparse scenes for the Trainer image. The Trainer workflow remains owned by the Trainer branch.

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

The historical `prueba-01` run exposed the multi-model selection gap. The corrected `Prueba02` run evaluated two candidates, selected original model `1` with 30 registered images and 4,555 points, and normalized it to `sparse/0`.

Surveyor can package that scene as:

```text
/workspace/archives/<scene>/<scene>-surveyor-scene.tar.gz
/workspace/archives/<scene>/<scene>-surveyor-scene.tar.gz.sha256
```

## Trainer Acceptance Check

After transfer and unpacking, validate the scene in Trainer:

```bash
train-scene.sh --check <scene>
```

This command is not present in Surveyor.

## Validated Handoff

`Prueba02` validated package transfer, receipt, checksum verification, manual extraction, `train-scene.sh --check Prueba02`, and a 300-step training run. Trainer-side scene extraction is still manual and should be automated in the Trainer branch.
