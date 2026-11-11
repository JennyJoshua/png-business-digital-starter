# Phase 2B — Security Verification and Readiness

**Environment:** `PNG Business Digital Starter Dev`  
**Project ref:** `rwcwvqlgyckfdrglsbfg`  
**Region:** `ap-southeast-2` (Sydney)  
**Review date:** 11 November 2026  
**Owner-admin branch:** `phase-2b/owner-admin-v1-review`  
**Security-remediation branch:** `phase-2b/security-remediation`

## Current decision and rollout status

- Business owners may edit their business profile and prepare category/product/service drafts.
- **Only platform administrators may publish a business, category, product or service listing.** This is the user's explicit Option B decision, confirmed 11 November 2026.
- Owners may archive their own categories/listings through membership-checked RPCs; they cannot publish or unarchive records.
- PR #8 contains the owner-admin foundation and publication-control migration.
- PR #9 contains one-active-owner enforcement and public-view privilege hardening; it is stacked on PR #8.
- Both PRs remain draft/unmerged. The new migrations in PR #8 and PR #9 have **not** been applied to the hosted Supabase project.
- No owner account has been invited, no real business data has been created, and no production deployment has occurred.

## Hosted Supabase state — previously applied migrations

The following four migrations are present in the hosted development project's migration history:

1. `20261109000651_phase_2b_owner_admin_core`
2. `20261109000726_phase_2b_public_read_and_fk_indexes`
3. `20261109001259_phase_2b_admin_api_views`
4. `20261109002919_phase_2b_public_storefront_read_grants`

The core schema has seven application tables in `app_private`, RLS enabled on all seven, membership-based owner policies, three public storefront views, and seven authenticated `admin_api` views. Admin/public views use `security_invoker = true`.

## Live configuration evidence

### Data API exposure and anonymous REST

The earlier live audit confirmed:
- Exposed schemas: `public`, `graphql_public`, and `admin_api`.
- `app_private` is not exposed.
- Anonymous access to `admin_api` is denied.
- Anonymous GET requests to the three public storefront views returned HTTP 200 with empty result sets in the then-empty development project.

**Additional test finding:** a seeded PostgreSQL 17 integration test exposed a missing internal column privilege needed by the category/listing RLS parent-business check. The pending PR #8 migration grants `anon` SELECT on `app_private.businesses.id` solely for that policy predicate. The schema remains unexposed, and the public storefront views do not select or return this UUID. This fix must be applied before anonymous catalogue reads are considered ready.

### Auth settings

A fresh public Auth settings check previously confirmed:
- `disable_signup=true` — public self-registration disabled.
- Email provider enabled.
- Anonymous Auth sign-ins disabled.
- Email auto-confirm disabled; email confirmation required.

On 11 November 2026, the user personally checked Supabase Authentication → URL Configuration and confirmed:

| Setting | User-confirmed value | Evidence status |
|---|---|---|
| Site URL | `https://jennyjoshua.github.io/png-business-digital-starter/` | User-confirmed in dashboard; not independently re-read by the verification connection |
| Redirect URL allow-list | `https://jennyjoshua.github.io/png-business-digital-starter/admin/` | User-confirmed in dashboard; not independently re-read by the verification connection |

No invitation or password-recovery email has been sent. Email delivery to an external owner address and end-to-end PKCE callbacks remain untested.

## Owner-admin application security review

- Browser code contains only the Supabase publishable key; no secret/service-role key is shipped to the browser.
- No public owner registration or `signUp()` call exists.
- The app queries active owner memberships and filters to role `owner`.
- Business/category/listing/promotions queries are tenant-scoped.
- The business selector is disabled while tenant data loads; the admin panel is made inert during the switch.
- Password recovery uses a stable callback URL based on the admin page's origin and pathname.
- Unexpected promise/network failures now produce user-facing feedback.
- Promotions remain private to the owner-admin area and are not included in the public storefront.
- Owners can create and edit drafts, but cannot set publication status. Publication status is enforced by database column grants, not merely by hiding UI controls.
- Privileged archive implementations are SECURITY DEFINER functions in unexposed `app_private`; exposed `admin_api` RPCs are SECURITY INVOKER wrappers. Both private functions independently require `auth.uid()` and an active owner membership for the target record.
- The public storefront is still a static build. Owner edits do not yet synchronize to public pages.

## PostgreSQL 17 integration tests

CI now starts a disposable PostgreSQL 17 service and runs real SQL integration tests. No live Supabase data is used.

The publication-control test covers:
- Owner can read their own business but not another tenant's business.
- Owner can create and edit category/listing drafts.
- New categories/listings default to `draft`.
- Owner cannot insert/update `publication_status` for businesses, categories or listings.
- Owner can archive own categories/listings through the RPC wrappers.
- Owner cannot archive another tenant's records.
- The privileged implementation is in unexposed `app_private`; exposed wrappers are invoker-rights.
- Platform-admin publication causes only approved published records to appear in anonymous storefront views.

The security-remediation test covers:
- Duplicate active owner membership is rejected.
- Public storefront views grant SELECT only to `anon` and `authenticated`.
- Future tables created by both `postgres` and `supabase_admin` do not inherit broad public API privileges.

CI is the source of truth for each commit. Do not treat an earlier green run as covering a later commit.

## Pending security migrations

### PR #8 — platform publication controls

The migration:
- Removes owner publication-status insert/update privileges.
- Narrows `admin_api` view grants to editable content columns.
- Adds private membership-checked archive implementations and invoker RPC wrappers.
- Adds the internal `businesses.id` read privilege required for public child-row RLS checks while keeping `app_private` unexposed.

### PR #9 — membership and public API hardening

The migration:
- Stops if duplicate active owners exist; it never edits membership rows.
- Adds a partial unique index enforcing one active owner per business.
- Revokes all DML on the three public storefront views and grants SELECT only.
- Revokes broad per-schema default table privileges for `postgres` and `supabase_admin`.

Neither migration has been applied to the hosted project.

## Remaining go-live blockers

1. Complete CI on the latest heads of PR #8 and PR #9, including both PostgreSQL 17 integration suites.
2. Complete a final human review of both migrations and the stacked PR dependency.
3. Explicit owner approval is required before merging either PR or applying any hosted migration.
4. After approved merge/deployment, verify the live `/admin/` route and test invitation/password-recovery PKCE callbacks in a real browser.
5. Verify invitation email delivery to a non-organization address before inviting an owner. Do not configure paid SMTP without separate approval.
6. Run browser tests using a real invited test owner: sign-in, draft CRUD, archive, cross-tenant denial, and direct API attempts to publish.
7. Build the platform-admin review/publish workflow; publication remains a controlled platform-admin operation outside the owner UI until that exists.
8. Add Storage bucket/object policies before enabling image uploads.
9. Implement storefront synchronization, an append-only audit trail, backup/recovery and a separately approved production hosting plan.
10. Confirm server-side password policy settings; the admin UI's client-side password-length check alone is not a security boundary.

**Conclusion:** The Phase 2B owner-admin code and database controls are still under review. The automated PostgreSQL tests are a meaningful improvement, but no production readiness, live owner onboarding, hosted migration or deployment is authorized by this review.
