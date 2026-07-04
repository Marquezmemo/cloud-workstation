# Handoff To The Eye - The Surveyor v0.1

This directory is a proposal/evidence handoff. It does not modify canonical project documentation or Surveyor runtime behavior.

## Frozen Source

```text
source branch: headless-surveyor-v0.1-dev
source commit: 01b7f6876f0af933e610eb67a3583cb628ea2ddd
audit branch: audit/surveyor-v0.1-freeze
source tree at inspection: clean
```

## Files

- `surveyor-v0.1-freeze-report.md`: human-readable forensic report and recovery procedure.
- `surveyor-v0.1-freeze-manifest.json`: machine-readable identity, evidence, workflow, and test record.
- `output/pdf/The-Surveyor-v0.1-Freeze-Report.pdf`: rendered report artifact.
- `output/pdf/SHA256SUMS`: checksum for the rendered PDF.

## Trust Levels

### Independently observed in this audit

- Git remote, source branch, exact commit, clean tree, and empty diff.
- Dockerfile, base digest, OCI labels, dependency pins, scripts, contracts, and workflow definitions.
- Existing local non-GPU tests and their exit codes.
- Latest existing GitHub Actions run status and CI-reported push digest.
- Absence of Docker tooling on the inspection Mac.

### Recorded from versioned Prueba02 evidence

- 30 input/database/registered images.
- Two sparse candidates; original model `1` selected and normalized to `sparse/0`.
- 4,555 points, 19,928 observations, track length `4.374973`, and reprojection error `1.133537 px`.
- Packaging, checksum verification, Trainer receipt, `train-scene.sh --check`, and 300-step training.

The external Prueba02 attachments were not present locally during this audit, so their reported checksum was not independently recomputed.

## Pending Blocking Item

The stable Docker digest remains `PENDING` because Docker/Buildx is unavailable locally. CI reported:

```text
sha256:51e9a9236cdc8c8351195709e5f0a864a01c62d4a79251f71e182219acdeb7d8
```

The Eye must not treat this as independently verified until a Docker-capable host runs `docker pull`, `docker image inspect`, or `docker buildx imagetools inspect` against the current development tag.

## Proposed Tags - Not Created

```text
Git: surveyor-v0.1.0-smoke-validated
Docker: headless-surveyor-v0.1.0
```

The Docker tag must point to the verified existing digest. Do not rebuild.

## Final Downstream Confirmation

Final Surveyor documentation commit: `28731aed2ea8d4de9c4c9a308f61b66ef7753045`.

The repository owner and operator confirmed that final Trainer runtime `221c4ef76a1ff5bfa8a9f45e5e9a084e8fbedfe3`, digest `sha256:726ac98c9678431fc34fbcc1de0bf07b71adbff215d672f04740a95999a6bf98`, consumed the Surveyor package successfully through `preparar-escena`, CUDA training, checkpoint, PLY packaging, transfer and viewer load.

```text
validation_status: passed
validation_authority: repository-owner-operator
evidence_level: operator-confirmed
primary_execution_records: not-preserved
```

This confirmation supplements Prueba02 and does not replace its preserved primary evidence.

## Integration Checklist For The Eye

1. Verify the published digest independently.
2. Approve and create the immutable Git tag at the recorded source commit.
3. Retag/copy the existing Docker digest to the stable tag without rebuilding.
4. Integrate the architecture, dependency, command, variable, workspace, and data-contract inventory.
5. Integrate Prueba02 evidence with this exact statement:

   > Esta evidencia valida funcionalidad, reconstrucción sparse y handoff. No valida calidad profesional ni comercial.

6. Document the mutable-development-tag risk and recovery procedure.
7. Preserve the distinction between CI-reported and independently verified digest values.

## Prohibited During Freeze

- No commits or pushes to `headless-surveyor-v0.1-dev`.
- No image rebuild to create the stable tag.
- No dependency, runtime, COLMAP, CUDA, Ubuntu, camera, sparse-selection, or Trainer contract change.
- No new GPU run without explicit authorization.
