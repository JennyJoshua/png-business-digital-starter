# Phase 2B — Final Code Review and Readiness Handover

**Review date:** 11 November 2026  
**Repository:** `JennyJoshua/png-business-digital-starter`  
**Status:** Code-level security review and disposable-database integration testing completed. Both review PRs are draft/unmerged. Hosted rollout remains approval-gated.

## Executive result

The Phase 2B owner-admin foundation has passed the current repository and PostgreSQL 17 integration checks. The implementation now reflects the owner's publication decision:

**Only platform administrators may publish businesses, categories, products and services.** Owners can manage their own profile and prepare/edit drafts; they cannot publish or unarchive records. They can archive only their own categories/listings through membership-checked operations.

The review also found and corrected a public category/listing RLS permission defect. The fix is in PR #8 and is covered by an anonymous storefront integration test.

This is not a go-live approval. Real browser authentication, invitation delivery, platform-admin publishing workflow, Storage, audit trail, public data synchronization and production hosting remain incomplete.

## Pull request status

| PR | Scope | State | CI |
|---|---|---|---|
| [#8 — Private owner-admin foundation](https://github.com/JennyJoshua/png-business-digital-starter/pull/8) | Admin app, platform-only publication controls, public RLS support fix, tests and docs | Draft; open; unmerged | Run #144 — **success** |
| [#9 — Phase 2B security remediation](https://github.com/JennyJoshua/png-business-digital-starter/pull/9) | One-active-owner index, read-only public views, default-privilege hardening, audit docs and SQL tests | Draft; open; unmerged; stacked on PR #8 | Run #154 — **success** |

PR #9 is reconciled onto the current PR #8 branch. GitHub compare reports it as ahead with zero commits behind, and the PR is mergeable. Its diff contains only the security-remediation workflow/doc/migration/test files.

## Verified implementation and test results

### PR #8 owner-admin and publication controls

- Browser code uses only the Supabase publishable key; no service-role or secret key is included.
- No public owner sign-up flow exists.
- Owner lookup filters to active `owner` memberships.
- Business data requests are tenant-scoped.
- The business selector is disabled and the admin panel inert during a business switch.
- Password recovery uses the stable admin pathname as its callback.
- Unexpected promise/network failures produce user-facing feedback.
- Promotions remain private and absent from public storefront output.
- Owner publication privileges are removed at the database column/view level.
- SECURITY DEFINER archive implementations live in unexposed `app_private`; exposed `admin_api` RPCs are SECURITY INVOKER wrappers with authenticated-only execution.

Disposable PostgreSQL 17 tests passed for:
- Owner A sees their own business but not tenant B.
- Owner can create and edit category/listing drafts.
- New records default to `draft`.
- Owner cannot insert/update business/category/listing publication status.
- Owner can archive own categories/listings.
- Owner cannot archive another tenant's records.
- Platform-admin publication results in the expected anonymous storefront visibility.
- Anonymous queries to all three public views succeed without exposing the internal business UUID.

### PR #9 security remediation

Disposable PostgreSQL 17 tests passed for:
- Duplicate active owner memberships are rejected by the partial unique index.
- Public storefront views retain SELECT but not INSERT/UPDATE/DELETE for `anon` or `authenticated`, including simulated inherited `PUBLIC` grants.
- Future public tables created by both `postgres` and `supabase_admin` do not inherit broad `PUBLIC`, `anon` or `authenticated` privileges.

The live project read-only audit found no duplicate active owner memberships and no membership rows at the time of inspection.

## Important defect found and corrected

The seeded PostgreSQL test found that anonymous category/listing reads could fail because the public RLS policies check the parent business UUID, while `anon` lacked SELECT on `app_private.businesses.id`.

PR #8 now grants that one internal column to `anon` for the RLS predicate only. The schema remains unexposed through the Data API, and none of the public storefront views select or return the internal UUID. The PostgreSQL suite verifies that published storefront records are visible anonymously and draft/archived records are not.

## Supabase configuration evidence

- Live Auth settings previously verified: public signups disabled, email provider enabled, anonymous Auth disabled, email auto-confirm disabled.
- Data API exposed schemas previously verified: `public`, `graphql_public`, `admin_api`; `app_private` remains unexposed.
- On 11 November 2026, the user confirmed the Site URL and admin Redirect URL in the dashboard:
  - `https://jennyjoshua.github.io/png-business-digital-starter/`
  - `https://jennyjoshua.github.io/png-business-digital-starter/admin/`
- The URL values are user-confirmed, not independently re-read by the verification connection.
- The public Pages site is live with the demo storefront. The `/admin/` route is not yet deployed because PR #8 is unmerged.

## Hosted database and deployment safety

- Four foundational migrations are already applied to the development project.
- The new PR #8 publication-control migration has **not** been applied to hosted Supabase.
- The PR #9 one-active-owner/public-view migration has **not** been applied to hosted Supabase.
- No owner invitation has been sent.
- No real business/customer data has been added.
- No merge to `main` or GitHub Pages deployment has been triggered.
- No paid service has been configured.

## Remaining go-live blockers

1. **Platform-admin publication interface:** not yet built. Until it exists, publication requires a controlled privileged process; never use a browser service-role key or owner privileges as a shortcut.
2. **Auth end-to-end:** test invitation and password-recovery PKCE callbacks on the deployed admin page.
3. **Email delivery:** test invitation delivery to an external/non-organization address. If default SMTP cannot deliver, stop for approval; do not add paid SMTP without approval.
4. **Browser/API authorization:** test real invited-owner sign-in, draft CRUD, archive, cross-tenant denial and direct attempts to publish through the actual Supabase Data API.
5. **Storage:** create and test least-privilege bucket/object policies before enabling image upload.
6. **Public sync:** implement the live public storefront adapter; owner edits currently do not synchronize with the static public site.
7. **Auditability:** add append-only audit events for owner and platform-admin actions.
8. **Password policy:** confirm/enforce the minimum password policy server-side; a client-side length check is not a security boundary.
9. **Production plan:** review hosting, backups, monitoring, data retention, recovery and cost separately. The current Free development project is not approved for live customer operations.

## Recommended approval sequence

1. Owner reviews and explicitly approves PR #8 merge to `main`. A successful merge will trigger the existing GitHub Pages workflow and publish the owner-admin route; treat this as a visible deployment and approve it separately.
2. After PR #8 is merged, retarget PR #9 from the feature branch to `main`, verify its diff contains only security-remediation changes, and review/approve it.
3. Only after explicit approval, apply PR #8 and PR #9 pending migrations to the hosted development database in order, then verify grants, indexes, Supabase advisors and real REST behaviour.
4. Complete invitation/recovery/browser tests before creating any real owner membership or business data.
5. Build the platform-admin publication workflow and remaining go-live capabilities before onboarding real businesses.

**Current recommendation:** code-level review is sufficiently complete to present PR #8 and PR #9 for owner decision. Do not merge, deploy, apply hosted migrations or onboard owners automatically.
