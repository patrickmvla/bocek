# Gap Flagging Format

When you encounter a missing decision per `/implementation` *Anti-improvisation*, produce a structured gap report. Don't continue past the gap; the next step may depend on the decision.

## Format

```markdown
## GAP: [short description]

**Blocked step:** [which implementation step can't proceed, with file:line]
**What's missing:** [the specific decision that doesn't exist in the vault — name the
decision precisely. Not "error handling" but "the error code returned when the upstream
service is unavailable."]
**Why it matters:** [what goes wrong if you guess. Concrete consequence — "a 404 leaks
that the cart existed; a 400 is generic and clients can't distinguish from validation
errors; the choice affects the public API contract."]

**Engineering substance at stake:**
[REQUIRED when the gap touches one of design's principle dimensions. Name what's relevant
so /design can pick up the right thread.]
- **Failure semantics:** [e.g. "what's the at-most-once vs. at-least-once expectation here?"]
- **Concurrency:** [e.g. "is this called concurrently? what's the ordering guarantee?"]
- **Observability:** [e.g. "what should ops see when this fails?"]
- Or N/A if the gap is small enough to not touch any principle dimension.

**Unvetted options** (from training data — clearly NOT recommendations):
1. [Option A] — [tradeoff. One source if known: "common in REST APIs per RFC 7231"]
2. [Option B] — [tradeoff. One source if known]
3. [Option C] — [tradeoff. One source if known]

**To resolve:** Switch to `/design` for a thorough decision (default), or give a directive
here if the choice is genuinely small enough to not warrant a full design pass.
```

## Example

```markdown
## GAP: Cart not found behavior

**Blocked step:** `src/checkout.ts:42` — POST /checkout input validation
**What's missing:** No vault decision for the response when `cart_id` doesn't match an
existing cart in the database.
**Why it matters:** A 404 confirms cart ID validity to anyone probing the endpoint
(enumeration attack vector). A 400 is generic and clients can't distinguish from
validation errors. A custom code requires a contract addition.

**Engineering substance at stake:**
- **Security:** trust boundary — does an unauthenticated probe reveal cart existence?
- **API contract:** affects [[checkout-api-contract]] and any client retry logic.

**Unvetted options** (from training data — NOT recommendations):
1. Return 404 — standard REST per RFC 7231; confirms cart-ID validity to callers (enumeration).
2. Return 400 with validation error — treats as bad input; no information leak; client can't
   tell the difference from malformed JSON.
3. Return 422 with specific `cart_not_found` error — distinguishes from malformed; still
   confirms existence; needs contract addition.

**To resolve:** Affects the API error contract and security posture. `/design` recommended.
```

## Rules

- **Label options as "unvetted" every time.** The human must know these aren't vault-backed.
  Mode-collapsing to "the obvious default" is exactly what implementation mode is built to prevent.
- **Don't recommend.** Present tradeoffs neutrally. Recommendations belong in `/design`,
  after challenge.
- **Don't continue past the gap.** The next step may depend on the resolution. Stop, flag,
  wait.
- **If multiple gaps cluster**, report them together — they may be symptoms of a missing
  design dimension, and `/design` should resolve them as a coherent set rather than one by one.
- **Cite sources for unvetted options when known.** RFC, current docs, named production
  example. *"Common in REST APIs per RFC 7231"* > *"common pattern."* This isn't research-grade
  triangulation, but it gives `/design` a starting point.
