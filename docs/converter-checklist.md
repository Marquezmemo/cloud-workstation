# Converter v0.2 Checklist

## Branch Scope

- [x] Confirm branch is `headless-converter-v0.2-dev`.
- [ ] Confirm base is `origin/workstation-v0.2-dev` unless the Governor changes it.
- [ ] Do not merge Surveyor or Trainer branches.
- [ ] Do not modify Trainer training logic.
- [ ] Do not modify Surveyor logic.

## Input Handling

- [x] Accept a local Trainer `.ply` path.
- [x] Support a remote artifact reference when `runpodctl` is available.
- [x] Download remote `.ply` artifacts only when requested or required.
- [x] Record input file size before conversion.
- [x] Keep staged inputs under `converter/input/`.

## Format Conversion

- [x] Detect available conversion tools before selecting targets.
- [x] Attempt SPZ when supported.
- [x] Attempt SOG when supported.
- [x] Attempt Streamed SOG / LOD when supported.
- [x] Attempt compressed PLY when supported.
- [x] Attempt SPLAT / KSPLAT when supported.
- [x] Generate an HTML viewer bundle when supported.
- [x] Generate voxel collision output when supported.
- [x] Mark unsupported targets as skipped with reasons.

## CPU-First Constraint

- [x] Keep CUDA optional.
- [x] Do not introduce required GPU-only dependencies.
- [x] Document any optional acceleration separately from required workflow.
- [x] Validate the workflow on modest local assumptions.

## Reporting

- [x] Generate `converter/reports/conversion-report.json`.
- [x] Generate `converter/reports/conversion-report.md`.
- [x] Generate `converter/reports/file-sizes.csv`.
- [x] Generate `converter/reports/checksums.sha256`.
- [x] Include input path/source and input size.
- [x] Include each attempted target, tool, output path, and final size.
- [x] Include skipped targets and reasons.
- [x] Include packaging result.
- [x] Include errors and recovery hints.

## Packaging

- [x] Place converted artifacts under `converter/output/`.
- [x] Place packaged bundles under `converter/packages/`.
- [x] Preserve report files with the packaged results.
- [x] Keep packaging suitable for download or later upload.
