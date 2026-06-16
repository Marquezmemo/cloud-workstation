#!/usr/bin/env bash
set -euo pipefail

trainer_path="${1:-/opt/gsplat/examples/simple_trainer.py}"

if [[ ! -f "${trainer_path}" ]]; then
  echo "ERROR: trainer file not found: ${trainer_path}" >&2
  exit 1
fi

tmp_file="$(mktemp)"

awk '
  /^import viser$/ {
    print "# Headless patch: viewer imports are disabled in this image."
    print "viser = None"
    next
  }
  /^from gsplat_viewer import GsplatViewer, GsplatRenderTabState$/ {
    print "class GsplatViewer:"
    print "    def __init__(self, *args, **kwargs):"
    print "        raise RuntimeError(\"Viewer is disabled in this headless image. Use --disable_viewer.\")"
    print ""
    print "class GsplatRenderTabState:"
    print "    pass"
    next
  }
  /^from nerfview import CameraState, RenderTabState, apply_float_colormap$/ {
    print "CameraState = object"
    print "RenderTabState = object"
    print "def apply_float_colormap(*args, **kwargs):"
    print "    raise RuntimeError(\"Viewer rendering is disabled in this headless image.\")"
    next
  }
  { print }
' "${trainer_path}" > "${tmp_file}"

mv "${tmp_file}" "${trainer_path}"

if grep -qE "^(import viser|from gsplat_viewer import|from nerfview import)" "${trainer_path}"; then
  echo "ERROR: viewer imports remain after headless patch: ${trainer_path}" >&2
  exit 1
fi

echo "Applied headless viewer patch to ${trainer_path}"
