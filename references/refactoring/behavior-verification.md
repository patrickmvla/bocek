# Behavior Verification

After all refactoring steps complete, verify holistically that behavior is preserved.

## Verification steps

1. **Run full test suite** — not just the tests for the refactored area. Refactoring can have distant effects through shared state or imports.

2. **Trace critical paths** — walk through the most important user-facing flows that touch the refactored code:
   - Does the happy path produce the same result?
   - Does each error path produce the same error?
   - Do side effects (events, logs, state changes) still occur in the same conditions?

3. **Compare contracts** — re-read every vault contract that touches the refactored area. Confirm the refactored code still satisfies each one.

4. **Check integration points** — if the refactored code interfaces with other components, verify the interface hasn't changed:
   - Same function signatures (or updated callers)
   - Same return types
   - Same error types
   - Same side effects

## What constitutes a behavioral change

- Different output for the same input
- Different error for the same failure condition
- Different side effects (missing event, extra log, changed state)
- Different timing characteristics that affect correctness (not performance)
- Different order of operations where order matters

## What does NOT constitute a behavioral change

- Different variable names
- Different code structure with same execution path
- Different internal organization (extracted functions, reordered declarations)
- Performance differences (unless a vault constraint specifies performance bounds)
