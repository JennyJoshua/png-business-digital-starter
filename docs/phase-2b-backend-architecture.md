# Phase 2B — Owner Admin Backend Architecture

**Status:** Architecture proposal on `phase-2b/owner-admin-backend-foundation`. This is not a deployment or a final platform selection. No cloud resources, credentials, database schema, migrations or authentication settings have been changed.

**Purpose:** Establish a secure, affordable and marketplace-ready foundation for the private business-owner admin while preserving the current public static storefront and the one-repository/one-deployment customer delivery model.

## 1. Current baseline and constraints

- Phase 2A is merged into `main` (PR #3). Public Promotions output is removed; the public search experience is implemented.
- The current app is a zero-runtime-dependency Node.js static generator. It has no login, server, database or persistent owner editing.
- Each customer receives an independent storefront repository and deployment.
- The long-term data contract must preserve stable business/listing identifiers and allow owner-approved onboarding into PNG Materials Marketplace without re-entering all data.
- The preferred operating constraint is no paid services during development and reuse of existing accounts where possible. These Free Plan projects are development/testing environments only; before public launch or live customer use, plan and approve a suitable paid production setup.

## 2. Recommended direction

**Recommend Supabase as the first backend candidate, using one shared multi-tenant project for this product rather than one database project per business.**

This recommendation is based on an integrated Postgres database, Auth, Storage and database-enforced Row Level Security, and the existing Supabase account already used in the user's other work. It avoids introducing a separate paid application server for the first pilot.

The recommended topology is:

- Each customer keeps an independent public storefront repository and static deployment.
- The owner-admin interface is a separate route/application surface, but may share the same repository and design tokens.
- All participating stores connect to one central backend project using a publishable client key.
- Every business-owned record carries a `business_id` foreign key; every owner access is checked against a database membership record.
- Postgres RLS is the mandatory authorization boundary. Frontend filtering is never treated as security.
- A future marketplace can consume a versioned, consent-based business/listing export or API without depending on the static site's file layout.

**Important distinction:** independent storefront repositories/deployments do not mean independent database projects. A shared backend is a multi-tenant architecture and must pass cross-tenant security tests before any real business data is stored.

## 3. Free-tier reality and operating limits

Supabase's official pricing and billing pages checked 9 November 2026 state that the Free plan includes two active projects, 500 MB database per project, 1 GB file storage, 5 GB egress and 50,000 monthly active users. Free projects pause after one week of inactivity. The Free plan does not include automatic backups, and projects beyond the free allowance may require paid service.

Consequences:

1. Use one shared backend project for the Digital Starter pilot, not a new project for every business.
2. The two-active-project quota applies across all Free Plan organizations where the account is an Owner or Administrator. Paused projects do not count, so projects can be rotated manually without deleting them.
3. Pausing a project makes its database/API-backed applications unavailable. Never pause a live customer-facing project unless its downtime is explicitly acceptable.
4. A paused Free Plan project can be restored through the dashboard's one-click restore for **90 days**. After 90 days, the one-click restore window has expired; recovery requires downloading the available database backup and Storage objects, then restoring them to a project or locally. Treat this as a recovery path, not a routine rotation.
5. Pausing is not a backup strategy. Keep independent database and Storage backups before any planned pause, especially because Free Plan projects do not include automatic backups.
6. Avoid uploading large original photos; resize/compress images before upload and monitor storage/egress.
7. Keep Free Plan projects limited to development and testing. Before publishing a site or using it for live customer/business operations, plan and approve paid production hosting/backend capacity, backups and operational requirements. Do not assume a development project is production-ready.
8. Do not create a new Supabase project until the user confirms the intended organization and explicitly approves the project creation.

Sources:
- https://supabase.com/pricing
- https://supabase.com/docs/guides/platform/billing-on-supabase
- https://supabase.com/docs/guides/platform/billing-faq

## 4. Logical data model

Use UUID primary keys internally and preserve stable external identifiers for imports/marketplace portability.

| Entity | Purpose | Visibility |
|---|---|---|
| `businesses` | Canonical business profile, stable `business_id`, publication status | Public fields only when published |
| `business_memberships` | Maps Auth users to businesses and their role | Owner/admin only |
| `business_private_settings` | Private settings and operational metadata | Members only |
| `categories` | Business-specific or shared taxonomy | Public only when attached to a published catalogue |
| `listings` | Product/service records, stable `listing_id`, price/currency, publication state | Published fields only |
| `promotions` | Owner-created promotional drafts and internal copy | Private to authorized members in v1 |
| `asset_metadata` | Storage paths, ownership and intended use | Members; public assets are delivered through public URLs |

Data rules:
- A business may have multiple authorized members in the schema, even if v1 initially provisions one owner.
- A user may be a member of more than one business.
- Membership roles are stored in the database, never trusted from editable user metadata.
- Listing identifiers remain stable across edits and exports; deletion/archival must not silently recycle IDs.
- Price is numeric plus an explicit ISO currency code; do not store formatted display text as the canonical amount.
- Promotions are not included in public queries, public exports or public storage.
- Public views/exports use an explicit field allowlist; no `select *` as a public API contract.

## 5. Authorization and publication model

### Public visitor (unauthenticated)
- Can read only public business profile fields for businesses marked `published`.
- Can read only listings/categories marked `published` that belong to a published business.
- Cannot read memberships, private settings, draft/unpublished listings, owner notes or promotions.
- Cannot write any business/catalogue/admin data.

### Authenticated business owner/member
- Can read and update only businesses for which a matching active membership exists.
- Can create/update/delete only records scoped to those businesses, subject to role permissions.
- Cannot add themselves to another business or promote their own membership role.
- Cannot change stable ownership/tenant identifiers through ordinary profile/listing updates.
- Cannot read another business's private data, including by guessing UUIDs or changing request parameters.

### Trusted operator
- Initial business provisioning and owner invitation use a trusted administrative process.
- Any privileged server key is restricted to server-side secrets and never appears in static HTML, JavaScript, source maps, Git history or customer configuration.
- Admin invitations, role changes and account recovery are audited.

### Mandatory implementation safeguards
- Enable RLS on every table exposed through the Data API.
- Use explicit grants and separate policies for SELECT, INSERT, UPDATE and DELETE.
- UPDATE policies require both `USING` and `WITH CHECK`.
- Check membership from protected database records; do not authorize with `user_metadata`.
- Add indexes for business/membership columns used in policies.
- Treat public buckets as public: only intentionally public images go there. Enforce owner-only upload/update/delete by business path. Keep any future private documents in a private bucket.
- Do not add broad `SECURITY DEFINER` functions to bypass policy problems.
- Test with at least two business tenants and two users, including unauthenticated access, guessed IDs, cross-tenant writes, role escalation and unpublished content.

Supabase references:
- https://supabase.com/docs/guides/database/postgres/row-level-security
- https://supabase.com/docs/guides/storage/security/access-control
- https://supabase.com/docs/guides/getting-started/the-supabase-way-to-build

## 6. Application shape

Keep the public storefront lightweight and static where possible. Add a separate private owner-admin surface (for example, `/admin/`) that:
- requires an authenticated session before rendering protected data;
- uses a publishable key only;
- performs data operations under the signed-in user's JWT so RLS is applied;
- handles session expiry and logout;
- never assumes hiding a route is access control;
- uses database publication state to control what the public storefront can read.

A small trusted server-side function may be needed for operator-only onboarding/invitations and other actions that require privileged credentials. It must be narrowly scoped and must validate inputs and caller authorization. Do not put a service-role/secret key in the browser.

**Static storefront integration:** Phase 2B should not silently break the existing generated public pages. First establish a canonical backend contract and a controlled data adapter. During migration, the current JSON-to-static build remains the fallback until a test storefront proves it can read published backend data safely. Avoid maintaining two editable sources of truth indefinitely; define a one-way import from current JSON into canonical database records.

## 7. Suggested implementation sequence

| Step | Deliverable | Exit condition |
|---|---|---|
| 2B.1 | Confirm provider, tenancy model and owner onboarding policy | Owner decisions recorded |
| 2B.2 | Versioned schema and migrations | Schema review; no production apply |
| 2B.3 | RLS policies and pgTAP tests | Cross-tenant and anonymous tests pass |
| 2B.4 | Auth and owner provisioning | Invitation/recovery/session tests pass |
| 2B.5 | Private admin shell and business profile | Owner can manage own profile only |
| 2B.6 | Catalogue/categories CRUD and image storage | Owner CRUD + public read boundary passes |
| 2B.7 | Private Promotions module | No public query/export leakage |
| 2B.8 | Public storefront data adapter and migration | Existing static build remains deployable; integration verified |
| 2B.9 | Marketplace export/API contract | Stable IDs and explicit owner consent verified |

## 8. Decisions still required before database implementation

The following are the minimum architecture decisions. The recommendation is shown; alternatives remain open until the owner confirms.

1. **Backend provider:** Supabase (recommended, reuse existing account) vs another provider.
2. **Tenant topology:** one shared multi-tenant Supabase project for all customer storefronts (recommended for free-tier feasibility) vs one project per customer (not feasible at scale on the Free plan).
3. **Owner onboarding:** invitation-only during pilot (recommended for security) vs public self-registration with pending business approval.
4. **Initial membership roles:** one owner only in v1 (recommended) vs owner plus staff roles from the beginning.
5. **Existing project:** reuse an existing Supabase project only after confirming it is suitable and isolated from the PNG Materials Marketplace; otherwise create a separate Digital Starter project only with explicit approval.

No database or cloud changes are authorized by this architecture proposal. Once these decisions are approved, implementation can begin with reviewed migrations and RLS tests on this branch.
