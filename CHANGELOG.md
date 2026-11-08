# Changelog

## Unreleased — Phase 2B backend foundation (design only)
- Started a separate `phase-2b/owner-admin-backend-foundation` branch.
- Added a backend architecture decision brief covering Supabase as the recommended candidate, shared multi-tenant deployment, data model, authorization boundaries, storage, onboarding and security tests.
- No provider connection, database project, schema migration, credentials, authentication flow or admin UI has been created. Platform and onboarding decisions remain explicit approval gates.


## Phase 2A — public storefront (merged into main)
- Removed the Promotions navigation item and stopped generating a public `promo.html`; promotions remain owner-admin-only in v1.
- Added a consistent homepage logo area using the configured logo or generated branded fallback.
- Added live product/service and category suggestions beneath the homepage search field.
- Added a dedicated full search-results page with listing images, names, category, business name and price where supplied.
- Added category filtering, name/price sorting, result counts, clear-search control and an accessible no-results state.
- Added regression tests for the public search experience and absence of public Promotions output.
- PR #3 merged into `main`; the changes are part of the current codebase.

## Unreleased — owner admin and public storefront product decisions
- Recorded the approved split between a public customer storefront and a private authenticated business-owner admin interface, sharing canonical business/catalogue data and design tokens.
- Specified that Promotions management is admin-only and promotions remain private in v1; no public Promotions page, navigation item, homepage banner or public placement.
- Specified a homepage logo area with a neutral placeholder when no logo is configured.
- Specified mobile live search suggestions, selectable matches, a full results view, category filters/sorting and a useful no-results state.
- Documented that secure owner administration requires authentication, server-side authorization and a trusted backend; these are future requirements, not current static-site capabilities.

## 1.1.0 — quality-assurance corrections
- Marked all demo data; added banner, noindex, [DEMO] titles and Sample price labels.
- Added placeholder phone/email checks and validation for supported business types, field lengths, IDs, colours, contacts, categories, prices and image paths.
- Added brand colour contrast checks, missing-image fallbacks and runtime image fallback.
- Improved mobile navigation, focus rings, skip link, landmarks, headings, labels and 44px tap targets.
- Added field-whitelisted export and safer import with schema compatibility and business-ID overwrite guard.
- Expanded automated tests and added optional Chromium/axe-core browser QA.
- Breaking: unsupported business types and unsafe image paths now fail validation.

## 1.0.0 — initial template
