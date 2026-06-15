#!/usr/bin/env bash
set -euo pipefail

mkdir -p /workspace/logs

echo "===== cloud-workstation headless gsplat ====="
date -Is
echo
echo "Container is running in headless keepalive mode for RunPod."
echo
echo "Useful validation commands:"
echo "  validate-gpu.sh"
echo "  collect-training-diagnostics.sh"
echo
echo "Workspace:"
echo "  /workspace/datasets"
echo "  /workspace/scenes"
echo "  /workspace/outputs"
echo "  /workspace/logs"
echo "  /workspace/checkpoints"
echo
echo "Keeping foreground process alive for SSH/manual validation."

sleep infinity
