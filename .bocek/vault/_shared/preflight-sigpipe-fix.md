---
type: decision
features: [_shared]
related: ["[[discovery-preflight-mode-write-fails-under-sigpipe]]", "[[mandatory-feature-folders]]"]
created: 2026-05-14
confidence: high
---

# Relocate `scripts/preflight.sh` mode-write to the top of the script, before any echo

## Decision

`scripts/preflight.sh` is restructured so the mode-file write and its read-back verification execute immediately after `$PROJECT_ROOT` is resolved and BEFORE any `echo` to stdout. Specifically:

- Move the block currently at lines 310-319 (`mkdir -p "$PROJECT_ROOT/.bocek"`, `echo "$MODE" > "$MODE_FILE"`, read-back verification, exit-1-on-mismatch) to immediately after the `PROJECT_ROOT=$(find_project_root "${CLAUDE_PROJECT_DIR:-$PWD}")` line (currently line 47).
- The mode-validation case statement at lines 14-20 stays at the top — it must precede any use of `$MODE`.
- The closing banner at line 322 (`echo "=== Mode set: ${MODE}. Enforcement hook is active. ==="`) stays in place as an informational closing-line. It is no longer load-bearing for the side effect; it's decoration.

Result: every invocation of `preflight.sh` writes the mode file before producing any stdout output. If a caller pipes preflight's output through a truncating consumer (`head -N`, `awk` with early exit, etc.) and the resulting SIGPIPE aborts the script under `set -euo pipefail`, the mode-write has already happened. The silent at-most-never failure mode documented in `[[discovery-preflight-mode-write-fails-under-sigpipe]]` is structurally eliminated.

## Reasoning

Three fix options were enumerated in the discovery: (1) move mode-write to top, (2) trap SIGPIPE around the echo block to keep write-at-end, (3) document the limitation only. The discovery itself classifies as implementation bug; the design question is purely about fix shape.

**Option 3 is dominated.** Document-only is the exact "doctrine without enforcement" pattern bocek has rejected three times — first in `[[mandatory-feature-folders]]` for path conventions, then in `[[discovery-compile-instruction-lacks-output-path]]` + `[[compile-removal]]` for the cache concept, and most recently in `G4`'s `enforce-mode.sh` extensions for path-shape rules. The pattern's failure mode is consistent: prose-only rules are interpreted by the model (or user) idiosyncratically and drift on contact with scale. A documentation comment in `preflight.sh` saying "don't pipe through truncating commands" would be ignored or forgotten by exactly the callers most likely to truncate output (the model itself, when writing terse Bash invocations) (production-cited within bocek; high — three independent observations of the same failure pattern within this project).

**Option 1 beats Option 2 on the load-bearing sub-question** — what should happen when the truncation aborts the script mid-output?

- **Option 2's invariant** ("mode is set only when orientation completes"): preserves the all-or-nothing property. Under SIGPIPE, mode-write IS prevented; but the user has already seen the banner up to truncation, including the *"Mode: prior → current"* line. The user's mental model says they're in `current` mode; the file says `prior`. The hook enforces `prior`. **The silent-bug surface persists under Option 2.** Trap-SIGPIPE doesn't fix the practical problem; it preserves an invariant the user can't observe.
- **Option 1's invariant** ("mode-write is reliable"): mode file matches the user's invocation intent, regardless of consumer behavior. Truncation may obscure the orientation block, but the enforcement layer reads correct state. The slash command itself confirms intent (`/research` was typed); the banner is observability, not contract (production-cited within bocek; high — the implementation session that vaulted `[[discovery-...]]` observed the practical-correctness-over-invariant tension first-hand).

The fix is mechanical: $MODE and $PROJECT_ROOT are both available before any echo. The mode-validation case statement at lines 14-20 already runs before any output, so `$MODE` is known-valid by the time we reach $PROJECT_ROOT resolution. The relocation is a structural reorder, not a behavioral change beyond the bug fix.

## Engineering substance applied

- **Failure semantics:** mode-write moves from at-most-never (under truncation) to at-least-once (per invocation). Read-back verification stays adjacent to the write — if the write itself fails for other reasons (permissions, disk full), the script aborts with explicit stderr + exit 1 before producing any user-visible orientation, which matches the "fail loud, fail early" principle.
- **Operability:** silent failure mode eliminated. Pre-fix, a user truncating output saw the banner but got the wrong mode in the file; the hook enforced incorrectly without surfacing anything. Post-fix, mode is always correct; if the script aborts mid-orientation, the user sees a partial banner but the enforcement layer behaves consistently with the user's stated intent.

## Production-grade gates

- **Idiomatic** — standard bash pattern: do critical side effects first, output decoration second. Every shell script that's been hardened against SIGPIPE-under-pipefail (e.g. systemd unit scripts, CI orchestration scripts) follows this shape (production-cited; high — common pattern across the systems-shell ecosystem).
- **Industry-standard** — Two named systems with the same write-then-output pattern: `git` commands generally complete object-database writes before printing user-facing output for the same reason (production-cited per git internals docs); `cargo` writes lock-file mutations before printing build progress (docs-cited). The mechanism is universal at this layer.
- **First-class** — uses bash's normal execution order. No traps, no signal handlers, no `|| true` workarounds. The script's correctness becomes a function of statement order, which is the simplest possible invariant to audit.

## Rejected alternatives

### (2) Trap SIGPIPE around the echo block

**What:** Add `trap '' PIPE` at the top of the script (or after `set -euo pipefail`) to make SIGPIPE non-fatal. The mode-write stays at line 312. Add explicit error checking around the write to catch real failures vs. SIGPIPE-from-downstream.

**Wins when:** Preserving the "mode is set only when orientation completes" invariant has user-visible value AND the team accepts the additional bash discipline (trap behavior, careful audit of which signal classes are silenced).

**Why not here:** The invariant Option 2 preserves is not user-observable in the actual failure mode. Pre-fix under SIGPIPE, the user already sees a banner that asserts the new mode (truncated at line 8 of output, but including the *"Mode: prior → current"* line at line 2). So the user thinks they're in the new mode regardless. Option 2's invariant is theoretical; the practical correctness Option 1 provides is what the user needs.

### (3) Document-only

**What:** Add a comment to `preflight.sh` saying *"Caller note: this script writes the mode file at the end. Do not pipe its stdout through commands that close their read end early (head, awk with exit, etc.)."*

**Wins when:** The team has high tolerance for prose-only rules AND the caller population is small and disciplined.

**Why not here:** Bocek's caller population includes the model itself, which writes Bash invocations under varying instructions and is not naturally aware of script-internal SIGPIPE semantics. The model would (and did) write `bash preflight.sh ... | head -8` in this very session. Doctrine-without-enforcement has now failed three times in this project; expecting Option 3 to work on the fourth is the textbook definition of repeating a known failure.

## Failure mode

**Post-fix boundary case:** the mode-write happens before the project-shape calibration block (lines 287-308) runs. If a future caller relies on side effects of that block having happened (e.g. setting a variable used by the enforcement hook), and that side effect doesn't survive a SIGPIPE abort, the new failure model trades the mode-write reliability for that other reliability.

Quantitative signal: no caller currently relies on lines 287-308 side effects beyond the orientation print. The project-state classification at lines 295-308 produces text output only — no file writes, no env-var exports. The boundary case is hypothetical, not observed.

A second potential failure mode: **mode-write succeeds but the user wanted to abort the invocation.** If a user runs preflight and notices the orientation looks wrong (e.g. wrong project root), they may want to cancel before the mode is set. Pre-fix, that worked accidentally (any abort before line 312 left mode unwritten). Post-fix, by the time the user sees the orientation, mode is already set.

This is acceptable: the slash command is the user's commitment to a mode. The orientation is informational. If the user wants to revert, `echo idle > .bocek/mode` is one bash command away.

## Mitigations

1. **Pre-write defensive check:** the mode-validation case statement at lines 14-20 (the existing one) ensures `$MODE` is one of the known set before the write. No bogus modes can be written.
2. **Post-write read-back verification stays adjacent** to the write at the new top-of-script location. If the kernel reports the write succeeded but the file content is wrong, exit 1 with stderr message — same behavior as today, just earlier in the script.
3. **The closing banner at line 322 remains.** Even though it's no longer load-bearing for the side effect, it provides a clear "script completed" signal when the orientation runs to completion. Useful for callers that DO want the all-or-nothing observability (they can grep for the closing banner).

## Idiom citations

None — bash-shell pattern, not stack-specific.

## Revisit when

- Preflight grows additional side effects that have similar SIGPIPE vulnerability. The fix protects the *mode-write* specifically; if a future feature adds another late-script side effect (e.g. cache invalidation, lock-file write, telemetry emission), each new side effect needs the same structural-reorder treatment OR a different mechanism. Per `Revisit when` discipline, this is a maintenance trigger, not a one-time fix.
- A bocek caller emerges that legitimately wants "all or nothing" orientation+mode semantics. At that point, Option 2 (trap SIGPIPE) becomes worth revisiting as an addition (not replacement) to the relocation. Currently no such caller is named.
- `set -euo pipefail` is dropped from `preflight.sh` for some other reason. The SIGPIPE-abort behavior depends on `set -e`; without it, individual echo failures don't abort the script and the original bug never fires. If the script is restructured to not need pipefail, the relocation becomes unnecessary (but not harmful).
