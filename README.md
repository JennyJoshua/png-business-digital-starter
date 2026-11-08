# PNG Business Digital Starter

A reusable, mobile-first storefront template for PNG businesses. One master template; each customer gets their **own independent repository and deployment**. Version 1.1.0 (quality-assurance round), with the next product-design decisions recorded in [the owner admin and public search specification](docs/owner-admin-and-search-spec.md).

## What it does

Reads two JSON files (`business.json`, `catalogue.json`) and generates a fast static website: homepage, about, searchable and filterable catalogue, one page per product or service, contact (call, WhatsApp, email), social links and share buttons. Branding (name, logo, colours, cover image) comes entirely from configuration. Invalid configuration stops the build with an error that names the file and field.

**Next approved product direction:** provide separate public storefront and private owner-admin interfaces, sharing the same business and catalogue data. Promotions management belongs in the owner admin only; there will be no dedicated public Promotions section in v1. See the specification for security, logo placeholder and search behaviour. These are documented requirements, not yet implemented features.

## Quick start (Node.js 18+, no packages to install)
```
npm run build:examples   # builds the 3 demo businesses into dist-examples/
npm run build            # builds business/ into dist/
npm run serve            # preview dist/ at http://localhost:8080
npm run validate         # check business/ without building
npm test                 # 16 automated tests
```
Real-browser checks (optional, needs Python Playwright): `python3 tests/browser/browser-qa.py` (see docs/testing-report.md).

## Demonstration data is clearly marked

Everything shipped (`examples/*` and the starter in `business/`) has `"demo": true`. Demo builds show a yellow **DEMONSTRATION DATA** banner on every page, are marked `noindex`, prefix page titles with `[DEMO]`, label prices **"Sample:"**, and use obvious placeholder phone numbers (`+675 0000 000x`) and `example.com` emails. A real business (`"demo"` omitted or false) that still contains placeholder wording, numbers or emails **fails validation**. To onboard a real business follow `docs/customer-onboarding.md`.

## Folders
- `src/` shared code and design system (no business content)
- `scripts/` build, import, preview server
- `business/` the active business for this copy (edit this)
- `examples/` hardware supplier, general retail, service provider (demo data)
- `docs/` documentation; `tests/` automated tests and browser QA script

## Not included in the current implementation

Payments, carts, customer login, secure owner authentication/admin dashboard, direct social publishing, live marketplace sync, marketplace registration or approval. The future owner admin requires authenticated server-side access; simply hiding a public link or route is not security. See `docs/architecture.md`, `docs/outstanding-issues.md` and `CHANGELOG.md`.
