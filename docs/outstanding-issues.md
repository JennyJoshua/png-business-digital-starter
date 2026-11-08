# Outstanding issues (version 1.1.0)

1. Marketplace schema has not been inspected. Field mapping, provider type, approval, consent and ID collision rules remain unresolved. This blocks marketplace integration, not standalone use.
2. Browser coverage reported by the implementer is Chromium only (320, 375, 768 and 1280 px). Safari/iOS, Firefox, Android browsers, real devices and slow networks are not covered.
3. Accessibility checks include axe-core and structural tests, but no manual screen-reader pass or physical-device testing.
4. No hosting deployment has been performed; deployment and domain instructions remain unverified.
5. Public export is always generated at `/export/business-export.json`. It contains whitelisted storefront-visible fields, but customers may prefer a way to disable it.
6. Uploaded SVG images are served as-is and may contain active content if opened directly. Use trusted files only.
7. Images are not resized or compressed by the build; large images can slow mobile pages.
8. Search is client-side and has no pagination; suitable for small-to-medium catalogues.
9. Placeholder detection is heuristic and cannot identify every false detail; human review is required before launch.
10. Older configs with unsupported types or unsafe image paths now fail validation and may need correction.
