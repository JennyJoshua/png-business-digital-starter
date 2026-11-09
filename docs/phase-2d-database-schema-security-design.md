# Phase 2D — Single-store database schema and security design

**Status:** detailed design proposal for owner review; not executable migration SQL  
**Branch:** `phase-2d/schema-and-security-design`  
**Architecture source:** `docs/single-store-data-contract.md`  
**Operator process:** `docs/operator-provisioning-and-maintenance.md`

## 1. Design objective

Replace the earlier shared multi-tenant prototype with a clean single-store database baseline. Every customized app gets its own Supabase project and this schema contains one store only. Multiple invited administrators may manage that store's approved content. The platform operator retains database and infrastructure control.

This document specifies logical tables, constraints, API exposure, grants, RLS intent, administrator lifecycle and migration order. It is not a SQL migration and does not authorise changes to any Supabase project.

## 2. Decisions recommended for the first implementation

| Area | First-version decision | Reason |
|---|---|---|
| Store identity | One singleton `store_profile` row, database-enforced | Prevents multiple stores in one project |
| Portable identity | Immutable UUIDs on store, category, listing and promotion | Stable export/import independent of editable names/slugs |
| Admin roles | One permission class: active `store_admin` | All admins have equal content permissions; no unapproved owner/editor hierarchy |
| Admin provisioning | Operator sends Auth invitation and creates/activates membership | No public registration or self-promotion |
| Admin revocation | Set membership status to `revoked`; RLS checks current DB membership on every request | Blocks app data access even while an old JWT has not expired |
| Deletes | Archive content; no ordinary hard-delete permissions for admins | Preserves references and recovery options |
| Public data | Explicit public views over published rows only | Keeps private columns/tables out of public responses |
| API | Expose only `public` and `admin_api`; keep `app_private` unexposed | Separates public/admin API surfaces from base tables |
| Images | Keep current URL fields for v1; defer Supabase Storage buckets and upload policies | Avoids introducing untested object-level access rules in this baseline |
| Store settings | Operator-managed/private in v1 | Do not expose arbitrary JSON settings to browser clients |
| Promotions | Admin-only; no public view, route, banner, navigation or storefront placement | Preserves the approved public/admin separation |

## 3. Proposed schema layout

- `app_private`: base tables and the narrowly scoped membership-check function. This schema is not exposed through the Supabase Data API.
- `public`: read-only storefront views with an explicit public column allowlist.
- `admin_api`: admin-facing views for approved content-management operations. Only authenticated requests with active store membership can read/write through them.
- Supabase-managed `auth` and `storage` schemas remain provider-managed. The app does not write directly to `auth` tables.

The Data API exposed-schema setting must be checked for each project. Target exposed schemas: `public` and `admin_api`; never add `app_private`.

## 4. Logical table specification

All base tables live in `app_private`. Enable RLS on every base table as defence in depth. Use UUID primary keys for internal row identity and separate immutable portable UUIDs for exported entities.

### 4.1 `store_profile` — exactly one row

| Column | Type / rule | Notes |
|---|---|---|
| `singleton_key` | smallint primary key, CHECK = 1 | Database-level one-row invariant |
| `store_uid` | uuid unique, generated once | Immutable portable store ID |
| `name` | text, required, 1–120 chars | Public display name |
| `slug` | text, required, unique | Editable URL label; not an identifier |
| `business_type` | text, constrained enum-like check | hardware_supplier, general_retail, service_provider, other |
| `tagline`, `description` | text, nullable | Public only when profile is published |
| `phone`, `whatsapp`, `public_email`, `website_url` | text, nullable | Explicit business contact fields, not admin account details |
| `address_line`, `town`, `province` | text, nullable | Public only when the business chooses to publish |
| `country_code` | char(2), default PG | ISO country code |
| `logo_url`, `cover_image_url` | text, nullable | HTTPS URLs for v1; no bucket upload workflow yet |
| `brand_primary`, `brand_accent` | text, nullable | Validated colour values |
| `social_links` | jsonb object, default {} | Validate allowed keys and HTTPS URLs in app and DB |
| `publication_status` | draft / published / suspended | Only operator creates row; admins may edit approved profile fields and publication status |
| `created_at`, `updated_at` | timestamptz | Server-generated; updated timestamp maintained by trigger |

**Invariant:** `singleton_key = 1` as the primary key means a second store row cannot be inserted. Only the operator provisioning process inserts the initial row. Store administrators cannot change `singleton_key` or `store_uid`, delete the row, or create a second store.

### 4.2 `store_admins` — membership registry

| Column | Type / rule | Notes |
|---|---|---|
| `user_id` | uuid primary key, FK to `auth.users(id)` | One identity per admin per project |
| `status` | invited / active / revoked | Only active grants admin access |
| `invited_by` | uuid nullable, FK to auth.users | Operator audit reference |
| `invited_at`, `activated_at`, `revoked_at` | timestamptz nullable | Lifecycle timestamps |
| `created_at`, `updated_at` | timestamptz | Server-generated |

No business/store foreign key is needed: the project itself is the store boundary. Do not add customer-facing INSERT/UPDATE/DELETE grants, an admin API view, or a self-service membership endpoint for this table. Operator-only provisioning updates it.

### 4.3 `categories`

- `id` uuid primary key; `category_uid` uuid unique and immutable.
- `name` required (1–80 chars); `slug` required and unique within this store.
- `description` nullable; `sort_order` integer default 0.
- `publication_status`: draft / published / archived.
- `image_url` nullable HTTPS URL for v1.
- `created_at`, `updated_at` server-maintained.

### 4.4 `listings` (products and services)

- `id` uuid primary key; `listing_uid` uuid unique and immutable.
- `category_id` nullable FK to categories; deletion of a referenced category is restricted.
- `kind`: product / service.
- `name` required (1–160 chars); `slug` unique within this store.
- `description`, `reference_code`, `price_unit`, `availability_note` nullable.
- `price` numeric(12,2), nullable, non-negative; missing means “contact business”, not zero.
- `currency` char(3), default PGK, constrained to uppercase ISO 4217 code.
- `publication_status`: draft / published / archived.
- `image_url` nullable HTTPS URL for v1; multiple image uploads are deferred.
- `sort_order` integer default 0; timestamps server-maintained.

### 4.5 `promotions` — private admin content

- `id` uuid primary key; `promotion_uid` uuid unique and immutable.
- `title` required; `internal_copy`/description nullable.
- `status`: draft / active / archived; optional `starts_at` and `ends_at`, with end after start.
- Timestamps server-maintained.
- No public view, public grant, anonymous policy or public route. Admin “delete” should become archive in the redesigned app.

### 4.6 `store_settings` — operator-private in v1

- `setting_key` text primary key; `setting_value` jsonb; timestamps.
- No anon or authenticated Data API grant in v1.
- Add narrowly scoped admin-editable settings only after an explicit key allowlist and validation contract exists.

### 4.7 Images and Supabase Storage

The first clean schema should use nullable HTTPS image URL fields and should not create Storage buckets or policies. This is intentional: the current admin app has no upload flow, and public/private object access needs its own testable design.

A later image phase can introduce asset metadata, a public-only bucket for approved published assets, and a separate private bucket for drafts/private material. Do not place private and public objects in one public bucket: public buckets allow unauthenticated object reads. Storage policies must be designed and tested before enabling uploads.

## 5. Constraints, indexes and data integrity

- Enforce the singleton row with a primary key/check constraint, not a UI check.
- Unique constraints: `store_uid`, `category_uid`, `listing_uid`, `promotion_uid`; category and listing slugs unique within their table.
- Use foreign keys for listing-to-category relationships; restrict category deletion while referenced.
- Use CHECK constraints for status values, kind, non-negative price, text lengths, JSON object shape, URL scheme and date ordering where practical.
- Add indexes to support common reads: category status/order; listing status/order; listing category/status; membership status (operator queries).
- Keep IDs and timestamps out of ordinary admin update grants.
- Avoid `ON DELETE CASCADE` for catalogue records. Archive instead; operator-only permanent deletion requires a separate retention policy.
- Use a single timestamp trigger function with a fixed empty search path and fully qualified built-ins. Revoke direct execution from client roles.

## 6. API surface and grants

### 6.1 Public storefront views

Create these views in `public`, all with `security_invoker = true` and explicit selected columns:
- `storefront_profile`
- `storefront_categories`
- `storefront_listings`

The views return only:
- Published profile fields explicitly approved as public.
- Published categories, only while the store profile is published.
- Published listings, only while the store profile is published and, where category is required, the category is published.

Never include admin email, Auth IDs, membership data, private settings, internal notes, audit fields or promotions. Do not use `SELECT *`.

### 6.2 Admin API views

Create `admin_api.store_profile`, `admin_api.categories`, `admin_api.listings` and `admin_api.promotions` as simple, explicitly-columned, `security_invoker = true` views.

Grant authenticated users only the operations/columns required by the admin UI. The views are not sufficient authorization by themselves: underlying table RLS and column-level grants remain mandatory. Do not create an admin membership view.

### 6.3 Grant principles

- Revoke broad/default privileges from `PUBLIC`, `anon` and `authenticated` on all base tables.
- Grant `anon` SELECT only on required public views and the minimal underlying columns needed by security-invoker views.
- Grant `authenticated` access only to the approved admin views and required underlying columns.
- Do not grant client roles INSERT/UPDATE/DELETE on `store_admins` or `store_settings`.
- No client role gets TRUNCATE, REFERENCES, TRIGGER, schema CREATE, or table ownership.
- Never expose service-role/secret keys in browser code, GitHub files or customer handovers.
- Confirm schema exposure and grants separately: grants do not automatically mean a schema is exposed through PostgREST, and RLS does not replace grants.

## 7. RLS policy design

Use a dedicated, no-argument helper function `app_private.is_active_store_admin()` for admin checks. Recommended properties:
- Returns only a boolean; accepts no user ID argument and cannot be used to probe another account.
- Reads `auth.uid()` internally and checks for a row in `store_admins` with status active.
- Uses `SECURITY DEFINER` only because the membership table is deliberately not granted to browser roles; set `search_path = ''` and fully qualify every object.
- Revoke EXECUTE from `PUBLIC` and `anon`; grant EXECUTE only to `authenticated`.
- Keep the function in the unexposed `app_private` schema. Do not create a general-purpose membership lookup function.
- Review the function owner, grants and body during security review; do not add dynamic SQL.

The helper is a narrowly scoped security boundary. It must be tested against active, pending, revoked and unrelated users before use.

### RLS matrix

| Table | anon | authenticated non-member | active store admin | operator |
|---|---|---|---|---|
| store_profile | SELECT published allowlist only | no access | SELECT; UPDATE approved business fields | full maintenance |
| store_admins | no access | no access | no direct access or membership writes | provision/activate/revoke |
| categories | SELECT published while store published | no access | SELECT / INSERT / UPDATE; archive via status | full maintenance |
| listings | SELECT published while store published and parent rules pass | no access | SELECT / INSERT / UPDATE; archive via status | full maintenance |
| promotions | no access | no access | SELECT / INSERT / UPDATE; archive via status | full maintenance |
| store_settings | no access | no access | no access in v1 | full maintenance |

RLS rules should be separated by operation:
- Public SELECT policies only on profile/categories/listings and only for published state.
- Authenticated SELECT policies on content tables require `is_active_store_admin()`.
- INSERT policies on categories/listings/promotions require `WITH CHECK (is_active_store_admin())`.
- UPDATE policies require both `USING (is_active_store_admin())` and `WITH CHECK (is_active_store_admin())`.
- No client DELETE policies in v1; archive through UPDATE.
- No INSERT/DELETE policy for the singleton store profile; operator provisions it.
- No authenticated policy or client grant for membership/settings.

Do not rely on `TO authenticated` alone. Authentication is not store authorization. Do not use editable `user_metadata` as an authorization claim.

## 8. Administrator provisioning and revocation

### Invite and activate

1. Operator confirms the business owner's authorisation and intended admin email.
2. Operator sends an invitation from Supabase Dashboard (or a trusted server-side Auth Admin API in a later operator tool). The secret key never enters the browser.
3. Operator records the invited Auth user UUID in `store_admins` with status `invited`.
4. The invited user completes the Supabase invitation and signs in.
5. Operator verifies the invitation was accepted, then changes membership status to `active`.
6. The admin app can read/write only after the database membership check succeeds.

Repeat the process for every additional administrator. There is no self-registration, public signup, client-side invite, role selection or membership editing in v1.

### Revoke

1. Operator changes the membership status to `revoked` and records `revoked_at`.
2. The RLS helper checks current database state on each request; subsequent admin data requests must be denied even if the user's existing JWT has not expired.
3. The user may still possess a valid Auth session until token expiry, but the session no longer authorises access to this store's data.
4. If full account removal is separately required, use the trusted Auth admin process after considering Storage ownership and other project dependencies. Do not treat JWT expiry or deleting a row in the app as a substitute for database membership revocation.

The implementation must prove revocation with a previously authenticated session, not just a fresh login attempt.

## 9. Migration sequence for implementation phase

No migration files are created in this design phase. When implementation is approved, create migration files through the Supabase CLI's migration creation command; do not invent timestamp filenames.

Proposed clean baseline sequence:
1. **Foundation:** create `app_private`, revoke unsafe defaults, create timestamp helper, base tables, constraints and indexes.
2. **Membership boundary:** create `store_admins`, the restricted membership-check function and its execute/schema grants.
3. **RLS and base grants:** enable RLS on every base table; add per-operation policies; revoke broad defaults; grant least-privilege column access.
4. **API views:** create security-invoker public/admin views with explicit column lists and grant only intended view access.
5. **Seed/provisioning:** operator-only creation of singleton profile and initial admin membership; never seed customer-specific data in the generic migration.
6. **Storage (later phase):** separate reviewed migration only after public/private asset lifecycle and bucket policies are approved.

Test the entire sequence on a clean disposable project. Do not apply it to the existing prototype project.

## 10. Implementation gates

Before any hosted schema change:
- Confirm a clean disposable Supabase project is available and cost/plan is acceptable.
- Verify current Supabase CLI version and command syntax; the November 2026 CLI v3 change makes local-by-default behaviour and hosted confirmation important.
- Verify current Supabase documentation and changelog for any relevant breaking changes.
- Review the generated migration SQL before execution.
- Run RLS/grant/view tests and Supabase advisors.
- Preserve the existing development project untouched.

No database schema, Auth settings, storage bucket, migration history or customer record has been changed by this design.
