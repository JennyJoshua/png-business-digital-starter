# Phase 2B security remediation migration

## Status

Prepared on `phase-2b/security-remediation` for review. This migration has **not** been applied to the hosted PNG Business Digital Starter Dev Supabase project.

## Changes proposed

1. Add a partial unique index on `app_private.business_memberships(business_id)` for rows where `role = 'owner'` and `status = 'active'`, enforcing the approved one-active-owner-per-business rule.
2. Include a preflight guard that raises an explicit exception if duplicate active owners exist. It does not modify or delete membership records.
3. Revoke all privileges from `PUBLIC`, `anon` and `authenticated` on the three public storefront views, then grant `SELECT` only to `anon` and `authenticated`.
4. Revoke broad default table privileges for `PUBLIC`, `anon` and `authenticated` from future tables created in `public` by `postgres` or `supabase_admin`. Future API exposure must grant only the privileges required.

## Read-only preflight performed on 2026-11-11

- Confirmed the target project is the existing active `PNG Business Digital Starter Dev` project.
- Confirmed `business_memberships` has `business_id`, `role`, and `status` columns.
- Queried for duplicate active owners grouped by `business_id`; none were returned.
- Queried membership role/status distribution; no membership rows were returned.
- Confirmed all three public storefront views currently grant broad privileges to `anon` and `authenticated`; the migration also revokes any inherited `PUBLIC` privileges.
- Confirmed default table ACLs for both `postgres` and `supabase_admin` currently include broad privileges for `anon` and `authenticated`; the migration also revokes `PUBLIC` defaults.
- Confirmed the views are based on published storefront records and the prior audit found `security_invoker = true`.

## Important deployment notes

- The partial unique index is intentionally scoped to active owner rows only. Pending/inactive memberships are not constrained by it.
- The migration fails rather than resolving duplicate owners automatically.
- Tightening default privileges means future public tables will not be automatically usable through the Data API by `anon` or `authenticated`; developers must explicitly grant the minimum needed access and enable RLS for exposed tables.
- The `public` view grants do not replace the underlying base-table grants or RLS policies required by `security_invoker = true` views.
- A disposable PostgreSQL 17 CI test simulates broad `PUBLIC`, `anon` and `authenticated` grants, applies the migration, and checks the one-owner index, read-only view grants and future-table defaults.
- Apply only after branch review and explicit owner authorization. Then verify view privileges, default privileges, index definition, Supabase advisors, and actual anonymous/authenticated API behavior.
