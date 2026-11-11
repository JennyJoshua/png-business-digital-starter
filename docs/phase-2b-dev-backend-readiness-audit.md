# Phase 2B Development Backend — Live Readiness Audit

**Audit date:** 11 November 2026  
**Project inspected:** PNG Business Digital Starter Dev  
**Project reference:** `rwcwvqlgyckfdrglsbfg`  
**Region:** `ap-southeast-2`  
**Project status at inspection:** `ACTIVE_HEALTHY`  
**Audit type:** Read-only database metadata, grants, RLS policy, Storage and function inventory

## 1. Executive summary

A dedicated **PNG Business Digital Starter Dev** Supabase project already exists in the user's Supabase organization. It is separate from the two projects named for PNG Materials Marketplace. **Do not create another Starter development project.** Use the existing Dev project as the development environment, subject to the remediation and source-control work below.

The project is not an empty shell. It already has four recorded Phase 2B migrations, seven tenant data tables in a non-public `app_private` schema, admin API views, public storefront views, RLS policies and a clean Supabase security-advisor result.

However, this is not yet a complete or end-to-end verified owner-admin backend. The audit found:
- the database does not enforce exactly one active owner membership per business;
- public storefront views have unnecessary DML privileges inherited from broad `public` schema default privileges; they should be read-only;
- there is no Storage bucket or Storage object policy;
- there are no Edge Functions for trusted operator onboarding/invitation;
- there is no audit-events table;
- the four migration files and implementation are on an unmerged feature branch, not yet on `main`;
- actual browser REST/Auth flows have not been independently verified in this audit; the feature branch's security report documents transaction-scoped SQL role-simulation tests.

**Recommendation:** preserve the existing project and schema. Do not create a second project or apply another migration until the remote schema has been reconciled into source control and the grant/ownership gaps have been reviewed.

## 2. Project inventory

The connected Supabase organization contains:
- `png-materials-marketplace`
- `PNG Materials Marketplace - Testing`
- `PNG Business Digital Starter Dev`
- `PNG Alert`

The Starter Dev project is a distinct project and is currently `ACTIVE_HEALTHY`. The Marketplace projects are separate. No project was created, paused, restored, renamed or modified during this audit.

## 3. Recorded migration history

The Starter Dev project reports these applied migrations:

| Version | Name |
|---|---|
| `20261109000651` | `phase_2b_owner_admin_core` |
| `20261109000726` | `phase_2b_public_read_and_fk_indexes` |
| `20261109001259` | `phase_2b_admin_api_views` |
| `20261109002919` | `phase_2b_public_storefront_read_grants` |

The GitHub `main` tree currently has no `supabase/` directory. All four matching SQL migration files and the initial owner-admin implementation were found on the older unmerged branch `phase-2b/owner-admin-interface-foundation`. They have now been ported to a clean review branch based on current `main`: `phase-2b/owner-admin-v1-review`, preserving the merged fictional demo pilot. The migration source is recoverable and version-controlled on the review branch, but is not yet part of `main`. Treat the remote schema as existing state, not as a disposable environment. Review the branch and reconcile its exact migration history before any new migration is authored or applied.

## 4. Existing schema

Seven application tables exist in `app_private`:

- `businesses`
- `business_memberships`
- `business_private_settings`
- `categories`
- `listings`
- `promotions`
- `asset_metadata`

The schema already includes useful design elements:
- UUID internal primary keys and stable external business/category/listing identifiers;
- tenant-scoped foreign keys and unique keys;
- explicit product/service listing kind;
- numeric price plus currency code and price unit;
- publication status;
- business-specific categories;
- private Promotions records;
- asset metadata with private/public visibility;
- membership role constrained to `owner`.

The listing currency defaults to `PGK`, and the business country code defaults to `PG`. These are useful PNG-first defaults but should remain explicit and overridable where the business's actual currency differs.

### Owner-count constraint gap

`business_memberships` currently has a unique constraint on `(business_id, user_id)`, but no unique constraint on `business_id` alone. Its role check restricts rows to `owner`, but multiple different owner users can still be linked to one business.

This does not meet the newly approved initial rule of exactly one owner per business. Add an appropriate database-level uniqueness rule only after checking for existing duplicate rows and preparing a reviewed migration. No rows were changed during this audit.

### Listing category cardinality

The existing v1 schema supports one category per listing through `listings.category_id` and a composite foreign key that ensures the category belongs to the same business. Keep this single-category model for the current implementation; do not add a join table unless multi-category listings become an explicitly approved product requirement.

## 5. RLS and policy inventory

RLS is enabled on all seven `app_private` application tables. The tables are not marked FORCE ROW LEVEL SECURITY.

Observed policy pattern:
- owner reads/writes are generally scoped through `business_memberships`, matching `auth.uid()`, active status and owner role;
- public anonymous SELECT policies exist for published businesses, categories and listings;
- category/listing public policies also require the parent business to be published;
- Promotions has authenticated owner policies and no anonymous policy;
- memberships have a self-read policy limited to active memberships;
- no client policy allows an owner to create or modify membership/role records.

This is a promising base. However, policy metadata inspection is not a substitute for runtime tests with separate JWTs for owner A, owner B and anonymous clients. No such runtime test suite was verified in this audit.

The Supabase security advisor returned **zero security lints**. That is useful evidence but does not prove the application authorization model is complete or that all view grants are least-privilege.

## 6. View and privilege findings

Two API-oriented schemas exist:
- `admin_api` — seven views over private application tables, all configured with `security_invoker=true`;
- `public` — three `storefront_*` views for public business, category and listing data, all configured with `security_invoker=true`.

The public views use explicit public field selections and filter for published businesses/listings. This is aligned with the approved public data boundary.

### Finding A — admin view/base-table grants are aligned at column level

The first table-level privilege query did not show the column-level grants. A follow-up inspection of `information_schema.column_privileges` confirmed that the intended authenticated INSERT/UPDATE columns are granted on the underlying `app_private` tables, and the `admin_api` views use `security_invoker=true`.

**Correction:** no admin view/base-table grant mismatch is established by this audit. The remaining limitation is that browser CRUD through the actual Data API has not been independently verified in this audit. The earlier branch security-verification document reports SQL role-simulation tests passed; actual browser REST requests remain an outstanding gate.

Do not switch views to security-definer or expose a service-role key to the browser.

### Finding B — public storefront views inherit excessive DML grants

The `public.storefront_businesses`, `public.storefront_categories` and `public.storefront_listings` views currently have broad ACLs, including INSERT, UPDATE, DELETE, TRIGGER and TRUNCATE, for `anon` and `authenticated`.

The migration source explicitly grants SELECT, but the live database's `pg_default_acl` for the `public` schema grants broad relation privileges to `anon` and `authenticated` by default. The views use `security_invoker=true`, and the relevant base tables grant only SELECT to anonymous users, so the view ACLs alone do not establish that an anonymous write can succeed. Nevertheless, public storefront views must be read-only.

**Remediation direction:** revoke all existing DML privileges from the three public storefront views, then grant only SELECT to the intended public roles. Review and tighten the default privileges for future public-schema relations so new views/tables do not silently inherit broad client DML.

### Finding C — API schema exposure needs dashboard verification

The database contains `app_private`, `admin_api` and `public` schemas. SQL metadata confirms schema usage privileges, but the effective PostgREST exposed-schema configuration was not available from the inspected SQL setting. Verify the Data API exposed-schema configuration in the Supabase dashboard before relying on either custom API schema. Do not expose `app_private` merely to make the admin views work.

## 7. Owner-admin application branch review

The older source branch `phase-2b/owner-admin-interface-foundation` contained a mobile-first `admin/` interface, four SQL migration files, implementation notes, owner-auth setup guidance, security verification notes and expanded tests. That work was ported to `phase-2b/owner-admin-v1-review`, based on current `main`.

The clean review branch now addresses three static-review issues:
1. **Session restoration:** it calls `getSession()` on load so an existing session can be restored after page refresh.
2. **Multiple business memberships:** it adds a business selector instead of silently choosing the first business returned.
3. **Currency display:** listing display now uses the currency stored on each listing.

Remaining unverified or incomplete behaviours:
1. **Invitation/recovery flow:** the code handles invitation/recovery markers and password setup, but real Auth email-link callbacks have not been verified. Test invite setup and password recovery on the actual admin URL.
2. **Error and loading states:** network exceptions and some async event-handler failures are not consistently caught and surfaced as safe user messages.
3. **Incomplete features:** logo/image upload, contact/social editing refinements and data export are not implemented; Storage is not configured.
4. **Public data sync:** owner changes do not yet update the public static storefront. Keep the current static fallback until a controlled, tested published-data adapter is ready.

The UI uses a Supabase publishable key in browser code, not a service-role key. That key is intended for public client use; authorization still depends on RLS and grants. The UI escapes dynamic text inserted into HTML templates and marks the admin page noindex, but these observations do not replace runtime testing.

## 8. Missing capabilities

| Capability | Observed state | Consequence |
|---|---|---|
| Storage buckets | None | Logo/listing uploads are not configured |
| Storage object policies | None found | No tenant-safe upload/download boundary yet |
| Edge Functions | None deployed | No trusted server-side owner invitation/provisioning flow |
| Audit events table | None among application tables | Sensitive owner/operator actions lack an application audit trail |
| Owner invitation acceptance | Not implemented/verified | Membership status lifecycle needs a trusted process |
| Real JWT RLS tests | Not verified | Cross-tenant isolation remains unproven |
| Versioned migration source in GitHub | No `supabase/` directory on `main` | Remote schema is not reproducible from the repo |

## 9. Security and operational assessment

**Positive evidence**
- Dedicated Starter Dev project exists and is separate from Marketplace.
- Core tenant tables and four migration records exist.
- RLS is enabled across the application tables.
- RLS predicates use `auth.uid()` and database membership rows rather than user-editable profile metadata.
- Public storefront views are explicit projections and security-invoker views.
- Promotions are absent from the anonymous public read policy set.
- Security advisor returned no lints.

**Outstanding before owner-admin pilot**
1. Review and reconcile the four existing migration files on `phase-2b/owner-admin-interface-foundation` against the four applied remote migration records. Do not recreate or blindly reapply them.
2. Enforce the one-owner-per-business invariant after checking existing rows.
3. Revoke DML from the three public storefront views and retain SELECT only; tighten default privileges for future public-schema objects.
4. Verify API exposed schemas and ensure `app_private` is not exposed.
5. Complete and test the invitation/session lifecycle without browser secrets.
6. Add Storage buckets and tenant-specific Storage policies only after upload requirements are finalized.
7. Add an append-only audit trail for sensitive events.
8. Verify session restoration, business switching and stored-currency display through browser tests; implement safe error/loading handling.
9. Run real browser JWT tests for at least two tenants and anonymous access; re-run Supabase security advisors after remediation.

## 10. Recommended next work order

| Priority | Work | Environment |
|---|---|---|
| 1 | Review the four migration files on the existing feature branch against the four applied remote migration records | Repository and read-only database inspection |
| 2 | Produce a remediation migration proposal for owner uniqueness and grants | Feature branch only |
| 3 | Add a real JWT tenant-isolation test plan/harness | Development project only after test accounts are approved |
| 4 | Implement and verify the trusted invitation process | Development project after review |
| 5 | Add Storage and audit events | Development project after requirements and migration review |
| 6 | Build the owner-admin interface against the verified API | Feature branch; no production deployment |

## 11. Scope and non-actions

This audit was read-only. It did not:
- insert, update or delete business/user rows;
- create, alter or drop tables, policies, grants, functions or views;
- apply or roll back migrations;
- create Storage buckets or policies;
- create or invite Auth users;
- deploy Edge Functions;
- read or expose user email addresses, credentials, tokens, business content or file contents;
- change the Materials Marketplace projects;
- deploy or publish the Starter storefront.

## 12. Conclusion

The existing Starter Dev project is the correct environment to continue investigating; a duplicate project is unnecessary. The current schema is a useful Phase 2B foundation, but it is not yet proven ready for owner-admin use. The next work should reconcile source control and correct the specific privilege and one-owner constraints before building the UI or onboarding a real business.
