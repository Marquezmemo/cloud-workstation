# Workstation_v0.1 Freeze Policy

`Workstation_v0.1` is an immutable restoration point for the project.

## Rules

- Do not modify the `Workstation_v0.1` baseline.
- Do not move historical tags.
- Do not replace published artifacts.
- Do not update existing dependencies in place.
- Do not execute `apt upgrade`.
- Do not execute `apt dist-upgrade`.
- Do not use mutable tags such as `latest`.
- Every functional change requires a new version.
- Every new baseline requires new fingerprinting.
- Future development must happen in new branches, new versions, and new tags.

## Required Baseline Artifacts

Before any version is treated as a frozen baseline, it must include:

- Exact image digest
- `baseline.md`
- `pip-freeze.txt`
- `dpkg-freeze.txt`
- GPU validation record
- Changelog entry

## Next Version

The next official development version is `Workstation_v0.2-dev`.

Its first goal is to validate a real Ubuntu desktop layer with observable logs:

- Ubuntu desktop minimal
- GDM startup behavior
- Wayland or Xorg session behavior
- OpenGL when a display is available
- Functional graphical session

Do not install Blender, Houdini, or complex DCC tooling in the first desktop validation pass.
