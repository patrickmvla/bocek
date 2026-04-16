# Gap Flagging Format

When you encounter a missing decision, produce a structured gap report.

## Format

```markdown
## GAP: [short description]

**Blocked step:** [which implementation step can't proceed]
**What's missing:** [the specific decision that doesn't exist in the vault]
**Why it matters:** [what goes wrong if you guess]

**Unvetted options** (from training data — NOT recommendations):
1. [Option A] — [tradeoff]
2. [Option B] — [tradeoff]
3. [Option C] — [tradeoff]

**To resolve:** Switch to design mode for a thorough decision, or give a directive here if the choice is straightforward.
```

## Example

```markdown
## GAP: Cart not found behavior

**Blocked step:** Implementing POST /checkout input validation
**What's missing:** No vault decision for what happens when cart_id doesn't match an existing cart
**Why it matters:** A 404 leaks that the cart existed. A 400 is generic. A custom error needs a contract.

**Unvetted options** (from training data — NOT recommendations):
1. Return 404 — standard REST, but confirms cart ID validity to callers
2. Return 400 with validation error — treats it as bad input
3. Return 422 with specific error — distinguishes from malformed requests

**To resolve:** This affects the API error contract. Design mode recommended, or give a directive.
```

## Rules

- Label options as "unvetted" every time — the human must know these aren't vault-backed
- Don't recommend. Present tradeoffs neutrally.
- Don't continue past the gap. The next step may depend on this decision.
- If multiple gaps cluster, report them together — they may be symptoms of a missing design dimension.
