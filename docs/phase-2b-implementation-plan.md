# Phase 2B — Implementation Plan

**Working branch:** `phase-2b/independent-single-store-architecture`  
**Architecture:** one independent app/repository/deployment/Supabase project per store.  
**Status:** architecture and plan revised; code and database still reflect an earlier shared multi-tenant prototype.

## Product outcome

Deliver a reusable storefront/admin template that can be copied into an independent business instance. Each instance serves exactly one store. One or more invited administrators can manage that store's content. The platform operator maintains the underlying Supabase project, database schema, migrations, backups and technical operations.

Public visitors browse without accounts. Public Promotions output remains excluded. Data must remain portable for a future owner-consented connection to PNG Materials Marketplace.

## Approved decisions

- Each business instance has its own GitHub repository under the platform operator's account.
- Each instance has its own hosting/deployment.
- Each instance has its own Supabase project under the platform operator's account.
- A project/database contains one store only; do not use a shared multi-tenant customer database.
- One or more administrators may manage the same store.
- Store administrators are content custodians, not database or Supabase project operators.
- The platform operator provisions and maintains projects, schemas, migrations, security, backups and recovery.
- Future central marketplace profiles/directory/social features are deferred to PNG Materials Marketplace.
- The existing Supabase project and shared-tenant implementation are retained as a prototype until a separately approved disposition.

## Work sequence

### 2B.1 — Architecture decision and documentation
<badge>Complete</badge>
The independent single-store-per-project model, role boundaries, future marketplace boundary and transition cautions are documented.

### 2B.2 — Single-store data contract
<badge>Next — design required</badge>
- Define the singleton store profile and stable portable store ID.
- Define categories, listings, promotions, settings and asset metadata.
- Define multiple administrators for one store, with operator-controlled provisioning and revocation.
- Define immutable stable IDs and versioned export/import JSON.
- Specify publication states and public-field allowlists.
- Avoid business-to-many-tenant relationships in an instance schema.

### 2B.3 — Operator provisioning and maintenance design
- Document how the operator creates each Supabase project and records its repository/project/deployment association.
- Define repeatable clean-project migrations and version tracking.
- Define operator-only initial store/admin provisioning.
- Define backup, restore, recovery, migration rollback/forward-fix and incident procedures.
- Ensure store admins do not need Supabase dashboard access or database credentials.

### 2B.4 — Database schema and security implementation
- Create a clean baseline migration for the single-store model.
- Enable RLS on every exposed table and use least-privilege grants.
- Enforce the one-store invariant.
- Support multiple active admin memberships for that one store.
- Prevent client-side self-enrolment, self-promotion and membership writes.
- Ensure public access returns only published, allowlisted content.
- Keep private settings, membership data, asset metadata and Promotions out of public responses.
- Use publishable keys in browser code only; never expose secret/service-role keys.
- Run Supabase advisors and regression tests.

### 2B.5 — Admin application adaptation
- Replace old tenant-selection/membership assumptions with one-store membership verification.
- Support one or more invited admins for the instance.
- Provide profile/branding, categories, listings and private Promotions management.
- Add approved contact/social editing, image uploads after Storage policy review, and data export.
- Keep database provisioning and privileged operations out of the browser.
- Confirm admin UI works on Android/mobile browsers.

### 2B.6 — Public storefront data integration
- Add a tested data adapter to read published records from that instance's own project.
- Keep Promotions excluded from public pages, navigation, banners and placements.
- Preserve static build/config fallback until live data behaviour passes.
- Test publication, archive, search, category filters and listing detail pages.

### 2B.7 — Integration and security acceptance
- Test on a clean disposable Supabase project, not by assuming the old prototype proves the new design.
- Test anonymous REST reads, draft/archived exclusion and private-data denial.
- Test unauthenticated admin denial.
- Test two administrators of the same store can access permitted functions.
- Test a non-member is denied and membership revocation removes access after session/token considerations are handled.
- Test admins cannot access database infrastructure or privileged keys.
- Test public browser storefront and admin workflows on mobile.
- Verify no cross-instance access: each app points only to its own Supabase project.
- Record actual pass/fail evidence; do not label SQL simulation as browser/REST integration.

### 2B.8 — Template release and customer instance
- Prepare a repeatable copy/customisation procedure.
- Create each customer repo, hosting site and Supabase project independently.
- Apply reviewed migrations and operator provisioning.
- Complete security, accessibility, mobile and recovery checks.
- Release only after explicit owner approval. Do not merge to main or deploy production without approval.

## Required security acceptance matrix

| Scenario | Expected result |
|---|---|
| Anonymous visitor reads published store profile/categories/listings | Only explicitly allowlisted published fields returned |
| Anonymous visitor requests draft/archived content | No row returned |
| Anonymous visitor requests memberships, private settings, asset metadata or Promotions | Denied / not exposed |
| Visitor opens admin interface without a session | Sign-in screen; no private data |
| Authenticated non-member calls admin API | Denied / zero rows |
| Active administrator reads or edits this store's permitted content | Allowed |
| Two active administrators belong to same store | Both can perform their permitted admin functions |
| Administrator attempts to add/promote another admin from client | Denied |
| Administrator attempts privileged database operation | Denied; no privileged key available |
| Administrator's membership is revoked | Access is blocked according to tested session/revocation design |
| App instance A requests data from instance B | No shared backend path; each app is configured only for its own project |
| Store data export is requested | Versioned, scoped export; external sharing requires owner consent |

## Current prototype — not the target acceptance baseline

The branch currently contains the earlier multi-tenant database, RLS policies, public/admin views and an initial owner-admin app. Its historical SQL tests cover cross-tenant isolation in that old model. The implementation has not yet been redesigned for a single-store database with multiple admins. Do not proceed with real owner invitations, live customer data, customer deployment or production integration using the old implementation.

The old development project must not be destructively converted as part of this planning phase. First design and test the new baseline on a clean disposable project; decide separately whether to retain, reset or retire the old project.

## Out of scope for this phase

- Central Facebook-like business profiles/directory or cross-business social platform.
- Central marketplace registration, buyer accounts or marketplace-wide admin.
- Payments, carts and customer login.
- Automatic cross-instance synchronisation.
- Any paid infrastructure without separate approval.

No production deployment, main merge, destructive database action or customer onboarding is authorised by this plan.
