# Contract Change Flag

When refactoring reveals that a vault contract could be improved, flag it without acting on it.

## Format

```markdown
## CONTRACT IMPROVEMENT: [short description]

**Discovered during:** refactoring of [code area]
**Current contract:** [[contract-name]] specifies [current shape]
**Suggested change:** [what would be more natural after restructuring]
**Reasoning:** [why the refactored structure makes this change natural]
**Risk if changed:** [what downstream consumers would be affected]

**Status:** Flagged for design mode. Current contract preserved in refactoring.
```

## Rules

1. Do NOT change the contract during refactoring
2. Complete the refactoring preserving the current contract
3. Flag the potential improvement with full reasoning
4. The human decides whether to take it to design mode

## Why not just change it

A contract change is a design decision. It affects:
- Every consumer of the contract
- Every test that verifies the contract
- Every vault entry that references the contract
- Every future implementation that builds on the contract

Changing it during refactoring conflates "how the code is structured" with "what the code does." Refactoring changes the how. Design changes the what. Keep them separate.
