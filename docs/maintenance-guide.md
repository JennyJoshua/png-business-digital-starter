# Maintenance guide

## Apply master-template improvements to a customer copy
The customer's own files live in `business/`; the rest is shared template code.
1. Add the master repository as a remote: `git remote add master <master-repo-url>`.
2. Fetch and merge: `git fetch master`, then `git merge master/main` (or cherry-pick selected commits).
3. Resolve conflicts carefully. Customer-specific edits should stay in `business/`; do not fork shared components for one customer without recording the change upstream.
4. Run `npm run validate`, `npm test`, `npm run build`, review and redeploy.

## Template changes
Edit shared source in `src/`, run tests and build all examples, review the storefronts, bump the package version and record changes in the changelog. Breaking data-format changes require a major schema version update.

## Routine
Update catalogue → validate → build → review → deploy. Back up the whole `business/` folder for each customer.
