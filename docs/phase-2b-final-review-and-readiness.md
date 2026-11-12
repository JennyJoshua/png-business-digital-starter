# Phase 2B — Final Code Review and Readiness Handover

**Review date:** 12 November 2026  
**Repository:** `JennyJoshua/png-business-digital-starter`  
**Review status:** PR #8 has been merged and its GitHub Pages deployment workflow completed successfully. PR #9 remains a draft, open and unmerged. Hosted database rollout remains approval-gated.

## Executive result

The Phase 2B owner-admin foundation and security-remediation changes pass the latest repository CI runs. The implementation reflects the owner's approved publication policy:

**Only platform administrators may publish businesses, categories, products and services.** Owners may manage their own business profile and prepare/edit drafts. Owners cannot publish or unarchive records and may archive only their own categories/listings through membership-checked operations.

The review addressed a public category/listing RLS permission defect and added protection against duplicate active owner memberships, public-view DML and overly broad default privileges.

This is not a go-live approval or an independent third-party penetration test. Real browser authentication, invitation delivery, platform-admin publishing workflow, Storage policies, audit trail, public data synchronization and production operations remain incomplete.

## Current pull request and CI status

| PR | Scope | Current state | Latest CI |
|---|---|---|---|
| [#8 — Private owner-admin foundation](https://github.com/JennyJoshua/png-business-digital-starter/pull/8) | Owner admin app, platform-only publication controls, public RLS support fix, tests and docs | Merged 12 Nov 2026; merge commit `4bfd9e5287a44b1ab6dd3349748df407b5f79dc2` | [Pages deployment run #11 — success](https://github.com/JennyJoshua/png-business-digital-starter/actions/runs/43145840341) |
| [#9 — Phase 2B security remediation](https://github.com/JennyJoshua/png-business-digital-starter/pull/9) | One-active-owner index, read-only public views, default-privilege hardening, security docs and SQL tests | Draft; open; unmerged; targets `main`; 23 commits ahead, 0 behind; 7 changed files | Latest test workflow for head `8470a07c3e5dd8392b4422dd45d9f272a82adc10` — success |

PR #8 is merged. PR #9 has been retargeted to `main`; its resulting diff contains only seven security-remediation workflow, audit-documentation, migration and SQL-test files. GitHub reports the PR as mergeable and clean. The latest test workflow associated with its head commit completed successfully.

**Review-record note:** GitHub currently shows no submitted formal PR reviews or inline review threads on either PR. The present assessment is a repository/code inspection plus automated CI evidence; it should not be described as an independent external review.

## Verified implementation and test results

### PR #8 — owner administration and publication controls

The reviewed implementation includes:

- Browser code uses the Supabase publishable key; no service-role or secret key is included in the browser bundle.
- No public owner self-registration flow.
- Owner access is based on active `owner` memberships.
- Business/category/listing/promotions queries are scoped to the selected business.
- The business selector is disabled and the admin panel made inert during business switching.
- Password recovery uses the stable admin pathname as its callback.
- Unexpected promise/network failures produce user-facing feedback.
- Promotions remain in the private owner-admin area and are not included in public storefront output.
- Owner publication privileges are removed at the database column/view level.
- Archive implementations are SECURITY DEFINER functions in unexposed `app_private`; exposed `admin_api` functions are SECURITY INVOKER wrappers with authenticated-only execution.

The disposable PostgreSQL 17 integration suite passed checks for:

- Owner A can read their own business but not tenant B.
- Owners can create and edit category/listing drafts.
- New categories and listings default to `draft`.
- Owners cannot insert/update business, category or listing publication status.
- Owners can archive their own categories/listings.
- Owners cannot archive another tenant's records.
- Platform-admin publication produces the expected anonymous storefront visibility.
- Anonymous queries can read the three public storefront views without returning the internal business UUID.

### PR #9 — security remediation

The disposable PostgreSQL 17 integration suite passed checks for:

- The partial unique index rejects a second active owner for the same business.
- Public storefront views grant SELECT but not INSERT/UPDATE/DELETE to `anon` or `authenticated`, including simulated inherited `PUBLIC` grants.
- Future public tables created by both `postgres` and `supabase_admin` do not inherit broad `PUBLIC`, `anon` or `authenticated` privileges.

The earlier live read-only audit found no duplicate active owner memberships and no membership rows at the time of inspection. That historical observation is not a substitute for a fresh live check before applying migrations.

## Security defect fixed

A seeded PostgreSQL test exposed that anonymous category/listing reads could fail because the public RLS policies check the parent business UUID while `anon` lacked SELECT on `app_private.businesses.id`.

PR #8 grants that one internal column to `anon` for the RLS predicate. The `app_private` schema remains unexposed through the Data API, and public storefront views do not select or return the internal UUID. The PostgreSQL integration suite verifies anonymous visibility for published records.

## Supabase configuration evidence

Previously verified configuration:

- Public signups disabled (`disable_signup=true`).
- Email provider enabled.
- Anonymous Auth disabled.
- Email auto-confirm disabled.
- Data API exposed schemas: `public`, `graphql_public`, `admin_api`; `app_private` remains unexposed.

On 11 November 2026, the user confirmed these Supabase Authentication URL settings in the dashboard:

- Site URL: `https://jennyjoshua.github.io/png-business-digital-starter/`
- Redirect allow-list includes: `https://jennyjoshua.github.io/png-business-digital-starter/admin/`

These URL values are user-confirmed, not independently re-read by the verification connection.

The public GitHub Pages demo storefront and `/admin/` route are deployed. The Pages deployment workflow triggered by the PR #8 merge completed successfully on 12 November 2026. The user has opened the admin application and confirmed it displays.

## Hosted database and deployment status

- Four foundational migrations were previously applied to the development project.
- PR #8's platform-publication migration has not been applied to hosted Supabase.
- PR #9's owner-uniqueness/public-view migration has not been applied to hosted Supabase.
- No owner invitation has been sent.
- No real business/customer data has been added.
- PR #8 has been merged and the Pages deployment succeeded. PR #9 remains unmerged.
- The PR #8 platform-publication migration and PR #9 owner-uniqueness/public-view migration have not been applied to hosted Supabase.
- No paid service has been configured.

## Remaining go-live blockers

1. **Platform-admin publication interface:** not yet built. Until it exists, publication must remain a controlled privileged process. Never place a service-role key in browser code or grant owners publication privileges as a shortcut.
2. **Authentication end-to-end:** test invitation and password-recovery PKCE callbacks on the deployed admin page.
3. **Email delivery:** test invitation delivery to an external/non-organization address. If default SMTP cannot deliver, stop for approval; do not add paid SMTP without approval.
4. **Browser/API authorization:** test a real invited test owner performing sign-in, draft CRUD and archive, and verify cross-tenant denial and direct API attempts to publish.
5. **Storage:** create and test least-privilege bucket/object policies before enabling image uploads.
6. **Public synchronization:** implement the live public storefront adapter; owner edits currently do not synchronize with the static public site.
7. **Auditability:** add append-only audit events for owner and platform-admin actions.
8. **Password policy:** confirm/enforce the minimum password policy server-side; a client-side length check is not a security boundary.
9. **Operational readiness:** review hosting, backups, monitoring, data retention, recovery and costs separately. The current Free development project is not approved for live customer operations.

## Recommended next sequence

1. Complete the independent review of PR #9's seven-file security-remediation diff and resolve any findings.
2. Present PR #9 for the owner's explicit merge decision. Do not merge without approval.
3. Only after separate explicit approval, apply the PR #8 and PR #9 pending migrations to the hosted development database in order. Then verify grants, indexes, Supabase advisors and live REST behaviour.
4. Complete invitation/recovery and authenticated browser/API tests before creating any real owner membership or business data.
5. Build and test the platform-admin publication workflow and remaining go-live capabilities before onboarding real businesses.

**Current recommendation:** PR #8's owner-admin foundation is deployed for inspection. PR #9's isolated security changes are ready for final code review, but not for production use. Do not merge PR #9, apply hosted migrations or onboard owners automatically.
