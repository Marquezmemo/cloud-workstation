#!/usr/bin/env bash
set -euo pipefail

# Purpose: Keep a RunPod Surveyor container alive for manual headless operation.
# Input:   No arguments.
# Output:  Operator command hints followed by a foreground keepalive process.

mkdir -p /workspace/incoming /workspace/scenes /workspace/logs /workspace/archives /workspace/temp

echo "===== cloud-workstation headless surveyor ====="
date -Is
echo
echo "Container is running in headless keepalive mode for RunPod."
echo
echo "Useful validation commands:"
echo "  validate-surveyor.sh"
echo "  runpodctl version"
echo "  survey-scene.sh <scene>"
echo "  validate-surveyor-scene.sh <scene>"
echo "  package-surveyor-scene.sh <scene>"
echo
echo "Workspace:"
echo "  /workspace/incoming"
echo "  /workspace/scenes"
echo "  /workspace/logs"
echo "  /workspace/archives"
echo "  /workspace/temp"
echo
echo "Keeping foreground process alive for SSH/manual validation."

sleep infinity
