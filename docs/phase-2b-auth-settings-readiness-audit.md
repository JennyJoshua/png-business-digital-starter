# Phase 2B Auth settings readiness audit

**Project:** PNG Business Digital Starter Dev  
**Audit date:** 2026-11-11  
**Mode:** Read-only public Auth settings inspection. No settings changed by this audit and no email sent.

## Current public Auth settings response

The user turned off **Allow new user signups** in the Supabase dashboard. I independently re-queried the project's public `/auth/v1/settings` endpoint using its publishable client key after the change.

| Setting | Verified value | Assessment |
|---|---|---|
| `disable_signup` | `true` | **Pass** — public signups are disabled, consistent with invitation-only owner accounts. |
| `external.email` | `true` | Pass — email provider is enabled. |
| `external.anonymous_users` | `false` | Pass — anonymous Auth sign-ins are disabled. |
| `mailer_autoconfirm` | `false` | Pass — email auto-confirmation is off; confirmation is required. |
| `site_url` | `null` | Not confirmed — set/verify the exact Site URL in the dashboard. |
| `uri_allow_list` | `null` | Not confirmed — set/verify the exact allowed redirect URL list in the dashboard. |

## Remaining actions before owner onboarding

1. Confirm the exact host that will serve the owner-admin app under `/admin/`.
2. Set the Supabase Site URL to the selected host and add only the exact admin callback URL plus any approved development callback URL to the redirect allow-list. Avoid broad wildcards.
3. Test the invitation and password-recovery callbacks end to end.
4. Test invitation email delivery to a non-organization address before any external business owner is invited. If the default SMTP restriction blocks it, stop and bring options back for approval; do not configure a paid SMTP service without approval.
5. Only after those tests, consider a real owner invitation and provision the membership after the business and owner details are confirmed.

## Safety and limitations

- No Auth configuration was changed by this audit; the user made the signup change in the dashboard.
- No test user was created and no invitation or recovery email was sent.
- The connected Supabase tools do not provide an Auth-settings update action. The dashboard is the control surface for Site URL and redirect allow-list configuration.
- No real owner account should be provisioned until the business and owner details are confirmed and the invitation email delivery path is tested.
