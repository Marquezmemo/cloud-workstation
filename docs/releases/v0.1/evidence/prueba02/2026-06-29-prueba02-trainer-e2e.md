# Prueba02 — Trainer End-to-End Validation

Date: 2026-06-29 (Aguascalientes, Aguascalientes)

Branch: `headless-gsplat-v0.1-dev`

Evidence status: `validated with evidence`

## Conclusion

> Pipeline funcional validado desde la preparación de imágenes hasta un PLY válido, transferido y cargado en SuperSplat; calidad profesional y comercial todavía no validadas.

This run validates the Surveyor-to-Trainer handoff, scene validation, a short GPU training run, checkpoint creation, standard and compressed PLY export, packaging, transfer, independent PLY inspection, and visual loading of the standard PLY in SuperSplat.

It does not validate reconstruction quality, commercial usability, or densification.

## Input And Scene Preparation

- Received Surveyor scene archive: `741.1 MB`.
- The received archive checksum matched its supplied checksum.
- `train-scene.sh --check Prueba02` initially failed because the archive had not been extracted under `/workspace/scenes/Prueba02`.
- The operator created the scene directory and extracted the archive manually.
- The repeated dataset check passed.
- The parser loaded `30` images and `1` camera.
- The camera model was `OPENCV`; the trainer emitted its distortion warning.

The required manual extraction is evidence of a missing Trainer preparation step, not a failed Surveyor handoff.

## Training Result

Command depth: `MAX_STEPS=300`.

| Observation | Result |
| --- | ---: |
| Training status | completed |
| Duration | `2:20` |
| Throughput | `2.13 it/s` |
| Final reported loss | `0.196` |
| Checkpoint | `ckpt_299_rank0.pt` |
| Initial Gaussian count | `4,555` |
| Final Gaussian count | `4,555` |
| Reported GPU memory | `3.2356 GB` |

The unchanged Gaussian count means this run does **not** demonstrate densification. The loss value is recorded for reproducibility only and is not accepted as a quality score.

The first execution also recorded:

- CUDA extension setup: `61.61 s`;
- initial AlexNet download: `233 MB`;
- a future-behavior warning from `torch.load`.

These are operational observations and remain optimization or maintenance backlog items.

## Export, Packaging, And Transfer

- Running `empaquetar Prueba02` before export failed because no PLY exports existed.
- Running `generar` with one unambiguous scene selected `Prueba02` and exported both native formats.
- Standard PLY size: `1,076,455 bytes`.
- Compressed PLY size: `280,894 bytes`.
- Both exports reported `4,555` vertices.
- Packaging completed and the result was sent with `runpodctl`.
- The successful operator sequence was `generar --scene Prueba02` (or unambiguous `generar`) followed by `empaquetar Prueba02`; the failed reverse order remains useful UX evidence.

Ephemeral `runpodctl` transfer codes are intentionally not retained in Git.

## Independent Standard PLY Inspection

Artifact inspected outside the pod: `Prueba02.ply`.

| Property | Result |
| --- | --- |
| SHA-256 | `f7acbb332667a028756f7f2426dd07bfde577f66f30ef0dfa27b02449eea5c71` |
| Encoding | `binary_little_endian` |
| Vertices | `4,555` |
| Vertex properties | `59` float properties |
| Payload | exact for the declared header and vertex layout |
| Non-finite values | `0` NaN, `0` infinities |

This establishes structural validity of the standard export. It does not establish visual quality.

## SuperSplat Compatibility

![Prueba02.ply loaded in SuperSplat](../evidence/prueba02-supersplat.png)

The screenshot validates that:

- `Prueba02.ply` loaded in the scene manager;
- SuperSplat rendered the scene;
- the application recognized `4,555` splats;
- compatibility was observed with SuperSplat `v2.27.4`.

The image is evidence of successful loading and rendering only. Blur, framing, color, geometry quality, capture discipline, and commercial suitability were not evaluated.

### Screenshot provenance

The repository contains a deterministic crop with no generative processing. Browser tabs, address bar, and profile UI were removed; the source screenshot itself is not versioned.

| File | SHA-256 | Dimensions | Size |
| --- | --- | ---: | ---: |
| Original operator screenshot | `1641f39c27ed03bcab42f1a99dc9c66573078ca4c15cb98f544e588d7e1a9670` | `2880×1800` | `2,450,261 bytes` |
| `docs/evidence/prueba02-supersplat.png` | `5c18b61b221311d61769e54842dc29fe6c6c2fd1b0d85bd58ff717a0134aac28` | `2880×1620` | `1,906,249 bytes` |

## Evidence Basis

The conclusion was cross-checked against:

- the operator's Surveyor and Trainer run transcripts;
- Surveyor's `Prueba02` manifest, sparse selection, model analysis, and checksums;
- Trainer console output and manually recorded execution order;
- independent inspection of `Prueba02.ply`;
- the preserved SuperSplat screenshot crop.

Large scene archives, RTF transcripts, PLY files, and ephemeral transfer codes remain outside Git.

## Open Work

- automate safe scene archive preparation in Trainer;
- improve corrective messaging for `generar --scene <scene>` before `empaquetar <scene>`;
- investigate the `61.61 s` first CUDA extension setup;
- control or cache the initial `233 MB` AlexNet dependency;
- address the future `torch.load` warning;
- evaluate `OPENCV` input against a `PINHOLE` or undistorted path;
- collect PSNR, SSIM, LPIPS, and comparable renders;
- validate densification and Gaussian growth;
- validate professional capture practice and commercial output quality;
- test transfers above `1 GB`, interruption behavior, resume support, and measured throughput.

These are backlog items, not commands or capabilities claimed by the current image.
