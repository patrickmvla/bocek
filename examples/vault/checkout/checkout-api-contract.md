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

## Request
```json
{
  "cart_id": "string (UUID)",
  "payment_method_id": "string (Stripe payment method ID)"
}
```

## Responses

### 200 — Success
```json
{
  "order_id": "string (UUID)",
  "status": "confirmed"
}
```
Inventory decremented, payment charged, order record created.

### 402 — Payment failed
```json
{
  "error": "payment_failed",
  "detail": "string (Stripe error message)"
}
```
Inventory NOT decremented. No order created. Cart remains active.

### 409 — Inventory conflict
```json
{
  "error": "inventory_conflict"
}
```
Optimistic lock version mismatch. Client should retry (max 3 attempts with exponential backoff). Inventory was modified between cart load and checkout attempt.

### 410 — Cart expired
```json
{
  "error": "cart_expired"
}
```
Cart passed the 30-minute inactivity window per [[cart-expiry]]. Client must create a new cart.

### 422 — Validation error
```json
{
  "error": "validation_error",
  "fields": {
    "field_name": "error description"
  }
}
```
Malformed request. Missing or invalid fields.

## Transaction order
1. Validate request
2. Load cart (fail 410 if expired)
3. Check inventory version (fail 409 if stale)
4. Charge payment via Stripe with idempotency key `checkout:{cart_id}:{version}`
5. Update inventory (conditional on version)
6. Create order record
7. Return 200

Payment is charged BEFORE inventory is decremented. On inventory conflict after payment, the charge is refunded automatically.
