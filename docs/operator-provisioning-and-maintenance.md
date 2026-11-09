# Operator provisioning and maintenance

**Status:** operational design proposal; not yet implemented or tested  
**Owner:** platform operator  
**Scope:** repeatable lifecycle for independent single-store app instances

## 1. Operating model

The platform operator owns and maintains the technical stack for every instance:
- GitHub repository and source changes.
- Hosting project, deployment configuration and environment variables.
- Supabase project, database schema, migrations, Auth/Data API configuration, security and backups.
- Monitoring, incident response, recovery and technical upgrades.

The business owner and their authorised administrators are content custodians. They manage approved store profile, brand assets, categories, products/services, catalogue and private Promotions. They do not administer Supabase, GitHub infrastructure, database credentials, migrations or backups.

**One instance = one repository + one hosting deployment + one Supabase project + one store.** Never place two customer businesses in one instance database.

## 2. Operator instance register

Maintain a private operator-controlled register. It is an inventory and maintenance record, not a customer-facing feature. Suggested fields:

| Field | Purpose |
|---|---|
| instance_id | Operator-generated immutable identifier for this deployment |
| store_uid | Portable store identifier from the data contract |
| business_display_name | Human-readable label; not a key |
| repository_full_name and repository_url | Source repository |
| hosting_provider, hosting_project_id, production_url | Deployment association |
| supabase_org_id, supabase_project_ref, region | Backend association |
| schema_version / latest migration | Database upgrade state |
| auth_config_reviewed_at | Last Auth configuration review |
| security_reviewed_at | Last security/advisor review |
| backup_method, last_backup_at, last_restore_test_at | Recovery evidence |
| status | planned, provisioning, test, active, suspended, retired |
| created_at, updated_at, notes | Operational history |

Never store database passwords, service-role/secret keys, recovery codes, user passwords or access tokens in this register. Store secrets only in the relevant provider's protected secret manager/environment configuration. Do not put them in GitHub files, public build variables, issues, handovers or customer admin UI.

## 3. New instance provisioning workflow

### Gate 0 — approval and scope

Before creating paid resources or using a customer's data:
- Confirm the business instance is authorised and identify the approved business content.
- Confirm the chosen hosting and Supabase plans/costs. Do not create a resource with a non-zero cost without explicit user approval.
- Confirm the intended repository name, deployment URL and region.
- Confirm who may administer the store and obtain the required invitation email addresses through an appropriate private channel.
- Keep the instance in planned status until the owner approves the scope.

### Gate 1 — repository and hosting

1. Create a new repository from the reviewed template under the operator's GitHub account.
2. Preserve the upstream/template relationship and record the template version/commit.
3. Add only non-secret public configuration to the repo.
4. Create a separate hosting project/deployment for this instance.
5. Configure environment variables in the hosting provider's protected settings. Browser variables may contain only the Supabase project URL and publishable key; never a secret/service-role key.
6. Verify the deployment is the correct business instance and does not reference another store's backend.

### Gate 2 — Supabase project

1. Create one new Supabase project under the operator's account for this business.
2. Confirm region and cost before creation; retain the project reference in the private register.
3. Apply the reviewed baseline migration set in order.
4. Configure Auth, redirect URLs, email/invitation settings, Data API exposure and database grants according to the reviewed checklist.
5. Confirm every exposed table has RLS and least-privilege grants. Verify views do not bypass intended RLS.
6. Configure storage only after bucket visibility and object policies are reviewed.
7. Run security/performance advisors and resolve relevant findings.
8. Create the singleton store profile and initial admin membership through the trusted operator-only provisioning path.

The current prototype project is not the template for new customer data and must not be destructively converted as part of this procedure.

### Gate 3 — verification before invitation/launch

Run and retain evidence for:
- Clean baseline migrations and recorded schema version.
- Singleton store constraint.
- Anonymous access limited to published allowlisted content.
- Anonymous denial for promotions, membership, private settings and unpublished records.
- Unauthenticated admin denial.
- Active administrator access.
- Two active administrators of the same store.
- Non-member denial and membership revocation behaviour.
- Client cannot self-enrol or grant membership.
- No privileged key in source, browser bundles, network requests or build output.
- Public and admin mobile browser workflows.
- Backup creation and a restore test on a safe target.
- Correct instance-to-repository/hosting/project association.

Only after these checks pass may the instance move to test or active, subject to the owner's separate launch approval.

### Gate 4 — administrator handover

1. Invite the approved initial administrator using the operator-controlled Auth process.
2. Explain that the administrator manages business content only.
3. Demonstrate profile/branding, category and listing changes, and private Promotions management.
4. Explain support/escalation for technical issues.
5. Record who was invited, when, and the membership status—without recording passwords or tokens.
6. Add additional administrators only after owner authorisation.

## 4. Migration and upgrade lifecycle

- Keep all schema changes as reviewed, ordered migration files in the template repository.
- Each migration has a clear purpose, dependencies and rollback/forward-fix notes.
- Test the full migration sequence on a clean disposable Supabase project before any customer instance.
- Record the deployed migration/schema version per instance.
- Do not assume a code deployment automatically upgrades the database.
- For each upgrade: review change impact, take/verify a recoverable backup, apply migration to a test instance, run security and regression checks, then schedule and apply to the target instance with explicit approval where user-visible or risky.
- Prefer additive migrations and compatibility windows. Avoid destructive column/table changes until all app versions and data dependencies are accounted for.
- If a migration fails, stop and inspect state; do not blindly rerun or reset a customer database.
- For destructive or irreversible changes, require a separate explicit approval and a verified recovery path.

## 5. Backup, restore and recovery

A backup is not considered reliable until a restore has been tested.

For each instance, document:
- What is backed up: database records, storage objects, application source/configuration, and any provider-managed configuration that cannot be recreated automatically.
- Backup mechanism and frequency supported by the actual plan/provider.
- Retention period and storage location.
- Who can access backup files and how they are protected.
- Recovery point objective (maximum acceptable data loss) and recovery time objective (target time to restore), agreed before customer launch.
- Restore sequence and post-restore checks.
- Date and result of the last restore drill.

Do not promise point-in-time recovery, automated backups, a particular retention period or free backup capability until verified for the selected Supabase plan and hosting arrangement. For the initial low-cost design, distinguish provider-managed backups from operator-created logical exports and storage-file copies.

Restore procedure:
1. Declare the incident and stop risky writes/deployments.
2. Identify the affected instance and last known-good backup/export.
3. Create or select a safe recovery target; never overwrite the only source copy.
4. Restore database and storage assets using the documented method.
5. Apply only the required compatible migrations.
6. Verify store singleton, record counts, key relationships, public access, admin access and assets.
7. Reconnect the deployment only after validation.
8. Record the incident, data-loss window, recovery actions and follow-up prevention.

## 6. Admin lifecycle and security operations

- Operator creates/invites admin identities and associates them with the one store.
- Owner requests additions/removals through the agreed support channel.
- Operator verifies authorisation before changing membership.
- Revocation removes active membership and uses the tested session/token invalidation procedure.
- Review admin list periodically with the business owner.
- Never share Supabase dashboard access as a shortcut for content administration.
- Rotate exposed secrets immediately; investigate whether the secret was used; redeploy only after the replacement is configured.
- Keep audit events for operator provisioning, membership changes, migration runs, restore drills and incidents. Do not expose internal audit records to public visitors.

## 7. Instance lifecycle states

| State | Meaning | Permitted action |
|---|---|---|
| planned | Scope approved; resources not provisioned | Prepare repo/config plan |
| provisioning | Repo, hosting and backend being created | Operator-only setup |
| test | Baseline exists; acceptance checks in progress | Test with synthetic data |
| active | Owner-approved and checks passed | Normal content administration and maintenance |
| suspended | Temporarily unavailable or under investigation | Restrict access; preserve data |
| retiring | Closure approved; export/retention being handled | Read-only/export and controlled shutdown |
| retired | Instance closed under retention policy | No normal access; retain required records/backups |

## 8. Minimum operational acceptance criteria

- A new instance can be provisioned from a clean template without reusing another customer's database.
- Operator register identifies the exact repository, deployment, project, region and schema version.
- No secret appears in source control, public build output, browser code or operator register.
- The operator can repeat migrations and verify the resulting version.
- Multiple admins can manage one store without infrastructure access.
- A non-member is denied; revoked access is blocked under the tested session design.
- Backups include the documented data/assets and a restore drill succeeds.
- Instance can be suspended/retired without accidentally affecting another instance.
- The store remains functional without PNG Materials Marketplace.

## 9. Not authorised by this design

This document does not create Supabase projects, change the existing development database, create customer repositories, invite administrators, configure paid hosting, deploy production, or authorise customer data onboarding. Each such action requires its own approval and, where applicable, cost confirmation.
