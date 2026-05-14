---
type: research
features: [_shared]
related: ["[[research-subfolder]]", "[[mandatory-feature-folders]]", "[[compile-step-rent-research]]"]
created: 2026-05-14
confidence: high
provisional: true
---

> **Update 2026-05-14 (deep-read pass).** v1 of this entry capped scope at 15 active skills + architecture docs and labeled the rest *"not load-bearing for the architectural question"* based on category, not content. A second `/research` pass read the remaining 13 SKILL.md files (including all `misc/`, `personal/`, `in-progress/writing-*`, and `deprecated/`) plus 8 Tier-A supporting files. **One finding was wrong (F8); five new findings surfaced (F9-F13); take-list re-ranked.** Addendum at the bottom under *Deep-read findings (F9-F13)* and *Take-list revisions after deep-read*. Original v1 body preserved below — corrections are noted inline where they apply.



# How does `mattpocock/skills` structure agent methodology, and which patterns map onto bocek's primitives without breaking bocek's modal-enforcement moat?

## Question

`mattpocock/skills` (81k GitHub stars as of 2026-05-14, last push 2026-05-13) publishes a complete set of Claude Code agent skills with persistent companion artifacts (`CONTEXT.md`, `docs/adr/`, per-repo configuration). The question this research answers: what tactical patterns in matt's repo could be lifted into bocek's primitives, references, and scripts to harden bocek against the failure modes observed in `[[vault-scale-audit-bokchoy]]` — *without* abandoning bocek's modal-mutex architecture, which is the only thing that gives the PreToolUse enforcement hook a defined mode to enforce against.

## Triangulation

- **Production reference:** ✓ — `github.com/mattpocock/skills` at HEAD (commit on default branch `main`, pushed 2026-05-13). 17 active skills surveyed across `engineering/`, `productivity/`, `misc/` categories. Architectural docs (`README.md`, `CLAUDE.md`, `CONTEXT.md`, `.claude-plugin/plugin.json`) read in full. SKILL.md files for `grill-me`, `grill-with-docs`, `diagnose`, `tdd`, `improve-codebase-architecture`, `triage`, `to-prd`, `to-issues`, `zoom-out`, `prototype`, `caveman`, `handoff`, `write-a-skill`, `setup-matt-pocock-skills`, and in-progress `review` read in full. `ADR-FORMAT.md`, `CONTEXT-FORMAT.md`, and `docs/adr/0001-explicit-setup-pointer-only-for-hard-dependencies.md` read in full. Misc skills (`git-guardrails-claude-code`, `migrate-to-shoehorn`, `scaffold-exercises`, `setup-pre-commit`), personal skills (`edit-article`, `obsidian-vault`), and deprecated skills (`design-an-interface`, `qa`, `request-refactor-plan`, `ubiquitous-language`) were NOT pulled — they're tactical or off-pattern, not load-bearing for the architectural question.
- **Docs reference:** ✗ — no "official spec" exists for the SKILL.md format beyond Anthropic's blog post announcing the standard (December 2025, mentioned in third-party writeups but not pulled here). The repo IS the spec for matt's interpretation of it.
- **Contradiction probe:** ✗ partial — did not survey alternative skill-system designs (BMAD, GSD, Spec-Kit, all named in matt's README as competitor frameworks he built skills as an alternative to). `provisional: true` set on this entry because patterns extracted from one team's published methodology may reflect matt's idiosyncrasies, not the production-grade default for AI-engineering methodology. Closing this gap requires reading at least one of BMAD/GSD/Spec-Kit and noting where their architectural choices diverge.

## Sources examined

### `mattpocock/skills` repository at HEAD

- **Tier:** 1 (production code — public repo of named system)
- **Provenance:** `github.com/mattpocock/skills`, default branch `main`, pushed 2026-05-13, 81,135 stars per `gh api repos/mattpocock/skills`
- **Author context:** Matt Pocock — TypeScript educator (`ts-reset` 8.5k stars, `ts-error-translator` 2.5k stars, `evalite` 1.5k stars), Total TypeScript courses; describes himself as solo educator/tooling-builder; skills repo published from his daily personal `.claude/` directory. Not a team-scale system; reflects one expert's personal workflow.
- **What it tells us:** Concrete shape of a composable skill-bundle architecture: 17 atomic slash commands organized in buckets, distributed as a Claude Code plugin (`.claude-plugin/plugin.json`), with per-repo setup via `/setup-matt-pocock-skills` writing config to `CLAUDE.md` + `docs/agents/`. The architecture works because skills are independent and the model is trusted to read them on invocation — no enforcement.

### `mattpocock/skills/skills/engineering/grill-with-docs/{SKILL,ADR-FORMAT,CONTEXT-FORMAT}.md`

- **Tier:** 1 (production code, but documentation files)
- **Provenance:** repo HEAD as of 2026-05-13
- **Author context:** Matt Pocock, single author per commit history
- **What it tells us:** ADR pattern (paragraph-length, lazy creation, three-criteria gate: hard-to-reverse + surprising + real trade-off), CONTEXT.md glossary pattern (opinionated definitions, avoid-list of aliases, flagged ambiguities, single-vs-multi-context branching), inline-update discipline ("create documentation lazily — only when you have something concrete to capture; capture resolved terms in CONTEXT.md as they emerge, not in batches").

### `mattpocock/skills/skills/engineering/diagnose/SKILL.md`

- **Tier:** 1
- **Provenance:** repo HEAD as of 2026-05-13
- **What it tells us:** Six-phase debugging discipline with Phase 1 ("build a feedback loop") explicitly named as "the skill" — the rest is mechanical once a loop exists. Enumerates 10 ranked loop-construction methods (failing test, curl script, CLI fixture diff, headless browser, replay traces, throwaway harness, property/fuzz, bisection harness, differential loop, HITL bash). Falsifiability gate on hypotheses ("If X is the cause, then changing Y will make the bug disappear"). Tag-and-grep cleanup convention (`[DEBUG-a4f2]` prefixes).

### `mattpocock/skills/skills/engineering/tdd/SKILL.md`

- **Tier:** 1
- **Provenance:** repo HEAD as of 2026-05-13
- **What it tells us:** Vertical-not-horizontal rule, named explicitly: "DO NOT write all tests first then all implementation. Tests written in bulk test imagined behavior, not actual behavior." Tracer-bullet pattern (test1→impl1, test2→impl2). Behavior-over-implementation framing: "good tests describe what the system does, not how it does it."

### `mattpocock/skills/skills/in-progress/review/SKILL.md`

- **Tier:** 1 (but flagged in-progress by author)
- **Provenance:** repo HEAD as of 2026-05-13
- **What it tells us:** Two-axis review (Standards × Spec) using parallel sub-agents to prevent context pollution. Standards sub-agent reads `CLAUDE.md`, `CONTEXT.md`, `docs/adr/`, style configs; Spec sub-agent reads originating issue/PRD and the diff. Reports kept separate, not merged. Rationale: "A change can pass one axis and fail the other."

### Third-party writeups

- **Tier:** 4 (engineering blog/news, named author)
- **Provenance:** `tosea.ai/blog/matt-pocock-skills-claude-code-guide`, `implicator.ai/matt-pocock-skills-repo-jumps-past-45k-stars-with-reusable-ai-instructions`, `byteiota.com/agent-skills-matt-pococks-68k-star-repo-defines-standard`, all accessed 2026-05-14
- **Author context:** AI-news aggregators; not engineering practitioners; reflect adoption signal more than technical evaluation
- **What it tells us:** Star-count trajectory (45k → 68k → 81k across ~3 weeks late April through mid-May 2026) confirms rapid adoption. None of the writeups critique the architecture; treat as marketing-grade evidence of *adoption*, not evidence of *correctness*.

## Findings

### F1. Composable-not-modal architecture

Skills are independent slash commands that compose in a single session — `/grill-with-docs` → `/to-prd` → `/to-issues` → `/tdd` → `/diagnose` → `/review`. No "mode" concept; no mutually-exclusive state. Per Source 1 (`.claude-plugin/plugin.json` lists 14 active skills, no dependencies between them) and Source 2 (every SKILL.md describes its own activation triggers; no "predecessor/successor" frontmatter).

**Why this matters for bocek:** bocek's modal-mutex architecture exists *because* the PreToolUse enforcement hook needs a defined mode in `.bocek/mode` to enforce against. Composable skills require there to be no such mode. **Composability and enforcement are architecturally incompatible at this layer.** This is the load-bearing reason bocek cannot adopt matt's distribution architecture wholesale.

### F2. CONTEXT.md as shared vocabulary, not glossary-of-everything

Per matt's `CONTEXT-FORMAT.md`: rules are "be opinionated" (pick the best word, list aliases as `_Avoid_`), "keep definitions tight" (one sentence max), "only include terms specific to this project's context" (explicitly excludes general programming concepts). Multi-context repos use a `CONTEXT-MAP.md` index that lists per-context CONTEXT.md files and inter-context relationships.

**Why this matters for bocek:** bocek's vault entries capture *decisions* (with feature folders), but bocek has no equivalent artifact for *vocabulary*. The bokchoy vault demonstrates this gap: feature folders carry semantic load (`wallet/`, `cockpit/`, `architecture/`) but the meaning of each is implicit. New contributors and the model both have to reverse-engineer "what is `wallet/` actually?" from the entries inside it.

### F3. ADRs with strict three-criteria gate

Per matt's `ADR-FORMAT.md`: ADR is created only when all three apply — (a) hard to reverse, (b) surprising without context, (c) result of a real trade-off between alternatives. Format is minimum one paragraph; optional sections (Status, Considered Options, Consequences) only when they add genuine value. ADRs live in `docs/adr/` numbered sequentially.

**Why this matters for bocek:** bocek's design primitive nudges toward vaulting every "decision that survives challenge." Matt's bar is stricter. Bokchoy's `architecture/` folder (39 entries) and `_shared/` folder (16 entries) both show vault entries that may not pass matt's three-criteria gate — e.g., research-paired-with-decision artifacts that document a choice without naming what would have been surprising or what alternatives lost.

### F4. Two-axis review via parallel sub-agents

Per matt's in-progress `review` SKILL.md: review runs Standards (does code conform to documented standards?) AND Spec (does code implement the originating issue/PRD?) as two parallel sub-agent calls in a single message. Results are presented under `## Standards` and `## Spec` headings, NOT merged. Rationale stated explicitly: a change can pass one axis and fail the other; merging would let one mask the other.

**Why this matters for bocek:** bocek's review primitive is single-axis (vault compliance). Adding a Standards-axis (read `CONTEXT.md` + `docs/adr/` or vault entries + `idioms/*.md` + lint configs) catches drift the vault doesn't cover (typescript idiom violations, naming inconsistency against project vocabulary). Parallel-sub-agents pattern prevents context pollution and is a real architectural pattern, not a tactical detail.

### F5. Diagnose's "feedback loop is the skill" framing

Per matt's `diagnose/SKILL.md` Phase 1: "Build a feedback loop. This IS the skill. Everything else is mechanical. If you have a fast, deterministic, agent-runnable pass/fail signal for the bug, you will find the cause — bisection, hypothesis-testing, and instrumentation all just consume that signal. If you don't have one, no amount of staring at code will save you." Followed by 10 ranked construction methods.

**Why this matters for bocek:** bocek's debugging primitive is evidence-first (reads `references/debugging/trace-protocol.md`) but doesn't enumerate loop-construction methods. Matt's framing is sharper because it makes the loop the *unit of debugging work*, not a precondition to debugging work.

### F6. TDD vertical-not-horizontal rule

Per matt's `tdd/SKILL.md`: "DO NOT write all tests first then all implementation." The rule is named, falsifiable, and language-agnostic. Tracer-bullet protocol: one test → minimal impl → one more test → minimal impl. Refactor only after all tests in the slice pass.

**Why this matters for bocek:** bocek's implementation primitive doesn't address TDD discipline at all. The rule is short (~80 lines of doc) and would map cleanly onto a `references/implementation/tdd-vertical.md` file.

### F7. Lazy doc creation + inline update during conversation

Per matt's `grill-with-docs/SKILL.md`: "Create documentation lazily — only when you have something concrete to capture. Capture resolved terms in CONTEXT.md as they emerge, not in batches. Reserve ADRs only when all three [criteria] apply."

**Why this matters for bocek:** bocek's design sessions batch decisions to the end of the session. Matt's pattern updates `CONTEXT.md` inline as terms resolve, which prevents the "I had it five turns ago, now I've drifted" failure mode.

### F8. The PreToolUse enforcement hook is bocek's moat

> **CORRECTED in deep-read pass.** The v1 framing — *"no analog to bocek's PreToolUse enforcement"* — was wrong. Matt's `misc/git-guardrails-claude-code` IS a PreToolUse hook (`scripts/block-dangerous-git.sh`, copied to `.claude/hooks/` and wired via `.claude/settings.json`, exit-code-2 blocks dangerous git commands like `push`, `reset --hard`, `clean`, `branch -D`, `checkout`, `restore`). The enforcement *primitive* exists in matt's repo. The moat is **the scope of enforcement** — mode-mutex (one active mode determines what's allowed) — not the *existence* of PreToolUse hooks. Matt's hook is command-blocklist-shaped (blocks specific git commands at any time); bocek's is mode-state-shaped (blocks source writes if and only if `.bocek/mode` says reasoning). Different mechanism class, both PreToolUse. The take-list still rejects composable-skills distribution because that *would* eliminate the mode-state needed for bocek's hook to work — but the rejection's reasoning is "you'd lose mode state," not "matt has no enforcement primitives."

Cross-reference inference: matt's `git-guardrails-claude-code` skill (in `misc/`) is the *only* enforcement-shaped artifact in his whole system, and it only blocks dangerous git commands, not source writes. Matt's system depends on the model voluntarily reading and following SKILL.md content. **There is no analog to bocek's PreToolUse enforcement.** This is the architectural property bocek must preserve, even while stealing tactical patterns.

## Conflicts

### ADR pattern vs. vault model

Matt's published ADR doctrine is structurally identical to what bocek's deleted `docs/decisions/0003-vault-as-knowledge-graph.md` had — lazy creation, paragraph minimum, status frontmatter only on revisit, three-criteria gate. The user position recorded during this design session is that ADRs hit a scaling wall (bokchoy had 23 ADRs in `docs/decisions/` before migrating to vault-style; the wall manifested as "endless flow of ADRs" with no shared vocabulary or cross-feature graph) and the vault model is the next rung on the maturity ladder. **Matt is operating one rung below bocek's current architecture, not above it.** Treat his ADR pattern as informative-not-authoritative: it works because matt's projects haven't hit the wall yet.

### Composable skills vs. modal enforcement

Both are defensible architectures with incompatible trade-offs. Composable wins on flexibility (skills compose freely, à la carte adoption); modal wins on enforcement (the hook can know what mode is active because there IS only one active mode). Bocek must choose modal; matt chose composable. The choice is binary at this layer — there is no hybrid.

### "Standards" as a review axis vs. "vault compliance" as a review axis

Matt's Standards axis reads `CONTEXT.md` + ADRs + style configs as standards sources. Bocek's review axis reads vault entries. **These are not the same artifact set.** Matt's standards include implicit project conventions (`CLAUDE.md`); bocek's vault includes explicit decisions. The right move for bocek is to ADD a Standards axis without removing the vault-compliance axis — they cover different drift classes. Per *Contradiction protocol*, this is reconciled by superset-union, not by picking one.

## Conditions

These findings apply when:

- The methodology system runs inside Claude Code (matt's distribution model is CC-specific; portability to other coding agents is unverified).
- The team treats markdown as the authoritative artifact (not a wiki, not a SaaS knowledge base).
- The model is expected to read documentation files on each session start (matt's system depends on this; if Claude Code's behavior changes around session-start file loading, the architecture is invalidated).

These findings BREAK when:

- The project's scale exceeds what matt's single-author workflow has been tested at. Matt's repo is one engineer's daily-use directory; production-team adoption may surface different failure modes.
- Enforcement becomes a requirement. Composable skills cannot enforce against the model in a way that survives the model deciding to skip a skill — only PreToolUse hooks can do that, and they require global state matt's system doesn't have.

## Operational implications

For the immediate decision in this session:

- **`[[research-subfolder]]`'s rejection of Option (a) "fold inline like matt"** — confirmed defensible. Matt's pattern fits matt's scale and his ADR-style decision shape; bocek operates at a different rung where research is durable, cross-cited evidence.

For follow-up design sessions:

- **Take F2 (CONTEXT.md), F4 (two-axis review with parallel sub-agents), F5 (diagnose feedback-loop framing), F6 (TDD vertical-not-horizontal), F7 (lazy doc creation + inline update), F3 (ADR-style three-criteria gate folded into bocek's vault-or-don't gate).** Each gets its own design session and vault entry.
- **Skip F1 (composable distribution)** — incompatible with enforcement hook.
- **Skip caveman mode** — conflicts with bocek's calibration (precise pushback, no hedging).
- **Skip PRD/issues/triage pipeline (`to-prd`, `to-issues`, `triage`)** — out of scope for bocek's vault-centric persistence model.
- **Defer `prototype`, `handoff`, `improve-codebase-architecture`'s "deep modules"** — real value but adds primitive surface area; revisit after the cheaper steals land.

## Reproducibility note

Reproducible. Steps:

1. `gh search repos --owner mattpocock --json name,description,stargazersCount` to confirm repo exists.
2. `gh api repos/mattpocock/skills/git/trees/main?recursive=1 --jq '.tree[] | select(.type=="blob") | .path'` for full file listing.
3. For each SKILL.md path, `gh api repos/mattpocock/skills/contents/{path}` or `WebFetch https://raw.githubusercontent.com/mattpocock/skills/main/{path}` retrieves content.
4. The findings above are extractions, not interpretations — another investigator reading the same files reaches substantially the same F1-F8 (production-cited within the survey itself; reproducible).

Caveat: the *bocek-applicability mapping* (the "Why this matters for bocek" paragraphs under each finding) is judgment, not reproduction. A different reviewer with different priors about bocek's architecture might prioritize differently. Calibration: high for the findings themselves, medium for the applicability mapping.

## Open threads

- **BMAD / GSD / Spec-Kit comparison.** Matt's README names these as the methodology systems his skills are an alternative to. Reading at least one would close the contradiction-probe channel. Without it, this entry remains `provisional: true`.
- **Production-team adoption signal.** 81k stars is adoption-as-aspiration, not adoption-as-use. Are there public posts from teams (not solo developers) running matt's skills in production? Either would change confidence on F1 / F3 / F4.
- **The "exact application" gap in `[[research-subfolder]]`'s Industry-standard gate.** That entry's Production-grade gates flagged the type-class-routed subfolder hide as inferred-medium. A survey of Obsidian power-user vaults at >100-note scale + at least one other knowledge-base tool (Logseq? Foam? Roam?) would either confirm or falsify the pattern.
- **The lazy-compile gap in bocek.** Identified in `[[vault-scale-audit-bokchoy]]` finding 6 — `.compiled/` never generated. Needs trace through `primitives/implementation.md` to find the exact instruction the model skips at scale. Not in scope for this entry but flagged as adjacent research. **Resolved 2026-05-14 by `[[discovery-compile-instruction-lacks-output-path]]` + `[[compile-step-rent-research]]` + `[[compile-removal]]`** — the cache concept was removed entirely after research showed it didn't pay rent.

---

## Deep-read pass (2026-05-14)

The remaining 13 SKILL.md files + 8 Tier-A supporting files were read in a second research session. Sources added to *Sources examined* by reference (full content captured in conversation, not duplicated here for vault economy — reproducible via the URLs at the bottom of this update).

### Files added to the survey

**SKILL.md (13):** `misc/git-guardrails-claude-code`, `misc/migrate-to-shoehorn`, `misc/scaffold-exercises`, `misc/setup-pre-commit`, `personal/edit-article`, `personal/obsidian-vault`, `in-progress/writing-beats`, `in-progress/writing-fragments`, `in-progress/writing-shape`, `deprecated/design-an-interface`, `deprecated/qa`, `deprecated/request-refactor-plan`, `deprecated/ubiquitous-language`. All current as of HEAD on `main`, observed 2026-05-14.

**Supporting (8):** `engineering/improve-codebase-architecture/{DEEPENING,INTERFACE-DESIGN,LANGUAGE}.md`, `engineering/tdd/{deep-modules,interface-design,mocking,refactoring,tests}.md`.

**Not pulled (and why):** `engineering/triage/{AGENT-BRIEF,OUT-OF-SCOPE}.md`, `engineering/prototype/{LOGIC,UI}.md`, `engineering/setup-matt-pocock-skills/{domain,issue-tracker-*,triage-labels}.md` (5 files), `.out-of-scope/*` (3 files), shell scripts. These are operational templates and config substitutions, not architectural patterns; they won't change the take-list. If the user later wants to lift the *triage agent-brief format* or the *prototype LOGIC/UI split* directly, fetch them then.

### Deep-read findings (F9-F13)

#### F9. Matt's architectural vocabulary in `LANGUAGE.md` is more original than v1 credited

`improve-codebase-architecture/LANGUAGE.md` defines 8 precise terms (**Module**, **Interface**, **Implementation**, **Depth**, **Seam**, **Adapter**, **Leverage**, **Locality**) AND explicitly *rejects* Ousterhout's original "depth = ratio of implementation-lines to interface-lines" framing in favor of "depth = leverage at the interface." Direct quote: *"Depth as ratio of implementation-lines to interface-lines (Ousterhout): rewards padding the implementation. We use depth-as-leverage instead."* (production-cited; high). This is genuine refinement of the canonical source, not a derivation. The vocabulary is reusable and could be lifted as a `mental-models/software-design.md` entry in bocek — bocek has 6 domain mental models (auth, api-design, data-layer, distributed-systems, frontend, state-management) and zero foundational software-architecture model. **Bigger gap than v1 surfaced.**

#### F10. Parallel sub-agents for position derivation — pattern is in TWO skills

The v1 survey noted *"design-it-twice via parallel sub-agents"* under `deprecated/design-an-interface` as a candidate take. Deep-read reveals the pattern is **kept alive** in the active `improve-codebase-architecture/INTERFACE-DESIGN.md` — same Task-tool-spawned 3-4 parallel sub-agents, each given a different optimization constraint (minimize-method-count / maximize-flexibility / optimize-common-case / ports-and-adapters), each producing a complete interface design independently. Deprecation of `design-an-interface` wasn't *rejection* of the pattern — it was *subsumption* into the larger architecture skill. **Pattern is matt's load-bearing position-derivation discipline; it appears in BOTH versions of his interface-design workflow** (production-cited; high). Bocek's design primitive Position Derivation requires "at least three positions" but in practice derives sequentially via single-model reasoning. Parallel sub-agent derivation would enforce breadth more reliably and combat mode-collapse to the most-common training-data pattern.

#### F11. Seam discipline + dependency taxonomy from `DEEPENING.md`

Two specific rules emerge:

- **"One adapter is a hypothetical seam. Two adapters means a real one."** Don't introduce a port/interface boundary unless ≥2 adapters exist (typically production + test). Single-adapter seams are just indirection (production-cited; high).
- **4-category dependency taxonomy:** (1) In-process (always deepenable, no adapter), (2) Local-substitutable (e.g. PGLite, in-memory FS — deepenable with stand-in), (3) Remote-but-owned (ports & adapters), (4) True external (mock at boundary). Determines how the deepened module is tested across its seam.

Bocek's refactoring primitive references behavior-preservation but doesn't have this specific seam-discipline. Could go into `references/refactoring/seam-discipline.md` or a `mental-models/software-design.md` entry alongside F9 vocabulary.

#### F12. TDD reference layer is much richer than v1 captured

The TDD SKILL.md is supported by 5 references (`deep-modules`, `interface-design`, `mocking`, `refactoring`, `tests`). The lifeable rules:

- **"Tests assert on observable outcomes through the interface, not internal state."** Mocking internal collaborators is the canonical bad-test pattern (production-cited; high).
- **"Mock at system boundaries only."** External APIs, sometimes databases, time/randomness, sometimes filesystem. Don't mock your own classes.
- **"Prefer SDK-style interfaces over generic fetchers."** Each operation gets its own function, not one `fetch(endpoint, options)` with internal conditionals. Mocks become per-endpoint, no conditional logic in test setup.
- **"Accept dependencies, don't create them"** + **"Return results, don't produce side effects"** as interface-testability rules.

Take D (originally "TDD vertical-not-horizontal" — small reference at `references/implementation/tdd-vertical.md`) is now a much bigger reference set. Could be a single `references/implementation/tdd.md` covering all the rules, or split into multiple files matching matt's organization.

#### F13. `personal/obsidian-vault/SKILL.md` confirms matt's vault model is exactly what bocek outgrew

Matt's personal Obsidian vault: *"Mostly flat at root level. No folders for organization - use links and index notes instead. Title case for all note names."* This IS the failure mode bocek's `[[mandatory-feature-folders]]` decision corrects (ADR-0003's flat-graph philosophy). Combined with `grill-with-docs/ADR-FORMAT.md` (paragraph-length ADRs, lazy creation, three-criteria gate) — matt's architecture is *intentionally* at the rung below bocek's vault model. **Independent confirmation of the user's defense from earlier in this design pass:** *"the adr i had them before matt did his skills i outgrew them and moved to a vault style like obsidian which i need to polish its better than having and endless flow of adrs."* (production-cited; high). The user's position is now triangulated against matt's own published architecture.

### Take-list revisions after deep-read

**Updates to existing takes:**

- **Take A (`CONTEXT.md`).** Strengthened by F2-doubled. The pattern shipped twice (deprecated `ubiquitous-language` and current `grill-with-docs/CONTEXT-FORMAT.md`). Keep at priority 1.
- **Take C (Diagnose feedback-loop framing).** Unchanged.
- **Take D (TDD vertical-not-horizontal).** **Substantially widened** by F12. Originally a one-rule reference; now a 5-rule reference set covering vertical-not-horizontal, mock-at-boundaries-only, SDK-style-over-generic-fetcher, dependency-injection, return-results-not-side-effects. Decide: one big reference or split into multiple files.
- **Take E (ADR three-criteria gate).** Unchanged.
- **Take F (Vertical slicing).** Unchanged.
- **Take G (Lazy doc creation).** Unchanged.

**New takes from deep-read (H, I, J):**

- **Take H (architectural vocabulary).** Adopt matt's Module / Interface / Implementation / Depth / Seam / Adapter / Leverage / Locality vocabulary as a bocek `mental-models/software-design.md` entry. Cite the LANGUAGE.md provenance; refine where bocek's context differs. Bocek currently has zero foundational software-design mental model — this fills the gap. **Priority: high, low cost.**
- **Take I (parallel sub-agents for position derivation).** Amend `primitives/design.md`'s Position Derivation protocol to support — or require, for system-shaped decisions — parallel sub-agent generation of 3+ design positions. Each sub-agent gets a different optimization constraint. Run via Task tool. Reduces mode-collapse to most-common training pattern. **Priority: medium, medium cost** (requires sub-agent tooling integration in the primitive's instructions, plus a reference on how to brief each sub-agent).
- **Take J (seam discipline).** Add the one-adapter-hypothetical / two-adapters-real rule + the 4-category dependency taxonomy to bocek's refactoring primitive (or to the F9-derived software-design mental model). **Priority: medium, low cost** (one short reference).

**Skip-list additions from deep-read:**

- All 4 `deprecated/*` skills as stand-alone takes (their useful patterns are already in active skills). Reading them confirmed nothing new beyond the F10 parallel-sub-agents pattern.
- All 4 `misc/*` skills (`migrate-to-shoehorn`, `scaffold-exercises`, `setup-pre-commit`, `git-guardrails-claude-code`). `git-guardrails` informs the F8 correction but isn't itself a take — bocek already has the enforcement primitive.
- `personal/edit-article`. Tactical article editing, no architectural transfer.
- `personal/obsidian-vault`. Informs F13 confirmation but the architecture itself is what bocek outgrew.
- All 3 `in-progress/writing-*` skills. Writing-domain methodology, not coding-methodology — out of bocek's scope.

**Revised priority order for design sessions:**

1. **Take A (CONTEXT.md)** — biggest scope, biggest payoff, enables Takes B/F9-related work.
2. **Take H (architectural vocabulary)** — new from deep-read; low cost; fills the software-design mental-model gap.
3. **Take G (lazy doc creation rule)** — trivial; one sentence amendment.
4. **Take E (ADR three-criteria gate)** — small; one gate in design primitive.
5. **Take J (seam discipline)** — new from deep-read; one short reference.
6. **Take C (diagnose feedback-loop framing)** — medium; restructures debugging primitive's trace-protocol.
7. **Take D (TDD reference layer)** — newly widened; medium-to-large depending on split-vs-bundle.
8. **Take B (two-axis review)** — depends on Take A landing first for the standards-axis to have CONTEXT.md to read.
9. **Take F (vertical slicing)** — small; one reference.
10. **Take I (parallel sub-agents)** — medium; design-primitive amendment + Task-tool brief reference.

### Provisional flag status

**Still `provisional: true`.** The contradiction-probe channel (BMAD / GSD / Spec-Kit comparison) remains empty. Deep-read thickened the matt-side coverage substantially but did not close the contradiction channel. Closing it requires reading at least one of those competitor frameworks and noting where their architectural choices diverge from matt's. Open thread #1 in the original *Open threads* section still stands. Provisional flag drops when that thread closes.
