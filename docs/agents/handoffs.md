# Handoffs

## Purpose

A handoff is used when a proposed change crosses ownership boundaries.

The goal is not bureaucracy. The goal is to preserve context efficiency, ownership clarity, reproducibility, diagnosability, and baseline safety.

Handoffs should stay short, operational, and evidence-based.

## When A Handoff Is Required

A handoff is required when:

- a change touches a protected path
- a change alters another agent's owned files outside delegated scope
- a change affects a frozen baseline
- a change alters startup integrity or reproducibility
- another agent's validation is needed to avoid blind edits

A handoff is not required for read-only consultation.

## Lightweight Handoff Format

```md
## Handoff

**From:** <requesting agent>
**To:** <target agent>

**Requested change**
<short description>

**Reason**
<why this is needed for workstation progress>

**Files affected**
- `<path>`

**Evidence**
- <log, observation, validation result, or failure mode>

**Risks**
- <possible regression or baseline concern>

**Validation expected**
- <how success should be checked>
```

## Temporary v0.2-dev Package Requests

During desktop bring-up:

- Desktop Integration may request small package changes with brief evidence.
- Core Infrastructure retains final ownership of `Dockerfile`.
- The request should name the package, why it is needed, and what log or failure motivated it.
- This exception should be reviewed once bring-up becomes less volatile.

Example:

```md
## Handoff

**From:** Desktop Integration
**To:** Core Infrastructure

**Requested change**
Add `<package>` to the `v0.2-dev` image.

**Reason**
Required to validate `<desktop/display behavior>`.

**Files affected**
- `Dockerfile`

**Evidence**
- `<log path>` shows `<failure>`

**Risks**
- May increase desktop layer surface area.

**Validation expected**
- Build succeeds and `<probe>` produces useful output.
```

## Coordinator Override

The project coordinator may override ownership boundaries when project coherence, debugging speed, or baseline safety requires it.

Overrides should be brief and explicit in the commit message, handoff note, or review summary.

This rule exists because agents do not hold total system coherence. They operate on limited context by design.

## Anti-Bloat Rule

Handoffs must not become a substitute for real work.

If a handoff can be resolved with a short evidence-based approval, do that. Do not turn it into a long design discussion unless the change materially affects:

- baseline integrity
- reproducibility
- workstation stability
- diagnostic clarity
