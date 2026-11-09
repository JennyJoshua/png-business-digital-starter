grant select (id) on app_private.businesses to anon;
create index business_memberships_invited_by_idx on app_private.business_memberships(invited_by);
create index asset_metadata_created_by_idx on app_private.asset_metadata(created_by);
