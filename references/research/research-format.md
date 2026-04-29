# Research Entry Format

When writing a research finding to the vault, use this structure. The format encodes what `/research` produces — every section corresponds to a step in *Operating at your ceiling*.

## Frontmatter

```yaml
---
type: research
features: [feature-name]
related: ["[[related-decisions]]", "[[related-research]]"]
created: YYYY-MM-DD
confidence: high | medium | low
provisional: false  # true if the finding is from a single channel
---
```

**type** — `research`
**provisional** — `true` if the finding does not meet the *Triangulation* gate (see below). Default `false`.
**confidence** — overall confidence the finding will hold; per-source confidence and provenance go in *Sources examined*.

## Body structure

```markdown
# [Research question as title — specific, not topical]

## Question
[What was investigated. Stated as a specific question, not a topic.
"How do production teams handle Stripe webhook signature verification, including
clock-skew edge cases?" — not "investigate Stripe webhooks."]

## Triangulation
[REQUIRED. Explicitly name the channels covered.]
- **Production reference:** ✓ / ✗ — [which named systems]
- **Docs reference:** ✓ / ✗ — [which official docs, version-pinned]
- **Contradiction probe:** ✓ / ✗ — [what disagreement was actively searched for; if none found,
  say so explicitly: "no credible disagreement found in the engineering blogs / GitHub
  discussions surveyed"]

If any channel is missing, set `provisional: true` in the frontmatter and name what
investigation would close the gap.

## Sources examined
[Each source carries: tier, full provenance, author context, date observed.]

### [Source 1 name]
- **Tier:** [1: production code | 2: official docs | 3: post-mortem | 4: engineering blog
  (named author) | 5: tutorial / advocacy | 6: forum | 7: training-data inference]
- **Provenance:** [URL+version for docs; repo+commit SHA+file:line for code; publication date
  + venue for blogs/talks/papers]
- **Author context:** [scale, role, date — "Stripe staff engineer per commit history; describes
  payments at Stripe scale, ~2024"]
- **What it tells us:** [the specific claim this source supports, in 1–2 sentences]

### [Source 2 name]
...

## Findings

### [Pattern / approach name]
[What was found. Reference the source by name; don't restate the source.
"Stripe SDK validates the `idempotency-key` server-side and returns the original response
for any subsequent request with the same key within 24 hours. Per Source 1 (`stripe-node`
SDK code) and Source 2 (`docs.stripe.com/api/idempotent_requests`)."]

### [Alternative pattern]
[Other approaches surfaced — research presents multiple, design chooses.]

## Conflicts
[REQUIRED when sources disagree. Name the disagreement; do NOT artificially resolve.
Apply *Contradiction protocol* (production code > docs > blogs > training-data)
to suggest precedence — but the contradiction itself is part of the finding.

"The 2017 Stripe blog post says idempotency keys are optional for safe operations;
current docs (2024-Q4) recommend them on ALL POST requests. Per *Contradiction protocol*,
current docs win — the blog post is outdated on this point."]

## Conditions
[REQUIRED. Every finding has boundaries — when does it apply, when does it break?
"Keys expire after 24h — retries beyond that window are treated as new requests.
Keys are per-API-key, not per-customer — shared API keys between services could collide."]

## Operational implications
[REQUIRED. The bridge to /design — what does this finding mean for our system?
Spell out the design implications, not just the technical fact.

"For our checkout: derive idempotency keys from `cart_id` + `attempt_number`, not random UUIDs,
so process restarts don't lose the key. Store the key in the cart record so retries after
crash use the same key. Bound retries to 24h to stay within Stripe's window."]

## Reproducibility note
[REQUIRED. Could another investigator with the same question reach substantially the same
finding? If yes, what tools/repos/queries did you use? If no, what judgment was load-bearing?

"Reproducible: clone `stripe/stripe-node`, read `lib/RequestSender.ts:45-89`, cross-reference
with `docs.stripe.com/api/idempotent_requests`. Search GitHub issues for 'idempotency-key'
in the same repo for known edge cases."

If a finding hinges on a judgment that wouldn't reproduce, label it explicitly and downgrade
confidence in the frontmatter.]

## Open threads
[What wasn't answered — signals for future research. Each thread is a future research
session's starting `Question`.

"What key format prevents collisions across retry attempts vs. genuinely new checkout
attempts for the same cart?"
"Should we test against Stripe's idempotency-key TTL by writing a synthetic key and
re-using after 24h?"]
```

## Tier reference

When labeling sources by tier, use the ladder from research.md *Operating at your ceiling*:

1. **Production code** — public repository of a named system, with provenance.
2. **Official docs** — canonical reference, version-pinned.
3. **Engineering post-mortem** — a system that did this and wrote up consequences.
4. **Engineering blog (named author, recent)** — useful for context but author-dependent.
5. **Tutorial / advocacy post** — weak; often a toy implementation generalized.
6. **Forum thread / Stack Overflow** — useful for "this exact error happens because" but not for design.
7. **Training-data inference** — labeled explicitly. Lowest tier. Hypothesis only, never citation.

A finding backed by tier 1+2 is vault-ready. Tier 4–5 alone is exploratory — set `provisional: true`.
