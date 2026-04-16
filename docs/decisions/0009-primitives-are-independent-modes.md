# ADR-0009: Primitives Are Independent Modes, Not Sequential Stages

## Status
Accepted

## Context
The three core primitives (design, research, implementation) could be structured as a pipeline (design ��� research → implementation) or as independent operational modes the human enters in any order.

## Decision
Primitives are independent entry points with no enforced sequencing. The human decides which mode to enter and when. The hook layer enforces what a mode can do (tool access constraints), never which mode comes next. The vault provides continuity between modes, not the order of execution.

## Alternatives Considered
**Sequential pipeline with enforcement:** Design must complete before research, research before implementation. Rejected because it cripples the engineering thought process. Real engineering is non-linear — you might need research to inform design, or discover a missing decision during implementation that sends you back to design. Enforcing sequence does exactly what the market already does wrong: constraining the human instead of empowering them.

**Recommended sequence with soft warnings:** Warn if entering implementation without design decisions in the vault. Considered but deferred — this could be a useful nudge but shouldn't block the human.

## Consequences
- **Positive**: Human judgment controls sequencing — the correct sequence for a given moment is whatever the human decides
- **Positive**: Non-linear workflows are first-class — research before design, design during implementation, all valid
- **Positive**: Hook layer stays simple — only enforces tool constraints per mode, no state machine
- **Negative**: A human could jump straight to implementation and skip design entirely — but that's their choice, and the vault will be empty, which is its own signal

## Revisit When
- If users consistently shoot themselves in the foot by skipping design, consider soft nudges (not enforcement)
