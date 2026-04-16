# Mental Models: Design

## Context
Mental models are domain-specific reasoning activators that load into any primitive when the conversation enters a specific domain. They are one of the three rarest capabilities in the AI coding ecosystem — only BMAD and Superpowers attempt them, and both implement them as checklists or step-by-step frameworks rather than genuine reasoning activators.

The research (MeMo paper, vocabulary research, multi-dimensional reasoning) shows that the mechanism for activating domain-specific reasoning is naming the domain and presenting its key tensions — not prescribing a thinking process. Naming a domain activates relevant pre-trained knowledge. Presenting tensions creates productive dissonance. Hard-won insights shift the probability distribution toward knowledge the model has but won't surface by default.

## Goals
- Activate the model's latent domain knowledge for the specific problem at hand
- Present domain tensions that create productive dissonance — force the model to reason about tradeoffs
- Surface hard-won engineering insights that have low default probability in the model's output
- Work across all six primitives — the same activator produces different reasoning in design vs implementation vs debugging
- Grow organically as new domains become relevant

## Non-Goals
- Not a teaching tool — doesn't explain fundamentals of a domain
- Not a checklist — doesn't list things to consider
- Not a reasoning script — doesn't tell the model how to think step by step
- Not comprehensive — covers the tensions that matter most, not every aspect of a domain
- Not static — "when this went wrong" examples are sourced from research primitive sessions and evolve with the project

## Design

### File structure

Each mental model lives at `~/.bocek/primitives/references/mental-models/{domain}.md`.

Structure:

```markdown
# {Domain Name}

You are reasoning about {one sentence — what this domain covers}.

## The tensions that define this domain
- {Tension A vs Tension B} — {one line explaining the tradeoff}
- {Tension C vs Tension D} — {one line}
- {Tension E vs Tension F} — {one line}
- {Tension G vs Tension H} — {one line}

## What gets missed
- {Hard-won insight that shifts attention to what actually matters}
- {Another insight — something the training data has but won't surface by default}
- {Another — the kind of thing a senior engineer says after being burned}
- {Another}

## When this went wrong
{2-3 concrete examples from real engineering. Sourced during research
primitive sessions from post-mortems, engineering blogs, or production
code analysis. Not fabricated. Each example shows a decision that seemed
reasonable but failed, and WHY it failed — the tension it ignored.}
```

### What makes this different from a checklist

A checklist says: "consider caching, rate limiting, error handling, logging."

A mental model says: "normalization vs query performance — clean schema vs fast reads." The model already knows about normalization. The mental model activates that knowledge by naming the tension. The model then reasons about which side of the tension applies to THIS project based on THIS project's constraints in the vault.

The checklist produces the same output for every project. The mental model produces different questions for every project because the reasoning is the model's, not the file's.

### How primitives load mental models

The primitive's reference table includes:

```
| Need an engineering mental model | references/mental-models/{domain}.md |
```

The model identifies the relevant domain from the conversation context and loads the appropriate mental model. Multiple mental models can be loaded in one session if the problem spans domains (e.g., a checkout system needs data-layer and API-design activators).

The model selects which mental model to load — this aligns with the MeMo research showing LLMs make effective context-dependent selections when given the concept of mental models + examples.

### V1 library

Six mental models for the initial release, covering the domains that matter for most software projects:

1. **data-layer.md** — access patterns, consistency vs availability, normalization vs query performance, schema flexibility vs integrity, migration pain
2. **api-design.md** — consumer-first design, payload minimization, versioning strategies, error contracts, N+1 traps at the API boundary
3. **state-management.md** — ownership, mutation authority, concurrent writes, source of truth conflicts, cache coherence
4. **distributed-systems.md** — partition tolerance, retry strategies, idempotency, eventual consistency traps, failure domain isolation
5. **frontend.md** — server/client boundary, serialization costs, bundle impact, hydration, interaction latency budgets
6. **auth.md** — trust boundaries, session lifecycle, token expiry mid-operation, credential blast radius, permission model granularity

### V2 candidates (added based on user need)

- **concurrency.md** — race conditions, lock strategies, deadlock detection, backpressure
- **observability.md** — what to log vs metric vs trace, alert fatigue, cardinality explosion
- **testing.md** — test boundary decisions, mock vs integration, test as documentation
- **infrastructure.md** — deployment coupling, environment parity, secret management
- **data-pipeline.md** — backpressure, exactly-once semantics, schema evolution, replay capability

### "When this went wrong" sourcing

The examples in each mental model are NOT written from the model's training data during initial creation. They are sourced through the research primitive:

1. Research primitive finds post-mortems, engineering blogs, and production code that demonstrate the domain's tensions failing
2. Research findings are written to the vault
3. The mental model's "when this went wrong" section references or adapts these findings
4. As more research accumulates, the examples improve

This means v1 mental models may ship with placeholder examples that are refined as users run research sessions. The structure and tensions are the high-value content; the examples are enrichment that improves over time.

## Trade-offs

**Activation vs instruction:** Mental models activate without constraining. The tradeoff is less predictability — you can't guarantee the model will ask a specific question about database design. But the research shows this produces better reasoning than prescribed steps. The model's autonomous selection outperforms human-prescribed selection (MeMo results).

**Domain breadth vs depth:** Six mental models cover common software domains but miss specialized ones (game dev, embedded systems, ML pipelines). The library grows over time, but v1 users in niche domains won't have activators. Mitigation: the model's training data still has domain knowledge — the mental model just boosts it. Without a mental model, the model still functions, just without the probability shift.

**Example quality:** "When this went wrong" examples sourced from real engineering are more powerful than fabricated ones, but they require research primitive sessions to populate. V1 may ship with thinner examples that improve over time.

## References
- ADR-0016: Mental models as domain activators
- MeMo paper: https://arxiv.org/abs/2402.18252
- Vocabulary research: https://arxiv.org/abs/2505.17037
- Microsoft Amplifier zen-architect analysis (generic framework limitation)
- Vercel agent-skills (domain-specific rule files as precedent for domain-scoped references)
