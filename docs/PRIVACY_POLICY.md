# Jebbo Privacy Policy

_Effective: 17 October 2026_

> **Before publishing:** fill in every `[BRACKETED]` value, then host this at a public URL (App Store Connect and Google Play both require one). This draft is generated from the codebase and is not legal advice. Have it reviewed if you operate at scale or in a regulated market.

Jebbo ("we", "us") is a personal expense tracker run by **[LEGAL NAME / COMPANY]**, **[ADDRESS]**. This policy explains what Jebbo collects, why, who else handles it, and what you can do about it.

**The short version:** Jebbo collects only what it needs to store your finances and sign you in. There are no ads, no analytics or tracking SDKs, and we never sell or share your data for advertising.

## 1. What we collect

### If you use Jebbo without an account (guest mode)

Everything you enter stays on your device. Nothing is sent to us. If you later sign in, Jebbo uploads that on-device data to your new account and then removes the local copy.

### If you create an account

| Data | Examples | Where it comes from |
| --- | --- | --- |
| **Account details** | Email address, password (stored only as a hash by our auth provider), and your account ID | You, at sign-up |
| **Name and profile picture** | Your name, and a profile picture link if you sign in with Google | You (onboarding), Google, or Apple. Apple shares your name only the first time you sign in, and only if you choose to share it |
| **Financial records you enter** | Transactions (amount, currency, date, category, merchant / payer name, notes), recurring payments and their reminders, accounts you create (name, type, provider name, nickname, notes, statement and due days), budgets, and custom categories | You |
| **Preferences** | Default currency, theme, accent colour, and whether you've finished onboarding | You |
| **Service logs** | For each request to our server: your account ID, the endpoint, the response status and timing. Logs never include your financial data, request bodies, or sign-in tokens | Automatically, when the app talks to our server |

Jebbo does **not** connect to your bank, and never asks for card numbers, bank account numbers, or government IDs. It does not access your location, contacts, photos, camera, microphone, or advertising identifier.

### Stored on your device

Your sign-in session is kept in the iOS Keychain or Android Keystore. App settings and a few local counters (for example, how many onboarding steps you skipped) stay on your device and are never sent to us.

## 2. How we use it

- To provide the app: store and sync your records, and show your dashboards, budgets, and insights. All calculations happen in the app.
- To sign you in and keep your account secure, including emailing you verification and password-reset codes.
- To email you a CSV export of your data when you ask for one.
- To run and fix the service, using the logs described above.

We do not use your data for advertising or profiling, and we don't sell it. **Legal basis (GDPR / UK GDPR):** we process your data to perform our contract with you (running the app), and for our legitimate interest in keeping the service secure and working (logs).

## 3. Who else handles your data

We rely on these service providers (processors). Each one handles your data only to provide its service to us:

| Provider | What it does | Data involved |
| --- | --- | --- |
| **Supabase** | Database and authentication (region: **[SUPABASE REGION]**) | Everything in section 1 for account holders |
| **Railway** | Hosts our API server (region: **[RAILWAY REGION]**) | Data in transit to the database; service logs |
| **Resend** | Sends the "Export Data" email | Your email address and the CSV files of your data |
| **Google** / **Apple** | Sign-in, only if you choose it | Sign-in is handled by Google or Apple under their own privacy policies. They share your email and name with us, and Google also shares your profile picture |
| **[EMAIL PROVIDER FOR AUTH EMAILS, e.g. Supabase's built-in mailer or your SMTP provider]** | Sends verification and password-reset codes | Your email address |

We may also disclose data if the law requires it, or as part of a merger or acquisition (we'll tell you first if that happens).

**International transfers:** these providers may process data outside your country. Where the law requires it, the transfers are covered by the providers' Standard Contractual Clauses or an equivalent safeguard.

## 4. How long we keep it

- **Account data:** for as long as your account exists.
- **When you delete your account** (Settings → Data & Privacy → Delete Account): we immediately delete all of your records and then your login. Copies in our database provider's backups are removed within **[BACKUP RETENTION, e.g. 7 days]**.
- **Reset Account** deletes your records but keeps your login.
- **Service logs:** kept for **[LOG RETENTION, e.g. 30 days]**, then deleted.
- **Guest data:** stays on your device until you delete the app or reset it.

## 5. Your rights

You can do all of the following yourself in the app:

- **Access / portability:** Settings → Data & Privacy → Export Data emails all of your records to you as CSV files.
- **Correction:** edit any record, or your profile, in the app.
- **Deletion:** Delete Account removes everything (see section 4).

Depending on where you live, you may also have the right to object to or restrict processing, withdraw consent, or complain to your data protection authority. This includes rights under the GDPR / UK GDPR (EU and UK), the CCPA / CPRA (California), and India's Digital Personal Data Protection Act. **California residents:** we do not sell or "share" personal information as the CCPA defines those terms, and we don't use sensitive personal information to infer characteristics about you. To exercise any of these rights, email us (see section 9). We won't treat you differently for doing so.

## 6. Security

All traffic between the app and our server uses HTTPS. Each request is checked against your sign-in token, and the database enforces row-level security so that one user cannot read another user's data. Your session token is stored in your device's secure keystore. No system is perfectly secure, but we'll notify you and the relevant authorities of a breach if the law requires us to.

## 7. Children

Jebbo is not directed at children under **[13 / 16]**, and we don't knowingly collect their data. If you believe a child has created an account, contact us and we'll delete it.

## 8. Changes

If we change this policy, we'll update the date above. If the change is significant, we'll also tell you in the app before it takes effect.

## 9. Contact

**[SUPPORT EMAIL]**, **[LEGAL NAME / COMPANY]**, **[ADDRESS]**.
