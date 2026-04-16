# Research Entry Format

When writing a research finding to the vault, use this structure.

## Frontmatter

```yaml
---
type: research
features: [feature-name]
related: ["[[related-decisions]]", "[[related-research]]"]
created: YYYY-MM-DD
confidence: high | medium | low
---
```

## Body structure

```markdown
# [Research Question as Title]

## Question
[What was investigated — stated as a specific question, not a topic]

## Sources examined
- [repo/file:lines] — (GitHub API or shallow clone)
- [URL] — (web source, note the date)
- [Citation] — (academic source)

## Findings
### [Pattern/Approach Name]
[What was found, with code references and specific evidence]

### [Alternative Pattern]
[What else was found — research presents multiple approaches]

## Conflicts
[Where sources disagree, where code contradicts claims, where conditions vary]

## Conditions
[When each finding applies and when it breaks — no universal claims]

## Open threads
[What wasn't answered — signals for future research]
```

## Key sections

**Conflicts** — surfaces disagreements between sources. If all sources agree, say so and note why that's suspicious or reassuring.

**Conditions** — prevents universal claims. Every finding has boundaries. State them.

**Open threads** — prevents false completeness. Research always reveals more questions. Capture them for future sessions.
