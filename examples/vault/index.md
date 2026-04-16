---
vault_version: 1
---

# Vault Index

## checkout
- [[optimistic-locking]] — decision — Use optimistic locking for inventory; low write contention assumed
- [[stripe-idempotency-research]] — research — How Stripe handles idempotency keys in production
- [[checkout-api-contract]] — contract — POST /checkout endpoint shape, responses, and error codes
- [[cart-expiry]] — decision — Carts expire after 30 minutes of inactivity

## auth
- [[session-format]] — decision — JWT with 15-minute expiry + refresh token rotation
