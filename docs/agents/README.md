# Agent Ownership For Headless Training Pivot

Agents reduce active context. They do not hold global project coherence.

Project-level coherence is handled by the project coordinator with Codex support.

Active agents:

- Core Infrastructure
- Observability / The Eye
- Release Governance
- The Surveyor
- The Trainer

Paused agents:

- Desktop Integration / Deky
- Streaming & UX

## Current Rule

The project is pivoting to a headless Gaussian Splatting training image.

No active agent should repair or extend desktop, display-manager, VNC, NoMachine, streaming, or Blender GUI workflows.

## Ownership

Core Infrastructure owns:

- Dockerfile
- CUDA/PyTorch runtime
- system dependencies
- RTX 4090 compatibility

Observability / The Eye owns:

- GPU validation scripts
- training diagnostics
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

## Local Multi-Agent Operation

The v0.2 workflow now uses separate local checkouts/worktrees for role isolation:

- The Trainer works only on `headless-gsplat-v0.2-dev`.
- The Surveyor works on its own Surveyor branch and checkout.
- Each agent reviews, tests, commits, and publishes only its own branch.
- Agents can work in parallel without changing the physical branch of the other checkout.

This infrastructure is functional but manual. There is no automatic orchestration, cross-agent scheduler, or automatic merge flow yet.
