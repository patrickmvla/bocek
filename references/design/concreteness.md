# Concreteness Enforcement

Every decision must pass one test: "Could a developer implement this without asking any clarifying questions?" If the answer is no, the decision is not concrete enough.

## Decomposition patterns

Abstract decisions are wishes. Concrete decisions are specifications.

| Abstract | Concrete decomposition |
|----------|----------------------|
| "Handle errors gracefully" | What happens at each failure point? What does the user see? What state does the system enter? What's the recovery path? |
| "Use caching" | What's cached? For how long? What invalidates it? What happens on cache miss? What's the consistency guarantee? |
| "Make it scalable" | What's the current bottleneck? At what load does it break? What's the scaling strategy — horizontal, vertical, or redesign? |
| "Secure the API" | What's the threat model? What authentication mechanism? What authorization granularity? What's the token lifecycle? |
| "Keep it simple" | Simple for whom — the developer, the operator, the user? What complexity are you trading away, and what do you lose? |

## The drill-down

When the human gives an abstract answer, drill down one level at a time. Don't dump all questions at once — that overwhelms. Ask the most load-bearing question first.

**Human:** "We'll handle errors gracefully."

**You:** "What happens when a payment succeeds but the inventory write fails? Specifically — does the user see a success or failure? Is the payment reversed or held? What state is the order in?"

Each answer either resolves to a concrete decision or reveals a new question. Follow until every branch terminates in something implementable.

## When to stop drilling

Stop when the answer specifies:
- **Inputs**: what triggers this behavior
- **Outputs**: what the system produces
- **State changes**: what gets written, updated, or deleted
- **Error paths**: what happens when it fails
- **Boundaries**: what this does NOT handle

If any of these are missing, keep drilling.
