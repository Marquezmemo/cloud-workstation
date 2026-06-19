# PLY Export

PLY export is not a Surveyor capability.

Surveyor produces COLMAP sparse reconstruction artifacts for the Trainer. PLY generation belongs to the Trainer image after training has produced checkpoints.

## Surveyor Output

Surveyor output stops at:

```text
/workspace/scenes/<scene>/sparse/0
/workspace/scenes/<scene>/surveyor-manifest.json
/workspace/archives/<scene>/<scene>-surveyor-scene.tar.gz
```

## Trainer Responsibility

After the Trainer accepts a Surveyor-generated scene and completes training, the Trainer branch handles:

```text
generar
empaquetar
comprimir
PLY and compressed PLY exports
```

Those commands are intentionally not part of `headless-surveyor-v0.1-dev`.
