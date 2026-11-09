# Architecture

**Principle:** one master template, many independent single-store applications, one future marketplace connection.

## Current public storefront implementation

`scripts/build.mjs` reads a business folder and writes plain HTML/CSS/JS into `dist/`.

| Need | Current approach |
|---|---|
| Independent storefronts | Each customer receives a separate repository and build |
| Config-driven branding | Colours, name, logo and cover come from business configuration |
| Mobile performance | Static output, small CSS/JS, lazy-loaded images |
| Low-cost hosting | Static hosting is supported |
| Future API integration | Stable IDs and versioned export contract |
| Simple public delivery | No framework/runtime server required for the public static build |

Catalogue edits in the static-only baseline require a rebuild and redeploy. Phase 2A is merged into `main`: public Promotions output is removed; homepage logo fallback, live listing/category suggestions and a dedicated results page with filtering/sorting are implemented.

## Approved product architecture: independent single-store app + private admin

Each customized business application is an independent instance with:
- Its own GitHub repository under the platform operator's account.
- Its own hosting/deployment.
- Its own Supabase project under the platform operator's account.
- Exactly one store/business in that database.
- A public storefront and a separate private admin interface.

One store may have one administrator or several administrators. All of them administer the same store in that instance. The platform operator owns and maintains the technical infrastructure, database schema, migrations, security configuration, backups and recovery. Store administrators are custodians of the store's brand, profile and catalogue content; they do not receive Supabase project-owner or database-maintenance access.

This replaces the earlier shared multi-tenant Supabase proposal. Do not implement cross-business tenant switching or place multiple customer stores in one customer database.

### Public storefront

Customers browse without accounts. The storefront displays only public business information and published products/services, search, category navigation, listing details and contact/social links. It must not contain a dedicated Promotions section or owner-management controls.

### Private store admin

Authenticated store administrators manage their own store's profile, brand identity, logo/assets, contact details, categories, products/services, catalogue content and private Promotions. The interface must be separate from the public customer experience. Store administrators cannot manage database schema, migrations, backups, project settings or privileged credentials.

### Shared data and publication

The public storefront and admin interface use the same canonical records within that one store's Supabase project. Public APIs return explicit allowlisted fields and published records only. Draft/archived and private data remain unavailable to anonymous visitors. Promotions remain private in v1 and must not appear in public navigation, pages, banners or placements.

### Security boundary

Admin security must be enforced by Auth, database grants and RLS—not merely by hiding a link or route. Every exposed table needs deliberate RLS and least-privilege grants. Admin policies must verify an active membership for the current user; authenticated role alone is insufficient. Multiple administrators may be members of the same store, but they cannot self-enrol or grant access through the browser client. Never embed service-role/secret keys in public files.

## Platform operator maintenance model

The platform operator provisions each independent Supabase project, applies reviewed version-controlled migrations, configures Auth/Data API settings, provisions store and administrator records through a trusted process, monitors the instance and maintains backups/recovery. A repeatable clean-project setup and upgrade procedure is a prerequisite for customer onboarding.

The current Phase 2B branch contains an earlier shared multi-tenant prototype. Its schema, membership model, admin API calls and security tests do not yet implement this approved architecture. It must be redesigned and retested before customer use. The existing development project is retained for review; do not destructively convert or delete it without a separate approved plan.

## Future PNG Materials Marketplace

The future PNG Materials Marketplace may later provide central business profiles, discovery and marketplace-wide features. That is not part of this starter phase. Each storefront must work independently without depending on the marketplace.

Preserve stable store/category/listing IDs and a versioned export/import contract. Any future transfer or synchronisation must be scoped, documented and explicitly consented to by the business owner. Do not build a central Facebook-like directory or cross-business account system now.

## Search experience

Search must support mobile live suggestions for products/services and categories, a full results page, category filters, sorting, useful empty states and clear-search. The merged Phase 2A implementation provides client-side live suggestions and a dedicated results page. The public experience must only search public catalogue fields.

## Demonstration-only items

Example businesses, phone numbers, emails and social links are placeholders. Demo data must remain visibly marked and must be replaced and reviewed before launch.

## Design system

One shared stylesheet and page-template system supports all instances. Branding changes colours, logo and cover while preserving consistent layout. The admin should reuse design tokens where appropriate but retain its own information architecture and access boundary.

## Phase 2B status

The approved target architecture is documented, but the existing implementation remains the old shared-tenant prototype. Single-store schema, multi-admin workflow, operator provisioning/maintenance, REST/browser integration, Storage policies, live public data adapter and backup/restore procedure remain to be implemented and verified.
