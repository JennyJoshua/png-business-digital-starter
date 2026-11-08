# Business configuration (schemaVersion 1.0)

Two files per business, in `business/` (or an example folder).

## business.json

| Field | Required | Notes |
|---|---|---|
| `schemaVersion` | no | `"1.0"` |
| `businessId` | yes | Stable ID: 2–64 chars, lowercase letters, digits, hyphens. Never change after publishing. |
| `name` | yes | Max 80 chars |
| `type` | yes | `hardware-supplier`, `general-retail`, `service-provider`, or `other` |
| `demo` | no | `true` marks demonstration data (banner, noindex, Sample labels). Remove or set false for a real business. |
| `tagline`, `description` | no | Shown in hero and About |
| `logo`, `coverImage` | no | Relative path inside business folder; png/jpg/jpeg/webp/svg. URLs, `..`, absolute paths rejected. Missing file produces warning/fallback. |
| `brand.primary`, `brand.accent` | no | `#RRGGBB`. Primary contrast with white and accent contrast with dark text must be at least 4.5:1. |
| `phone`, `whatsapp` | no | Digits and optional leading + (e.g. `+67570000000`). Missing hides that contact link. |
| `email` | no | Optional contact email |
| `location.address/town/province` | no | Optional location details |
| `social` | no | Label-to-URL map; only http/https URLs |
| `currency` | no | `{code, symbol, position: before/after, decimals}`; default PGK/K/2 decimals |

## catalogue.json
- `categories`: list of `{id, name}`.
- `listings`: list of product/service objects.
- `listingId` is required, stable and unique within the business.
- `name` and `kind` (`product` or `service`) are required.
- `categoryId` must exist in categories.
- `description`, `image`, `price`, and `priceNote` are optional.
- Omit price for "Ask for price".

Run `npm run validate` to check configuration without building. Limits: business name 80, tagline 160, description 2000, listing name 100, listing description 1000 characters. Extra fields are ignored and not exported.

## Replacing demonstration content
1. Change business ID, name, type, description, contacts, location and social links.
2. Replace sample categories/listings and their IDs.
3. Add real logo, cover and listing images inside `business/`.
4. Remove `"demo": true` only after all sample values are replaced.
5. Run validation, build, and confirm no DEMONSTRATION DATA banner or Sample prices remain.
