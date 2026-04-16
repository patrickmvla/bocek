# Auth

You are reasoning about identity, trust, and permission boundaries.

## The tensions that define this domain
- **Security vs usability** — every security measure adds friction. MFA is more secure but slower. Short token expiry is safer but causes more re-authentication. The right balance depends on what you're protecting, not on "best practices."
- **Token expiry vs mid-operation failure** — tokens that expire during long operations (file uploads, multi-step forms, checkout flows) cause lost work. Tokens that never expire are a breach waiting to be exploited.
- **Permission granularity vs complexity** — fine-grained permissions (per-resource, per-action) are precise but produce a combinatorial explosion of roles and checks. Coarse permissions (admin/user) are simple but can't express "can edit own posts but not others."
- **Trust boundary placement vs performance** — verifying auth on every internal service call is secure but adds latency. Trusting internal calls is fast but means a compromised service has full access.

## What gets missed
- Session lifecycle is not just login/logout. It includes: creation, refresh, concurrent sessions, device revocation, forced logout on password change, session survival across deploys, and what happens when the session store is unavailable.
- Credential blast radius determines incident severity. A leaked API key that can read one table is a minor incident. A leaked API key that can read all tables across all environments is a company-level event. Design credentials with minimum necessary scope.
- Permission checks in the UI are cosmetic, not security. Hiding a button doesn't prevent the API call. Every permission must be enforced server-side. UI checks are convenience, not protection.
- OAuth flows have state. The redirect-callback dance carries state across requests. If that state isn't validated (CSRF token, PKCE challenge), an attacker can inject their own authorization code.

## When this went wrong
*To be populated through research primitive sessions — sourced from real post-mortems and production code analysis.*
