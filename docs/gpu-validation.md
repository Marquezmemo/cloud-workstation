# GPU Validation

Validation source: Runpod pod running `Workstation_v0.1`.

## NVIDIA-SMI

- Command: `nvidia-smi`
- Timestamp: `Tue Jun 2 22:10:13 2026`
- NVIDIA-SMI version: `580.126.20`
- Driver version: `580.126.20`
- CUDA host runtime: `13.0`

## GPU

- GPU: `NVIDIA GeForce RTX 4090`
- VRAM: `24564 MiB`
- Bus ID: `00000000:81:00.0`
- Persistence mode: `On`
- Display active: `Off`
- Fan: `32%`
- Temperature: `30C`
- Performance state: `P8`
- Power usage: `13W / 450W`
- GPU utilization: `0%`
- Memory usage: `1 MiB / 24564 MiB`
- Compute mode: `Default`
- MIG mode: `N/A`
- Processes: `No running processes found`

## CUDA Toolkit

- Command: `nvcc --version`
- CUDA compilation tools release: `12.4`
- CUDA toolkit version: `12.4.131`
- Build: `cuda_12.4.r12.4/compiler.34097967_0`

## Runtime Validation

- RTX 4090 validated
- NVIDIA driver validated
- CUDA host runtime validated
- CUDA toolkit validated
- NVENC previously validated
- SSH validated
- Runpod deployment validated
- Networking validated

## Current Non-Desktop State

- X11 absent
- Desktop session absent
- Desktop layer not implemented
- Streaming layer not implemented
- OpenGL pending validation

## Evidence

- Text transcript: `docs/nvidia-smi.txt`
- Screenshot: `docs/evidence/nvidia-smi-2026-06-02.png`
