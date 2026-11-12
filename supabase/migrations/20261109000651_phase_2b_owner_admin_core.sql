create schema if not exists app_private;
revoke all on schema app_private from public;
grant usage on schema app_private to anon, authenticated;

create table app_private.businesses (
  id uuid primary key default gen_random_uuid(),
  business_id text not null unique check (business_id ~ '^[a-z0-9][a-z0-9_-]{1,79}$'),
  slug text not null unique check (slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'),
  name text not null check (char_length(name) between 1 and 120),
  business_type text not null default 'other' check (business_type in ('hardware_supplier','general_retail','service_provider','other')),
  tagline text, description text, phone text, whatsapp text, email text, website_url text,
  address_line text, town text, province text,
  country_code char(2) not null default 'PG' check (country_code ~ '^[A-Z]{2}$'),
  logo_path text, cover_image_path text, brand_primary text, brand_accent text,
  social_links jsonb not null default '{}'::jsonb check (jsonb_typeof(social_links) = 'object'),
  publication_status text not null default 'draft' check (publication_status in ('draft','published','suspended')),
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);

create table app_private.business_memberships (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references app_private.businesses(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null default 'owner' check (role = 'owner'),
  status text not null default 'active' check (status in ('invited','active','suspended')),
  invited_by uuid references auth.users(id) on delete set null,
  invited_at timestamptz, accepted_at timestamptz,
  created_at timestamptz not null default now(),
  unique (business_id, user_id)
);
create index business_memberships_user_business_idx
  on app_private.business_memberships(user_id, business_id) where status = 'active';

create table app_private.categories (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references app_private.businesses(id) on delete cascade,
  category_id text not null check (category_id ~ '^[a-z0-9][a-z0-9_-]{0,79}$'),
  name text not null check (char_length(name) between 1 and 80),
  slug text not null check (slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'),
  description text, sort_order integer not null default 0,
  publication_status text not null default 'draft' check (publication_status in ('draft','published','archived')),
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  unique (business_id, category_id), unique (business_id, slug), unique (business_id, id)
);
create index categories_business_status_idx
  on app_private.categories(business_id, publication_status, sort_order);

create table app_private.listings (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references app_private.businesses(id) on delete cascade,
  listing_id text not null check (listing_id ~ '^[a-z0-9][a-z0-9_-]{0,79}$'),
  category_id uuid,
  kind text not null check (kind in ('product','service')),
  name text not null check (char_length(name) between 1 and 160),
  slug text not null check (slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'),
  description text, price numeric(12,2) check (price is null or price >= 0),
  currency char(3) not null default 'PGK' check (currency ~ '^[A-Z]{3}$'),
  price_unit text, availability_status text,
  publication_status text not null default 'draft' check (publication_status in ('draft','published','archived')),
  image_path text, sort_order integer not null default 0,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  unique (business_id, listing_id), unique (business_id, slug),
  constraint listings_category_same_business_fk
    foreign key (business_id, category_id)
    references app_private.categories(business_id, id)
    on delete set null (category_id)
);
create index listings_business_status_idx
  on app_private.listings(business_id, publication_status, sort_order);
create index listings_business_category_idx
  on app_private.listings(business_id, category_id);

create table app_private.business_private_settings (
  business_id uuid primary key references app_private.businesses(id) on delete cascade,
  internal_notes text,
  operational_metadata jsonb not null default '{}'::jsonb check (jsonb_typeof(operational_metadata) = 'object'),
  updated_at timestamptz not null default now()
);

create table app_private.promotions (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references app_private.businesses(id) on delete cascade,
  title text not null check (char_length(title) between 1 and 120),
  internal_copy text,
  status text not null default 'draft' check (status in ('draft','active','archived')),
  starts_at timestamptz, ends_at timestamptz,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  check (ends_at is null or starts_at is null or ends_at > starts_at)
);
create index promotions_business_status_idx on app_private.promotions(business_id, status);

create table app_private.asset_metadata (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references app_private.businesses(id) on delete cascade,
  bucket_id text not null, object_path text not null,
  visibility text not null default 'private' check (visibility in ('private','public')),
  mime_type text not null, byte_size bigint check (byte_size is null or byte_size >= 0),
  alt_text text, created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(), unique (bucket_id, object_path)
);
create index asset_metadata_business_idx on app_private.asset_metadata(business_id);

create or replace function app_private.set_updated_at()
returns trigger language plpgsql set search_path = ''
as $$
begin
  new.updated_at = pg_catalog.now();
  return new;
end;
$$;
revoke all on function app_private.set_updated_at() from public, anon, authenticated;

create trigger businesses_set_updated_at before update on app_private.businesses
for each row execute function app_private.set_updated_at();
create trigger categories_set_updated_at before update on app_private.categories
for each row execute function app_private.set_updated_at();
create trigger listings_set_updated_at before update on app_private.listings
for each row execute function app_private.set_updated_at();
create trigger business_private_settings_set_updated_at before update on app_private.business_private_settings
for each row execute function app_private.set_updated_at();
create trigger promotions_set_updated_at before update on app_private.promotions
for each row execute function app_private.set_updated_at();

alter table app_private.businesses enable row level security;
alter table app_private.business_memberships enable row level security;
alter table app_private.categories enable row level security;
alter table app_private.listings enable row level security;
alter table app_private.business_private_settings enable row level security;
alter table app_private.promotions enable row level security;
alter table app_private.asset_metadata enable row level security;

create policy memberships_select_self on app_private.business_memberships for select to authenticated
using (user_id = (select auth.uid()) and status = 'active');

create policy businesses_public_read on app_private.businesses for select to anon
using (publication_status = 'published');
create policy businesses_owner_read on app_private.businesses for select to authenticated
using (exists (select 1 from app_private.business_memberships m
  where m.business_id = businesses.id and m.user_id = (select auth.uid()) and m.status = 'active'));
create policy businesses_owner_update on app_private.businesses for update to authenticated
using (exists (select 1 from app_private.business_memberships m
  where m.business_id = businesses.id and m.user_id = (select auth.uid()) and m.status = 'active' and m.role = 'owner'))
with check (exists (select 1 from app_private.business_memberships m
  where m.business_id = businesses.id and m.user_id = (select auth.uid()) and m.status = 'active' and m.role = 'owner'));

create policy categories_public_read on app_private.categories for select to anon
using (publication_status = 'published' and exists (
  select 1 from app_private.businesses b where b.id = categories.business_id and b.publication_status = 'published'));
create policy categories_owner_read on app_private.categories for select to authenticated
using (exists (select 1 from app_private.business_memberships m
  where m.business_id = categories.business_id and m.user_id = (select auth.uid()) and m.status = 'active'));
create policy categories_owner_insert on app_private.categories for insert to authenticated
with check (exists (select 1 from app_private.business_memberships m
  where m.business_id = categories.business_id and m.user_id = (select auth.uid()) and m.status = 'active' and m.role = 'owner'));
create policy categories_owner_update on app_private.categories for update to authenticated
using (exists (select 1 from app_private.business_memberships m
  where m.business_id = categories.business_id and m.user_id = (select auth.uid()) and m.status = 'active' and m.role = 'owner'))
with check (exists (select 1 from app_private.business_memberships m
  where m.business_id = categories.business_id and m.user_id = (select auth.uid()) and m.status = 'active' and m.role = 'owner'));

create policy listings_public_read on app_private.listings for select to anon
using (publication_status = 'published' and exists (
  select 1 from app_private.businesses b where b.id = listings.business_id and b.publication_status = 'published'));
create policy listings_owner_read on app_private.listings for select to authenticated
using (exists (select 1 from app_private.business_memberships m
  where m.business_id = listings.business_id and m.user_id = (select auth.uid()) and m.status = 'active'));
create policy listings_owner_insert on app_private.listings for insert to authenticated
with check (exists (select 1 from app_private.business_memberships m
  where m.business_id = listings.business_id and m.user_id = (select auth.uid()) and m.status = 'active' and m.role = 'owner'));
create policy listings_owner_update on app_private.listings for update to authenticated
using (exists (select 1 from app_private.business_memberships m
  where m.business_id = listings.business_id and m.user_id = (select auth.uid()) and m.status = 'active' and m.role = 'owner'))
with check (exists (select 1 from app_private.business_memberships m
  where m.business_id = listings.business_id and m.user_id = (select auth.uid()) and m.status = 'active' and m.role = 'owner'));

create policy private_settings_owner_read on app_private.business_private_settings for select to authenticated
using (exists (select 1 from app_private.business_memberships m
  where m.business_id = business_private_settings.business_id and m.user_id = (select auth.uid()) and m.status = 'active'));
create policy private_settings_owner_update on app_private.business_private_settings for update to authenticated
using (exists (select 1 from app_private.business_memberships m
  where m.business_id = business_private_settings.business_id and m.user_id = (select auth.uid()) and m.status = 'active' and m.role = 'owner'))
with check (exists (select 1 from app_private.business_memberships m
  where m.business_id = business_private_settings.business_id and m.user_id = (select auth.uid()) and m.status = 'active' and m.role = 'owner'));

create policy promotions_owner_read on app_private.promotions for select to authenticated
using (exists (select 1 from app_private.business_memberships m
  where m.business_id = promotions.business_id and m.user_id = (select auth.uid()) and m.status = 'active'));
create policy promotions_owner_insert on app_private.promotions for insert to authenticated
with check (exists (select 1 from app_private.business_memberships m
  where m.business_id = promotions.business_id and m.user_id = (select auth.uid()) and m.status = 'active' and m.role = 'owner'));
create policy promotions_owner_update on app_private.promotions for update to authenticated
using (exists (select 1 from app_private.business_memberships m
  where m.business_id = promotions.business_id and m.user_id = (select auth.uid()) and m.status = 'active' and m.role = 'owner'))
with check (exists (select 1 from app_private.business_memberships m
  where m.business_id = promotions.business_id and m.user_id = (select auth.uid()) and m.status = 'active' and m.role = 'owner'));
create policy promotions_owner_delete on app_private.promotions for delete to authenticated
using (exists (select 1 from app_private.business_memberships m
  where m.business_id = promotions.business_id and m.user_id = (select auth.uid()) and m.status = 'active' and m.role = 'owner'));

create policy assets_owner_read on app_private.asset_metadata for select to authenticated
using (exists (select 1 from app_private.business_memberships m
  where m.business_id = asset_metadata.business_id and m.user_id = (select auth.uid()) and m.status = 'active'));
create policy assets_owner_insert on app_private.asset_metadata for insert to authenticated
with check (created_by = (select auth.uid()) and exists (
  select 1 from app_private.business_memberships m
  where m.business_id = asset_metadata.business_id and m.user_id = (select auth.uid()) and m.status = 'active' and m.role = 'owner'));
create policy assets_owner_update on app_private.asset_metadata for update to authenticated
using (exists (select 1 from app_private.business_memberships m
  where m.business_id = asset_metadata.business_id and m.user_id = (select auth.uid()) and m.status = 'active' and m.role = 'owner'))
with check (exists (select 1 from app_private.business_memberships m
  where m.business_id = asset_metadata.business_id and m.user_id = (select auth.uid()) and m.status = 'active' and m.role = 'owner'));
create policy assets_owner_delete on app_private.asset_metadata for delete to authenticated
using (exists (select 1 from app_private.business_memberships m
  where m.business_id = asset_metadata.business_id and m.user_id = (select auth.uid()) and m.status = 'active' and m.role = 'owner'));

revoke all on all tables in schema app_private from public, anon, authenticated;
grant select on app_private.businesses to authenticated;
grant update (slug,name,business_type,tagline,description,phone,whatsapp,email,website_url,address_line,town,province,country_code,logo_path,cover_image_path,brand_primary,brand_accent,social_links,publication_status)
on app_private.businesses to authenticated;
grant select on app_private.business_memberships to authenticated;
grant select on app_private.categories to authenticated;
grant insert (business_id,category_id,name,slug,description,sort_order,publication_status) on app_private.categories to authenticated;
grant update (name,slug,description,sort_order,publication_status) on app_private.categories to authenticated;
grant select on app_private.listings to authenticated;
grant insert (business_id,listing_id,category_id,kind,name,slug,description,price,currency,price_unit,availability_status,publication_status,image_path,sort_order)
on app_private.listings to authenticated;
grant update (category_id,kind,name,slug,description,price,currency,price_unit,availability_status,publication_status,image_path,sort_order)
on app_private.listings to authenticated;
grant select on app_private.business_private_settings to authenticated;
grant update (internal_notes,operational_metadata) on app_private.business_private_settings to authenticated;
grant select on app_private.promotions to authenticated;
grant insert (business_id,title,internal_copy,status,starts_at,ends_at) on app_private.promotions to authenticated;
grant update (title,internal_copy,status,starts_at,ends_at) on app_private.promotions to authenticated;
grant delete on app_private.promotions to authenticated;
grant select on app_private.asset_metadata to authenticated;
grant insert (business_id,bucket_id,object_path,visibility,mime_type,byte_size,alt_text,created_by) on app_private.asset_metadata to authenticated;
grant update (visibility,mime_type,byte_size,alt_text) on app_private.asset_metadata to authenticated;
grant delete on app_private.asset_metadata to authenticated;

-- RLS policies for public categories/listings use businesses.id to verify that
-- the parent business is published. app_private remains unexposed through the Data API.
grant select (id) on app_private.businesses to anon;
grant select (business_id,slug,name,business_type,tagline,description,phone,whatsapp,email,website_url,address_line,town,province,country_code,logo_path,cover_image_path,brand_primary,brand_accent,social_links,publication_status)
on app_private.businesses to anon;
grant select (id,business_id,category_id,name,slug,description,sort_order,publication_status)
on app_private.categories to anon;
grant select (id,business_id,listing_id,category_id,kind,name,slug,description,price,currency,price_unit,availability_status,publication_status,image_path,sort_order)
on app_private.listings to anon;

create view public.storefront_businesses with (security_invoker = true) as
select business_id,slug,name,business_type,tagline,description,phone,whatsapp,email,website_url,address_line,town,province,country_code,logo_path,cover_image_path,brand_primary,brand_accent,social_links
from app_private.businesses where publication_status = 'published';

create view public.storefront_categories with (security_invoker = true) as
select c.category_id,b.business_id,c.name,c.slug,c.description,c.sort_order
from app_private.categories c join app_private.businesses b on b.id=c.business_id
where c.publication_status='published' and b.publication_status='published';

create view public.storefront_listings with (security_invoker = true) as
select l.listing_id,b.business_id,c.category_id,l.kind,l.name,l.slug,l.description,l.price,l.currency,l.price_unit,l.availability_status,l.image_path,l.sort_order
from app_private.listings l join app_private.businesses b on b.id=l.business_id
left join app_private.categories c on c.id=l.category_id
where l.publication_status='published' and b.publication_status='published';

grant select on public.storefront_businesses,public.storefront_categories,public.storefront_listings to anon,authenticated;
