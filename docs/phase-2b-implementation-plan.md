# Phase 2B — Owner Admin Implementation Plan

**Working branch:** `phase-2b/owner-admin-v1-review`  
**Baseline:** latest merged `main`  
**Status:** multi-tenant database schema, RLS foundation, public storefront views, authenticated admin API views and initial private owner-admin app implemented on the approved development branch. Dashboard Auth/Data API configuration and real owner provisioning remain outstanding.

## Product outcome

Deliver a private, mobile-first owner-admin experience alongside the public storefront. Both surfaces use the same canonical business and catalogue data. Public visitors browse without accounts and never see private owner data or Promotions.

## Approved architecture decisions

- **Backend:** Supabase.
- **Tenant topology:** one shared multi-tenant Supabase project for Digital Starter businesses; not one project per customer.
- **Project:** `PNG Business Digital Starter Dev`, reference `rwcwvqlgyckfdrglsbfg`, Sydney region (`ap-southeast-2`), Free development project.
- **Isolation:** separate from the PNG Materials Marketplace and PNG Alert projects.
- **Onboarding:** invitation-only owner provisioning for the pilot; no self-service business-owner registration.
- **Initial role:** owner only in v1; membership authorization comes from protected database rows.
- **Production:** this Free project is for development/testing only. No production deployment or live customer data until a separately approved production plan exists.

## Work sequence and status

### 2B.1 — Architecture decisions
<badge>Complete</badge>
Provider, tenant model, project, owner onboarding direction and initial role are recorded.

### 2B.2 — Data contract
<badge>Complete — v1 core</badge>
- Seven canonical tables: businesses, memberships, categories, listings, private settings, Promotions and asset metadata.
- Internal UUID keys plus stable external business/category/listing identifiers.
- Explicit publication states and public-field allowlists.
- Three public storefront views and seven authenticated `admin_api` views.
- Promotions and owner-only records are excluded from public views.

### 2B.3 — Database security
<badge>Core verified</badge>
- RLS enabled on all seven application tables in `app_private`.
- 22 policies; ownership is checked through protected membership records.
- No client write privileges on membership records; stable external identifiers are not updateable through normal owner grants.
- UPDATE policies use both `USING` and `WITH CHECK`.
- Anonymous and two-tenant/two-owner checks passed using temporary transaction-scoped fixtures; all fixtures were rolled back.
- Added the minimum `anon SELECT` grants required by the `security_invoker` public views; existing RLS policies keep the grant limited to published business/catalogue rows.
- Admin API view isolation and anonymous denial checks passed.
- Supabase Security Advisor returned no findings.
- See [Phase 2B security verification](phase-2b-security-verification.md).

### 2B.4 — Owner authentication and initial admin app
<badge>Code foundation complete; dashboard gates remain</badge>
- Sign-in, sign-out, password recovery and invitation password setup are implemented in `admin/`.
- Tenant membership lookup uses the protected `admin_api` schema.
- Profile and brand-colour editing, category/listing create/archive, and private Promotions create/delete are implemented.
- Session restoration after page reload and a business selector for users with multiple authorized businesses are included in the review branch.
- Listing price display uses each listing's stored currency code.
- User confirmed the Data API schema allowlist was saved with `public` and `admin_api` exposed and `app_private` unexposed; verify through real REST requests.
- Configure and verify Auth settings using [Owner Auth setup](phase-2b-owner-auth-setup.md).
- Test email invitation delivery before inviting a real owner; no owner account has been provisioned.
- Never expose a secret/service-role key in browser code.
- CI passed admin JavaScript syntax validation, automated tests, starter-data validation and demonstration builds; end-to-end Auth/Data API testing remains blocked on dashboard configuration.

### 2B.5 — Complete private admin interface
**Partially implemented**
- Mobile-first dashboard and navigation; business profile and brand-colour editing.
- Category/listing creation and archive; private Promotions create/delete.
- Still to implement: logo/image upload, contact/social editing refinements, data export, and further QA.
- The current public static storefront is still the fallback; owner edits do not yet synchronize to public pages.

### 2B.6 — Public storefront integration
- Read only published, allowlisted fields through the public views.
- No Promotions page, navigation, banner or public placement.
- Preserve the current static storefront as a fallback until integration tests pass.

### 2B.7 — Review and handover
- Automated tests, RLS regression tests, accessibility checks and mobile browser QA.
- Migration notes and owner handover.
- Open a review PR; do not merge to `main` or deploy production without owner approval.

## Admin interface navigation target

1. Dashboard
2. Business profile
3. Branding and logo
4. Catalogue
5. Categories
6. Promotions (private)
7. Contact and social links
8. Data export
9. Account and sign out

## Security acceptance matrix

| Scenario | Expected result |
|---|---|
| Visitor without a session opens admin | Sign-in screen only; no private data returned |
| Owner A requests Business B | Denied / zero rows |
| Owner A inserts or updates a record under Business B | Denied |
| Owner changes own membership role | Denied |
| Public visitor queries draft listing | No row returned |
| Public visitor queries Promotions | No access |
| Public visitor queries published business/listing | Only allowlisted fields returned |
| Owner session expires | Protected actions stop; user is asked to sign in again |

## Remaining implementation gates

1. Verify the Data API exposed-schema list through actual REST requests (`public` and `admin_api` exposed; `app_private` unexposed).
2. Add a database constraint for exactly one active owner per business; the current unique (`business_id`, `user_id`) constraint permits multiple owners.
3. Revoke inherited DML privileges from the three public storefront views and retain SELECT only.
4. Configure and verify Auth invitation-only settings and email delivery; no owner account has been provisioned.
5. Run browser integration tests through the actual Data API after dashboard configuration.
6. Set up Storage bucket and object policies before enabling logo/listing image upload.
7. Implement the public data adapter; the current static storefront is not yet synchronised with owner edits.
8. Add an append-only audit trail and complete owner invitation/provisioning workflow.

The current database foundation is development-only. No production deployment, live customer onboarding, or merge to `main` is authorized by this phase.
