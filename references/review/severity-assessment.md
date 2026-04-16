# Severity Assessment

Code quality findings (Priority 3) are only flagged when severe. This reference defines the severity threshold.

## Flag these (severe)

**Bugs — actual logical errors:**
- Race conditions (shared mutable state without synchronization)
- Resource leaks (unclosed connections, file handles, streams)
- Null/undefined access on paths that can be reached
- Off-by-one errors in boundary conditions
- Infinite loops or unbounded recursion

**Security issues:**
- SQL injection (string concatenation in queries)
- XSS (unescaped user input in HTML output)
- Auth bypass (missing permission check on a protected route)
- Exposed secrets (API keys, credentials in code or logs)
- SSRF (user-controlled URLs in server-side requests)

**Performance traps:**
- N+1 queries (database call per item in a loop)
- Unbounded collection growth (no pagination, no limit)
- Blocking operations in async contexts
- Missing indexes on frequently queried columns (if vault specifies access patterns)

## Do NOT flag (not severe enough)

- Naming conventions ("this variable should be camelCase")
- Code organization ("this function is too long")
- Design pattern suggestions ("consider using the strategy pattern")
- Style preferences ("prefer const over let")
- Documentation completeness ("this function needs a docstring")
- Test coverage ("this branch isn't tested")
- Dependency choices ("consider using library X instead")

These are opinions. The vault defines what matters. If the vault doesn't specify it, the review doesn't flag it.
