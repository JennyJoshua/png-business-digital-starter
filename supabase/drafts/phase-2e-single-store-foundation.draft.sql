-- PHASE 2E DRAFT — NOT YET A DEPLOYABLE MIGRATION
-- Target: existing PNG Business Digital Starter Dev Supabase project.
-- This file is deliberately stored outside supabase/migrations until it has
-- been generated/reviewed with the Supabase CLI and tested on a disposable DB.
--
-- Conversion is additive/reversible-first: old prototype base tables are
-- retained as legacy_* tables. No business, admin, or customer data is seeded.
-- Abort if any legacy data, Auth users, or Storage buckets exist at execution.
--
-- IMPORTANT: review every statement and the backup/recovery plan before use.

begin;

-- 0. Defensive preflight. The current live inventory was empty on 2026-11-09;
-- this assertion prevents silent loss if data has appeared since then.
do $preflight$
declare
  legacy_rows bigint;
  auth_rows bigint;
  bucket_rows bigint;
begin
  select
    (select count(*) from app_private.businesses) +
    (select count(*) from app_private.business_memberships) +
    (select count(*) from app_private.business_private_settings) +
    (select count(*) from app_private.categories) +
    (select count(*) from app_private.listings) +
    (select count(*) from app_private.promotions) +
    (select count(*) from app_private.asset_metadata)
  into legacy_rows;

  select count(*) into auth_rows from auth.users;
  select count(*) into bucket_rows from storage.buckets;

  if legacy_rows <> 0 or auth_rows <> 0 or bucket_rows <> 0 then
    raise exception
      'Phase 2E preflight failed: legacy rows %, Auth users %, Storage buckets %. Stop and prepare a reviewed data migration.',
      legacy_rows, auth_rows, bucket_rows;
  end if;
end
$preflight$;

-- 1. Remove the old multi-tenant API views. Base tables are retained below.
drop view if exists public.storefront_businesses;
drop view if exists public.storefront_categories;
drop view if exists public.storefront_listings;
drop view if exists public.businesses;
drop view if exists public.business_memberships;
drop view if exists public.business_private_settings;
drop view if exists public.categories;
drop view if exists public.listings;
drop view if exists public.promotions;
drop view if exists public.asset_metadata;

drop view if exists admin_api.businesses;
drop view if exists admin_api.business_memberships;
drop view if exists admin_api.business_private_settings;
drop view if exists admin_api.categories;
drop view if exists admin_api.listings;
drop view if exists admin_api.promotions;
drop view if exists admin_api.asset_metadata;

-- 2. Preserve old prototype tables. Their old policies/indexes/triggers remain
-- attached to these legacy tables, but all client privileges are revoked below.
alter table app_private.businesses rename to legacy_businesses;
alter table app_private.business_memberships rename to legacy_business_memberships;
alter table app_private.business_private_settings rename to legacy_business_private_settings;
alter table app_private.categories rename to legacy_categories;
alter table app_private.listings rename to legacy_listings;
alter table app_private.promotions rename to legacy_promotions;
alter table app_private.asset_metadata rename to legacy_asset_metadata;

create schema if not exists app_private;
create schema if not exists admin_api;

revoke all on schema app_private from public, anon, authenticated;
grant usage on schema app_private to anon, authenticated;
revoke all on schema admin_api from public, anon;
grant usage on schema admin_api to authenticated;

-- 3. Shared validation and trigger functions.
create or replace function app_private.touch_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $function$
begin
  new.updated_at := pg_catalog.now();
  return new;
end;
$function$;

revoke all on function app_private.touch_updated_at() from public, anon, authenticated;

create or replace function app_private.prevent_immutable_fields()
returns trigger
language plpgsql
set search_path = ''
as $function$
declare
  field_name text;
begin
  foreach field_name in array tg_argv loop
    if (pg_catalog.to_jsonb(new) -> field_name)
       is distinct from
       (pg_catalog.to_jsonb(old) -> field_name) then
      raise exception 'Field % is immutable', field_name
        using errcode = '22000';
    end if;
  end loop;
  return new;
end;
$function$;

revoke all on function app_private.prevent_immutable_fields() from public, anon, authenticated;

create or replace function app_private.valid_social_links(p_links jsonb)
returns boolean
language sql
immutable
set search_path = ''
as $function$
  select
    pg_catalog.jsonb_typeof(p_links) = 'object'
    and not exists (
      select 1
      from pg_catalog.jsonb_each_text(p_links) as item(key, value)
      where item.key not in ('facebook', 'instagram', 'tiktok', 'youtube', 'linkedin', 'x')
         or item.value !~ '^https://[^[:space:]]+$'
    );
$function$;

revoke all on function app_private.valid_social_links(jsonb) from public, anon, authenticated;

-- 4. New single-store base tables. All remain in unexposed app_private.
create table app_private.store_profile (
  singleton_key smallint primary key default 1 check (singleton_key = 1),
  store_uid uuid not null unique default pg_catalog.gen_random_uuid(),
  name text not null check (pg_catalog.char_length(name) between 1 and 120),
  slug text not null unique check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
  business_type text not null check (business_type in
    ('hardware_supplier', 'general_retail', 'service_provider', 'other')),
  tagline text,
  description text,
  phone text,
  whatsapp text,
  public_email text,
  website_url text check (website_url is null or website_url ~ '^https://[^[:space:]]+$'),
  address_line text,
  town text,
  province text,
  country_code char(2) not null default 'PG' check (country_code ~ '^[A-Z]{2}$'),
  logo_url text check (logo_url is null or logo_url ~ '^https://[^[:space:]]+$'),
  cover_image_url text check (cover_image_url is null or cover_image_url ~ '^https://[^[:space:]]+$'),
  brand_primary text check (brand_primary is null or brand_primary ~ '^#[0-9A-Fa-f]{6}$'),
  brand_accent text check (brand_accent is null or brand_accent ~ '^#[0-9A-Fa-f]{6}$'),
  social_links jsonb not null default '{}'::jsonb
    check (app_private.valid_social_links(social_links)),
  publication_status text not null default 'draft'
    check (publication_status in ('draft', 'published', 'suspended')),
  created_at timestamptz not null default pg_catalog.now(),
  updated_at timestamptz not null default pg_catalog.now()
);

create table app_private.store_admins (
  user_id uuid primary key references auth.users(id) on delete restrict,
  status text not null default 'invited' check (status in ('invited', 'active', 'revoked')),
  invited_by uuid references auth.users(id) on delete set null,
  invited_at timestamptz not null default pg_catalog.now(),
  activated_at timestamptz,
  revoked_at timestamptz,
  created_at timestamptz not null default pg_catalog.now(),
  updated_at timestamptz not null default pg_catalog.now(),
  check (status <> 'active' or activated_at is not null),
  check (status <> 'revoked' or revoked_at is not null)
);
create index store_admins_status_idx on app_private.store_admins(status);

create table app_private.categories (
  id uuid primary key default pg_catalog.gen_random_uuid(),
  category_uid uuid not null unique default pg_catalog.gen_random_uuid(),
  name text not null check (pg_catalog.char_length(name) between 1 and 80),
  slug text not null unique check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
  description text,
  sort_order integer not null default 0,
  publication_status text not null default 'draft'
    check (publication_status in ('draft', 'published', 'archived')),
  image_url text check (image_url is null or image_url ~ '^https://[^[:space:]]+$'),
  created_at timestamptz not null default pg_catalog.now(),
  updated_at timestamptz not null default pg_catalog.now()
);
create index categories_status_order_idx
  on app_private.categories(publication_status, sort_order);

create table app_private.listings (
  id uuid primary key default pg_catalog.gen_random_uuid(),
  listing_uid uuid not null unique default pg_catalog.gen_random_uuid(),
  category_id uuid references app_private.categories(id) on delete restrict,
  kind text not null check (kind in ('product', 'service')),
  name text not null check (pg_catalog.char_length(name) between 1 and 160),
  slug text not null unique check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
  description text,
  reference_code text,
  price numeric(12,2) check (price is null or price >= 0),
  currency char(3) not null default 'PGK' check (currency ~ '^[A-Z]{3}$'),
  price_unit text,
  availability_note text,
  publication_status text not null default 'draft'
    check (publication_status in ('draft', 'published', 'archived')),
  image_url text check (image_url is null or image_url ~ '^https://[^[:space:]]+$'),
  sort_order integer not null default 0,
  created_at timestamptz not null default pg_catalog.now(),
  updated_at timestamptz not null default pg_catalog.now()
);
create index listings_status_order_idx
  on app_private.listings(publication_status, sort_order);
create index listings_category_status_idx
  on app_private.listings(category_id, publication_status);

create table app_private.promotions (
  id uuid primary key default pg_catalog.gen_random_uuid(),
  promotion_uid uuid not null unique default pg_catalog.gen_random_uuid(),
  title text not null check (pg_catalog.char_length(title) between 1 and 120),
  internal_copy text,
  status text not null default 'draft' check (status in ('draft', 'active', 'archived')),
  starts_at timestamptz,
  ends_at timestamptz,
  created_at timestamptz not null default pg_catalog.now(),
  updated_at timestamptz not null default pg_catalog.now(),
  check (ends_at is null or starts_at is null or ends_at > starts_at)
);
create index promotions_status_idx on app_private.promotions(status);

create table app_private.store_settings (
  setting_key text primary key check (pg_catalog.char_length(setting_key) between 1 and 100),
  setting_value jsonb not null,
  created_at timestamptz not null default pg_catalog.now(),
  updated_at timestamptz not null default pg_catalog.now()
);

-- 5. Immutable portable identities and server-maintained timestamps.
create trigger store_profile_identity_immutable
before update of singleton_key, store_uid on app_private.store_profile
for each row execute function app_private.prevent_immutable_fields('singleton_key', 'store_uid');
create trigger categories_uid_immutable
before update of category_uid on app_private.categories
for each row execute function app_private.prevent_immutable_fields('category_uid');
create trigger listings_uid_immutable
before update of listing_uid on app_private.listings
for each row execute function app_private.prevent_immutable_fields('listing_uid');
create trigger promotions_uid_immutable
before update of promotion_uid on app_private.promotions
for each row execute function app_private.prevent_immutable_fields('promotion_uid');

create trigger store_profile_touch_updated_at before update on app_private.store_profile
for each row execute function app_private.touch_updated_at();
create trigger store_admins_touch_updated_at before update on app_private.store_admins
for each row execute function app_private.touch_updated_at();
create trigger categories_touch_updated_at before update on app_private.categories
for each row execute function app_private.touch_updated_at();
create trigger listings_touch_updated_at before update on app_private.listings
for each row execute function app_private.touch_updated_at();
create trigger promotions_touch_updated_at before update on app_private.promotions
for each row execute function app_private.touch_updated_at();
create trigger store_settings_touch_updated_at before update on app_private.store_settings
for each row execute function app_private.touch_updated_at();

-- 6. Current database membership is checked for each admin request.
create or replace function app_private.is_active_store_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $function$
  select exists (
    select 1
    from app_private.store_admins as membership
    where membership.user_id = (select auth.uid())
      and membership.status = 'active'
  );
$function$;

revoke all on function app_private.is_active_store_admin() from public, anon;
grant execute on function app_private.is_active_store_admin() to authenticated;

-- 7. RLS on every new base table. No client DELETE or membership/settings
-- policies are created. Operator/service-role provisioning bypasses RLS.
alter table app_private.store_profile enable row level security;
alter table app_private.store_admins enable row level security;
alter table app_private.categories enable row level security;
alter table app_private.listings enable row level security;
alter table app_private.promotions enable row level security;
alter table app_private.store_settings enable row level security;

create policy store_profile_public_read
on app_private.store_profile for select to anon
using (publication_status = 'published');
create policy store_profile_admin_read
on app_private.store_profile for select to authenticated
using ((select app_private.is_active_store_admin()));
create policy store_profile_admin_update
on app_private.store_profile for update to authenticated
using ((select app_private.is_active_store_admin()))
with check ((select app_private.is_active_store_admin()));

create policy categories_public_read
on app_private.categories for select to anon
using (
  publication_status = 'published'
  and exists (
    select 1 from app_private.store_profile as profile
    where profile.singleton_key = 1 and profile.publication_status = 'published'
  )
);
create policy categories_admin_read
on app_private.categories for select to authenticated
using ((select app_private.is_active_store_admin()));
create policy categories_admin_insert
on app_private.categories for insert to authenticated
with check ((select app_private.is_active_store_admin()));
create policy categories_admin_update
on app_private.categories for update to authenticated
using ((select app_private.is_active_store_admin()))
with check ((select app_private.is_active_store_admin()));

create policy listings_public_read
on app_private.listings for select to anon
using (
  publication_status = 'published'
  and exists (
    select 1 from app_private.store_profile as profile
    where profile.singleton_key = 1 and profile.publication_status = 'published'
  )
  and (
    category_id is null
    or exists (
      select 1 from app_private.categories as category
      where category.id = listings.category_id
        and category.publication_status = 'published'
    )
  )
);
create policy listings_admin_read
on app_private.listings for select to authenticated
using ((select app_private.is_active_store_admin()));
create policy listings_admin_insert
on app_private.listings for insert to authenticated
with check ((select app_private.is_active_store_admin()));
create policy listings_admin_update
on app_private.listings for update to authenticated
using ((select app_private.is_active_store_admin()))
with check ((select app_private.is_active_store_admin()));

create policy promotions_admin_read
on app_private.promotions for select to authenticated
using ((select app_private.is_active_store_admin()));
create policy promotions_admin_insert
on app_private.promotions for insert to authenticated
with check ((select app_private.is_active_store_admin()));
create policy promotions_admin_update
on app_private.promotions for update to authenticated
using ((select app_private.is_active_store_admin()))
with check ((select app_private.is_active_store_admin()));

-- store_admins and store_settings intentionally have RLS enabled but no
-- browser policies or browser grants.

-- 8. Remove all old browser grants, including privileges on retained legacy
-- prototype tables. Then grant only the new API's required base privileges.
revoke all on all tables in schema app_private from public, anon, authenticated;

grant select (
  singleton_key, store_uid, name, slug, business_type, tagline, description,
  phone, whatsapp, public_email, website_url, address_line, town, province,
  country_code, logo_url, cover_image_url, brand_primary, brand_accent,
  social_links, publication_status
) on app_private.store_profile to anon;

grant select (
  singleton_key, store_uid, name, slug, business_type, tagline, description,
  phone, whatsapp, public_email, website_url, address_line, town, province,
  country_code, logo_url, cover_image_url, brand_primary, brand_accent,
  social_links, publication_status, created_at, updated_at
) on app_private.store_profile to authenticated;
grant update (
  name, slug, business_type, tagline, description, phone, whatsapp,
  public_email, website_url, address_line, town, province, country_code,
  logo_url, cover_image_url, brand_primary, brand_accent, social_links,
  publication_status
) on app_private.store_profile to authenticated;


grant select (id, publication_status) on app_private.categories to anon;
grant select (
  id, category_uid, name, slug, description, sort_order, publication_status, image_url
) on app_private.categories to anon;
grant select (
  id, category_uid, name, slug, description, sort_order, publication_status,
  image_url, created_at, updated_at
) on app_private.categories to authenticated;
grant insert (name, slug, description, sort_order, publication_status, image_url)
on app_private.categories to authenticated;
grant update (name, slug, description, sort_order, publication_status, image_url)
on app_private.categories to authenticated;

grant select (id, publication_status, category_id) on app_private.listings to anon;
grant select (
  id, listing_uid, category_id, kind, name, slug, description, price, currency,
  price_unit, availability_note, publication_status, image_url, sort_order
) on app_private.listings to anon;
grant select (
  id, listing_uid, category_id, kind, name, slug, description, reference_code,
  price, currency, price_unit, availability_note, publication_status, image_url,
  sort_order, created_at, updated_at
) on app_private.listings to authenticated;
grant insert (
  category_id, kind, name, slug, description, reference_code, price, currency,
  price_unit, availability_note, publication_status, image_url, sort_order
) on app_private.listings to authenticated;
grant update (
  category_id, kind, name, slug, description, reference_code, price, currency,
  price_unit, availability_note, publication_status, image_url, sort_order
) on app_private.listings to authenticated;

grant select (
  id, promotion_uid, title, internal_copy, status, starts_at, ends_at,
  created_at, updated_at
) on app_private.promotions to authenticated;
grant insert (title, internal_copy, status, starts_at, ends_at)
on app_private.promotions to authenticated;
grant update (title, internal_copy, status, starts_at, ends_at)
on app_private.promotions to authenticated;

-- 9. Explicit public and admin API views. Promotions exist only in admin_api.
create or replace view public.storefront_profile
with (security_invoker = true)
as
select
  store_uid, name, slug, business_type, tagline, description, phone, whatsapp,
  public_email, website_url, address_line, town, province, country_code,
  logo_url, cover_image_url, brand_primary, brand_accent, social_links
from app_private.store_profile
where singleton_key = 1 and publication_status = 'published';

create or replace view public.storefront_categories
with (security_invoker = true)
as
select category_uid, name, slug, description, sort_order, image_url
from app_private.categories
where publication_status = 'published'
  and exists (
    select 1 from app_private.store_profile as profile
    where profile.singleton_key = 1 and profile.publication_status = 'published'
  );

create or replace view public.storefront_listings
with (security_invoker = true)
as
select
  listing.listing_uid,
  category.category_uid,
  listing.kind,
  listing.name,
  listing.slug,
  listing.description,
  listing.price,
  listing.currency,
  listing.price_unit,
  listing.availability_note,
  listing.image_url,
  listing.sort_order
from app_private.listings as listing
left join app_private.categories as category
  on category.id = listing.category_id
where listing.publication_status = 'published'
  and exists (
    select 1 from app_private.store_profile as profile
    where profile.singleton_key = 1 and profile.publication_status = 'published'
  )
  and (
    listing.category_id is null
    or category.publication_status = 'published'
  );

create or replace view admin_api.store_profile
with (security_invoker = true)
as
select
  singleton_key, store_uid, name, slug, business_type, tagline, description,
  phone, whatsapp, public_email, website_url, address_line, town, province,
  country_code, logo_url, cover_image_url, brand_primary, brand_accent,
  social_links, publication_status, created_at, updated_at
from app_private.store_profile;

create or replace view admin_api.categories
with (security_invoker = true)
as
select
  id, category_uid, name, slug, description, sort_order, publication_status,
  image_url, created_at, updated_at
from app_private.categories;

create or replace view admin_api.listings
with (security_invoker = true)
as
select
  id, listing_uid, category_id, kind, name, slug, description, reference_code,
  price, currency, price_unit, availability_note, publication_status, image_url,
  sort_order, created_at, updated_at
from app_private.listings;

create or replace view admin_api.promotions
with (security_invoker = true)
as
select
  id, promotion_uid, title, internal_copy, status, starts_at, ends_at,
  created_at, updated_at
from app_private.promotions;

revoke all on public.storefront_profile, public.storefront_categories, public.storefront_listings
from public, anon, authenticated;
grant select on public.storefront_profile, public.storefront_categories, public.storefront_listings
to anon, authenticated;

revoke all on admin_api.store_profile, admin_api.categories, admin_api.listings, admin_api.promotions
from public, anon, authenticated;
grant select on admin_api.store_profile, admin_api.categories, admin_api.listings, admin_api.promotions
to authenticated;
grant update (
  name, slug, business_type, tagline, description, phone, whatsapp,
  public_email, website_url, address_line, town, province, country_code,
  logo_url, cover_image_url, brand_primary, brand_accent, social_links,
  publication_status
) on admin_api.store_profile to authenticated;
grant insert, update on admin_api.categories to authenticated;
grant insert, update on admin_api.listings to authenticated;
grant insert, update on admin_api.promotions to authenticated;

-- 10. Legacy tables remain inaccessible to browser roles because the schema-wide
-- revocation above ran before the new-table grants. No additional grants follow.
grant select (
  singleton_key, store_uid, name, slug, business_type, tagline, description,
  phone, whatsapp, public_email, website_url, address_line, town, province,
  country_code, logo_url, cover_image_url, brand_primary, brand_accent,
  social_links, publication_status
) on app_private.store_profile to anon;
grant select (
  singleton_key, store_uid, name, slug, business_type, tagline, description,
  phone, whatsapp, public_email, website_url, address_line, town, province,
  country_code, logo_url, cover_image_url, brand_primary, brand_accent,
  social_links, publication_status, created_at, updated_at
) on app_private.store_profile to authenticated;
grant update (
  name, slug, business_type, tagline, description, phone, whatsapp,
  public_email, website_url, address_line, town, province, country_code,
  logo_url, cover_image_url, brand_primary, brand_accent, social_links,
  publication_status
) on app_private.store_profile to authenticated;
grant select (id, publication_status) on app_private.store_profile to anon;
grant select (id, publication_status) on app_private.categories to anon;
grant select (id, category_uid, name, slug, description, sort_order, publication_status, image_url)
on app_private.categories to anon;
grant select (id, category_uid, name, slug, description, sort_order, publication_status, image_url, created_at, updated_at)
on app_private.categories to authenticated;
grant insert (name, slug, description, sort_order, publication_status, image_url)
on app_private.categories to authenticated;
grant update (name, slug, description, sort_order, publication_status, image_url)
on app_private.categories to authenticated;
grant select (id, publication_status, category_id) on app_private.listings to anon;
grant select (id, listing_uid, category_id, kind, name, slug, description, price, currency, price_unit, availability_note, publication_status, image_url, sort_order)
on app_private.listings to anon;
grant select (id, listing_uid, category_id, kind, name, slug, description, reference_code, price, currency, price_unit, availability_note, publication_status, image_url, sort_order, created_at, updated_at)
on app_private.listings to authenticated;
grant insert (category_id, kind, name, slug, description, reference_code, price, currency, price_unit, availability_note, publication_status, image_url, sort_order)
on app_private.listings to authenticated;
grant update (category_id, kind, name, slug, description, reference_code, price, currency, price_unit, availability_note, publication_status, image_url, sort_order)
on app_private.listings to authenticated;
grant select (id, promotion_uid, title, internal_copy, status, starts_at, ends_at, created_at, updated_at)
on app_private.promotions to authenticated;
grant insert (title, internal_copy, status, starts_at, ends_at) on app_private.promotions to authenticated;
grant update (title, internal_copy, status, starts_at, ends_at) on app_private.promotions to authenticated;

commit;
