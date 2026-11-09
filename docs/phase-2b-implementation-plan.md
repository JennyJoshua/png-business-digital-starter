# Phase 2B — Owner Admin Implementation Plan

**Working branch:** `phase-2b/owner-admin-interface-foundation`  
**Baseline:** latest merged `main`  
**Status:** multi-tenant database schema, RLS foundation, public storefront views and authenticated admin API views implemented on the approved development project. Auth configuration and UI remain outstanding.

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
- Admin API view isolation and anonymous denial checks passed.
- Supabase Security Advisor returned no findings.
- See [Phase 2B security verification](phase-2b-security-verification.md).

### 2B.4 — Owner authentication
**Next**
- Verify the project's Data API schema allowlist; expose `admin_api` only when ready for the admin client and keep `app_private` unexposed.
- Configure and verify invitation-only owner access.
- Implement sign-in, sign-out, session expiry and password recovery.
- Provision the first owner only after an actual business and owner email are approved.
- Never expose a secret/service-role key in browser code.

### 2B.5 — Private admin interface
- Mobile-first dashboard and navigation.
- Business profile and branding/logo management.
- Categories and product/service listing management.
- Private Promotions management.
- Contact/social details and owner data export.
- Loading, empty, validation and error states.

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

1. Verify exposed Data API schemas; `admin_api` has been created but is not yet exposed.
2. Configure and verify Auth invitation-only settings; no owner account has been provisioned.
3. Implement and test the admin application and public data adapter.
4. Set up Storage bucket and object policies only when logo/listing image upload is implemented.

The current database foundation is development-only. No production deployment, live customer onboarding, or merge to `main` is authorized by this phase.
