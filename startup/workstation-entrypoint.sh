#!/usr/bin/env bash
set -uo pipefail

LOG_DIR="${WORKSTATION_LOG_DIR:-/var/log/workstation}"
STARTUP_LOG="${LOG_DIR}/startup.log"

mkdir -p "${LOG_DIR}" /var/run/sshd /run/dbus
rm -f /run/dbus/pid
touch "${STARTUP_LOG}"

log() {
  printf '[%s] %s\n' "$(date -Is)" "$*" | tee -a "${STARTUP_LOG}"
}

log "Starting ${WORKSTATION_VERSION:-Workstation_v0.2-dev}"
log "Preparing observable desktop integration environment"

{
  echo "===== identity ====="
  id
  echo
  echo "===== kernel ====="
  uname -a
  echo
  echo "===== os-release ====="
  cat /etc/os-release 2>/dev/null || true
  echo
  echo "===== environment ====="
  env | sort
  echo
  echo "===== display variables ====="
  printf 'DISPLAY=%s\n' "${DISPLAY:-}"
  printf 'WAYLAND_DISPLAY=%s\n' "${WAYLAND_DISPLAY:-}"
  printf 'XDG_SESSION_TYPE=%s\n' "${XDG_SESSION_TYPE:-}"
  printf 'XDG_RUNTIME_DIR=%s\n' "${XDG_RUNTIME_DIR:-}"
  echo
  echo "===== commands ====="
  command -v supervisord || true
  command -v dbus-daemon || true
  command -v gdm3 || true
  command -v gdm || true
  command -v Xorg || true
  command -v glxinfo || true
  command -v nvidia-smi || true
} >> "${STARTUP_LOG}" 2>&1

if command -v nvidia-smi >/dev/null 2>&1; then
  nvidia-smi >> "${LOG_DIR}/gpu.log" 2>&1 || true
else
  log "nvidia-smi not found"
fi

if command -v ssh-keygen >/dev/null 2>&1; then
  log "Ensuring SSH host keys exist"
  ssh-keygen -A >> "${STARTUP_LOG}" 2>&1 || true
fi

log "Launching supervisord"
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/workstation.conf
