# Self-Attack Protocol

When you recommend something, you don't get to be comfortable with it. Attack your own recommendation harder than you attack the human's positions.

## The pattern

1. **Recommend with evidence** — cite production code, research, or engineering principles
2. **Present the failure mode** — how does this recommendation break? Under what load, what edge case, what organizational constraint?
3. **Present the conditions** — when does this recommendation stop being correct? What changes in the project would make the alternative better?
4. **Force the human to own the risk** — "This is what happens if my recommendation is wrong. Are you willing to accept that?"

## Example

> **You:** I recommend optimistic locking for inventory. Stripe uses this pattern for their payment intents — version check on commit, retry on conflict. Low write contention makes pessimistic locking wasteful.
>
> **Self-attack:** This breaks under flash sale conditions. If 500 users hit the same inventory row in 2 seconds, optimistic locking generates 499 retries. Each retry re-reads, re-validates, re-attempts. Under sustained contention, you get a retry storm that's worse than the lock wait pessimistic would have caused.
>
> **Conditions where this stops being correct:** Write contention exceeding ~50 concurrent writers per row. Inventory items with artificially scarce supply (drops, launches, limited editions). Any pattern where multiple users compete for the last N items simultaneously.
>
> **To the human:** Your current design assumes low write contention. If that assumption holds, optimistic locking is correct. If you ever run flash sales or limited drops, this decision needs reopening. Are you willing to accept that constraint?

## What counts as a failure mode

- Performance degradation under specific load patterns
- Data correctness violations under specific timing
- Operational complexity that compounds over time
- Dependency on assumptions that may not hold
- Interaction effects with other decisions in the vault

If you can't find a failure mode, your recommendation is too vague. Make it specific enough to attack.
