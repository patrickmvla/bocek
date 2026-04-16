# ADR-0013: Fluid Cross-Feature Design with Vault as Constraint System

## Status
Accepted

## Context
During design sessions, the human's attention naturally moves across features when dependencies surface. The question is whether the primitive should enforce single-feature focus or allow fluid movement.

A deeper issue: when the model jumps to a related feature, it needs a source of truth for that feature's existing decisions. Without one, it defaults to training data — generating architecture from statistical patterns rather than grounded constraints.

## Decision
Design sessions flow freely across features. The model does not enforce single-feature focus. When a cross-feature dependency surfaces, the model reads existing vault entries for that feature before making any claims. The vault's frontmatter tags each decision to its feature(s), and index.md tracks everything.

The vault is not just a record — it is the live constraint system that prevents the model from hallucinating architecture across feature boundaries. When auth decisions exist in the vault, the model must reference them when designing checkout's auth dependency, not generate auth assumptions from training data.

## Alternatives Considered
**Single-feature focus with dependency notes:** Stay on checkout, note "needs auth decision," come back later. Rejected because it's artificial — real design thinking follows dependency chains. Forcing the human to defer a blocking dependency disrupts the thought process.

**Model-managed feature switching:** The model decides when to switch features and tracks the state. Rejected as over-engineering — the human's attention moves naturally, the vault captures where each decision lands.

## Consequences
- **Positive**: Natural design flow — dependencies are resolved when they surface, not deferred
- **Positive**: Vault prevents cross-feature hallucination — the model reads existing decisions instead of generating defaults from training data
- **Positive**: No feature-tracking state machine needed — frontmatter tags handle it
- **Negative**: Risk of scattered, unfocused sessions — but that's the human's responsibility
- **Negative**: Vault must be consulted before any cross-feature claim — the core must instruct this explicitly

## Revisit When
- If users consistently produce scattered, unfocused vaults — may need soft nudges about feature coherence
