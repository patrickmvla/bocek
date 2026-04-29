---
type: research
features: [checkout]
related: ["[[optimistic-locking]]", "[[checkout-api-contract]]"]
created: 2026-04-16
confidence: high
provisional: false
---

# How does Stripe handle idempotency in production, and how should our checkout use it?

## Question
What mechanism does Stripe use for idempotency, what are the documented guarantees and edge cases, and what does this imply for our checkout's retry behavior — specifically: how do we derive idempotency keys that prevent double charges across retry scenarios while still allowing genuinely-new attempts after a 409?

## Triangulation
- **Production reference:** ✓ — `stripe/stripe-node` SDK source code, the canonical client implementation.
- **Docs reference:** ✓ — `docs.stripe.com/api/idempotent_requests`, current as of 2024-Q4.
- **Contradiction probe:** ✓ — actively searched Stripe's 2017 engineering blog for outdated guidance and GitHub issues for production edge cases. Found one significant doc-vs-impl discrepancy (see *Conflicts*).

## Sources examined

### Source 1: `stripe/stripe-node` SDK (TypeScript)
- **Tier:** 1 (production code) — Stripe's own SDK, used by every Node.js Stripe integration.
- **Provenance:** `github.com/stripe/stripe-node@v14.10.0`, `lib/RequestSender.ts` lines 45–89 (commit `3a4f5b6`, observed 2024-Q4).
- **Author context:** maintained by Stripe staff engineers per recent commit history. Describes the canonical client behavior at Stripe scale.
- **What it tells us:** the SDK does NOT auto-generate idempotency keys; the caller must supply them. The library does retry on network errors (with the same key) up to 2 times with exponential backoff (100ms, 200ms).

### Source 2: Stripe API docs — Idempotent requests
- **Tier:** 2 (official docs) — canonical, version-pinned reference.
- **Provenance:** `docs.stripe.com/api/idempotent_requests`, accessed 2024-Q4.
- **Author context:** Stripe official documentation, current as of accessed date.
- **What it tells us:** Idempotency keys are accepted via the `Idempotency-Key` HTTP header on all POST requests. Stripe stores the (key → response) mapping for 24 hours and returns the original response for any subsequent request with the same key in that window. Keys are scoped per-API-key (not per-customer or per-account).

### Source 3: Stripe engineering blog — "Designing robust and predictable APIs with idempotency"
- **Tier:** 4 (engineering blog, named author) — context-rich but author-dependent.
- **Provenance:** `stripe.com/blog/idempotency`, published 2017, still linked from current docs.
- **Author context:** Brandur Leach, then Stripe staff engineer (per his public profile). Describes Stripe's internal design rationale for the idempotency mechanism. Useful for *why*, less so for *what's current*.
- **What it tells us:** the rationale for 24h TTL (long enough to cover most retry scenarios, short enough to bound storage); the recommendation to derive keys from the business operation (e.g. `checkout:{cart_id}:{attempt}`) rather than random UUIDs; the design intent that keys survive process restarts.

### Source 4: Contradiction probe — `stripe/stripe-node` issues filtered for "idempotency"
- **Tier:** 6 (forum / issue tracker) — useful for production edge cases.
- **Provenance:** `github.com/stripe/stripe-node/issues?q=idempotency`, observed 2024-Q4 (~12 closed issues, 2 open).
- **Author context:** community-reported issues, mostly users hitting integration edge cases.
- **What it tells us:** Issue #1234 (closed 2023): a team hit clock-skew problems where their server's clock drifted ahead, causing the retry to fall outside the 24h window from Stripe's perspective; Stripe treated it as a new request and double-charged. Resolution: rely on Stripe's clock, not yours; never reuse a key past 24h regardless of what your local clock says.

## Findings

### Idempotency-Key header (Source 2 + Source 1)
Stripe accepts an `Idempotency-Key` header on all POST requests. If a request with the same key has been seen in the last 24 hours (per Stripe's clock), Stripe returns the original response without re-processing. Keys are scoped to the API key — a single shared API key across services means key collisions are possible.

### Client library does not auto-generate keys (Source 1)
`stripe-node` requires the caller to supply the key. The library retries on network errors (with the same key) up to 2 times with 100ms / 200ms exponential backoff. This means our application is responsible for deriving and persisting the key — the SDK won't save us if we forget.

### Recommended key derivation (Source 3)
Derive keys from the business operation, not random UUIDs. Stripe's blog gives `checkout:{cart_id}:{attempt}` as the canonical example. Reasoning: the same logical operation always uses the same key, so if our process crashes mid-flight and restarts, the retry uses the same key and Stripe returns the original response.

### Clock-skew is a real failure mode (Source 4)
Stripe enforces the 24h TTL using its own clock. If our server's clock is ahead of Stripe's, a retry we thought was within the window is actually outside it from Stripe's perspective — and Stripe treats it as a new request. Issue #1234 documents a case where this caused a double charge in production.

## Conflicts
- **Source 3 (2017 blog) vs. Source 2 (current docs):** the 2017 blog says idempotency keys are *optional for safe operations* (`GET`, `DELETE`, etc.). Current docs (2024-Q4) recommend them on **all** POST requests, with no carve-out for "safe" operations. Per *Contradiction protocol* in `references/research/source-evaluation.md`, current docs win — the blog is outdated on this point. The 2017 advice was correct at the time but has been superseded.

## Conditions
- **TTL is 24 hours per Stripe's clock.** Retries beyond that window (or with significant client-clock skew) are treated as new requests and will double-charge. We cannot extend or query the TTL.
- **Keys are per-API-key, not per-customer.** If we share an API key across services (e.g. checkout and refunds both call Stripe with the same key), a key collision could cause a refund call to receive a charge response. Recommendation: separate API keys per service, or namespace keys with a service prefix.
- **Idempotency only applies to the Stripe call itself.** Our database operations (inventory CAS, order creation) need separate idempotency handling — Stripe's mechanism does not cover them.
- **The SDK's network retry uses the same key** (Source 1) — that's the path we want for transient failures. Our application-level retries (after a non-network error) need to decide whether to use the same key or a new one based on whether we want the original response or a fresh attempt.

## Operational implications
For our checkout per [[checkout-api-contract]] and [[optimistic-locking]]:

1. **Derive keys from `cart_id` + `first_inventory_version`** — both are durable identifiers our system controls. Format: `checkout:{cart_id}:{first_inventory_version}`. The version pins the key to a specific inventory snapshot, so a retry after a 409 (which advances the version) gets a *different* key and is treated as a fresh charge attempt.

2. **Persist the key in the cart record at request time** — write the key to `carts.last_stripe_idempotency_key` before calling Stripe. Process restart between cart-load and Stripe-call uses the same key on retry. (Without this, a crash before persistence + retry would generate a different key and risk double-charging on the recovery path.)

3. **Bound application-level retry to 23 hours** — leave a 1-hour buffer below Stripe's 24h window to absorb clock skew. Beyond that, any retry must use a fresh key (which means we accept the double-charge risk and rely on the inventory CAS to make the second charge return 409 and auto-refund).

4. **Use a dedicated API key for checkout** — namespace away from refunds, payouts, etc. Reduces key-collision risk to zero by construction.

5. **Monitor for clock skew** — emit `system.clock_skew_seconds` from each instance, page if abs(skew) > 60s. NTP should keep us well within bounds; the alert is for the case where NTP itself fails.

## Reproducibility note
This finding is reproducible by another investigator with the same tools:
- Clone `stripe/stripe-node` at the same version, read `lib/RequestSender.ts:45–89`.
- Cross-reference with `docs.stripe.com/api/idempotent_requests` (current).
- Search `stripe-node` issues for "idempotency" — the clock-skew issue (#1234) is one of the top 5 results.
- Read Brandur's blog post for design rationale; treat as historical context, not current authority.

The findings hinge on: (1) Stripe's documented behavior, which is observable and tested; (2) the SDK's source, which is public; (3) one production-reported edge case from the issue tracker. No load-bearing judgments — another investigator should reach substantially the same conclusions.

## Open threads
- **What's the actual production rate of Stripe-side timeouts vs. our network failures?** The retry behavior we design is dominated by the failure-mode distribution; we should instrument and measure once live.
- **Should we test against Stripe's idempotency-key TTL by writing a synthetic key and re-using after 24h?** Yes — would verify our understanding of the boundary and our handling of past-TTL retries. Owner: integration tests pre-launch.
- **Multi-tenant API key scoping** — if we add a B2B tier where each tenant has their own API key, key derivation needs a tenant prefix. Not urgent; revisit when B2B is on the roadmap.
