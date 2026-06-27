# PLY Export

`headless-gsplat-v0.1-dev` implements headless `gsplat` training and checkpoint output. A 30,000-iteration RunPod execution was reported historically, but its logs and artifacts were not preserved; it does not validate the current image.

The missing `.ply` was not a pipeline failure. The official `simple_trainer.py` only writes PLY during training when PLY export is requested. This image now includes a manual export command for existing checkpoints.

## Generate Exports

Complete command syntax is maintained in [command-reference.md](command-reference.md).

Use the lowercase command. The uppercase `Generar` alias exists, but `generar` is the documented operator command.

Use the default automatic command when there is only one clear checkpoint scene:

```bash
generar
```

Use an explicit scene when multiple scenes exist:

```bash
generar --scene truck
```

Use an explicit checkpoint when needed:

```bash
generar --checkpoint /workspace/outputs/truck/ckpts/ckpt_100.pt
```

Use an explicit checkpoint directory when needed:

```bash
generar --ckpt-dir /workspace/outputs/truck/ckpts
```

Choose export format:

```bash
generar --scene room --format both
generar --scene room --format ply
generar --scene room --format ply_compressed
```

Choose export device:

```bash
generar --scene room --device cpu
generar --scene room --device cuda
generar --scene room --device cuda --fallback-cpu
```

By default, `generar` writes both native formats supported by `gsplat.export_splats`:

```text
/workspace/outputs/<scene>/exports/<scene>.ply
/workspace/outputs/<scene>/exports/<scene>.compressed.ply
```

The standard `.ply` is binary little endian and validates that vertex count matches the checkpoint splat count. The compressed PLY can contain fewer vertices because the native exporter may filter very low-opacity splats.

The current default export device is CPU.

Do not use these forms:

```bash
generar --room
generar /room
generar --/workspace/checkpoints/room
```

They are not declared arguments. The positional form `generar room` is only a possible future ergonomic improvement and is not needed for current pipeline validation.

## Logs

Export logs are written to:

```text
/workspace/logs/<scene>/generate-ply.log
```

The log records the checkpoint, detected step, checkpoint keys, tensor shapes, native export format, generated files, and validation results.

## Manual Transfer Prep

The pod does not push files to the Mac. Package exports for manual transfer:

```bash
empaquetar truck
```

This creates a `.tar.gz`, writes a `.sha256`, and prints the final paths.

The current checksum record contains the absolute pod path. Verify it in place on the pod; after transfer, calculate the received file hash and compare the digest manually.

Alias:

```bash
comprimir truck
```

The selected transfer method is `runpodctl`. The image installs `runpodctl v2.5.0` from the official GitHub release and verifies the Linux amd64 binary checksum during build. SCP through `ssh.runpod.io` is discarded for this workflow.

Pod-to-Mac pattern:

```bash
runpodctl send /workspace/outputs/bonsai/exports/bonsai-ply-exports.tar.gz
runpodctl send /workspace/outputs/bonsai/exports/bonsai-ply-exports.tar.gz.sha256
runpodctl receive <transfer-code>
```

The exact Mac-to-pod syntax, large-file behavior, interruption behavior, and checksum verification flow remain pending smoke test.

Package scene-scoped logs separately with:

```bash
empaquetar-logs truck
```

That command creates a portable checksum and packages existing logs only. It does not generate GPU telemetry.

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
