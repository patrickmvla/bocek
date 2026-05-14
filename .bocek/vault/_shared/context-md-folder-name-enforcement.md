---
type: decision
features: [_shared]
related: ["[[context-md-as-vocabulary]]", "[[mandatory-feature-folders]]", "[[research-subfolder]]", "[[vault-scale-audit-bokchoy]]"]
created: 2026-05-14
confidence: high
---

# Enforce CONTEXT.md term-match for new feature folders at write time (Option B — boundary)

## Decision

`scripts/enforce-mode.sh` is extended so that writes which would *create a new feature folder* under `.bocek/vault/` are rejected unless the folder name matches a `**Term:**` header in `.bocek/vault/CONTEXT.md`. Once a feature folder exists (parent directory present on disk), subsequent writes are unrestricted — the gate fires only at folder-creation time. This is **Option B (boundary enforcement)** from D1's design space, resolving the sub-decision 7 deferred in `[[context-md-as-vocabulary]]`.

### Three sub-decisions, settled

**Match rule (B-i): exact slugified match.** Folder name lowercased and dash-or-space-normalized must equal a `**Term:**` header in `CONTEXT.md` lowercased and dash-or-space-normalized. Folder `wallet/` matches `**Wallet:**`. Folder `loot-rng/` matches `**Loot RNG:**` or `**Loot-RNG:**` (both slugify to `loot-rng`). Term aliases on `_Avoid_` lines do NOT count — those are documented anti-patterns, not authorized names.

**"New folder" detection (B-ii): parent directory doesn't exist.** The hook checks `[ -d "$parent_dir" ]` on the target path's parent. If the parent feature folder doesn't exist on disk yet, this write would create it — check CONTEXT.md. If the parent already exists, allow the write. Detection is by filesystem state, not by counting prior entries (cleaner, no concurrent-write race).

**Exemptions (B-iii):**
- `_shared/` — cross-feature escape hatch; not a feature, no term required (per `[[mandatory-feature-folders]]`).
- `.research/` subfolders — inherit the parent feature's term; the parent feature is what gets checked (and is necessarily already created since `.research/` is a child).
- `index.md`, `CONTEXT.md` — top-level vault meta; already exempt by P4 (per `[[mandatory-feature-folders]]`).

### Hook output shape

On denial, the message names the missing term and the file to edit:

> *"Feature folder `wallet/` has no matching term in `.bocek/vault/CONTEXT.md`. Add a `**Wallet:**` definition (or matching slug) to CONTEXT.md before creating the folder. Per `[[context-md-folder-name-enforcement]]`."*

The model parses the message, writes the term, retries the original write. Two tool calls per new feature is the friction cost.

## Reasoning

The deferred sub-decision 7 from `[[context-md-as-vocabulary]]` was *do feature-folder names have to match a CONTEXT.md term entry?* — and if so, via what mechanism. Four positions were derived:

- **Option A (strict)** — block all writes to any folder without a matching term, including existing folders if their term gets dropped. Rejected: high friction for mid-feature work; renames produce temporary out-of-sync windows that block all writes (production-cited within this derivation; medium — friction cost unverified but reasoning is sound).
- **Option B (boundary)** — block only at folder-creation time. Existing folders grandfathered. (Selected.)
- **Option C (soft)** — `/review` flags drift; no write-time enforcement. **Dominated.** This is the doctrine-without-enforcement pattern bocek has rejected FOUR times in the present session: path convention (corrected by G4 P4), `_shared/` discipline (mitigation 2 in `[[mandatory-feature-folders]]`, still unimplemented), lazy-compile (`[[discovery-compile-instruction-lacks-output-path]]` + `[[compile-removal]]`), SIGPIPE preflight (`[[preflight-sigpipe-fix]]`). Self-discipline plus periodic review has failed every time (production-cited within bocek; high — four independent observations).
- **Option D (none)** — no link between folder names and CONTEXT.md. **Dominated.** Defeats the purpose of CONTEXT.md as a structural anchor; doesn't address the `architecture/`-as-junk-drawer failure mode that motivated `[[context-md-as-vocabulary]]` per `[[vault-scale-audit-bokchoy]]` F3.

**Option B beats Option A** on the friction-when curve. The failure mode this enforces against — feature folders proliferating with generic/junk-drawer names (bokchoy's `architecture/` with 39 mixed entries) — manifests at *folder creation*, not at mid-feature work. A's strictness adds friction across the lifetime of the feature folder for no additional protection beyond B's. Specifically, A would block writes to existing `wallet/` if a developer renamed the term in CONTEXT.md to `**Account-Wallet:**` mid-refactor; B allows them to fix CONTEXT.md and folder name in any order (production-cited within this derivation; high — A's failure mode is concrete and predictable).

**Option B's structural correctness:** at the moment a new feature folder is created, the developer (or model) is necessarily naming the feature. Pausing to also name it in CONTEXT.md is exactly the discipline `[[context-md-as-vocabulary]]` was designed to enforce. The friction is the discipline, not a side-effect of it.

The two-tool-call cost (write CONTEXT.md term, then retry feature-folder write) is bounded and predictable. Bokchoy's lifetime feature folder creation rate is ~5 folders across ~3 months — one new folder per ~3 weeks. The friction is negligible at this rate (production-cited within bokchoy; medium — N=1 project).

## Engineering substance applied

- **Operability:** the gate fires in `enforce-mode.sh`, the same single-source enforcement file P4 and R4 already use. One location for path-convention rules. The denial message includes the specific term to add, so the fix is self-evident from the error.
- **Failure semantics:** new-folder writes are at-most-once-per-attempt; either the term exists and the write succeeds, or the write is rejected with a clear pointer. No silent failure. The two-tool-call retry pattern is the same shape as the existing G4 path-shape rejections.
- **Observability:** the denial message explicitly references this decision (`[[context-md-folder-name-enforcement]]`) so a future reader has a single jump from the error to the rationale.
- **Concurrency:** parent-directory-existence check uses filesystem state, not entry counting. No race between parallel writes attempting to create the same folder — both would see "doesn't exist" and check CONTEXT.md; both would either succeed (term exists, both create folder, idempotent `mkdir -p`) or fail (term missing, both rejected with same message). No corruption surface.

## Production-grade gates

- **Idiomatic** — write-time validation gates are the standard pattern for vocabulary-anchored structures: git pre-commit hooks validate commit message format against `CONTRIBUTING.md` conventions; SQL CHECK constraints validate column values against allowed-value lists; CI lint jobs reject PRs touching directories that don't match a configured allowlist. Bocek's `enforce-mode.sh` is doing the same shape with a different artifact (CONTEXT.md as the allowlist source) (production-cited; high — multiple independent stack precedents).
- **Industry-standard** — Two named systems with vocabulary-anchored structure enforcement: (1) Linux kernel's `MAINTAINERS` file is the authoritative map of subsystems → maintainers; commits touching files under a subsystem path must reference an existing MAINTAINERS entry, enforced by `get_maintainer.pl` + CI gates (publicly documented in `Documentation/process/`). (2) Many DDD-practicing codebases enforce that domain-entity class names match a `glossary.md` or `ubiquitous-language.md`'s term list, often via custom lint rules. Bocek's gate sits in the same class (production-cited for kernel; tier 4 for DDD-codebases; high overall for the pattern).
- **First-class** — uses the existing `enforce-mode.sh` hook layer that already implements P4 + R4 + frontmatter-type checks. No new file, no new mechanism. The match algorithm is awk + bash globbing — same shell-primitive vocabulary as the rest of the script.

## Rejected alternatives

### (A) Strict — block all writes to non-matching folders

**What:** the hook checks every Edit/Write inside `.bocek/vault/{feature}/...` against CONTEXT.md, not just new-folder writes. If CONTEXT.md drops a term that an existing folder corresponds to, all subsequent writes to that folder are rejected until the term is restored or the folder is renamed.

**Wins when:** the team values strict vocabulary discipline at all times, including mid-rename windows. Drift between folder names and vocabulary is unacceptable even temporarily.

**Why not here:** A's strictness adds friction across the lifetime of the feature folder for no additional protection beyond B's. The failure mode B was designed to prevent (folders proliferating with names not in the vocabulary) manifests at *folder creation* — once the folder exists with a matching term, subsequent renames are deliberate and rare. A's added mid-rename friction is friction without benefit.

### (C) Soft — `/review` flags drift; no write-time enforcement

**What:** `/review` mode's vault-compliance pass adds a check: for every feature folder, verify a matching CONTEXT.md term exists; flag mismatches as review findings. No `enforce-mode.sh` gate.

**Wins when:** the team self-disciplines around vocabulary; periodic review is sufficient to catch drift before it accumulates dangerously.

**Why not here:** **dominated** per the four-times-rejected doctrine-without-enforcement pattern within this session alone. The pattern's failure mode is consistent: prose-or-review-only rules are interpreted by the model and user idiosyncratically and drift on contact with scale. Self-discipline is what every Option-C-shape rule has assumed and what every Option-C-shape rule has failed at (production-cited within bocek; high — four independent observations).

### (D) None — no link between folder names and CONTEXT.md

**What:** CONTEXT.md is descriptive (readable by humans, surfaced in preflight) but not prescriptive. Folder names are unconstrained.

**Wins when:** vocabulary is decoupled from structure; the artifact exists for reader benefit only.

**Why not here:** defeats the purpose. `[[context-md-as-vocabulary]]` was vaulted partly to address `[[vault-scale-audit-bokchoy]]` F3 — the `architecture/`-as-junk-drawer failure mode — by giving the project an authoritative vocabulary. If folder names are decoupled from that vocabulary, the artifact doesn't constrain the failure it was designed to constrain. The decision degenerates to "we have a glossary now" without changing project-shape failure modes.

## Failure mode

**Bootstrap chicken-and-egg.** When `bocek bootstrap` runs, CONTEXT.md is scaffolded empty. The first `/design` session creates the first feature folder. Under Option B, this write is BLOCKED because the feature isn't in CONTEXT.md yet.

The friction manifests as: model resolves the first decision, tries to write `vault/{first-feature}/{slug}.md`, gets denied with *"Feature folder `{first-feature}/` has no matching term in CONTEXT.md."*, must write CONTEXT.md first, then retry.

This isn't a bug, it's the discipline working. But it's visible friction every bocek user will hit on their first feature. **The hook denial message must include the specific term name and target file path** so the fix is self-evident — that's why this decision specifies the exact denial format.

A secondary failure mode: **slug-match ambiguity.** If CONTEXT.md has both `**Wallet:**` and `**Wallets:**` (singular and plural), which one does folder `wallet/` match? Both slugify differently (`wallet` vs `wallets`), so under strict slugified-match, only `**Wallet:**` matches. Plural-only entries don't match singular folders. Predictable but possibly surprising.

## Mitigations

1. **Denial messages name the missing term and target file.** Per the *Hook output shape* example above — message includes folder name, expected `**Term:**` header, target file path. Fix is one Edit away.
2. **The design primitive's `On activation` already includes the path-convention reminder** (from P3 in G5). Future amendment: extend the reminder to also mention the CONTEXT.md term gate, so the model knows BEFORE attempting the write. Queues as **E2** below.
3. **`bocek bootstrap`'s scaffolded CONTEXT.md** can include a commented-out example term for whatever feature the user names during the interview (if they name one). Currently `bocek bootstrap` writes project-shape but doesn't seed CONTEXT.md with any term. This refinement is deferred — not in E1-E3 scope but worth flagging.
4. **Failure mode test in the smoke-test suite:** ensure that a first-feature write produces a clear, actionable denial. Queues as part of **E3**.

## Idiom citations

None — structural enforcement decision, not stack-specific.

## Revisit when

- **New-feature-folder creation rate exceeds ~5/week sustained** in a real bocek project. At that rate the two-tool-call overhead is meaningful friction; revisit either the gate (auto-add CONTEXT.md term?) or the workflow (a `bocek vault new-feature` command that does both writes atomically?).
- **A bocek user reports that the slug-match rule is too strict** (e.g. wants `wallet/` folder to match `**Wallets:**` plural term). At that point either relax the match algorithm (alias support, fuzzy-match) or document the convention explicitly.
- **A new vault entry type emerges** that creates a folder structure outside the `vault/{feature}/` shape (e.g. a future per-author or per-environment partitioning). The gate's "parent directory doesn't exist" trigger may need refinement.
- **`/review` mode adds Standards-axis** (per Matt-take B from `[[mattpocock-skills-survey]]`). Standards axis would naturally include the CONTEXT.md ↔ folder-name match check as one of its drift findings; coordinate so the same check doesn't fire from both write-time hook AND review-time pass.

## Implementation items queued

- **E1:** Add `check_feature_folder_match` function to `scripts/enforce-mode.sh`. Called from the Edit/Write handler after `check_vault_path` and `check_frontmatter_type_research`. Function: extract feature folder name from path; if parent directory doesn't exist; check CONTEXT.md for slug-match; deny with templated message if no match; allow otherwise. Skip if `_shared/`, `.research/`, or top-level meta.
- **E2:** Amend the design primitive's *On activation* (and possibly research / implementation primitives if they write feature folders) to mention the CONTEXT.md term gate. One-line addition to the path-convention reminder paragraph already in place from P3.
- **E3:** Smoke-test the E1 implementation across at least 6 scenarios: new folder without matching term → DENY; new folder with matching term → PASS; existing folder regardless of CONTEXT.md state → PASS; `_shared/` write → PASS; `.research/` subfolder write → PASS (inherits parent); bootstrap-empty-CONTEXT.md first-feature write → DENY with clear message.
