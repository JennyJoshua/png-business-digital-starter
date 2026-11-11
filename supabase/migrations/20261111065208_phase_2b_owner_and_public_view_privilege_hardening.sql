-- Enforce the approved one-active-owner-per-business model and keep public
-- storefront API views strictly read-only.
-- This migration is intentionally prepared for review; it has NOT been applied
-- to the hosted Starter Dev database.

-- Fail with a clear message rather than silently changing existing membership
-- records if conflicting active owners are introduced before this migration runs.
DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM app_private.business_memberships
    WHERE role = 'owner'
      AND status = 'active'
    GROUP BY business_id
    HAVING count(*) > 1
  ) THEN
    RAISE EXCEPTION
      'Cannot enforce one active owner per business: duplicate active owner memberships exist. Review and resolve them explicitly before retrying.';
  END IF;
END;
$$;

CREATE UNIQUE INDEX IF NOT EXISTS business_memberships_one_active_owner_per_business_idx
  ON app_private.business_memberships (business_id)
  WHERE role = 'owner' AND status = 'active';

-- The public storefront views are a read-only API surface. Remove every
-- existing object privilege first, then grant only SELECT to public clients.
REVOKE ALL PRIVILEGES ON TABLE
  public.storefront_businesses,
  public.storefront_categories,
  public.storefront_listings
FROM PUBLIC, anon, authenticated;

GRANT SELECT ON TABLE
  public.storefront_businesses,
  public.storefront_categories,
  public.storefront_listings
TO anon, authenticated;

-- Avoid repeating the broad table privileges on future objects created in
-- public by either migration owner. Future API exposure must use explicit,
-- least-privilege grants. This does not alter existing objects.
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
  REVOKE ALL PRIVILEGES ON TABLES FROM PUBLIC, anon, authenticated;

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public
  REVOKE ALL PRIVILEGES ON TABLES FROM anon, authenticated;
