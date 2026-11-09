# Phase 2B — Owner Authentication Setup and Safety Gates

**Project:** PNG Business Digital Starter Dev  
**Project ref:** `rwcwvqlgyckfdrglsbfg`  
**Dashboard:** https://supabase.com/dashboard/project/rwcwvqlgyckfdrglsbfg  
**Status:** Application code is prepared. User confirmed the Data API schema list was saved; Auth configuration, URL configuration, invitation delivery and first real owner provisioning remain outstanding.

## 1. Data API schema exposure

Open [Project Settings → Data API](https://supabase.com/dashboard/project/rwcwvqlgyckfdrglsbfg/integrations/data_api/settings).

The browser admin calls the schema explicitly with `supabase.schema('admin_api')`. Configure the exposed schema list to include:
- `public` — required for the public storefront views.
- `admin_api` — required for authenticated owner-admin views.

**Do not expose `app_private`.** It contains the underlying application tables. The owner API views in `admin_api` use `security_invoker = true`; their underlying table privileges and RLS remain in force.

The user has confirmed saving this configuration. Before connecting the browser app, verify the exposed-schema list and test actual REST requests. Do not expose other schemas merely to make an API error disappear.

## 2. Auth general settings

In the Supabase dashboard, open Authentication → Settings / General configuration and verify:

| Setting | Required value | Reason |
|---|---|---|
| Allow new user signups | **Off** | No public self-registration for business owners |
| Allow anonymous sign-ins | **Off** | No anonymous Auth sessions |
| Email provider | On | Owner email/password login |
| Confirm email | On | Verify invited owner email before sign-in |

The admin app intentionally has no registration form or `signUp()` call. An owner must already have been invited and have an active database membership.

Supabase reference: [General Auth configuration](https://supabase.com/docs/guides/auth/general-configuration).

## 3. URL configuration

The owner app is served from the `/admin/` path of the selected storefront host. Before using email invitation or password recovery links:
- Set the Supabase Site URL to the intended admin host.
- Add the exact admin URL and local development URL to the allowed redirect URL list.
- Do not add broad wildcard domains unless there is a documented need.
- Test the redirect on the real target host before inviting a business owner.

No branch preview or production admin URL is assumed by this document. The current branch is not automatically deployed by the existing GitHub Pages workflow.

## 4. Invitation email delivery

Inviting a user is an administrator action and must be done from the Supabase dashboard or a trusted server using the secret key. Never put a secret/service-role key in the browser.

Before any external business owner is invited, test whether the project's configured email provider can deliver to an address that is not an organization member. Supabase's default email provider has historically restricted delivery to organization members; if the Free project's default SMTP cannot deliver to the intended recipient, stop and bring the options back for approval. Do not silently configure a paid SMTP service or add a paid service.

Reference: [Supabase Auth users and invitations](https://supabase.com/docs/guides/auth/users).

## 5. First-owner provisioning sequence

No real owner account or business record has been created yet. When the user approves the actual business details and owner email, use this controlled sequence:

1. Verify the saved Data API exposure through actual REST requests and verify Auth settings above.
2. Verify invitation email delivery to the intended recipient.
3. Send the owner invitation from Authentication → Users.
4. Retrieve the invited Auth user's UUID from the dashboard.
5. Insert the business record and its active `owner` membership using a reviewed, one-time SQL statement in the Supabase SQL Editor. The membership is what grants business access; Auth account creation alone grants no business data access.
6. Test sign-in, password setup, owner-only view access, cross-tenant denial and sign-out.
7. Do not put a business's real customer data into the Free development project.

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
- Email invitations and recovery links are tested.
- An actual owner account is provisioned with a confirmed business membership.
- Browser-based RLS tests pass through the real Data API.
- Storage rules and public storefront integration are complete.
- Production hosting, backup and paid/free-plan suitability have been separately reviewed and approved.
