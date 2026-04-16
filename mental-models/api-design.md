# API Design

You are reasoning about how systems expose functionality to consumers.

## The tensions that define this domain
- **Consumer convenience vs implementation simplicity** — a consumer-friendly API hides complexity the server must absorb. A server-friendly API leaks complexity to every consumer.
- **Payload minimization vs round trips** — small payloads mean more requests. Large payloads mean wasted bandwidth and parsing. The network is never free.
- **Versioning stability vs evolution** — stable APIs build trust. But APIs that can't evolve accumulate debt. URL versioning is explicit but ugly. Header versioning is clean but invisible.
- **Error specificity vs security** — detailed errors help developers debug. Detailed errors help attackers probe. "Invalid credentials" is secure. "Password incorrect for user admin@company.com" is not.

## What gets missed
- N+1 at the API boundary is invisible in unit tests. A list endpoint that triggers a downstream call per item works fine with 10 items and collapses at 1000.
- Pagination is a day-one decision, not an optimization. Adding pagination to an existing endpoint that returns unbounded results is a breaking change.
- Error contracts are part of the API. If consumers can't programmatically distinguish "retry later" from "never retry," they'll retry everything or nothing.
- Idempotency keys are not optional for any mutation that touches money, inventory, or state a user cares about. "It's unlikely to be called twice" means "it will be called twice in production."

## When this went wrong
*To be populated through research primitive sessions — sourced from real post-mortems and production code analysis.*
