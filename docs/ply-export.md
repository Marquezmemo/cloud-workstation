# PLY Export

`headless-gsplat-v0.1-dev` can train `gsplat` headlessly and save checkpoints. A real RunPod RTX 4090 run reached 30,000 iterations and generated checkpoint tensors successfully.

The missing `.ply` was not a pipeline failure. The official `simple_trainer.py` only writes PLY during training when PLY export is requested. This image now includes a manual export command for existing checkpoints.

## Generate Exports

Use the default automatic command when there is only one clear checkpoint scene:

```bash
Generar
```

Use an explicit scene when multiple scenes exist:

```bash
Generar --scene truck
```

Use an explicit checkpoint when needed:

```bash
Generar --checkpoint /workspace/outputs/truck/ckpts/ckpt_30000.pt
```

By default, `Generar` writes both native formats supported by `gsplat.export_splats`:

```text
/workspace/outputs/<scene>/exports/<scene>.ply
/workspace/outputs/<scene>/exports/<scene>.compressed.ply
```

The standard `.ply` is binary little endian and validates that vertex count matches the checkpoint splat count. The compressed PLY can contain fewer vertices because the native exporter may filter very low-opacity splats.

## Logs

Export logs are written to:

```text
/workspace/logs/<scene>/generate-ply.log
```

The log records the checkpoint, detected step, checkpoint keys, tensor shapes, native export format, generated files, and validation results.

## Manual Download Prep

The pod does not push files to the Mac. Prepare exports for manual download:

```bash
PrepararDescarga truck
```

This creates a `.tar.gz`, writes a `.sha256`, and prints an `scp -O` template to run from the Mac.

Example:

```bash
scp -O -i ~/.ssh/id_ed25519 \
  <RUNPOD_USER>@ssh.runpod.io:/workspace/outputs/truck/exports/truck-ply-exports.tar.gz \
  ~/Downloads/
```

RunPod may require `scp -O` when using its SSH proxy.

## Not Included

- no upload automation
- no HTTP server
- no tunnel to the Mac
- no supervisor
- no fire-and-forget pipeline
- no Nerfstudio
- no COLMAP
- no viewer
- no desktop
