-- Phase 2E post-migration structural verification.
-- Read-only: safe to run after the reviewed migration has been applied.
-- This does not replace REST/RLS role simulation or Android browser testing.

with expected_tables(schema_name, table_name) as (
  values
    ('app_private','store_profile'),
    ('app_private','store_admins'),
    ('app_private','categories'),
    ('app_private','listings'),
    ('app_private','promotions'),
    ('app_private','store_settings')
),
expected_views(schema_name, view_name) as (
  values
    ('public','storefront_profile'),
    ('public','storefront_categories'),
    ('public','storefront_listings'),
    ('admin_api','store_profile'),
    ('admin_api','categories'),
    ('admin_api','listings'),
    ('admin_api','promotions')
),
expected_rls(schema_name, table_name) as (
  values
    ('app_private','store_profile'),
    ('app_private','store_admins'),
    ('app_private','categories'),
    ('app_private','listings'),
    ('app_private','promotions'),
    ('app_private','store_settings')
),
checks as (
  select
    not exists (
      select 1 from expected_tables e
      where to_regclass(format('%I.%I', e.schema_name, e.table_name)) is null
    ) as all_expected_tables_exist,
    not exists (
      select 1 from expected_views e
      where to_regclass(format('%I.%I', e.schema_name, e.view_name)) is null
    ) as all_expected_views_exist,
    not exists (
      select 1 from expected_rls e
      join pg_class c on c.oid = to_regclass(format('%I.%I', e.schema_name, e.table_name))
      where not c.relrowsecurity
    ) as rls_enabled_on_every_base_table,
    not exists (
      select 1
      from expected_views e
      join pg_class c on c.oid = to_regclass(format('%I.%I', e.schema_name, e.view_name))
      where not coalesce(c.reloptions @> array['security_invoker=true'], false)
    ) as every_api_view_is_security_invoker,
    to_regclass('public.storefront_promotions') is null as no_public_promotions_view,
    to_regclass('admin_api.promotions') is not null as admin_promotions_view_exists,
    not has_table_privilege('anon', 'app_private.legacy_businesses', 'SELECT')
      and not has_table_privilege('authenticated', 'app_private.legacy_businesses', 'SELECT')
      and not has_table_privilege('anon', 'app_private.legacy_categories', 'SELECT')
      and not has_table_privilege('authenticated', 'app_private.legacy_categories', 'SELECT')
      as legacy_tables_not_client_readable,
    not has_table_privilege('anon', 'app_private.store_admins', 'SELECT')
      and not has_table_privilege('authenticated', 'app_private.store_admins', 'SELECT')
      as membership_table_not_client_readable,
    not has_table_privilege('anon', 'app_private.store_settings', 'SELECT')
      and not has_table_privilege('authenticated', 'app_private.store_settings', 'SELECT')
      as settings_table_not_client_readable,
    not has_function_privilege('anon', 'app_private.is_active_store_admin()', 'EXECUTE')
      and has_function_privilege('authenticated', 'app_private.is_active_store_admin()', 'EXECUTE')
      as membership_helper_execute_grants_correct,
    (select count(*) <= 1 from app_private.store_profile) as singleton_row_limit_holds,
    not exists (
      select 1 from pg_policies
      where schemaname = 'app_private'
        and tablename in ('store_admins','store_settings')
    ) as no_client_policies_on_operator_only_tables
)
select
  checks.*,
  checks.all_expected_tables_exist
    and checks.all_expected_views_exist
    and checks.rls_enabled_on_every_base_table
    and checks.every_api_view_is_security_invoker
    and checks.no_public_promotions_view
    and checks.admin_promotions_view_exists
    and checks.legacy_tables_not_client_readable
    and checks.membership_table_not_client_readable
    and checks.settings_table_not_client_readable
    and checks.membership_helper_execute_grants_correct
    and checks.singleton_row_limit_holds
    and checks.no_client_policies_on_operator_only_tables
    as structural_checks_all_pass
from checks;
