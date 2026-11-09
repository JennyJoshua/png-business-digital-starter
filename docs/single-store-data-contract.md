# Single-store data contract

**Status:** design proposal for owner review  
**Applies to:** one independent business app and one Supabase project  
**Parent architecture:** phase-2b/independent-single-store-architecture

## 1. Contract invariants

1. One deployed app instance maps to one business/store and one Supabase project.
2. A database contains exactly one canonical store profile. It is not a shared multi-tenant database.
3. A store may have one or more active administrators. All administer the same store.
4. Store administrators manage business content only. The platform operator manages infrastructure, database, migrations, security, backups and recovery.
5. Public visitors do not need accounts. Public data is limited to explicitly published and allowlisted content.
6. Promotions remain private admin content in v1 and are excluded from all public APIs and storefront output.
7. Stable portable identifiers survive ordinary edits, archive/restore, export and import. An import must not silently replace identifiers.
8. The storefront remains independently usable. The future PNG Materials Marketplace is not a runtime dependency.

## 2. Logical records and proposed fields

This is a logical contract, not executable SQL. Exact SQL types, constraints, indexes, triggers, grants and RLS policies must be reviewed before a migration is written.

| Record | Required fields | Optional / supporting fields | Access |
|---|---|---|---|
| Store profile (singleton) | internal row ID; immutable store_uid; name; status; created/updated timestamps | description, business type, slug, logo/cover asset references, phone, email, address, opening hours, social links, brand tokens | Public allowlist for active/published profile; admins edit permitted fields |
| Admin membership | Auth user ID; active/inactive status; created timestamp | invited/activated/revoked timestamps; operator audit reference | Operator provisions/revokes; user may read own limited membership |
| Category | internal ID; immutable category_uid; name; slug; status; sort order; timestamps | description, image reference | Published categories public; admins manage |
| Listing | internal ID; immutable listing_uid; kind (product or service); name; status; timestamps | category reference, description, SKU/reference, price, currency, unit, images, contact/action details, sort order | Published listings public; admins manage |
| Promotion | internal ID; immutable promotion_uid; title; content; status; timestamps | start/end dates, image, internal notes | Admin-only in v1; never public |
| Asset metadata (later image phase) | internal ID; immutable asset_uid; storage object path; media type; visibility; created timestamp | alt text, dimensions, linked record/type | Deferred from v1; admin metadata private; object access follows separately reviewed bucket policies |
| Store settings | setting key/value; updated timestamp | grouping and validation metadata | Private; only explicitly approved editable settings exposed to admins |

### Singleton enforcement

The database must enforce one store profile, not merely rely on the UI. Recommended pattern: a singleton row key constrained to the single allowed value (for example, primary key instance_key = 1) plus a separate immutable UUID store_uid for portability. The migration must fail safely if a second profile is attempted.

Child tables do not need a business_id/tenant discriminator because each project belongs to one store. They may reference the singleton row where doing so provides useful referential integrity, but must not recreate a cross-tenant model.

### Identifier rules

- Internal database primary keys may be UUIDs or another reviewed stable key.
- Every portable entity has a separate immutable UUID: store_uid, category_uid, listing_uid, and promotion_uid (where promotions are included in an owner-authorised export).
- Generate portable IDs once at record creation. Never derive them from a business name, slug, row order or mutable catalogue fields.
- Slugs and names are editable labels, not identifiers.
- Normal admin operations cannot update or replace portable IDs.
- Archive is a state transition, not a hard delete. Permanent deletion requires a separate retention/export policy and explicit operator process.
- Imported records preserve source portable IDs. If an ID collision exists, reject or quarantine the record for resolution; never silently merge unrelated records.

## 3. Publication states and public field allowlist

Recommended states:
- draft: private; not returned to anonymous visitors.
- published: eligible for public output, subject to parent/category rules.
- archived: hidden from public output and normal catalogue editing; retained for references and export history.

A listing is publicly visible only when it is published and its category (if required) is also published. The store profile itself must be in its approved public state. Public endpoints must select explicit columns rather than SELECT *.

### Public fields

- Store profile: store_uid, display name, business type, public description, public contact channels, public address/opening hours if approved, brand tokens, public logo/cover URLs.
- Category: category_uid, name, slug, description, public image URL, sort order.
- Listing: listing_uid, kind, name, description, category portable ID, price, currency, unit, public images, public contact/action details, sort order.

### Never public in v1

- Admin membership, Auth identifiers, invitations, revocation state.
- Private store settings, internal notes, moderation/audit fields.
- Draft/archived content.
- Promotions and promotion schedules.
- Private asset metadata, private object paths and upload diagnostics.
- Operator register, project references, migration status, backup metadata or credentials.

Public contact fields are content chosen by the store administrator; the application must not expose private account email addresses or administrator identity as a side effect.

## 4. Pricing and catalogue semantics

- Store money as a decimal amount, never binary floating-point.
- Store currency as an explicit ISO 4217 currency code (for PNG Kina, PGK).
- A missing price means “not specified / contact the business”; it must not be interpreted as zero.
- Do not assume every service has a fixed price. Support optional price and a clear unit/price note.
- Preserve the original amount and currency during export/import. Currency conversion is a separate future feature.
- kind distinguishes product from service; do not infer it from category names.
- Category deletion should be blocked while listings reference it, or require an explicit reassignment/archive workflow.

## 5. Administrator membership contract

- Supabase Auth identifies the user; a separate database membership record authorises store administration.
- Membership starts inactive/pending and becomes active only after the trusted operator provisioning/invitation workflow is complete.
- Initial administrator and additional administrators are provisioned by the platform operator using a trusted server-side/dashboard process. No browser-side self-enrolment, self-promotion or membership writes.
- The first version has one permission class: store_admin. Do not invent owner/editor roles until the product owner approves a role matrix.
- Multiple active administrators can manage the same store.
- Revocation is performed by the operator. The implementation must define and test session/token invalidation or a server-side active-membership check for sensitive operations; do not assume deleting a membership instantly invalidates an already-issued JWT.
- Administrators never receive the Supabase project-owner role, database password, service-role key or secret key.

## 6. Versioned export/import contract

Export format is JSON with an explicit schema version. Example envelope (illustrative only):

    {
      "format": "png-business-store-export",
      "schema_version": "1.0.0",
      "exported_at": "2026-11-09T00:00:00Z",
      "store": {
        "store_uid": "00000000-0000-4000-8000-000000000001",
        "name": "Example Store",
        "business_type": "retail"
      },
      "categories": [],
      "listings": [],
      "assets": [],
      "included_sections": ["store", "categories", "listings", "public_assets"]
    }

Rules:
- Export is generated from an explicit allowlist and includes only sections selected/authorised by the store owner.
- Do not include Auth users, passwords, session tokens, project credentials, private settings, operator metadata or internal audit/security data.
- Promotions are excluded by default and remain private in v1. Any later inclusion requires a separate owner-approved export option and documented privacy review.
- Asset binaries may be packaged separately or represented by stable asset IDs plus downloadable files; never export temporary signed URLs as durable references.
- Include each entity's portable ID, status, created/updated timestamps and source schema version where relevant.
- Import validates the envelope and every record before writing. Unknown major versions are rejected. Compatible minor versions may be accepted only through explicit migration rules.
- Import is preview-first: show counts, conflicts, invalid records and planned changes; require an operator/owner confirmation before applying.
- Import must be idempotent for the same source export, preserve portable IDs and report skipped/updated/created records.
- No automatic synchronisation or marketplace sharing is part of this phase.

### Future PNG Materials Marketplace handoff

The marketplace may later accept an owner-consented export through a documented mapping. Consent must identify the business, destination, data sections, purpose and time. The owner must be able to decline without affecting the standalone storefront. A later synchronisation feature must define revocation and treatment of copies already imported. Do not build central profiles, social/directory features or cross-business accounts in this phase.

## 7. Acceptance criteria

- Database-level singleton constraint prevents a second store profile.
- Two or more active administrators can manage the same instance.
- An inactive/non-member cannot use admin operations.
- Admin client cannot create or activate its own membership.
- Anonymous requests return only published allowlisted profile/category/listing fields.
- Promotions, memberships, private settings and draft/archived records are not publicly readable.
- Stable IDs survive edit, archive, export and import.
- Invalid/unknown export versions and ID collisions fail safely.
- No project credentials, Auth secrets or operator-only data appear in an export.
- A separate instance has a separate project and cannot query this instance's database.

## 8. Open design decisions before SQL

The following recommendations are specified in the Phase 2D design for owner review before implementation:
1. Store profile fields are limited to the explicit public contact/address allowlist; administrators choose which business contact details to publish.
2. V1 uses validated HTTPS image URLs only. Supabase Storage, asset metadata, bucket visibility and upload policies are deferred to a later separately reviewed phase.
3. Administrators may restore archived catalogue records by changing status back to draft/published; hard deletion remains operator-only.
4. V1 export is a versioned JSON envelope with separately referenced asset URLs; packaging limits are deferred until image upload/export is implemented.
5. The operator sends Auth invitations and activates/revokes membership. RLS checks current membership state so revocation blocks app data access even if the Auth JWT remains valid.
6. Archive is the normal retention mechanism. Permanent deletion/retention periods require a separately approved policy and backup/recovery process.

No schema has been applied to Supabase by this document.
