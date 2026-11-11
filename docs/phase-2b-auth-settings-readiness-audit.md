# Phase 2B Auth settings readiness audit

**Project:** PNG Business Digital Starter Dev  
**Audit date:** 2026-11-11  
**Mode:** Read-only settings review. No settings changed by this audit and no email sent.

## Current Auth settings

The user previously disabled **Allow new user signups** in the Supabase dashboard. A fresh public Auth settings check independently confirmed:

| Setting | Verified value | Assessment |
|---|---|---|
| `disable_signup` | `true` | **Pass** — public signups are disabled, consistent with invitation-only owner accounts. |
| `external.email` | `true` | Pass — email provider is enabled. |
| `external.anonymous_users` | `false` | Pass — anonymous Auth sign-ins are disabled. |
| `mailer_autoconfirm` | `false` | Pass — email auto-confirmation is off; confirmation is required. |

### Site URL and redirect URL — user-confirmed

On 2026-11-11, the user opened the Supabase Authentication → URL Configuration dashboard and explicitly confirmed that both displayed values match:

| Setting | User-confirmed value | Evidence status |
|---|---|---|
| Site URL | `https://jennyjoshua.github.io/png-business-digital-starter/` | **User-confirmed in dashboard; not independently re-read by the connected verification path.** |
| Redirect URL allow-list | `https://jennyjoshua.github.io/png-business-digital-starter/admin/` | **User-confirmed in dashboard; not independently re-read by the connected verification path.** |

The public `/auth/v1/settings` response previously returned `site_url: null` and `uri_allow_list: null`. That response is not being treated as evidence that the dashboard values are blank; the dashboard confirmation is recorded separately and accurately.

## Remaining actions before owner onboarding

1. Test invitation and password-recovery callbacks end to end against the published `/admin/` path. The admin page is not yet deployed; PR #8 must be reviewed and merged and the Pages deployment must succeed before this test.
2. Test invitation email delivery to a non-organization address before any external business owner is invited. If default SMTP restrictions block it, stop and bring options back for approval; do not configure a paid SMTP service without approval.
3. Only after those tests, consider a real owner invitation and provision the membership after the business and owner details are confirmed.

## Safety and limitations

- The user changed the dashboard URL settings; this audit did not change them.
- No test user was created and no invitation or recovery email was sent.
- No real owner account should be provisioned until the callback and email-delivery paths are tested and the business and owner details are confirmed.
- Do not treat user-confirmed dashboard values as an independent machine verification.
