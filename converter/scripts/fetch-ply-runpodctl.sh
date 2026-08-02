#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  fetch-ply-runpodctl.sh --source <runpod-reference> [--output converter/input/scene.ply]

Copies a remote Trainer .ply artifact into converter/input/ using runpodctl.
USAGE
}

SOURCE=""
OUTPUT="converter/input/scene.ply"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source) SOURCE="${2:-}"; shift 2 ;;
    --output) OUTPUT="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

if [[ -z "${SOURCE}" ]]; then
  echo "--source is required" >&2
  exit 2
fi

if ! command -v runpodctl >/dev/null 2>&1; then
  echo "runpodctl is not installed or not on PATH." >&2
  exit 127
fi

mkdir -p "$(dirname "${OUTPUT}")" converter/reports
runpodctl receive "${SOURCE}" -o "${OUTPUT}"

python3 - <<PY
import hashlib
import json
from pathlib import Path

path = Path("${OUTPUT}")
digest = hashlib.sha256()
with path.open("rb") as handle:
    for chunk in iter(lambda: handle.read(1024 * 1024), b""):
        digest.update(chunk)
report = {
    "source": "${SOURCE}",
    "destination": str(path),
    "bytes": path.stat().st_size,
    "sha256": digest.hexdigest(),
    "command": "runpodctl receive <source> -o <destination>",
}
Path("converter/reports/runpod-fetch-report.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
print(json.dumps(report, indent=2))
PY
