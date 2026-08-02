# Converter Contract v0.2

## Purpose

The Converter turns a `.ply` file produced by The Trainer into portable Gaussian
Splatting outputs and reports enough metadata for downstream download, upload,
viewer, and collision workflows.

The Converter is an integration boundary between training output and standard
delivery formats. It is not a training agent, Surveyor agent, visual editor, or
manual cleanup tool.

## Inputs

Required input:

- A Gaussian Splatting `.ply` artifact produced by The Trainer.

Optional inputs:

- A local file path to the Trainer artifact.
- A remote artifact reference that can be downloaded with `runpodctl`.
- Conversion profile or requested target format list.
- Packaging destination metadata for later download or upload.

Input staging should use:

- `converter/input/`

## Download Contract

When the Trainer output is not already local, Converter may use `runpodctl` to
download the `.ply` artifact.

The download step must record:

- source reference
- destination path
- file size
- command used, when safe to disclose
- success or failure

Converter must not assume a powerful local workstation. Large files should be
handled with simple streaming or file-based workflows where possible.

## Output Targets

Converter should prefer open or widely used Gaussian Splatting targets when the
available local toolchain supports them:

- SPZ
- SOG
- Streamed SOG / LOD
- compressed PLY
- SPLAT / KSPLAT
- HTML viewer bundle
- voxel collision artifact

If a target format is unavailable, Converter should report it as skipped with a
clear reason instead of silently failing or adding mandatory heavyweight
dependencies.

Output artifacts should use:

- `converter/output/`

Packaged bundles should use:

- `converter/packages/`

## Reports

Converter must generate:

- `converter/reports/conversion-report.json`
- `converter/reports/conversion-report.md`
- `converter/reports/file-sizes.csv`
- `converter/reports/checksums.sha256`

The reports should include:

- input artifact path or source reference
- input file size
- conversion targets attempted
- tool used for each target
- output path for each successful target
- final size of each output
- skipped targets and reasons
- packaging result
- CPU/GPU requirement notes
- errors and recovery hints

## Presets

The supported preset names are:

- `benchmark`: attempt all configured targets and compare resulting file sizes.
- `mac-preview`: prioritize SOG, Streamed SOG/LOD, HTML viewer, SPZ, and
  compressed PLY for lightweight Mac evaluation.
- `archive-master`: preserve the master PLY and prioritize SPZ, SOG,
  checksums, and report completeness.

Every preset must keep the same reporting and packaging contract. Missing tools
must produce explicit skipped target records.

## Runtime Limits

Converter must remain CPU-first.

Allowed:

- optional GPU acceleration when a chosen tool supports it
- optional local tool detection
- optional `runpodctl` download support
- measuring artifact sizes
- packaging results

Not allowed:

- making CUDA a required dependency
- modifying Trainer logic
- modifying Surveyor logic
- merging active agent branches
- manual splat cleanup
- visual splat editing
- assuming workstation-grade local hardware
- installing Blender, Unity, or SuperSplat Studio as mandatory dependencies

## Integration Boundaries

Trainer owns generation of the source `.ply`.

Converter owns format conversion, size measurement, reporting, and packaging.

Surveyor remains out of scope for Converter except for consuming documented
outputs through an explicit future contract.

Changes to shared runtime dependencies, Dockerfile packages, or protected paths
require coordinator review or a handoff.
