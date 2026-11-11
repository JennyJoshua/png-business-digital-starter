# PNG Materials Marketplace Compatibility Assessment

**Date:** 11 November 2026  
**Status:** Read-only schema assessment; no integration or database changes  
**Repositories reviewed:**
- `JennyJoshua/png-business-digital-starter` — current `main`
- `JennyJoshua/png-materials-marketplace` — current `main`

## Executive finding

The Business Digital Starter is a useful **data-source and onboarding precursor**, but its version 1.0 export is **not directly import-compatible** with the current Materials Marketplace schema.

The projects share useful concepts—provider identity, product listings, categories, stable external identifiers and PNG business contact/location data—but several fields and relationships do not line up. Most importantly, the Marketplace currently models a provider as one `ProviderProfile` per registered user, while the Starter has an independent `businessId` and catalogue. The Marketplace also has no service-listing model or canonical currency field on product listings.

**Recommendation:** preserve the Starter as a standalone storefront and define a versioned, owner-consented import/API contract. Do not connect the Starter directly to the Marketplace database, write to Marketplace tables from the browser, or claim that current schema compatibility exists.

## What was inspected

- Marketplace Prisma schema and committed migrations for the foundation, provider foundation and product listings.
- Starter integration notes, demo business configuration and catalogue structure.
- No live Supabase database, credentials, production environment, private customer data or deployed application was accessed.
- No schema migration, API, import, account, deployment or data mutation was performed.

## Field and concept mapping

| Starter v1.0 field/concept | Marketplace model | Assessment |
|---|---|---|
| `businessId` (stable string) | `ProviderProfile.id` (UUID) and `userId` | **No direct field.** Preserve Starter ID as an external reference; do not replace or regenerate it. |
| Business name | `ProviderProfile.displayName` | Good conceptual match; length/validation rules differ. |
| Business type | `ProviderProfile.providerKind` | Partial match only. Marketplace values are `INDIVIDUAL` or `BUSINESS`; Starter's current type values need an explicit mapping. |
| Products/services capability | `ProviderProfile.providerType` | Marketplace supports `PRODUCTS`, `SERVICES`, `BOTH`; useful mapping, but must be owner-confirmed. |
| Description | `ProviderProfile.description` | Good conceptual match. |
| Phone, public email, address | Corresponding provider fields | Mostly direct; field lengths and validation need normalization. |
| Province, district, town | Marketplace location fields | Partial match. Starter currently has town/province/address; district may be absent. |
| Logo URL | `ProviderProfile.logoUrl` | Conceptual match; asset ownership, URL lifetime and upload migration are unresolved. |
| Brand colours, tagline, social links | No corresponding provider fields in current schema | Keep in Starter or define separate marketplace metadata only if the product needs it. |
| Currency code/symbol/format | No currency field on `ProductListing` | **Blocking data ambiguity.** PGK must not be silently assumed for every future business. |
| Category IDs/names | `ProductCategory` / `ServiceCategory` | Partial match. Marketplace categories are global name-based records, while Starter categories are business catalogue records with stable slugs. Mapping/deduplication rules are needed. |
| `listingId` (stable string) | `ProductListing.id` (UUID) | **No direct external ID.** Preserve Starter ID in a dedicated external-ID mapping/field with uniqueness rules. |
| Product name/brand/specification/description | `ProductListing` fields | Good partial match. Starter does not currently define all Marketplace product attributes. |
| Product price and price note | `ProductListing.price` and `unit` | Partial match. Numeric price maps, but `priceNote` needs a validated unit mapping. Marketplace currently requires price greater than zero. |
| Product availability | `ProductListing.stockStatus` | No explicit equivalent in the Starter v1.0 export; do not invent stock status. |
| Publication state | Provider/listing statuses | Requires an explicit approval/publication mapping. A Starter listing must not become Marketplace-active automatically. |
| Service listing | `ServiceCategory` only | **Missing Marketplace service-listing entity.** Service categories exist, but the inspected schema has no service listing table/model. |
| Images | `logoUrl` only on provider; no product image field in inspected listing model | No complete image mapping. Starter currently exports paths, not image bytes. |

## Architectural and security findings

### 1. Provider ownership model differs

Marketplace `ProviderProfile.userId` is unique, so the current schema models one provider profile per user. The Starter's independent business identity is not tied to a Marketplace user account. Import therefore requires an authenticated provider account and an explicit ownership/linking process.

The Starter must not create accounts, claim ownership or create a provider profile on behalf of a business without that business owner's consent and onboarding approval.

### 2. Marketplace access is server-mediated

The Marketplace migrations enable RLS and revoke direct `anon` and `authenticated` table privileges. Its schema comments state that application data access is performed through server-side Prisma; Prisma's privileged server connection bypasses RLS.

This is materially different from a design where each Starter browser talks directly to shared Supabase tables under end-user RLS policies. **Do not reuse the Marketplace database as a direct browser-access backend for Starter admin.** Any future cross-product integration should use a narrowly scoped, authenticated server-side API with its own authorization, validation and audit trail.

### 3. Marketplace approval remains authoritative

Marketplace provider status and verification are controlled by Marketplace workflows. A Starter storefront's existence, publication status or owner-entered details do not establish Marketplace approval. Imported records should enter a non-public/pending state until the Marketplace's own review process accepts them.

### 4. Business and listing IDs must remain portable

The Starter's `businessId` and `listingId` values should remain stable across exports and imports. Marketplace UUID primary keys should remain internal database identifiers. Use an explicit mapping layer (for example, source system + external business/listing ID) with uniqueness constraints and idempotent import behaviour. Do not overload Marketplace UUIDs with Starter slugs.

### 5. The two products should not share a database by default

The Starter Phase 2B proposal recommends a shared multi-tenant Supabase backend for Starter owner-admin. The Marketplace currently has its own application data model and server-side access boundary. The safer initial boundary is:
- Starter owner-admin manages its own canonical Starter business/catalogue records.
- Marketplace owns Marketplace provider/listing records and approval state.
- A future connector sends an owner-approved, validated export to a Marketplace API.
- No shared database or direct cross-project table writes are assumed.

This keeps the Starter independently usable and avoids coupling its admin lifecycle to Marketplace internals.

## Required work before integration

1. Define an explicit business-owner consent and provider-account linking flow.
2. Agree a stable external-ID mapping for Starter business and listing IDs.
3. Decide whether service listings will be supported by a new Marketplace model or remain out of scope for the first connector.
4. Define canonical currency and price/unit semantics; do not infer currency from location.
5. Map categories using stable category identifiers, not name-only matching.
6. Define the import state machine so imported providers/listings remain non-public until Marketplace review.
7. Define image transfer/storage rules and asset ownership.
8. Specify an authenticated Marketplace API with validation, authorization, idempotency and audit logging.
9. Add contract tests using fictional fixtures only.
10. Test duplicate imports, changed records, revoked consent, rejected providers and partial failures.

## Recommended next sequence

| Order | Work | Can proceed now? |
|---|---|---|
| 1 | Keep the Starter demo and public storefront unchanged | Yes; current instruction |
| 2 | Record the schema gap and preserve the versioned export contract | Yes; this assessment |
| 3 | Review the Starter Phase 2B backend proposal against this boundary | Yes; design review only |
| 4 | Finalize owner-admin provider/tenant/onboarding decisions | Requires owner decisions |
| 5 | Design Starter-owned schema, RLS and cross-tenant tests | After decisions; no live apply |
| 6 | Implement owner-admin and backend | After architecture approval |
| 7 | Design Marketplace API and import contract | Separate Marketplace scope and approval |
| 8 | Run fictional end-to-end contract tests | After both sides expose reviewed contracts |
| 9 | Onboard real businesses and transfer their data | Only with explicit business-owner consent and production readiness |

## Explicit non-actions

This assessment does not authorize or perform:
- changes to either repository's application code or database schema;
- creation or modification of Supabase projects, tables, policies, credentials or migrations;
- public deployment or launch;
- transfer of real business data;
- Marketplace provider registration, approval or account creation;
- public Promotions content or a change to the current demo.

## Conclusion

The Starter-to-Marketplace direction remains sound as a **consent-based onboarding and data-portability path**, but direct schema compatibility is not yet present. The key design decision is to keep the two products' data and authorization boundaries separate and connect them later through a versioned, authenticated API and explicit external-ID mapping.
