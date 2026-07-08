# Converter v0.2 Initial Checklist

## Branch Scope

- [ ] Confirm branch is `headless-converter-v0.2-dev`.
- [ ] Confirm base is `origin/workstation-v0.2-dev` unless the Governor changes it.
- [ ] Do not merge Surveyor or Trainer branches.
- [ ] Do not modify Trainer training logic.
- [ ] Do not modify Surveyor logic.

## Input Handling

- [ ] Accept a local Trainer `.ply` path.
- [ ] Support a remote artifact reference when `runpodctl` is available.
- [ ] Download remote `.ply` artifacts only when requested or required.
- [ ] Record input file size before conversion.
- [ ] Keep staged inputs under `converter/input/`.

## Format Conversion

- [ ] Detect available conversion tools before selecting targets.
- [ ] Attempt SPZ when supported.
- [ ] Attempt SOG when supported.
- [ ] Attempt Streamed SOG / LOD when supported.
- [ ] Attempt compressed PLY when supported.
- [ ] Attempt SPLAT / KSPLAT when supported.
- [ ] Generate an HTML viewer bundle when supported.
- [ ] Generate voxel collision output when supported.
- [ ] Mark unsupported targets as skipped with reasons.

## CPU-First Constraint

- [ ] Keep CUDA optional.
- [ ] Do not introduce required GPU-only dependencies.
- [ ] Document any optional acceleration separately from required workflow.
- [ ] Validate the workflow on modest local assumptions.

## Reporting

- [ ] Generate `converter/reports/conversion-report.json`.
- [ ] Generate `converter/reports/conversion-report.md`.
- [ ] Include input path/source and input size.
- [ ] Include each attempted target, tool, output path, and final size.
- [ ] Include skipped targets and reasons.
- [ ] Include packaging result.
- [ ] Include errors and recovery hints.

## Packaging

- [ ] Place converted artifacts under `converter/output/`.
- [ ] Place packaged bundles under `converter/packages/`.
- [ ] Preserve report files with the packaged results.
- [ ] Keep packaging suitable for download or later upload.
