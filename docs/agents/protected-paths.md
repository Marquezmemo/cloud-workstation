# Protected Paths

## Purpose

Protected paths prevent ownership ambiguity and accidental cross-domain edits.

They do not exist to create friction. They exist to preserve context isolation, traceability, cleaner diffs, safer iteration, and baseline integrity.

## Rule

A protected path is a path another agent may read, but may not modify directly without handoff, delegated scope, explicit coordination, or coordinator override.

Boundaries are guardrails, not walls. During `workstation-v0.2-dev` bring-up, temporary flexibility is allowed when it helps diagnose real failures faster.

## Core Infrastructure

Owned paths:

- `Dockerfile`
- base runtime setup files
- system-level runtime foundation files

Protected from direct modification by other agents:

- `Dockerfile`
- base image selection metadata
- system package foundations

Temporary exception:

- On dev branches, Desktop Integration may request small package changes with brief evidence.
- Core Infrastructure retains final ownership of `Dockerfile`.
- Review this exception once desktop bring-up stabilizes.

## Desktop Integration

Owned paths:

- `startup/`
- desktop/session scripts
- desktop-specific configuration
- current desktop integration notes

Protected from direct modification by other agents:

- desktop session startup files
- graphical session configuration
- GDM/X11/Wayland bring-up logic

Delegated edit:

- Observability & Diagnostics may edit `startup/supervisord.conf` only for probe/log process entries.

## Observability & Diagnostics

Owned paths:

- `scripts/`
- `healthchecks/`
- diagnostics collection utilities
- probes
- current error logs and validation notes

Protected from direct modification by other agents:

- diagnostic scripts
- healthcheck definitions
- structured validation outputs

Delegated edits:

- Desktop Integration may edit `startup/desktop-probe-loop.sh` only for display/session probe inputs.
- Desktop Integration may append observed desktop bring-up failures to `docs/error-log.md`.

## Release & Freeze

Owned paths:

- `docs/freeze-policy.md`
- `docs/image-digest.md`
- `docs/baseline.md`
- `docs/pip-freeze.txt`
- `docs/dpkg-freeze.txt`
- `docs/nvidia-smi.txt`
- `docs/evidence/`
- release traceability records
- `CHANGELOG.md`

Protected from direct modification by other agents:

- freeze policy documents
- digest records
- baseline state records
- package snapshots
- evidence snapshots
- rollback/version traceability files

Delegated edit:

- All agents may append dev-branch notes to `CHANGELOG.md`.
- No agent may rewrite historical changelog entries without Release & Freeze coordination.

## Streaming & UX

Owned paths:

- streaming strategy documents
- remote access configuration
- UX validation records
- protocol evaluation notes

Protected from direct modification by other agents:

- streaming decision docs
- remote access workflow docs
- UX acceptance records

## Historical Artifacts

These are read-only for all agents except Release & Freeze:

- `docs/baseline.md`
- `docs/image-digest.md`
- `docs/freeze-policy.md`
- `docs/pip-freeze.txt`
- `docs/dpkg-freeze.txt`
- `docs/nvidia-smi.txt`
- `docs/evidence/`

Corrections are allowed only as explicit correction notes. Do not silently rewrite historical evidence.

## Shared Reality, Not Shared Ownership

Some files influence more than one agent. That does not automatically make them shared ownership files.

Examples:

- `Dockerfile` affects Desktop Integration, but remains Core Infrastructure owned.
- `startup/` affects Observability, but remains Desktop Integration owned except for the delegated probe/log scopes.
- freeze documents affect everyone, but remain Release & Freeze owned.

Impact does not equal ownership.

## Repo Hygiene

No agent should introduce:

- OS/editor artifacts
- accidental empty files
- unowned root files
- noisy generated outputs

If such files appear, treat cleanup as housekeeping and keep it separate from functional changes when possible.

## Boundary Review

If repeated handoffs show that a protected path is constantly edited by another agent for valid reasons, review the boundary.

That may justify:

- a narrower protected area
- a delegated sub-area
- a temporary bring-up exception
- eventual agent fusion

Fusion should be considered only if it improves context efficiency.
