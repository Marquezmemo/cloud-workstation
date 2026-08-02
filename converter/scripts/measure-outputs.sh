#!/usr/bin/env bash
set -euo pipefail

TARGET_DIR="${1:-converter/output}"
REPORT_DIR="converter/reports"
mkdir -p "${REPORT_DIR}"

python3 - <<PY
import csv
import hashlib
from pathlib import Path

def sha256(path):
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()

root = Path(".").resolve()
target = Path("${TARGET_DIR}")
rows = []
for path in sorted(target.rglob("*")):
    if path.is_file():
        digest = sha256(path)
        rel = path.resolve().relative_to(root)
        rows.append({
            "target": path.suffix.lstrip(".") or path.name,
            "status": "success",
            "path": str(rel),
            "bytes": path.stat().st_size,
            "size": f"{path.stat().st_size} B",
            "sha256": digest,
            "tool": "measure-outputs",
            "reason": "",
        })

with Path("${REPORT_DIR}/file-sizes.csv").open("w", encoding="utf-8", newline="") as handle:
    writer = csv.DictWriter(handle, fieldnames=["target", "status", "path", "bytes", "size", "sha256", "tool", "reason"])
    writer.writeheader()
    writer.writerows(rows)

Path("${REPORT_DIR}/checksums.sha256").write_text(
    "".join(f"{row['sha256']}  {row['path']}\\n" for row in rows),
    encoding="utf-8",
)
print(f"Measured {len(rows)} files under {target}")
PY
