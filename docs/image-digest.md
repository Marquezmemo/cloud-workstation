# Image Digest

`Workstation_v0.1` is pinned to an immutable image digest.

## Base Image

- Mutable tag originally validated:
  `runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04`
- Frozen manifest digest:
  `sha256:61a4aafb0094cd773f11eefa378929d5a687bd775febeb78eac62fc824141fb5`
- Exact Dockerfile reference:
  `runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04@sha256:61a4aafb0094cd773f11eefa378929d5a687bd775febeb78eac62fc824141fb5`

## Correction Note

The original freeze finalization recorded an image index digest by mistake. The active Dockerfile must use the platform manifest digest above.

Incorrect index digest previously recorded:

```text
sha256:6878d595cd929b97acb8cce666c3db7e6709971547d46b2d94362460695f5b29
```

Correct manifest digest:

```text
sha256:61a4aafb0094cd773f11eefa378929d5a687bd775febeb78eac62fc824141fb5
```

## Project Image

- Expected Docker Hub image:
  `docker.io/${DOCKERHUB_USERNAME}/cloud-workstation:v0.1`
- Do not republish or replace this artifact after freeze.
- Do not publish `latest` for this baseline.

## Digest Policy

- Do not use mutable tags as the only source of truth.
- Do not replace the digest for `Workstation_v0.1`.
- Do not move historical Git tags.
- Every future baseline requires a new digest record.
- Every future baseline requires new fingerprinting snapshots.
