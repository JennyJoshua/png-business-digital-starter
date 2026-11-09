# Phase 2B — Security Verification Record

**Purpose:** Preserve an accurate record of tests run against the earlier shared multi-tenant prototype and distinguish them from tests still required for the approved independent single-store architecture.  
**Revised target:** one app/repository/deployment/Supabase project per store, with one or more administrators of that store.  
**Status:** target architecture is not yet implemented or verified.

## 1. Important scope distinction

The existing tests below were run against the earlier shared multi-tenant schema in the development project `PNG Business Digital Starter Dev` (`rwcwvqlgyckfdrglsbfg`). They are historical evidence for that prototype only.

They do **not** verify the revised target architecture, the clean-project provisioning workflow, multiple administrators of one store, per-instance isolation, operator maintenance, backup/restore, or actual browser REST integration.

The existing development project must not be treated as a customer database. Do not destructively convert or delete it without a separate reviewed and approved transition plan.

## 2. Historical prototype configuration

- Seven application tables under `app_private`; RLS enabled on all seven.
- 22 policies covering anonymous publication reads, active-owner reads/writes and private data.
- Three public security-invoker views: `public.storefront_businesses`, `public.storefront_categories`, `public.storefront_listings`.
- Seven security-invoker views under `admin_api`.
- Anonymous SELECT was granted only on the three public-read base tables; RLS constrained rows to published records belonging to published businesses.
- Membership, private settings, Promotions and asset metadata were excluded from public views.
- The user reported saving the Data API exposed-schema list with `public` and `admin_api`, leaving `app_private` unexposed. Actual REST verification remained outstanding.
- No SECURITY DEFINER function was created.
- No owner account or real business records were provisioned.

## 3. Historical tests on the old prototype

Temporary fixtures represented two Auth users and two business tenants. SQL checks ran in transactions and were rolled back; no test users or business records were retained.

| Historical test | Result on old prototype |
|---|---|
| Anonymous public views return published businesses/listings only | PASS in transaction-scoped SQL fixtures |
| Draft listing omitted from public results | PASS |
| Anonymous role cannot SELECT Promotions or memberships | PASS |
| Anonymous role can query the three public views after grants | PASS — zero rows in the empty project; no permission error |
| Owner A sees own business and catalogue rows | PASS |
| Owner A cannot see tenant B's business/listing | PASS |
| Owner A cross-tenant update affects zero rows | PASS |
| Owner A cross-tenant insert rejected by RLS | PASS |
| Authenticated role cannot update memberships/self-promote | PASS — no UPDATE privilege |
| Owner API views return only the signed-in owner's records | PASS |
| Anonymous role has no usage on `admin_api` | PASS |
| Supabase Security Advisor | No findings at time of historical check |

These results must not be relabelled as verification of the new single-store design.

## 4. Required verification for the revised architecture

Run all tests against a newly provisioned disposable Supabase project created from the new version-controlled baseline migrations.

### Database and authorization
- Verify the one-store invariant is enforced.
- Verify two distinct Auth users can be provisioned as administrators for the same store.
- Verify both active administrators can read and perform permitted content operations.
- Verify a non-member cannot read or mutate admin data.
- Verify administrators cannot create, promote or revoke admin memberships through the browser API.
- Verify membership revocation blocks future access according to the chosen token/session strategy.
- Verify all exposed tables have RLS and least-privilege grants.
- Verify no service-role/secret key appears in browser code, build output or source maps.

### Public REST API
- Published store profile/categories/listings return only allowlisted fields.
- Draft and archived records are not returned.
- Memberships, private settings, asset metadata and Promotions are inaccessible.
- Unexposed schemas remain inaccessible through the Data API.

### Admin REST/browser API
- Unauthenticated requests are denied.
- Authenticated non-member requests are denied.
- Two authorised admins can manage only their store's permitted content.
- Admin membership changes and infrastructure operations are denied to ordinary admins.
- Updates cannot change stable identifiers or move records outside the store.

### Instance isolation and operator operations
- Instance A and instance B use different Supabase project URLs and publishable keys.
- No instance contains another business's data.
- The operator can apply a migration to a clean project and identify the schema version.
- Backup and restore are documented and tested before production use.
- Store admins have no database-owner or Supabase project access.

### Browser and mobile
- Public homepage, search, categories, listing detail and contact links work.
- Admin sign-in, recovery, profile, branding, categories, listings and private Promotions work.
- Test on Android/mobile viewport and a supported desktop browser.
- Verify errors, expired sessions, sign-out and revoked membership handling.

## 5. Verification evidence discipline

For every test, record environment/project, migration version, test identity/role, exact request or workflow, expected result, actual result and date. Distinguish:
- SQL privilege/RLS simulation;
- real REST/Data API request;
- browser end-to-end test;
- manual dashboard configuration check.

A passing SQL simulation is not a substitute for REST or browser testing. Do not mark any target acceptance item complete without evidence from the target single-store schema.

## 6. Release blockers

The revised architecture is not ready for customer onboarding or production. Blockers include:
- Single-store schema and migrations not yet implemented.
- Multiple-admin provisioning and revocation not yet implemented/tested.
- Operator provisioning, migration and maintenance workflow not yet implemented.
- Actual REST/browser tests against the new schema not run.
- Storage upload policies and live public storefront adapter not complete.
- Backup/restore and per-instance upgrade process not demonstrated.

No production deployment, main merge, real customer data or destructive database conversion is authorised by this verification record.
