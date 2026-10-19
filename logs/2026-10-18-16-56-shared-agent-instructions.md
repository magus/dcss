# Shared agent instructions

## Context

Adopt the shared agents.md repository for logs and scratch rules.

## Decisions

- Follow the shared format exactly. Earlier integration retained obsolete commit metadata;
  remove it and the local requirements that caused the conflict.
- Pin the shared repository at `.agents/` and retain project-specific instructions.
- Preserve existing scratch files, nested instructions, and unrelated work.

## Changes

- Add the submodule, its required read and initialization fallback, and scratch ignore rules.
- Replace duplicate guidance with shared references while keeping local requirements.

## Verification

- Submodule initialized at `0b6abdb`; its shared instructions are present.
- `git diff --check` and `git diff --cached --check` passed.
- Ignore checks confirm `.scratch/` is ignored and delivery logs are not.
- Application tests were not run for this documentation-only change.
- Shared instruction links and initialization fallbacks passed path checks.
- Verified the checkout and staged submodule pointer both match GitHub commit `0b6abdb`.
- Final diff checks and shared log-format checks passed.
