# Constraint-Preserving Fix

When fixing an implementation bug, every vault constraint in the affected area must be explicitly preserved.

## The fix protocol

1. **List constraints** — before writing any fix, list every vault decision and contract that touches the affected code
2. **Write the fix** — change only what's necessary to resolve the bug
3. **Verify each constraint** — after the fix, trace each constraint through the changed code
4. **Narrate preservation** — state which constraints you verified and how

## Example

```
Bug: Payment failure returns 500 instead of 402.
Cause: Stripe error not caught in the try/catch at checkout.js:58.

Constraints in this area:
- [[payment-api-contract]]: 402 with {error: "payment_failed", detail: string}
- [[optimistic-locking-decision]]: version check before payment charge
- [[inventory-contract]]: inventory reserved before payment, released on failure

Fix: Add catch for Stripe errors at checkout.js:58, return 402 with contract format.

Constraint verification:
✓ payment-api-contract: 402 response matches spec (error + detail fields)
✓ optimistic-locking: version check at line 42 unchanged
✓ inventory-contract: inventory release in finally block at line 75 unchanged
```

## What NOT to do

- Don't "improve" surrounding code while fixing the bug
- Don't add error handling for errors the contract doesn't specify
- Don't change the fix scope beyond what's necessary
- Don't remove code you don't understand, even if it "looks unnecessary"
