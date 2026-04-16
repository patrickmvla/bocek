# ADR-0010: Six Primitives Covering Full Engineering Workflow

## Status
Accepted

## Context
The original design document proposed three primitives (design, research, implementation) with a note that the system is extensible. Analysis of real engineering workflows revealed gaps — debugging, refactoring, and review are distinct modes with different intents, tool constraints, and vault interaction patterns.

## Decision
Bocek ships with six primitives:

| Primitive | Intent | Vault interaction | Source writes? |
|-----------|--------|-------------------|----------------|
| **Design** | Force decisions via interrogation | Writes decisions, contracts | No |
| **Research** | Gather evidence from code and docs | Writes research findings | No |
| **Implementation** | Build code constrained by vault | Reads compiled context | Yes |
| **Debugging** | Understand and fix failures | Reads context, may write discoveries | Yes |
| **Refactoring** | Reshape existing code | Reads contracts, may update them | Yes |
| **Review** | Evaluate code against design | Reads everything, writes drift findings | No |

Each primitive has a unique combination of intent, tool constraints, and vault interaction. No two overlap enough to merge.

Hook enforcement splits cleanly into two groups:
- **Reasoning modes** (design, research, review): block Write/Edit on source files
- **Code modes** (implementation, debugging, refactoring): allow Write/Edit on source files

All six modes can write to `.bocek/` — vault writes are always allowed.

## Alternatives Considered
**Three primitives (original proposal):** Design, research, implementation. Rejected because debugging is fundamentally different from implementation (goal is understanding, not building), refactoring is different from implementation (reshaping vs adding), and review is different from design (evaluating existing code vs making new decisions). Collapsing these into three modes loses the distinct constraints that make each mode effective.

**Open-ended (let users create their own):** The system supports this — primitives are just markdown files. But shipping without a core set leaves users without the methodology. The six cover the workflows engineers actually do.

## Consequences
- **Positive**: Covers the full engineering workflow — no gaps where the human has to work without a primitive
- **Positive**: Clean hook enforcement — two groups, one rule (source file writes yes/no)
- **Positive**: Each mode can be deeply designed without competing for scope
- **Negative**: Six primitives to write, test, and maintain vs three
- **Negative**: More modes means more mode-switching decisions for the human — but humans already make these decisions naturally

## Revisit When
- If two primitives consistently get used interchangeably, merge them
- If a seventh workflow emerges that can't be served by the six (e.g., deployment, documentation as a distinct mode)
