# Converter RunPod Usage

The Converter image is CPU-first. It can run on a CPU pod and does not require
CUDA. GPU-enabled pods may still be used when an optional conversion tool can
benefit from them, but CUDA is not part of the contract.

## Build

From the repository root:

```bash
docker build -f converter/Dockerfile -t cloud-workstation-converter:v0.2 .
```

If the npm package name for `splat-transform` changes or is unavailable:

```bash
docker build \
  -f converter/Dockerfile \
  --build-arg SPLAT_TRANSFORM_PACKAGE=splat-transform \
  --build-arg INSTALL_SPLAT_TRANSFORM=0 \
  -t cloud-workstation-converter:v0.2 .
```

## Local Conversion

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

## Docker Conversion

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

## RunPod Artifact Fetch

When a Trainer `.ply` artifact is available through `runpodctl`, fetch it first:

```bash
./converter/scripts/fetch-ply-runpodctl.sh \
  --source <runpod-artifact-reference> \
  --output converter/input/scene.ply
```

Then run the same conversion command inside the pod or container.

## Outputs To Download

Download or upload:

- `converter/output/<scene-name>/`
- `converter/reports/conversion-report.json`
- `converter/reports/conversion-report.md`
- `converter/reports/file-sizes.csv`
- `converter/reports/checksums.sha256`
- `converter/packages/<scene-name>-converter-results.tar.gz`
