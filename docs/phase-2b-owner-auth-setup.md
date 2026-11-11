# Phase 2B — Owner Authentication Setup and Safety Gates

**Project:** PNG Business Digital Starter Dev  
**Project ref:** `rwcwvqlgyckfdrglsbfg`  
**Dashboard:** https://supabase.com/dashboard/project/rwcwvqlgyckfdrglsbfg  
**Status:** Public signup is disabled and verified. GitHub Pages is the selected host. The Pages project site is live (HTTP 200) and currently serves the public demo storefront. The `/admin/` path currently returns HTTP 404 because the Phase 2B admin app remains on an unmerged branch. Site URL/redirect allow-list and invitation delivery remain outstanding.

## 1. Data API schema exposure

Open [Project Settings → Data API](https://supabase.com/dashboard/project/rwcwvqlgyckfdrglsbfg/integrations/data_api/settings).

The browser admin calls the schema explicitly with `supabase.schema('admin_api')`. Configure the exposed schema list to include:
- `public` — required for the public storefront views.
- `admin_api` — required for authenticated owner-admin views.

**Do not expose `app_private`.** It contains the underlying application tables. The owner API views in `admin_api` use `security_invoker = true`; their underlying table privileges and RLS remain in force.

The saved schema list was confirmed through live REST probes: `public`, `graphql_public`, and `admin_api` are exposed; `app_private` is not. Anonymous access to `admin_api` was denied as expected.

## 2. Auth general settings

The user turned off **Allow new user signups** in the Supabase dashboard. A fresh public Auth settings request verified `disable_signup=true`.

| Setting | Verified value | Reason |
|---|---|---|
| Allow new user signups | **Off** | No public self-registration for business owners |
| Allow anonymous sign-ins | **Off** | No anonymous Auth sessions |
| Email provider | On | Owner email/password login |
| Confirm email | On | Verify invited owner email before sign-in |

The admin app intentionally has no registration form or `signUp()` call. An owner must already have been invited and have an active database membership.

Supabase reference: [General Auth configuration](https://supabase.com/docs/guides/auth/general-configuration).

## 3. GitHub Pages hosting and Supabase callback URLs

GitHub Pages is the selected host for the owner-admin interface.

**Expected repository project-site URL:**
`https://jennyjoshua.github.io/png-business-digital-starter/`

**Expected owner-admin URL:**
`https://jennyjoshua.github.io/png-business-digital-starter/admin/`

The project-site URL has been confirmed live with HTTP 200. The `/admin/` path currently returns HTTP 404 and is not yet deployed. The expected admin URL will become live only after the owner-admin foundation is approved, merged, and successfully deployed.

### Existing deployment workflow

The repository already has `.github/workflows/deploy-pages.yml` on `main`. It deploys the generated `dist/` directory to GitHub Pages on pushes to `main` and manual workflow dispatch. On current `main`, the build publishes the public demonstration storefront.

The Phase 2B owner-admin foundation branch changes the build script to copy the private admin app into `dist/admin/`. Once that branch is reviewed and merged, the existing Pages workflow will include `/admin/` in the Pages artifact and publish it on the next successful main deployment. Until then, the owner-admin page is not part of the live Pages site. No deployment has been triggered by this setup work. The live site remains the public demonstration storefront; no owner-admin page is published yet.

### Supabase URL settings to configure after deployment is confirmed

Set the Supabase Authentication URL configuration as follows:

- **Site URL:** `https://jennyjoshua.github.io/png-business-digital-starter/`
- **Allowed redirect URL:** `https://jennyjoshua.github.io/png-business-digital-starter/admin/`
- Add a local development callback only if it is actually needed for a controlled test.
- Do not add broad wildcards or unrelated preview URLs.

The application calls `resetPasswordForEmail(..., { redirectTo: window.location.href })`; invitation/recovery links must therefore be allowed to return to the exact `/admin/` page. The Supabase public settings endpoint currently returned `null` for `site_url` and `uri_allow_list`, so these dashboard settings still need to be configured and verified.

Do not set these URLs based only on an assumed hostname if the repository's Pages settings show a custom domain or a different published URL.

## 4. Invitation email delivery

Inviting a user is an administrator action and must be done from the Supabase dashboard or a trusted server using the secret key. Never put a secret/service-role key in the browser.

Before any external business owner is invited, test whether the project's configured email provider can deliver to an address that is not an organization member. Supabase's default email provider has historically restricted delivery to organization members; if the Free project's default SMTP cannot deliver to the intended recipient, stop and bring the options back for approval. Do not silently configure a paid SMTP service or add a paid service.

Reference: [Supabase Auth users and invitations](https://supabase.com/docs/guides/auth/users).

## 5. First-owner provisioning sequence

No real owner account or business record has been created yet. When the user approves the actual business details and owner email, use this controlled sequence:

1. Verify the saved Data API exposure and Auth settings above.
2. Confirm the GitHub Pages deployment URL and configure/verify Supabase Site URL and redirect allow-list.
3. Test invitation and password-recovery callbacks on the deployed `/admin/` page.
4. Verify invitation email delivery to the intended recipient.
5. Send the owner invitation from Authentication → Users.
6. Retrieve the invited Auth user's UUID from the dashboard.
7. Insert the business record and its active `owner` membership using a reviewed, one-time SQL statement in the Supabase SQL Editor. The membership is what grants business access; Auth account creation alone grants no business data access.
8. Test sign-in, password setup, owner-only view access, cross-tenant denial and sign-out.
9. Do not put a business's real customer data into the Free development project.

The SQL statement must be prepared only after the business name, permanent business ID, slug, type and owner account UUID are known and confirmed. Do not create placeholder or dummy owner accounts.

## 6. Current browser application behaviour

- Email/password sign-in only; no public sign-up.
- Password recovery and invitation password setup.
- Active owner membership lookup through `admin_api.business_memberships`.
- Tenant-scoped business, category, listing and private Promotions views.
- Business profile and brand-colour editing.
- New categories and listings are created as drafts.
- Category/listing removal uses archive status; private Promotions can be deleted.
- Promotions are never rendered on the public storefront.
- No logo/image upload yet; Storage bucket and object policies are a later security task.
- No live storefront sync yet; the existing public site continues to use its current static build data.
- Only a Supabase publishable key is included in browser code. It is not a secret; RLS and database grants enforce access.

## 7. Go-live blockers

Do not use the owner admin for real customer operations until all of the following are complete:
- Data API schema list is verified.
- Auth signup and anonymous settings are verified.
- GitHub Pages admin deployment and Supabase callback URLs are verified.
- Email invitations and recovery links are tested.
- An actual owner account is provisioned with a confirmed business membership.
- Browser-based RLS tests pass through the real Data API.
- Storage rules and public storefront integration are complete.
- Production hosting, backup and paid/free-plan suitability have been separately reviewed and approved.
