# CONTEXT.md Format

The shape of `.bocek/vault/CONTEXT.md` — the project-domain vocabulary artifact established by `[[context-md-as-vocabulary]]`. This format adapts `mattpocock/skills`'s `CONTEXT-FORMAT.md` with two bocek-specific refinements: YAML frontmatter consistent with the vault's other top-level artifacts, and optional `→ see [[wikilink]]` cross-references from terms to the vault entries that define them in depth.

## Frontmatter

```yaml
---
vault_version: 2
created: YYYY-MM-DD
---
```

Both fields are required. `vault_version` matches `index.md` (currently `2`). `created` is the date the file was first scaffolded (typically by `bocek bootstrap`).

## Body structure

```markdown
# {Project Name} — Domain Context

{One or two sentence description of what this project is and what its domain is.}

## Language

**{Term}:**
{One-sentence definition. What it IS, not what it does.}
→ see [[{feature}/{slug}]]  *(optional — wikilink to the vault entry that defines this term in depth)*
_Avoid_: {comma-separated aliases that mean the same thing — call them out so they don't drift into use}

**{Another Term}:**
{One-sentence definition.}
_Avoid_: {aliases}

## Relationships

- A **{Term A}** has zero or more **{Term B}**s
- A **{Term B}** belongs to exactly one **{Term C}**

## Example dialogue

> **Dev:** "When a **{Term A}** triggers a **{Term B}**, does the system also produce a **{Term C}**?"
> **Domain expert:** "No — only when the **{Term B}** is confirmed."

## Flagged ambiguities

- "{word}" was used to mean both **{Term A}** and **{Term B}** — resolved: these are distinct concepts.
```

## Rules

- **Be opinionated.** When multiple words exist for the same concept, pick the best one and list the others as aliases to avoid. Indecision in the vocabulary becomes drift in the code.
- **Flag conflicts explicitly.** If a term is used ambiguously, call it out in *Flagged ambiguities* with a clear resolution. Don't silently pick one and hope.
- **Keep definitions tight.** One sentence max. Define what the term IS, not what it does. The verbs go in the vault entry the term `→ see`s.
- **Show relationships.** Use bold term names. Express cardinality where obvious (one, zero-or-more, exactly-one). Cardinality is part of the contract; don't drop it.
- **Only include terms specific to this project's context.** General programming concepts (timeouts, error types, utility patterns, HTTP verbs) don't belong here even if the project uses them extensively. The test: would a senior engineer fluent in the stack but unfamiliar with this *project* know the term without being told? If yes, it's general — exclude. If no, it's domain — include.
- **Group terms under subheadings** when natural clusters emerge (e.g. `### Players`, `### Wallets`). If all terms belong to a single cohesive area, a flat list is fine.
- **Write an example dialogue.** A conversation between a dev and a domain expert demonstrating how the terms interact naturally and clarifying boundaries between related concepts. Two-to-four lines is usually enough.

## The `→ see [[wikilink]]` refinement

Bocek-specific. After a term definition, an optional line:

```markdown
→ see [[{feature}/{slug}]]
```

Points to the vault entry where the term is defined in depth — typically a decision, contract, or research entry. The wikilink is optional and resolves by filename per bocek's standard wikilink convention.

**When to add it:** the term has a vault entry that elaborates beyond the one-sentence CONTEXT.md definition. *Example:* `**Wallet:** balance-holding container for a player. → see [[wallet/wallet-functions-research]]`.

**When to skip it:** the term is so general or stable that no vault entry digs into it further. *Example:* `**Player:** a user account in the game.` — if "Player" isn't elaborated anywhere in the vault, no `→ see` line.

**Drift surface:** when a vault entry gets superseded or moved, its wikilink in CONTEXT.md goes stale. `/review` mode is expected to scan CONTEXT.md wikilinks against the actual vault entry set and flag drift as a review finding. Implementation owed in a future amendment to the review primitive.

## Single vs multi-context

**Single context (v1 default; all current bocek projects):** one `CONTEXT.md` at `.bocek/vault/CONTEXT.md`. No `CONTEXT-MAP.md`.

**Multiple contexts (deferred):** `[[context-md-as-vocabulary]]` explicitly defers the multi-context split (matt's `CONTEXT-MAP.md` pattern) until a real bocek-using project demonstrates the need. The revisit trigger: any vault has `>10` feature folders AND those folders form `>2` coherent semantic clusters that don't share vocabulary. At that point, a follow-up `/design` session adapts matt's multi-context pattern.

For v1, every bocek project is single-context. Period.

## Update discipline

`CONTEXT.md` is updated **inline during conversation** when terms resolve — not in batches at session end. Per `[[context-md-as-vocabulary]]`'s sub-decision 4:

- When a term emerges or is resolved during a `/design`, `/research`, or `/debugging` session, write it to `CONTEXT.md` immediately.
- Re-read `CONTEXT.md` before each write to preserve user edits made between turns.
- Refinement of an existing term is an in-place edit, not an append — the file is always its current best understanding, not a journal.

The rhythm matters: terms that wait for session-end get lost as the model drifts past the moment of resolution. Matt's `grill-with-docs/CONTEXT-FORMAT.md` makes the same point: *"create documentation lazily — only when you have something concrete to capture; capture resolved terms in CONTEXT.md as they emerge, not in batches."*

## Initialization

`bocek bootstrap` scaffolds `CONTEXT.md` alongside `_shared/project-shape.md` and `index.md`. The scaffolded file is empty or near-empty (a single comment explaining the file's purpose); users fill it as terms emerge.

## Path-convention exemption

`CONTEXT.md` is a top-level vault meta-artifact, not a feature-folder entry. It is exempt from `[[mandatory-feature-folders]]`'s "entries must live in `{feature}/{slug}.md`" rule, alongside `index.md`. The exemption set: `index.md`, `CONTEXT.md`, `.research/` subfolders.

## Reading discipline

Every primitive's *On activation* section reads `CONTEXT.md` after `index.md` and `state.md`. Eager-load, every session — non-missable. The preflight prints `CONTEXT.md`'s path as an eager reference; the primitive reads it before forming any response.

## Reference

- `[[context-md-as-vocabulary]]` — the bocek vault decision establishing this format.
- `[[mattpocock-skills-survey]]` — the research entry that surfaced the pattern (matt's F2, deepened in the 2026-05-14 deep-read pass).
- Matt's source: `github.com/mattpocock/skills/blob/main/skills/engineering/grill-with-docs/CONTEXT-FORMAT.md` (current as of 2026-05-14).
