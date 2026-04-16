# Source Evaluation Protocol

Every source must be evaluated before its findings are vaulted. Trust is earned, not assumed.

## Evaluation dimensions

**Age and currency:**
- When was this written or last updated?
- Has the API/library/framework changed since then?
- Are there deprecation notices or migration guides that supersede this?

**Author context:**
- What scale is the author operating at? A solution for 10M users may be wrong for 10K.
- What team size? Solo developer advice differs from platform team advice.
- What domain? E-commerce patterns don't transfer cleanly to real-time systems.

**Code-vs-claims:**
- Does the actual code do what the blog post says it does?
- Read the source, not just the README. READMEs describe intent. Code describes reality.
- Check tests — what does the author actually verify?

**Consensus and disagreement:**
- Who else writes about this? Do they agree?
- Check GitHub issues — are users reporting problems the blog post doesn't mention?
- Check Stack Overflow — are people struggling with the approach described?

## Trust tiers

| Tier | Source type | Trust level |
|------|-----------|-------------|
| 1 | Production source code you've read | High — code doesn't lie |
| 2 | Official framework/library docs | Medium-high — may lag behind code |
| 3 | Engineering blogs from known teams | Medium — context may differ from yours |
| 4 | Stack Overflow answers | Low-medium — verify against code |
| 5 | Tutorial/course content | Low — often simplified past usefulness |
| 6 | LLM training data (your own knowledge) | Lowest — ungrounded, use as leads only |

When sources conflict, prefer higher-tier sources. When same-tier sources conflict, vault the conflict — don't resolve it by picking a winner.
