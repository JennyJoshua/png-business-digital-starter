# Supabase Free Project Rotation Runbook

**Purpose:** Make room for development work on another Supabase Free Plan project without deleting an existing project or exceeding the two-active-project quota.

## Rules confirmed against current Supabase documentation

- The Free Plan permits **two active projects** across all organizations where the account is an Owner or Administrator.
- Paused projects do not count toward the two-active-project quota.
- A paused Free Plan project can be restored through the dashboard for **90 days** after it was paused.
- After that 90-day window, one-click restoration is no longer available. Download the available database backup and Storage objects, then restore them to a new project or locally.
- Pausing makes the project's database and APIs unavailable. Applications that depend on it will stop working until restoration completes.
- Pausing does not create an independent backup. Free Plan projects do not include automatic backups.

Official references:
- [About billing on Supabase](https://supabase.com/docs/guides/platform/billing-on-supabase)
- [Project pausing and restoration](https://supabase.com/docs/guides/platform/free-project-pausing)

## Safe rotation procedure

1. List all projects and identify which two are active.
2. Check which application, preview, test, or production service depends on each project.
3. Select only a project whose downtime is acceptable. Never pause a live customer-facing service just to free a slot without an explicit downtime decision.
4. Before pausing, create and verify independent backups of the database and any Storage objects that matter.
5. Pause the selected project in Supabase Dashboard → Project Settings → General → Project availability.
6. Confirm it is paused before creating or restoring another project.
7. When finished with the temporary project, pause it and restore the earlier project.
8. Verify database connectivity, Auth, Storage and the dependent application after restoration.
9. Track the 90-day restore deadline for every paused project. Do not leave important projects paused near or beyond that deadline.

## Project-specific policy for PNG Business Digital Starter

- Keep its schema, migration files, RLS policies and automated tests in GitHub.
- Do not apply migrations to a live Supabase project until the target project has been explicitly selected and the migration has been reviewed.
- Prefer a separate Digital Starter backend project rather than sharing the PNG Materials Marketplace database.
- Use one shared multi-tenant Digital Starter backend for its customer storefronts; do not create one Supabase project per storefront.
- Activate the Digital Starter project only when there is a safe active-project slot. Do not assume either existing project can be paused; check its service dependencies first.
- No project has been paused, restored, created or modified by this runbook.
