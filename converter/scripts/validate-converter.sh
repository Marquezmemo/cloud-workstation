#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "${REPO_ROOT}"

python3 -m py_compile converter/tools/converter_runner.py

for path in \
  converter/Dockerfile \
  converter/README.md \
  converter/config/converter-formats.json \
  converter/config/converter-presets.json \
  converter/scripts/convert-scene.sh \
  converter/scripts/fetch-ply-runpodctl.sh \
  converter/scripts/measure-outputs.sh \
  converter/scripts/package-results.sh \
  docs/converter-contract.md \
  docs/converter-checklist.md \
  docs/converter-runpod-usage.md \
  docs/converter-output-format.md
do
  test -e "${path}" || { echo "Missing ${path}" >&2; exit 1; }
done

python3 - <<'PY'
import json
from pathlib import Path

for path in ["converter/config/converter-formats.json", "converter/config/converter-presets.json"]:
    json.loads(Path(path).read_text(encoding="utf-8"))
print("Converter validation passed.")
PY
