-- Continues tests/phase-2b-publication-controls.test.sql in the same disposable
-- PostgreSQL database. Roles, auth fixtures, schema and two tenant fixtures exist.

\set ON_ERROR_STOP on

-- Simulate broad per-schema defaults so the migration must actively revoke them.
alter default privileges for role postgres in schema public
  grant all privileges on tables to anon, authenticated;
alter default privileges for role supabase_admin in schema public
  grant all privileges on tables to anon, authenticated;
grant create on schema public to supabase_admin;

\ir ../supabase/migrations/20261111065208_phase_2b_owner_and_public_view_privilege_hardening.sql

-- One-active-owner constraint rejects a second active owner for the same business.
do $$
begin
  begin
    insert into app_private.business_memberships(business_id,user_id,role,status)
    select b.id,'00000000-0000-4000-8000-000000000002'::uuid,'owner','active'
    from app_private.businesses b where b.business_id='test-business-a';
    raise exception 'second active owner was accepted';
  exception when unique_violation then null;
  end;
end;
$$;

-- Existing public views are read-only for both public API roles.
do $$
declare
  view_name text;
begin
  foreach view_name in array array['storefront_businesses','storefront_categories','storefront_listings'] loop
    if not has_table_privilege('anon','public.'||view_name,'SELECT')
       or not has_table_privilege('authenticated','public.'||view_name,'SELECT') then
      raise exception 'SELECT missing on public.%', view_name;
    end if;
    if has_table_privilege('anon','public.'||view_name,'INSERT')
       or has_table_privilege('anon','public.'||view_name,'UPDATE')
       or has_table_privilege('anon','public.'||view_name,'DELETE')
       or has_table_privilege('authenticated','public.'||view_name,'INSERT')
       or has_table_privilege('authenticated','public.'||view_name,'UPDATE')
       or has_table_privilege('authenticated','public.'||view_name,'DELETE') then
      raise exception 'public.% is not read-only', view_name;
    end if;
  end loop;
end;
$$;

-- The migration removes inherited broad defaults for both migration owners.
create table public.future_table_postgres(id integer);
set role supabase_admin;
create table public.future_table_supabase_admin(id integer);
reset role;

do $$
declare
  table_name text;
begin
  foreach table_name in array array['future_table_postgres','future_table_supabase_admin'] loop
    if has_table_privilege('anon','public.'||table_name,'SELECT')
       or has_table_privilege('anon','public.'||table_name,'INSERT')
       or has_table_privilege('anon','public.'||table_name,'UPDATE')
       or has_table_privilege('anon','public.'||table_name,'DELETE')
       or has_table_privilege('authenticated','public.'||table_name,'SELECT')
       or has_table_privilege('authenticated','public.'||table_name,'INSERT')
       or has_table_privilege('authenticated','public.'||table_name,'UPDATE')
       or has_table_privilege('authenticated','public.'||table_name,'DELETE') then
      raise exception 'future public table % inherited API privileges', table_name;
    end if;
  end loop;
end;
$$;

set role anon;
select count(*) from public.storefront_businesses;
select count(*) from public.storefront_categories;
select count(*) from public.storefront_listings;
reset role;

\echo 'PASS: one-active-owner index, read-only public views, and least-privilege future defaults'
