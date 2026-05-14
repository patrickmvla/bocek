---
type: discovery
features: [_shared]
related: ["[[vault-scale-audit-bokchoy]]", "[[research-subfolder]]"]
created: 2026-05-14
confidence: high
---

# Discovery: the `/implementation` primitive's "compile" instruction names no write-target, so `.compiled/{feature}.md` is never produced regardless of how many implementation sessions run

## Found during

`/debugging` session investigating bokchoy's absent `.compiled/` directory, per `[[vault-scale-audit-bokchoy]]` F7. The audit hypothesized "prose instruction the model skips at scale" with `confidence: inferred, medium` — debugging traced through the actual primitive text to find the load-bearing mechanism. Reproduction signal: `ls ~/audhd/bokchoy/.bocek/vault/.compiled/` returns `No such file or directory`, while bokchoy's `state.md` shows multiple implementation seats have landed work (`"Cockpit slice 8.3.6 landed 2026-05-14 (prior implementation seat)"`, `"M-1 + M-2 + M-3 LANDED"`).

## Failure lenses that surfaced this

- **Input shape** — model session in `/implementation` mode against any feature folder containing vault entries; this is the steady-state activation for the mode.
- **Side effects in flight** — the primitive's *intent* is for `.compiled/{feature}.md` to be written as a derived cache artifact. Observed: no file is written. No partial state, no rollback — the side effect simply never starts.
- **Concurrency state** — N/A (single-session phenomenon).
- **System load** — N/A (failure is deterministic, not load-dependent).
- **Timing window** — deterministic. Failure manifests on every `/implementation` session, regardless of vault size.
- **Data state** — feature folder contains vault entries; `.bocek/vault/.compiled/` does not exist. The state at failure-time is the same as the state at session-start.

## Discovery

The implementation primitive specifies the *existence* of `.bocek/vault/.compiled/{feature}.md` as a cache artifact but **never specifies a directive for the model to write it.** All three places the primitive mentions compile use input-direction phrasing ("compile from", "from the compiled vault or the human vault entry"). None contain a write-target verb (no "write to", "create", "produce", "save", "synthesize-and-save-at"). The model reads "compile from `.bocek/vault/{feature}/*`" as a synthesize-in-context-window directive — the natural LLM interpretation, given that "compile from X" in training data almost universally means "consume X for understanding," not "produce derived artifact at Y."

Under this reading the model:

1. Sees no `.bocek/vault/.compiled/{feature}.md` exists.
2. Reads `.bocek/vault/{feature}/*` directly per the "otherwise compile it from" branch.
3. Forms internal understanding of the feature's contracts and decisions.
4. Proceeds to write code.

Step 3 never has a "write the synthesis to disk at PATH" sub-step. The cache target is named in the primitive's prose but never connected to a file-write tool invocation. The cache file does not exist because nothing in the primitive ever instructs anyone to create it.

This is sharper than `[[vault-scale-audit-bokchoy]]` F7's framing ("prose instruction the model skips"). The model isn't skipping an instruction — **there is no instruction with the right shape to either follow or skip.** Promoting that finding's confidence from `inferred, medium` to `production-cited, high`.

## Root cause classification

**Design gap in the implementation primitive.** The primitive specifies the conceptual existence of `.compiled/{feature}.md` (and `references/shared/vault-format.md` calls it the "gitignored compiled file") without specifying *when* and *by whom* it gets written. The cache file's lifecycle was never made executable.

Two valid resolutions exist (queued for `/design` to choose):

1. **Make the instruction explicit in prose.** Change `implementation.md:25` to include a write directive: *"If `.compiled/{feature}.md` is not present: read every file in `.bocek/vault/{feature}/*`, synthesize them into a single markdown file, **write the result to `.bocek/vault/.compiled/{feature}.md`**, then proceed."* Same enforcement class as the path-convention rule was before `enforce-mode.sh` — prose doctrine, model-interpretation-dependent.

2. **Push the compile into a script.** Add a `bocek vault compile <feature>` subcommand to `scripts/bocek` that walks the feature folder, concatenates entries with frontmatter intact, and writes the result to `.compiled/{feature}.md`. The implementation primitive invokes the script explicitly via Bash. Compile becomes a deterministic operation: it either succeeds and writes the file, or fails with an error. Same enforcement-in-code pattern as the path-convention's `enforce-mode.sh` solution. This is `[[vault-scale-audit-bokchoy]]`'s polish #6, already queued in state.md.

Option 2 is the load-bearing answer. Option 1 inherits the exact "doctrine without enforcement" failure pattern the bocek project keeps re-deriving — the path-convention rule, the `_shared/` misclassification gate, the lazy-compile instruction itself. Every time the rule lives only in prose, the model drifts on it.

## Engineering substance touched

- **Operability:** the cache file's lifecycle was never specified in directive form. Reading the rule means reading three different prose mentions across primitive + reference + spec, none of which name the write step. When the rule needs to change, no single file changes — the bug is *the absence of a load-bearing instruction*, not the misstatement of one.
- **Observability:** if the model believes it has "compiled" the vault into its context window, but no `.compiled/` file ever materializes, an outside observer (the human, another mode, a `/review` pass) has no way to detect whether the compile step happened. The contract between the implementation primitive and the rest of bocek is silently broken every session.

## Impact on existing decisions

- **`[[vault-scale-audit-bokchoy]]` F7** — sharpened from `inferred, medium` to `production-cited, high`. Earlier framing said "prose instruction the model skips"; corrected framing is "instruction has no write-target, so there is nothing for the model to skip or follow." The polish #6 ranking in that entry's *Operational implications* (lazy-compile becomes a script) stands; the *reason* it's the right fix is now traceable to this discovery's evidence.
- **`[[mandatory-feature-folders]]`** — not affected. The `.compiled/` directory's path layout is correct in the path-convention spec; the bug is only in the *instruction to write* that file, not in where it should live.
- **`[[research-subfolder]]`** — not affected directly, but adjacent: when the compile script lands per Option 2 above, it has to decide whether `.compiled/{feature}.md` includes content from `.research/*.md` or excludes it. That's an open thread already named in `[[vault-scale-audit-bokchoy]]`'s open threads section.
- **`primitives/implementation.md`** (the source artifact, not a vault entry) — owes an amendment in the next `/design` session. The amendment text depends on which fix option `/design` picks.
- **`references/implementation/contract-following.md`** — same. Line 8's "Pull the exact constraint from the compiled vault or the human vault entry" inherits the ambiguity; if the fix is the script approach, this prose should say "Pull from `.compiled/{feature}.md` (regenerated by `bocek vault compile {feature}` on each implementation session activation)" — making the write a precondition the script enforces, not a conditional the model interprets.

## Evidence

The three load-bearing instructions in the codebase, quoted verbatim:

**`primitives/implementation.md:25`** (the only mention in the activation flow):

```
4. **Identify the feature being implemented.** If unclear, ask. The first thing you read
   after orientation is the vault entry for that feature — the compiled file at
   `.bocek/vault/.compiled/{feature}.md` if present, otherwise compile it from
   `.bocek/vault/{feature}/*` (per the *Path convention* in `references/shared/vault-format.md`).
```

**`primitives/implementation.md:118`** (the only mention in the operational flow):

```
1. **Before writing any function:** read the compiled vault entry
   (`.bocek/vault/.compiled/{feature}.md`; compile from human files if stale)
   → quote the contract → derive the implementation → pass the code lenses
   → attack the pick → then write.
```

**`references/implementation/contract-following.md:8`**:

```
Pull the exact constraint from the compiled vault or the human vault entry.
```

The three quotes contain: zero occurrences of "write to", zero of "create", zero of "produce", zero of "save". The verb "compile" appears 5 times across the three quotes — always in input-direction phrasing ("compile from", "the compiled file at", "the compiled vault"). The cache file is *named* but never *produced* by any directive.

Production evidence:

```
$ ls ~/audhd/bokchoy/.bocek/vault/.compiled/
ls: cannot access '/home/mvula/audhd/bokchoy/.bocek/vault/.compiled/': No such file or directory

$ grep -c "implementation seat\|/implementation\|landed" ~/audhd/bokchoy/.bocek/state.md
[multiple matches across state.md, including "Cockpit slice 8.3.6 landed 2026-05-14 (prior implementation seat)"]
```

Implementation seats landed work; `.compiled/` was never created. Deterministic.

## Reproduction

Deterministic, reproducible without any new infrastructure:

1. Pick any bocek-using project where `/implementation` has run at least once (e.g., `~/audhd/bokchoy/`).
2. `ls $PROJECT/.bocek/vault/.compiled/`
3. Observe: directory does not exist.

For a controlled reproduction in a fresh vault (recommended for confirming the diagnosis isn't bokchoy-specific):

1. `mkdir /tmp/test-bocek-compile && cd /tmp/test-bocek-compile && git init && bocek bootstrap` — accept defaults.
2. `/design` a single feature with one decision and one contract.
3. Acknowledge the vault entry via `/implementation`.
4. After the implementation seat completes any work, run `ls .bocek/vault/.compiled/`.
5. Expected per primitive intent: `.compiled/{feature}.md` exists.
6. Observed per this discovery: directory absent.

Falsification path: if anyone in any bocek-using project, on any model version, has observed `.compiled/{feature}.md` being auto-generated by `/implementation` without manual intervention, this discovery's hypothesis fails. Search across known bocek vaults welcome.

Anti-default check applied: the simplest scenario this hypothesis cannot explain is "a session where `.compiled/` DID materialize on its own." No such session has been observed in the production evidence to date. Hypothesis survives.
