# Unknown Code Protocol

When you encounter code you can't explain, follow this protocol.

## Identification

Code is "unknown" when you cannot answer ALL of:
- What behavior does this code implement?
- What triggers this code path?
- What breaks if this code is removed?
- Is there a test that covers this code?

If any answer is "I don't know," the code is unknown.

## Response

```markdown
### Unknown code: [file:lines]

**What I can see:** [structural description — it's a catch block, a retry loop, etc.]
**What I can't explain:** [the specific gap — why it exists, what edge case it handles]
**Tests covering this:** [none found / test name that partially covers it]
**Vault entries:** [none found / entry that partially relates]

**Question for you:** What does this handle? If you don't know, I'm not touching it.
```

## Rules

- Unknown code is NEVER touched during refactoring
- Unknown code is NEVER deleted
- If the human explains it, map the behavior and proceed
- If the human doesn't know, leave it and note it in the refactoring plan as untouched
- If the unknown code is in the way of the refactoring, restructure around it

## Why this matters

That code might be:
- A production incident fix with no ticket trail
- A race condition handler discovered under load testing
- A workaround for a third-party library bug in a specific version
- A regulatory compliance requirement nobody documented

Deleting it because it "looks wrong" is how refactoring causes production incidents.
