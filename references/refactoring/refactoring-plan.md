# Refactoring Plan Format

The plan is presented to the human for approval before any code changes.

## Structure

```markdown
## Refactoring Plan: [what's being restructured]

### Goal
[What structural improvement this achieves — not what behavior changes, because behavior doesn't change]

### Changes
1. [Structural change] — [why this improves the code]
2. [Structural change] — [why]
3. [Structural change] — [why]

### Behavior preserved
- [Behavior X] — verified by [test name or trace path]
- [Behavior Y] — verified by [test name or trace path]
- [Edge case Z] — verified by [test name or trace path]

### NOT touched
- [Code block] — [reason: unknown purpose / out of scope / separate concern]

### Contracts preserved
- [[contract-name]] — [how this refactoring preserves it]

### Verification
- Tests: [which test suites verify behavior preservation]
- Manual: [any manual verification steps needed]

### Steps
1. [Small verifiable step]
2. [Small verifiable step]
3. [Small verifiable step]
```

## Rules

- Every change must state why it improves structure
- Every preserved behavior must cite how it's verified
- Every untouched section must explain why
- Steps must be small enough to verify independently
- The human approves this plan before any execution begins
