# The Converter v0.2

The Converter receives Gaussian Splatting `.ply` output from The Trainer, stages
conversion inputs, writes converted artifacts, records output sizes, and packages
results for download or upload.

The workflow is CPU-first. CUDA is not a required dependency.

## Quick Start

```bash
./converter/scripts/convert-scene.sh \
  --input converter/input/scene.ply \
  --scene-name room_test_001 \
  --preset benchmark
```

```bash
./converter/scripts/convert-scene.sh \
  --input converter/input/scene.ply \
  --scene-name room_test_001 \
  --preset mac-preview
```

## Docker

```bash
docker build -f converter/Dockerfile -t cloud-workstation-converter:v0.2 .
```

```bash
docker run --rm \
  -v "$PWD/converter/input:/workspace/converter/input" \
  -v "$PWD/converter/output:/workspace/converter/output" \
  -v "$PWD/converter/reports:/workspace/converter/reports" \
  -v "$PWD/converter/packages:/workspace/converter/packages" \
  cloud-workstation-converter:v0.2 \
  --input converter/input/scene.ply \
  --scene-name room_test_001 \
  --preset benchmark
```

## Presets

- `benchmark`: attempts every configured output and writes comparative reports.
- `mac-preview`: prioritizes SOG, Streamed SOG/LOD, HTML viewer, SPZ, and
  compressed PLY for lightweight review.
- `archive-master`: preserves the master PLY copy and attempts high-value
  archive outputs.

## Outputs

- `converter/output/<scene-name>/`
- `converter/reports/conversion-report.json`
- `converter/reports/conversion-report.md`
- `converter/reports/file-sizes.csv`
- `converter/reports/checksums.sha256`
- `converter/packages/<scene-name>-converter-results.tar.gz`

Unsupported targets are reported as `skipped` with a reason instead of forcing a
GPU stack or heavyweight editor dependency.
