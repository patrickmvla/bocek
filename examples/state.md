## Current state
- **Mode:** design
- **Feature:** checkout
- **Last resolved:** [[cart-expiry]]
- **In progress:** Considering error recovery strategy — what happens when payment succeeds but order creation fails
- **Next:** Resolve the payment-success-but-order-failure scenario, then move to auth session lifecycle decisions

## Session history
- 2026-04-16 — Resolved inventory locking strategy → [[optimistic-locking]]
- 2026-04-16 — Researched Stripe idempotency → [[stripe-idempotency-research]]
- 2026-04-16 — Defined checkout API contract → [[checkout-api-contract]]
- 2026-04-16 — Resolved cart expiry policy → [[cart-expiry]]
