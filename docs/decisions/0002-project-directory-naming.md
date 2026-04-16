# ADR-0002: Project Directory Named .bocek/

## Status
Accepted

## Context
Bocek needs a per-project directory in the user's codebase root to store the vault, mode file, and state. This directory gets committed to the project's repo. The name must be unambiguous, avoid collisions with existing conventions, and clearly signal ownership.

## Decision
We will use `.bocek/` as the per-project directory name. All project-local Bocek state lives under this directory: vault at `.bocek/vault/`, mode file at `.bocek/mode`, state at `.bocek/state.md`.

## Alternatives Considered
**`.design/`** — Descriptive but generic. Another tool or convention could claim this name. No clear ownership signal.

**`.design/vault/`** — Original proposal from design document. Nests vault under a generic parent, mixing Bocek concerns with a name that could mean anything.

**`docs/design/`** — Visible and conventional but could collide with existing `docs/` directories in projects.

## Consequences
- **Positive**: Unambiguous namespace — no other tool will claim `.bocek/`
- **Positive**: Single directory owns all Bocek state per project — clean boundary
- **Positive**: Dot-prefix hides from casual `ls`, consistent with `.git/`, `.github/`, `.vscode/`
- **Negative**: Branded name in someone else's repo — but this is standard practice (`.github/`, `.vscode/`, `.husky/`)

## Revisit When
- If Bocek becomes a standard that should use a generic name (unlikely near-term)
