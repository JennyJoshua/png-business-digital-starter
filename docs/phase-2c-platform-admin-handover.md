# Phase 2C — Platform-admin publication console handover

**Repository:** `JennyJoshua/png-business-digital-starter`  
**Branch:** `phase-2c/platform-admin-console`  
**Pull request:** [#11 — Phase 2C: add platform-admin publication console](https://github.com/JennyJoshua/png-business-digital-starter/pull/11)  
**Issue:** [#10 — Phase 2C scope](https://github.com/JennyJoshua/png-business-digital-starter/issues/10)  
**Verified head at handover:** `ae82c6b832ef9a9ebfc8fac7fff75cff294321bc`  
**Status:** Draft PR; CI passed on push and pull-request events. Not merged or deployed.

## Delivered

1. A separate mobile-responsive `/platform-admin/` sign-in and publication review interface. The existing `/admin/` owner interface is unchanged and remains a separate experience.
2. A private database allowlist, `app_private.platform_admins`, that determines platform-admin access. No user metadata, browser flag, public signup or owner-side operation can grant this role.
3. A protected review queue for businesses, categories, products and services.
4. Publish/unpublish actions with confirmation and an optional review note.
5. Database-side checks: only allowlisted platform admins can invoke privileged actions; businesses must be published before their categories/listings; assigned categories must be published before their listings; archived categories/listings cannot be restored through this console; suspended businesses require a separate reinstatement review.
6. A private publication audit log recording actor, entity type and ID, action, previous/new status, reason and timestamp.
7. Static build integration so the new route is included in generated storefront output.
8. Updated README, architecture, outstanding-issues and historical Phase 2B readiness documentation.

## Security model

- The browser contains only the existing Supabase publishable key. Requests use the signed-in user's JWT.
- The allowlist and audit table are in the unexposed `app_private` schema, with no direct API table grants.
- Privileged operations are implemented as narrowly scoped SECURITY DEFINER functions in `app_private`; exposed `admin_api` functions are SECURITY INVOKER wrappers.
- The functions independently check the caller's authenticated identity against the allowlist. Hiding the interface is not treated as authorization.
- No service-role key or privileged secret is included in browser code.
- No platform administrator has been provisioned. The allowlist is intentionally empty until a separate controlled setup is approved.

## Verification

GitHub Actions passed on the verified head:

- Push CI run [#190](https://github.com/JennyJoshua/png-business-digital-starter/actions/runs/43149707075) — success.
- Pull-request CI run [#191](https://github.com/JennyJoshua/png-business-digital-starter/actions/runs/43149711724) — success.

The workflow verified:

- JavaScript syntax for both admin clients.
- Existing storefront regression tests and starter-data validation.
- Builds of all demonstration storefronts.
- Presence of the generated `platform-admin/index.html` and client script.
- Existing Phase 2B PostgreSQL 17 publication-control and security-remediation tests.
- New Phase 2C PostgreSQL 17 tests for administrator allowlisting, owner/anonymous denial, protected publication actions, parent business/category requirements, audit records and public storefront visibility.

These are disposable PostgreSQL integration tests, not live Supabase verification or an external penetration test.

## Rollout gates — not performed

- The Phase 2C migration `20261112140000_phase_2c_platform_admin_console.sql` is committed as a file only. It has not been applied to hosted Supabase.
- The Phase 2B migrations from PR #8/#9 also remain pending on the hosted project as previously recorded. Before any rollout, inspect the hosted migration history and apply only the verified pending migrations in timestamp order, with separate explicit approval.
- Do not provision the first platform-admin allowlist entry until the user confirms which Auth identity is the platform administrator and separately approves the controlled database operation.
- No owner invitation, real business/customer data, hosted Auth/Data API setting change, paid service, main merge or deployment has been performed.
- GitHub Pages deployment remains configured for pushes to `main` only. This PR does not trigger a production/demo deployment.
- Before enabling password recovery or invitation callbacks specifically for `/platform-admin/`, verify the Supabase redirect allow-list for that route.

## Next decision

Review draft PR #11. Merge and deployment require separate explicit approval. Hosted migration application and first administrator provisioning are also separate approval gates; approval of this PR alone does not authorize either.
