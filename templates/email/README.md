# Auth0 email templates

HTML templates for Auth0's transactional emails, styled to match the app's design system (`lib/config/design_tokens.dart`, see [docs/DESIGN.md](../../docs/DESIGN.md)). Auth0 renders them with Liquid ([supported Liquid syntax](https://auth0.com/docs/customize/email/email-templates/supported-liquid-syntax)).

| File | Auth0 template | Suggested subject |
| --- | --- | --- |
| [`auth0_verification_email.html`](./auth0_verification_email.html) | **Verification Email (using Link)** | `Confirm your email for {{ friendly_name }}` |

## Installing

1. Auth0 Dashboard → **Branding** → **Email Templates** → pick the template from the table.
2. Turn on **Status**, set **From** (sending needs a custom email provider; see Branding → Email Provider), and paste the subject.
3. Paste the full HTML file into **Message**, then **Try** to send a test, and **Save**.
4. Optional: set **Redirect To** so people land back on a page after they verify. Without it, Auth0 shows its own success page.

`friendly_name`, `support_email`, `support_url`, `home_url` and `logo_url` come from **Settings** → **General** (tenant) and **Branding** → **Universal Login** (logo). Fill them in. Otherwise the template uses its fallbacks: the brand name defaults to "Expense Tracker", and the logo, support line and links are left out.

## Liquid variables used

| Variable | Used for |
| --- | --- |
| `url` | Verification link (button and plain-text fallback) |
| `user.email` | "Signing up as" chip |
| `user.given_name` | Greeting ("Hi Jane,"). Falls back to a plain welcome; database sign-ups usually don't have it |
| `friendly_name` | Brand name (`default: "Expense Tracker"`) |
| `logo_url` | Optional logo above the brand name |
| `home_url` | Brand link target |
| `support_url`, `support_email` | Optional "Need help?" footer line |

Every output goes through `| escape`.

## Design token mapping

Email clients can't read our Dart tokens, so the template hardcodes their values. It uses the light theme with the default teal accent. Tokens that have alpha in the app (`textSecondary`, `border`, `primarySoft`, …) are pre-blended into solid hex, because Outlook and Gmail handle `rgba` unreliably. If a token changes in `design_tokens.dart`, update it here too.

| Token | Light (inline) | Dark (`prefers-color-scheme`) |
| --- | --- | --- |
| `background` | `#F2F2F7` | `#000000` |
| `surface` (card) | `#FFFFFF` | `#1C1C1E` |
| `surfaceSecondary` (chip) | `#F2F2F7` | `#2C2C2E` |
| `primary` (teal, CTA fill) | `#00C896` | `#00C896` |
| `onAccent` (CTA label) | `#003328` | `#003328` |
| `primarySoft` (icon tile) | `#D1F5EC` | `#173B34` |
| `secondary` (links) | `#0A84FF` | `#0A84FF` |
| `textPrimary` | `#000000` | `#FFFFFF` |
| `textSecondary` | `#3C3C43` body / `#8A8A8E` small | `#98989E` |
| `textTertiary` (footer) | `#AEAEB2` | `#636366` |
| `border` / `divider` | `#E8E8E8` | `#3B3B3D` |
| `AppRadii.card` / `button` / `chip` | 20 / 16 / 12 px | same |
| `AppSpacing` | 4 / 8 / 12 / 16 / 20 / 24 / 32 px | same |
| Font | `-apple-system, 'SF Pro Text', 'Helvetica Neue', …` | same |

The CTA uses `onAccent` (dark text on teal), as the app's sticky save button does. White text on `#00C896` fails contrast at email body sizes.

## Compatibility notes

- Table-based layout with inline styles. The `<style>` block only adds the mobile, dark-mode and reset rules, so clients that strip it (some Gmail views) still render the light design correctly.
- Outlook for Windows gets a VML `v:roundrect` button and a fixed 560px wrapper.
- Dark mode works in Apple Mail, iOS Mail and Outlook.com/app (`[data-ogsc]`). Gmail applies its own colour inversion.
- The icon tile uses the ✉️ emoji instead of an image, so there's no remote asset to block or host.

## Previewing locally

Auth0's **Preview** tab renders the Liquid. To preview outside Auth0, render it with [liquidjs](https://liquidjs.com/) and sample data:

```bash
npx liquidjs --template "$(cat templates/email/auth0_verification_email.html)" \
  --context '{"url":"https://example.com/verify","user":{"email":"jane@example.com","given_name":"Jane"}}' > /tmp/preview.html
```
