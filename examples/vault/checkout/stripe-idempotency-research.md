---
type: research
features: [checkout]
related: ["[[optimistic-locking]]", "[[checkout-api-contract]]"]
created: 2026-04-16
confidence: high
---

# How does Stripe handle idempotency in production?

## Question
What mechanism does Stripe use for idempotency, and how should our checkout use it to prevent double charges during retry scenarios?

## Sources examined
- stripe/stripe-node:src/RequestSender.ts:45-89 — (GitHub API read)
- https://docs.stripe.com/api/idempotent_requests — (official docs, April 2026)
- https://stripe.com/blog/idempotency — (engineering blog, 2017, still referenced in current docs)

## Findings
### Idempotency-Key header
Stripe accepts an `Idempotency-Key` header on all POST requests. If a request with the same key has been seen in the last 24 hours, Stripe returns the original response without re-processing. Keys are scoped to the API key (not the customer or account).

### Client library behavior
`stripe-node` does NOT auto-generate idempotency keys. The caller must provide them. The library retries on network errors (with the same key) up to 2 times with exponential backoff.

### Key generation guidance
Stripe recommends using a UUID derived from the business operation (e.g., `checkout:{cart_id}:{attempt}`) rather than a random UUID. This ensures the same logical operation always uses the same key, even across process restarts.

## Conflicts
Stripe's 2017 blog post suggests idempotency keys are optional for safe operations. Current docs (2026) recommend them on ALL POST requests. The blog post is outdated on this point — current guidance is stronger.

## Conditions
- Keys expire after 24 hours — retries beyond that window are treated as new requests
- Keys are per-API-key, not per-customer — shared API keys between services could collide
- Idempotency only applies to the Stripe call itself — our own database operations need separate idempotency handling

## Open threads
- What key format prevents collisions across retry attempts vs genuinely new checkout attempts for the same cart?
- Should we store the idempotency key in the cart record to survive process restarts?
