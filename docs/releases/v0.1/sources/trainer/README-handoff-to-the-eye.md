# Handoff to The Eye - Trainer v0.1 freeze

## What this package establishes

The evidence-backed Prueba02 runtime is the image produced from commit:

```text
90196251d59907754cc19caf76b59a737752893b
```

and published as:

```text
sha256:535822530f4b23fca3eee3970b147e3e979162a32c2e9de9f76a829836b63a89
```

The association is based on immutable GitHub Actions chronology. The pod did not preserve its own resolved image digest, so this must remain labeled as a forensic inference.

## Do not merge identities

The source branch later advanced to `221c4ef`, whose successful image digest is:

```text
sha256:726ac98c9678431fc34fbcc1de0bf07b71adbff215d672f04740a95999a6bf98
```

That later image adds `preparar-escena` and regression tests. It was not the image that ran Prueba02.

## Proposed immutable tags

- Git: `trainer-v0.1.0-smoke-validated` -> `90196251d59907754cc19caf76b59a737752893b`
- Docker: `headless-gsplat-v0.1.0` -> `sha256:535822530f4b23fca3eee3970b147e3e979162a32c2e9de9f76a829836b63a89`

Create the Docker tag by digest-preserving registry retag only. Do not rebuild.

## Documentation facts to integrate

1. Prueba02 validated the Surveyor-to-Trainer smoke path through SuperSplat.
2. The OPENCV warning does not mean distortion is ignored. The fixed parser computes corrected intrinsics, remaps, crops the valid ROI and trains on the corrected image/K pair.
3. Surveyor does not run image undistortion; Trainer performs one remap.
4. Warn against changing only one half of the camera contract, which can cause double undistortion.
5. `preparar-escena` is post-Prueba02 functionality. It has regression/CI evidence, not Prueba02 runtime evidence.
6. The 0.196 loss is a reproducibility observation, not a quality score.
7. No densification, professional quality or commercial quality was validated.
8. Standard PLY non-finite inspection is independently preserved. The compressed PLY zero-NaN/zero-infinity claim is operator-supplied but its raw independent inspection is not versioned.

## Evidence set

- `trainer-v0.1-freeze-report.md`: editable source and full reasoning.
- `trainer-v0.1-freeze-manifest.json`: machine-readable identities and evidence grades.
- `The-Trainer-v0.1-Freeze-Report.pdf`: reviewed rendering of the report.
- `SHA256SUMS`: checksums for the delivered evidence files.

## The Eye checklist

- Verify proposed Git tag target before creating it.
- Verify proposed Docker tag resolves to the validated digest after registry retag.
- Keep the development and stable tags distinct.
- Integrate facts into official docs in a separate authorized change.
- Preserve evidence limitations verbatim.
- Do not copy the unrelated Surveyor freeze artifacts found in the original shared worktree.
