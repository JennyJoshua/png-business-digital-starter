-- Disposable PostgreSQL 17 integration test for Phase 2B security remediation.
-- Run with psql against an empty database as a superuser.

\set ON_ERROR_STOP on

create role anon nologin;
create role authenticated nologin;
create role supabase_admin nologin;

create schema auth;
create table auth.users (id uuid primary key);
create or replace function auth.uid()
returns uuid
language sql stable
as $$
  select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid;
$$;
grant usage on schema auth to anon, authenticated;
grant execute on function auth.uid() to anon, authenticated;

-- Simulate the broad default privileges this migration is designed to remove.
alter default privileges for role postgres in schema public
  grant all privileges on tables to anon, authenticated;
alter default privileges for role supabase_admin in schema public
  grant all privileges on tables to anon, authenticated;
grant create on schema public to supabase_admin;

\ir ../supabase/migrations/20261109000651_phase_2b_owner_admin_core.sql
\ir ../supabase/migrations/20261109001259_phase_2b_admin_api_views.sql

insert into auth.users(id) values
 ('00000000-0000-4000-8000-000000000001'),
 ('00000000-0000-4000-8000-000000000002');
insert into app_private.businesses(business_id,slug,name)
values ('test-business-a','test-business-a','Test Business A');
insert into app_private.business_memberships(business_id,user_id,role,status)
select b.id,u.id,'owner','active'
from app_private.businesses b
cross join auth.users u
where b.business_id='test-business-a'
  and u.id='00000000-0000-4000-8000-000000000001';

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
