# Handoff to The Eye - Trainer v0.1 freeze

## What this package establishes

The final Trainer v0.1 runtime is:

```text
commit: 221c4ef76a1ff5bfa8a9f45e5e9a084e8fbedfe3
digest: sha256:726ac98c9678431fc34fbcc1de0bf07b71adbff215d672f04740a95999a6bf98
```

Its real end-to-end result is classified as:

```text
validation_status: passed
validation_authority: repository-owner-operator
evidence_level: operator-confirmed
primary_execution_records: not-preserved
```

This confirms `preparar-escena`, training, checkpoint, PLY, packaging, transfer and viewer load. It does not provide primary records or missing metrics.

## Do not merge identities

The original Prueba02 runtime remains historical primary evidence:

```text
commit: 90196251d59907754cc19caf76b59a737752893b
digest: sha256:535822530f4b23fca3eee3970b147e3e979162a32c2e9de9f76a829836b63a89
```

That execution used manual extraction and preserves the 300-step, checkpoint, PLY and SuperSplat evidence. Its metrics must not be attributed to the final run.

## Proposed immutable tags

- Git: `trainer-v0.1.0-smoke-validated` -> `221c4ef76a1ff5bfa8a9f45e5e9a084e8fbedfe3`
- Docker: `headless-gsplat-v0.1.0` -> `sha256:726ac98c9678431fc34fbcc1de0bf07b71adbff215d672f04740a95999a6bf98`

Create the Docker tag by digest-preserving registry retag only. Do not rebuild.

## Documentation facts to integrate

1. Prueba02 validated the Surveyor-to-Trainer smoke path through SuperSplat.
2. The OPENCV warning does not mean distortion is ignored. The fixed parser computes corrected intrinsics, remaps, crops the valid ROI and trains on the corrected image/K pair.
3. Surveyor does not run image undistortion; Trainer performs one remap.
4. Warn against changing only one half of the camera contract, which can cause double undistortion.
5. `preparar-escena` is part of the final baseline and is regression-tested plus operator-confirmed in real operation; primary execution records were not preserved.
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
