# Outstanding issues (version 1.1.0)

1. Marketplace schema has not been inspected. Field mapping, provider type, approval, consent and ID collision rules remain unresolved. This blocks marketplace integration, not standalone use.
2. Browser coverage reported by the implementer is Chromium only (320, 375, 768 and 1280 px). Safari/iOS, Firefox, Android browsers, real devices and slow networks are not covered.
3. Accessibility checks include axe-core and structural tests, but no manual screen-reader pass or physical-device testing.
4. The demo storefront is deployed to GitHub Pages and the deployment workflow has passed. A customer-specific production deployment, custom domain, backup and operational setup remain unverified.
5. Public export is always generated at `/export/business-export.json`. It contains whitelisted storefront-visible fields, but customers may prefer a way to disable it.
6. Uploaded SVG images are served as-is and may contain active content if opened directly. Use trusted files only.
7. Images are not resized or compressed by the build; large images can slow mobile pages.
8. Search is client-side and has no pagination; suitable for small-to-medium catalogues.
9. Placeholder detection is heuristic and cannot identify every false detail; human review is required before launch.
10. Older configs with unsupported types or unsafe image paths now fail validation and may need correction.

11. Phase 2C platform-admin console and its database migration are on a feature branch and have not been merged or deployed. The trusted administrator allowlist is intentionally empty until a platform-admin identity is approved and provisioned through a controlled database operation.
12. Hosted Supabase migrations from Phase 2B and Phase 2C remain unapplied. Do not onboard owners or create real business/customer data until the user separately approves the migration sequence and live verification.
13. The platform-admin route must be added to Supabase Auth redirect allow-lists if password recovery or invitation callbacks are later enabled for that route. Current console sign-in uses an existing account/password and no admin invitation flow.
14. Public storefront synchronization from canonical Supabase records remains outstanding; current static storefront content is still generated from JSON configuration.
