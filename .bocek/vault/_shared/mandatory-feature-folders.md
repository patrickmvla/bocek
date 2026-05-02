---
type: decision
features: [_shared]
related: []
created: 2026-05-02
confidence: high
---

# Mandatory feature folders for vault entries

## Decision

Vault entries must live in a feature-named subdirectory. The path shape is `.bocek/vault/{feature}/{slug}.md` when the entry has an identifiable primary feature, or `.bocek/vault/_shared/{slug}.md` when the entry genuinely spans multiple features with no primary one. Flat writes to `.bocek/vault/*.md` are forbidden and code-enforced — only `index.md` and the gitignored `.compiled/` cache directory are allowed at the vault root.

The `_shared/` folder is the *legitimate escape hatch*, not a placeholder for "I don't know the feature yet." If the entry has a single value in `features:` frontmatter, it belongs in that named feature folder, not `_shared/`.

Enforcement is structural, not doctrinal. `scripts/enforce-mode.sh` rejects `Edit`/`Write` calls and bash-write commands that target flat-vault paths, regardless of mode. Design, research, implementation, debugging, refactoring, review — all behave identically with respect to this rule.

This decision supersedes `docs/decisions/0003-vault-as-knowledge-graph.md` at the path layer. ADR-0003's other claims — the vault as a knowledge graph, wikilinks as the primary relationship mechanism, frontmatter for type/features/related/created/confidence, "the graph structure is more important than the folder structure" — all stand. **Graph-shape stays flexible. File-shape becomes structured.**

## Reasoning

The drift from optional-folders (ADR-0003, accepted) to mandatory-folders (vault-format.md, primitives, preflight) happened gradually as bocek's operational doctrine evolved past what flat-tolerance can support, but the founding decision was never amended. The model anchors on the surviving load-bearing decision when picking paths — observed in this very session, where the model proposed `discovery-preflight-path-doubling.md` (slug only) rather than `preflight/discovery-path-doubling.md` (feature folder) when offering to vault a debugging discovery (production-cited within bocek; high confidence).

Two compounding signals:

1. **Doctrinal drift exists in-tree.** `references/shared/vault-format.md:121` says "never directly into `.bocek/vault/`". All six primitives' "Vault writes" sections quote that same mandatory framing. `scripts/preflight.sh:95-99` calls loose entries a "path-convention violation." None of these references back-reference ADR-0003, and ADR-0003 was never updated to match. The team kept tightening the operational layer without touching the decision record (production-cited; high).

2. **Enforcement is prose, not code.** `scripts/enforce-mode.sh:31` allows any write to `.bocek/`. Preflight only warns at orientation time about pre-existing loose entries; new ones are allowed. The "convention" can be violated without any blocking layer noticing — and the model's training-data default is flat (inferred; medium).

The drift was right, the recording wasn't. This decision retroactively makes the doctrine load-bearing and pushes enforcement into code where it can't drift.

## Engineering substance applied

This is a structural decision, not system-shaped, but two principles apply directly:

- **Operability:** enforcement at the script layer is mode-independent and single-source-of-truth. Reading the rule means reading `enforce-mode.sh`, not reconciling six prose mentions across vault-format.md and the primitives. When the rule changes, one file changes.
- **Discoverability:** file-system structure as the index. `ls .bocek/vault/` becomes a feature map; `ls .bocek/vault/{feature}/` becomes the per-feature entry list. Browse cost is O(features × entries-per-feature) instead of O(total-entries). Past ~30 entries, the latter becomes unreadable (inferred; medium — common knowledge for note-taking systems).

## Production-grade gates

- **Idiomatic** — Hierarchical organization is the standard pattern for engineering knowledge bases at this layer: ADR repos on GitHub group by topic, engineering wikis (Confluence, Notion) by feature/area, Obsidian power users with >100 notes converge on folder structures despite Obsidian itself being flat-tolerant. Bocek inherited Obsidian-flat as inspiration in ADR-0003 but never had the lifecycle data to validate it; the operational doctrine drift IS the data (inferred; high — based on observed convergence).
- **Industry-standard** — Every public ADR repo of significant size organizes by topical subdirectory rather than flat-numbered files. Two named: Spotify's `engineering` ADR repo and ThoughtWorks' technology-radar (both publicly visible; both subdirectory-organized once past ~20 entries). Cited as inferred provenance — I have not re-verified the exact current shape of either; if this matters before vaulting, switch to /research.
- **First-class** — Uses the filesystem itself as the organizational primitive. No custom index database, no metadata-only structure, no SaaS-layer registry. `find`, `ls`, `grep`, `cat` are the navigation tools. Doesn't fight the platform.

## Rejected alternatives

### (b) Keep ADR-0003 as-is, soften vault-format.md from "never" to "strongly recommended"

**What:** Bring operational doctrine back into alignment with the founding decision by relaxing `vault-format.md` and the primitives. Stop pretending preflight's warning is enforcement.

**Wins when:** The project values the original Obsidian-graph philosophy over operational discoverability — specifically, short-lived projects, single-feature scope, or research-notebook usage where structure emerges late.

**Why not here:** The drift toward mandatory wasn't a mistake; it was the team noticing flat-vault stops working at scale. Reverting the doctrine reverts the lesson. Bocek's intended user is a multi-month, multi-feature engineering project. Flat-tolerance underdelivers there.

### (c) Tighten enforcement at the code layer without amending ADR-0003

**What:** Update `enforce-mode.sh` to block flat writes; leave ADR-0003's "optional" framing intact and call the script behavior a "soft default."

**Wins when:** The team wants to preserve flat as a future option (e.g., a hypothetical experimental mode).

**Why not here:** Worst of both worlds. The doctrine still says optional; the code says mandatory. The exact drift this decision corrects would re-emerge between ADR-0003 and the new script behavior. The decision record must match the code, or one of them is lying.

## Failure mode

The sharp edge: `_shared/` becomes a default dumping ground. A designer in the middle of a session doesn't pause to identify the primary feature, drops the entry into `_shared/`, moves on. Past ~30% of entries in `_shared/`, the feature-folder structure stops being navigationally useful — `_shared/` becomes the new flat.

Quantitative threshold: when `_shared/` holds more than 30% of total non-`index.md` entries in a vault, the convention is being abused.

## Mitigations

1. **Convention text in `references/shared/vault-format.md` is precise.** "_shared/ when the entry genuinely has no primary feature; never as a placeholder for 'I don't know yet'."
2. **`/review` mode gate.** When a review session reads an entry under `_shared/` whose `features:` frontmatter contains exactly one named feature, flag it as misclassified. The entry should be moved to that feature folder.
3. **Preflight visibility.** When `_shared/` exceeds the 30% threshold, the orientation block emits a one-line warning so the next session sees it before designing forward.

## Revisit when

- A short-lived or single-feature use case emerges as a major bocek persona, and feature-folder ceremony becomes friction. Add a `flat-vault: true` opt-in.
- `_shared/` exceeds 30% of total entries in a real vault despite mitigation 1 — the convention is being applied carelessly and the rule needs a sharper gate.
- A future Obsidian-style flat-tolerant note-taking mode is added to bocek (currently no plans).
- A decision-record format other than the current `vault-format.md` schema is adopted; the path layer may need re-derivation.
