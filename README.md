# PNG Business Digital Starter

A reusable, mobile-first storefront template for PNG businesses. One master template; each customer gets their **own independent repository and deployment**. Phase 2A is complete. Phase 2B has begun: the multi-tenant Supabase development database foundation and first private owner-admin interface are implemented on the working branch. Supabase Auth/Data API dashboard configuration, owner provisioning, live storefront sync and production deployment remain gated.

## What it does

Reads two JSON files (`business.json`, `catalogue.json`) and generates a fast static website: homepage, about, live search suggestions, a dedicated searchable results page, category filters and sorting, one page per product or service, contact (call, WhatsApp, email), social links and share buttons. The public build does not generate a Promotions page or expose Promotions navigation. Branding (name, logo, colours, cover image) comes from configuration. Invalid configuration stops the build with an error that names the file and field.

**Approved product direction:** separate the public storefront and private owner-admin interfaces while sharing canonical business and catalogue data. Public Promotions remain excluded. The Phase 2B database foundation uses one shared multi-tenant Supabase development project with database-enforced tenant isolation. The separate `admin/` app provides invited-owner sign-in, password recovery, profile/brand-colour editing, categories, listings and private Promotions. It uses the Supabase publishable key only; all owner data requests use the `admin_api` schema and rely on RLS. It is not production-ready: the `admin_api` schema must first be exposed in Data API settings, Auth signups must be disabled, invitation delivery must be verified, and live storefront sync is still pending.

## Quick start (Node.js 18+, no packages to install)

```
npm run build:examples
npm run build
npm run serve
npm run validate
npm test
```

Real-browser checks (optional, needs Python Playwright): `python3 tests/browser/browser-qa.py` (see `docs/testing-report.md`).

## Phase 2B backend

- Development project: `PNG Business Digital Starter Dev` (Sydney, Supabase Free).
- SQL migrations: `supabase/migrations/`.
- Owner admin source: `admin/`; static builds publish it under `/admin/`.
- Supabase SDK is loaded from a pinned jsDelivr ESM URL (`@supabase/supabase-js` 2.119.0); internet access to that CDN is required for admin sign-in.
- Required manual dashboard gates: see `docs/phase-2b-owner-auth-setup.md`.
- Database design and security verification: see `docs/phase-2b-backend-architecture.md` and `docs/phase-2b-security-verification.md`.
- Do not use this Free development project for live customer data or production.

## Demonstration data is clearly marked

Everything shipped (`examples/*` and the starter in `business/`) has `"demo": true`. Demo builds show a yellow **DEMONSTRATION DATA** banner on every page, are marked `noindex`, prefix page titles with `[DEMO]`, label prices **"Sample:"**, and use obvious placeholder phone numbers (`+675 0000 000x`) and `example.com` emails. A real business (`"demo"` omitted or false) that still contains placeholder wording, numbers or emails **fails validation**. To onboard a real business follow `docs/customer-onboarding.md`.

## Folders

- `src/` shared code and design system (no business content)
- `scripts/` build, import, preview server
- `business/` the active business for this copy (edit this)
- `examples/` hardware supplier, general retail, service provider (demo data)
- `docs/` documentation; `tests/` automated tests and browser QA script
- `supabase/` version-controlled database migrations

## Not yet implemented

Owner sign-in and initial private admin UI are implemented but not yet enabled for use. Invitation provisioning, logo/listing image upload, live public storefront integration, payments, carts, customer login, direct social publishing, live marketplace sync, marketplace registration or approval remain outstanding. The admin must use real Auth sessions and RLS; hiding a public link or route is not security. See `docs/architecture.md`, `docs/outstanding-issues.md` and the Phase 2B documents.
