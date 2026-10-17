# Supabase Auth email templates

Branded templates for the emails Supabase Auth sends, styled with the app's design tokens (`lib/config/design_tokens.dart`, see [docs/DESIGN.md](../../docs/DESIGN.md)) and the Jebbo mark + wordmark. Every template sends **only a code** (`{{ .Token }}`), never `{{ .ConfirmationURL }}`: the app has no auth deep links, and link scanners (e.g. Microsoft Safe Links) can use up a link before the user taps it.

| File | Supabase template | Subject | Verified in the app with |
| --- | --- | --- | --- |
| [`supabase_confirm_signup.html`](./supabase_confirm_signup.html) | **Confirm sign up** | `{{ .Token }} is your Jebbo verification code` | `verifyOTP(type: signup)` ✅ |
| [`supabase_invite_user.html`](./supabase_invite_user.html) | **Invite user** | `You're invited to Jebbo: your code is {{ .Token }}` | `verifyOTP(type: invite)` (no screen yet) |
| [`supabase_magic_link.html`](./supabase_magic_link.html) | **Magic link** | `{{ .Token }} is your Jebbo sign-in code` | `verifyOTP(type: email)` (no screen yet) |
| [`supabase_change_email.html`](./supabase_change_email.html) | **Change email address** | `{{ .Token }} is your Jebbo email change code` | `verifyOTP(type: emailChange)` (no screen yet) |
| [`supabase_reset_password.html`](./supabase_reset_password.html) | **Reset password** | `{{ .Token }} is your Jebbo password reset code` | `verifyOTP(type: recovery)` ✅ |
| [`supabase_reauthentication.html`](./supabase_reauthentication.html) | **Reauthentication** | `{{ .Token }} is your Jebbo confirmation code` | `updateUser(UserAttributes(password: …, nonce: code))` (no screen yet) |

Today the app only asks for the sign-up and reset codes ([auth_service.dart](../../lib/services/auth_service.dart)). The other four are ready for when those flows exist, so nothing goes out as Supabase's plain default.

With **Secure email change** on, Supabase sends the change-email template to both the current and the new address, each with its own code. The copy ("from `{{ .Email }}` to `{{ .NewEmail }}`") reads correctly for both.

## Installing

1. Supabase Dashboard → **Authentication** → **Emails** → **Templates** → pick the template from the table.
2. Paste the subject, then the whole HTML file into **Body**, and **Save**.
3. Send yourself one (sign up with a test address, or "Forgot password?") and check it in a real inbox.

## Logo hosting

Emails can't use the app's bundled assets, so the mark and wordmark load from this public repo: `https://raw.githubusercontent.com/shubhamambastha/expense_tracker_app/main/templates/email/assets/…` (3× PNGs in [`assets/`](./assets/), made from `assets/branding/`). They only resolve once this folder is on `main`. If the repo goes private or the logo moves, host the two PNGs somewhere public (e.g. a public Supabase Storage bucket) and replace that URL in all six files. When images are blocked, the wordmark's alt text shows "Jebbo".

## Template variables used

Supabase renders these with Go's `html/template` ([variables](https://supabase.com/docs/guides/auth/auth-email-templates#terminology)), which escapes every value and **strips HTML comments**, so the templates have no `<!-- -->` and no Outlook `<!--[if mso]>` blocks.

| Variable | Used for |
| --- | --- |
| `{{ .Token }}` | The code: code box and inbox preview text (and the subject) |
| `{{ .Email }}` | The account's address in the intro (the current address in the change-email template) |
| `{{ .NewEmail }}` | Change-email template only: the address being switched to |

## Design token mapping

Email clients can't read the Dart tokens, so the values are hardcoded. Tokens with alpha in the app are pre-blended into solid hex, because Outlook and Gmail handle `rgba` unreliably. If a token changes in `design_tokens.dart`, update it here too.

| Token | Light (inline) | Dark (`prefers-color-scheme`) |
| --- | --- | --- |
| `background` | `#F2F2F7` | `#000000` |
| `surface` (card) | `#FFFFFF` | `#1C1C1E` |
| `surfaceSecondary` (code box) | `#F2F2F7` | `#2C2C2E` |
| Accent options teal / blue / purple (gradient bar, same as the wordmark) | `#00C896` → `#0A84FF` → `#AF52DE` | same |
| `warning` ("keep this code to yourself") | `#FF9500` | `#FF9500` |
| `textPrimary` | `#000000` | `#FFFFFF` |
| `textSecondary` | `#3C3C43` body / `#8A8A8E` small | `#98989E` |
| `textTertiary` (footer) | `#AEAEB2` | `#636366` |
| `border` / `divider` | `#E8E8E8` | `#3B3B3D` |
| `AppRadii.card` / code box | 20 / 18 px | same |
| Font | `-apple-system, 'SF Pro Text', 'Helvetica Neue', …` | same |
| Code font | `ui-monospace, 'SF Mono', Menlo, Consolas, …` (digits need fixed width) | same |

## Compatibility notes

- Table layout with inline styles. The `<style>` block only adds the mobile, dark-mode and reset rules, so clients that strip it (some Gmail views) still render the light design.
- The gradient bar falls back to solid teal where `linear-gradient` isn't supported (Outlook for Windows).
- Dark mode works in Apple Mail, iOS Mail and Outlook.com/app (`[data-ogsc]`). Gmail applies its own colour inversion.
- The six files share one layout and differ only in title, intro, code label and the "didn't ask for this" lines. Change the layout in all six.

## Previewing locally

Render with Go's `html/template` and sample data, the same engine Supabase uses:

```go
t := template.Must(template.ParseFiles("templates/email/supabase_confirm_signup.html"))
t.Execute(os.Stdout, map[string]any{"Token": "482913", "Email": "jane@example.com", "NewEmail": "jane.new@example.com"})
```
