# Trace Protocol

When tracing an error through code, follow execution — don't guess.

## The trace

1. **Start at the error** — the exact line in the stack trace where the error was thrown or logged
2. **Read the function** — understand what it's doing, what state it expects, what it produces
3. **Walk up the call chain** — follow each caller in the stack trace. At each level, understand what state was passed in and what was expected
4. **Find the divergence** — the point where actual behavior differs from expected behavior. This is the root cause candidate.
5. **Verify the divergence** — can you explain WHY the state diverged? If not, keep tracing.

## Example

```
Error: InventoryConflictError at checkout.js:45
Stack:
  at checkInventory (inventory.js:112)
  at processCheckout (checkout.js:45)
  at handleRequest (router.js:28)

Trace:
1. inventory.js:112 — version check fails. Current version is 3, expected 2.
2. checkout.js:45 — calls checkInventory with version from cart snapshot.
3. Cart was loaded at request start (version 2), but inventory was updated
   between cart load and checkout attempt.

Root cause candidate: race condition between cart snapshot and inventory check.
Vault check: [[optimistic-locking-decision]] specifies this exact scenario
should return 409. This is DESIGNED BEHAVIOR, not a bug.

Conclusion: The error is expected. The bug is in the caller — it's not
handling the 409 and retrying or informing the user.
```

## What to capture

- The exact trace path (file:line at each step)
- The state at each step (what values, what conditions)
- Where state diverged from expectations
- Whether the divergence is a bug or designed behavior (check vault)
