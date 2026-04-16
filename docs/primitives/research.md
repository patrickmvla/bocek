# Research Primitive: Design

## Context
The research primitive is Bocek's evidence engine. It gathers ammunition from production codebases, current documentation, engineering blogs, post-mortems, and academic literature. Its output feeds directly into the design primitive's challenges, the implementation primitive's constraints, and the review primitive's drift detection.

Research doesn't make Bocek softer or more academic. It makes every other primitive harder to argue with. When the design primitive says "your approach is wrong," it's backed by production code, academic foundations, and real-world failure evidence. The research primitive supplies that evidence.

## Goals
- Produce structured vault entries grounded in real code, current docs, and academic foundations
- Attack every source before vaulting it — surface conflicts between sources, code-vs-claims discrepancies, and conditions under which findings apply
- Proactively identify research gaps in the vault based on existing decisions and the codebase
- Provide full source attribution on every finding — no ungrounded claims

## Non-Goals
- Not a summarization tool — it doesn't condense blog posts into bullet points
- Not an opinion engine — findings are evidence with citations, not the model's assessment
- Not a recommendation engine — the design primitive uses research to challenge decisions, the research primitive just provides the evidence
- Not a literature review — academic sources are included when they add engineering value, not for comprehensiveness

## Design

### Three evidence channels

**Code** — Production codebases read via tiered access (ADR-0014):
- Tier 1 (default): GitHub API for targeted file reads
- Tier 2 (fallback): Shallow clone to `/tmp/bocek-ref-*` for exploration
- Security: public repos only, source files only, never execute

**Web** — Current documentation, engineering blogs, post-mortems, discussions:
- Official framework/library docs for current API shapes
- Engineering blogs from teams who solved similar problems
- Post-mortems from teams who failed at what the human is attempting
- Discussions (GitHub issues, Stack Overflow) for known pitfalls

**Academic** — Papers, formal analysis, theoretical foundations:
- Used when the problem has formal properties (consistency models, distributed systems, type theory)
- Extracted for practical implications, not theoretical completeness
- Cross-referenced against production code — does the theory match what teams actually build?

### Source skepticism

The research primitive is adversarial toward its own sources. Before vaulting any finding, the model challenges it:
- How old is this? Is the advice current or deprecated?
- What's the author's context? Scale? Team size? Same problem domain?
- Does the actual code match what the blog post or docs claim?
- Who disagrees and why? What are the counterarguments?
- Does the academic literature support or contradict this?
- Under what conditions does this finding hold? When does it break?

Vault research entries are evidence packages with conflict built in — not endorsements of any single source.

### Research direction

The primitive defaults to **exploratory mode**: reads the vault and codebase, identifies decisions without evidence or areas with no research coverage, and recommends what to research next. The human can accept, redirect, or give a specific directive.

When the human gives a directive ("research how production systems handle X"), the model executes focused research. When the human says "what should we research?", the model analyzes vault gaps.

### Vault output format

Research entries follow a consistent structure:

```markdown
---
type: research
features: [feature-name]
related: ["[[related-decisions]]", "[[related-research]]"]
created: YYYY-MM-DD
confidence: high | medium | low
---

# [Research Question as Title]

## Question
[What was investigated — stated as a specific question]

## Sources Examined
- [repo/file:lines] (GH API or shallow clone)
- [URL] (web source with date)
- [Citation] (academic source)

## Findings
### [Pattern/Approach Name]
[What was found, with code references and specific evidence]

## Conflicts
[Where sources disagree, where code contradicts claims, where conditions vary]

## Conditions
[When each finding applies and when it breaks]

## Open Threads
[What wasn't answered — signals for future research]
```

Key sections: **Conflicts** surfaces disagreements. **Conditions** prevents universal claims. **Open Threads** prevents false completeness.

### Two-layer architecture (ADR-0011, ADR-0012)

**Core** (~800-2,000 tokens, persistent):
- Mode identity — evidence engine, three channels
- Source skepticism mandate
- Exploratory default behavior
- Vault write trigger
- Tool constraints (no source file writes)
- Reference table:

| When | Read |
|------|------|
| Writing a research entry | references/research-format.md |
| Evaluating a source | references/source-evaluation.md |
| Reading an unfamiliar codebase | references/code-reading.md |
| Evaluating web sources | references/web-research.md |
| Integrating academic sources | references/academic-integration.md |
| Linking to existing vault entries | references/cross-referencing.md |

**References** (loaded on demand):
- Research entry format template
- Source evaluation protocol (age, relevance, author context, code-vs-claims)
- Code reading patterns (entry points, dependency graphs, tests as documentation)
- Web research patterns (evaluating blogs, finding post-mortems, current vs stale docs)
- Academic integration patterns (when papers matter, extracting practical implications)
- Cross-referencing protocol (linking research to decisions and other research)

### Session continuity

Same pattern as design primitive: checkpoint to `.bocek/state.md` every time a research entry is written to the vault. State captures:
- Current research question(s)
- Sources already examined
- In-progress findings not yet vaulted
- Next sources to examine

### Cross-feature flow

Research naturally spans features. A finding about database locking applies to checkout, inventory, and warehouse. Research entries use the `features` frontmatter list to tag multiple features. Wikilinks in `related` connect research to the decisions it informs.

## Trade-offs

**Depth vs breadth:** Deep research on one approach vs surveying many. The primitive defaults to breadth first (survey the landscape) then depth on the approaches that survived initial scrutiny. But the human can direct either way.

**Source quality vs coverage:** Reading production source code is slower than reading blog summaries. But blog summaries are frequently wrong or outdated. The primitive prioritizes code over prose — a blog post is a lead, the code is the evidence.

**Academic rigor vs engineering pragmatism:** Papers provide theoretical foundations but can be disconnected from production reality. The primitive uses papers to understand *why* something works, then checks production code to see *if* it's actually used that way. Theory without practice is flagged as unverified.

**Research scope vs context budget:** Deep research consumes context. The three-channel approach could fill the context window quickly. The tiered code access (GH API before cloning) and structured vault writes (persist findings, free context) mitigate this. Heavy research sessions should use multiple sessions with vault continuity rather than one long session.
