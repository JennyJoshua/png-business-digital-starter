# Customer onboarding

## Target instance model

Every customer receives an independent single-store application:
- One GitHub repository under the platform operator's account.
- One independent hosting/deployment.
- One independent Supabase project under the platform operator's account.
- One store in that Supabase project.
- One or more administrators who manage that same store.

The platform operator maintains the Supabase project, database schema, migrations, security configuration, backups and recovery. Store administrators maintain business content and branding; they do not receive database-owner credentials or Supabase project access.

## Current static storefront preparation

1. Copy the template into a new customer repository.
2. Edit `business/business.json` (name, permanent `businessId`, type, colours and contacts). Remove `"demo": true` only after replacing all sample data.
3. Add the customer's logo and optional cover image inside `business/`, then reference relative paths.
4. Edit `business/catalogue.json`; assign each listing a permanent `listingId`. Add optimised images inside `business/images/`.
5. Run `npm run validate`, `npm run build` and `npm run serve`. Review the storefront on mobile and desktop.
6. Review all public content and confirm the business owner approves it.

## Backend provisioning — not yet ready for customer use

Before enabling the admin interface, the platform operator must:
1. Create a separate Supabase project for this business under the operator's account.
2. Record the repository, hosting site and Supabase project association in the operator register.
3. Apply the reviewed single-store baseline migrations.
4. Configure Auth, Data API exposure, grants and RLS.
5. Provision the store profile and initial administrator through the trusted operator process.
6. Test anonymous public REST access, admin access, multiple administrators and denial cases.
7. Configure and test backup/restore and the instance upgrade process.
8. Connect the public storefront and admin interface to this project's URL and publishable key only.

The existing Phase 2B branch still contains an earlier shared multi-tenant prototype. Do not use it to invite real owners, store customer data or launch a customer instance until the single-store redesign and testing are complete.

## Store administrator handover

Store administrators may manage the store's business profile, brand identity, logo/assets, contact details, categories, products/services, catalogue and permitted private promotions. They must not be asked to run SQL, manage migrations, configure Supabase, maintain backups or handle privileged keys.

The platform operator retains technical maintenance responsibility. Explain clearly which business-content tasks the administrator can perform and how to request technical support.

## Future marketplace connection

The starter remains independent. Stable store/category/listing identifiers and versioned export/import formats will support a later owner-consented connection to PNG Materials Marketplace. Do not create central marketplace profiles, social/directory features or cross-business accounts during this onboarding phase.
