---
type: research
features: [_shared]
related: ["[[research-subfolder]]", "[[mandatory-feature-folders]]", "[[mattpocock-skills-survey]]"]
created: 2026-05-14
confidence: high
provisional: true
---

# At what scale does bocek's vault model produce navigability and context-budget failures, and what specifically fails?

## Question

`~/audhd/bokchoy/.bocek/vault/` is a production bocek-using project at 89 entries (as of 2026-05-14). The user reports the vault "the more you work with the more messy it gets" and that bocek's `.compiled/` mechanism "isn't working." Specific failure modes need to be identified, named, and quantified — both to inform the immediate `[[research-subfolder]]` decision and to surface the broader queue of vault-format polish work that prompted this entire design pass.

## Triangulation

- **Production reference:** ✓ — `~/audhd/bokchoy/.bocek/vault/` at filesystem state observed 2026-05-14. Tier 1 (production code, here as production *vault data*, but the structural shape is what's being audited).
- **Docs reference:** ✓ — bocek's own `references/shared/vault-format.md` (path convention, frontmatter spec, body structure spec), `references/shared/session-continuity.md` (state.md format spec), `primitives/implementation.md:25` (lazy-compile instruction). The audit finds *deviations from these specs*, so the docs are the comparator, not the source of the findings.
- **Contradiction probe:** ✗ — did NOT survey other bocek-using projects. bokchoy is N=1 production-cited evidence. `provisional: true` set on this entry because the failure modes observed may be bokchoy-specific (single-team, AI/game-economy domain, research-first culture per the type distribution) rather than general bocek-at-scale behavior. Closing this gap requires auditing at least one other project at >50 vault entries.

## Sources examined

### `~/audhd/bokchoy/.bocek/vault/` filesystem state

- **Tier:** 1 (production code / production vault data)
- **Provenance:** local filesystem, observed 2026-05-14. Entries' last-modified timestamps span 2026-04-29 through 2026-05-14. Reproducible via `find ~/audhd/bokchoy/.bocek/vault -type f -name '*.md' -not -path '*/.compiled/*'` (which currently returns 89 entries) and `awk` on frontmatter to extract `type:` and `features:` per entry.
- **Author context:** Single-engineer bokchoy project. Bocek user since ~2026-05-02 per state.md "Session history" entries. Active design+research+implementation cycles; multiple implementation seats have run per state.md citations.
- **What it tells us:** Quantitative shape of a real bocek vault at the scale where the user reports failure — entry counts per folder, type distribution, frontmatter compliance, path-convention compliance, presence/absence of `.compiled/`, state.md and index.md sizes.

### `~/audhd/bokchoy/.bocek/state.md`

- **Tier:** 1
- **Provenance:** local filesystem, 20,353 bytes, observed 2026-05-14
- **What it tells us:** state.md has grown to 20KB with appended session history, slice queues, implementation queues, "parked tracks," "design amendments owed," "prior decision context for fresh seats reading cold." Per `scripts/preflight.sh:71`, only `head -8` of state.md is loaded into the preflight orientation block — meaning ~99% of the file is dead context for the next session that opens it.

### bocek's own `scripts/preflight.sh`

- **Tier:** 1 (production code, this repo)
- **Provenance:** `~/audhd/bocek/scripts/preflight.sh` at HEAD on `main`, observed 2026-05-14
- **What it tells us:** Lines 81-82 search for vault entries at `-maxdepth 4 -name "*.md" -not -path "*/.compiled/*"`. Lines 96-99 detect loose entries at vault root (path-convention violations). Lines 101-102 find "recent entries" at `-mindepth 2 -maxdepth 2`. These bounds DO encompass the current path convention but DO NOT encompass the `.research/` subfolder pattern introduced by `[[research-subfolder]]` — making the audit relevant to the active design decision.

### bocek's own `references/shared/vault-format.md` and `primitives/implementation.md`

- **Tier:** 2 (official docs, this project)
- **Provenance:** `~/audhd/bocek/references/shared/vault-format.md` and `~/audhd/bocek/primitives/implementation.md` at HEAD, observed 2026-05-14
- **What it tells us:** The *spec*. Body structure for index.md says one-line entry summaries (`- [[name]] — type: T — one-line summary`); body structure for state.md (per `references/shared/session-continuity.md`, not re-pulled here but cited at `primitives/implementation.md:25`) is a checkpoint shape, not a journal. Lazy-compile is documented as: *"the compiled file at `.bocek/vault/.compiled/{feature}.md` if present, otherwise compile it from `.bocek/vault/{feature}/*`."* — a prose instruction to the model, not a script call.

## Findings

### F1. The vault is 89 entries; production "messy at scale" complaint is real

`find ~/audhd/bokchoy/.bocek/vault -type f -name "*.md" -not -path "*/.compiled/*"` returns 89 entries. Bocek's documented design philosophy treats the vault as a feature-folder graph; the bokchoy state is past the scale where un-aided folder navigation works. The complaint *"the more you work with the more messy it gets"* maps to specific quantitative failure modes (F2-F7 below), not to vague aesthetic friction.

### F2. Research entries are 58% of the vault

Frontmatter `type:` distribution across all 89 entries:

| Type | Count | % of vault |
|---|---|---|
| `research` | 52 | 58% |
| `decision` | 27 | 30% |
| `discovery` | 3 | 3% |
| `contract` | 2 | 2% |
| `exploration` | 1 | 1% |

Research is the dominant type class. Inspection of feature folders reveals the *research-paired-decision* pattern: `architecture/backend-stack.md` exists next to `architecture/backend-stack-research.md`; `architecture/frontend-stack.md` next to `architecture/frontend-stack-research.md`; `architecture/local-docker.md` next to `architecture/local-docker-research.md`; `architecture/catalog-versioning.md` next to `architecture/catalog-versioning-research.md`. **Half the vault is research files that exist to support the other half's decision files.**

This is the load-bearing finding for `[[research-subfolder]]`.

### F3. `architecture/` is being used as a junk drawer (39 entries, ~44% of vault)

Per-folder counts:

| Folder | Entry count |
|---|---|
| `architecture/` | 39 |
| `_shared/` | 16 |
| `wallet/` | 14 |
| `cockpit/` | 11 |
| `marketing/` | 4 |
| `wedge/` | 3 |
| `mvp/` | 1 |

Inspection of `architecture/` reveals 39 entries spanning subjects that should be *separate features*: `backend-stack`, `frontend-stack`, `local-docker`, `drizzle-orm`, `tanstack-query-rsc`, `multi-tenant-rls`, `idempotency-strategy`, `catalog-versioning`, `loot-rng`, `pity-engine`, `wallet-source-of-truth`, `webhook-retry-norms`, `audit-retention`, `host-platform`, `player-auth`. **"Architecture" here is functioning as a meta-category meaning "stuff that doesn't fit cleanly elsewhere yet"** — the same failure mode `[[mandatory-feature-folders]]`'s mitigation 1 warned `_shared/` would develop. The vault path convention currently doesn't prohibit generic meta-feature names.

### F4. `_shared/` is misclassified at 56%

16 entries in `_shared/`. Frontmatter `features:` analysis:

- 3 entries have NO `features:` list at all (`africa-field-notes.md`, `landscape-survey.md`, `research-scope.md`).
- 6 entries have a *single feature* (`design-doc-audit` × 6: `cockpit-gap-research.md`, `design-claims-register.md`, `integration-feasibility-research.md`, `sales-cycle-research.md`, `slice-cell-research.md`, `structural-moat-research.md`). Per the path convention, single-feature entries belong in a named feature folder (`design-doc-audit/`), not `_shared/`.
- 7 entries have multiple features — the legitimate `_shared/` use case.

**9 of 16 `_shared/` entries (56%) are path-convention violations.** Per `[[mandatory-feature-folders]]`'s mitigation 2, a review session reading single-feature entries in `_shared/` should flag them as misclassified — but that mitigation was never implemented in the review primitive.

### F5. `index.md` is 113 lines for 89 entries — but spec is being violated

Spec (per `references/shared/vault-format.md` index update section): `- [[entry-name]] — type: T — one-line summary`. Practice: lines run 500+ characters with embedded paragraph-length descriptions. Sample (from `bokchoy/.bocek/vault/index.md` head): the marketing/currencies-endpoint-research entry has a single index line containing 11+ findings, citation counts, contradiction-probe results, and four "operational implications" — content that belongs in the entry body, not the index. **The index has become a redundant content layer alongside the entries themselves.**

### F6. `state.md` is 20,353 bytes — only `head -8` loads

`wc -c` reports 20353. `scripts/preflight.sh:71` reads `head -8` of state.md into the orientation block. **~99% of state.md is dead context** — the file has grown into a session-by-session journal with slice queues, implementation queues, parked tracks, and "prior decision context for fresh seats reading cold." The session-continuity format spec at `references/shared/session-continuity.md` describes state.md as a checkpoint (current state, in-progress, next), not a journal.

### F7. `.compiled/` directory does NOT exist

`ls ~/audhd/bokchoy/.bocek/vault/.compiled/` returns `No such file or directory`. Yet bokchoy's state.md shows multiple implementation seats have run: *"Cockpit slice 8.3.6 landed 2026-05-14 (prior implementation seat)"*, *"M-1 + M-2 + M-3 LANDED"*, *"`[[wallet/credit-route-contract]]` LANDED — Slice M-1.5"*. **Implementation ran repeatedly and never compiled.**

Root cause: `primitives/implementation.md:25` says "compile from `.bocek/vault/{feature}/*` if `.compiled/` not present" — but this is a prose instruction to the model, not a script call. The model reads vault entries directly from feature folders and skips the compile step at write time. The lazy-compile is documented but not enforced. Same failure pattern as the path-convention "doctrine without enforcement" problem the `[[mandatory-feature-folders]]` decision corrected — repeated at a different layer.

## Conflicts

### Vault philosophy says "research is durable evidence" but practice produced "research files inflate folder navigability past usability"

The original bocek design philosophy (per `primitives/design.md` and `primitives/research.md`) treats research as durable, separately-citable evidence that survives any individual decision's lifecycle. Bokchoy's data confirms research IS being treated that way (52 entries, several spanning multiple features per `oss-sdk-only.md` which has `features: [project-shape, sdk, marketing]`).

The conflict: durability is correct in principle but the *shape* (separate files at feature-folder root) causes navigability collapse at scale. **The philosophy is right; the file shape is wrong.** `[[research-subfolder]]` reconciles this by keeping research as separate files (durability preserved) while moving them to `.research/` (folder navigability restored).

### Per-folder ergonomic ceiling vs. feature-folder mandatory rule

`[[mandatory-feature-folders]]` mandates every entry live in a feature folder. bokchoy's `architecture/` proves a feature folder can itself grow past the ergonomic ceiling (39 entries) — at which point the parent rule's discoverability claim (O(features × entries-per-feature) instead of O(total)) breaks. **The parent rule needs a complementary "split-when-large" sub-rule or an explicit ban on meta-feature names** to prevent the architecture/ failure mode generalizing.

This is queued as polish #6 (generic-meta-feature ban) in `state.md`'s "Next" list.

## Conditions

These failure modes manifest at:

- **F1-F2 (research-paired bloat):** >30 entries per feature folder AND >50% research ratio. Below those thresholds, the flat shape works (bokchoy's `marketing/` with 4 entries, `wedge/` with 3, `mvp/` with 1, and `cockpit/` with 11 all read cleanly).
- **F3 (junk-drawer feature folder):** when a folder name describes a *category* rather than a *feature*. "Architecture" qualifies; "wallet" doesn't. Names that survive: nouns specific enough that the *feature itself* is the unit. Names that fail: nouns abstract enough to attract drift.
- **F4 (`_shared/` misclassification):** observed at 16-entry scale. Likely manifests earlier — `_shared/` becomes the model's path of least resistance when it's mid-session and doesn't want to stop and identify the primary feature.
- **F5 (index bloat):** the spec violation happens at any vault size, but it only becomes operationally painful when the index is the navigational interface (≥~20 entries). At smaller scale, readers go straight to the entries.
- **F6 (state.md bloat):** observable after ~5 sessions. The append-without-trim pattern is the default the model adopts.
- **F7 (`.compiled/` never generates):** happens *every time* implementation runs. The failure isn't scale-dependent — it's "doctrine without enforcement" at any scale.

These failures DO NOT manifest when:

- The project stays below ~20 vault entries total (no folder hits the ergonomic ceiling).
- Research is rare or folded inline (matt's pattern — see `[[mattpocock-skills-survey]]`).
- The team uses bocek for a single feature only (no folder-naming politics).
- The implementation primitive is never invoked (no lazy-compile failure to observe).

## Operational implications

For the immediate decision:

- **`[[research-subfolder]]` is grounded.** The 58% research ratio and the architecture-folder-at-39-entries data is the load-bearing production-cited evidence the Option B choice rests on.

For follow-up design sessions (state.md "Next" queue):

- **Polish #6 (lazy-compile becomes a script).** Highest-correctness payoff. Smallest content change — wrap the `find ... | cat` pattern in a `bocek vault compile <feature>` subcommand and update `primitives/implementation.md` to call it explicitly. Failure pattern is identical to the path-convention enforcement gap.
- **Polish #4 (index regen from frontmatter).** Highest "stop the bleeding" payoff. The spec is already correct; what's missing is enforcement. A `bocek vault index --rebuild` script that regenerates `index.md` from each entry's frontmatter `description:` field kills the bloat structurally; hand-edits to `index.md` get clobbered by next rebuild.
- **Polish #5 (state.md bounded format).** Two design options to grill: (a) overwrite each session (lose history), (b) rotate to `state-{YYYY-MM-DD}.md` past a size threshold. Design session owed.
- **Polish #2 (`_shared/` misclassification gate).** Mitigation already specified in `[[mandatory-feature-folders]]`; just needs implementation. Either `bocek vault organize --classify-shared` flags single-feature entries, or `enforce-mode.sh` blocks the write at frontmatter-parse time.
- **Polish #6 (generic-meta-feature ban).** Hardest to enforce because "generic" is fuzzy. Defer until #2 lands and the broader `_shared/` discipline pattern is observable.

Cross-cutting:

- **Five of the six failure modes share root cause: bocek's enforcement stops at `enforce-mode.sh`.** Everything else (path convention details, index format, state.md scope, lazy-compile) is markdown the model interprets at write time. The polish strategy isn't format polish — it's pushing enforcement deeper into code at every layer where doctrine currently lives only in prose.

## Reproducibility note

Reproducible in full. Steps:

1. `find ~/audhd/bokchoy/.bocek/vault -type f -name '*.md' -not -path '*/.compiled/*' | wc -l` → entry count
2. `find ~/audhd/bokchoy/.bocek/vault -mindepth 1 -maxdepth 1 -type d -not -name '.compiled' -printf '%f\n'` → feature-folder list
3. For each folder: `find ~/audhd/bokchoy/.bocek/vault/$folder -type f -name '*.md' | wc -l` → per-folder count
4. For each entry: `awk '/^---$/{if(c)exit;c=1;next} c && /^type:/{print $2;exit}' "$f"` → type
5. For each entry: `awk '/^---$/{if(c)exit;c=1;next} c && /^features:/{print;exit}' "$f"` → features
6. `wc -l ~/audhd/bokchoy/.bocek/vault/index.md` and `wc -c ~/audhd/bokchoy/.bocek/state.md` → size validations
7. `ls ~/audhd/bokchoy/.bocek/vault/.compiled/` → expect `No such file or directory`
8. `grep -B1 -A2 "implementation" ~/audhd/bokchoy/.bocek/state.md` → evidence that `/implementation` has run

A second investigator running these queries on the same vault state would reach the same F1-F7. Interpretation (the "Conditions" section's thresholds) is judgment, not reproduction — those thresholds are inferred from one project's data and need additional bocek-using projects to validate.

## Open threads

- **Second production vault.** N=1 is `provisional`. At least one more bocek-using project at >50 entries audited the same way would close the contradiction-probe channel and let this entry's `provisional` flag drop.
- **Folder splitting protocol.** When `architecture/` (or any folder) crosses ~30 entries, what's the splitting workflow? Manual? Scripted? Per-entry feature-rename via `bocek vault reassign`? This is a future design session's question.
- **`.compiled/` invariants under research-subfolder.** Once `[[research-subfolder]]` lands and bokchoy migrates, the `.compiled/{feature}.md` file should it include `.research/*.md` content or skip it? Currently `.compiled/` doesn't exist for bokchoy so the question is theoretical, but answering matters for polish #6's design.
- **Bokchoy's preflight-bug-2026-05-02.md.** Bokchoy has a 10KB file at `.bocek/preflight-bug-2026-05-02.md` directly in `.bocek/` (not under `vault/`). It's outside the vault path convention's jurisdiction but signals there's an "incident report" content class bocek doesn't have a home for. Adjacent research, not in scope for this entry.
