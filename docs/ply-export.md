# PLY Export

PLY export is not a Surveyor capability.

Surveyor produces and normalizes the selected COLMAP sparse reconstruction. PLY generation belongs to the Trainer image after handoff validation and training have produced checkpoints.

## Surveyor Output

Surveyor output stops at:

```text
/workspace/scenes/<scene>/sparse/*
/workspace/scenes/<scene>/surveyor-manifest.json
/workspace/archives/<scene>/<scene>-surveyor-scene.tar.gz
```

Surveyor normalizes the selected best model to `sparse/0`. `Prueba02` validated this handoff and Trainer subsequently generated both standard and compressed PLY exports.

## Trainer Responsibility

After the Trainer accepts a Surveyor-generated scene and completes training, the Trainer branch handles:

```text
generar
empaquetar
comprimir
PLY and compressed PLY exports
```

Those commands are intentionally not part of the inherited `headless-surveyor-v0.1-dev` runtime or the active `headless-surveyor-v0.2-dev` Surveyor scope.
