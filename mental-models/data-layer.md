# Data Layer

You are reasoning about how data is stored, accessed, and protected.

## The tensions that define this domain
- **Normalization vs query performance** — clean schema vs fast reads. Joins are correct; denormalization is fast. Pick wrong and you either have slow reads or update anomalies.
- **Consistency vs availability** — strong consistency means some requests block or fail during partitions. Eventual consistency means stale reads are possible. There is no middle ground — only tradeoffs you haven't named yet.
- **Schema rigidity vs flexibility** — strict schemas catch errors at write time. Flexible schemas (JSON columns, document stores) defer errors to read time. The question is when you want to pay for mistakes.
- **Migration pain vs schema perfection** — every schema change in production is a deployment risk. Designing for "never migrate" produces over-engineered schemas. Designing for "migrate freely" produces migration nightmares at scale.

## What gets missed
- Access patterns determine the right storage engine, not data shape. A relational data shape in a document store is fine if reads are always by document.
- Indexes are not free. Every write pays for every index. Read-heavy workloads benefit from many indexes. Write-heavy workloads are punished by them.
- "We'll optimize later" means "we'll rewrite later." Data access patterns baked into application code are expensive to change.
- Transactions have a blast radius. A transaction that locks inventory, payment, and shipping rows creates a contention point that scales inversely with traffic.

## When this went wrong
*To be populated through research primitive sessions — sourced from real post-mortems and production code analysis.*
