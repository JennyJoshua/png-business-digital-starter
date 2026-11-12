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

**Current trade-offs:** public storefront content still comes from the static JSON build and catalogue changes require a rebuild/redeploy; search runs in the browser over the generated catalogue (appropriate for small-to-medium catalogues, not tens of thousands). A Supabase-backed owner-admin foundation is merged; the separate platform-admin publication console is in Phase 2C review. Phase 2A is merged into `main`: public Promotions output is removed; homepage logo fallback, live listing/category suggestions and a dedicated results page with category filtering, sorting and clear-search are implemented.

## Product architecture: public storefront + private owner and platform administration

The product will provide two distinct user experiences while sharing one business identity, catalogue, stable IDs and design system:

- **Public storefront:** customer-facing and browseable without customer login. It shows business information, logo/placeholder, products/services, search, category navigation, listing details and contact/social links. It must not expose a dedicated Promotions section or owner-management controls.
- **Owner admin:** `/admin/`, a private management interface for authenticated business owners. It manages business profile and branding, catalogue/listings, categories and private promotions. Database grants/RLS prevent owners from publishing.
- **Platform admin:** `/platform-admin/`, a separate administrator-only interface for reviewing and publishing businesses, categories and listings. Phase 2C adds a database allowlist and protected RPCs; the allowlist is provisioned only through trusted database administration, never from the browser.
- **Shared data:** both interfaces use the same underlying business and listing records. The admin edits data; the public storefront renders only fields and content intended for public display.
- **Deployment shape:** separate interfaces/routes and access boundaries in the same product/codebase are preferred initially. They do not need separate codebases. Each customer still receives an independent business deployment/instance as the service model requires.

### Security boundary (mandatory)

Both admin interfaces are static front ends, not security boundaries. Supabase Auth supplies the user JWT; database grants, RLS and narrowly scoped SECURITY DEFINER RPCs enforce permissions. The platform-admin identity is checked against the app_private.platform_admins allowlist, not editable user metadata. Privileged secrets never appear in generated public files. The public storefront and export remain restricted to explicit whitelisted fields. Phase 2C code and migrations remain on a feature branch until reviewed; hosted migrations are not applied.

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

The merged Phase 2A implementation provides client-side live listing/category suggestions and a dedicated full results page. Search remains static/client-side and has no pagination or server-side index. Search exposes only generated public catalogue fields.

## Data separation and marketplace readiness

Each deployment contains only its own `business/` folder. The build rejects asset paths that point outside that folder. The export file is generated from the same config and contains only whitelisted fields. Stable business/listing IDs and a versioned export format remain the foundation for future marketplace onboarding, with owner consent and verified schema mapping required.

## Security measures implemented across the static frontend and Supabase backend

Business-supplied text is HTML-escaped; URLs must be http(s); colours must be `#RRGGBB`; IDs must be lowercase slugs; phone numbers are validated. Invalid configs fail the build with clear messages. Supabase Auth and database authorization support the merged owner-admin foundation. Phase 2C adds a separate platform-admin allowlist and publication RPCs on a feature branch. Hosted migrations, admin allowlisting and live owner onboarding remain approval-gated.

## Demonstration-only items

The three example businesses, their phone numbers, emails and social links are placeholders. Placeholder logos/images are generated SVGs.

## Design system

One stylesheet (`src/styles.css`) and one set of page templates (`src/render.mjs`). Branding changes colours, logo and cover image, so layout and navigation stay consistent for every business. The future admin interface should reuse the design tokens and shared components where appropriate while maintaining a distinct admin information architecture.

## Phase 2A — public storefront (merged)

Public storefront improvements are merged into `main`: no public Promotions page, homepage logo fallback, live listing/category suggestions, a dedicated search results page, category filtering, sorting and clear-search.

## Version 1.1.0

Validation covers fields with `file › field` messages, brand-colour contrast, safe image paths and placeholder detection for non-demo businesses. Demo data is visibly marked. Exports use a field whitelist. Images have runtime fallbacks. Architecture and data model remain unchanged.


## Phase 2C — platform-admin publication workflow (feature branch)

The Phase 2C implementation adds a separate mobile-responsive `/platform-admin/` route. It uses only the Supabase publishable key and the signed-in user's JWT. A private database allowlist authorizes platform administrators; no public registration, owner metadata or browser-controlled role assignment is used.

The protected review queue returns businesses, categories and product/service listings. Publish/unpublish decisions run through narrowly scoped database functions and create append-only publication audit events with actor, target, prior/new status, reason and timestamp. A category/listing can be published only after its parent business is published. Archived categories/listings cannot be restored through this console. Suspended businesses require a separate reinstatement review.

**Important rollout boundary:** the Phase 2C migration is a versioned file only. It has not been applied to hosted Supabase, no administrator has been allowlisted, and no live publication has been performed. CI uses disposable PostgreSQL 17 fixtures.
