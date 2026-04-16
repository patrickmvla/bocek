# Cross-Referencing Protocol

Research entries don't exist in isolation. Every finding connects to existing vault entries — decisions it informs, other research it confirms or contradicts, contracts it affects.

## When writing a research entry

1. **Read the vault index** — scan for entries in the same feature or related features
2. **Check for decisions this informs** — if your finding provides evidence for or against an existing decision, add it to `related` and note the connection in the body
3. **Check for conflicting research** — if your finding contradicts a previous research entry, vault the conflict explicitly. Don't silently update — the conflict is the valuable part
4. **Check for cross-feature implications** — a finding about database locking applies to checkout, inventory, and warehouse. Tag all relevant features in frontmatter

## Wikilink conventions

Use `[[entry-name]]` to reference other vault entries. Names are resolved by filename, not path — surviving file moves within the vault.

```markdown
related: ["[[optimistic-locking-decision]]", "[[stripe-idempotency-research]]"]
```

In the body:
```markdown
This contradicts the assumption in [[optimistic-locking-decision]] that write
contention will remain low. Under the conditions described in findings,
contention spikes during inventory release events.
```

## When research invalidates a decision

Don't modify the decision entry. Instead:
1. Write the research entry with the contradicting evidence
2. Add a wikilink to the decision in `related`
3. Note in the research body: "This finding suggests [[decision-name]] should be revisited. The assumption that X no longer holds because Y."
4. The human takes it to design mode if they agree

Research provides evidence. Design makes decisions. Don't cross the boundary.
