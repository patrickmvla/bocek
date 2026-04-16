# Behavior Mapping

Before touching code, document what it does in terms of behavior, not structure.

## How to map

For each block of code being refactored:

1. **State the behavior** — "This block handles the case where a payment succeeds but inventory was claimed by another transaction between the lock check and the commit."
2. **Identify inputs** — what triggers this code path
3. **Identify outputs** — what state changes, what gets returned
4. **Identify edge cases** — branches, error handlers, early returns
5. **Note dependencies** — what external state does this code read or modify

## Example

```
Function: processCheckout (checkout.js:25-89)

Behavior:
1. Loads cart from database (line 28)
2. Checks inventory version matches cart snapshot (line 35)
   - Edge case: version mismatch → returns 409 (lines 36-38)
3. Charges payment via Stripe (line 45)
   - Edge case: charge failure → releases inventory, returns 402 (lines 46-52)
4. Creates order record (line 58)
5. Sends confirmation event (line 65)
   - Edge case: event send failure → logs warning, does NOT roll back (line 67)

Dependencies:
- Database connection (read: cart, inventory; write: order)
- Stripe API (external call)
- Event bus (fire-and-forget)

Unknown: Lines 70-74 — catch block that retries the order write once on
database timeout. No test covers this. No vault decision mentions retry
behavior on order creation. → UNTOUCHABLE until explained.
```

## The goal

After mapping, you should be able to answer: "If I delete line X, what behavior changes?" for every line in scope. If you can't answer that for a line, it's unknown code — flag it.
