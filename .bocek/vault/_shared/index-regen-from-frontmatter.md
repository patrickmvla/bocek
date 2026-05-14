---
type: decision
features: [_shared]
related: ["[[vault-scale-audit-bokchoy]]", "[[mandatory-feature-folders]]"]
created: 2026-05-14
confidence: high
---

# `bocek vault index --rebuild` regenerates `index.md` from entry frontmatter and H1 headings

## Decision

Add a `bocek vault index --rebuild` subcommand to `scripts/bocek`. The command walks every vault entry under `.bocek/vault/{feature,_shared}/` (including `.research/` subfolders), extracts a one-line summary from each, and rewrites `.bocek/vault/index.md` with the spec format: `- [[entry-name]] — type: T — one-line summary`. Hand-edits to index.md are clobbered by the next rebuild — the script is the single source of truth for index.md content.

### Source of truth for the one-line summary

Per-entry resolution order:
1. **`description:` frontmatter field** if present (matt's pattern: "the description is the only thing your agent sees" — concise by design).
2. **First `# H1` heading** (excluding any leading `#` and frontmatter), truncated to 200 characters with `...` if longer.
3. **Slug-as-title-case fallback** (e.g. `compile-removal.md` → "Compile removal").
4. **Warn but don't fail** when fallback hits — the rebuild proceeds; the user gets stderr output naming the entries missing description metadata.

Frontmatter `description:` is **not yet required** by `references/shared/vault-format.md`. Adding it as a recommended (or required) field is a separate follow-up decision (call it polish #4-followup); not folded into this entry.

### Output shape

```markdown
---
vault_version: 2
---

# {Project Name} Vault Index

## {feature}

- [[entry-name]] — type: decision — one-line summary
- [[other-entry]] — type: research — one-line summary

## _shared

- [[shared-entry]] — type: decision — one-line summary
```

Entries grouped by feature folder; `_shared/` placed last (or first per the existing underscore-sort convention — pick consistent: **first**, per matt's pattern of meta-content-first). `.research/` subfolder entries inline with parent feature's group, not separated (matches the wikilink-resolves-by-filename property — readers find them either way).

Project name extracted from `.bocek/vault/CONTEXT.md`'s H1 heading if present; falls back to `"Vault Index"`.

### When `--rebuild` is invoked

- **Manually for v1.** User runs `bocek vault index --rebuild` after any session that adds entries. No auto-invocation.
- **Future enhancement (deferred):** preflight could detect index drift (`index.md` last-modified before the most recent vault entry's last-modified) and emit a warning suggesting `--rebuild`. Not in this decision's scope.
- **Future enhancement (deferred):** the enforce-mode.sh hook could auto-trigger `--rebuild` on every vault write. Has concurrency and recursion risks; not in this decision's scope.

## Reasoning

`[[vault-scale-audit-bokchoy]]` F5 is the production-cited evidence: bokchoy's `index.md` reached 113 lines for 89 entries with paragraph-length summary lines (500+ chars each), violating the spec's *"one-line summary"* rule. Hand-edited index entries drift because the model writes verbose descriptions when adding entries inline; the spec rule is correct but unenforced (the doctrine-without-enforcement pattern this project keeps re-deriving — fifth observation in this session). Auto-regen forces the spec structurally.

The source-of-truth resolution order (description → H1 → slug) handles the transition state: existing vault entries don't have `description:` in frontmatter, but they DO have descriptive H1 headings. The script works on the current vault without requiring a one-time bulk-frontmatter-update.

Matt's pattern (from `[[mattpocock-skills-survey]]` deep-read F12) is that `description:` is the agent-visible summary — purpose-built for terse one-liners. Adopting `description:` as the preferred source aligns bocek with matt's pattern; the H1 fallback handles current entries without forcing premature migration.

## Engineering substance applied

- **Operability:** single script, single source of truth, predictable output. No coordination between session-end index-edit and the script's regeneration; the script wins.
- **Discoverability:** the index.md output uses the existing spec format. Readers don't have to learn a new file.
- **Failure semantics:** rebuild is idempotent. Running it twice in a row produces identical output. Hand-edits are clobbered (intentional, not silent loss — the spec rule is the contract).
- **Concurrency:** the rebuild reads the vault filesystem, writes index.md atomically. Concurrent writes to vault entries during a rebuild produce a snapshot consistent with the read point; subsequent rebuild picks up any missed entries.

## Production-grade gates

- **Idiomatic** — directory-snapshot-to-index-file is the standard pattern for vault/notebook tools (Obsidian's index plugins, Logseq's automatic graph maintenance, Hugo's site index generation). Production-cited.
- **Industry-standard** — Hugo (`hugo build` walks content dir, generates index pages — public source, named system). Sphinx (`make html` regenerates table of contents from RST/Markdown frontmatter — public source). Two independent production examples; high confidence in the pattern at this layer.
- **First-class** — uses `scripts/bocek` as the existing subcommand router. No new tool, no new file type, no new discovery mechanism.

## Rejected alternatives

### (a) Hook-driven auto-regen

**What:** Every vault write triggers `index --rebuild` via the enforce-mode.sh hook (post-write).

**Wins when:** index drift must be impossible — the model can never see a stale index.md.

**Why not here:** concurrency complexity (multiple vault writes per session race on index.md); recursion risk (the hook writes index.md, which is also a vault file — needs careful gating); cost overhead (every write pays the cost of a full vault walk). The manual `--rebuild` is sufficient for the failure mode being addressed; auto-trigger is over-engineering for v1.

### (b) Review-time flagging only

**What:** `/review` mode reads index.md and flags entries whose summaries exceed N characters; no auto-rebuild.

**Wins when:** the team self-disciplines around summary length; review catches drift periodically.

**Why not here:** **dominated.** Fifth observation of the doctrine-without-enforcement pattern in this session. Self-discipline plus periodic review has failed every time it's been tried (path conventions, `_shared/` discipline, lazy-compile, SIGPIPE preflight, CONTEXT.md folder-name enforcement).

### (c) Manual maintenance — keep status quo

**What:** Don't add a rebuild script. Trust that users will hand-edit index.md to the spec format.

**Wins when:** vault stays small enough that the failure mode never manifests.

**Why not here:** bokchoy's evidence is N=1 production observation that the manual approach fails at scale (89 entries, paragraph-length summaries). The script is small; the cost-benefit obviously favors automation.

## Failure mode

**Hand-edits to index.md that the user wants preserved are clobbered.** A user manually adds an annotation to the index (e.g. a comment, a TODO note, a grouping decision the script doesn't infer); the next `--rebuild` removes it. Predictable but possibly surprising.

A secondary failure: **the resolution-order fallback warning might be noisy.** If 80% of existing entries lack `description:` frontmatter (bocek's own vault is currently 100% in this state), every rebuild produces a long warning list. The user might learn to ignore the warnings, defeating their purpose.

## Mitigations

1. **The rebuild script outputs a count, not a list, when warnings exceed a threshold.** *"15 entries missing `description:` frontmatter — falling back to H1 headings. Run `bocek vault index --check` for the full list."* Avoids alarm fatigue.
2. **Manual annotations go elsewhere:** if a user wants to capture an index-level note (grouping decision, deprecation flag), they edit the vault entry itself (frontmatter or body), not the index. The script regenerates the surface from the data.
3. **`bocek vault index --check`** dry-run flag prints what the rebuild would do without writing. Lets the user preview changes before clobbering hand-edits.

## Idiom citations

None — script + filesystem pattern, not stack-specific.

## Revisit when

- More than 30% of vault entries adopt `description:` frontmatter sustained over 5+ sessions. At that point, `description:` is empirically the preferred source; consider making it required via vault-format.md amendment.
- A user reports the hand-edit-clobber failure mode in practice. At that point, design an explicit "annotations" layer (separate file? annotated frontmatter field?) that the rebuild preserves.
- The vault grows past ~200 entries. At that point, a flat index.md becomes navigationally unworkable even at one-line-per-entry; consider per-feature index files or a tree-shaped index.
- Auto-trigger from the hook becomes valuable (e.g. multi-user vaults where stale index causes coordination friction). Currently no such use case named.

## Implementation items queued

- **#4-1:** Add `cmd_vault_index_rebuild` function to `scripts/bocek`. Walks `.bocek/vault/{feature,_shared}/**/*.md` and `.bocek/vault/{feature,_shared}/.research/**/*.md`, extracts summary per the resolution order, writes index.md per the output shape. Plus dispatch routing for `bocek vault index --rebuild` and `bocek vault index --check`.
- **#4-2:** Smoke-test the rebuild script against bocek's own vault (13 entries currently). Confirms the H1-fallback handles all current entries cleanly; the warning count is ≤ entry count.
