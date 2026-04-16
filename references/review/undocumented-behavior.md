# Undocumented Behavior Detection

Code that does things no vault entry covers is an orphan — it may be intentional or it may be drift that was never caught.

## What to look for

**Behavior without a decision behind it:**
The model made a choice during implementation that should have been flagged as a gap. Common patterns:
- Error handling strategies that aren't in any contract
- Retry logic with specific parameters (count, backoff) that aren't specified
- Caching with TTLs that aren't documented
- Logging that includes sensitive data

**Side effects not in any contract:**
- External API calls that aren't part of any vault flow
- Database writes that aren't part of any specified state change
- Event emissions that aren't documented
- Metrics or telemetry that collects specific data

**Implicit assumptions:**
- Hardcoded values (timeouts, limits, URLs) that encode decisions nobody made explicitly
- Environment variable dependencies that aren't documented
- Feature flags or configuration that controls behavior without vault backing

## How to report

Each orphan gets a finding entry. Don't judge whether it's correct — just flag that it exists without vault backing.

The human decides:
- **Intentional** → add a vault entry documenting the decision
- **Accidental** → fix or remove it
- **Investigate** → unclear, needs more context

The goal is full vault coverage of actual behavior, not removal of useful code.
