# Academic Integration Patterns

Academic sources provide theoretical foundations. Use them when the problem has formal properties — consistency models, distributed systems, type theory, algorithm complexity. Don't use them as decoration.

## When papers matter

- **Formal correctness** — "is this approach provably correct under these conditions?"
- **Impossibility results** — "is what we're attempting fundamentally impossible?" (CAP theorem, FLP impossibility)
- **Complexity bounds** — "what's the best we can do here?"
- **Algorithm comparison** — "which approach performs better under what conditions, with proof?"

## When papers don't matter

- The problem is pure engineering (API shape, deployment strategy, config format)
- The paper's assumptions don't match production conditions
- The paper is theoretical without practical implementation evidence

## How to integrate

1. **Extract the practical implication** — "this paper proves that under network partitions, you cannot have both consistency and availability" not "Brewer's conjecture, formalized by Gilbert and Lynch..."
2. **Cross-reference against production code** — does any production system actually implement what the paper recommends? If not, why not?
3. **Note the gap** — if theory and practice diverge, that's a finding worth vaulting. "The paper recommends X, but every production system we examined uses Y instead because Z."

## Citation format

```
[Author, Year] "Title" — [practical implication in one sentence]
```

Keep citations minimal. The vault is for engineers, not reviewers. The practical implication matters more than the citation.
