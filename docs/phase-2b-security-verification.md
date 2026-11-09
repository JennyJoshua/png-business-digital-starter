# Phase 2B — Security Verification

**Environment:** `PNG Business Digital Starter Dev`  
**Project ref:** `rwcwvqlgyckfdrglsbfg`  
**Region:** `ap-southeast-2` (Sydney)  
**Verification date:** 9 November 2026  
**Branch:** `phase-2b/owner-admin-interface-foundation`

## Implemented foundation

- Seven application tables under `app_private`; RLS enabled on all seven.
- 22 policies covering anonymous publication reads, active-owner reads/writes and private data.
- Three explicit public views: `public.storefront_businesses`, `public.storefront_categories`, `public.storefront_listings`.
- Seven security-invoker views under `admin_api`, granted only to authenticated users.
- Public and admin views use explicit column lists and invoke underlying table privileges/RLS.
- Anonymous `SELECT` is granted only on the three public-read base tables (`businesses`, `categories`, `listings`); their existing RLS policies restrict rows to published records belonging to published businesses. Promotions, memberships, private settings and asset metadata remain inaccessible to `anon`.
- Promotions, memberships, private settings and asset metadata are not included in public views.
- User confirmed that `admin_api` was added to the Data API exposed-schema list in the Supabase Dashboard and saved, with `public` retained and `app_private` left unexposed. The setting has not yet been independently verified through a browser REST request; that is still required.
- No SECURITY DEFINER function was created.
- Membership writes are not granted to authenticated users; stable external identifiers are not updateable through normal owner grants.

## Tests performed

Temporary fixtures used two test Auth users and two business tenants. The SQL checks ran inside transactions and were rolled back; no test users or business records were retained.

| Test | Result |
|---|---|
| Anonymous public views return published businesses | PASS |
| Anonymous public views return published listings only | PASS — draft listing omitted |
| Anonymous role has no SELECT privilege on Promotions | PASS |
| Anonymous role has no SELECT privilege on memberships | PASS |
| Owner A sees their own business only | PASS |
| Owner A sees own draft and published listings | PASS |
| Owner A reads own private Promotions | PASS |
| Owner A cannot see tenant B's business/listing | PASS |
| Owner A cross-tenant listing update affects zero rows | PASS |
| Owner A cross-tenant listing insert is rejected by RLS | PASS |
| Authenticated role cannot update memberships or self-promote | PASS — no UPDATE privilege |
| Authenticated role cannot insert businesses directly | PASS — no INSERT privilege |
| Owner cannot update stable business identifier | PASS — no column UPDATE privilege |
| Owner API view returns only the signed-in owner's business | PASS |
| Owner API membership view returns only own active membership | PASS |
| Anonymous role has no usage on `admin_api` | PASS |
| Anonymous role has no SELECT on admin Promotions view | PASS |
| Authenticated role cannot insert/update membership view | PASS — no privileges |

## Supabase advisors

- **Security Advisor:** no findings at verification time.
- **Performance Advisor:** no unindexed foreign-key findings after adding indexes for the two flagged foreign keys. It reports unused indexes as informational because the new development schema has no retained production workload; review index usage after real test traffic.

## Migration history

- `20261109000651` — `phase_2b_owner_admin_core`
- `20261109000726` — `phase_2b_public_read_and_fk_indexes`
- `20261109001259` — `phase_2b_admin_api_views`
- `20261109002919` — `phase_2b_public_storefront_read_grants`

All three SQL files are version-controlled under `supabase/migrations/`.

## Important remaining checks

1. Verify and configure the project's exposed Data API schema list before client integration: expose `public` and `admin_api` as required, never `app_private`.
2. Configure and verify Auth invitation-only settings before any owner account is provisioned.
3. Test through the actual Supabase REST/Data API and browser client after schema exposure and Auth configuration, not only via SQL role simulation.
4. Add Storage bucket/object policies before enabling image upload.
5. Repeat the security tests whenever RLS policies, grants, views or tenant relationships change.

**Scope:** This verifies the core database boundary only. It does not mean the admin UI, authentication workflow, Storage uploads or production readiness are complete.


## Owner-admin application security review

- Browser client uses only the Supabase publishable key; no secret/service-role key is included.
- Every owner-data request is explicitly scoped to `admin_api`.
- The application contains no public registration flow.
- New categories/listings default to draft; archive actions do not hard-delete them.
- Promotions are managed only in the authenticated owner area and remain absent from public storefront output.
- CI passed JavaScript syntax validation, automated tests, starter-data validation and demonstration builds.

**Not yet end-to-end verified:** Data API exposure through actual REST requests, Auth signup/anonymous settings, invitation/recovery email delivery, actual browser sign-in and owner CRUD through the REST API. These remain go-live blockers; see [Owner Auth setup](phase-2b-owner-auth-setup.md).
