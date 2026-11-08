# Architecture

**Principle:** one master template, many independent business applications, one future marketplace connection.

## Current implementation: zero-dependency static site generator (Node.js)

`scripts/build.mjs` reads a business folder and writes plain HTML/CSS/JS into `dist/`.

| Need | How it is met |
|---|---|
| Independent deployments | Each customer copies the repo and builds only their own folder; output is static files |
| Config-driven branding | Colours become CSS variables; name, logo, cover come from `business.json` |
| Mobile performance | No framework, small CSS, tiny inline script, lazy-loaded images |
| Low cost / simple hosting | Any static host (GitHub Pages, Cloudflare Pages, Netlify, plain web server) |
| Future API integration | Stable IDs, versioned export format, documented interface |
| Simple maintenance | No runtime dependencies; builds quickly |

**Current trade-offs:** catalogue edits require a rebuild and redeploy; there is no owner admin; search runs in the browser over the generated catalogue (appropriate for small-to-medium catalogues, not tens of thousands). The Phase 2A branch removes the public Promotions page and navigation, adds homepage logo fallback, live listing/category suggestions and a dedicated results page with category filtering, sorting and a clear-search action. These changes remain on a review branch until accepted.

## Approved next product architecture: public storefront + private owner admin

The product will provide two distinct user experiences while sharing one business identity, catalogue, stable IDs and design system:

- **Public storefront:** customer-facing and browseable without customer login. It shows business information, logo/placeholder, products/services, search, category navigation, listing details and contact/social links. It must not expose a dedicated Promotions section or owner-management controls.
- **Owner admin:** a separate, private management interface for the authenticated business owner. It manages business profile and branding, logo, catalogue/listings, categories, promotions, contact/social details and data export.
- **Shared data:** both interfaces use the same underlying business and listing records. The admin edits data; the public storefront renders only fields and content intended for public display.
- **Deployment shape:** separate interfaces/routes and access boundaries in the same product/codebase are preferred initially. They do not need separate codebases. Each customer still receives an independent business deployment/instance as the service model requires.

### Security boundary (mandatory)

The owner admin is private by authentication and server-side authorization, not merely by hiding navigation or using an obscure URL. Owner-only operations and writes must be enforced by a trusted backend. Never embed admin credentials or privileged secrets in generated public files. The current static-only architecture cannot safely implement authenticated administration or persistent owner edits by itself; introducing an appropriate backend/authentication layer is a prerequisite. Public storefront pages and exports must never leak private admin data.

### Promotions policy

Promotions creation and management is owner-admin functionality. For v1, promotions remain private to the owner/admin and are not rendered as a dedicated public page, navigation item, homepage banner or public promotional placement. Any future public promotion placement requires a separately approved scope change and an explicit owner-controlled publication state.

### Logo behaviour

The public homepage must reserve a consistent logo area. If a business logo exists, display it; otherwise display a neutral, branded placeholder that preserves layout and clearly indicates the logo can be added by the owner. The owner admin will provide the future logo-management control.

### Search experience

Search must work well on mobile and support:
1. Live suggestions while the customer types, matching product/service names and relevant categories.
2. Selecting a suggestion opens its listing/category, while a “view all results” action opens the full results view.
3. Full results show relevant listing image, name, category, business name and price when supplied.
4. Category filters and useful sorting; clear empty state and clear-search action when there are no matches.
5. Search results expose only public catalogue data.

The Phase 2A review branch implements client-side live listing/category suggestions and a dedicated full results page. Search remains static/client-side and has no pagination or server-side index. Search exposes only generated public catalogue fields.

## Data separation and marketplace readiness

Each deployment contains only its own `business/` folder. The build rejects asset paths that point outside that folder. The export file is generated from the same config and contains only whitelisted fields. Stable business/listing IDs and a versioned export format remain the foundation for future marketplace onboarding, with owner consent and verified schema mapping required.

## Security measures actually implemented in the current static version

Business-supplied text is HTML-escaped; URLs must be http(s); colours must be `#RRGGBB`; IDs must be lowercase slugs; phone numbers are validated. Invalid configs fail the build with clear messages. There is currently no authentication, secure admin area or login.

## Demonstration-only items

The three example businesses, their phone numbers, emails and social links are placeholders. Placeholder logos/images are generated SVGs.

## Design system

One stylesheet (`src/styles.css`) and one set of page templates (`src/render.mjs`). Branding changes colours, logo and cover image, so layout and navigation stay consistent for every business. The future admin interface should reuse the design tokens and shared components where appropriate while maintaining a distinct admin information architecture.

## Version 1.2.0 (Phase 2A — review branch)

Public storefront improvements: remove Promotions from public output, add a homepage logo area with a generated fallback, live listing/category suggestions, a dedicated search results page, category filtering, sorting, a clear-search action and mobile-friendly controls. This branch is not yet merged or deployed.

## Version 1.1.0

Validation covers fields with `file › field` messages, brand-colour contrast, safe image paths and placeholder detection for non-demo businesses. Demo data is visibly marked. Exports use a field whitelist. Images have runtime fallbacks. Architecture and data model remain unchanged.
