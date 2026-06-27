# PLY Export

PLY export is not a Surveyor capability.

Surveyor produces one or more COLMAP sparse reconstruction artifacts. PLY generation belongs to the Trainer image only after the best sparse model has been selected, the handoff has been validated, and training has produced checkpoints.

## Surveyor Output

Surveyor output stops at:

```text
/workspace/scenes/<scene>/sparse/*
/workspace/scenes/<scene>/surveyor-manifest.json
/workspace/archives/<scene>/<scene>-surveyor-scene.tar.gz
```

The current Surveyor automation points to `sparse/0`, but the first real run showed that this directory may not contain the reconstruction with the most registered images. PLY export remains downstream and must not be used to imply that the current Surveyor handoff is validated.

## Trainer Responsibility

After the Trainer accepts a Surveyor-generated scene and completes training, the Trainer branch handles:

```text
generar
empaquetar
comprimir
PLY and compressed PLY exports
```

Those commands are intentionally not part of `headless-surveyor-v0.1-dev`.
