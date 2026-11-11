# Phase 2B Auth settings readiness audit

**Project:** PNG Business Digital Starter Dev  
**Audit date:** 2026-11-11  
**Mode:** Read-only public Auth settings inspection. No settings changed and no email sent.

## Current public Auth settings response

Read from the project's public `/auth/v1/settings` endpoint using its publishable client key.

| Setting | Observed value | Assessment |
|---|---|---|
| `disable_signup` | `false` | **Not compliant** with the approved invitation-only owner model. Public Auth signups are currently enabled at the project level. |
| `external.email` | `true` | Email provider is enabled. |
| `external.anonymous_users` | `false` | Anonymous Auth sign-ins are disabled, as required. |
| `mailer_autoconfirm` | `false` | Email auto-confirmation is off; email confirmation is required. |
| `site_url` | `null` | The public settings response did not provide a configured Site URL. Confirm the dashboard value before testing links. |
| `uri_allow_list` | `null` | The public settings response did not provide an allowed redirect list. Confirm the dashboard value before testing links. |

## Required action before owner onboarding

1. Disable new user signups in Authentication → Settings / General configuration, preserving invitation-based user creation.
2. Keep anonymous sign-ins disabled and email confirmation enabled.
3. Configure the exact Site URL and narrowly scoped redirect allow-list for the selected admin host and any approved development host.
4. Test an invitation and password-recovery callback end to end before inviting a real business owner.
5. Verify that a normal public signup attempt is rejected after the setting is changed.

## Safety and limitations

- No Auth configuration was changed during this audit.
- No test user was created and no invitation or recovery email was sent.
- The available Supabase connector exposes project read operations and SQL execution, but no Auth settings update action. Do not attempt to change these settings through an improvised endpoint or by placing any secret key in browser code.
- A dashboard-level configuration change is required. The setting is a live Auth control, so it should be changed deliberately and then verified through the public settings endpoint.
- No real owner account should be provisioned until the business and owner details are confirmed and the invitation email delivery path is tested.
