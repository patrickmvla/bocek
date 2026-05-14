---
type: discovery
features: [_shared]
related: ["[[mandatory-feature-folders]]", "[[research-subfolder]]", "[[compile-removal]]", "[[context-md-as-vocabulary]]"]
created: 2026-05-14
confidence: high
---

# Discovery: `scripts/preflight.sh` silently fails to write `.bocek/mode` when its stdout is piped through a truncating command (SIGPIPE + `set -euo pipefail` aborts script before line 312)

## Found during

`/implementation` session landing 18 contracts across G1-G8 against the working tree. Mid-session, an `Edit` to `.gitignore` was rejected by the enforcement hook with *"research mode active. Source file writes are blocked."* despite the preceding preflight invocation (`bash ~/.bocek/scripts/preflight.sh implementation 2>&1 | head -8`) printing the banner *"Mode: research → implementation"*. Direct read of `.bocek/mode` confirmed the file still contained `research`. The preflight banner had lied about success. Workaround applied to unblock: `echo implementation > .bocek/mode`. Subsequent `/debugging` session built a deterministic feedback loop and confirmed the cause.

## Failure lenses that surfaced this

- **Input shape** — any invocation of `scripts/preflight.sh` whose stdout is piped through a truncating consumer (`head -N`, `awk` with early `exit`, `read` once, etc.) closes the consumer's read end after N lines.
- **Side effects in flight** — the mode-file write at line 312 (`echo "$MODE" > "$MODE_FILE"`) is a side effect the script intends to execute every invocation. Under the failure, it silently does not.
- **Concurrency state** — N/A (single invocation, single process).
- **System load** — N/A (failure is deterministic, not load-dependent).
- **Timing window** — precise: the first `echo` after the consumer closes its read end receives SIGPIPE.
- **Data state** — `.bocek/mode` retains its prior content. The enforcement hook reads the prior mode and blocks tools per the prior mode's rules.

## Discovery

`scripts/preflight.sh` is structured with `set -euo pipefail` at the top (line 9) and the mode-file write near the end (line 312, after ~50 prior `echo` statements that produce the orientation block). When a caller pipes the script's stdout through a truncating command, the truncator closes its read end after N lines. The first `echo` in preflight that attempts to write to the closed pipe receives `SIGPIPE` (signal 13, exit status 141). `set -e` treats this nonzero exit as a script failure and aborts. The mode-file write never executes. The closing banner (`echo "=== Mode set: ${MODE}..."` at line 322) also never executes — but callers reading only the first N lines don't notice its absence, and the consumer command (e.g. `head -8`) exits 0 successfully, so the caller has no signal that anything went wrong.

Per `Contradiction protocol` against the existing read-back verification at lines 314-319: that verification was added explicitly to catch silent mode-write failures, but it runs AFTER the write (at line 312) — under SIGPIPE, the read-back code path is also unreachable. The verification was load-bearing under a different failure model (write-completes-but-target-state-is-wrong) and does not help under this one (script-aborts-before-write).

## Root cause classification

**Implementation bug.** The script's design (write-at-end + `set -euo pipefail` + unbounded prior `echo`s) is incompatible with stdout truncation by the caller. Three valid fixes ranked by structural soundness:

1. **Move the mode-file write to the start of the script** (before any `echo` to stdout). The mode-write depends only on `$MODE` (line 11) and `$PROJECT_ROOT` (line 47); both are computable before any output. Post-write read-back verification stays. Pro: structurally eliminates the failure mode. Con: the orientation banner becomes informational only — if the script aborts mid-output, the mode is already written, which means failed orientations leave mode in a "newly set" state that may not match the caller's intent.
2. **Trap SIGPIPE around the echo block** with `trap '' PIPE` to make SIGPIPE non-fatal, and use a manual error check before the mode write. Pro: preserves write-at-end semantics. Con: subtler bash discipline, harder to audit later.
3. **Document the limitation** — add a comment that preflight output cannot be piped through truncating commands. Pro: zero code change. Con: doctrine without enforcement — exactly the failure pattern bocek keeps re-deriving (per `[[mandatory-feature-folders]]`, `[[discovery-compile-instruction-lacks-output-path]]`).

Fix decision is owed in a `/design` session. Option 1 is my prior — but the decision should pass through derivation properly. **Not redesigning here per debugging-mode discipline.**

## Engineering substance touched

- **Failure semantics:** the mode-write is intended at-least-once per invocation. Under SIGPIPE, it becomes at-most-never. The caller has no signal that the side effect didn't happen — the truncating consumer exits 0. Silent at-most-never is the worst failure semantics class because no caller-visible error fires.
- **Operability:** the script's existing read-back verification at lines 314-319 was designed to catch one failure model (file-write-succeeded-but-content-is-wrong) and is unreachable under the actually-observed failure model (script-aborted-before-write). Verification-where-the-failure-can-actually-happen is a separate concern.

## Impact on existing decisions

- **`[[mandatory-feature-folders]]`** — its enforcement (per the just-landed G4 `enforce-mode.sh` extensions) depends on `.bocek/mode` being current. Under this bug, mode lags, which means writes the user expects to be enforced by the CURRENT mode are instead enforced by a STALE mode. Not invalidating; it adds a known way to silently bypass the moat.
- **`[[research-subfolder]]`, `[[compile-removal]]`, `[[context-md-as-vocabulary]]`** — each depends on the primitive's `On activation` reading the correct mode from preflight and applying the right discipline. Under the bug, the preflight's banner asserts a mode the file doesn't actually contain. Future sessions may proceed under stale-mode disciplines without noticing.
- **No vault decision is invalidated.** All affected entries assume preflight is reliable. The fix restores that assumption.

## Evidence

```
$ echo "idle" > .bocek/mode && cat .bocek/mode
idle

# Test A — preflight WITHOUT pipe truncation
$ bash scripts/preflight.sh review >/dev/null 2>&1
$ cat .bocek/mode
review                # ✓ write succeeded

# Test B — preflight WITH pipe truncation (8 lines)
$ echo "idle" > .bocek/mode && cat .bocek/mode
idle
$ bash scripts/preflight.sh review 2>&1 | head -8 > /dev/null
$ cat .bocek/mode
idle                  # ✗ write blocked; mode unchanged
```

`scripts/preflight.sh:9` — `set -euo pipefail`
`scripts/preflight.sh:49-308` — ~50 `echo` statements producing the orientation block
`scripts/preflight.sh:312` — `echo "$MODE" > "$MODE_FILE"` — the unreached side effect
`scripts/preflight.sh:314-319` — read-back verification (also unreached)
`scripts/preflight.sh:322` — closing banner (also unreached)

## Reproduction

Deterministic, no environment requirements beyond bash + bocek installed:

```bash
echo "idle" > .bocek/mode                                   # set known state
bash scripts/preflight.sh review 2>&1 | head -8 > /dev/null  # invoke with truncation
cat .bocek/mode                                              # expect: idle (bug); actual: idle (bug confirmed)
```

Compare:

```bash
echo "idle" > .bocek/mode                                   # set known state
bash scripts/preflight.sh review > /dev/null 2>&1           # invoke without truncation
cat .bocek/mode                                              # expect: review; actual: review
```

The bug manifests for any truncating consumer:
- `head -N` for any N less than the full output length (currently ~50 lines, so `head -50` or less)
- `awk '...exit...'`
- `read` (consuming a single line)
- A pipe to a process that crashes before reading all output

Verified at HEAD on `main` of `~/audhd/bocek/scripts/preflight.sh` (working tree) as of 2026-05-14. The installed copy at `~/.bocek/scripts/preflight.sh` has the same structure and the same bug.
