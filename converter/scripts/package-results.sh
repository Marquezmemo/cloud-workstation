#!/usr/bin/env bash
set -euo pipefail

SCENE_NAME="${1:-converter-results}"
PACKAGE_DIR="converter/packages"
mkdir -p "${PACKAGE_DIR}"

PACKAGE_PATH="${PACKAGE_DIR}/${SCENE_NAME}-converter-results.tar.gz"
tar -czf "${PACKAGE_PATH}" converter/output converter/reports
python3 - <<PY
import hashlib
from pathlib import Path

path = Path("${PACKAGE_PATH}")
digest = hashlib.sha256()
with path.open("rb") as handle:
    for chunk in iter(lambda: handle.read(1024 * 1024), b""):
        digest.update(chunk)
Path("${PACKAGE_PATH}.sha256").write_text(f"{digest.hexdigest()}  {path}\\n", encoding="utf-8")
PY
echo "${PACKAGE_PATH}"
