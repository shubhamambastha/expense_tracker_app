# Auth0 email templates

HTML templates for Auth0's transactional emails, styled to match the app's design system (`lib/config/design_tokens.dart`, see [docs/DESIGN.md](../../docs/DESIGN.md)). Auth0 renders them with LiquidJS. Before editing, read [AUTH0_LIQUID_REFERENCE.md](./AUTH0_LIQUID_REFERENCE.md), a copy of [Auth0's supported Liquid syntax](https://auth0.com/docs/customize/email/email-templates/supported-liquid-syntax). Only use the tags, filters and variables it lists for that template type.

| File | Auth0 template | Suggested subject |
| --- | --- | --- |
| [`auth0_verification_email.html`](./auth0_verification_email.html) | **Verification Email (using Link)** | `Confirm your email for {{ friendly_name \| default: "Expense Tracker" }}` |
| [`auth0_verification_code_email.html`](./auth0_verification_code_email.html) | **Verification Email (using Code)** | `{{ code }} is your {{ friendly_name \| default: "Expense Tracker" }} verification code` |
| [`auth0_welcome_email.html`](./auth0_welcome_email.html) | **Welcome Email** | `Welcome to {{ friendly_name \| default: "Expense Tracker" }}` |

Auth0 sends only one of the two verification emails, depending on the tenant's verification setting (link or code). Both share the same layout. The code version replaces the button and benefits list with a large code box and a "keep this code to yourself" warning, and puts the code in the inbox preview text.

Auth0 sends the welcome email after someone verifies their email address (or on their first social login). It greets them by first name, with their profile picture when Auth0 has one, and walks through three first steps that match the app: the post-login setup wizard, logging an expense (+ button or the iOS widget), and adding income so Spending Room has a number. The "Open Expense Tracker" button only appears when the tenant has `home_url` set. If you change onboarding, Spending Room or the widget, check this copy still matches [docs/FEATURES.md](../../docs/FEATURES.md).

## Installing

1. Auth0 Dashboard → **Branding** → **Email Templates** → pick the template from the table.
2. Turn on **Status**, set **From** (sending needs a custom email provider; see Branding → Email Provider), and paste the subject.
3. Paste the full HTML file into **Message**, then **Try** to send a test, and **Save**.
4. Link template only, optional: set **Redirect To** so people land back on a page after they verify. Without it, Auth0 shows its own success page. That field only accepts `application.name`, `application.clientID` and `application.callback_domain`, and custom Redirect To values aren't available on non-enterprise tenants created on or after May 5, 2026.

`friendly_name`, `support_email` and `support_url` come from **Settings** → **General** (tenant). Fill them in. Otherwise the template uses its fallbacks: the brand name defaults to "Expense Tracker" and the support line is left out.

## Liquid variables used

| Variable | Documented by Auth0 | Used for |
| --- | --- | --- |
| `url` | Yes (verification link template only) | Link template: verification link (button and plain-text fallback) |
| `code` | Yes (verification code template only) | Code template: code box, inbox preview text, suggested subject |
| `user.email` | Yes | Link template: "Signing up as" chip. Code template: intro sentence |
| `user.given_name` | Yes (untrusted) | Greeting ("Hi Jane," / "Welcome, Jane!"). Falls back to a plain welcome; database sign-ups usually don't have it |
| `user.picture` | Yes (untrusted) | Welcome template: avatar. Falls back to the 👋 tile when blank |
| `friendly_name` | Yes (tenant) | Brand name (`default: "Expense Tracker"`) |
| `support_url`, `support_email` | Yes (tenant) | Optional "Need help?" footer line |
| `logo_url`, `home_url` | **No.** Auth0's default template uses them, but the syntax doc doesn't list them | Optional logo, brand link and the welcome email's "Open" button, each rendered only when non-blank |

Every output goes through `| escape`. Every optional value is wrapped in `{% if … != blank %}` or `default`, so a missing value removes that element and never leaves an empty link.

The templates use only these Liquid features: `assign`, `if` / `else` (with `or` and `!= blank`), `comment`, and the `escape` and `default` filters.

## Design token mapping

Email clients can't read our Dart tokens, so the template hardcodes their values. It uses the light theme with the default teal accent. Tokens that have alpha in the app (`textSecondary`, `border`, `primarySoft`, …) are pre-blended into solid hex, because Outlook and Gmail handle `rgba` unreliably. If a token changes in `design_tokens.dart`, update it here too.

| Token | Light (inline) | Dark (`prefers-color-scheme`) |
| --- | --- | --- |
| `background` | `#F2F2F7` | `#000000` |
| `surface` (card) | `#FFFFFF` | `#1C1C1E` |
| `surfaceSecondary` (chip) | `#F2F2F7` | `#2C2C2E` |
| `primary` (teal, CTA fill, checkmarks) | `#00C896` | `#00C896` |
| `warning` (code template's share warning) | `#FF9500` | `#FF9500` |
| `onAccent` (CTA label) | `#003328` | `#003328` |
| `primarySoft` (icon tile) | `#D1F5EC` | `#173B34` |
| `secondary` (links) | `#0A84FF` | `#0A84FF` |
| `textPrimary` | `#000000` | `#FFFFFF` |
| `textSecondary` | `#3C3C43` body / `#8A8A8E` small | `#98989E` |
| `textTertiary` (footer) | `#AEAEB2` | `#636366` |
| `border` / `divider` | `#E8E8E8` | `#3B3B3D` |
| `AppRadii.card` / `button` / `input` / `chip` | 20 / 16 / 18 (code box) / 12 px | same |
| `AppSpacing` | 4 / 8 / 12 / 16 / 20 / 24 / 32 px | same |
| Font | `-apple-system, 'SF Pro Text', 'Helvetica Neue', …` | same |
| Code font (code template) | `ui-monospace, 'SF Mono', Menlo, Consolas, …` (the app has no mono token; numerals need fixed width) | same |

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
