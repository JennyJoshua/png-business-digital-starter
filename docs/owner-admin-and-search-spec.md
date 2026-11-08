# Owner Admin and Public Storefront — Product Design Decisions

**Status:** Phase 2A public storefront changes are merged into `main`. Phase 2B is defining the secure owner-admin backend; the admin and authentication are not yet implemented.

## 1. Product structure

Provide two distinct experiences that share the same underlying business and catalogue data:

### Public storefront
- Publicly accessible; customers can browse without creating an account.
- Shows business identity, logo or logo placeholder, business profile, products/services, categories, search, listing details, contact details and social links.
- Does not show an owner dashboard, admin controls or a dedicated Promotions section.
- Does not expose private owner data or admin actions.

### Private owner admin
- Separate management interface for the authenticated business owner.
- Includes dashboard, business profile and branding, logo management, catalogue/listing management, category management, promotions management, contact/social details and data export.
- Promotions are private to the owner in v1. No public promotions page, nav item, homepage banner or public promotional placement is included in this release.

## 2. Architecture decision

Use separate interfaces and access boundaries within the same product/codebase initially, rather than maintaining two independent codebases. Both interfaces share business identity, catalogue records, stable IDs and design tokens.

Each customer continues to receive an independent business application/deployment. The architecture must remain portable and integration-ready for future PNG Materials Marketplace onboarding.

## 3. Security requirements

- Owner admin requires authentication and server-side authorization.
- Hiding an admin link or relying on an unlisted URL is not access control.
- Owner-only reads/writes must be protected by a trusted backend.
- No privileged credentials or secrets may be shipped to public static files.
- Public pages and exports contain only explicitly public/whitelisted fields.
- The current static generator has no authentication or persistent admin editing; backend/auth design is a prerequisite to implementing the admin. Phase 2A does not introduce an admin route or expose owner data.

## 4. Logo placeholder

The public homepage reserves a consistent logo area. Display the business logo when configured; otherwise display a neutral branded placeholder without breaking the layout. The owner admin will eventually allow the owner to add or replace the logo.

## 5. Search and results behaviour

### Live suggestions
- Suggestions appear beneath the search box as the customer types.
- Match product/service names and relevant categories.
- Suggestions are concise and selectable, with listing/category context.
- Include a “View all results” action for the current query.

### Full results
- Display matching products/services as mobile-friendly result cards or rows.
- Show image, listing name, category, business name and price when supplied.
- Provide category filtering and useful sorting.
- Selecting a result opens its detail page.
- Provide a helpful empty state and a clear-search action when no results match.
- Only public catalogue fields may be indexed or displayed.

## 6. Acceptance criteria

1. No Promotions navigation item, page or section is visible on the public storefront.
2. An authenticated owner can reach Promotions management in the private admin.
3. Unauthenticated visitors cannot access admin data or owner actions, including by entering a direct URL.
4. Public homepage displays the configured logo or a consistent placeholder.
5. Typing a query displays relevant live suggestions.
6. A suggestion can be selected, and “View all results” opens a full results view.
7. Full results show the defined listing information and support category filtering/sorting.
8. No-results state is clear and offers a way to clear the query.
9. Public search and exports do not reveal private admin information.
10. Public and admin interfaces read/write the same canonical business and catalogue records.

## 7. Implementation boundary

Implementation status: Phase 2A is merged into `main` and implements public Promotions removal, homepage logo area/fallback, live listing/category suggestions and a full results page with category filtering, sorting and clear-search. This does not implement secure authentication, a backend, owner dashboard, private Promotions management or logo upload. Those remain separate scoped phases and must not be exposed through public static files.
