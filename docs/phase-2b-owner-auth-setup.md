# Phase 2B — Auth Setup and Operator Provisioning

**Target architecture:** one independent Supabase project per store.  
**Responsibility:** the platform operator provisions and maintains each project; store administrators manage business content only.

## 1. Important: current prototype is not ready for owner setup

The current working branch contains an earlier shared multi-tenant implementation. Its `admin_api` schema and tenant-membership flow do not yet represent the approved single-store architecture. Do not invite a real store owner, create a customer business record or configure a production host using that prototype.

The existing development project (`rwcwvqlgyckfdrglsbfg`) is retained for review only. Do not delete, reset or destructively migrate it as part of this documentation change.

## 2. Per-instance project setup (target procedure)

For each new business instance, the platform operator will:
1. Create a separate Supabase project under the operator's account.
2. Record the business instance, GitHub repository, hosting site, Supabase project reference and region in an operator-controlled register.
3. Apply the reviewed, version-controlled single-store baseline migrations.
4. Configure Data API exposure and least-privilege grants for that instance.
5. Configure Auth and URL settings for the exact deployed admin host.
6. Provision the one store profile and initial administrator through a trusted operator-only procedure.
7. Test public REST access, admin access, multiple-admin behaviour and denial cases before launch.

Each project must contain one store only. Never point two business apps at the same customer database.

## 3. Auth policy

The intended v1 model is invitation/operator-provisioned administrators, not public self-registration. Verify the following settings in each instance's Supabase dashboard before launch:

| Setting | Required direction |
|---|---|
| Allow new user signups | Off unless a later approved invitation flow demonstrably requires a different secure configuration |
| Allow anonymous sign-ins | Off |
| Email provider | On if email/password authentication is used |
| Confirm email | On where supported by the selected sign-in and invitation flow |

The app must not contain a public admin registration route. A logged-in user is not automatically an administrator: the database must verify an active store-admin membership.

## 4. URL and email delivery

For each independent app:
- Set Site URL to the actual admin host.
- Add only the exact required redirect URLs, including the admin path and a controlled local-development URL if needed.
- Test invitation and password-recovery redirects on the real host before inviting the business administrator.
- Verify email delivery to an external recipient before relying on the default provider.
- If the free/default email provider cannot deliver, stop and present alternatives. Do not silently add a paid SMTP service.

Never use a broad wildcard redirect allowlist without a documented security reason.

## 5. Operator-controlled administrator provisioning

The platform operator creates or invites the Auth user and grants membership to the one store through a reviewed trusted process. Store administrators must not be able to add themselves, promote themselves, or grant access to others from the browser client.

Multiple administrators are supported for the same store. The implementation must define and test:
- How an additional administrator is invited and verified.
- How membership is activated, suspended and revoked.
- Whether administrators have identical permissions in v1.
- How existing sessions/tokens behave after revocation.
- How the operator recovers access if all store administrators lose access.

Do not place a service-role/secret key in HTML, JavaScript, static assets, source maps or customer configuration. Privileged provisioning must run only in a trusted operator-controlled environment or dashboard workflow.

## 6. Responsibility boundary

Store administrators may manage permitted business content: store profile, brand identity, logo/assets, contact details, categories, products/services, catalogue descriptions and approved promotions. They do not manage database schema, migrations, backups, project billing, project settings or privileged credentials.

The platform operator maintains the database and technical infrastructure. Do not ask store administrators to run SQL or maintain Supabase.

## 7. Go-live checklist

Do not onboard a real business until:
- The instance has its own Supabase project and repository/deployment association is recorded.
- The single-store baseline migrations have been applied and version recorded.
- RLS, grants and public/admin API behaviour have passed real REST tests.
- Initial and additional administrator workflows have passed browser tests.
- Invitation and recovery email delivery work for the intended recipients.
- Store admins cannot access database infrastructure or privileged keys.
- Public storefront integration and Storage policies are verified.
- Backup/restore and operator maintenance procedures are documented and tested.
- The business owner has approved the content and launch.
- The platform operator has explicitly approved deployment.

No real owner account, invitation, customer data or production deployment is authorised by this documentation alone.
