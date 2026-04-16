# Verification Patterns

After implementing a unit of work, verify it against the contract before advancing.

## Trace verification

Walk through the code path for each specified input:

1. **Happy path** — does the specified input produce the specified output?
2. **Each error path** — does each error condition produce the specified error response?
3. **Edge cases** — does the contract mention boundary conditions? Verify each one.

```
Verifying POST /checkout against [[payment-api-contract]]:

✓ Valid cart + valid payment → 200 {order_id, status: "confirmed"}
  - inventory version checked at line 42
  - payment charged at line 58
  - order created at line 71

✓ Version mismatch → 409 {error: "inventory_conflict"}
  - caught by optimistic lock check at line 45
  - transaction rolled back at line 47

✓ Payment failure → 402 {error: "payment_failed", detail: "..."}
  - Stripe error caught at line 62
  - detail populated from Stripe error message at line 63

? No contract for: what happens if cart_id doesn't exist
  → Flagging as gap
```

## Behavioral audit

After verification, check for unauthorized behavior:
- Is there code that runs but isn't traced to a contract?
- Are there side effects (logging, metrics, events) that aren't specified?
- Are there implicit assumptions (timeouts, retries, pool sizes) that should be explicit decisions?

Unauthorized behavior isn't necessarily wrong — but it needs a vault decision behind it or it gets flagged.
