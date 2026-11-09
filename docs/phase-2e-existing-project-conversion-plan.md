# Phase 2E — Existing development project conversion plan

**Status:** implementation preparation; no database changes applied  
**Branch:** `phase-2e/single-store-database-foundation`  
**Target:** existing Supabase project `PNG Business Digital Starter Dev` (`rwcwvqlgyckfdrglsbfg`)  
**Architecture authority:** approved Phase 2B–2D decisions, as clarified by the project owner on 2026-11-09

## 1. Owner clarification and scope

The owner has directed that the existing development project be adapted to the approved independent single-store architecture, or that the work be prepared separately on this implementation branch. Do not create another Supabase project unnecessarily.

This later owner direction supersedes the earlier Phase 2D design note that said to leave the existing prototype project untouched. It does **not** authorise destructive database operations, a reset, production deployment, or a merge to `main`.

Phase 2E must convert the current prototype carefully while preserving the old structures until the new schema is verified. The old implementation must not be mistaken for the approved target architecture.

## 2. Verified live project inventory (2026-11-09)

Read-only inspection of the existing Supabase project confirmed:

- Project is active and healthy, in `ap-southeast-2` (Sydney), running PostgreSQL 17.
- Applied migration history contains four Phase 2B migrations:
  - `20261109000651_phase_2b_owner_admin_core`
  - `20261109000726_phase_2b_public_read_and_fk_indexes`
  - `20261109001259_phase_2b_admin_api_views`
  - `20261109002919_phase_2b_public_storefront_read_grants`
- Existing schemas: `public`, `admin_api`, and `app_private`.
- Existing base tables in `app_private`: `businesses`, `business_memberships`, `business_private_settings`, `categories`, `listings`, `promotions`, and `asset_metadata`.
- Existing API views expose the old multi-tenant prototype. The old public API includes `storefront_businesses`, `storefront_categories`, and `storefront_listings`. The old `admin_api` also exposes memberships, private settings and asset metadata.
- All seven existing base tables currently contain zero rows.
- `auth.users` currently contains zero users.
- Supabase Storage currently has no buckets.
- Security Advisor returned no findings at inspection time. Performance Advisor reported six unused indexes on the empty prototype tables; these are not a reason to remove them before the conversion is designed.

The live database inventory and migration history were inspected read-only. No SQL DDL, data writes, Auth changes, Storage changes or migration applications were performed.

## 3. Conversion strategy

Use an additive, reversible-first conversion rather than resetting the project.

1. **Preflight and backup gate**
   - Reconfirm the target project ref and current migration history immediately before execution.
   - Take and verify an appropriate database backup/export before any DDL.
   - Re-run row-count checks. The migration must abort if any legacy table has acquired data since the recorded inspection; data mapping then requires a separate explicit plan.
   - Confirm no user accounts or Storage objects have appeared.

2. **Retire old API exposure without deleting legacy data**
   - Remove the old `admin_api` and public storefront views that conflict with the approved API contract.
   - Preserve the old base tables under clearly named `legacy_*` names in the unexposed `app_private` schema.
   - Revoke browser-role access to the preserved legacy tables.
   - Do not drop the old base tables, Auth records, Storage objects or migration history.

3. **Create the approved single-store base schema**
   - Add `store_profile` with a database-enforced singleton key and immutable `store_uid`.
   - Add `store_admins` with operator-managed invited/active/revoked membership.
   - Create the new `categories`, `listings`, `promotions`, and operator-private `store_settings` base tables.
   - Add immutable portable UUIDs, status constraints, foreign keys, price/currency rules, HTTPS URL validation, indexes and updated-at triggers.
   - Keep all base tables in `app_private`; do not add tenant/business discriminator columns.

4. **Implement the authorisation boundary**
   - Enable RLS on every base table.
   - Implement the narrowly scoped `app_private.is_active_store_admin()` helper, with an empty search path, fully qualified references and tightly restricted EXECUTE grants.
   - Ensure membership writes remain operator-only and no client can self-enrol or self-promote.
   - Ensure revocation is checked against current database membership on subsequent requests.

5. **Expose only the approved API**
   - Public views: `public.storefront_profile`, `public.storefront_categories`, and `public.storefront_listings`.
   - Admin views: `admin_api.store_profile`, `admin_api.categories`, `admin_api.listings`, and `admin_api.promotions`.
   - Every view uses `security_invoker = true`, explicit column lists and least-privilege grants.
   - No public Promotions view, route, banner or public data grant.
   - No browser access to memberships, private settings, operator records or asset metadata.
   - Keep `app_private` out of the Data API exposed-schema list.

6. **Verify before app integration**
   - Test anonymous published reads and private/draft/archived exclusion.
   - Test authenticated non-member denial.
   - Test active administrator reads/writes and multiple active administrators.
   - Test revocation with a previously authenticated session.
   - Test that a second store row cannot be inserted.
   - Run Supabase Security Advisor and inspect grants, policies, function ownership and view options.
   - Update the admin and public app integrations to the new view names in a separately reviewed implementation step. The existing UI currently targets the prototype API and must not be assumed compatible.

## 4. Data migration decision

At the time of inspection, all prototype tables were empty and there were no Auth users or Storage buckets. Therefore, the planned baseline should not invent or seed a business, owner account, administrator or customer data.

The conversion migration should include defensive preflight assertions and stop if old records appear before execution. If records do appear, first prepare and review an explicit field mapping and portable-ID strategy; do not silently discard or automatically transform them.

## 5. Important compatibility warning

The existing admin interface and public storefront were built against the old multi-tenant API names and fields. Renaming the database schema alone will not make those clients compatible. Do not expose broad compatibility views merely to make the old UI appear to work; update the clients to the approved API contract and verify them separately.

## 6. Execution boundary

This document is a conversion plan, not executable SQL. The live database remains unchanged. Before hosted DDL, generate and review the migration through the Supabase migration workflow, verify backup/recovery readiness, and obtain explicit approval for any operation that drops or irreversibly changes existing objects.

No production deployment, customer onboarding, Auth user creation, Storage bucket creation, branch merge or change to `main` is included in Phase 2E.
