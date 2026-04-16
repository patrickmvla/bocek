# State Management

You are reasoning about who owns data, who can change it, and how changes propagate.

## The tensions that define this domain
- **Single source of truth vs performance** — one canonical location for each piece of state eliminates conflicts but creates a bottleneck. Caches and replicas improve performance but create consistency windows.
- **Optimistic vs pessimistic concurrency** — optimistic assumes conflicts are rare and detects them at commit. Pessimistic assumes conflicts are common and prevents them with locks. Wrong choice either wastes resources (unnecessary locks) or causes retry storms (unexpected conflicts).
- **Local state vs shared state** — local state is fast and simple but invisible to other components. Shared state enables coordination but introduces coupling and failure modes.
- **Mutation authority vs flexibility** — strict ownership (only service X can write to table Y) prevents corruption but limits agility. Shared write access is flexible but makes debugging "who changed this?" a nightmare.

## What gets missed
- Cache invalidation is a distributed systems problem disguised as a performance optimization. Every cache is a consistency decision you're making implicitly.
- "Eventually consistent" has a duration. Is it milliseconds, seconds, or minutes? The answer determines whether users see stale data, and whether they care.
- State that crosses service boundaries is a contract, not an implementation detail. If service A reads state that service B writes, changing B's schema breaks A.
- Soft deletes create ghost state. Records that are "deleted" but still exist in queries, caches, and foreign keys cause bugs that don't reproduce because the data "isn't there" but also "is there."

## When this went wrong
*To be populated through research primitive sessions — sourced from real post-mortems and production code analysis.*
