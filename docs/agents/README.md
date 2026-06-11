# Agent Ownership

This directory documents lightweight ownership boundaries for the cloud workstation project.

The goal is context efficiency, not agent count or orchestration sophistication.

Agents operate with limited context by design. They do not need to understand the whole repository. Project-level coherence is held by the coordinator with Codex support.

## Documents

- `ownership-summary.md`: agent scopes, victory definitions, delegated ownership, and temporary `v0.2-dev` flexibility.
- `handoffs.md`: short evidence-based handoff rules.
- `protected-paths.md`: protected paths, historical artifacts, and hygiene rules.

## Operating Principle

If a boundary helps reduce context and protect reproducibility, keep it.

If a boundary repeatedly slows down real workstation progress, review it.
