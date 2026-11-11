# Phase 2B API exposure and anonymous REST audit

**Project:** PNG Business Digital Starter Dev  
**Audit date:** 2026-11-11  
**Mode:** Read-only; no database or Auth settings changed.

## Exposed Data API schemas

The anonymous PostgREST API returned the following schema list when probing an unexposed schema:

- `public`
- `graphql_public`
- `admin_api`

The response explicitly rejected `app_private` with `PGRST106` and identified the three schemas above as exposed. This confirms the intended separation: `app_private` is not exposed, while `admin_api` is exposed for owner-admin operations.

## Anonymous REST checks

Using the project's publishable client key, without an owner JWT:

| Request | HTTP result | Finding |
|---|---:|---|
| `GET public.storefront_businesses?select=*&limit=1` | 200 | Public read endpoint responds; result was an empty array |
| `GET public.storefront_categories?select=*&limit=1` | 200 | Public read endpoint responds; result was an empty array |
| `GET public.storefront_listings?select=*&limit=1` | 200 | Public read endpoint responds; result was an empty array |
| `GET admin_api.businesses?select=business_id&limit=1` | 401 | Anonymous caller is denied with SQLSTATE `42501`: permission denied for schema `admin_api` |
| `GET app_private.businesses?select=business_id&limit=1` | 406 | Rejected with `PGRST106`: `app_private` is not an exposed schema |

No business rows or private records were returned or inspected.

## Interpretation

- Anonymous public storefront reads are reachable and currently return no published rows.
- The owner-admin schema is exposed at the API layer, but anonymous callers do not have schema access.
- The private data schema is not exposed.
- The database audit separately found that the three public views have excessive object-level DML grants for `anon` and `authenticated`. These grants should be reduced to `SELECT` only by the pending PR #9 migration. The successful anonymous GET checks do not establish that writes are possible; underlying base-table grants and RLS remain additional controls. No write request was sent.
- The REST API root/OpenAPI discovery endpoint returned HTTP 401 when called with a publishable key because that endpoint requires a secret API key. No secret key was retrieved or used.

## Still required

- An authenticated owner JWT test is not yet possible: no real owner account has been provisioned, and no invitation/recovery email flow has been validated.
- Do not create a real owner account or send an invitation until the Auth configuration and test-user approach have been reviewed.
- After a test owner is explicitly provisioned, verify that the owner can access only their own business through `admin_api`, cannot access another tenant, and can perform only the intended owner operations.
- Repeat anonymous REST checks after PR #9 is approved and its migration is applied to the Dev database.
