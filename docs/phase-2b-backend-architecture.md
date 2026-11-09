# Phase 2B — Owner Admin Backend Architecture

**Status:** Core multi-tenant database foundation and API view layer implemented and verified on the approved development project. Owner authentication, admin UI, Storage upload policies and public storefront integration remain future steps on `phase-2b/owner-admin-interface-foundation`.

**Purpose:** Provide a secure, affordable and marketplace-ready foundation for the private business-owner admin while preserving the existing static public storefront.

## 1. Current baseline and constraints

- Phase 2A is merged into `main`. Public Promotions output is removed; public search is implemented.
- The existing app is a zero-runtime-dependency Node.js static generator. It has no login, server, database or persistent owner editing.
- Each customer continues to receive an independent storefront repository and deployment.
- The data contract preserves stable business/category/listing identifiers for future owner-consented PNG Materials Marketplace onboarding.
- Free Supabase projects are development/testing only. Plan and approve a suitable paid production environment, backups and operations before public launch or live customer data.

## 2. Approved architecture decisions

- **Provider:** Supabase.
- **Topology:** one shared multi-tenant backend project for all Digital Starter storefronts, rather than one project per business.
- **Project:** `PNG Business Digital Starter Dev` (`rwcwvqlgyckfdrglsbfg`), Sydney region (`ap-southeast-2`), Free development project.
- **Separation:** this project is separate from PNG Materials Marketplace and PNG Alert.
- **Owner onboarding:** invitation-only provisioning for the pilot; no self-service business-owner registration.
- **Initial role:** owner only in v1. Membership authorization comes from database rows, never editable user metadata.
- **Storefronts:** independent static deployments; public and private interfaces are separate surfaces but share canonical records.

## 3. Logical data model

UUID primary keys are internal. Stable external identifiers are retained for business, category and listing portability.

| Table | Purpose | Visibility |
|---|---|---|
| `app_private.businesses` | Canonical business profile, stable `business_id`, publication status | Published allowlisted fields through public view; owner full record |
| `app_private.business_memberships` | Maps Auth users to businesses and role/status | Owner's own active membership only |
| `app_private.categories` | Business-specific categories and stable category IDs | Published rows through public view; owner rows |
| `app_private.listings` | Product/service catalogue, stable listing IDs, price/currency, publication state | Published rows through public view; owner rows |
| `app_private.business_private_settings` | Private notes and operational metadata | Active business members |
| `app_private.promotions` | Owner-created promotional drafts and internal copy | Private to authorized owners in v1 |
| `app_private.asset_metadata` | Storage object paths, visibility and ownership metadata | Authorized owners |

### Public data contract

Three explicit allowlist views are provided in `public`:

- `storefront_businesses`
- `storefront_categories`
- `storefront_listings`

All are created with `security_invoker = true`, so underlying table privileges and RLS are applied to the requesting role. The views include only public business/catalogue fields and published rows belonging to published businesses. Promotions, memberships, private settings and asset metadata are not included.

### Owner API contract

An `admin_api` schema contains seven security-invoker views corresponding to the seven application tables. The views are granted only to `authenticated`; the schema has no `anon` usage grant. These views are simple/updatable where appropriate, but underlying column grants and RLS remain authoritative. Memberships are read-only to owners.

**Important configuration gate:** `admin_api` has been created but has not yet been added to the Supabase Data API exposed-schema list. Before the browser admin is connected, expose `admin_api` and `public` only as required, and keep `app_private` unexposed. Verify the final exposed-schema list in the Supabase dashboard. The schema/grant design does not replace this configuration check.

### Data rules

- Business-owned records carry a business foreign key.
- A user may belong to more than one business; a business can support multiple membership rows.
- The v1 role constraint permits only `owner`.
- Stable external identifiers are not updateable through normal owner table grants. Categories/listings are archived rather than hard-deleted.
- Prices are numeric with explicit ISO currency codes (default `PGK`).
- Promotions are excluded from public views.
- Public views use explicit column lists; no `select *` public contract.

## 4. Authorization and publication model

### Anonymous visitor

- Can read only published business fields through `public.storefront_businesses`.
- Can read only published categories/listings belonging to a published business through the other two views.
- Has no table privilege for memberships, private settings, Promotions or asset metadata.
- Cannot write business/catalogue/admin data.

### Authenticated owner

- Reads businesses and catalogue rows only when an active membership exists for that business.
- Creates/updates categories and listings only within a business for which they hold an active owner membership.
- Can access private settings and Promotions only for their own business.
- Cannot create or update membership records, self-promote, or change stable tenant/listing/category identifiers through normal table grants.
- UPDATE policies include both `USING` and `WITH CHECK`.

### Trusted operator

Business creation, owner invitation and membership provisioning remain operator-controlled. No user can self-assign a membership through the client. Any future privileged key must remain server-side and must never enter public HTML, JavaScript, source maps or customer configuration.

## 5. Implemented database safeguards

- Seven application tables in `app_private`; RLS enabled on all seven.
- 22 policies across public reads, owner reads/writes and private data.
- Membership checks use protected `business_memberships` rows and `auth.uid()`, not user metadata.
- Least-privilege grants separate public reads, owner writes and operator provisioning.
- Public and owner API views use `security_invoker = true`.
- `admin_api` is not granted to anonymous users; membership view is not insertable/updateable by authenticated owners due to grants.
- No SECURITY DEFINER function was added.
- Foreign keys used by ownership lookups have indexes; remaining unused-index advisor messages are informational on a new empty schema.

See [Phase 2B security verification](phase-2b-security-verification.md) for actual checks and results.

## 6. Authentication and Storage still to implement

The database foundation does not yet configure Auth invitation settings, create an owner account, or implement sign-in/recovery UI. Before the first owner is invited:
- Verify public sign-up is disabled or otherwise ensure only operator-invited accounts can receive a membership.
- Confirm email delivery and recovery behaviour.
- Provision the owner membership through a trusted operator process.
- Test session expiry and membership suspension.

Storage bucket/object policies are not yet created. Logo and listing image upload must wait until a bucket strategy and tenant-path policies are reviewed. Public assets and private documents must not share an indiscriminately public bucket.

## 7. Supabase project and Free-plan operations

The Digital Starter development project is separate from other projects. PNG Alert was selected by the user for temporary pausing to free the Free-plan active-project slot; the pause operation was still processing at the last status check. No other existing project was changed.

Supabase Free projects are for development/testing only. A paused Free project has a 90-day one-click restore window; pause is not a backup. Maintain independent database and Storage backups before planned pauses. Before public launch, approve a paid production arrangement and migration/recovery plan.

## 8. Migrations and implementation record

Version-controlled SQL migrations:

- `supabase/migrations/20261109000651_phase_2b_owner_admin_core.sql`
- `supabase/migrations/20261109000726_phase_2b_public_read_and_fk_indexes.sql`
- `supabase/migrations/20261109001259_phase_2b_admin_api_views.sql`

Applied migration versions on the development project match these files. The SQL schema has been checked against the live project after application.

## 9. Next sequence

1. Verify Data API exposed schemas and Auth invitation settings.
2. Implement secure owner authentication and operator-controlled invitation/provisioning.
3. Build the private mobile-first admin UI.
4. Add Storage bucket/object policies and image management.
5. Connect the static storefront to the public views behind a tested adapter.
6. Add the versioned marketplace export contract and owner consent flow.

No production deployment or merge to `main` is authorized by this work.
