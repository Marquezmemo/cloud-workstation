# Agent Ownership Summary

Agents exist to reduce active context and token consumption.

They are not a multi-agent platform, orchestration layer, or substitute for project-level coherence. The project coordinator keeps global coherence with Codex support. Each agent should focus on its owned area and reject work that does not improve the workstation goal.

## Success Metric

Agent count is not a success metric.

Context efficiency is the success metric.

Project priority order remains:

1. Stability
2. Visual fidelity
3. Latency

## Core Infrastructure

Can modify:

- `Dockerfile`
- base runtime setup
- system-level package foundations
- NVIDIA/CUDA/runtime compatibility notes within its scope

Can read:

- freeze docs
- startup scripts
- diagnostics docs
- current validation records

Protected from this agent:

- historical freeze artifacts except by handoff to Release & Freeze
- desktop session scripts except by handoff to Desktop Integration
- observability utilities except by handoff to Observability & Diagnostics

Victory means the image foundation stays reproducible, stable, Blender-compatible, and easy to debug.

## Desktop Integration

Can modify:

- `startup/`
- desktop/session bring-up files
- desktop-specific configuration
- docs for current desktop integration attempts

Can read:

- `Dockerfile`
- diagnostics docs
- current snapshot docs
- runtime constraints

Protected from this agent:

- baseline image policy
- release/freeze files
- historical snapshots
- release workflows except by handoff

Victory means the graphical session becomes stable enough to support Blender workflow validation.

## Observability & Diagnostics

Can modify:

- `scripts/`
- `healthchecks/`
- diagnostics collection
- probes
- current error and validation notes

Can read:

- startup files
- desktop bring-up config
- release state docs
- runtime constraints

Protected from this agent:

- `Dockerfile`
- baseline runtime decisions
- release identity
- historical freeze artifacts

Victory means failures affecting the workstation can be diagnosed quickly with minimal context reload.

## Release & Freeze

Can modify:

- freeze policy docs
- digest records
- baseline/version records
- snapshot references
- release traceability docs
- `CHANGELOG.md`

Can read:

- all implementation areas as needed for release traceability

Protected from this agent:

- functional runtime changes
- desktop stack implementation
- streaming stack implementation

Victory means every frozen version is reproducible, traceable, and safe to roll back to.

## Streaming & UX

Can modify:

- streaming strategy docs
- remote access configuration
- UX validation notes
- protocol evaluation notes

Can read:

- desktop integration files
- observability outputs
- runtime constraints
- release state docs

Protected from this agent:

- baseline freeze records
- non-streaming runtime ownership
- desktop session internals except by handoff

Victory means the remote workstation feels close to local for Blender: responsive, stable, visually clear, and low-latency.

## Delegated Ownership

Delegated ownership stays short and concrete:

- Primary owner protects intent.
- Delegated editor may make only the exact scoped change.
- Repeated friction should trigger boundary review, not a larger permission model.

Initial delegations:

| Path | Primary owner | Delegated editor | Exact delegation scope |
| --- | --- | --- | --- |
| `startup/supervisord.conf` | Desktop Integration | Observability & Diagnostics | Probe/log process entries only |
| `startup/desktop-probe-loop.sh` | Observability & Diagnostics | Desktop Integration | Display/session probe inputs only |
| `docs/error-log.md` | Observability & Diagnostics | Desktop Integration | Append observed desktop bring-up failures |
| `CHANGELOG.md` | Release & Freeze | All agents | Append dev-branch notes only; no historical rewrite |

## Temporary v0.2-dev Flexibility

During desktop bring-up, cross-boundary edits may need to move faster than usual.

- On dev branches, Desktop Integration may request small package changes with brief evidence.
- Core Infrastructure keeps final ownership of `Dockerfile`.
- This exception must be reviewed once bring-up becomes less volatile.

This flexibility is temporary and exists to reduce operational friction, not to weaken freeze discipline.
