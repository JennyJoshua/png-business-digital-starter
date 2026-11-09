# PNG Business Digital Starter

A reusable, mobile-first storefront template for Papua New Guinea businesses. The master template is maintained centrally; every customized business app is an independent single-store product with its own GitHub repository, hosting/deployment and Supabase project, all controlled by the platform operator.

**Approved architecture:** one deployed app = one store = one Supabase project. A store may have one administrator or several administrators, all managing that same store. The platform operator owns and maintains the database infrastructure, schema, migrations, backups and technical operations. Store administrators are custodians of their business profile, branding and catalogue content; they do not receive database-owner or Supabase project access.

The future PNG Materials Marketplace is a separate later-stage platform. This starter will preserve stable identifiers and portable data contracts so a business can connect or transfer selected data with its consent when that platform is ready.

## What it does

Reads business and catalogue data and generates a fast mobile-first public storefront: homepage, about, live search suggestions, searchable results, category filters and sorting, product/service pages, contact links, social links and sharing. Public visitors browse without accounts. Public Promotions output is excluded. A separate private admin interface lets authorised store administrators maintain the store's content.

Demonstration data is clearly marked. A real business must replace all sample content before public launch.

## Architecture and project status

- Each customized business app has its own repository under the platform operator's GitHub account.
- Each app has its own hosting/deployment and its own Supabase project under the platform operator's account.
- Each Supabase project contains data for that one store only; no shared multi-business tenant database is used for customer instances.
- One or more invited administrators may be associated with that store. Their access is limited to that store's admin functions.
- The platform operator controls project provisioning, database schema, migrations, backups, security configuration and maintenance.
- Store administrators manage approved business content through the admin interface; they are not database operators.
- No central business directory, social network, marketplace account system or cross-business admin portal is part of this starter phase.

**Important implementation status:** the current Phase 2B working branch contains an earlier shared multi-tenant database implementation and an initial owner-admin interface. That implementation is a development prototype, not the approved customer-instance architecture. Its schema, policies, admin queries and tests must be redesigned and revalidated for the single-store-per-project model before it is treated as a deployable template. Do not provision customer data or invite a real store administrator into the current prototype.

## Quick start

Node.js 18+; no packages are required for the static build:

```
npm run build:examples
npm run build
npm run serve
npm run validate
npm test
```

See [architecture](docs/architecture.md), [customer onboarding](docs/customer-onboarding.md), the [single-store data contract](docs/single-store-data-contract.md), the [operator provisioning and maintenance workflow](docs/operator-provisioning-and-maintenance.md), and the [Phase 2B implementation plan](docs/phase-2b-implementation-plan.md), [Phase 2D database schema/security design](docs/phase-2d-database-schema-security-design.md), and [Phase 2D security test plan](docs/phase-2d-database-security-test-plan.md) for the current design and implementation gates.

## Database operations

The platform operator is responsible for each instance's Supabase project and database lifecycle. The template must provide repeatable, version-controlled migrations and a documented provisioning procedure so the operator can create, update, back up and recover each instance consistently. Customer-facing administrators must never receive a Supabase service-role/secret key or direct database-owner credentials.

The existing `PNG Business Digital Starter Dev` project is a development environment for the earlier prototype only. It is not a shared production database and must not be used for live customer data. Do not delete or repurpose it until its existing schema and migration history have been reviewed and a separately approved transition plan exists.

## Future marketplace compatibility

Business, category and listing records must have stable portable identifiers and documented export/import formats. Data transfer or connection to PNG Materials Marketplace must be explicit, scoped and consent-based. The starter must remain independently useful if the marketplace is not yet available.

## Not yet implemented / not yet approved

The independent per-store Supabase provisioning and migration workflow, redesigned single-store schema and policies, multiple-admin workflow, operator maintenance workflow, real Auth/REST/browser integration tests, image storage policies, live public-storefront data adapter, backups/recovery procedure and marketplace export/consent flow remain work items. The Phase 2D schema/security documents are design specifications only; no new single-store migration has been applied. Payments, carts, customer accounts and the future central marketplace are outside the current scope.

No production deployment, merge to `main`, customer onboarding or destructive database change is authorised by this documentation revision.
