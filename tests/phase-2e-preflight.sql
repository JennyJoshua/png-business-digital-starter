-- Phase 2E read-only preflight for the existing development project.
-- Safe to run before conversion. This script performs SELECTs only.
-- Stop and prepare a data-mapping/backup plan if any legacy row count is non-zero.

with legacy_counts as (
  select 'businesses'::text as table_name, count(*)::bigint as row_count from app_private.businesses
  union all
  select 'business_memberships', count(*) from app_private.business_memberships
  union all
  select 'business_private_settings', count(*) from app_private.business_private_settings
  union all
  select 'categories', count(*) from app_private.categories
  union all
  select 'listings', count(*) from app_private.listings
  union all
  select 'promotions', count(*) from app_private.promotions
  union all
  select 'asset_metadata', count(*) from app_private.asset_metadata
)
select
  current_database() as database_name,
  current_setting('server_version') as postgres_version,
  (select count(*) from auth.users) as auth_user_count,
  (select count(*) from storage.buckets) as storage_bucket_count,
  coalesce(
    (select jsonb_agg(jsonb_build_object('table', table_name, 'rows', row_count)
                      order by table_name)
     from legacy_counts),
    '[]'::jsonb
  ) as legacy_table_counts,
  not exists (select 1 from legacy_counts where row_count > 0) as legacy_data_empty;
