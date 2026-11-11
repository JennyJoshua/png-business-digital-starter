# Fictional storefront demonstration pilot

**Status:** Prepared as a demonstration fixture; not a real customer pilot.

## Purpose

Exercise the existing static storefront generator with a more complete, PNG-focused hardware and building-supplies catalogue. This is intended to test the product workflow before approaching a real business.

## Fictional business identity

- **Name:** Kumul BuildMart (Demo)
- **Business ID:** `demo-kumul-buildmart`
- **Location:** Demo Town, Gulf Province (fictional sample location)
- **Business type:** Hardware supplier
- **Currency display:** PGK / K
- **Contact details:** obvious placeholder phone number and `example.com` email
- **Logo and product imagery:** generated placeholders; no real brand assets
- **Data status:** every business, product, service, price, location and contact detail is fictional

Do not contact the placeholder number, send messages to it, treat the sample prices as market prices, or represent this business as a real supplier.

## Files

- `examples/demo-pilot/business.json` — fictional business profile and branding
- `examples/demo-pilot/catalogue.json` — sample catalogue with stable business/listing IDs
- Generated output is written to `dist-demo-pilot/` and is not committed or deployed

## How to run

Requires Node.js 18 or newer; no third-party packages are required.

```sh
npm test
node scripts/build.mjs examples/demo-pilot dist-demo-pilot
node scripts/serve.mjs dist-demo-pilot
```

Open the local preview URL printed by the server. Do not enable a public deployment for this fixture.

## Demonstration QA checklist

- [ ] Build completes and emits the expected eight listing pages
- [ ] Every page displays the demonstration warning and noindex metadata
- [ ] Homepage branding and generated logo fallback render
- [ ] Catalogue search suggestions work for product names and categories
- [ ] Full results page supports category filters and sorting
- [ ] Each product/service detail page opens from its card
- [ ] Sample prices display with the PGK symbol and a clear sample label
- [ ] Unpriced delivery service shows an enquiry/price-needed state
- [ ] Phone, WhatsApp and email controls are visibly placeholders and are not treated as working contact channels
- [ ] No public Promotions section or page is present
- [ ] No horizontal overflow at narrow mobile viewport widths
- [ ] Keyboard navigation and visible focus states are usable
- [ ] Export contains stable business/listing IDs and only approved public fields

## Evidence and limitations

Automated CI validates the shared generator and demo fixture. That does not substitute for manually opening the generated site in a real mobile browser or testing on a physical Android device. Record those checks separately when a suitable local preview environment is available.

This pilot does not implement owner login/admin, payments, checkout, customer accounts, live marketplace synchronisation, provider approval, a custom domain or public deployment. Those remain out of scope.

## Exit criteria before a real-business pilot

1. Automated tests and demo build pass.
2. Mobile and desktop visual checks are recorded.
3. Search, category, sorting, listing and contact-link behaviour are checked.
4. Owner/admin and marketplace limitations are clearly explained.
5. A real business owner explicitly agrees to participate and approves all data/assets before any real details are entered.
