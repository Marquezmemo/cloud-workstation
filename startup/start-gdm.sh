#!/usr/bin/env bash
set -uo pipefail

LOG_DIR="${WORKSTATION_LOG_DIR:-/var/log/workstation}"
GDM_LOG="${LOG_DIR}/gdm.log"

mkdir -p "${LOG_DIR}" /run/dbus
touch "${GDM_LOG}"

log() {
  printf '[%s] %s\n' "$(date -Is)" "$*" | tee -a "${GDM_LOG}"
}

log "Starting GDM without Wayland/Xorg overrides"

{
  echo "===== gdm binaries ====="
  command -v gdm3 || true
  command -v gdm || true
  echo
  echo "===== gdm config snippets ====="
  find /etc/gdm3 /usr/share/gdm -maxdepth 2 -type f 2>/dev/null | sort || true
  echo
  echo "===== display manager state before start ====="
  ps auxww | grep -E '[g]dm|[X]org|[d]bus' || true
} >> "${GDM_LOG}" 2>&1

if command -v gdm3 >/dev/null 2>&1; then
  exec /usr/sbin/gdm3 --nodaemon
fi

if command -v gdm >/dev/null 2>&1; then
  exec /usr/sbin/gdm --nodaemon
fi

log "No gdm binary found"
exit 127
