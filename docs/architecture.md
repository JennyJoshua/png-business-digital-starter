# Architecture

**Principle:** one master template, many independent business applications, one future marketplace connection.

## Decision: zero-dependency static site generator (Node.js)
`scripts/build.mjs` reads a business folder and writes plain HTML/CSS/JS into `dist/`.

| Need | How it is met |
|---|---|
| Independent deployments | Each customer copies the repo and builds only their own folder; output is static files |
| Config-driven branding | Colours become CSS variables; name, logo, cover come from `business.json` |
| Mobile performance | No framework, small CSS, tiny inline script, lazy-loaded images |
| Low cost / simple hosting | Any static host (GitHub Pages, Cloudflare Pages, Netlify, plain web server) |
| Future API integration | Stable IDs, versioned export format, documented interface |
| Simple maintenance | No runtime dependencies; builds quickly |

**Trade-offs:** catalogue edits require a rebuild and redeploy; there is no admin screen; search/filter runs in the browser over the rendered page (fine for hundreds of items, not tens of thousands). A framework was rejected for v1 because nothing in scope needs server code. If a trusted backend is needed later (social publishing, marketplace sync), it can be added beside the static site without rewriting the templates.

## Data separation
Each deployment contains only its own `business/` folder. The build rejects asset paths that point outside that folder. No secrets exist or are needed. The export file is generated from the same config and contains only whitelisted fields.

## Security measures actually implemented
Business-supplied text is HTML-escaped; URLs must be http(s); colours must be `#RRGGBB`; IDs must be lowercase slugs; phone numbers are validated. Invalid configs fail the build with clear messages. There is no authentication, admin area or login in v1.

## Demonstration-only items
The three example businesses, their phone numbers, emails and social links are placeholders. Placeholder logos/images are generated SVGs.

## Design system
One stylesheet (`src/styles.css`) and one set of page templates (`src/render.mjs`). Branding changes colours, logo and cover image, so layout and navigation stay consistent for every business.

## Version 1.1.0
Validation covers fields with `file › field` messages, brand-colour contrast, safe image paths and placeholder detection for non-demo businesses. Demo data is visibly marked. Exports use a field whitelist. Images have runtime fallbacks. Architecture and data model remain unchanged.
