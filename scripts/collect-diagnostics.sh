#!/usr/bin/env bash
set -uo pipefail

LOG_DIR="${WORKSTATION_LOG_DIR:-/var/log/workstation}"
OUTPUT_DIR="${1:-/tmp/workstation-diagnostics}"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
RUN_DIR="${OUTPUT_DIR}/workstation-${STAMP}"

mkdir -p "${RUN_DIR}"

copy_if_exists() {
  local src="$1"
  local dst="$2"

  if [ -e "${src}" ]; then
    mkdir -p "$(dirname "${dst}")"
    cp -a "${src}" "${dst}"
  fi
}

copy_if_exists "${LOG_DIR}" "${RUN_DIR}/var-log-workstation"
copy_if_exists "/var/log/gdm3" "${RUN_DIR}/var-log-gdm3"
copy_if_exists "/var/log/Xorg.0.log" "${RUN_DIR}/var-log-Xorg.0.log"
copy_if_exists "/var/log/Xorg.1.log" "${RUN_DIR}/var-log-Xorg.1.log"
copy_if_exists "/etc/gdm3" "${RUN_DIR}/etc-gdm3"
copy_if_exists "/etc/supervisor" "${RUN_DIR}/etc-supervisor"

{
  echo "===== collected_at ====="
  date -Is
  echo
  echo "===== version ====="
  echo "${WORKSTATION_VERSION:-unknown}"
  echo
  echo "===== os-release ====="
  cat /etc/os-release 2>/dev/null || true
  echo
  echo "===== uname ====="
  uname -a
  echo
  echo "===== env ====="
  env | sort
  echo
  echo "===== processes ====="
  ps auxww
  echo
  echo "===== supervisor ====="
  supervisorctl -c /etc/supervisor/conf.d/workstation.conf status 2>&1 || true
  echo
  echo "===== nvidia-smi ====="
  nvidia-smi 2>&1 || true
  echo
  echo "===== glxinfo ====="
  glxinfo -B 2>&1 || true
  echo
  echo "===== display sockets ====="
  find /tmp /run -maxdepth 3 \( -name '.X11-unix' -o -name 'wayland-*' -o -name 'bus' \) -print 2>/dev/null || true
} > "${RUN_DIR}/system-report.txt" 2>&1

tar -C "${OUTPUT_DIR}" -czf "${RUN_DIR}.tar.gz" "$(basename "${RUN_DIR}")"

printf '%s\n' "${RUN_DIR}.tar.gz"
