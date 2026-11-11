-- Owners may prepare draft businesses/listings, but only platform administrators
-- may change publication_status to published. Owner archive operations are kept
-- in app_private (not Data API exposed) and exposed through SECURITY INVOKER RPCs.

-- Business publication is platform-controlled.
revoke update (publication_status) on app_private.businesses from authenticated;
revoke update on admin_api.businesses from authenticated;
grant update (slug,name,business_type,tagline,description,phone,whatsapp,email,website_url,
  address_line,town,province,country_code,logo_path,cover_image_path,brand_primary,brand_accent,social_links)
on admin_api.businesses to authenticated;

-- Categories: owners can create and edit content, but cannot set publication status.
revoke insert (publication_status), update (publication_status)
on app_private.categories from authenticated;
revoke insert, update on admin_api.categories from authenticated;
grant insert (business_id,category_id,name,slug,description,sort_order)
on admin_api.categories to authenticated;
grant update (name,slug,description,sort_order)
on admin_api.categories to authenticated;

-- Listings (products and services): owners can create and edit drafts, but cannot publish.
revoke insert (publication_status), update (publication_status)
on app_private.listings from authenticated;
revoke insert, update on admin_api.listings from authenticated;
grant insert (business_id,listing_id,category_id,kind,name,slug,description,price,currency,
  price_unit,availability_status,image_path,sort_order)
on admin_api.listings to authenticated;
grant update (category_id,kind,name,slug,description,price,currency,price_unit,
  availability_status,image_path,sort_order)
on admin_api.listings to authenticated;

-- Privileged implementation lives in the unexposed app_private schema.
create or replace function app_private.archive_category(p_category_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare affected integer;
begin
  if auth.uid() is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  update app_private.categories c
  set publication_status = 'archived'
  where c.id = p_category_id
    and exists (
      select 1
      from app_private.business_memberships m
      where m.business_id = c.business_id
        and m.user_id = auth.uid()
        and m.role = 'owner'
        and m.status = 'active'
    );
  get diagnostics affected = row_count;
  if affected <> 1 then
    raise exception 'Category not found or owner access denied'
      using errcode = '42501';
  end if;
end;
$$;

create or replace function app_private.archive_listing(p_listing_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare affected integer;
begin
  if auth.uid() is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;
  update app_private.listings l
  set publication_status = 'archived'
  where l.id = p_listing_id
    and exists (
      select 1
      from app_private.business_memberships m
      where m.business_id = l.business_id
        and m.user_id = auth.uid()
        and m.role = 'owner'
        and m.status = 'active'
    );
  get diagnostics affected = row_count;
  if affected <> 1 then
    raise exception 'Listing not found or owner access denied'
      using errcode = '42501';
  end if;
end;
$$;

revoke all on function app_private.archive_category(uuid) from public, anon, authenticated;
revoke all on function app_private.archive_listing(uuid) from public, anon, authenticated;
grant execute on function app_private.archive_category(uuid) to authenticated;
grant execute on function app_private.archive_listing(uuid) to authenticated;

-- Exposed RPCs are invoker-rights wrappers only; the privileged implementation
-- remains in the unexposed schema and independently validates auth.uid().
create or replace function admin_api.archive_category(p_category_id uuid)
returns void
language sql
security invoker
set search_path = ''
as $$
  select app_private.archive_category(p_category_id);
$$;

create or replace function admin_api.archive_listing(p_listing_id uuid)
returns void
language sql
security invoker
set search_path = ''
as $$
  select app_private.archive_listing(p_listing_id);
$$;

revoke all on function admin_api.archive_category(uuid) from public, anon, authenticated;
revoke all on function admin_api.archive_listing(uuid) from public, anon, authenticated;
grant execute on function admin_api.archive_category(uuid) to authenticated;
grant execute on function admin_api.archive_listing(uuid) to authenticated;
