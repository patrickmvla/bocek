---
type: decision
features: [_shared]
related: ["[[mattpocock-skills-survey]]", "[[mandatory-feature-folders]]", "[[research-subfolder]]", "[[vault-scale-audit-bokchoy]]"]
created: 2026-05-14
confidence: high
---

# Adopt `CONTEXT.md` as a top-level vault artifact for project-domain vocabulary

## Decision

Bocek adopts a project-domain vocabulary artifact, `CONTEXT.md`, at `.bocek/vault/CONTEXT.md` — peer of `index.md`, top-level vault meta. Every bocek-using project has one. Its content is the domain language the project uses: terms that have specific meaning *to this project* (not general programming concepts), each defined opinionatedly with a short definition, an `_Avoid_:` aliases line, and an optional `→ see [[wikilink]]` to the vault entry that defines the term in depth. The full body shape adopts `mattpocock/skills`'s `CONTEXT-FORMAT.md` (Language section + Relationships section + Example dialogue + Flagged ambiguities) with two bocek-specific refinements: YAML frontmatter consistent with `index.md` and `[[wikilink]]` cross-references.

### Body shape

```markdown
---
vault_version: 2
created: YYYY-MM-DD
---

# {Project Name} — Domain Context

## Language

**Wallet:**
A balance-holding container for a player; one wallet per (player, currency) pair.
→ see [[wallet/wallet-functions-research]]
_Avoid_: account, balance object

**Currency:**
A customer-defined unit of in-game value (gems, coins). Identified by `code`, scoped per project.
→ see [[wallet/credit-route-contract]]
_Avoid_: token (overloaded with auth tokens)

## Relationships

- A **Player** has zero or more **Wallets**
- A **Wallet** holds one **Currency**
- A **Currency** belongs to exactly one **Project**

## Example dialogue

> **Dev:** "When we credit a **Wallet**, do we create the **Player** if missing?"
> **Domain expert:** "Yes — lazy-create per [[wallet/credit-route-contract]], idempotent on the `external_id`."

## Flagged ambiguities

- "credit" was used to mean both "add balance" and "issue gems to a new player" — resolved: the verb is *credit*; the lazy-create is a side effect, not the operation.
```

### Operational layer

- **Location.** `.bocek/vault/CONTEXT.md` — sibling of `index.md`. Top-level vault meta, not a feature folder entry.
- **Reading.** Every primitive's `On activation` reads `CONTEXT.md` after `index.md` and `state.md`. Eager-load, non-missable.
- **Updates.** Inline during conversation when terms resolve. Re-read `CONTEXT.md` before each write to preserve user edits (per matt's `grill-with-docs/CONTEXT-FORMAT.md` discipline).
- **Initialization.** `bocek bootstrap` scaffolds an empty `CONTEXT.md` alongside `_shared/project-shape.md`. Stub content names the file's purpose; users fill it as terms emerge.
- **Multi-context.** Single-context only for v1. `CONTEXT-MAP.md` (matt's pattern for multi-context repos) is explicitly deferred until a real multi-context bocek user appears.
- **Path-convention status.** Path-convention layout in `references/shared/vault-format.md` lists `CONTEXT.md` alongside `index.md` as a top-level vault meta-file — exempt from the "entries must live in a feature folder" rule of `[[mandatory-feature-folders]]`. The exemption set is now: `index.md`, `CONTEXT.md`, `.compiled/` (deprecated per `[[compile-removal]]`), `.research/` subfolders (per `[[research-subfolder]]`).

### Explicitly deferred

**Sub-decision 7 (enforcement)** — whether feature-folder names must match `CONTEXT.md` term entries — is deferred to a follow-up `/design` session. This decision establishes `CONTEXT.md` as an artifact; whether the artifact is *load-bearing on folder creation* is a separate decision with its own derivation complexity.

## Reasoning

Two independent evidence channels converge on adopting this artifact:

1. **`mattpocock/skills` has shipped vocabulary-extraction twice** — once as the deprecated `ubiquitous-language` skill (DDD-style CLI), and once as the current `grill-with-docs/CONTEXT-FORMAT.md`. Two iterations of the same pattern by the same author across a multi-year span is the kind of evidence the bocek production-grade gate exists to surface (production-cited; high, per `[[mattpocock-skills-survey]]` finding F2 and the deep-read pass).

2. **Bokchoy's `architecture/`-as-junk-drawer failure mode is empirical evidence of the gap.** Per `[[vault-scale-audit-bokchoy]]` F3, bokchoy's `architecture/` folder holds 39 entries spanning unrelated subjects (`backend-stack`, `drizzle-orm`, `tanstack-query`, `multi-tenant-rls`, `idempotency-strategy`, `loot-rng`, `pity-engine`, `wallet-source-of-truth`, …). The drift happened because feature-folder names were never constrained by an authoritative vocabulary. `CONTEXT.md` is the missing constraint layer — a defined `**Wallet:**` term means a `wallet/` folder; a missing `**Architecture:**` term means `architecture/` shouldn't have been created in the first place. The enforcement of that link is sub-decision 7, deferred — but the artifact required for enforcement is this decision (production-cited within bocek; high).

The path choice (`.bocek/vault/CONTEXT.md` over matt's repo-root pattern) is defended by the existing preflight infrastructure: the preflight pipeline reads from `.bocek/vault/` on every primitive activation; co-locating `CONTEXT.md` with `index.md` means the eager-load mechanism applies without modification, making the artifact structurally non-missable. The user's defense: *"needs to be read on every session activation makes [it] non missable"* — captured here as the load-bearing reason.

The format choice (matt's wholesale + bocek refinements) is defended by the user as *"getting matt's production approach combining [it with] our setup"* — synthesis of strongest evidence base with existing project infrastructure. Frontmatter consistency with `index.md` plus `[[wikilink]]` cross-references gives bocek-using projects a navigability win matt's wikilink-less version doesn't have (inferred; medium — bocek-specific value not yet measured).

## Engineering substance applied

- **Operability:** `CONTEXT.md` lives in the same eager-load pipeline as `index.md` and `state.md`. No new loading mechanism; the preflight extension is one file path added to the list. Single point of doctrine.
- **Discoverability:** the artifact is at the most obvious path a reader would look for it — `.bocek/vault/CONTEXT.md`, peer of `index.md`. No nested location to learn about. `ls .bocek/vault/` shows it.
- **Drift reduction:** vocabulary inline-updated as it resolves matches the rhythm at which terms actually emerge in design/research sessions. Matt's evidence: batch-at-end loses terms because the model drifts past the moment of resolution.
- **Cross-reference graph:** `[[wikilink]]` from a term to its in-depth vault entry creates a navigable map. `**Wallet:** ... → see [[wallet/wallet-functions-research]]` lets a reader move from vocabulary to engineering substance in one click. Bocek's existing wikilink machinery handles this without new infrastructure.

## Production-grade gates

- **Idiomatic** — matt's `CONTEXT-FORMAT.md` is the production-cited pattern; bocek's frontmatter convention matches what `index.md` and every vault entry already uses. Both halves of the format are stack-idiomatic to bocek (production-cited; high).
- **Industry-standard** — vocabulary-as-artifact has multiple precedents at this layer: Eric Evans' *Domain-Driven Design* (2003) names ubiquitous language as a core practice; matt's repo at 81k stars is one production-cited adoption; Obsidian power users converge on *Glossary* or *Index* note patterns at scale. Cited as production-cited within methodology space; high.
- **First-class** — uses existing vault infrastructure (path layout, preflight pipeline, wikilink resolution) rather than fighting the platform. No new file class, no new index, no new resolver.

## Rejected alternatives

### (1) `.bocek/CONTEXT.md` (sibling of `mode`, `state.md`, `vault/`)

**What:** Place `CONTEXT.md` at the top of `.bocek/` itself, outside `vault/`. Treats it as a top-level methodology artifact like `mode`.

**Wins when:** the team conceptually separates "methodology artifacts" (mode, state, config) from "vault content" (decisions, research, contracts, vocabulary).

**Why not here:** `CONTEXT.md` is content the user writes during reasoning sessions — it's vault-shaped, not config-shaped. Co-locating it with `mode` and `state.md` would imply it's machine-managed, when in practice it's human-authored and evolves like decisions evolve. The vault is the right neighborhood.

### (1-alt) Repo-root `CONTEXT.md` (matt's literal pattern)

**What:** Place `CONTEXT.md` at the repository root, outside `.bocek/`. Matt's exact pattern.

**Wins when:** the methodology artifact is intended to be visible to readers who never look inside `.bocek/` — onboarding contributors, external readers of the repo's documentation tree.

**Why not here:** bocek's design philosophy is that everything methodology-related lives under `.bocek/` so the project's actual source tree stays clean. Externalizing `CONTEXT.md` to the repo root would carve out an exception specifically for the vocabulary artifact, which is a worse rule (one-file-exempt) than the consistent rule (all bocek artifacts under `.bocek/`).

### (3) `.bocek/vault/_shared/context.md` (regular vault-entry shape)

**What:** Treat `CONTEXT.md` as just another `_shared/` vault entry, subject to the path-convention rule and all vault-entry lifecycle.

**Wins when:** vocabulary is conceptually "just another decision" — one of many entries in `_shared/`.

**Why not here:** vocabulary is *meta* to the vault's decisions in a way that single decisions aren't. `index.md` is already exempt from the "entries must live in a feature folder" rule because it's the entry-map; `CONTEXT.md` is the term-map. Both are top-level vault meta. Demoting `CONTEXT.md` to a regular entry would mean it shows up in `.research/`-listing, gets subjected to the `_shared/` misclassification gate, and competes with content entries for attention in `ls _shared/`.

## Failure mode

**Empty-`CONTEXT.md`-as-noise.** Projects bootstrapped via `bocek bootstrap` get a scaffolded `CONTEXT.md` file from day 1. If the project never accumulates domain vocabulary worth writing down — small projects, single-feature scope, prototype-only work — the file sits empty or near-empty forever, and the eager-load that reads it on every primitive activation costs tokens for zero benefit.

**Quantitative signal:** `CONTEXT.md` smaller than ~30 lines after 5+ design sessions probably indicates the project doesn't need it. At that point either the project is too small to benefit, or the model isn't actually capturing terms as they emerge (a different failure mode — sub-decision 7 enforcement would catch this).

A secondary failure mode: **drift between `CONTEXT.md` wikilink targets and superseded vault entries.** When a research entry gets superseded, its `[[wikilink]]` in `CONTEXT.md` becomes stale. The drift is detectable via `/review` mode but not auto-corrected.

## Mitigations

1. **Eager-load can be conditional on file size.** A future preflight refinement: if `CONTEXT.md` is shorter than N lines AND the session has not modified it in the last K sessions, skip the eager-load. (Not in v1; queued as a polish opportunity if the empty-noise failure mode manifests.)
2. **`/review` mode's vault-compliance pass scans `CONTEXT.md` wikilinks** against the vault's actual entry set. Drift between term wikilinks and superseded entries gets flagged as a review finding. (Implementation owed in a future amendment to the review primitive.)
3. **`bocek bootstrap` scaffolds with one example term** (commented out or labeled `# Example — replace with real domain terms`) so the file is never literally empty on day 1 and the user has a template to follow.
4. **`/review` mode also flags terms in `CONTEXT.md` that have no corresponding `[[wikilink]]`** AFTER they've been present for N sessions — signal that the term resolved but the depth-decision was never written.

## Idiom citations

None — structural decision, not stack-specific.

## Revisit when

- A multi-context bocek-using project appears. Specific signal: any vault has `>10` feature folders AND those folders form `>2` coherent semantic clusters that don't share vocabulary. At that point, defer-of-`CONTEXT-MAP.md` becomes implementation-owed and a follow-up `/design` session adapts matt's multi-context pattern.
- `/review` flags consistent drift between `CONTEXT.md` terms and vault entry wikilinks (e.g., >5 stale wikilinks per review). At that point, the inline-update discipline is failing; revisit either the discipline or add tooling to catch drift earlier.
- Bocek widens scope beyond Claude Code / Anthropic API. Cross-reference: `[[compile-removal]]`'s revisit clause. If the model-layer's session-start behavior changes such that eager-loading is no longer free, the cost of every-session `CONTEXT.md` reading rebalances.
- An empty-`CONTEXT.md`-as-noise pattern manifests across multiple bocek projects (>2 projects with `CONTEXT.md` <30 lines after 5+ sessions). At that point, the eager-load default is wrong; revisit either the conditional-load mitigation (#1 above) or the value of `CONTEXT.md` for small projects.
