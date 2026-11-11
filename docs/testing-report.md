# Testing report — version 1.1.0

## Automated tests

The implementer reports `npm test`: 16 tests passed, 0 failed before the fictional pilot fixture was added. The test suite now includes the dedicated `examples/demo-pilot` fixture alongside the three original examples; the next CI run is the verification evidence for that addition.

Coverage includes example builds, branding isolation, stable IDs, export/import, HTML escaping, invalid configuration, demo-data markings, placeholder rejection, export whitelist, import validation, image fallbacks, empty catalogues and static accessibility structure.

## Builds

The implementer reports successful builds for the original examples:
- Hardware supplier: 6 listings.
- General retail: 5 listings.
- Service provider: 4 listings.
- Default starter: 2 listings.
- Default configuration validation.

A fourth fixture, `examples/demo-pilot`, has now been added with eight fictional hardware/service listings. Its build is included in `npm run build:examples`; verification is pending the next CI run.

Demo-build warnings are expected.

## Browser checks reported by implementer

Headless Chromium via Playwright, four viewport sizes (320×640, 375×667, 768×1024, 1280×800), three original examples plus a broken-image variant. The implementer reports 560 checks passed, including no horizontal overflow, image fallbacks, 44px tap targets, text sizing, navigation, search/filter behaviour, keyboard checks, axe-core and no JavaScript errors.

These browser results are the implementer's report; the browser run has not been independently reproduced in this repository. The new demo-pilot fixture has not yet been included in those reported browser checks.

## Limitations

- Chromium only; no Safari/iOS, Firefox, Android physical device or screen-reader pass.
- No deployment performed for this pilot.
- Marketplace schema not inspected; no compatibility claim.
- Public export file is always emitted.
- SVG assets are served as provided.
