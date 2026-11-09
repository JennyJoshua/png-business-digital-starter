# Phase 2D — Database security and acceptance test plan

**Status:** test specification only; no tests executed against a new single-store database  
**Target:** clean disposable Supabase project using the Phase 2D schema design

## 1. Test environment and evidence rules

- Use a new disposable project with synthetic records only.
- Do not use the existing `PNG Business Digital Starter Dev` project as a migration target.
- Record project ref, region, PostgreSQL version, Supabase CLI version, migration commit, exposed schemas and test date in the test report.
- Create at least three Auth identities: Admin A, Admin B and Non-member C. Include one pending invitation and one revoked admin for lifecycle tests.
- Use separate anon and authenticated clients. Retain request/SQL output with secrets and personal email addresses redacted.
- Distinguish SQL/pgTAP tests, Data API/REST tests, browser/mobile tests and manual Dashboard checks. A simulated SQL role is not proof of REST or browser behaviour.

## 2. Schema integrity tests

| ID | Scenario | Expected result |
|---|---|---|
| DB-01 | Insert first store profile with singleton key 1 | Succeeds |
| DB-02 | Insert second store profile | Rejected by database constraint |
| DB-03 | Update store_uid or singleton key as admin | Denied |
| DB-04 | Duplicate category_uid/listing_uid/promotion_uid | Rejected |
| DB-05 | Duplicate category or listing slug | Rejected |
| DB-06 | Insert negative price or invalid kind/status | Rejected |
| DB-07 | Insert listing with nonexistent category | Rejected |
| DB-08 | Delete category referenced by listing | Rejected |
| DB-09 | Update created_at/portable IDs through admin API | Denied |
| DB-10 | Admin attempts hard delete of catalogue/promotion row | Denied; archive update remains available |

## 3. Anonymous/public API tests

| ID | Scenario | Expected result |
|---|---|---|
| PUB-01 | Anonymous SELECT published store profile | Only allowlisted public columns |
| PUB-02 | Anonymous SELECT draft/suspended profile | No row |
| PUB-03 | Anonymous SELECT published categories with published store | Published categories only |
| PUB-04 | Anonymous SELECT categories when store is draft/suspended | No rows |
| PUB-05 | Anonymous SELECT published listings | Published listings only |
| PUB-06 | Anonymous SELECT listing with draft/archived category (if category required) | Listing not returned |
| PUB-07 | Anonymous request to admin_api schema/views | Denied |
| PUB-08 | Anonymous request to app_private schema/base tables | Not exposed / denied |
| PUB-09 | Anonymous request for promotions, memberships or settings | Denied / no API object |
| PUB-10 | Inspect public view columns | No Auth IDs, private notes, membership, operator metadata or internal settings |
| PUB-11 | Public storefront routes and search | No Promotions section, banner, navigation item or placement |

## 4. Authentication and administrator authorization tests

| ID | Scenario | Expected result |
|---|---|---|
| AUTH-01 | Unauthenticated request to admin_api | Denied |
| AUTH-02 | Authenticated Non-member C reads admin views | Denied / zero rows |
| AUTH-03 | Pending Admin A reads admin views | Denied |
| AUTH-04 | Active Admin A reads profile/categories/listings/promotions | Allowed |
| AUTH-05 | Active Admin B reads same store | Allowed |
| AUTH-06 | Admin A creates/updates permitted content | Allowed |
| AUTH-07 | Admin A attempts to create/activate/revoke membership | Denied; no membership endpoint/grant |
| AUTH-08 | Admin A attempts to read store_admins | Denied |
| AUTH-09 | Admin A attempts to modify store_uid, IDs, timestamps or operator settings | Denied |
| AUTH-10 | Admin A attempts to publish a field excluded from public allowlist | No private field becomes public |
| AUTH-11 | Admin A attempts direct base-table/API path | Denied because app_private is unexposed; grants remain least-privilege |
| AUTH-12 | Admin A tries a second-store/tenant identifier | No such customer data path exists |

## 5. Revocation tests — critical

1. Sign in as Admin A and retain the existing access token/session.
2. Confirm Admin A can read and update an allowed test record.
3. As operator, change Admin A membership to `revoked`.
4. Without signing out or refreshing the token, call the same admin API read and write requests.
5. Expected: both are denied (or return zero rows for filtered reads); no data changes occur.
6. Confirm Admin B remains able to manage the store.
7. Confirm Non-member C remains denied.
8. Record whether the user still has a valid Auth session; this is expected to be distinct from store authorization.

Do not mark revocation complete if only a new login was tested. Do not claim the JWT itself was invalidated when the database membership check is what blocks store access.

## 6. Data integrity and publication transitions

- Draft to published: public view starts returning the row only after status change.
- Published to archived: public view stops returning it.
- Store profile suspended: all public categories/listings stop appearing.
- Category archived: dependent listing visibility follows the approved category rule.
- Reordering categories/listings changes sort order only, not portable IDs.
- Rename category/listing/slug: portable IDs remain unchanged.
- Archive then restore: same portable IDs and relationships remain.
- Promotions remain absent from public views before and after every status transition.

## 7. View and grant security tests

- Verify every API view uses `security_invoker = true`.
- Verify explicit view column lists; reject `SELECT *`.
- Verify base-table RLS is enabled and policies target explicit Postgres roles with `TO anon` or `TO authenticated`.
- Verify update policies include both `USING` and `WITH CHECK`.
- Verify `anon` cannot reach admin views and `authenticated` non-members cannot pass admin RLS.
- Verify no client role has membership-table privileges, schema CREATE, TRUNCATE, REFERENCES or TRIGGER privileges.
- Verify no client can execute the membership helper as anon/PUBLIC or call any function that accepts an arbitrary user ID.
- Verify no `SECURITY DEFINER` function other than the reviewed no-argument membership predicate exists in the app schema.
- Verify public views do not bypass base-table RLS.

## 8. Browser and mobile acceptance

On Android mobile browser, test:
- Admin sign-in, sign-out and password recovery.
- Pending invite cannot access admin content before activation.
- Admin A and Admin B independently access the same store.
- Profile/branding edits, category create/edit/archive, listing create/edit/archive, private Promotions create/edit/archive.
- Refresh and relogin preserve expected data.
- Public storefront updates only for published records.
- Public UI contains no Promotions section or private admin controls.
- No client-side self-registration or invitation UI.
- Browser network/source inspection shows only project URL and publishable key; no secret/service-role key.

## 9. Operator and project-separation tests

- Operator creates two separate disposable projects for synthetic Store A and Store B.
- Confirm each project has one singleton store and independent Auth users/data.
- Confirm Store A app configuration points only to Store A project; Store B likewise.
- Confirm no shared database, tenant selector, cross-project API key or cross-store membership query.
- Confirm migrations can be applied from zero in a clean project and schema version is recorded.
- Confirm migration failure stops without destructive reset or blind retry.

## 10. Release gate

The single-store baseline is not ready for a customer until:
- All critical schema, public API, admin authorization and revocation tests pass.
- Supabase advisors have been reviewed and relevant findings resolved.
- Real Data API/REST tests and Android browser tests pass.
- No privileged secret is present in browser bundles or repository.
- A backup/restore drill has been performed on a safe target.
- Evidence and known limitations are recorded.
- The platform owner separately approves customer onboarding and deployment.

This plan does not claim any test has passed. It defines what must be proven after an implementation exists.
