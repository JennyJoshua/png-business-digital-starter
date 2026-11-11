# PNG Business Digital Starter

A reusable, mobile-first storefront template for PNG businesses. One master template; each customer gets their **own independent repository and deployment**. Phase 2A complete; Phase 2B backend foundation in design, with the product direction recorded in [the owner admin and public search specification](docs/owner-admin-and-search-spec.md).

## What it does

Reads two JSON files (`business.json`, `catalogue.json`) and generates a fast static website: homepage, about, live search suggestions, a dedicated searchable results page, category filters and sorting, one page per product or service, contact (call, WhatsApp, email), social links and share buttons. The public build does not generate a Promotions page or expose Promotions navigation. Branding (name, logo, colours, cover image) comes entirely from configuration. Invalid configuration stops the build with an error that names the file and field.

**Approved product direction:** separate the public storefront and private owner-admin interfaces while sharing canonical business and catalogue data. Phase 2A is merged into `main`: public Promotions output was removed, homepage logo fallback and live suggestions were added, and the dedicated results page supports category filtering, sorting and clear-search. Phase 2B has an existing Supabase development schema, RLS foundation, versioned migrations and a first private admin interface on `phase-2b/owner-admin-v1-review`. This is not yet merged or ready for real owner onboarding.

## Quick start (Node.js 18+, no packages to install)
```
npm run build:examples   # builds the 3 demo businesses into dist-examples/
npm run build            # builds business/ into dist/
npm run serve            # preview dist/ at http://localhost:8080
npm run validate         # check business/ without building
npm test                 # automated regression tests
```
Real-browser checks (optional, needs Python Playwright): `python3 tests/browser/browser-qa.py` (see docs/testing-report.md).

## Phase 2B owner-admin development

- Development backend: the existing `PNG Business Digital Starter Dev` Supabase project, separate from PNG Materials Marketplace.
- One shared multi-tenant backend; invited owner accounts only; one active owner per business is the approved target.
- SQL migration history and owner-admin source are being reviewed on the Phase 2B feature branch.
- The admin interface is built under `/admin/`, uses a Supabase publishable key, and relies on database grants and RLS for authorization.
- Before any real owner onboarding: verify Data API schema exposure, Auth signup/anonymous settings, invitation and recovery email delivery, browser CRUD, tenant isolation, and the one-owner-per-business database constraint.
- Storage uploads, audit events, public storefront synchronization and production infrastructure are still outstanding.
- Do not use the Free development project for live customer data or production. See the Phase 2B implementation and readiness documents.

## Demonstration data is clearly marked

Everything shipped (`examples/*` and the starter in `business/`) has `"demo": true`. Demo builds show a yellow **DEMONSTRATION DATA** banner on every page, are marked `noindex`, prefix page titles with `[DEMO]`, label prices **"Sample:"**, and use obvious placeholder phone numbers (`+675 0000 000x`) and `example.com` emails. A real business (`"demo"` omitted or false) that still contains placeholder wording, numbers or emails **fails validation**. To onboard a real business follow `docs/customer-onboarding.md`.

## Folders
- `src/` shared code and design system (no business content)
- `scripts/` build, import, preview server
- `business/` the active business for this copy (edit this)
- `examples/` hardware supplier, general retail, service provider (demo data)
- `docs/` documentation; `tests/` automated tests and browser QA script

## Not included in the current implementation

Payments, carts, customer login, image uploads, public storefront synchronization, direct social publishing, live marketplace sync, marketplace registration or approval. The initial owner-admin foundation is not yet merged or enabled for real business operations; it requires verified Auth, API exposure, RLS, invitation and production gates. Simply hiding a public link or route is not security. See `docs/architecture.md`, `docs/outstanding-issues.md` and `CHANGELOG.md`.
