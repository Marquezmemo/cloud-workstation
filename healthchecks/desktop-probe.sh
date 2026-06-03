#!/usr/bin/env bash
set -uo pipefail

if pgrep -x supervisord >/dev/null 2>&1; then
  exit 0
fi

if pgrep -x gdm3 >/dev/null 2>&1 || pgrep -x gdm >/dev/null 2>&1; then
  exit 0
fi

exit 1
