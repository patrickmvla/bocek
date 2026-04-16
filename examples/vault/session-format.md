---
type: decision
features: [auth]
related: []
created: 2026-04-16
confidence: high
---

# JWT with 15-minute expiry and refresh token rotation

## Decision
Auth uses short-lived JWTs (15-minute expiry) for API authentication, paired with refresh tokens stored server-side. Refresh tokens rotate on use — each refresh issues a new access token AND a new refresh token, invalidating the old refresh token. Refresh tokens expire after 7 days of inactivity.

## Reasoning
Short-lived JWTs limit the damage window from a stolen token to 15 minutes without requiring a token denylist on every request. Refresh token rotation detects token theft — if a stolen refresh token is used after the legitimate user has already refreshed, the rotation chain breaks and all tokens for that session are invalidated.

## Strongest rejected alternative
Session-based auth with a server-side session store. Simpler, instant revocation, no refresh dance. Rejected because the checkout flow makes external API calls (Stripe) that may take 200-800ms. Session lookup on every request adds latency to an already latency-sensitive path. JWTs verify locally with no database call.

## Failure mode
Token expiry during a long checkout flow (user loads cart, walks away for 14 minutes, clicks checkout). The checkout request arrives with an expired token. Mitigation: client-side token refresh before initiating checkout, not just on 401 response.

## Revisit when
- Adding real-time features (WebSocket) where 15-minute tokens cause excessive reconnection
- Moving to a service mesh where internal auth could use mTLS instead of JWTs
