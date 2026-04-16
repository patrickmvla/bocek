# ADR-0004: Machine Format as Compiled Artifact, Not Parallel Copy

## Status
Accepted

## Context
ADR-0001 established dual-format vault (human-readable + machine-readable). The original design document proposed bidirectional sync between the two formats — when the human updates a decision, the machine representation updates too, and vice versa. This creates a real engineering problem: keeping two representations in sync reliably.

Analysis of the actual consumption pattern revealed that the LLM during implementation doesn't need research prose, exploration notes, or reasoning behind decisions. It needs decisions that constrain implementation, contracts (API shapes, type signatures, state machines), and resolved cross-feature dependencies. This is a subset of the human vault, not a mirror of it.

## Decision
The machine format is a one-way compiled artifact generated from human vault files. Human files are the sole source of truth. Edits only happen to human files. The machine format is rebuilt, not updated. Compiled files live in `.bocek/vault/.compiled/`, one per feature scope, and are gitignored as build artifacts.

Structure:
```
.bocek/vault/
  .compiled/           ← gitignored, regenerated from human files
    checkout.md        ← dense compiled context for checkout implementation
    auth.md            ← same for auth
  index.md             ← human navigation entry point
  checkout/            ← human files (source of truth)
  auth/                ← human files (source of truth)
```

## Alternatives Considered
**Bidirectional sync between human and machine formats:** Original proposal. Rejected because it creates a hard sync problem, and analysis showed the machine format is a subset of the human vault (compiled view), not a parallel representation. One-way compilation eliminates the sync problem entirely.

**One compiled file for the whole vault:** Rejected because it would grow as large as the human vault and defeat the token-efficiency purpose. Per-feature scoping means the LLM loads only what's relevant to the current implementation task.

## Consequences
- **Positive**: No sync problem — one-way compilation is simple and reliable
- **Positive**: Human files are sole source of truth — no ambiguity about what to edit
- **Positive**: Compiled files are gitignored — no merge conflicts on build artifacts
- **Positive**: Per-feature scoping means the LLM loads minimal relevant context
- **Negative**: Compilation step required — needs a script or primitive that runs it
- **Negative**: Compiled format could drift if compilation isn't triggered after human edits — needs a convention or hook

## Revisit When
- If the compilation step proves too slow or unreliable
- If the per-feature boundary doesn't map cleanly to how users organize vault knowledge
- If compiled files need to be committed (e.g., for CI/CD pipelines that read vault state)
