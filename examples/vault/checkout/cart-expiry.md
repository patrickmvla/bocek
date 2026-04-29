---
type: decision
features: [checkout]
related: ["[[checkout-api-contract]]"]
created: 2026-04-16
confidence: medium
---

# Carts expire after 30 minutes of inactivity

## Decision
Carts have a `last_active_at` timestamp updated on every cart modification (add item, remove item, update quantity, view cart from authenticated session). A cart is considered expired if `now() - last_active_at > 30 minutes`. Expired carts are rejected at checkout with HTTP 410 per [[checkout-api-contract]]. Expired carts are cleaned up by a background job (every 5 minutes), not inline at checkout — keeps the checkout path free of janitorial work.

## Reasoning
Holding inventory reservations indefinitely causes phantom stock-outs — items appear unavailable because abandoned carts are blocking them (production-cited: Shopify "Inside Shopify's modular monolith", 2022, references the same failure mode). 30 minutes balances user convenience (long enough to complete a purchase even with mid-flow interruptions) against inventory accuracy (short enough to recycle abandoned reservations during peak traffic). The 30-minute floor is conventional in e-commerce checkout flows (tutorial-blog: multiple Shopify / Etsy implementation guides; confidence: medium — the number is convention, not measured for our specific traffic pattern).

## Engineering substance applied
- **Failure semantics:** A cart that expires mid-checkout produces a clean 410 response — no inventory side-effect, no charge attempt. The transaction order in [[checkout-api-contract]] checks expiry before payment, so a cart expiring during the request returns 410 without partial state.
- **Observability:** `cart.expired_at_checkout.count` metric emitted on each 410. If this rate exceeds 2% of checkout attempts, the 30-minute window is too short for our actual user behavior — that's a *Revisit when* trigger, not a 3am page.
- **Operability:** Background job is idempotent — running it twice yields the same state. Failure mode of the job stopping is "expired carts pile up" not "double-deletion" — caught by a separate alert on `cart.expired.cleanup_lag_minutes > 30`.

## Production-grade gates
- **Idiomatic** — `last_active_at` timestamp + background sweep is the standard pattern for soft-expiry in transactional schemas (docs-cited: Drizzle / Prisma docs on timestamp columns; production-cited: pattern is visible in many open-source e-commerce projects, e.g. `medusajs/medusa` `cart` table).
- **Industry-standard** — Shopify uses ~24-hour cart expiry with a similar inactivity-timestamp pattern; Stripe Checkout uses ~24-hour session expiry (docs-cited: docs.stripe.com/payments/checkout/sessions). Our 30-minute window is shorter because our inventory is more constrained than theirs.
- **First-class** — uses native Postgres timestamp comparison and a standard background-job pattern (cron / scheduled task). No custom TTL infrastructure.

## Rejected alternatives

### No expiry — carts live forever until explicitly abandoned or checked out
**What:** Leave carts in the database indefinitely; users come back to them whenever.
**Wins when:** Inventory isn't constrained (digital goods, infinite supply) or the business model expects very long purchase consideration windows (high-ticket B2B sales).
**Why not here:** Our SKUs are inventory-limited, and reservations without expiry accumulate during high-traffic periods, causing real stock to appear sold out. The Shopify post-mortem documents this exact failure mode in their early years.

### Hard expiry at fixed clock time (e.g. cart expires 30min after creation, regardless of activity)
**What:** `expires_at = created_at + 30min`, no extension on activity.
**Wins when:** The flow is deliberately time-boxed (e.g. limited-time offers, scheduled drops where everyone gets exactly 30 minutes). Predictable for the user.
**Why not here:** Penalizes users who actively browse and edit their cart over 30+ minutes. Our checkout is open-ended, not a time-boxed sale.

### Inline expiry check + cleanup at checkout (no background job)
**What:** Check expiry on every read; clean up expired carts when they're touched.
**Wins when:** Cart traffic dominates background-job complexity — every checkout already touches the cart, so inline cleanup is "free."
**Why not here:** Carts that are never re-touched (the abandoned ones we want to clean) never get swept inline. Inventory reservations stay held. The background job is the only mechanism that catches truly-abandoned carts.

### Reservation-based with separate TTL (cart items hold an inventory reservation that times out independently)
**What:** Cart and inventory reservation are separate records with separate TTLs. Cart can outlive its reservation; on checkout, the reservation is re-acquired or the user gets 409.
**Wins when:** The cart is a UI artifact (long-lived) but the inventory commitment is separate (short-lived) — common in B2B procurement flows where the cart is a working document.
**Why not here:** Adds complexity (two timeouts to reason about, two failure modes — cart expired vs. reservation expired) for no user-facing benefit at our scale. Worth revisiting if we add features like saved-for-later or shared carts.

## Failure mode
Users with slow connections, or who leave and return after 30 minutes, lose their cart. The 410 error needs to be clear enough that the user understands they need to re-add items — if the client doesn't handle 410 gracefully, users see a confusing error. Specific failure: a user starts checkout, switches to email to copy a discount code (~5 minutes), comes back, finds checkout expired. They retry but the inventory has shifted, leading to confusion. Frequency: estimated <2% of checkouts per Stripe Checkout's documented abandonment patterns at 30-min vs. 24-hour windows (docs-cited but for a different system; confidence: low — verify against our actual data once instrumented).

## Mitigations
- **Client-side warning at 25 minutes:** "Your cart will expire in 5 minutes — complete checkout or your items may become unavailable."
- **Refresh-on-cart-view:** any authenticated cart view updates `last_active_at`, so users with the page open don't lose progress just from idle reading.
- **Friendly 410 page:** the client routes 410 to a "Your cart expired" screen with a single button to re-create the cart from the previous items if inventory is still available.

## Revisit when
- Support tickets indicate 30 minutes is too short for our users (>10 tickets/month about lost carts).
- Inventory reservation model changes (e.g., soft reservations that don't block other users) — the whole cost-benefit shifts.
- Average checkout completion time exceeds 10 minutes (current target: <5min) — would erode the safety margin.
- Multi-tab / multi-device cart synchronization is added — `last_active_at` semantics get more complex.
