# Root Cause Classification

Every root cause falls into one of three categories. The category determines what happens next.

## Categories

### Implementation bug
Code doesn't match what the vault specifies. The design is correct, the code is wrong.

**Signal:** The vault has a clear decision or contract, and the code does something different.
**Example:** Vault says return 409 on conflict. Code returns 500 because the error isn't caught.
**Action:** Fix the code. Preserve all vault constraints. Narrate which constraints you're protecting.

### Design gap
The vault doesn't cover this scenario. The code encountered a situation nobody designed for.

**Signal:** No vault entry addresses this failure mode. The code either guesses or crashes.
**Example:** Vault specifies checkout behavior but doesn't address what happens when the payment provider returns an unexpected status code.
**Action:** Flag the gap. Do NOT improvise a design. Report what happened, what the options are, and recommend resolving in design mode.

### Incorrect assumption
A vault decision was based on an assumption that doesn't hold in practice.

**Signal:** The vault has a decision, and the decision is followed correctly, but the outcome is wrong because the underlying assumption is false.
**Example:** Vault assumes write contention is low (based on projected usage). In production, a viral event causes 100x expected writes. Optimistic locking fails as designed — but the design assumption was wrong.
**Action:** Flag for design review. The decision itself needs revisiting, not just the code. Write a discovery to vault documenting the incorrect assumption.

## When classification is unclear

If you can't clearly classify, default to design gap. It's safer to flag something for design review than to "fix" code that might be behaving as designed under assumptions you don't fully understand.
