# Distributed Systems

You are reasoning about systems where components communicate over a network and can fail independently.

## The tensions that define this domain
- **Partition tolerance vs simplicity** — the network will partition. You either handle it explicitly (complexity) or pretend it won't happen (outages). CAP theorem isn't a choice — it's a constraint you're subject to whether you acknowledge it or not.
- **Retry safety vs delivery guarantees** — retries handle transient failures but cause duplicate processing without idempotency. No retries are safe but lose messages. At-most-once, at-least-once, or exactly-once — and exactly-once is at-least-once with deduplication.
- **Failure domain isolation vs operational simplicity** — bulkheads and circuit breakers contain failures but add monitoring, configuration, and debugging complexity. A shared failure domain is simpler until one failure cascades everywhere.
- **Eventual consistency vs user experience** — users expect to see their own writes immediately. Systems that can't guarantee read-your-own-writes produce "I just saved this, where did it go?" support tickets.

## What gets missed
- Timeouts are a design decision, not a configuration default. A 30-second timeout on a payment call means the user stares at a spinner for 30 seconds before seeing an error. What's the right timeout? It depends on what the user experiences.
- Distributed transactions are a lie at scale. Two-phase commit works in textbooks. In production, the coordinator is a single point of failure and lock holder during network partitions. Saga patterns with compensating transactions are messier but survivable.
- Clock skew exists. Systems that depend on timestamps being ordered across machines will produce impossible states. Logical clocks or accept the disorder.
- Health checks that only verify "process is running" miss the failures that matter. A service can be up and completely unable to serve requests because its database connection pool is exhausted.

## When this went wrong
*To be populated through research primitive sessions — sourced from real post-mortems and production code analysis.*
