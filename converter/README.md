# The Converter v0.2

This directory is the local workspace for Converter-owned conversion assets.

The Converter receives Gaussian Splatting `.ply` output from The Trainer, stages
conversion inputs, writes converted artifacts, records output sizes, and packages
results for download or upload.

## Ownership

Converter may own files under:

- `converter/input/`
- `converter/output/`
- `converter/reports/`
- `converter/packages/`
- `converter/tools/`
- `docs/converter-contract.md`
- `docs/converter-checklist.md`

Converter must not modify Trainer or Surveyor implementation logic.

## Runtime Direction

The conversion path must remain CPU-first. GPU/CUDA acceleration may be optional
when a tool supports it, but CUDA must not become a required dependency for the
Converter workflow.
