# Marketplace integration (preparation only)

**Status:** nothing is connected. The marketplace repository `JennyJoshua/png-materials-marketplace` was not inspected during this delivery; no field mapping or compatibility is claimed, and no marketplace fields are assumed.

## Integration points in this template
| Point | Current implementation |
|---|---|
| Business identity | `businessId`, validated and manually assigned; do not regenerate |
| Listing identity | `listingId` per product/service; unique within a business |
| Versioned portable data | schemaVersion `1.0`; JSON export and import |
| Public-safe export | Known-field whitelist; unknown/private extras ignored |
| Import safety | Rejects malformed JSON, incompatible major schema, validation errors and different business ID overwrite without `--force` |
| Independent identity | Branding, URL and hosting remain in the customer's own deployment |
| Marketplace status | Storefront does not claim provider approval |

The export contains business profile, contact, location, branding, social links, currency, categories and listing information. Image files are not included, only their paths.

## Not built; requires marketplace schema and owner decisions
- Map each export field to actual marketplace tables and decide how external IDs are retained.
- Confirm Individual Provider and Business Provider registration model.
- Marketplace approval remains authoritative; a storefront must not self-assert approval.
- Any transfer requires explicit business-owner consent.
- A future connector should be a separate trusted service calling an authenticated marketplace API.
- Confirm price/unit semantics and image upload strategy.

## Export format
`{ schemaVersion: "1.0", exportedFrom: "png-business-digital-starter", business: {...}, catalogue: {...} }`

Import with `npm run import -- path/to/export.json business/`. Minor versions may add optional fields; major versions signal breaking changes.

## Privacy
`/export/business-export.json` is currently published with the site and contains storefront-visible information. It is not access-controlled. See outstanding issues.
