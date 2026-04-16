# Session Continuity

Checkpoint progress to `.bocek/state.md` so sessions can crash and resume without losing resolved work.

## When to checkpoint

- After every resolved decision (design mode)
- After every research entry written to vault (research mode)
- After every contract satisfied (implementation mode)
- After root cause identified and after fix applied (debugging mode)
- After human approves plan and after each verified step (refactoring mode)
- After each vault entry reviewed (review mode)

## State format

```markdown
## Current state
- **Mode:** [active mode]
- **Feature:** [active feature(s)]
- **Last resolved:** [[vault-entry-name]]
- **In progress:** [what's being worked on — enough detail to resume]
- **Next:** [next step when resuming]

## Session history
- [timestamp or sequence] — [what was completed]
- [timestamp or sequence] — [what was completed]
```

## Resuming a session

New sessions read: primitive core → `.bocek/state.md` → relevant vault entries → continue.

The state file tells you:
1. What mode to be in
2. What feature you're working on
3. What's already done (don't redo)
4. What's in progress (continue)
5. What's next (start here)

## Rules

- Overwrite state on every checkpoint — state.md is current state, not history
- The session history section is a brief log, not a full record — just enough to show progression
- If the state file is empty or missing, start fresh — read the vault index and ask the human what to work on
