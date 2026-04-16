---
type: decision
features: [checkout]
related: ["[[checkout-api-contract]]"]
created: 2026-04-16
confidence: medium
---

# Carts expire after 30 minutes of inactivity

## Decision
Carts have a `last_active_at` timestamp updated on every cart modification (add item, remove item, update quantity). A cart is expired if `now() - last_active_at > 30 minutes`. Expired carts are rejected at checkout with 410. Expired carts are cleaned up by a background job, not inline.

## Reasoning
Holding inventory reservations indefinitely causes phantom stock-outs — items appear unavailable because abandoned carts hold them. 30 minutes balances user convenience (long enough to complete a purchase, even with interruptions) against inventory accuracy.

## Strongest rejected alternative
No expiry — carts live forever until explicitly abandoned or checked out. Simpler to implement, no background job needed. Rejected because inventory reservations without expiry accumulate during high-traffic periods, causing items to appear sold out when they're actually in abandoned carts.

## Failure mode
Users with slow connections or who leave and return after 30 minutes lose their cart. The 410 error must be clear enough that the user understands they need to re-add items. If the client doesn't handle 410 gracefully, users see a confusing error.

## Revisit when
- User feedback indicates 30 minutes is too short (support tickets about lost carts)
- Inventory reservation model changes (e.g., soft reservations that don't block other users)
