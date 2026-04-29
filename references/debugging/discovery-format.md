# Discovery Format

When debugging reveals something new about the system — an unknown constraint, a failure mode, an incorrect assumption — write it to the vault as a `discovery`. The format encodes what `/debugging` produces when investigation surfaces undocumented engineering substance.

## Frontmatter

```yaml
---
type: discovery
features: [affected-feature]
related: ["[[decisions-this-affects]]"]
created: YYYY-MM-DD
confidence: high
---
```

## Body

```markdown
# Discovery: [what was learned, stated as a claim]

## Found during
[Brief description of the debugging session — what error, what investigation,
what reproduction steps. Cite the failing test or the trace by name.]

## Failure lenses that surfaced this
[REQUIRED. Per *Failure lenses* in debugging.md — name the lens that exposed the issue.
Not every lens applies; name the ones that did.]
- **Input shape** — [what input shape exposed it; or N/A]
- **Side effects in flight** — [what was committed / rolled back / partial; or N/A]
- **Concurrency state** — [what other work was happening; or N/A]
- **System load** — [steady-state vs. spike; recent changes; or N/A]
- **Timing window** — [deterministic vs. flaky; window size; or N/A]
- **Data state** — [what data shape at the moment of failure; or N/A]

## Discovery
[What was learned that wasn't known before. Be specific — not "there's a race condition"
but "the version-read happens outside the write transaction, opening a ~50µs window where
two checkouts can both see version=N before either writes."]

## Root cause classification
[REQUIRED. One of:]
- **Implementation bug** — code doesn't match vault spec. Fix in `/implementation` or here.
- **Design gap** — vault doesn't cover this scenario. Hand to `/design`. Don't redesign in debugging.
- **Incorrect assumption** — a vault decision was based on an assumption that doesn't hold.
  Hand to `/design` to supersede or update the entry.

## Engineering substance touched
[REQUIRED when the discovery touches one of design's principle dimensions. Name what's at stake.]
- **Consistency:** [e.g. "phantom read in our SERIALIZABLE-claimed code path"]
- **Failure semantics:** [e.g. "at-most-once was assumed; observed at-least-once because the
  retry on network timeout doesn't carry the idempotency key"]
- **Concurrency:** [e.g. "race window between version read and update is wider than assumed"]
- **Other** — only those that actually apply.

## Impact on existing decisions
[REQUIRED. Which vault entries does this affect? Does it invalidate an assumption?
Add a constraint that wasn't considered? Quote the affected entry and name the change.

"Invalidates the assumption in [[optimistic-locking]] that conflict rate stays below
~10%. Under flash-sale load, observed rate reaches 60%+, which the bounded-retry mitigation
(max 3) wasn't designed for. The retry storm itself becomes the load problem."]

## Evidence
[REQUIRED. The specific error, log output, code trace, or test output that proves this
discovery. Quote, don't paraphrase. Include file:line references.

```
[stack trace or log output, exact]
```

`src/checkout.ts:142` — read happens here
`src/checkout.ts:178` — write happens here
Window: ~50µs at p50, ~200µs at p99 under load test
]

## Reproduction
[REQUIRED if the discovery is a failure mode. How to reproduce it deterministically (or
flakily, with the rate). Other engineers — and other modes — need to be able to verify.

"Run `pnpm test:integration -- --grep checkout-race`. Failure rate ~1/30 runs without load;
~1/3 runs with `--concurrent 50`."]
```

## What qualifies as a discovery

- A failure mode that wasn't anticipated during design.
- An assumption that proved false under production conditions.
- A constraint imposed by a dependency that wasn't documented.
- A race condition or timing issue that only manifests under specific load.
- An interaction effect between two features that wasn't predicted.
- A divergence between docs and implementation that bit us in production.

## What does NOT qualify

- A typo fix — that's just a bug.
- A known limitation being encountered — the vault already covers it; reference the entry.
- A performance observation without production evidence — that's speculation.
- A theoretical concern not backed by a trace — debugging is evidence-grounded.
