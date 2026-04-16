# Integration Verification

Before moving to the next component, verify the current one integrates correctly with adjacent contracts.

## What to verify

**Interface match:** Does the output of this component match the expected input of the next component in the chain? Check types, shapes, and error propagation.

```
Component A outputs: {order_id: string, status: "confirmed" | "pending"}
Component B expects: {order_id: string, status: string}
→ Match (B accepts A's output)

Component A error: throws InventoryConflictError
Component B expects: catches InventoryConflictError → returns 409
→ Match (error propagation is specified)
```

**Contract boundary:** Where does this component's responsibility end and the next one's begin? The vault should specify this. If it doesn't, flag the gap — unclear boundaries produce duplicate logic or dropped responsibilities.

**Data flow:** Trace a request from entry point through this component and into the next. Does data transform correctly at each step? Are there lossy transformations (field drops, type coercions) that violate a downstream contract?

**Failure propagation:** When this component fails, what does the caller see? Does the error match what the caller's contract expects? An internal 500 that should be a 409 is an integration bug, not an implementation bug.

## When integration reveals a contract gap

If two components can't integrate cleanly because the contracts don't align:
1. Don't adapt either component to "make it work"
2. Flag the misalignment as a gap
3. Both contracts may need revision — that's a design mode decision
