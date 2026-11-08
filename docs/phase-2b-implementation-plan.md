# Phase 2B — Owner Admin Implementation Plan

**Working branch:** `phase-2b/owner-admin-interface-foundation`  
**Baseline:** latest merged `main`  
**Status:** implementation planning and safe groundwork; no backend project or admin UI has been deployed.

## Product outcome

Deliver a private, mobile-first owner-admin experience alongside the existing public storefront. Both surfaces use the same canonical business and catalogue data. The public storefront remains browseable without customer accounts and must never expose private owner data or Promotions.

## Working assumptions

These follow the architecture recommendation already recorded; they remain subject to owner confirmation before hosted setup:

- Supabase is the preferred development backend candidate.
- One shared multi-tenant backend is used for the Digital Starter product, rather than one project per business.
- A separate Digital Starter backend is preferred over reusing the PNG Materials Marketplace database.
- The initial pilot uses invitation-only owner onboarding and one owner role; staff roles can follow later.
- Free Supabase projects are for development/testing only. Production hosting, database capacity, backups and launch readiness are planned separately before public launch.

## Work sequence

### 2B.1 — Lock architecture decisions
- Confirm the backend provider, tenant topology, owner onboarding, initial roles and the specific development project.
- No project creation, pause/resume, credential handling or hosted configuration changes before explicit approval.

### 2B.2 — Build the data contract
- Define canonical business, membership, category, listing, private settings, promotions and asset metadata entities.
- Use internal UUID primary keys plus stable external business/listing identifiers.
- Specify public-field allowlists and publication states.
- Version the schema and marketplace export contract.

### 2B.3 — Implement database security
- Enable RLS on every exposed table.
- Use least-privilege grants and separate SELECT/INSERT/UPDATE/DELETE policies.
- UPDATE policies must include both USING and WITH CHECK.
- Membership checks must use protected database records, not editable user metadata.
- Test two businesses and two owners for cross-tenant read/write isolation, role escalation, guessed IDs, unpublished data and private Promotions.
- Check Supabase Security Advisor after the test schema is deployed to the approved development project.

### 2B.4 — Build owner authentication
- Owner sign-in, sign-out, session expiry and password recovery.
- Invitation-only owner provisioning for the initial pilot.
- No public owner self-registration unless separately approved.
- No privileged secret key in browser code.

### 2B.5 — Build the private admin interface
- Mobile-first dashboard and navigation.
- Business profile and branding/logo management.
- Categories and product/service listing management.
- Private Promotions management.
- Contact/social details and owner data export.
- Clear loading, empty, validation and error states.

### 2B.6 — Connect the public storefront
- Public reads only published allowlisted fields.
- No Promotions page, navigation, banner or public placement.
- Preserve the existing static storefront as a safe fallback until integration tests pass.

### 2B.7 — Verify and prepare review
- Automated tests, RLS tests, accessibility checks and mobile browser QA.
- Documentation, migration notes and owner handover.
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

## Security test matrix

| Scenario | Expected result |
|---|---|
| Visitor without a session opens admin | Sign-in screen only; no private data returned |
| Owner A requests Business B | Denied / zero rows |
| Owner A inserts or updates a record under Business B | Denied |
| Owner changes own membership role | Denied |
| Public visitor queries draft listing | No row returned |
| Public visitor queries Promotions | No access |
| Public visitor queries published business/listing | Only allowlisted public fields returned |
| Owner session expires | Protected actions stop; user is asked to sign in again |

## Current blockers before hosted integration

1. Confirm the exact Supabase development project to use (or explicitly approve creating a separate Digital Starter project).
2. Confirm that the recommended Supabase provider, shared multi-tenant topology, invitation-only onboarding and one-owner v1 are accepted.

Until those are settled, implementation can proceed on version-controlled design, tests and interface work, but no remote database changes or credentials will be used.
