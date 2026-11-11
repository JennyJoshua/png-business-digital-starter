-- Allow anonymous visitors to read only the published storefront records.
-- The underlying app_private tables remain outside the exposed Data API schema.
-- These grants are constrained by the existing *_public_read RLS policies:
-- businesses: publication_status = 'published'
-- categories/listings: own status is published AND parent business is published.
grant select on table
  app_private.businesses,
  app_private.categories,
  app_private.listings
to anon;

-- Public-facing views are already explicitly granted to anon in the prior
-- storefront migration. Keep this migration narrowly scoped to base-table
-- privileges required by security_invoker=true views.
