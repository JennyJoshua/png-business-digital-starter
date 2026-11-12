create schema admin_api;
revoke all on schema admin_api from public, anon;
grant usage on schema admin_api to authenticated;

create view admin_api.businesses with (security_invoker = true) as
select id,business_id,slug,name,business_type,tagline,description,phone,whatsapp,email,website_url,
       address_line,town,province,country_code,logo_path,cover_image_path,brand_primary,brand_accent,
       social_links,publication_status,created_at,updated_at
from app_private.businesses;

create view admin_api.business_memberships with (security_invoker = true) as
select id,business_id,user_id,role,status,invited_by,invited_at,accepted_at,created_at
from app_private.business_memberships;

create view admin_api.categories with (security_invoker = true) as
select id,business_id,category_id,name,slug,description,sort_order,publication_status,created_at,updated_at
from app_private.categories;

create view admin_api.listings with (security_invoker = true) as
select id,business_id,listing_id,category_id,kind,name,slug,description,price,currency,price_unit,
       availability_status,publication_status,image_path,sort_order,created_at,updated_at
from app_private.listings;

create view admin_api.business_private_settings with (security_invoker = true) as
select business_id,internal_notes,operational_metadata,updated_at
from app_private.business_private_settings;

create view admin_api.promotions with (security_invoker = true) as
select id,business_id,title,internal_copy,status,starts_at,ends_at,created_at,updated_at
from app_private.promotions;

create view admin_api.asset_metadata with (security_invoker = true) as
select id,business_id,bucket_id,object_path,visibility,mime_type,byte_size,alt_text,created_by,created_at
from app_private.asset_metadata;

grant select, update on admin_api.businesses to authenticated;
grant select on admin_api.business_memberships to authenticated;
grant select, insert, update on admin_api.categories to authenticated;
grant select, insert, update on admin_api.listings to authenticated;
grant select, update on admin_api.business_private_settings to authenticated;
grant select, insert, update, delete on admin_api.promotions to authenticated;
grant select, insert, update, delete on admin_api.asset_metadata to authenticated;
