# Phase 2B publication authority

**Decision owner:** Project owner  
**Decision date:** 2026-11-11  
**Decision:** Option B — platform administrator only

## Policy

Only a platform administrator may publish a business, category, product or service listing to the public storefront.

Business owners may:
- Edit their business profile and branding fields.
- Create categories and listings; new records receive the database default status `draft`.
- Edit the content and commercial fields of their own categories/listings.
- Archive their own categories/listings through the dedicated owner archive functions.

Business owners may not:
- Set a business, category or listing to `published`.
- Change an archived category/listing back to another status.
- Use direct Data API requests to bypass the owner-admin interface and change publication status.

## Enforcement

The migration `20261111120000_phase_2b_platform_publication_controls.sql`:
- Revokes owner-role column privileges to insert or update `publication_status` on businesses, categories and listings.
- Restricts the exposed `admin_api` view grants to editable non-publication columns.
- Adds `app_private.archive_category(uuid)` and `app_private.archive_listing(uuid)` SECURITY DEFINER implementations in the unexposed schema. Each independently checks `auth.uid()` and the caller's active owner membership for the exact record before setting status to `archived`. Exposed `admin_api` RPCs are SECURITY INVOKER wrappers only.
- Grants execution of the private implementations and the invoker wrappers to authenticated users only; anonymous callers cannot execute them. The privileged implementation remains outside the exposed Data API schema and does not grant publication authority.

The owner-admin UI no longer sends a publication status on insert and calls the dedicated archive functions. There is no owner-facing publish button.

## Platform publication workflow

A platform-admin approval/review interface is not part of the current owner-admin foundation. Until that workflow is built and separately reviewed, platform administrators must perform publication through a controlled privileged process. Never place a service-role key in browser code or grant owners publication privileges as a workaround.

## Verification and rollout

- Automated source-level regression assertions cover the migration grants, archive functions and owner UI calls.
- The migration is committed to the Phase 2B branch but has **not** been applied to the hosted Supabase database.
- Hosted migration application remains an explicit approval gate.
- Before rollout, test on a disposable PostgreSQL database that owners can create/edit drafts and archive only their own records, cannot insert/update publication status, and cannot archive another tenant's records.
