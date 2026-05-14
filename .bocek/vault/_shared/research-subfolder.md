---
type: decision
features: [_shared]
related: ["[[mandatory-feature-folders]]", "[[mattpocock-skills-survey]]", "[[vault-scale-audit-bokchoy]]"]
created: 2026-05-14
confidence: high
---

# Research entries take `.research/` subfolder per feature

## Decision

Research-type vault entries (`type: research`) live at `.bocek/vault/{feature}/.research/{slug}.md` rather than alongside decisions at `.bocek/vault/{feature}/{slug}.md`. Cross-feature research lives at `.bocek/vault/_shared/.research/{slug}.md`. The dot-prefixed `.research/` subfolder hides them from default `ls` output while remaining wikilink-resolvable (`[[slug]]` is filename-based, not path-based), grep-able, and `find`-discoverable.

This is a path-convention *extension* of `[[mandatory-feature-folders]]`, not a supersession. The parent rule still governs decisions, contracts, discoveries, gaps, and exploration entries — those continue to live at `{feature}/{slug}.md`. Only `type: research` entries take the subfolder. `.compiled/` precedent already established that dot-prefixed subdirectories inside the vault are legitimate (cache directory at vault root); `.research/` extends that pattern to feature scope.

## Reasoning

The bokchoy vault (`~/audhd/bokchoy/.bocek/vault/`) is the production-cited evidence: 89 entries, 58% research-type (52 research / 27 decision / 3 discovery / 2 contract / 1 exploration), 5 feature folders. Two failure modes observed:

1. **Folder navigability collapses past ~30 entries per feature.** bokchoy's `architecture/` folder holds 39 entries; nearly half are research, the rest decisions. `ls` becomes unreadable as an index. Hiding research drops the visible per-feature entry count ~60% without losing the artifact (production-cited within bocek; high).

2. **Default context loads pull research the model doesn't need.** Implementation, debugging, refactoring, and review's vault-compliance pass need decisions and contracts — not the underlying research that informed them. bocek's preflight reads recent entries across the vault without type-filtering, so research enters the context window unnecessarily. At bokchoy's ratio, that's ~58% of preflight tokens being spent on research the active mode doesn't need (production-cited within bocek; high).

User's stated constraint: *"we need the research to be grounded enough and keeping under a `.research` folder makes it easy for me to read and saves context/tokens for the ai."* Both halves map to a winning condition for path-hide over fold-inline (production-cited within this session; high).

Matt Pocock's `mattpocock/skills` repo (81k stars, production-cited within methodology space; high) takes the opposite path: research folds inline into ADR reasoning sections, no separate research artifact. Rejected here because bocek deliberately preserves research as durable, cross-decision-citable evidence. bokchoy's `_shared/oss-sdk-only.md` is research that supports decisions across `project-shape`, `sdk`, AND `marketing`; folding inline forces three-way duplication or arbitrary canonical-home selection — both fight the data (production-cited within bokchoy; high).

## Engineering substance applied

This is a structural decision, not system-shaped, but three principles apply directly:

- **Operability:** one path-rule extension, one prose update in `vault-format.md`, one preflight extension, one enforce-mode rule. Single point of doctrine.
- **Discoverability:** visible folder shrinks ~60% on `ls` while research stays accessible to every Unix tool that doesn't default to dotfile-blindness (`find`, `grep -r`, `git`, every editor's project-wide search). The dot-prefix uses standard Unix semantics for "hidden from default listings, fully accessible to tools" — `.git`, `.next`, `.venv`, `.cache`, `.obsidian` are all production examples (production-cited; high).
- **Context budget:** primitives that don't need research can skip the `.research/` subfolder when loading vault context. Savings scale with research-to-decision ratio — at bokchoy's ratio (~2:1), nearly halves the relevant-vault read.

## Production-grade gates

- **Idiomatic** — Unix dotfile convention is the standard pattern for "kept accessible but hidden from default listings." Every developer reading the layout will know what `.research/` means at a glance; no new mental model required (production-cited; high — `.git`, `.next`, `.venv`, `.cache`, `.obsidian/` all use this exact semantics).
- **Industry-standard** — The *mechanism* (dotfile-hide for auxiliary content in a content tree) is universal. The *exact application* (type-class-routed subfolder hide for evidence artifacts in an ADR/vault system) is bocek-specific — no other ADR or vault tool I can name does this. Calibration: production-cited for the mechanism, inferred for the type-class application (medium — verify against more knowledge-base tools before claiming production-cited).
- **First-class** — Uses filesystem dotfile semantics directly. No custom indexing, no metadata routing layer, no symlinks. The path on disk IS the convention.

## Rejected alternatives

### (a) Fold research inline into decision entries

**What:** Research collapses into the decision's *Reasoning* and *Engineering substance applied* sections as inline citations with evidence labels. No separate research file class. Matt's pattern.

**Wins when:** Research is rarely consulted independently of its decision; project is small enough that cross-decision research duplication doesn't pay off; ADR-style single-file-per-decision is the team's culture.

**Why not here:** bokchoy's `oss-sdk-only.md` is research that informs three decisions across three features. Folding inline forces either three-way duplication or arbitrary canonical-home selection; both fight the data. Bocek's design philosophy treats research as durable evidence that survives any individual decision's lifecycle — folding inline collapses that property.

### (c) Status quo — research as flat siblings inside the feature folder

**What:** Continue writing research entries to `{feature}/{slug}-research.md` alongside decisions. No subfolder.

**Wins when:** Vault stays under ~30 entries total. At that scale, folder navigability isn't yet a constraint and the flat shape is the simplest possible rule.

**Why not here:** bokchoy is at 89 entries with 52 research — production evidence that the flat shape fails at this scale. The user's complaint that triggered this decision (*"the more you work with the messier it gets"*) is the status quo's failure mode.

### (d) Inverted organization — research at top-level, features nested inside

**What:** Research lives at the vault root under a single `.research/` directory, with feature subfolders inside it (`.bocek/vault/.research/{feature}/{slug}.md`). Inverts the feature-first / type-second hierarchy.

**Wins when:** Research is the primary artifact and decisions are a thin synthesis layer over it — research-first projects (academic, exploratory science, literature review).

**Why not here:** bocek is implementation-driven; the vault exists to constrain code, not to publish research. Feature-first organization keeps related artifacts co-located. Inverting the hierarchy breaks the *"`ls .bocek/vault/{feature}/` is the per-feature entry map"* property the parent decision established (inferred; medium).

### Hybrid (rejected explicitly)

"Fold inline when research supports exactly one decision; keep separate file when it spans multiple decisions" — sounds reasonable until you notice that "supports exactly one decision" is a property that changes over time. Research written as single-decision support gets cited by a second decision next month, then the inline copy has to be extracted back into a file. **Exception path that creates more work, not less.**

## Failure mode

**The dot-prefix quietly hides research from non-bocek-aware tooling.** Default `ls` doesn't show `.research/`. Many editor file explorers hide dotfiles by default. A new contributor browsing the vault may miss that an evidence layer exists — the vault's evidence-first culture becomes invisible at the filesystem layer until they learn the convention.

Specific manifestation in bocek's own code: `scripts/preflight.sh:101-102` searches recent entries at `-mindepth 2 -maxdepth 2`. Research entries at `vault/{feature}/.research/{slug}.md` are depth 3. **The preflight's recent-entries listing will silently exclude research entries** under this convention, under-reporting vault activity for projects that use it. Found via self-attack pre-vault.

## Mitigations

1. **Preflight extension (load-bearing).** `scripts/preflight.sh` updated to (a) count `.research/` entries per feature folder in the vault state output (`wallet/.research/: 4 entries`), and (b) extend recent-entries search to include depth-3 paths matching `*/.research/*.md`. Surfaces the hidden layer at orientation time so every session sees it before reading.
2. **Migration script.** `bocek vault organize --migrate-research` walks each feature folder, identifies `type: research` entries via frontmatter, moves them into `.research/` subfolder, preserves git history via `git mv` where applicable. One-time operation per vault. Without it, bokchoy's 52 research entries stay flat and the convention exists only for new entries.
3. **`vault-format.md` path-convention section documents the extension prominently.** The dotfile-hide-with-discoverability story sits in the same prose block as the parent rule, so a reader reaches them together. Prevents the "doctrine without enforcement" drift the parent decision named.
4. **`enforce-mode.sh` extension (load-bearing).** When a write targets `vault/{feature}/*-research.md` (the flat pattern) or `vault/{feature}/{slug}.md` where frontmatter declares `type: research`, the hook rejects with a message pointing to `.research/`. Same enforcement-in-code-not-prose philosophy as the parent decision. Without this, the model will drift back to flat-research at write time exactly the way it currently drifts back to flat-vault.

## Idiom citations

None — path-convention decision, not stack-specific.

## Revisit when

- Research-to-decision ratio exceeds ~70% sustained across multiple features. Suggests the project is research-first not implementation-first; consider Option (d) inverted hierarchy.
- A second type class develops the same "auxiliary evidence, not load-bearing-on-code" property at scale (e.g., `exploration` or `discovery` proliferating past ~20 per feature). The dot-prefix-subfolder pattern generalizes (`.exploration/`, `.discovery/`) — but past 3-4 subfolders per feature, consolidate into a unified `.evidence/` folder or revisit the type taxonomy.
- A tooling integration is added where dotfile-blindness becomes a load-bearing footgun rather than a context-budget feature.
- Wikilink resolution stops being filename-based (e.g., bocek adopts path-qualified wikilinks). The decision assumes `[[slug]]` works regardless of path; if that changes, the migration cost shifts.
