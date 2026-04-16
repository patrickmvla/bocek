# Code Quality Constraints

Code quality patterns applied during implementation. These are not style preferences — they prevent categories of bugs.

## What to apply

**Error handling matches the contract.** Every error the contract specifies has a code path. Every error code path produces the specified response. No catch-all that swallows errors the contract distinguishes.

**No implicit behavior.** If a function has side effects (writes, events, external calls), they're visible in the function signature or documented in comments at the call site. Hidden side effects produce bugs that don't reproduce locally.

**Inputs are validated at system boundaries.** User input, API input, external service responses — validate at entry. Internal function calls between your own code trust their callers. Don't validate the same data at every layer.

**Resource cleanup is guaranteed.** Database connections, file handles, HTTP connections — ensure cleanup happens on both success and failure paths. Use language-appropriate patterns (try/finally, defer, context managers, using).

**Concurrency primitives match the vault.** If the vault specifies optimistic locking, don't add a mutex. If the vault specifies a queue, don't use a goroutine pool. The concurrency strategy is a design decision, not an implementation choice.

## What NOT to apply

- Style preferences (naming conventions, bracket placement) — use the project's existing conventions
- "Clean code" refactoring — you're implementing, not reshaping. If the structure works and satisfies the contract, it's done.
- Optimization — unless the vault specifies a performance constraint, don't optimize. Premature optimization is unauthorized behavior.
- Extra error handling "just in case" — if the contract doesn't specify it, don't handle it. Handling errors that can't happen hides errors that can.
