# Vault Entry Format

When writing to the vault, use this structure. The path convention governs *where* entries live; the entry format governs *what* they contain. Read the path convention first — it's load-bearing for every other section below.

## Path convention

The vault is organized by feature, not flat. **Write entries into a feature-named subdirectory, never directly into `.bocek/vault/`.** A flat vault becomes unreadable past a handful of entries.

```
.bocek/
  vault/
    index.md                           ← top-level index, always at root
    CONTEXT.md                         ← project-domain vocabulary, top-level meta
                                          (see [[context-md-as-vocabulary]])
    {feature}/                         ← one folder per feature
      {slug}.md                        ← decisions, contracts, discoveries, gaps
      .research/                       ← research-type entries, hidden from default ls
                                          (see [[research-subfolder]])
        {topic}-research.md
    _shared/                           ← cross-cutting entries with no single primary feature
      {slug}.md
      .research/                       ← cross-feature research
        {topic}-research.md
```

**Top-level vault meta — exempt from the feature-folder rule:**
- `index.md` — entry map (auto-maintained per *Index update* below).
- `CONTEXT.md` — project-domain vocabulary (per `[[context-md-as-vocabulary]]`).

These two files sit at `.bocek/vault/` root. Every other markdown file lives in a feature folder or `_shared/`. Flat writes to `.bocek/vault/*.md` for anything other than `index.md` and `CONTEXT.md` are forbidden and code-enforced (per `[[mandatory-feature-folders]]`).

**Research-type entries take a `.research/` subfolder** inside their feature folder (or inside `_shared/`). The dot-prefix hides them from default `ls` and from preflight's "recent entries" listing while keeping them wikilink-resolvable, grep-able, and `find`-discoverable. Per `[[research-subfolder]]`.

**Picking the feature folder:**
- Use the primary feature from the entry's frontmatter `features:` list (the first item).
- If the entry genuinely spans multiple features and none is primary, write to `_shared/` (the underscore sorts it first in directory listings).
- Don't invent feature names — the feature folder name should match feature names already used elsewhere in the project (file paths, git history, vault entries, conversation, and — when the project has one — `CONTEXT.md` term entries).

**Picking the slug:**
- Kebab-case, descriptive, NO feature prefix (the folder already conveys the feature).
- For **decisions**: name what was chosen — `optimistic-locking.md`, `cart-expiry.md`.
- For **contracts**: `api-contract.md`, `webhook-contract.md`, or `{specific-thing}-contract.md` if there are multiple.
- For **research**: append `-research` and place under the `.research/` subfolder — `wallet/.research/stripe-idempotency-research.md`.
- For **reviews**: `review-YYYY-MM-DD.md`.
- For **discoveries**: `discovery-{what}.md`.
- For **gap reports**: `gaps.md` per feature (append to the existing file when re-flagging) or `gaps-YYYY-MM-DD.md` when sessions are distinct.

**Creating folders:**
- If the `{feature}/` directory doesn't exist, create it before writing the entry. The enforcement hook allows `mkdir` and any write under `.bocek/`.
- If the entry is research-type, also create the `.research/` subfolder.
- If you're the first entry for a feature, you create the folder. No ceremony needed.

## Frontmatter

```yaml
---
type: decision
features: [feature-name]
related: ["[[other-decision]]"]
created: YYYY-MM-DD
confidence: high | medium | low
---
```

**type** — `decision`, `research`, `contract`, `context`, `discovery`, or `exploration`
**features** — list of features this entry applies to
**related** — wikilinks to related vault entries (decisions cited, research consulted, contracts affected, idioms applied)
**created** — date the entry was written (YYYY-MM-DD)
**confidence** — overall confidence the decision will hold; per-claim confidence goes inline (see *Evidence labeling* below)

For `research` type entries, add `provisional: true` when the *Triangulation* gate (in `research/research-format.md`) is not yet met.

## Body structure for decisions

```markdown
# [Decision title — stated as what was chosen]

## Decision
[What was chosen, concrete enough to implement without clarification.
For system-shaped decisions, name: data flow, consistency model, failure semantics,
concurrency assumptions, observability hooks. Quote specific config / version /
flag values where relevant.]

## Reasoning
[Why this option won — the human's defense that survived challenge. Each non-trivial
claim labeled inline per *Evidence labeling* below. Cite vault entries with [[wikilinks]]
and idiom files with backticks: `idioms/typescript.md (branded types)`.]

## Engineering substance applied
[REQUIRED when the decision is system-shaped. Name the principles in play and how the
chosen path handles each.]
- **Consistency:** [e.g. "SERIALIZABLE on writes per ACID-I; eventual reads via replica
  with explicit `read_after_write` flag for sessions that need it"]
- **Failure semantics:** [e.g. "at-least-once with idempotency key per [[stripe-idempotency-research]];
  retries are safe because the key is cart-derived, not random"]
- **Concurrency:** [e.g. "optimistic lock with version column; bounded retry (max 3) +
  circuit breaker at 50% conflict rate"]
- **Observability:** [e.g. "page on conflict-rate > 10% over 5min; runbook entry: [[runbook-inventory-conflict]]"]
- **Other principles touched** — only those that actually apply.

## Production-grade gates
[REQUIRED. Explicit on each gate per *Production-grade default* in design.md.]
- **Idiomatic** — [why this is idiomatic to *this* stack/version/year, with evidence:
  e.g. "Standard pattern in Postgres-backed services using Drizzle; matches the
  `idioms/typescript.md` discriminated-union recommendation for the response type"]
- **Industry-standard** — [≥2 named production systems doing this with provenance:
  e.g. "Shopify (engineering blog 2022, post-mortem on flash sales) and GitHub
  (public source `github/github` per their 2021 conf talk)"]
- **First-class** — [why this uses platform abstractions rather than fighting them:
  e.g. "Postgres native row-version, not a custom mutex table; standard SQL UPDATE
  ... WHERE version = ?"]

## Rejected alternatives
[≥1, but two or more is the norm — the consensus default, the contrarian, and the
constraint-winner per *Position derivation* step 1. For each: what it is, the conditions
under which it would win, why those conditions don't hold here.]

### [Alternative A — name]
**What:** [the option, concretely]
**Wins when:** [the constraint regime under which this would be the right choice]
**Why not here:** [why this project's constraints don't match]

### [Alternative B — name]
**What:** ...
**Wins when:** ...
**Why not here:** ...

## Failure mode
[How the chosen approach breaks and under what conditions. Specific:
"At sustained 1k qps with N>3 replicas, the version-read race window is ~50µs;
expect ~20 conflicts/min." Not "could have concurrency issues."]

## Mitigations
[REQUIRED when failure modes are non-trivial. What the team will do when the failure
manifests — runbook, circuit breaker, retry policy, alert threshold.]

## Idiom citations
[REQUIRED if any idiom file informed the decision. Name the file and the principle:
"`idioms/typescript.md` (branded types) — Email type validates at the boundary;
downstream code trusts the type."]

## Revisit when
[Specific conditions that should trigger reopening this decision.
Quantitative when possible: "write contention exceeds 50 concurrent writers per product"
beats "if performance becomes an issue."]
```

## Evidence labeling (inline, throughout reasoning)

Every non-trivial claim in *Reasoning* and *Engineering substance applied* carries an
evidence class and (when not high) a confidence note. Labels go in parens after the claim:

> Optimistic locking is the standard pattern for low-contention, high-latency-external-call
> workloads (production-cited: Shopify engineering blog 2022; docs-cited: Postgres docs
> on row versioning §13.3). Confidence: high.

> The retry-storm threshold of 50% is a heuristic — we have no production data at this scale
> (inferred; confidence: medium — verify in load test before relying on it).

Evidence classes (strongest to weakest):
- **production-cited** — named system known to do this, with provenance
- **docs-cited** — current official docs, version-pinned
- **tutorial-blog** — single non-authoritative source
- **inferred** — training-data pattern, no specific source

Untagged claims are assumed *production-cited / high* — only deviate when truthful. Bluffing
*production-cited* on an inference is mode-collapse; the human should be able to trust the labels.

## Index update

After writing the vault entry, add a line to `.bocek/vault/index.md`:

```markdown
- [[entry-name]] — type: decision — one-line summary
```

Group entries by feature. Create the feature heading if it doesn't exist.

## State checkpoint

After writing the vault entry, update `.bocek/state.md`:

```markdown
## Current state
- Feature: [active feature]
- Last resolved: [[entry-name]]
- In progress: [what's being explored]
- Next: [next question to address]
```

Overwrite on every checkpoint — state.md is current state, not history. A *Session history* section is allowed as a brief log; keep it short.

## Index initialization

If `.bocek/vault/index.md` doesn't exist, create it:

```yaml
---
vault_version: 2
---
```

Then add the entry line below.

For the `CONTEXT.md` format, see `references/shared/context-format.md`.
