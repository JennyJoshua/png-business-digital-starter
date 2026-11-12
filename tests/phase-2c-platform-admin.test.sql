-- Phase 2C integration tests. Run after Phase 2B publication and security tests
-- in the same disposable PostgreSQL 17 database as a superuser.

\set ON_ERROR_STOP on
\ir ../supabase/migrations/20261112140000_phase_2c_platform_admin_console.sql

insert into auth.users(id) values
 ('00000000-0000-4000-8000-000000000003');

-- The allowlist is provisioned only by trusted database administration.
insert into app_private.platform_admins(user_id,granted_by,note)
values ('00000000-0000-4000-8000-000000000003',
        '00000000-0000-4000-8000-000000000001',
        'Disposable integration-test administrator');

do $$
begin
  if has_table_privilege('anon','app_private.platform_admins','SELECT')
     or has_table_privilege('authenticated','app_private.platform_admins','SELECT')
     or has_table_privilege('anon','app_private.publication_audit_events','SELECT')
     or has_table_privilege('authenticated','app_private.publication_audit_events','SELECT') then
    raise exception 'private administrator or audit tables are directly readable';
  end if;
  if has_function_privilege('anon','admin_api.platform_admin_queue()','EXECUTE')
     or has_function_privilege('anon','admin_api.set_publication_status(text,uuid,text,text)','EXECUTE') then
    raise exception 'anonymous users can invoke platform-admin RPCs';
  end if;
  if not (select prosecdef from pg_proc where oid='app_private.set_publication_status(text,uuid,text,text)'::regprocedure)
     or (select prosecdef from pg_proc where oid='admin_api.set_publication_status(text,uuid,text,text)'::regprocedure) then
    raise exception 'publication function security boundary is incorrect';
  end if;
end;
$$;

-- Ordinary owner cannot read the queue or publish through direct RPC calls.
set role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000001',false);
do $$
declare target_id uuid;
begin
  begin
    perform admin_api.platform_admin_queue();
    raise exception 'owner read the platform-admin queue';
  exception when insufficient_privilege then null;
  end;
  select id into target_id from app_private.businesses where business_id='test-business-b';
  begin
    perform admin_api.set_publication_status('business',target_id,'published','owner attempt');
    raise exception 'owner published another business';
  exception when insufficient_privilege then null;
  end;
end;
$$;
reset role;

-- Resolve fixture UUIDs as the database test operator, before switching to the API role.
select set_config('test.phase2c.business_id',
  (select id::text from app_private.businesses where business_id='test-business-b'),false);
select set_config('test.phase2c.category_id',
  (select id::text from app_private.categories
   where business_id=(select id from app_private.businesses where business_id='test-business-b')
     and category_id='seed-category'),false);
select set_config('test.phase2c.listing_id',
  (select id::text from app_private.listings
   where business_id=(select id from app_private.businesses where business_id='test-business-b')
     and listing_id='seed-listing'),false);
update app_private.listings
set category_id=current_setting('test.phase2c.category_id')::uuid
where id=current_setting('test.phase2c.listing_id')::uuid;

-- Allowlisted platform administrator can review and publish across tenants.
set role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000003',false);
do $$
declare
  business_id_value uuid;
  category_id_value uuid;
  listing_id_value uuid;
  queue jsonb;
begin
  queue := admin_api.platform_admin_queue();
  if jsonb_typeof(queue) <> 'array' or jsonb_array_length(queue) < 5 then
    raise exception 'platform administrator queue did not return expected records';
  end if;

  business_id_value := current_setting('test.phase2c.business_id')::uuid;
  category_id_value := current_setting('test.phase2c.category_id')::uuid;
  listing_id_value := current_setting('test.phase2c.listing_id')::uuid;

  perform admin_api.set_publication_status('business',business_id_value,'published','Business details reviewed');
  begin
    perform admin_api.set_publication_status('listing',listing_id_value,'published','Premature publication attempt');
    raise exception 'listing was published while its category remained draft';
  exception when check_violation then null;
  end;
  perform admin_api.set_publication_status('category',category_id_value,'published','Category reviewed');
  perform admin_api.set_publication_status('listing',listing_id_value,'published','Listing reviewed');

  if (select publication_status from app_private.businesses where id=business_id_value) <> 'published'
     or (select publication_status from app_private.categories where id=category_id_value) <> 'published'
     or (select publication_status from app_private.listings where id=listing_id_value) <> 'published' then
    raise exception 'platform administrator publication failed';
  end if;

  perform admin_api.set_publication_status('listing',listing_id_value,'draft','Needs more information');
  if (select publication_status from app_private.listings where id=listing_id_value) <> 'draft' then
    raise exception 'platform administrator unpublish failed';
  end if;
end;
$$;
reset role;

do $$
begin
  if (select count(*) from app_private.publication_audit_events
      where actor_user_id='00000000-0000-4000-8000-000000000003') <> 4 then
    raise exception 'publication audit log did not record all four decisions';
  end if;
  if exists(select 1 from app_private.publication_audit_events
            where actor_user_id <> '00000000-0000-4000-8000-000000000003') then
    raise exception 'publication audit actor is incorrect';
  end if;
end;
$$;

set role anon;
do $$
begin
  if (select count(*) from public.storefront_businesses) <> 2 then
    raise exception 'public storefront does not show the two published businesses';
  end if;
  if exists(select 1 from public.storefront_listings where listing_id='seed-listing' and business_id='test-business-b') then
    raise exception 'unpublished listing is visible on the public storefront';
  end if;
end;
$$;
reset role;

\echo 'PASS: platform-admin allowlist, owner denial, publication RPCs, audit trail and public visibility'
