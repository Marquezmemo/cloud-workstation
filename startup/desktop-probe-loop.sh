#!/usr/bin/env bash
set -uo pipefail

LOG_DIR="${WORKSTATION_LOG_DIR:-/var/log/workstation}"
PROBE_LOG="${LOG_DIR}/desktop-probe.log"
GPU_LOG="${LOG_DIR}/gpu.log"
XORG_LOG="${LOG_DIR}/xorg.log"

mkdir -p "${LOG_DIR}"
touch "${PROBE_LOG}" "${GPU_LOG}" "${XORG_LOG}"

while true; do
  {
    echo "===== probe $(date -Is) ====="
    echo "DISPLAY=${DISPLAY:-}"
    echo "WAYLAND_DISPLAY=${WAYLAND_DISPLAY:-}"
    echo "XDG_SESSION_TYPE=${XDG_SESSION_TYPE:-}"
    echo "XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-}"
    echo
    echo "----- processes -----"
    ps auxww | grep -E '[g]dm|[X]org|[w]ayland|[g]nome|[d]bus|[s]upervisord|[s]shd' || true
    echo
    echo "----- sockets -----"
    find /tmp /run -maxdepth 3 \( -name '.X11-unix' -o -name 'wayland-*' -o -name 'bus' \) -print 2>/dev/null || true
    echo
    echo "----- glxinfo -----"
    if command -v glxinfo >/dev/null 2>&1; then
      glxinfo -B 2>&1 || true
    else
      echo "glxinfo not found"
    fi
    echo
  } >> "${PROBE_LOG}" 2>&1

  if command -v nvidia-smi >/dev/null 2>&1; then
    {
      echo "===== nvidia-smi $(date -Is) ====="
      nvidia-smi
      echo
    } >> "${GPU_LOG}" 2>&1 || true
  fi

  {
    echo "===== xorg logs $(date -Is) ====="
    find /var/log -maxdepth 1 -type f -name 'Xorg*.log' -print -exec tail -200 {} \; 2>/dev/null || true
    echo
  } >> "${XORG_LOG}" 2>&1

  sleep "${WORKSTATION_PROBE_INTERVAL_SECONDS:-30}"
done
