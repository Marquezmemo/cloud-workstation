# Agent Ownership For Headless Pipeline

Agents reduce active context. They do not hold global project coherence.

Project-level coherence is handled by the project coordinator with Codex support.

Active agents:

- Core Infrastructure
- Surveyor
- Observability / The Eye
- Release Governance

Paused agents:

- Desktop Integration / Deky
- Streaming & UX

## Current Rule

The project is split into headless image roles. This branch is the Surveyor COLMAP image line.

No active agent should repair or extend desktop, display-manager, VNC, NoMachine, streaming, or Blender GUI workflows.

## Local Multiagent Operation

The manual local multiagent workflow is functional as of 2026-07-07:

- The Surveyor v0.2 agent works from its own checkout/worktree on `headless-surveyor-v0.2-dev`.
- The Trainer v0.2 agent works from a separate checkout/worktree and a separate branch.
- Both agents can work in parallel without changing the other agent's physical branch.
- Coordination is still manual; automatic cross-agent orchestration is not implemented.
- Each agent must review, test, commit, and publish only its own branch.

## Ownership

Core Infrastructure owns:

- Dockerfile
- base runtime
- system dependencies
- image compatibility

Surveyor owns:

- COLMAP image/frame intake
- sparse reconstruction commands
- Surveyor scene packaging
- Surveyor-to-Trainer handoff artifacts

Observability / The Eye owns:

- validation scripts
- diagnostic clarity
- log collection
- minimum validation criteria

Release Governance owns:

- changelog
- pivot documentation
- legacy classification
- freeze integrity
- phase gates

## Paused / Legacy

Desktop Integration / Deky is paused.

It may read legacy desktop materials for audit purposes only. It must not modify the project unless explicitly reactivated.

Streaming & UX is paused until the headless training baseline is validated.
