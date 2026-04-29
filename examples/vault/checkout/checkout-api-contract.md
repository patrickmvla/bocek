---
type: contract
features: [checkout]
related: ["[[optimistic-locking]]", "[[stripe-idempotency-research]]", "[[cart-expiry]]"]
created: 2026-04-16
confidence: high
---

# Checkout API Contract

## Endpoint
`POST /api/checkout`

Authentication: required. Bearer token in `Authorization` header. Unauthenticated requests return 401.

## Request

```json
{
  "cart_id": "string (UUID)",
  "payment_method_id": "string (Stripe payment method ID)"
}
```

Both fields required. Missing or malformed → 422.

## Engineering substance applied

- **Failure semantics:** at-least-once on the Stripe charge call (the network may fail after the charge succeeds at Stripe), at-most-once on the inventory write (CAS via [[optimistic-locking]] only succeeds once per version), at-most-once on the order record creation (database `INSERT` is atomic). The combination is reconciled by:
  - Stripe idempotency keys per [[stripe-idempotency-research]] — a retry with the same key returns the original charge response without double-charging.
  - The 409 path triggers an automatic Stripe refund — if the charge succeeded but inventory CAS failed, the user is not charged.
- **Concurrency:** multiple checkout attempts on the same cart are serialized at the inventory row via [[optimistic-locking]]. The cart itself is not locked — last-update-wins on cart fields is acceptable since checkout is the terminal operation.
- **Consistency:** read-your-writes within a single checkout request (transaction). No cross-request consistency guarantee — clients should not assume that two checkout requests on the same cart produce a defined ordering of effects.
- **Observability:** every response includes a request ID (`X-Request-ID` response header). 5xx responses also include this in the body. Logs / spans / errors are correlated by this ID. Latency target: p99 < 1.5s (dominated by the Stripe call).
- **Security:** the trust boundary is at the auth check. Past that, we trust `cart_id` and `payment_method_id` are valid for this user. Cart IDs are UUIDv4 (unguessable) — but we still verify ownership before processing.

## Responses

### 200 — Success
```json
{
  "order_id": "string (UUID)",
  "status": "confirmed"
}
```
Inventory decremented, payment charged, order record created. Idempotent — retrying with the same Stripe idempotency key returns the same response without side effects (per [[stripe-idempotency-research]]).

### 401 — Unauthenticated
```json
{
  "error": "unauthenticated"
}
```
Missing, malformed, or expired bearer token. Body is intentionally generic — no information about whether the token was missing vs. expired vs. signature-invalid (security: don't help an attacker enumerate auth states).

### 402 — Payment failed
```json
{
  "error": "payment_failed",
  "detail": "string (Stripe error message, sanitized)"
}
```
Inventory NOT decremented. No order created. Cart remains active. The `detail` field is the Stripe-provided customer-facing error message (e.g. "Your card was declined") — Stripe's sanitization rules apply (docs-cited: docs.stripe.com/api/errors).

### 409 — Inventory conflict
```json
{
  "error": "inventory_conflict"
}
```
Optimistic-lock version mismatch per [[optimistic-locking]]. Inventory was modified between cart load and checkout attempt. Stripe charge, if it occurred, is automatically refunded — the client does NOT need to handle the refund. Client should retry with a fresh cart load (max 3 attempts with exponential backoff: 250ms, 500ms, 1000ms).

### 410 — Cart expired
```json
{
  "error": "cart_expired"
}
```
Cart passed the 30-minute inactivity window per [[cart-expiry]]. Client must create a new cart — retrying with the same cart_id will continue to return 410.

### 422 — Validation error
```json
{
  "error": "validation_error",
  "fields": {
    "field_name": "error description"
  }
}
```
Malformed request. Missing or invalid fields. The `fields` object names each invalid field with a human-readable description (e.g. `{"cart_id": "must be a valid UUID"}`).

### 503 — Circuit breaker open
```json
{
  "error": "service_unavailable"
}
```
Optimistic-lock conflict-rate exceeded the circuit-breaker threshold for this product per [[optimistic-locking]]. Response includes `Retry-After: 5` header. The breaker re-closes automatically when conflict-rate falls below the threshold. Client should respect `Retry-After`.

## Transaction order
1. Validate request shape (→ 422 on failure).
2. Authenticate (→ 401 on failure).
3. Load cart and verify ownership (→ 422 if cart_id valid format but doesn't exist or doesn't belong to this user — both return the same shape; we do not distinguish, for security).
4. Check cart expiry (→ 410 if past the [[cart-expiry]] window).
5. Read inventory version for each item.
6. Charge payment via Stripe with idempotency key `checkout:{cart_id}:{first_inventory_version}`.
7. Conditional inventory update: `UPDATE ... WHERE id = ? AND version = ?` per [[optimistic-locking]].
   - If 0 rows affected → trigger Stripe refund, return 409.
   - If success → continue.
8. Create order record (`INSERT`, atomic).
9. Mark cart as `checked_out` (terminal state; cart cannot be modified after this).
10. Return 200.

**Payment is charged BEFORE inventory is decremented.** The reasoning: inventory CAS is fast (~5ms), Stripe charge is slow (200–800ms). Charging first means the slow path completes before the locking path opens its race window. On 409, the auto-refund recovers the user — net cost is one extra Stripe API call in the conflict case.

## Idempotency
Stripe idempotency key format: `checkout:{cart_id}:{first_inventory_version}`. Derivation rules per [[stripe-idempotency-research]]:
- Cart ID is the durable identifier — survives client restarts.
- The first item's inventory version is included so retries after a 409 use a *different* key (you're charging for a different inventory snapshot, conceptually).
- Keys are unique per (cart, version) pair, so genuine retries (network errors before Stripe acks) reuse the same key and Stripe returns the original response.
- Keys are stored in the cart record at step 6, so process restarts don't lose them.

## Versioning
This contract is `v1`. Breaking changes (new required fields, removed responses, changed semantics) require a new endpoint version (`/api/v2/checkout`). Additive changes (new optional fields, new response codes) can be made in place; clients must tolerate unknown fields.
