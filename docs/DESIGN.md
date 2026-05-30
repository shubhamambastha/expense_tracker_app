# Design System

Premium dark theme for the Expense Tracker app. Source of truth lives in `lib/config/design_tokens.dart` and is wired into Material 3 via `lib/config/theme.dart`. Always reach for tokens — never hardcode hex values, durations, or radii in widgets.

---

## Foundations

### Brand voice
- **Premium** — generous spacing, soft shadows, single accent.
- **Calm** — high-contrast text on near-black surfaces; one accent at a time.
- **Responsive** — every interaction has a subtle spring; never harsh.

### File layout

Design tokens and theme wiring live in `lib/config/`. Shared UI primitives that enforce those tokens live under `lib/components/`. Category/chart styling and snackbars live in `lib/utils/`.

```
lib/
├── config/
│   ├── design_tokens.dart      # AppColors, AppRadii, AppShadows, AppDurations,
│   │                           # AppCurves, AppSpacing, AppTextStyles
│   └── theme.dart              # AppTheme.darkTheme — wires tokens into Material 3
├── utils/
│   ├── category_style.dart     # kCategoryColors, CategoryIcons, default seeds
│   └── snackbar_helper.dart    # SnackbarHelper — top-anchored feedback
├── components/
│   ├── common/
│   │   ├── compact_header.dart # Safe-area header shell (no full AppBar)
│   │   └── states/             # Empty, loading, error, offline, sync UX
│   │       └── states.dart     # Barrel export — import this in features
│   ├── settings/               # Settings rows, sections, subpage scaffold
│   ├── analytics/widgets/      # AnalyticsSectionCard, charts, metric tiles
│   ├── transaction/
│   │   ├── detail/widgets/     # DetailSectionCard, DetailInfoRow
│   │   └── …                   # Form fields, list items, type selectors
│   ├── home/dashboard/         # HeroOverviewCard, section headers, quick actions
│   ├── accounts/               # Account cards, swipe tiles, empty states
│   ├── recurring/              # Subscription/EMI cards, timeline tiles
│   ├── profile/                # Profile form fields, manage cards
│   ├── auth/                   # Login form
│   └── dialogs/                # Sheets and confirmation dialogs
└── screens/                    # Full pages — compose components, own navigation
    ├── home/expense_home_page.dart   # Tab shell + bottom nav + FAB
    ├── auth/                         # Login, splash
    ├── transaction/                  # Add/edit transaction
    ├── accounts/                     # Account list & detail
    ├── analytics/                    # Analytics tab
    ├── recurring/                    # Recurring payments manager
    └── settings/                     # Settings hub + sections/
```

Token classes are private-constructor (`AppColors._()`) static-only namespaces. Import them as `import '../../config/design_tokens.dart';` (adjust depth per file).

### Feature map

| Tab / area | Screen | Primary design primitives |
| --- | --- | --- |
| Home | `screens/home/expense_home_page.dart` | `CompactHeader`, `HeroOverviewCard`, dashboard sections, `states.dart` |
| Transactions | `components/home/transactions_content.dart` | `TransactionListItem`, filters, `EmptyStatePresets` |
| Add (+ FAB) | `screens/transaction/add_transaction_page.dart` | Form inputs, category/account chips, `StickyBottomCTA` |
| Analytics | `screens/analytics/analytics_page.dart` | `AnalyticsSectionCard`, chart widgets, `TimeRangeSelector` |
| Settings | `screens/settings/settings_page.dart` | `SettingsSection`, `SettingsTile`, `SettingsSubpageScaffold` |
| Accounts | `screens/accounts/` | `BankAccountCard`, `CreditCardCard`, `AccountsEmptyState` |
| Recurring | `screens/recurring/recurring_payments_page.dart` | `SubscriptionCard`, `EmiCard`, `UpcomingPaymentTile` |
| Detail sheets | `components/transaction/transaction_detail_sheet.dart` | `DetailSectionCard`, hero amount, action rows |

---

## Color

All colors are dark-mode only. The app is single-theme by design.

### Tokens

| Token | Hex | Usage |
| --- | --- | --- |
| `AppColors.background` | `#0F1115` | App scaffold, status bar, deepest layer |
| `AppColors.surface` | `#171A21` | Cards, dialogs, sheets, nav bar |
| `AppColors.surfaceSecondary` | `#1E232D` | Inputs, chips, nested fills, segmented tracks |
| `AppColors.primary` | `#00C896` | Primary actions, selected states, charts accent A |
| `AppColors.secondary` | `#00B8D9` | Secondary accents, recurring badges, charts accent B |
| `AppColors.textPrimary` | `#F5F7FA` | Headlines, body, icons |
| `AppColors.textSecondary` | `#A8B0BF` | Captions, labels, helper text, inactive icons |
| `AppColors.border` | `#262C36` | Card borders, dividers, input outlines |
| `AppColors.divider` | `#262C36` | Alias for border (semantic clarity) |
| `AppColors.danger` | `#FF5C7A` | Destructive actions, error text, delete swipe |
| `AppColors.warning` | `#FFB547` | Cautionary state, warning snackbars |
| `AppColors.success` | `#00C896` | Confirmation, success snackbars |

### Container tints

Pre-mixed dark fills used as soft accent backgrounds in destructive containers, success badges, etc.

| Token | Hex |
| --- | --- |
| `AppColors.primarySoft` | `#002820` |
| `AppColors.secondarySoft` | `#002632` |
| `AppColors.dangerSoft` | `#351720` |
| `AppColors.warningSoft` | `#3A2A12` |

### Usage rules

- **One accent per surface.** Don't mix `primary` and `secondary` as competing emphasis — pair them only in gradients or charts.
- **Text on surfaces:** always `textPrimary` for content, `textSecondary` for supporting text. Avoid raw white/grey.
- **Borders preferred over shadows.** Most cards combine `border` + a single subtle shadow; never use both heavy borders and dramatic elevation.
- **Semantic colors are reserved.** `danger`/`warning`/`success` must map to real meaning — don't reuse them for decoration.

---

## Typography

**Family:** Inter (bundled offline at `assets/fonts/Inter-*.ttf`, weights 400–900).

All text styles are exposed from `AppTextStyles`. Use them directly or via `Theme.of(context).textTheme.*` (already wired to the same scale in `AppTheme`).

### Scale

| Token | Size | Weight | Used for |
| --- | --- | --- | --- |
| `displayLarge` | 40 | 700 | Hero amounts on detail screens |
| `displayMedium` | 36 | 700 | Reserved |
| `displaySmall` | 32 | 700 | Dashboard totals, amount input |
| `headingLarge` | 24 | 600 | Page titles |
| `headingMedium` | 22 | 600 | Section headers |
| `headingSmall` | 20 | 600 | Card titles, sheet titles |
| `bodyLarge` | 16 | 500 | Primary body, list titles |
| `bodyMedium` | 14 | 500 | Default body, button labels |
| `bodySmall` | 14 | 400 | Secondary body |
| `caption` | 12 | 400 | Captions, helper text |
| `label` | 12 | 600 | Uppercase-ish labels, metric captions |
| `button` | 15 | 600 | Button labels (applied automatically by theme) |

### Rules

- Never set font family on a `TextStyle` — Inter is the app default.
- Prefer `AppTextStyles.*` for new widgets; `theme.textTheme.*` is fine for inherited components (it maps to the same tokens).
- Letter spacing is baked into display + heading tokens (slightly negative for premium feel). Don't override unless intentional.

---

## Radius

| Token | Value | Usage |
| --- | --- | --- |
| `AppRadii.card` | 20 | Cards, dialogs, sheets, surface containers |
| `AppRadii.button` | 16 | Buttons, FAB, icon-button containers, bottom-nav items |
| `AppRadii.input` | 18 | Text inputs, picker fields, date tiles |
| `AppRadii.chip` | 12 | Chips, tooltips, snackbars |
| `AppRadii.pill` | 999 | Pills, full-circular elements |

Helper `BorderRadius` constants exist for each (e.g. `AppRadii.cardRadius`). Use these in `BoxDecoration`, `RoundedRectangleBorder`, etc.

> **Don't** hand-roll `BorderRadius.circular(20)` — use `AppRadii.cardRadius` so a future refactor is one-line.

---

## Spacing

All padding/margin should reference `AppSpacing.*`.

| Token | px |
| --- | --- |
| `xs` | 4 |
| `sm` | 8 |
| `md` | 12 |
| `lg` | 16 |
| `xl` | 20 |
| `xxl` | 24 |
| `xxxl` | 32 |

Conventions:
- Card inner padding: `lg`–`xl`.
- Section gap inside a screen: `md`.
- Page padding: `lg` horizontal, `xxl` bottom.
- Tight rows (list items, inline icons): `sm`.

---

## Shadows

Very subtle — never neumorphic. Three variants:

| Token | Spec |
| --- | --- |
| `AppShadows.subtle` | `0px 2px 12px rgba(0,0,0,0.08)` — hover states, sticky bars |
| `AppShadows.card` | `0px 4px 20px rgba(0,0,0,0.18)` — default card lift (matches spec) |
| `AppShadows.elevated` | `0px 12px 28px rgba(0,0,0,0.20)` — dialogs, modals, FAB |

**Rules:**
- Pair every shadow with a `border` for crispness on dark surfaces.
- Don't stack multiple shadows on one element.
- Never use `Color.white` for inner highlights — use `AppColors.background` for cut-outs.

---

## Motion

Spring-based, premium, subtle. Always go through `AppDurations` and `AppCurves`.

### Durations

| Token | ms | Used for |
| --- | --- | --- |
| `AppDurations.micro` | 180 | Toggles, hover, selected state changes |
| `AppDurations.short` | 220 | Fade-ins, small reveals |
| `AppDurations.page` | 280 | Page transitions, surface swaps |
| `AppDurations.pageLong` | 350 | Longer page transitions |
| `AppDurations.reveal` | 600 | Chart/list reveal flourishes |

### Curves

| Token | Definition | Used for |
| --- | --- | --- |
| `AppCurves.spring` | `Cubic(0.2, 0.9, 0.25, 1.0)` | Default for micro-interactions |
| `AppCurves.easeOutQuint` | `Cubic(0.23, 1, 0.32, 1)` | Smooth, slow-finishing reveals |
| `AppCurves.emphasized` | `Cubic(0.2, 0, 0, 1)` | Page transitions |

### Packages

```yaml
flutter_animate: ^4.5.0   # declarative chained animations
animations: ^2.0.11       # OpenContainer, FadeThroughTransition
```

### Patterns

- **Entrance:** `.animate().fadeIn(duration: AppDurations.page).slideY(begin: 0.04, end: 0, curve: AppCurves.spring)`.
- **Tab switch:** wrap content in `AnimatedSwitcher` with `AppDurations.page` + `AppCurves.emphasized`.
- **Selected state:** `AnimatedContainer(duration: AppDurations.micro, curve: AppCurves.spring)`.
- **Pulse / breathing:** `.animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(begin: 1.0, end: 1.04, duration: 1800ms, curve: Curves.easeInOut)`.

---

## Iconography

- **Pack:** Material rounded icons (`Icons.*_rounded`). Chosen for stroke consistency, breadth, and existing Supabase wiring via `CategoryIcons` keys.
- **Sizes:** 16 (tight inline), 18 (list/tile), 20 (input prefix), 22 (nav), 26+ (hero).
- **Color:** `textPrimary` for chrome, `textSecondary` for inactive, accent for selected/semantic.
- **Containers:** square-rounded with a `colorAlpha(28–40)` background of the icon's accent — radius `10–14` depending on container size.

> Switching to Lucide or Phosphor later is a single-file change (`lib/utils/category_style.dart`) — the icon-by-key indirection is preserved.

---

## Components

Prefer existing shared widgets over one-off `Container` decorations. Each primitive below already applies the border + shadow + radius combo from the spec.

### Surface cards

| Widget | Location | Use for |
| --- | --- | --- |
| `AnalyticsSectionCard` | `components/analytics/widgets/` | Analytics sections; set `useGradient: true` for hero cards |
| `DetailSectionCard` | `components/transaction/detail/widgets/` | Nested panels on transaction detail (uses `surfaceSecondary`) |
| `SettingsSection` | `components/settings/` | Grouped settings rows inside a single card |
| `HeroOverviewCard` | `components/home/dashboard/` | Dashboard hero with budget progress semantics |

Raw surface pattern (when no shared widget fits):

```dart
Container(
  decoration: BoxDecoration(
    color: AppColors.surface,
    borderRadius: AppRadii.cardRadius,
    border: Border.all(color: AppColors.border),
    boxShadow: AppShadows.card,
  ),
  padding: const EdgeInsets.all(AppSpacing.lg),
  child: ...,
)
```

For premium hero cards, swap the flat color for a soft `LinearGradient(colors: [AppColors.surface, AppColors.surfaceSecondary])` — see `AnalyticsSectionCard` and `HeroOverviewCard`.

### App chrome

| Widget | Location | Use for |
| --- | --- | --- |
| `CompactHeader` | `components/common/` | Top safe-area strip on tab screens (used by `ExpenseHomePage`) |
| `SettingsSubpageScaffold` | `components/settings/` | Every settings sub-screen — back bar, scroll padding, entrance animation |

### State UX

Import the barrel once per feature:

```dart
import 'package:expense_tracker_app/components/common/states/states.dart';
```

| Widget | Use for |
| --- | --- |
| `EmptyState` + `EmptyStatePresets` | No-data lists and sections (`standard`, `compact`, `inline` layouts) |
| `LoadingState` + skeletons (`ShimmerBox`, `SkeletonCard`, `SkeletonTransactionRow`) | Initial load and inline refresh |
| `ErrorState` + `ErrorStatePresets` | Recoverable failures with retry CTA |
| `OfflineBanner` | Connectivity hint above content |
| `SyncIndicator` | Subtle sync-in-progress badge |
| `StateContentTransition` | Cross-fade between loading / empty / content |

### Settings rows

| Widget | Use for |
| --- | --- |
| `SettingsTile` | Tappable row with icon, optional `valueLabel`, chevron |
| `SettingsSwitchTile` | Toggle row |
| `SettingsInfoTile` | Read-only info row |
| `SettingsDangerSection` | Destructive actions grouped at bottom |

### Transaction form & list

| Widget | Use for |
| --- | --- |
| `TransactionTypeSelector` / `TransactionSubtypeChips` | Expense / income / transfer kind |
| `CategoryPillsSelector` / `IncomeCategoryPillsSelector` | Category pickers |
| `AccountChipsSelector` | Account selection |
| `AmountSection` | Hero amount input (`displaySmall`) |
| `StickyBottomCTA` | Primary save action pinned above keyboard |
| `TransactionListItem` | Unified row in home + transactions tab |

### Buttons

All button themes are pre-wired in `AppTheme.darkTheme`. Use them as-is:

- **`FilledButton`** — primary CTA. Background `primary`, foreground deep-teal `#003328`, radius `button`.
- **`OutlinedButton`** — secondary CTA. `border` outline, `textPrimary` label.
- **`TextButton`** — tertiary / inline. `primary` label.
- **`FloatingActionButton`** — gradient teal→cyan, soft primary glow, radius `button`.

Minimum height: 48. Default padding: `22 × 14`.

### Inputs

- Filled with `surfaceSecondary`, radius `input`, no border by default.
- Focused border: `primary` 1.4px.
- Error border: `danger` 1.4px.
- Always provide a `prefixIcon` for clarity (size 20).

### Cards

- Always `border: AppColors.border` + `AppShadows.card`.
- Nest inner panels with `surfaceSecondary` or `background` to layer depth.

### Bottom navigation

Implemented inline in `screens/home/expense_home_page.dart` (not `BottomNavigationBar`): rounded `card`-radius surface container, five slots (Home · Transactions · **+ FAB** · Analytics · Settings), items use `AnimatedContainer` with accent-tinted fill when selected. The centre `_AddExpenseFab` uses a teal→cyan gradient with a soft primary glow and a breathing scale animation.

Tab content switches via `AnimatedSwitcher` + `AppDurations.page` + `AppCurves.emphasized` in the same file.

### Dialogs & sheets

- Background `surface`, radius `card`, no surface-tint (M3 default removed).
- Drag handle on sheets is `border` colored.
- Bottom-sheet background must be set explicitly to `AppColors.surface` when calling `showModalBottomSheet` (Flutter still defaults to `surfaceContainerLow`).

### Snackbars

Use `SnackbarHelper` only — never call `ScaffoldMessenger` directly:

```dart
SnackbarHelper.showSuccess(context, 'Saved');
SnackbarHelper.showError(context, error);
SnackbarHelper.showWarning(context, 'Almost full');
SnackbarHelper.showMessage(context, 'Info');
SnackbarHelper.showWithUndo(context, message: 'Deleted', undoLabel: 'Undo', onUndo: () { ... });
```

Top-anchored overlay, spring-in, accent-bordered, ~2.4s lifetime (`showWithUndo` stays longer).

---

## Charts

- Palette: `kCategoryColors` (see `lib/utils/category_style.dart`) — leads with `primary` + `secondary`, then `warning`, `danger`, and a curated supporting set. Stays harmonised on dark.
- Track / grid: `AppColors.surfaceSecondary` or `AppColors.border` at low alpha.
- Highlight rings: `AppColors.background` (not white) for cut-outs.
- Animations: reveal with `AppCurves.easeOutQuint` over `AppDurations.reveal`.

---

## Accessibility

- All text styles meet WCAG AA contrast against the surfaces they're paired with (`textPrimary` on `surface` ≈ 14:1; `textSecondary` ≈ 6:1).
- Hit targets ≥ 44px on touch (buttons default 48).
- Never communicate state with color alone — pair semantic colors with an icon (snackbars already do this).
- Animations should respect `MediaQuery.disableAnimationsOf(context)` for future motion-reduction support.

---

## Adding a new screen

1. Scaffold with `backgroundColor: AppColors.background` (or wrap in `SettingsSubpageScaffold` for settings sub-pages).
2. Compose with token-based shared widgets from the tables above — never hardcode a hex, radius, duration, or font.
3. Use `AnalyticsSectionCard`, `SettingsSection`, or `DetailSectionCard` for surfaces; fall back to the raw `Container` pattern only when nothing fits.
4. Wire empty / loading / error through `states.dart` presets where applicable.
5. Apply a one-shot entrance: `fadeIn + slideY` (page) at the outermost block — see `SettingsSubpageScaffold` for the canonical pattern.
6. Use `SnackbarHelper` for all messaging, semantic variant matching the meaning.
7. Run `flutter analyze`; the project should remain clean.

---

## Changing a token

Every visual change should start in `lib/config/design_tokens.dart`. Updating a single value (e.g. nudging `AppRadii.card` from 20 → 24, or swapping `AppColors.primary`) propagates everywhere — including snackbars, FABs, charts, and segmented controls — because nothing else in the codebase hardcodes those values.

---

## Related docs

- [ARCHITECTURE.md](./ARCHITECTURE.md) — app structure, services, navigation
- [DATABASE_SCHEMA.md](./DATABASE_SCHEMA.md) — Postgres schema mind map
- [auth0_setup.md](./auth0_setup.md) · [supabase_setup.md](./supabase_setup.md) — backend setup
