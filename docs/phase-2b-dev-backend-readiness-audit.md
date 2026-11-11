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

However, this is not yet a complete or verified owner-admin backend. The audit found:
- the database does not enforce exactly one owner membership per business;
- admin API view write grants do not line up with underlying table grants, so intended owner writes are not currently supported by the inspected privileges;
- public storefront views have unnecessary write privileges granted to `anon` and `authenticated` (the underlying base-table grants appear to block those writes, but the view grants should still be read-only);
- there is no Storage bucket or Storage object policy;
- there are no Edge Functions for trusted operator onboarding/invitation;
- there is no audit-events table;
- the remote migrations are not represented by a `supabase/` directory in the current GitHub `main` tree;
- runtime RLS tests with real user JWTs have not been demonstrated.

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

The GitHub `main` tree currently has no `supabase/` directory and no checked-in SQL migration files. This means the repository cannot currently reproduce or independently review the applied database history from its own contents. Treat the remote schema as existing state, not as a disposable environment.

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

### Finding A — admin view writes lack matching base-table privileges

The `admin_api` views grant authenticated users INSERT/UPDATE/DELETE for selected admin resources. But the underlying `app_private` table grants observed for `authenticated` are largely SELECT-only:
- businesses: SELECT only;
- categories: SELECT only;
- listings: SELECT only;
- business private settings: SELECT only;
- promotions: SELECT and DELETE only;
- asset metadata: SELECT and DELETE only.

Because the admin views use `security_invoker=true`, the caller's underlying table privileges and RLS policies still apply. The view grants alone do not provide the missing base-table privileges. Consequently, the intended owner-admin write operations are not yet demonstrated and are expected to fail where the underlying table privilege is missing.

**Remediation direction:** align view and base-table grants with the exact RLS-protected owner operations. Do not solve this by switching views to security-definer or by exposing a service-role key to the browser.

### Finding B — public storefront views have excessive DML grants

The `public.storefront_businesses`, `public.storefront_categories` and `public.storefront_listings` views have broad privileges, including INSERT, UPDATE, DELETE, TRIGGER and TRUNCATE, granted to `anon` and `authenticated`.

The underlying `app_private` base tables appear to grant those roles SELECT only for the relevant public-read tables, and the views use `security_invoker=true`; therefore the observed view grants alone do not establish that an anonymous write can succeed. Nevertheless, public storefront views should be explicitly read-only. Revoke unnecessary DML privileges and retain only SELECT for the intended public roles.

### Finding C — API schema exposure needs dashboard verification

The database contains `app_private`, `admin_api` and `public` schemas. SQL metadata confirms schema usage privileges, but the effective PostgREST exposed-schema configuration was not available from the inspected SQL setting. Verify the Data API exposed-schema configuration in the Supabase dashboard before relying on either custom API schema. Do not expose `app_private` merely to make the admin views work.

## 7. Missing capabilities

| Capability | Observed state | Consequence |
|---|---|---|
| Storage buckets | None | Logo/listing uploads are not configured |
| Storage object policies | None found | No tenant-safe upload/download boundary yet |
| Edge Functions | None deployed | No trusted server-side owner invitation/provisioning flow |
| Audit events table | None among application tables | Sensitive owner/operator actions lack an application audit trail |
| Owner invitation acceptance | Not implemented/verified | Membership status lifecycle needs a trusted process |
| Real JWT RLS tests | Not verified | Cross-tenant isolation remains unproven |
| Versioned migration source in GitHub | No `supabase/` directory on `main` | Remote schema is not reproducible from the repo |

## 8. Security and operational assessment

**Positive evidence**
- Dedicated Starter Dev project exists and is separate from Marketplace.
- Core tenant tables and four migration records exist.
- RLS is enabled across the application tables.
- RLS predicates use `auth.uid()` and database membership rows rather than user-editable profile metadata.
- Public storefront views are explicit projections and security-invoker views.
- Promotions are absent from the anonymous public read policy set.
- Security advisor returned no lints.

**Outstanding before owner-admin pilot**
1. Reconcile all four remote migrations into reviewed, versioned repository files. Do not blindly generate/apply duplicate migrations.
2. Enforce the one-owner-per-business invariant after checking existing rows.
3. Correct the admin view/base-table privilege mismatch using narrowly scoped grants plus RLS.
4. Revoke DML from public storefront views; keep only SELECT.
5. Verify API exposed schemas and ensure `app_private` is not exposed.
6. Implement a trusted operator invitation/provisioning flow without browser secrets.
7. Add Storage buckets and tenant-specific Storage policies only after upload requirements are finalized.
8. Add an append-only audit trail for sensitive events.
9. Run real JWT-based RLS tests for at least two tenants and anonymous access.
10. Re-run Supabase security advisors and inspect all results after remediation.

## 9. Recommended next work order

| Priority | Work | Environment |
|---|---|---|
| 1 | Recover/reconcile migration source into GitHub and review drift | Repository only; read-only database inspection |
| 2 | Produce a remediation migration proposal for owner uniqueness and grants | Feature branch only |
| 3 | Add a real JWT tenant-isolation test plan/harness | Development project only after test accounts are approved |
| 4 | Implement and verify the trusted invitation process | Development project after review |
| 5 | Add Storage and audit events | Development project after requirements and migration review |
| 6 | Build the owner-admin interface against the verified API | Feature branch; no production deployment |

## 10. Scope and non-actions

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

## Conclusion

The existing Starter Dev project is the correct environment to continue investigating; a duplicate project is unnecessary. The current schema is a useful Phase 2B foundation, but it is not yet proven ready for owner-admin use. The next work should reconcile source control and correct the specific privilege and one-owner constraints before building the UI or onboarding a real business.
