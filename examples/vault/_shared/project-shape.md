---
type: decision
features: [_shared]
related: []
created: 2026-04-29
confidence: high
---

# Project shape: Acme Checkout

## What's being built
A standalone checkout service (HTTP API) for Acme's e-commerce site. Owns: cart, payment intent creation, payment capture, inventory decrement, order creation. Does NOT own: catalog, fulfillment, shipping, customer profile, returns. Boundary with adjacent systems is REST + webhook events.

## Scale
- **Current:** ~1k orders/day. Peak ~50/min during launch promotions. (Confidence: high — measured.)
- **6-month target:** ~5k orders/day. Peak ~200/min. (Confidence: medium — extrapolation from current trend; depends on holiday season conversion rate holding.)
- **24-month aspirational:** ~50k orders/day. Peak ~1000/min during flash sales. (Confidence: low — depends on marketing wins, partnership announcements not yet confirmed; replan if marketing pipeline shifts.)

## Team
- **Size:** 3 backend engineers (1 senior, 2 mid). 1 SRE shared with adjacent services (~30% allocation).
- **Expertise:** strong in TypeScript / Postgres / AWS / Stripe integration. Weaker in distributed systems, event sourcing, multi-region deployment.
- **Ownership window:** 18-month roadmap visible. Beyond that, ownership may shift to a payments-platform team being formed in 2027.

## Constraints
- **Latency:** p99 < 1.5s for the checkout call (dominated by the Stripe charge round-trip ~200–800ms).
- **Regulatory:** PCI-DSS scope avoidance — no raw card data in our systems; tokens only via Stripe Elements client-side.
- **Budget:** AWS bill < $10k/month for this service alone. Stripe fees passed through to merchant pricing.
- **Timeline:** v1 shipping in 8 weeks (post-launch hardening continues for ~6 months after).
- **Operational:** 1 SRE shared 30%; we get paged but they're not full-time on us. Page-able failures must be < 1/week sustained.

## Explicit non-goals
- **Multi-region deployment.** Single region (us-east-1) for the foreseeable future. Latency to non-US customers is accepted at this stage.
- **Currency support beyond USD.** Single currency v1. Multi-currency would require FX handling, payment-method routing, and tax-engine work — separate initiative.
- **Subscription / recurring billing.** Not in scope; separate service when the product needs it.
- **Saved payment methods (local storage).** Initially Stripe Customer-managed; we don't store payment methods in our database.
- **Refunds via API.** Handled in admin tool, manual. API support added when refund volume justifies it.
- **B2B / multi-tenant.** Single-tenant retail commerce v1. B2B has different auth, billing, and contract semantics — separate roadmap item.

## Success criteria for v1
- 99.9% successful-checkout rate (excluding payment failures, which are user-side and tracked separately).
- p99 latency < 1.5s sustained for 30 days post-launch.
- Zero PCI-scope expansion incidents.
- Inventory drift < 0.1% (drift = inventory believed available vs. inventory actually reservable; measured via daily reconciliation job).
- < 1 SRE page per week sustained over 30 days.

## Inherited by
Every decision in this vault inherits these constraints. When a proposal violates one — a decision that requires multi-region, expands PCI scope, triples the AWS bill, breaches the latency target, or rejects a non-goal without a named reason — the proposal must either be rejected or this entry must be updated *first* with the named change. Don't let project-shape rot silently while decisions accumulate that contradict it.

## Revisit when
- Scale assumptions break: we hit > 10k orders/day before the 6-month mark (we're approaching 24-month target faster than planned).
- Team composition changes substantially (e.g., the senior engineer leaves, or headcount doubles).
- Regulatory landscape changes (e.g., enabling EU sales triggers GDPR data-residency rules; a non-goal becomes a goal).
- Success criteria drift in priority (e.g., latency replaces availability as the primary concern, or a new SLO is added by exec).
- 24-month aspirational becomes a real near-term target (plan multi-region work *before* it's urgent).
