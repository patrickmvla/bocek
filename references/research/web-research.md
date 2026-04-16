# Web Research Patterns

When gathering evidence from the web, apply these patterns to find reliable, current information.

## Source types and what they're good for

**Official docs** — current API shapes, configuration options, supported patterns. Check the version — docs for v2 don't apply to v3.

**Engineering blogs** — how teams solved specific problems at specific scale. The value is in the constraints they faced and the tradeoffs they made. Discount the "and it worked great" conclusion — survivorship bias is real.

**Post-mortems** — the highest-value web sources. They document what went wrong, why, and what changed. A post-mortem about a decision you're researching is worth more than ten blog posts advocating for it.

**GitHub issues** — real problems from real users. Search for the library/pattern + "issue" or "bug" or "migration." Issues reveal what docs don't cover.

**Discussions (Stack Overflow, forums)** — useful for identifying common pitfalls and misunderstandings. The questions are often more valuable than the answers.

## Freshness evaluation

| Age | Action |
|-----|--------|
| < 6 months | Likely current — verify against latest release |
| 6-18 months | Check for breaking changes in the interval |
| 18+ months | Treat as historical context, not current guidance |
| No date visible | Assume stale until proven otherwise |

## What to vault from web sources

- The specific finding, not a summary of the article
- The author's context (scale, team, domain) — it determines applicability
- The date — web content has a half-life
- Conflicts with other sources you've found
- The URL — for human follow-up
