# Social media roadmap

## Built in v1
- Social profile links in the footer (validated http/https URLs).
- Shareable business and listing pages; share button uses the phone share sheet or copies the link.
- `promo.html` generates ready-to-use promotional text from catalogue data, with a WhatsApp share link.

## Not built
No direct publishing to Facebook, Instagram, TikTok or other platforms. No social logins, passwords or tokens are requested or stored.

## Future requirements
1. Official OAuth connections per platform, subject to platform eligibility and review.
2. Secure server-side token storage, encrypted and separated by business; tokens never in static sites or repositories.
3. Platform publishing APIs, subject to approvals, permissions and rate limits.
4. Background jobs for scheduling, retries and failure reporting.
5. A trusted backend separate from static storefront deployments.
