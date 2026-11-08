# Deployment guide

The build output is the `dist/` folder: plain static files that work on any static host. No deployment, account creation or purchase was performed or tested as part of this delivery. Do not deploy a build that still shows the DEMONSTRATION DATA banner.

## 1. Copy the master template
Use the master repository as a GitHub template or copy the folder. Never work in the master for a customer.

## 2. Create a separate repository
Create one independent repository and hosting deployment per customer. No secrets are needed or may be committed.

## 3. Configure the business
Edit `business/business.json` and `business/catalogue.json`; replace demonstration details and remove `"demo": true`.

## 4. Add branding and images
Add the customer's logo, cover and product photos inside `business/`; reference them with relative paths. Optimise images for mobile data.

## 5. Build and review
Run `npm run validate`, `npm run build`, `npm run serve`; check on a phone and computer. A real-business build must not show the demo banner or Sample prices.

## 6. Deploy independently
Publish the contents of `dist/` on a static host. Options include GitHub Pages (with a build workflow), Cloudflare Pages or Netlify (build command `npm run build`, output `dist`), or any web host/cPanel. Check provider free-tier terms before use; create accounts only with the owner's agreement.

## 7. Domain
Each business may use a provider subdomain or its own domain. Add the domain in the hosting dashboard and follow the DNS records supplied by that provider. Enable HTTPS once DNS resolves.

## 8. Apply future template updates
See `maintenance-guide.md`. Keep customer-specific content in `business/`, merge master improvements, test, rebuild and redeploy.

## Public files
Everything in `dist/` is public, including `export/business-export.json`. It contains only whitelisted storefront-visible fields. Do not place private information in business configuration. Uploaded SVG files are served as-is; only use trusted SVG files.
