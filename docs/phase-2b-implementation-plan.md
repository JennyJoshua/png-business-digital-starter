# Phase 2B — Owner Admin Implementation Plan

**Working branch:** `phase-2b/owner-admin-v1-review`  
**Stacked security branch:** `phase-2b/security-remediation`  
**Baseline:** current `main`  
**Status:** owner-admin foundation implemented on a draft review branch. Security hardening and PostgreSQL 17 integration tests are in progress. No merge, hosted migration, owner onboarding or deployment has occurred.

## Product outcome

Deliver a private, mobile-first owner-admin experience alongside the public storefront. Both surfaces use the same canonical business and catalogue data. Public visitors browse without accounts and never see private owner data or Promotions.

## Approved architecture and product decisions

- **Backend:** existing Supabase project `PNG Business Digital Starter Dev`, ref `rwcwvqlgyckfdrglsbfg`, Sydney region (`ap-southeast-2`), Free development project.
- **Tenant topology:** one shared multi-tenant backend; separate from PNG Materials Marketplace and PNG Alert.
- **Owner onboarding:** invitation-only; no public owner self-registration.
- **Initial membership:** one active owner per business.
- **Public access:** visitors browse/search/buy without registering.
- **Publication authority:** **platform administrator only**. Owners prepare and edit drafts but cannot publish businesses, categories, products or services. Owners may archive only their own categories/listings.
- **Surface separation:** public storefront and private owner-admin are separate. Promotions are admin-only and never appear on the public storefront.
- **Production:** this Free development project is for development/testing only. No live customer data or production deployment until a separately approved production plan exists.

## Work sequence and status

### 2B.1 — Architecture decisions
<badge color="success">Complete</badge>

Provider, tenant model, project, owner onboarding direction, initial role and platform-only publication authority are recorded.

### 2B.2 — Data contract
<badge color="success">Core complete</badge>

- Seven canonical tables: businesses, memberships, categories, listings, private settings, Promotions and asset metadata.
- Internal UUID keys plus stable external business/category/listing identifiers.
- Explicit publication states and public-field allowlists.
- Three public storefront views and seven authenticated `admin_api` views.
- Promotions and owner-only records are excluded from public views.

### 2B.3 — Database security
<badge color="warning">Core applied; hardening under review</badge>

- RLS enabled on all seven application tables in `app_private`.
- Membership-based owner policies with `USING` and `WITH CHECK`.
- No client membership writes or self-promotion.
- Four foundational migrations are already applied to the development project.
- PR #8 adds platform-only publication grants and tenant-scoped archive RPCs.
- PR #9 adds one-active-owner-per-business enforcement and read-only public-view privileges.
- Disposable PostgreSQL 17 integration tests exercise the real SQL grants, RLS behaviour and cross-tenant boundaries.
- A seeded test exposed a missing internal parent-business UUID privilege needed by public child-row RLS checks; PR #8 now includes the narrow fix while keeping `app_private` unexposed.
- Do not apply either pending migration to hosted Supabase without explicit approval.

See [Phase 2B security verification](phase-2b-security-verification.md).

### 2B.4 — Owner authentication and initial admin app
<badge color="warning">Code foundation complete; end-to-end tests pending</badge>

- Email/password sign-in, sign-out, password recovery and invitation password setup are implemented.
- No public registration form or `signUp()` call.
- Tenant membership lookup filters to active owner memberships.
- Business selector supports multiple authorized businesses and locks the admin panel during a switch.
- Business profile and brand-colour editing, category/listing draft creation and archive, and private Promotions create/delete are implemented.
- Unexpected promise/network failures show user-facing feedback.
- Only a Supabase publishable key is shipped to the browser.
- The user confirmed the Site URL and exact admin Redirect URL in Supabase Authentication → URL Configuration on 11 November 2026. This is user-confirmed, not independently re-read.
- Public signup is disabled; email is enabled; anonymous Auth sign-ins are disabled; email confirmation is required.
- Invitation email delivery and PKCE callbacks still require end-to-end browser tests after the admin route is deployed.

See [Owner Auth setup](phase-2b-owner-auth-setup.md).

### 2B.5 — Complete private admin interface
**Partially implemented**

Implemented:
- Mobile-first dashboard and navigation.
- Business profile and brand-colour editing.
- Category/listing creation and archive.
- Private Promotions create/delete.

Still outstanding:
- Logo/listing image upload and secure Storage policies.
- Contact/social editing refinements and data export.
- Platform-admin publication/review interface.
- Additional accessibility and mobile browser QA.

### 2B.6 — Public storefront integration
**Not yet implemented**

- Read only published, allowlisted fields through the public views.
- Keep Promotions absent from public navigation, pages and output.
- Preserve the current static storefront as fallback until live data integration tests pass.
- Owner edits do not yet synchronize to public pages.

### 2B.7 — Review and handover
**In progress**

- PR #8: owner-admin foundation and platform publication controls.
- PR #9: stacked security remediation.
- Both are draft and unmerged.
- PostgreSQL 17 integration tests are part of GitHub Actions.
- Final review package must document remaining blockers and the approval gates.

## Owner-admin navigation target

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
| Owner tries to publish a business/category/listing | Database privilege denied |
| Owner archives own category/listing | Allowed through membership-checked RPC |
| Owner archives another tenant's record | Denied |
| Public visitor queries draft listing | No row returned |
| Public visitor queries Promotions | No access |
| Public visitor queries published business/listing | Only allowlisted fields returned |
| Owner session expires | Protected actions stop; user is asked to sign in again |

## Remaining approval gates

1. Finish CI for the latest PR #8 and PR #9 heads, including both disposable PostgreSQL 17 integration suites.
2. Complete final SQL review and reconcile PR #9 against the latest PR #8 branch.
3. Obtain explicit approval before merging PR #8 or PR #9.
4. Obtain explicit approval before applying either pending migration to hosted Supabase.
5. After approved deployment, verify the admin route, invite/recovery callbacks and email delivery.
6. Run authenticated browser/API tests for tenant isolation and direct attempts to publish.
7. Implement the platform-admin publication workflow before real business publishing.
8. Add Storage policies, storefront synchronization and an append-only audit trail.
9. Review backups, production hosting and Free-plan suitability separately before live onboarding.

No production deployment, real owner provisioning or hosted migration is authorized by this plan.
