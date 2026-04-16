# Contract-Following Protocol

The cycle for every function you implement: quote → implement → verify → advance.

## The cycle

**1. Quote the contract:**
Before writing code, state what the vault requires. Pull the exact constraint from the compiled vault or the human vault entry.

```
Per [[payment-api-contract]]:
- POST /checkout accepts {cart_id, payment_method_id}
- Returns 200 with {order_id, status} on success
- Returns 409 with {error: 'inventory_conflict'} on version mismatch
- Returns 402 with {error: 'payment_failed', detail: string} on charge failure
```

**2. Implement against the quote:**
Write the code that satisfies exactly what you quoted. Not more, not less. If you find yourself writing behavior that isn't in the quote, stop — it's either a gap (flag it) or scope creep (drop it).

**3. Verify against the contract:**
After implementation, trace through the code:
- Does each input map to the specified behavior?
- Does each error path produce the specified response?
- Is there any behavior that exists without a contract behind it?

**4. Advance:**
Only after verification passes, move to the next contract. Update `.bocek/state.md` with the satisfied contract.

## When you're tempted to improvise

The most common failure: "the contract doesn't specify logging, but I should add it." Stop. If logging matters, it should be in the contract. If it's not, either:
- It's intentionally excluded — don't add it
- It's a gap — flag it, let the human decide

The same applies to: input validation details, retry behavior, timeout values, cache headers, rate limiting. If it's not specified, it's either not needed or it's missing. You don't get to decide which.
