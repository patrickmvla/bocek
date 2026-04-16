---
type: decision
features: [checkout, inventory]
related: ["[[checkout-api-contract]]", "[[stripe-idempotency-research]]"]
created: 2026-04-16
confidence: high
---

# Use optimistic locking for inventory management

## Decision
Inventory uses a version column. On checkout, the transaction reads the current version, processes the charge, then attempts a conditional update (`UPDATE inventory SET quantity = quantity - 1, version = version + 1 WHERE id = ? AND version = ?`). If the version changed between read and write, the update affects 0 rows and the transaction is rolled back.

## Reasoning
Write contention is low — projected peak is ~20 concurrent checkouts per product. Optimistic locking avoids holding database locks during the Stripe charge (which takes 200-800ms). Pessimistic locking would hold row locks across that external call, creating a bottleneck under any concurrent load.

## Strongest rejected alternative
Pessimistic locking (`SELECT FOR UPDATE`) would guarantee no conflicts but holds database row locks during the entire checkout transaction, including the Stripe charge. At 20 concurrent checkouts on the same product, this creates a serial queue where each checkout waits for the previous Stripe call to complete. Estimated throughput: 1-5 checkouts/second per product vs ~20/second with optimistic locking.

## Failure mode
Under flash sale conditions (500+ concurrent checkouts for the same item), optimistic locking generates a retry storm. Each conflicting transaction re-reads, re-validates, and re-attempts. If retry logic isn't bounded, this amplifies database load instead of reducing it. Mitigation: bounded retry count (max 3), exponential backoff, and a circuit breaker that returns 503 if conflict rate exceeds threshold.

## Revisit when
- Write contention exceeds 50 concurrent writers per product (flash sales, limited drops)
- Stripe charge latency increases beyond 1 second consistently
- The bounded retry mechanism (max 3) produces unacceptable user-facing failure rates
