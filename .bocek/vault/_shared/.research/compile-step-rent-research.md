---
type: research
features: [_shared]
related: ["[[discovery-compile-instruction-lacks-output-path]]", "[[vault-scale-audit-bokchoy]]", "[[research-subfolder]]"]
created: 2026-05-14
confidence: high
provisional: false
---

# Does `.bocek/vault/.compiled/{feature}.md` pay rent in token cost or model performance compared to reading raw `vault/{feature}/*` files at implementation time?

## Question

The `[[discovery-compile-instruction-lacks-output-path]]` finding established that `.compiled/{feature}.md` has never been written in production (bokchoy ran `/implementation` multiple times without it). Before deciding whether to fix the gap (Option 2: script-driven compile) or remove the cache concept entirely (Option 3), the design seat needs to know whether compile is actually load-bearing at all. This research answers: under what conditions would a compiled cache artifact pay measurable rent — and do those conditions hold for bocek's typical use case?

## Triangulation

- **Production reference:** ✓ — Aider (`aider.chat/docs/repomap.html` and `aider.chat/2023/10/22/repomap.html`, by Paul Gauthier; verified at `github.com/Aider-AI/aider`). Closest production analog to `.compiled/{feature}.md` in the AI-coding-agent space. Plus bokchoy's own vault data as live production evidence (`~/audhd/bokchoy/.bocek/vault/wallet/` and `architecture/`, observed 2026-05-14).
- **Docs reference:** ✓ — Anthropic prompt-caching docs (`platform.claude.com/docs/en/build-with-claude/prompt-caching`, current as of 2026-05-14) and announcement (`anthropic.com/news/prompt-caching`). The model-layer alternative.
- **Contradiction probe:** ✓ — actively searched for "always-load-full-context wins over read-on-demand" position via three queries. **No credible engineering-grade source supporting flat-concatenation found.** The only sources supporting cache-everything were marketing pages for tools that hadn't optimized. Multiple independent engineering-blog sources (GitHub Blog, Augment Code, Towards Data Science, Klaus Hofenbitzer's "Token Cost Trap") consistently support read-on-demand for selective tasks.

## Sources examined

### bokchoy's `wallet/` and `architecture/` folders (filesystem state)

- **Tier:** 1 (production vault data)
- **Provenance:** `~/audhd/bokchoy/.bocek/vault/wallet/` (14 entries) and `~/audhd/bokchoy/.bocek/vault/architecture/` (39 entries), observed 2026-05-14
- **Author context:** Single-engineer bokchoy project, active bocek user
- **What it tells us:** First-principles token math.
  - `wallet/` raw concatenation: 49,656 words ≈ **65k tokens** at 1.3 tokens/word
  - `architecture/` raw concatenation: 142,653 words ≈ **185k tokens** ≈ **85% of Claude's 200k context window** consumed by ONE feature folder
  - `architecture/` decisions-only (excluding research files): 55,947 words ≈ 70k tokens
  - `architecture/` research-only: 85,796 words ≈ 110k tokens (60% of folder's content)

### Aider `repomap.html` and `2023/10/22/repomap.html`

- **Tier:** 2 (official docs of the tool) + 4 (the engineering blog post explaining the design)
- **Provenance:** `aider.chat/docs/repomap.html` (current); `aider.chat/2023/10/22/repomap.html` (Paul Gauthier, October 2023)
- **Author context:** Paul Gauthier, Aider's creator. Aider is one of the most-adopted AI coding agents; the repo-map approach has been in production for ~3 years.
- **What it tells us:** Aider does NOT flat-concatenate. It uses tree-sitter to extract symbol definitions/references, builds a PageRank graph, scores files by relevance to the current conversation, and renders the top-ranked definitions within a configurable token budget (default 1k tokens). Documented rationale: *"adding many irrelevant files will often distract or confuse the LLM, resulting in worse coding results, and also increases token costs."* The decision to use dynamic selection over static concatenation is *load-bearing for performance*, not just cost.

### Anthropic prompt-caching docs

- **Tier:** 2 (current official docs)
- **Provenance:** `platform.claude.com/docs/en/build-with-claude/prompt-caching` and `anthropic.com/news/prompt-caching` (both current as of 2026-05-14)
- **Author context:** Anthropic, the model vendor.
- **What it tells us:**
  - Cache reads cost **$0.30/1M tokens vs. $3.00/1M for uncached input** (Sonnet pricing) — a 90% reduction on cached prefixes.
  - Break-even after **1 cache hit** with 5-minute TTL. Trivially met within any multi-turn session.
  - The exact use case Anthropic names: *"For code assistants, you can cache the full codebase context so users can ask multiple questions about the code without repeatedly paying to process the entire repository."*
  - Implementation: single `cache_control` field at the top level of the request; the system auto-manages cache breakpoints. **No custom build step required.**

### Augment Code "AI Agent Loop Token Costs" (`augmentcode.com/guides/ai-agent-loop-token-cost-context-constraints`)

- **Tier:** 4 (engineering blog, vendor-affiliated — Augment is a coding-agent company)
- **Provenance:** undated current page on Augment Code's site
- **Author context:** Augment Code engineering team; coding-agent vendor with skin in the game (their product depends on getting this right)
- **What it tells us:** *"The growing conversation history is the dominant cost driver in multi-step loops, and each new tool output or reasoning trace is unique per iteration, so it cannot be cached. This means caching is limited to static system prompts and instructions."* Important caveat: prompt caching helps the FIRST read of the vault prefix; subsequent turns' dynamic context is the dominant cost regardless of whether a `.compiled/` file exists.

### GitHub Blog "Improving token efficiency in GitHub Agentic Workflows" (`github.blog/ai-and-ml/github-copilot/improving-token-efficiency-in-github-agentic-workflows`)

- **Tier:** 3 (engineering post-mortem from a major vendor with skin in the game)
- **Provenance:** GitHub Blog, current page on github.blog
- **Author context:** GitHub Copilot engineering team
- **What it tells us:** For pure code comprehension where an agent would normally read dozens of files, switching to tool-call-based on-demand retrieval saves 70-95% of tokens versus loading everything upfront. The pattern is: load minimal static context, fetch dynamically via function calls.

### Augment Code's hybrid framing (cross-referenced)

- **What it tells us:** *"The most effective approach combines both strategies: first pass loads static context (system prompt, cached instructions, long-lived summaries); second pass injects dynamic context (current task state, fresh retrieval results, recent history)."* The first-pass "cached instructions" is what Anthropic auto-handles; the second-pass dynamic injection is what tool-based reads handle. **There is no third layer where bocek's `.compiled/{feature}.md` would fit unless it provides curated synthesis that neither prompt caching nor on-demand retrieval covers.**

## Findings

### F1. Compile-as-flat-`cat` is strictly dominated. Production evidence: Aider explicitly rejects this approach.

At bokchoy's `architecture/`-folder scale, `cat *.md` produces 185k tokens — 85% of Claude's 200k context window — for ONE feature's vault. That makes the compile artifact roughly useless: implementation seats would have ~15% of context budget left for code reading, code writing, and conversation history combined. Per Aider's documented rationale (production-cited; high), large dump-context approaches actively hurt LLM coding performance, not just token cost. This shape of `.compiled/` is empirically worse than no cache.

### F2. Anthropic prompt caching already provides the auto-cache benefit `.compiled/` was designed for.

Anthropic's prompt caching breaks even after 1 cache hit, charges 90% less for cache reads, and auto-manages breakpoints with a single `cache_control` field. The exact use case Anthropic names — *"cache the full codebase context so users can ask multiple questions about the code without repeatedly paying to process the entire repository"* — IS what `.compiled/{feature}.md` was supposed to provide. **Building bocek's own pre-compile layer duplicates infrastructure the model vendor ships for free** (docs-cited; high).

This holds even if Bocek's implementation seats are run via Claude Code (which uses Anthropic's API under the hood). Claude Code's session-start file loading benefits from auto-prefix-caching the same way direct API calls do.

### F3. Read-on-demand wins 70-95% on token cost for selective tasks.

GitHub Copilot's measurement: routing agent reads through tool calls instead of upfront loading saves 70-95% of tokens for code comprehension tasks (production-cited; high). Bocek's `/implementation` seat is precisely this pattern: it doesn't need every entry in a feature folder — it needs the specific contracts to implement, the specific decisions that bind, occasionally a discovery that names an edge case. **The default access pattern for `/implementation` is selective, not exhaustive.** Read-on-demand naturally constrains to what's needed; compile-everything forces reading what isn't.

### F4. The model's natural reading behavior IS the compile step.

Bokchoy's evidence: `/implementation` ran multiple times against features containing 14-39 entries each, shipped code, and never needed `.compiled/{feature}.md` to exist. The model reads the entries it determines are relevant for the task at hand. The "compile" the primitive intended (synthesize-and-cache) happens implicitly inside the model's context window when it loads the relevant subset of files. Externalizing that synthesis as a pre-built artifact doesn't add value — and at scale it costs context window space (production-cited within bocek; high — supports F2 and F3).

### F5. There IS a narrow condition under which compile pays rent.

Compile-as-curated-synthesis (NOT concatenation) could pay rent IF all three hold:

1. The synthesis is meaningfully smaller than raw entries (e.g., contracts-only at ~25% of raw folder size, achievable by excluding `.research/` and stripping reasoning/rejected-alternatives sections from decisions to leave only the contract).
2. The synthesis runs across multi-session work and the model returns to the same feature repeatedly — so the artifact's *content* (vs. just its tokens) is what's reused, beyond what Anthropic's session-scoped 5-minute cache provides.
3. The team is willing to absorb the synthesis-quality maintenance cost (script needs to track which sections of each entry are "contract" vs. "reasoning" — non-trivial parsing of markdown).

Whether these conditions hold for typical bocek users is **not answerable from this research**. Bokchoy doesn't have multi-session-per-feature workloads documented; condition 2 is unknown. Condition 1 requires designing the synthesis format. Condition 3 is the polish #6 cost from `[[vault-scale-audit-bokchoy]]`.

## Conflicts

### Aider's repo map vs. Anthropic's prompt caching — both are right, different problems

Aider's PageRank-scored selection optimizes for *what content to include* under a token budget. Anthropic's prompt caching optimizes for *what to pay to re-read* when content is unchanged. They solve different parts of the cost equation:

- Aider: minimize context size by picking the right slice of a large codebase.
- Anthropic: minimize re-read cost by caching whatever content you decide to send.

Per `Contradiction protocol`, no precedence applies here — both are production-cited, both target tier-1 problems, and they compose rather than conflict. **For bocek: Anthropic handles the re-read cost automatically; Aider's lesson is that compile-everything is the wrong selection strategy.** Together they argue against bocek building its own compile layer.

### Vendor incentive to call out

Augment Code's source has a conflict-of-interest tag: they sell a coding agent. Their advice favors approaches that emphasize their product's differentiation. Their factual claims (history dominates multi-step cost; dynamic context can't be cached) are consistent with independent sources (GitHub Blog, Anthropic docs), so the bias doesn't undermine the load-bearing claims. Calibration: tier 4 with vendor bias, but not rejected — the technical claims are confirmed by independent tier-3 source.

## Conditions

These findings apply when:

- Implementation runs on Claude / Claude-Code / any Anthropic-API-backed agent (prompt caching applies). Holds for current bocek users — all bocek primitives target Claude Code per `docs/decisions/0017-claude-code-only-v1.md` (now committed-deleted, but the decision was the project's stance through 2026-05-02).
- Implementation seats access vault entries selectively (the typical pattern observed in bokchoy's state.md). If a future use case emerges where every entry in a 30+-entry feature folder must be in context simultaneously, F1 and F3 may not bind.
- Feature folders contain mixed entry types (decisions + research + discoveries + gaps) rather than research-only or contracts-only. Bokchoy's pattern matches.

These findings BREAK when:

- The user's agent has no native prompt-caching layer (e.g., a future bocek user runs against an LLM without auto-cache). Then F2 weakens and `.compiled/` regains some of its theoretical value.
- The feature is small enough (<5 entries) that flat-cat IS the entire feature and selective reading saves nothing. At that scale, neither path matters — context is cheap either way.
- The synthesis is genuinely smaller-and-better than raw (Compile-as-Synthesis per F5), AND condition 2+3 from F5 hold.

## Operational implications

For the design decision in queue — Option 2 (script-driven compile) vs. Option 3 (remove `.compiled/` entirely):

- **Option 3 has the stronger evidence base.** F1 + F2 + F3 + F4 all converge: at typical bocek scale, with Claude as the agent, the cache concept doesn't pay rent. The audit's bokchoy data (`[[vault-scale-audit-bokchoy]]` F7) demonstrates implementation works without it.
- **Option 2 is defensible ONLY in the narrow F5 regime.** Curated synthesis (contracts-only, stripped of reasoning), multi-session feature workloads, willingness to maintain a markdown-parsing script. Bocek hasn't measured whether F5's conditions hold for its actual users.
- **Option 1 (prose amendment) remains rejected.** Independent of which of Option 2 or Option 3 wins, prose amendments without enforcement is the failure pattern bocek keeps re-deriving (`[[mandatory-feature-folders]]`'s same finding).

For `references/shared/vault-format.md`: remove `.compiled/` from the documented path-convention layout if Option 3 wins; otherwise leave it and Option 2's script work updates it.

For `primitives/implementation.md` lines 25 and 118 + `references/implementation/contract-following.md` line 8: the "compile" language is incorrect regardless of which fix wins:
- Under Option 3: all three locations need to drop the compile-related framing entirely and describe direct reading of `vault/{feature}/*` files.
- Under Option 2: all three locations need to gain a directive verb that names the compile script invocation explicitly.

Per `[[research-subfolder]]`, when Option 3 wins, `.research/` subfolder still hides research from default loads — so the natural read pattern for `/implementation` becomes "read `vault/{feature}/{slug}.md` (decisions, contracts, discoveries, gaps), explicitly read `vault/{feature}/.research/{slug}.md` only when reasoning requires citing evidence." That's exactly the selective-read pattern F3 measures at 70-95% savings.

## Reproducibility note

Reproducible in full:

1. Token math: `wc -w ~/audhd/bokchoy/.bocek/vault/{feature}/*.md` for any feature; estimate tokens at ~1.3 per word (Anthropic's documented English ratio).
2. Aider's repo-map docs: `WebFetch https://aider.chat/docs/repomap.html` and `https://aider.chat/2023/10/22/repomap.html`.
3. Anthropic prompt-caching: `WebFetch https://platform.claude.com/docs/en/build-with-claude/prompt-caching` and `https://anthropic.com/news/prompt-caching`.
4. Contradiction probe: web search for `"AI coding agent" project context cache vs read on demand token efficiency` — same first-page results consistent within ±~6 months window.

The interpretation (mapping these findings onto bocek's specific architecture) is judgment. A different investigator with different priors about how bocek's primitives should evolve could weight differently — particularly on whether F5's conditions hold for typical bocek users. Calibration: high for the findings themselves; medium for the operational mapping to bocek.

## Open threads

- **F5 conditions check.** Does any bocek-using project have multi-session-per-feature workloads where compile-as-synthesis would pay rent? Need at least one project that's been at >50 entries for >3 months and has had implementation seats return to the same feature folder 5+ times. Bokchoy may qualify; verify against its state.md history.
- **Claude Code's exact session-start file-loading behavior.** Does Claude Code's session-start hook trigger automatic prompt-caching for the vault entries it reads, or does the cache apply only to messages within a single API call? Affects how F2 maps onto bocek's actual access pattern. Out of scope for this entry; queued for a future research session if Option 2 stays on the table.
- **Non-Claude bocek users.** Bocek's primitives target Claude Code per the deprecated ADR-0017. If bocek widens to other agents (Cursor, Aider, Continue), the F2 model-layer-cache argument may not hold for all of them. Adjacent research, not blocking the immediate decision.
- **The `.compiled/{feature}.md` shape question (if Option 2 wins).** Synthesis format is underspecified. Concatenation is rejected per F1. Contracts-only extraction requires markdown parsing that recognizes the section structure from `references/shared/vault-format.md`. Design owes this if it picks Option 2.
