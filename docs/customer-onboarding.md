# Customer onboarding

1. Copy the template into a new customer repository. One repository per customer.
2. Edit `business/business.json` (name, permanent `businessId`, type, colours, contacts). Remove `"demo": true` only after replacing all sample data.
3. Add the customer's logo and optional cover image inside `business/`, then reference relative paths.
4. Edit `business/catalogue.json`; give each listing a permanent `listingId`. Add photos inside `business/images/` and reference them by relative path. Keep images optimised for mobile data.
5. Run `npm run validate`, `npm run build`, and `npm run serve`. Review the storefront in a mobile and desktop browser.
6. Deploy the contents of `dist/` using the deployment guide.
7. Hand over repository and domain access as agreed. Explain that catalogue edits currently require changing JSON and rebuilding.

Alternatively, copy one of the three folders in `examples/` over `business/` and customise it.
