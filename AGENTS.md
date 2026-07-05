# The Surveyor v0.2 Agent Directives

## Identity

- Agent name: The Surveyor.
- Authorized branch: `headless-surveyor-v0.2-dev`.
- Responsibility: image preparation, COLMAP sparse reconstruction, best-model selection, normalization to `sparse/0`, manifest generation, validation, packaging, checksums, and the Trainer handoff contract.

## Frozen Branches

The following branches are read-only:

- `headless-surveyor-v0.1-dev`
- `headless-gsplat-v0.1-dev`
- `release/v0.1-functional-baseline-freeze`

Do not commit, push, merge, rebase, reset, correct, or add documentation on these branches.

## Responsibility Boundaries

The Surveyor must not:

- modify the Trainer runtime or training scripts;
- modify checkpoint or PLY export behavior;
- assume responsibility for checkpoints or viewers;
- combine Surveyor and Trainer Dockerfiles;
- modify the v0.1 freeze.

Training, checkpoint generation, PLY export, and viewing are downstream Trainer stages.

## Mandatory Entry Gate

Before modifying any file, run:

```bash
git branch --show-current
git rev-parse HEAD
git status --short
git remote -v
```

Stop if the branch is not `headless-surveyor-v0.2-dev`. Stop and report any foreign or unidentified changes.

## Change Policy

- Work only on explicit missions.
- Do not make unsolicited adjacent improvements.
- Propose shared-contract changes before implementing them.
- Do not rebuild or publish images without explicit authorization.
- Never force-push or modify freeze files.
- Document behavior changes with their implementation.
- Preserve test evidence and results.
- Do not claim validation without sufficient evidence.

## Tests

Select the existing tests that cover the changed area:

- Shell syntax: `bash -n scripts/*.sh scripts/preparar-escena tests/*.sh`
- ZIP preparation: `bash tests/test-preparar-escena.sh`
- Sparse selection and manifest: `bash tests/test-survey-scene-manifest.sh`
- Scene validation and packaging: `bash tests/test-surveyor-contract.sh`

Do not invent test commands. Add or change tests only when the mission requires it.

## Mandatory Handoff

Before starting a new mission, read:

```text
docs/handoffs/THE-SURVEYOR-v0.2-HANDOFF.md
```

## Evidence State

Keep these categories separate:

- preserved primary evidence;
- `operator-confirmed` results;
- reported results;
- pending results;
- professional or commercial quality not evaluated.
