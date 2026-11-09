# Phase 2B — Backend Architecture

**Architecture status:** revised and approved direction; implementation redesign required.  
**Working branch:** `phase-2b/independent-single-store-architecture`

## 1. Purpose

Provide a secure, repeatable backend for the private administrator interface while keeping the public storefront independent and mobile-first. Every customized business app is a separate single-store instance. The platform operator maintains the technical infrastructure; the business's administrators maintain business content.

This document defines the target architecture. It does not claim that the current Phase 2B prototype has already been converted or tested against it.

## 2. Approved deployment topology

**One app instance = one business/store = one Supabase project.**

Each customer instance receives:
- Its own GitHub repository under the platform operator's account.
- Its own hosting and deployment.
- Its own Supabase project under the platform operator's account.
- Its own database containing only that store's records.
- Its own public storefront and private admin interface.

Instances are isolated from one another by project/database boundaries, not by a shared multi-tenant business-membership model. A compromise or data query in one instance must not expose another business's data.

The platform operator is responsible for creating and maintaining each project, controlling database access, applying reviewed migrations, monitoring, backups and recovery. Store owners/admins do not need Supabase dashboard access and must not receive database-owner credentials or privileged keys.

The existing `PNG Business Digital Starter Dev` project (`rwcwvqlgyckfdrglsbfg`, Sydney) contains the earlier shared multi-tenant prototype. It is not the approved customer-instance pattern. Do not delete it, apply a destructive conversion, or place live customer data in it. Review it separately and decide its future only through an approved transition plan.

## 3. Roles and responsibility boundaries

| Actor | Responsibilities | Must not receive |
|---|---|---|
| Platform operator (template owner) | Owns GitHub repos and Supabase projects; provisions instances; maintains schema, migrations, security, backups, hosting configuration and technical operations | — |
| Store owner / administrator | Maintains that store's business name/profile, branding, logo, contact details, categories, products/services, catalogue content and permitted promotions | Supabase project-owner access, database credentials, service-role/secret keys, access to another store |
| Public visitor | Browses and searches published store content without registration | Private admin data or admin actions |

A store may have one administrator or several administrators. All administrators in a particular app instance belong to the same store and have the same store boundary. A later role/permission distinction (for example, owner versus catalogue editor) requires a separate product decision; do not silently invent elevated roles.

## 4. Target logical data model

The single-store database should not require a business-to-many-tenant abstraction. It may contain a singleton store/profile record and store-scoped content tables.

| Logical record | Purpose | Access |
|---|---|---|
| `store_profile` | One canonical store profile, stable portable store ID, name, slug/type, brand and publication state | Public allowlisted fields; administrators may edit permitted fields |
| `store_admins` | Maps Auth users to this instance's store and active admin status | Operator provisions; admins may read their own membership only |
| `categories` | Store categories with stable portable IDs and archive/publication state | Public published rows; authenticated store admins manage |
| `listings` | Products/services, stable portable IDs, descriptions, price/currency and publication state | Public published rows; authenticated store admins manage |
| `promotions` | Store promotions and campaign content | Private admin management; public placement remains excluded unless separately approved |
| `asset_metadata` | Logo/listing image paths, ownership and visibility metadata | Store admins within approved upload rules; public only for explicitly public assets |
| `store_settings` | Private store-specific operational settings | Store admins for approved settings; operator retains infrastructure control |

The precise physical schema, constraints and grants must be designed in a reviewed migration before implementation. A singleton store record should be enforced at database level. Stable external IDs must be immutable through ordinary admin operations. Prefer archive/status transitions to destructive deletion where records may be referenced by exports or future marketplace integration.

### Multi-admin model

The `store_admins` relationship supports multiple Auth users for the one store in that project. The operator provisions and revokes administrator membership through a trusted process. The browser client must not be able to add itself, promote itself, or grant another user access. RLS and database grants must verify an active membership for the current Auth user.

Because each project belongs to one store, policies should be simpler than the previous cross-tenant membership design. Nevertheless, every exposed table and view must have deliberate grants and RLS. Do not rely on an unguessable ID, hidden UI route, or authenticated role alone as authorization.

## 5. Public and administrator interfaces

- Public storefront and private admin are separate application surfaces.
- Public visitors do not register or log in to browse.
- Public REST access returns only explicitly allowlisted fields for published store profile, categories and listings.
- Draft/archived records and private settings are not public.
- Promotions are managed in the admin interface and are not rendered in public navigation, pages, banners or placements under the current product decision.
- Admin data access uses the intended private/admin API surface and RLS. Never put a service-role or secret key in browser code.
- Public storefront content must be driven by the canonical per-instance data source after a tested adapter is implemented. Until then, static sample/config data remains a prototype/fallback and must not be represented as live-synchronised.

For Supabase views, use `security_invoker = true` where supported and verify underlying grants/RLS. Views are not automatically safe merely because their source tables have RLS.

## 6. Operator maintenance and repeatability

The template must support repeatable operation across many independent Supabase projects:
1. Create a new project for the business instance under the operator's account.
2. Apply the version-controlled baseline migrations.
3. Apply per-instance configuration and secure Auth settings.
4. Provision the first store record and initial administrator through a trusted operator-only process.
5. Verify REST/browser behaviour and security acceptance tests.
6. Connect the instance's public site and admin app to only that project's URL and publishable key.
7. Record project/repository/deployment references in an operator-controlled register.
8. Maintain schema versions, backups, restore instructions and a tested upgrade procedure.

Migration files must be idempotent where practical, ordered, reviewed and tested against a clean disposable project before being applied to a customer instance. The operator must be able to identify which migration version each instance is running. Never use a browser-exposed key for operator maintenance.

The operator's maintenance access must be protected by the account's own security controls. Store administrators should not be asked to perform SQL, manage migrations or maintain backups.

## 7. Data portability and future PNG Materials Marketplace

This starter is an independent business storefront, not the central marketplace platform. It must preserve:
- Stable store, category and listing identifiers.
- Documented, versioned JSON export/import formats.
- Explicit field mapping and currency/price semantics.
- Owner-controlled export and consent before data is shared with the future marketplace.
- A way to revoke future synchronisation consent and understand what data was shared.

Do not build a Facebook-like central business directory, shared marketplace profiles, cross-business accounts or central marketplace admin now. Those belong to a later PNG Materials Marketplace phase. Avoid coupling each store's runtime availability to the future platform.

## 8. Security requirements

- RLS enabled on every exposed table.
- Least-privilege grants for `anon` and `authenticated`.
- No client-side service-role/secret keys.
- Admin policies verify an active membership for `auth.uid()`; `TO authenticated` alone is not authorization.
- UPDATE policies include both `USING` and `WITH CHECK`.
- Admin membership provisioning is operator-controlled.
- Public views expose explicit columns only and exclude private fields.
- Storage bucket and object policies are designed before uploads are enabled.
- Auth signup is not open to the public; initial admin accounts are provisioned/invited by the operator.
- Review Supabase Security and Performance Advisors after schema changes.

## 9. Current prototype versus target

The current working branch contains a prior shared multi-tenant schema with business memberships, tenant-scoped policies, public views, `admin_api` views and an initial static admin interface. Some SQL role-simulation tests passed for that prototype. Those results are historical evidence for the old design only; they do not prove the target single-store architecture.

The existing development database is empty of real customer records and has no owner account. Preserve it until a transition decision is made. Do not claim the current admin UI is compatible with the target until its membership lookup, data model, API calls, provisioning and tests have been reviewed and changed.

## 10. Next steps

1. Freeze the old shared-tenant design as a prototype; no customer onboarding or production use.
2. Finalise the single-store schema, multiple-admin membership model and operator provisioning/maintenance contract.
3. Update the implementation plan and security acceptance tests for one project per store.
4. Implement the new migrations and adapt the admin UI without destructive changes to the existing development project.
5. Test the baseline on a clean disposable Supabase project, including multiple admins of one store.
6. Implement and test public REST data access and the live storefront adapter.
7. Document backup/restore, per-instance upgrade and operator register procedures.
8. Review the future marketplace export/consent contract.

No production deployment, merge to `main`, customer onboarding or destructive database conversion is authorised by this architecture document.
