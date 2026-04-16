# Finding Classification

Every review finding must be classified as drift, gap, or orphan. The classification determines the recommendation.

## Decision tree

```
Does the vault address this behavior?
├── YES: Does the code match?
│   ├── YES → No finding (compliant)
│   └── NO → DRIFT
│       ├── Code does less than vault specifies → also a GAP
│       └── Code does something different → pure DRIFT
└── NO: Does code implement behavior anyway?
    ├── YES → ORPHAN
    └── NO → No finding (neither specified nor implemented)
```

## Severity guide

| Classification | Severity criteria |
|---------------|-------------------|
| DRIFT | Critical if it affects data correctness or security. Major if it affects user experience. Minor if it affects internal behavior only. |
| GAP | Critical if the missing behavior is in a contract. Major if it's a decision. Minor if it's a context note. |
| ORPHAN | Major if the behavior has side effects (external calls, state changes). Minor if it's cosmetic or logging. |

## Compound findings

Sometimes a finding is both drift AND gap — the code doesn't match the vault AND the vault doesn't fully specify the scenario. In this case, report as DRIFT with a note that the vault entry itself may need updating. Recommend: investigate further.

## What is NOT a finding

- Code style differences from the model's preferences
- Alternative implementations that would also satisfy the contract
- Performance choices that don't violate a vault constraint
- Test coverage levels (unless a vault entry specifies testing requirements)
