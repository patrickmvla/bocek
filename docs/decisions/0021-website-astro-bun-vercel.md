# ADR-0021: Website Stack — Astro + Bun + Vercel Free Tier

## Status
Accepted

## Decision
The website (`TBD domain`) uses Astro with Bun as the runtime, deployed to Vercel's free Hobby tier as a static site.

- **Framework**: Astro (static output, markdown-native)
- **Runtime**: Bun (not npm/Node)
- **Hosting**: Vercel free tier (static CDN, auto HTTPS, auto-deploy from GitHub)
- **Domain**: `TBD domain`

## Consequences
- **Positive**: Zero hosting cost, global CDN, automatic HTTPS
- **Positive**: Bun is faster for builds and dev server than npm/Node
- **Positive**: Astro generates static HTML — no SSR complexity, no serverless cold starts
- **Negative**: Vercel free tier prohibits commercial use — irrelevant for open source, but if Bocek ever has a paid tier, migrate to Vercel Pro ($20/mo) or Cloudflare Pages

## Revisit When
- If Bocek needs commercial hosting (Vercel Pro or Cloudflare Pages)
- If Vercel changes free tier terms
