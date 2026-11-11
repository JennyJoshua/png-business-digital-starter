-- Disposable PostgreSQL 17 integration test for platform-only publication.
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

\ir ../supabase/migrations/20261109000651_phase_2b_owner_admin_core.sql
\ir ../supabase/migrations/20261109001259_phase_2b_admin_api_views.sql

-- Two tenants and two distinct owners.
insert into auth.users(id) values
 ('00000000-0000-4000-8000-000000000001'),
 ('00000000-0000-4000-8000-000000000002');

insert into app_private.businesses(business_id,slug,name)
values ('test-business-a','test-business-a','Test Business A'),
       ('test-business-b','test-business-b','Test Business B');

insert into app_private.business_memberships(business_id,user_id,role,status)
select b.id, u.id, 'owner', 'active'
from app_private.businesses b
join auth.users u on (b.business_id='test-business-a' and u.id='00000000-0000-4000-8000-000000000001')
                 or (b.business_id='test-business-b' and u.id='00000000-0000-4000-8000-000000000002');

insert into app_private.categories(business_id,category_id,name,slug)
select id, 'seed-category', 'Seed Category', 'seed-category'
from app_private.businesses where business_id in ('test-business-a','test-business-b');

insert into app_private.listings(business_id,listing_id,kind,name,slug)
select id, 'seed-listing', 'product', 'Seed Listing', 'seed-listing'
from app_private.businesses where business_id in ('test-business-a','test-business-b');

\ir ../supabase/migrations/20261111120000_phase_2b_platform_publication_controls.sql

-- Privilege metadata checks: owner can edit content but cannot set publication state.
do $$
begin
  if has_column_privilege('authenticated','app_private.businesses','publication_status','UPDATE') then
    raise exception 'owner unexpectedly has base business publication UPDATE';
  end if;
  if has_column_privilege('authenticated','admin_api.businesses','publication_status','UPDATE') then
    raise exception 'owner unexpectedly has view business publication UPDATE';
  end if;
  if not has_column_privilege('authenticated','admin_api.businesses','name','UPDATE') then
    raise exception 'owner lost business name UPDATE';
  end if;
  if has_column_privilege('authenticated','app_private.categories','publication_status','INSERT')
     or has_column_privilege('authenticated','app_private.categories','publication_status','UPDATE')
     or has_column_privilege('authenticated','admin_api.categories','publication_status','INSERT')
     or has_column_privilege('authenticated','admin_api.categories','publication_status','UPDATE') then
    raise exception 'owner unexpectedly has category publication privileges';
  end if;
  if has_column_privilege('authenticated','app_private.listings','publication_status','INSERT')
     or has_column_privilege('authenticated','app_private.listings','publication_status','UPDATE')
     or has_column_privilege('authenticated','admin_api.listings','publication_status','INSERT')
     or has_column_privilege('authenticated','admin_api.listings','publication_status','UPDATE') then
    raise exception 'owner unexpectedly has listing publication privileges';
  end if;
  if not has_column_privilege('authenticated','admin_api.categories','name','INSERT')
     or not has_column_privilege('authenticated','admin_api.categories','name','UPDATE')
     or not has_column_privilege('authenticated','admin_api.listings','name','INSERT')
     or not has_column_privilege('authenticated','admin_api.listings','name','UPDATE') then
    raise exception 'owner lost ordinary category/listing content privileges';
  end if;
  if has_function_privilege('anon','admin_api.archive_category(uuid)','EXECUTE')
     or has_function_privilege('anon','admin_api.archive_listing(uuid)','EXECUTE') then
    raise exception 'anon unexpectedly can execute owner archive functions';
  end if;
  if not has_function_privilege('authenticated','admin_api.archive_category(uuid)','EXECUTE')
     or not has_function_privilege('authenticated','admin_api.archive_listing(uuid)','EXECUTE') then
    raise exception 'authenticated role cannot execute owner archive functions';
  end if;
end;
$$;

-- As owner A, create/edit drafts and archive only own tenant records.
set role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-4000-8000-000000000001',false);

do $$
declare
  biz_a uuid;
  category_a uuid;
  listing_a uuid;
  category_b uuid;
  listing_b uuid;
  status_value text;
begin
  select id into biz_a from admin_api.businesses where business_id='test-business-a';
  if biz_a is null then raise exception 'owner A cannot read own business'; end if;
  if exists(select 1 from admin_api.businesses where business_id='test-business-b') then
    raise exception 'owner A can read another tenant business';
  end if;

  insert into admin_api.categories(business_id,category_id,name,slug)
  values (biz_a,'owner-created-category','Owner Category','owner-category')
  returning id into category_a;
  select publication_status into status_value from app_private.categories where id=category_a;
  if status_value <> 'draft' then raise exception 'new owner category is not draft'; end if;

  update admin_api.categories set name='Owner Category Updated' where id=category_a;
  if not found then raise exception 'owner cannot update own category'; end if;

  begin
    insert into admin_api.categories(business_id,category_id,name,slug,publication_status)
    values (biz_a,'forbidden-category','Forbidden','forbidden-category','published');
    raise exception 'owner inserted a published category';
  exception when insufficient_privilege then null;
  end;

  begin
    update admin_api.categories set publication_status='published' where id=category_a;
    raise exception 'owner published a category';
  exception when insufficient_privilege then null;
  end;

  insert into admin_api.listings(business_id,listing_id,kind,name,slug)
  values (biz_a,'owner-created-listing','service','Owner Listing','owner-listing')
  returning id into listing_a;
  select publication_status into status_value from app_private.listings where id=listing_a;
  if status_value <> 'draft' then raise exception 'new owner listing is not draft'; end if;
  update admin_api.listings set name='Owner Listing Updated' where id=listing_a;
  if not found then raise exception 'owner cannot update own listing'; end if;

  begin
    insert into admin_api.listings(business_id,listing_id,kind,name,slug,publication_status)
    values (biz_a,'forbidden-listing','product','Forbidden','forbidden-listing','published');
    raise exception 'owner inserted a published listing';
  exception when insufficient_privilege then null;
  end;

  begin
    update admin_api.listings set publication_status='published' where id=listing_a;
    raise exception 'owner published a listing';
  exception when insufficient_privilege then null;
  end;

  begin
    update admin_api.businesses set publication_status='published' where id=biz_a;
    raise exception 'owner published a business';
  exception when insufficient_privilege then null;
  end;

  perform admin_api.archive_category(category_a);
  select publication_status into status_value from app_private.categories where id=category_a;
  if status_value <> 'archived' then raise exception 'owner archive category failed'; end if;

  perform admin_api.archive_listing(listing_a);
  select publication_status into status_value from app_private.listings where id=listing_a;
  if status_value <> 'archived' then raise exception 'owner archive listing failed'; end if;

  select c.id into category_b
  from app_private.categories c join app_private.businesses b on b.id=c.business_id
  where b.business_id='test-business-b' and c.category_id='seed-category';
  select l.id into listing_b
  from app_private.listings l join app_private.businesses b on b.id=l.business_id
  where b.business_id='test-business-b' and l.listing_id='seed-listing';

  begin
    perform admin_api.archive_category(category_b);
    raise exception 'owner A archived owner B category';
  exception when insufficient_privilege then null;
  end;
  begin
    perform admin_api.archive_listing(listing_b);
    raise exception 'owner A archived owner B listing';
  exception when insufficient_privilege then null;
  end;
end;
$$;

reset role;

-- Confirm cross-tenant records were not modified and all denied actions left no published data.
do $$
begin
  if (select c.publication_status from app_private.categories c join app_private.businesses b on b.id=c.business_id
      where b.business_id='test-business-b' and c.category_id='seed-category') <> 'draft' then
    raise exception 'cross-tenant category was changed';
  end if;
  if (select l.publication_status from app_private.listings l join app_private.businesses b on b.id=l.business_id
      where b.business_id='test-business-b' and l.listing_id='seed-listing') <> 'draft' then
    raise exception 'cross-tenant listing was changed';
  end if;
  if exists(select 1 from app_private.businesses where publication_status='published')
     or exists(select 1 from app_private.categories where publication_status='published')
     or exists(select 1 from app_private.listings where publication_status='published') then
    raise exception 'owner created a published record';
  end if;
end;
$$;

\echo 'PASS: platform-only publication controls and tenant-scoped owner archiving'
