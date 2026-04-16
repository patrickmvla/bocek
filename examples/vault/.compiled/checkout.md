# Checkout — Compiled Vault Context

Compiled: 2026-04-16 | Sources: 4 vault entries

## Contents
- [Constraints](#constraints)
- [Contracts](#contracts)
- [Dependencies](#dependencies)

---

## Constraints

### Inventory uses optimistic locking
Version column on inventory rows. Conditional update on checkout: `UPDATE ... WHERE version = ?`. If 0 rows affected, version mismatch — roll back and return 409.

**Why:** Low write contention (~20 concurrent checkouts/product). Avoids holding row locks during Stripe charge (200-800ms).
**Breaks when:** >50 concurrent writers per product. Flash sales cause retry storms.
**Mitigation:** Bounded retries (max 3), exponential backoff, circuit breaker at high conflict rate.
Source: [[optimistic-locking]]

### Carts expire after 30 minutes of inactivity
`last_active_at` timestamp on cart. Expired = `now() - last_active_at > 30 min`. Rejected at checkout with 410. Cleanup by background job, not inline.

**Why:** Prevents phantom stock-outs from abandoned cart reservations.
**Breaks when:** Users return after 30 min and lose their cart.
Source: [[cart-expiry]]

### Stripe idempotency keys are required
All Stripe charge calls include `Idempotency-Key: checkout:{cart_id}:{version}`. Keys derived from business operation, not random UUIDs. Keys expire after 24 hours on Stripe's side.

**Why:** Prevents double charges during retry scenarios. Key format ties to the specific checkout attempt.
**Note:** Idempotency covers the Stripe call only. Database operations need separate handling.
Source: [[stripe-idempotency-research]]

---

## Contracts

### POST /api/checkout

**Request:**
```json
{
  "cart_id": "string (UUID)",
  "payment_method_id": "string (Stripe payment method ID)"
}
```

**Responses:**

| Status | Body | Condition |
|--------|------|-----------|
| 200 | `{order_id, status: "confirmed"}` | Success — inventory decremented, payment charged, order created |
| 402 | `{error: "payment_failed", detail: string}` | Stripe charge failed — inventory NOT decremented, cart remains active |
| 409 | `{error: "inventory_conflict"}` | Version mismatch — client retries (max 3, exponential backoff) |
| 410 | `{error: "cart_expired"}` | Cart inactive >30 min — client must create new cart |
| 422 | `{error: "validation_error", fields: {...}}` | Malformed request |

**Transaction order:**
1. Validate request
2. Load cart (fail 410 if expired)
3. Check inventory version (fail 409 if stale)
4. Charge payment via Stripe with idempotency key `checkout:{cart_id}:{version}`
5. Update inventory (conditional on version)
6. Create order record
7. Return 200

**Critical:** Payment charged BEFORE inventory decremented. On inventory conflict after payment, charge is refunded automatically.

Source: [[checkout-api-contract]]

---

## Dependencies

### Auth
Checkout endpoint requires authenticated request. JWT with 15-minute expiry per [[session-format]]. Client must refresh token before initiating checkout to avoid mid-flow expiry.
