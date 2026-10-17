# App Store privacy labels

These are the answers for App Store Connect → App Privacy. They're derived from the code as of 2026-10-17; the public policy is [PRIVACY_POLICY.md](./PRIVACY_POLICY.md). Re-check both whenever you add an SDK, a permission (`Info.plist` usage description), or a new table or column.

**Do you or your third-party partners use data for tracking?** No. There are no ad, analytics, or attribution SDKs (`pubspec.yaml`), and the app never reads the IDFA.

**Do you collect data?** Yes. Guest mode is on-device only, and Apple doesn't count on-device-only data as collected. Signed-in data goes to our server.

| Apple category → type | Collected | Linked to user | Tracking | Purpose | Source in code |
| --- | --- | --- | --- | --- | --- |
| Contact Info → Email Address | Yes | Yes | No | App Functionality | Supabase Auth; `export-data` emails it |
| Contact Info → Name | Yes | Yes | No | App Functionality | onboarding, Google/Apple metadata (`auth_service.dart`) |
| Financial Info → Other Financial Info | Yes | Yes | No | App Functionality | `transactions`, `accounts`, `category_budgets`, `recurring_events` |
| Identifiers → User ID | Yes | Yes | No | App Functionality | Supabase user id; also in API request logs |
| User Content → Other User Content | Yes | Yes | No | App Functionality | free-text `note` / `notes` fields, `counterparties` names |

**Not collected:** Payment Info and Credit Info (no card or bank numbers, and no bank linking), Health, Location, Sensitive Info, Contacts, Photos or Videos, Audio, Browsing / Search History, Usage Data (`onboarding_analytics.dart` counters never leave the device), Device ID, Purchases, and Diagnostics (no crash SDK).

**Judgement calls** (both answered "no" above; revisit if Apple review pushes back):
- **Diagnostics → Performance Data:** the API logs status and latency per user id (`docs/BACKEND.md#logs`). That's server operation, not data gathered from the device, but if you want the conservative answer, declare it as linked, App Functionality.
- **Photos:** a Google `avatar_url` is stored in Supabase user metadata. It's a link Google supplies, not a photo the user uploads, so it isn't declared.

**Google Play Data safety:** the same categories apply (Personal info: email, name, user IDs; Financial info: other; App activity: none). Data is encrypted in transit, and users can request deletion in the app.
