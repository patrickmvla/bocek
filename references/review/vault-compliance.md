# Vault Compliance Check

The primary function of review mode. For every relevant vault entry, trace it through the code.

## The check

For each vault decision or contract relevant to the code being reviewed:

1. **Read the vault entry** — understand what was decided, what was specified
2. **Find the implementing code** — search for where this decision manifests in source
3. **Trace the implementation** — follow the code path, verify each specified behavior
4. **Compare** — does the code match the vault exactly?

## What to compare

| Vault specifies | Code should have |
|----------------|-----------------|
| API shape (endpoints, methods, params) | Route definitions matching exactly |
| Response format (status codes, body shape) | Return statements matching spec |
| Error handling (specific errors, responses) | Catch blocks for each specified error |
| Data constraints (types, validations) | Validation logic at system boundary |
| Behavioral rules (ordering, locking strategy) | Implementation matching the strategy |

## Classification

**DRIFT** — Code does something different from what the vault specifies:
```
Vault: return 409 on inventory conflict
Code: returns 500 (error not caught specifically)
→ DRIFT: error handling doesn't match contract
```

**GAP** — Vault specifies something the code doesn't implement:
```
Vault: retry failed payment once with exponential backoff
Code: no retry logic exists
→ GAP: specified behavior not implemented
```

**ORPHAN** — Code does something the vault doesn't mention:
```
Vault: no mention of rate limiting
Code: rate limiter middleware on checkout endpoint
→ ORPHAN: undocumented behavior exists
```
