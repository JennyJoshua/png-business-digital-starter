# Customer onboarding

1. Copy the template into a new customer repository. One repository per customer.
2. Edit `business/business.json` (name, permanent `businessId`, type, colours, contacts). Remove `"demo": true` only after replacing all sample data.
3. Add the customer's logo and optional cover image inside `business/`, then reference relative paths. Until a logo is supplied, the public homepage should use the approved neutral logo placeholder (planned; not yet implemented).
4. Edit `business/catalogue.json`; give each listing a permanent `listingId`. Add photos inside `business/images/` and reference them by relative path. Keep images optimised for mobile data.
5. Run `npm run validate`, `npm run build`, and `npm run serve`. Review the storefront in a mobile and desktop browser.
6. Deploy the contents of `dist/` using the deployment guide.
7. Hand over repository and domain access as agreed. Explain that catalogue edits currently require changing JSON and rebuilding. The secure owner admin and persistent editing workflow are future work and must not be represented as available until implemented and tested.

## Approved future owner/public experience

The public storefront is for customers and has no dedicated Promotions section. Promotions management belongs in the authenticated private owner admin; promotions remain private in v1. The owner admin and public storefront share canonical business/catalogue data but have separate interfaces and access boundaries. See [owner admin and public search specification](owner-admin-and-search-spec.md).

Public search is planned to show live suggestions while typing and a full results page with listing image, name, category, business name and price when supplied, plus category filters, sorting and a useful no-results state. These are requirements for a future iteration, not current feature claims.

Alternatively, copy one of the three folders in `examples/` over `business/` and customise it.
