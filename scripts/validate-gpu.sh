#!/usr/bin/env bash
set -euo pipefail

echo "===== validate-gpu ====="
date -Is
echo

echo "===== nvidia-smi ====="
if ! command -v nvidia-smi >/dev/null 2>&1; then
  echo "ERROR: nvidia-smi not found" >&2
  exit 1
fi
nvidia-smi
echo

echo "===== python / torch / cuda ====="
python - <<'PY'
import sys

print(f"python={sys.version.split()[0]}")

try:
    import torch
except Exception as exc:
    print(f"ERROR: failed to import torch: {exc}", file=sys.stderr)
    raise SystemExit(1)

print(f"torch={torch.__version__}")
print(f"torch_cuda={torch.version.cuda}")

cuda_available = torch.cuda.is_available()
print(f"cuda_available={cuda_available}")

if not cuda_available:
    raise SystemExit("ERROR: torch.cuda.is_available() returned False")

device_index = torch.cuda.current_device()
device_name = torch.cuda.get_device_name(device_index)
print(f"cuda_device_index={device_index}")
print(f"cuda_device_name={device_name}")

x = torch.ones((1024, 1024), device="cuda")
y = torch.matmul(x, x)
torch.cuda.synchronize()

print(f"cuda_test_sum={float(y.sum().item())}")
print("cuda_operation=success")
PY
