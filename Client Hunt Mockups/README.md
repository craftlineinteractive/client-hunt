# ClientHunt — UI Reference & Build Specification

This document is the single source of truth for every prompt after A1. It records what the approved
mockups contain, which values are authoritative, and how the Flutter build resolves the places where the
mockups disagree with each other or with `DESIGN.md`.

> **Read this first:** `DESIGN.md` is **obsolete for color**. It describes an indigo/teal system
> (`#4F46E5`, `#0D9488`, status colors, gradients). The approved screens are strictly monochrome. Only
> the typography families, the spacing scale, the radius scale and the motion durations from `DESIGN.md`
> survive; every color in this document comes from the `code.html` files.

---

## 1. Overview

### 1.1 What the app is

ClientHunt is a B2B lead-generation app for Android, built for freelancers, agencies and small sales
teams in India. A user types a niche and a city, the app finds local businesses, extracts public contact
details (phone, email, website, social profiles) and lets the user save, tag, track and export those
leads as a simple on-device CRM.

- Application ID / namespace: `com.craftlineinteractive.clienthunt`
- Dart package: `clienthunt`
- App label: `ClientHunt`
- Portrait only, Android first
- Offline-first: leads and CRM state live on the device (local data layer arrives in prompt C)

### 1.2 The eight approved screens

| # | Folder | Screen | Role | Bottom nav |
|---|--------|--------|------|-----------|
| 1 | `home_screen/` | Search (home) | Niche + location entry, sources, quick filters, recent searches | Yes (Search active) |
| 2 | `search_results/` | Search results | Scannable lead list with bulk selection and export entry | No (pushed) |
| 3 | `lead_detail/` | Lead details | Full lead profile, contact actions, notes, tags, status, reminder | No (pushed) |
| 4 | `saved_leads/` | Saved leads | On-device CRM pipeline with lists, statuses, bulk actions | Yes (Saved active) |
| 5 | `search_filters/` | Search filters | Pre-search precision tuning (contact, quality, keywords, area, results, cleanup) | No (modal sheet) |
| 6 | `export_leads/` | Export leads | Scope, format, columns, file name, cleanup, quick copy | No (pushed) |
| 7 | `go_pro/` | ClientHunt Pro | Paywall: three plans, feature list, comparison, sample reviews | No (pushed) |
| 8 | `settings/` | Settings | Theme, defaults, storage, privacy/ads, support, legal | Yes (Settings active) |

### 1.3 How to read the folder

Each screen folder contains exactly two files:

- **`code.html` — source of truth.** All exact values live here: hex colors, pixel sizes, spacing,
  radii, font sizes/weights, copy text and Material icon names. When this document and a mockup
  disagree, `code.html` wins (except where Section 8 records a deliberate resolution).
- **`screen.png` — visual reference.** A 390 × 844 render of both frames, used to judge composition,
  density and hierarchy. PNGs are never a source for a hex value or a pixel size.
- **`DESIGN.md`** (folder root) — typography families, spacing scale, radius scale, motion durations
  only. Its color, elevation and component sections are superseded.

### 1.4 How the two frames are organized

Every `code.html` renders two phone frames side by side at 390 × 844 CSS px:

- **Frame 1 — Light Mode.** Comment marker `FRAME 1: LIGHT MODE`. Background `#FFFFFF`, primary
  `#111111`.
- **Frame 2 — Dark Mode.** Comment marker `FRAME 2: DARK MODE`. Background `#0A0A0A`, primary
  `#FAFAFA`.

The two frames are near-duplicates that swap color tokens. They differ in a few places, and the dark
frames are **not uniformly well built**:

- `home_screen` and `search_results` have correct, consistent dark frames. These are the authority for
  the dark palette.
- `lead_detail`'s dark frame is effectively a second light frame (it keeps `#FFFFFF` surfaces and
  `#111111` text).
- `saved_leads`, `search_filters`, `export_leads` and `settings` mix light values into their dark
  frames (`#F5F5F5`, `#E5E5E5`, `#111111` on dark surfaces).
- `go_pro` uses a hand-written off-palette dark set (`#0d0e11`, `#14161b`, `#242730`, `#9da3ae`,
  `#4b5262`).

**Resolution:** the dark theme is normalized to the `home_screen` / `search_results` values (Section 2),
and every dark frame in the mockups is interpreted through that palette. Section 8 lists the specific
substitutions.

### 1.5 Non-negotiable rules that override the mockups

These come from the product owner and win over any mockup value that contradicts them:

1. **Strictly monochrome** — black, white and neutral grays. No hue anywhere. Errors, success and
   warnings are expressed with an icon plus text weight, never color.
2. **Light and dark are both first-class.** Every shared widget must be correct in both.
3. **No UI text below 13 px; every touch target at least 48 px.** The mockups contain 10–12 px labels
   and 28–44 px controls. In Flutter the *visual* box keeps the mockup size where it is safe, but the
   label is raised to 13 px and the *tap target* is expanded to 48 px with transparent padding.
4. **Real vector icons only**, from Flutter's built-in rounded Material set (`Icons.*_rounded`). Never
   render an icon name as text.
5. **Fonts** — Plus Jakarta Sans (headings), Inter (body/UI), JetBrains Mono (emails, phones, domains,
   codes) via `google_fonts`.
6. **No gradients, no illustrations, no fake urgency, no color accents.**

---

## 2. Design tokens

### 2.1 Color — core roles

Every role below is implemented in `lib/core/theme/app_colors.dart` as a `ThemeExtension` (`AppColors`),
with `AppColors.light` and `AppColors.dark` instances.

| Role | Token | Light | Dark | Where it is used |
|------|-------|-------|------|------------------|
| Background | `background` | `#FFFFFF` | `#0A0A0A` | Phone/screen body on home, detail, export, settings, saved |
| Canvas / list background | `canvas` | `#FAFAFA` | `#0A0A0A` | Search results list body, filters body, settings body, lead-detail hero card |
| Surface | `surface` | `#F5F5F5` | `#141414` | Grouped input fill, unselected chip fill, segmented-control track, pill backgrounds |
| Card | `card` | `#FFFFFF` | `#171717` | All cards, list rows, result cards, plan rows (dark) |
| Card subtle | `cardSubtle` | `#FAFAFA` | `#141414` | Plan rows (light), review cards, fact tiles, section header rows |
| Border | `border` | `#E5E5E5` | `#2A2A2A` | 1 px card/input/chip outlines, app bar and bottom nav top border |
| Divider | `divider` | `#E5E5E5` | `#262626` | Row dividers inside cards and lists |
| Divider subtle | `dividerSubtle` | `#F0F0F0` | `#1F1F1F` | Hairline dividers on saved/settings/filters/export (`#F0F0F0`, `#F5F5F5`) |
| Primary | `primary` | `#111111` | `#FAFAFA` | Filled buttons, selected chips, selected toggles, active nav pill, selected segment |
| On primary | `onPrimary` | `#FFFFFF` | `#111111` | Text/icons on primary |
| Text primary | `textPrimary` | `#111111` | `#FAFAFA` | Headings, values, names |
| Text secondary | `textSecondary` | `#525252` | `#A3A3A3` | Supporting labels, icons inside rows, unselected chip text |
| Text muted | `textMuted` | `#8A8A8A` | `#737373` | Captions, metadata, placeholders, "Not set", timestamps |
| Disabled fill | `disabled` | `#D4D4D4` | `#404040` | Off track of switches, disabled checkbox border, disabled control fill |
| Disabled foreground | `disabledForeground` | `#B0B0B0` | `#525252` | Disabled icons/labels |
| Inverse surface | `inverseSurface` | `#111111` | `#FAFAFA` | Selection action bar, Pro status card, tooltips, snackbars |
| On inverse surface | `onInverseSurface` | `#FAFAFA` | `#111111` | Text/icons on inverse surfaces |
| Shadow | `shadow` | `#000000` @ 4–6% | transparent | Soft card shadow in light; none in dark |

### 2.2 Overlay alphas

The mockups only ever express interaction states as flat grays (`hover:bg-[#F5F5F5]`,
`active:bg-[#E5E5E5]`, `#262626` / `#333333` in dark). Converted to overlays on the surface beneath:

| Role | Light | Dark | Mockup evidence |
|------|-------|------|-----------------|
| `overlayHover` | black @ 4% | white @ 6% | `#FFFFFF → #F5F5F5` (light), `#171717 → #262626` (dark) |
| `overlayPressed` | black @ 8% | white @ 10% | `#F5F5F5 → #E5E5E5` (light), `#262626 → #333333` (dark) |
| `overlayFocus` | black @ 12% | white @ 14% | Focus wash; focus border switches to `primary` |
| `overlayScrim` | black @ 40% | black @ 60% | Bottom sheets and dialogs |

Focus is also shown with a 2 px `primary` ring offset 2 px on inputs and keyboard focus.

### 2.3 Other grays that appear in the mockups

These are **not** new tokens. They are the same neutrals expressed inconsistently (three families are in
play: neutral, zinc and slate). Each maps to the nearest role above.

**Light frames**

| Hex | Frequency / where | Maps to |
|-----|-------------------|---------|
| `#FAFAFA` | Search-results body, hero card, plan rows, review cards, chips' selected label | `canvas` / `cardSubtle` |
| `#F9F9F9` | Saved-card status pill fill, ad strip, quick-copy hover | `cardSubtle` |
| `#F7F7F7` | Selected CSV format tile | `surface` |
| `#F5F5F5` | Grouped fields, chips, off rows, dividers in export | `surface` / `dividerSubtle` |
| `#F4F4F5` | Filters: segmented track, keyword chips (zinc-100) | `surface` |
| `#F2F2F2` | Export: count badge behind "42" | `surface` |
| `#F0F0F0` | Soft dividers (saved, settings, filters), icon tiles, segmented track, settings nav pill | `dividerSubtle` / `surface` |
| `#EBEBEB` | Lead-detail initials tile, saved count-pill border, export card border | `surface` / `border` |
| `#EAEAEA` | Pressed icon-button state, format-tile icon tile | `overlayPressed` |
| `#E5E5E5` | Borders, dividers, disabled fills, ad "Ad" tag | `border` / `divider` |
| `#E4E4E7` | Filters: slider track, off switch track (zinc-200) | `disabled` |
| `#DCDCDC` | Export: unselected column chip border | `disabled` |
| `#D8D8D8` | Export: off toggle track | `disabled` |
| `#D4D4D4` | Badge borders, disabled text, dashed borders | `disabled` |
| `#C5C5C5` | Export: unselected radio border | `disabledForeground` |
| `#CCCCCC` | Export: file-name / secondary button border, "Coming soon" pill | `disabled` |
| `#BBBBBB` | go_pro: unselected plan radio | `disabledForeground` |
| `#B0B0B0` | Saved: checkbox border, disabled action icon, dashed "New list" border | `disabledForeground` |
| `#A1A1AA` | Filters: slider min/max labels, placeholder (zinc-400) | `textMuted` |
| `#8A8A8A` | Muted captions, "Saved 2d ago", chevrons | `textMuted` |
| `#888888` | Export: count badges, file-name icon, summary icon | `textMuted` |
| `#828A96` | go_pro frame label (outside the phone) | n/a — documentation chrome |
| `#777777` | Export: format subtitle, footer notice | `textMuted` |
| `#71717A` | Filters: secondary labels, "Reset", inactive segment (zinc-500) | `textSecondary`/`textMuted` |
| `#666666` | Export/settings: section overlines, plan detail | `textSecondary` |
| `#555555` | Settings row values, go_pro "Restore" | `textSecondary` |
| `#525252` | Standard secondary text | `textSecondary` |
| `#444444` | Export: unselected scope labels, footer links | `textSecondary` |
| `#333333` | Settings row icons, review body text | `textPrimary` |
| `#222222` | Export/settings row labels, plan table cells | `textPrimary` |
| `#111111` | Primary text, fills | `textPrimary` / `primary` |
| `#000000` | Active pressed button, notch | `primary` (pressed) |

**Dark frames**

| Hex | Where | Maps to |
|-----|-------|---------|
| `#FAFAFA` | Primary text, primary fill | `textPrimary` / `primary` |
| `#E5E5E5` | lead_detail dark frame's light leftovers; go_pro feature text | `textPrimary` |
| `#A3A3A3` | Secondary text/icons | `textSecondary` |
| `#9DA3AE` | go_pro: subtitles, table headers | `textSecondary` |
| `#8B929E` | go_pro: coming-soon row, muted | `textMuted` |
| `#737373` | Muted captions, nav inactive | `textMuted` |
| `#525252` | Disabled foreground | `disabledForeground` |
| `#4B5262` | go_pro: unselected plan radio | `disabledForeground` |
| `#404040` | Disabled fill / off track | `disabled` |
| `#3F4452` | go_pro: "Coming soon" pill border | `border` |
| `#333333` | Pressed surface | `overlayPressed` |
| `#2E2E2E` | saved_leads card border variant | `border` |
| `#2A2A2A` | Card/input/chip border, frame border | `border` |
| `#27272A` | Filters: phone frame ring (zinc-800) | outside app chrome |
| `#262626` | Dividers, nav border, export button count pill, pressed fill | `divider` / `overlayPressed` |
| `#242730` | go_pro: plan/section card border | `border` |
| `#242424` | Export: card border variant | `border` |
| `#222222` | Phone frame border (mockup chrome) | outside app chrome |
| `#212121` | Filters: card variant | `card` |
| `#202020` | Settings: card variant | `card` |
| `#1F1F1F` | Divider subtle, tag fill | `dividerSubtle` |
| `#1E1E1E` | Export: card variant | `card` |
| `#1C1C1C` | saved_leads: card variant | `card` |
| `#1A1A1A` | Inner field group variant | `surface` |
| `#191C22` | go_pro: selected plan row | `card` |
| `#191919` | lead_detail: inner group | `surface` |
| `#171717` | Cards, inner field groups, hover fill | `card` |
| `#151515` | Settings: card variant | `card` |
| `#14161B` | go_pro: section/plan card | `card` |
| `#141414` | Surface, unselected chips, selected plan row (light-on-dark) | `surface` |
| `#0D0E11` / `#0B0C0E` | go_pro frame / page backdrop | n/a — documentation chrome |
| `#0A0A0A` | App background | `background` |
| `#60A5FA` | go_pro header chip dot — **BLUE, banned** | `textMuted` neutral dot |

The `.dart` implementation exposes exactly the roles in 2.1/2.2; the rest of this table exists so future
prompts can translate any stray value they find in a mockup.

### 2.4 Typography

Three families, loaded with `google_fonts`: **Plus Jakarta Sans** (headings), **Inter** (body and UI),
**JetBrains Mono** (emails, phones, domains, codes). Mono styles use
`FontFeature.tabularFigures()`.

| Token | Family | Size | Weight | Line height | Tracking | Where |
|-------|--------|------|--------|-------------|----------|-------|
| `headlineLg` | PJS | 26 | 700 | 32 | −0.01 em | Home question "Who are you looking for?" |
| `headlineMd` | PJS | 24 | 700 | 32 | −0.02 em | Paywall title "ClientHunt Pro" |
| `headlineSm` | PJS | 22 | 700 | 28 | −0.02 em | Settings title |
| `titleLg` | PJS | 20 | 700 | 28 | −0.01 em | "Saved leads", wordmark |
| `titleMd` | PJS | 18 | 700 | 26 | −0.01 em | Pushed app-bar titles ("Filters", "Export leads"), lead-detail name |
| `titleSm` | PJS | 16 | 600 | 24 | 0 | Result-card names, app-bar titles, Pro card title |
| `titleXs` | PJS | 15 | 600 | 22 | 0 | Saved-card names, primary button labels |
| `bodyLg` | Inter | 16 | 400 | 24 | 0 | Long copy, input text |
| `bodyMd` | Inter | 14 | 400 | 20 | 0 | Row labels, feature text, notes |
| `bodySm` | Inter | 13 | 400 | 18 | 0 | Captions, metadata, secondary rows |
| `labelLg` | Inter | 14 | 500 | 20 | 0 | Chips, quick filters, segmented labels |
| `labelMd` | Inter | 13 | 500 | 18 | 0 | Settings labels, card metadata, captions |
| `labelSm` | Inter | 13 | 600 | 18 | +0.02 em | Badges, pills, overlines (uppercase at call site) |
| `monoMd` | JB Mono | 14 | 400 | 20 | 0 | Result-card contact values |
| `monoSemibold` | JB Mono | 14 | 500 | 20 | 0 | Lead-detail contact values, counts |
| `monoSm` | JB Mono | 13 | 400 | 18 | 0 | Badges (source), timestamps, "5 filters active", min/max labels |
| `button` | PJS | 15 | 600 | 20 | 0 | Primary/secondary buttons |

**Minimum 13 px.** The mockups use 10 px (filter count bubble, ad tag), 11 px (Pro sources label,
"PRO" badges, bottom-nav labels, nav labels in settings, review "Play store" label) and 12 px
(Pro pill, profiles Pro chip, stats labels, ad copy). All of these are raised to **13 px** in Flutter.
Sizes are otherwise preserved.

### 2.5 Spacing scale

4 px base (`lib/core/theme/app_spacing.dart`):

| Token | Value | Use |
|-------|-------|-----|
| `xs` | 4 | Icon-to-label micro gap, dot gaps |
| `sm` | 8 | Chip gaps, stacked label pairs, list-row gaps |
| `md` | 12 | Card inner gaps, between related controls |
| `lg` | 16 | Screen padding, card padding, section gaps |
| `xl` | 20 | Between form sections |
| `xxl` | 24 | Major block separation |
| `xxxl` | 32 | Empty-state / large separation |
| `huge` | 48 | Screen-level separation |

Screen padding is 16 px horizontally. Card padding is 12–16 px (12 for dense cards, 14 for result
cards, 16 for section cards). Section gap is 12–16 px; list gap between cards is 8–12 px.

### 2.6 Radius scale

| Token | Value | Use |
|-------|-------|-----|
| `sm` | 8 | Small badges, inner segmented option, tiny tags, checkboxes (4 in mockups, 4 is allowed for checkboxes) |
| `md` | 12 | Inputs, action buttons, icon tiles, contact cards, sheets' inner rows |
| `tile` | 14 | Initials tiles, 52 px action buttons on detail, primary button on detail |
| `lg` | 16 | Cards, result cards, primary CTA on home/results, plan rows |
| `xl` | 20 | Bottom sheets, dialogs |
| `pill` | 999 | Chips, badges, status pills, switches, segmented track, nav pill |

Checkboxes are 4 px; radios are circular.

### 2.7 Borders, elevation, shadows

- Every card, input, chip and list container has a **1 px border** in `border`.
- **Light:** cards add a soft shadow — `0 1px 3px rgba(0,0,0,0.04)` (cards), sticky bars use
  `0 -4px 16px rgba(0,0,0,0.06)`, the paywall's selected plan row uses `0 4px 16px rgba(0,0,0,0.05)`.
  Use `AppCard` which applies it (and skips it in dark).
- **Dark:** **no shadows at all.** Depth comes from surface lightness steps
  (`#0A0A0A → #141414 → #171717 → #1F1F1F`) plus 1 px borders.
- App bars, bottom nav and sticky bars are flat with a single 1 px top/bottom border.
- No gradients anywhere. The saved-leads mockup has a right-edge
  `linear-gradient(#FFFFFF → transparent)` fade on the list-chip row; that is a scroll affordance, not
  decoration, and is **removed** in the Flutter build (the row simply clips at the padding edge).

### 2.8 Motion

| Token | Duration | Curve | Use |
|-------|----------|-------|-----|
| `micro` | 100 ms | `cubic-bezier(0.4, 0, 0.2, 1)` | Hover/press, toggle thumb, chip select |
| `standard` | 200 ms | `cubic-bezier(0.16, 1, 0.3, 1)` | Expand/collapse, tab change, snackbar |
| `structural` | 300 ms | `cubic-bezier(0.16, 1, 0.3, 1)` | Page push, bottom sheet, dialog |

### 2.9 Icons

Rounded Material icons only (`Icons.*_rounded`), matching the mockups' *Rounded* family. The mockups mix
*Outlined* and *Rounded*; Flutter uses Rounded everywhere.

| Size | Use |
|------|-----|
| 16 | Inline indicators, badges, checkmarks inside chips, chevrons |
| 18 | Chip icons, contact-row icons, small actions |
| 20 | Field leading icons, app-bar actions, list icons, contact-row glyphs (cards) |
| 22 | Bottom-nav icons, default `IconTheme` size |
| 24 | Pushed app-bar leading/actions, detail action buttons |
| 28 | Paywall hero tile |
| 32 | Empty state |

No icon is ever rendered as text. (In `search_results/code.html` the names `call`, `mail` and
`language` appear as literal strings inside contact rows — that is an icon-font loading bug in the HTML,
not the design. They are icons in Flutter.)

---

## 3. Global patterns

### 3.1 App bars — two variants

**Tab title bar** (`AppTopBar.tab`) — height 56, horizontal padding 16, no back button, title at
`titleLg` (20/700) or `headlineSm` (22/700) on the left, up to two 40 px icon buttons on the right,
1 px bottom border in `border`. Examples: "ClientHunt" wordmark + Pro pill + settings; "Saved leads"
with count pill; "Settings".
Wordmark variant: `filter_center_focus_rounded` 20 px + "ClientHunt" in `titleLg` weight 800.

**Pushed screen bar** (`AppTopBar.pushed`) — height 56, 40 px leading button (`arrow_back_rounded` or
`close_rounded`), title at `titleSm`/`titleMd`, optional 13 px muted subtitle under the title, up to
three 40 px icon actions (`search_rounded`, `more_vert_rounded`, `share_rounded`, bookmark), 1 px bottom
border. Examples: results (back, title + "42 leads · Maps", search, more), lead details (back, title,
bookmark filled, share, more), filters/export (close + title + text action), paywall (close, "Restore"
text action). Every leading slot keeps a 48 px tap target.

Hairline borders: `#E5E5E5` light / `#2A2A2A` dark. No elevation, no scrolled-under tint (transparent
surface tint).

### 3.2 Bottom navigation (three tabs)

`AppBottomNav` reads `navTabs` from `lib/core/constants/nav_tabs.dart` — the single list constant.

| Tab | Icon (inactive) | Icon (active) | Route |
|-----|-----------------|---------------|-------|
| Search | `search_rounded` | `search_rounded` (filled look) | `/search` |
| Saved | `bookmark_border_rounded` | `bookmark_rounded` | `/saved` |
| Settings | `settings_rounded` | `settings_rounded` | `/settings` |

- Height 64 (+ safe area). Background `background`, 1 px top border `border`.
- Inactive: icon 22 + label 13/500 in `textMuted` (mockups use `#8A8A8A` / `#737373`).
- Active: icon inside a **pill indicator** 40 × 28, fill `primary`, icon `onPrimary`; label 13/600 in
  `textPrimary`. (Saved-leads mockups use a 40×28 pill; home uses `px-2.5 py-0.5` ≈ 34×26. Use 40×28.)
- Labels are always visible. Tap targets are full 48+ px wide columns.
- The mockup's four-tab version includes **History**, for which there is no approved screen; the build
  has three tabs (Section 8, decision b).

### 3.3 Chips

`AppChip` — pill, height 36 (quick filters, columns) or 44 (source pills, list filters), horizontal
padding 12–14, optional leading icon 16–18, optional trailing count (mono 13), optional lock 16.

| State | Light | Dark |
|-------|-------|------|
| Selected | fill `#111111`, text `#FFFFFF`, optional check icon | fill `#FAFAFA`, text `#111111` |
| Unselected | fill `#F5F5F5`, 1 px `#E5E5E5`, text `#111111` (home popular niches) **or** fill `#FFFFFF`, 1 px `#E5E5E5`, text `#525252` (results/quick filters) | fill `#171717`, 1 px `#2A2A2A`, text `#FAFAFA` **or** fill `#141414`, text `#A3A3A3` |
| Locked / Pro | fill `#F5F5F5`, border `#E5E5E5`, text `#525252`, lock icon `#8A8A8A` | fill `#141414`, border `#2A2A2A`, text `#A3A3A3`, lock `#737373` |
| Disabled | 40% opacity over the unselected style | same |
| Dashed "add" | dashed 1 px `#8A8A8A` / `#B0B0B0`, fill `#FAFAFA`, `add_rounded` 16 | dashed `#404040`, fill `#141414` |

Selected chips with a count render the count in mono 13 at 80% opacity of the label color.

### 3.4 Badges and pills

- **Pro badge** — pill, height 24, fill `primary`, text `onPrimary` at 13/600, `lock_rounded` 16.
  Appears in the home app bar (with `workspace_premium_rounded` instead of the lock), on the paywall
  header, on the profiles card, on locked filters ("PRO"), on locked depth/result options.
- **Free badge** — pill, height 24, fill `surface`, 1 px `border`, text `textSecondary` 13/600.
- **Source badge** ("Maps", "Instagram", …) — height 24, 1 px `border`, fill `surface`, mono 13,
  text `textSecondary`. In result rows it sits between dot separators.
- **Status pill** (New / Contacted / Replied / Closed) — height 24, pill, 1 px border, 13/600.
  New: border `primary`, text `primary`, fill `#F9F9F9` / `#1F1F1F`. Contacted: border `#B0B0B0`,
  text `#525252`, fill `#FAFAFA` / `#141414`. Replied: border `primary`, text `primary`, fill `surface`.
  Closed: border `#D4D4D4`, text `#737373`, fill `#F5F5F5` / `#141414`. Differences are border/surface
  contrast plus weight, never hue.
- **Count pill** — "128" beside "Saved leads": mono 13, fill `surface`, 1 px `#EBEBEB` / `#2A2A2A`.

### 3.5 Cards

`AppCard` — radius 16, 1 px `border`, fill `card`, padding 12–16, soft shadow in light only.
Variants used: search card (p16), result card (p14), section card (p16), saved card (p12), fact tile
(radius 12, p10, fill `cardSubtle`), plan row (radius 16, min height 72, p14, fill `cardSubtle`; selected
state = 2 px `primary` border, fill `card`, shadow in light only), review card (radius 16, p14, width
≈ 264, fill `cardSubtle`).

Dense list rows live inside one card with `divider` hairlines between rows (contact details, settings
groups, profiles, recent searches, scope options).

### 3.6 Inputs

- **Grouped field** (home niche/location): container radius 12, fill `surface`, 1 px `border`, rows
  52 px high, 14 px horizontal padding, leading icon 20 in `textSecondary`, text 16 in `textPrimary`,
  placeholder `textMuted`; rows separated by 1 px `divider`; trailing action icon 20 (`my_location_rounded`).
- **Plain outlined field**: height 48–52, radius 12, fill `card` (or `background`), 1 px `border`
  (`#CCCCCC` in export, `#E5E5E5` elsewhere), text 14–16, placeholder `textMuted`. Focus: border
  `primary` at 1.5 px plus 2 px focus ring.
- **Textarea** (notes): radius 12, fill `cardSubtle`, 1 px border, 12 px padding, 14 px text, 3 rows,
  placeholder `textMuted`.
- **Dropdown / select row**: same as outlined field with `expand_more_rounded` 18; label 14 in
  `textPrimary`, value 13–14 in `textSecondary` (mono when numeric).
- **Keyword / tag input**: container radius 12, 1 px border, min height 44, 6 px padding, tags as
  radius-8 chips (`#F4F4F5` fill, 1 px border, mono 13, `close_rounded` 14), inline text field 13 with
  placeholder `textMuted`.

### 3.7 Toggles, checkboxes, radios, segmented controls, sliders

- **Switch** — track 44 × 24, thumb 20, 2 px inset. On: track `primary`, thumb `onPrimary` (light:
  black track, white thumb; dark: white track, black thumb). Off: track `disabled`, thumb `background`/
  `card`. 100 ms thumb motion. Tap target ≥ 48.
- **Checkbox** — 18 × 18 visual (mockup 16), radius 4, 1.5 px border `#B0B0B0`/`#525252`; checked:
  fill `primary`, `check_rounded` in `onPrimary`; 48 px tap target via `MaterialTapTargetSize.padded`.
- **Radio** — 20 circle, 2 px border `#BBBBBB`/`#525252`; selected: border `primary` + 10 px inner dot
  `primary`. Used by scope options and plan rows.
- **Segmented control** — track radius 12, 4 px padding, fill `surface` (`#F0F0F0`/`#F4F4F5` in some
  mockups, normalize to `surface`), 1 px `border`; option radius 8, height 32–40; selected = fill `card`
  with shadow-sm and text `textPrimary` (filters/status/theme) **or** fill `primary` with `onPrimary`
  (lead-detail status control). Two styles exist; the *boxed white* style is the default for settings,
  filters and saved-list statuses, and the *filled primary* style is used for lead-detail status.
  Counts render under labels in mono 13 for the saved-list status control.
- **Slider** — track height 6, radius pill, active `primary`, inactive `disabled` (`#E4E4E7`); thumb
  20 circle, `primary`; no value bubble; min/max labels 13 in `textMuted`.

### 3.8 Sticky bars

- **Bottom action bar** — full-width, fill `background`, 1 px top border, 16 px padding, 24 px bottom
  padding (safe area), optional 13 px caption above the button, primary button 52 (radius 16) or 48–52
  with an icon. Light: top shadow `0 -4px 16px rgba(0,0,0,0.06)`; dark: none.
- **Selection action bar** — floating 14 px above the bottom nav, radius 16, fill `inverseSurface`,
  height 56, 16 px padding, left: live dot + "1 selected" in `titleSm`; right: 36 px icon buttons
  (44 tap target) for export, add-to-list, tag and delete, with `overlayHover` = `#262626` / `#E5E5E5`.
  Inverted in both themes.

### 3.9 Ads — no banner slots

**The mockups draw a 320 × 50 banner on Home, Results, Saved and Lead detail. The product has only
rewarded and interstitial ads, so that element is intentionally removed — there is no banner, native
or inline ad placement anywhere in the app.** `AdBannerPlaceholder` no longer exists, and
`test/ads_test.dart` fails if the word "banner" or that class returns under `lib/`.

What replaces it:

* **Rewarded, opt-in.** A Free user taps Find Leads, confirms in a dialog, watches a short ad, and
  only then does the search run. Pro users never see it.
* **Interstitial, at natural breaks.** Controlled by `AdPolicy` (35% chance, 2 actions, 120 s apart,
  never in the first 60 s, never within 60 s of a rewarded ad, never for Pro).

Full rules, failure handling and the AdMob swap: Section 12.

### 3.10 Mono text

JetBrains Mono with tabular figures for: phone numbers, emails, domains, file names/extensions, source
badges, counts inside chips/pills, timestamps ("Saved 2d ago"), radii and prices ("₹2,999 / year"),
version strings, and the contact rows on result cards. Never use mono for prose.

---

## 4. Screen specifications

Notation: sizes in px, `icon:name` = rounded Material icon, `mono` = JetBrains Mono. "Lead fields" lists
which parts of the `Lead` model the screen renders. Every screen is a `Scaffold` with the app bar in
`appBar` and a sticky bar in `bottomNavigationBar`; avoid `Stack` + `Positioned` for bars so safe-area
and keyboard insets work.

### 4.1 home — Search (tab, `/search`)

**Purpose.** Turn a niche + location into a search. Secondary: explain the free quota, show lead
sources, expose two quick filters, reopen recent searches.

**Navigation.** Opened at launch (tab index 0). "Find Leads" → `/results`. Filters chip → `/filters`.
Settings icon → `/settings` tab. Pro pill and locked source chips → `/pro`. Recent row → re-runs that
search and opens `/results` (in B screens it can prefill the field). Bottom nav → Saved, Settings.

**Layout, top to bottom**

1. **Tab app bar** 56: `icon:filter_center_focus_rounded` 20 + "ClientHunt" (`titleLg`, w800,
tracking −0.02); right: Pro pill (28 h, `workspace_premium_rounded` 16 filled + "Pro" 13/600) and a
40 px settings icon button (`icon:settings_rounded` 20, `textSecondary`). Bottom border.
2. **Body** — 16 padding, 16 gaps.
   - Overline row: "Find your next client" (13/500 `textSecondary`) + quota pill (24 h, `surface`,
     1 px border, `icon:bolt_rounded` 14 + "3/5 free today" 13/600 `textPrimary`).
   - Question: "Who are you looking for?" (`headlineLg`).
   - **Search card** (radius 16, `card`, border, p16, soft shadow):
     - Grouped fields (radius 12, `surface`, border, two 52 px rows, 1 px divider):
       `icon:business_center_rounded` 20 `textSecondary` + placeholder "Niche, e.g. Dentists";
       `icon:location_on_rounded` 20 + placeholder "City or area, e.g. Ahmedabad" +
       trailing `icon:my_location_rounded` 20 ("Use my location").
     - Popular niche chips (36 h, 12 gap 6, horizontal scroll, clipped): "Dentists" (selected),
       "Cafes", "Salons", "Gyms", "Real Estate", "Lawyers". Tapping fills the niche field.
   - **Sources** header: "Sources" (14/600) + right `icon:lock_rounded` 14 + "Pro sources" (13/600
     `textSecondary`). Source pills (44 h, horizontal scroll): "Maps" selected with
     `icon:check_rounded` 16, `icon:map_rounded` 18; "Instagram" `icon:photo_camera_rounded`;
     "LinkedIn" `icon:badge_rounded`; "Facebook" `icon:groups_rounded`; "X" `icon:tag_rounded` — the
     four social pills are locked (13 tap → paywall).
   - **Quick filters** (36 h, single row, horizontal): "Email" selected (`icon:mail_rounded` 16),
     "Phone" selected (`icon:call_rounded` 16), "Website" unselected (`icon:language_rounded` 16),
     "Filters" outlined with a 16 px count bubble showing "2" (`icon:tune_rounded` 16) pushed to the
     right (`ml-auto`), tap → `/filters`.
   - **Primary action**: "Find Leads" 56 h, radius 16, `primary`/`onPrimary`, `icon:search_rounded` 20,
     `button` typography, active scale 0.99. Disabled until niche and location are non-empty.
   - **Recent**: header "Recent" (14/600) + "Clear all" (13/500 `textSecondary`, tap → confirm).
     Card with 1 px dividers, rows 56: `icon:history_rounded` 20 `textSecondary`, title 13/600, meta
     11→13 `textMuted` ("42 leads · Maps · 2 days ago"), trailing `icon:chevron_right_rounded` 18.
     Mockup data: "Dentists in Ahmedabad" (42, Maps, 2 days ago), "Cafes in Mumbai" (88, Maps, 4 days
     ago).
   - ~~Ad slot~~ — **removed.** The mockup's banner is not part of the product (Section 3.9).
3. **Bottom nav** — 3 tabs, Search active.

**States.** Empty fields; niche filled only; both filled (CTA enabled); free quota exhausted (quota pill
shows "0/5" and CTA opens paywall); locked source tapped; recent list empty (hide block).

**Interactive elements.** Two text fields, location autofill button, 6 niche chips, 5 source pills,
4 quick-filter chips, Find Leads, Clear all, 2 recent rows, Pro pill, settings button, 3 nav tabs.

**Dummy data.** Quota "3/5 free today"; recent searches above; filters count "2" (Email + Phone).

**Pro-gated.** Social sources (Instagram, LinkedIn, Facebook, X). The "Pro sources" label is
informational, not a control.

**Shared components.** `AppTopBar.tab`, `ProBadge`, `AppChip`, `AppTextField` (+ group), `AppButton`,
`AppCard`, `AppBottomNav`, `SectionHeader` (Recent/Sources), `AppDialog`.

**Lead fields.** None directly (the screen produces `SearchQuery`); recent rows show result counts and
source.

**Flutter notes.** `SingleChildScrollView` over a `Column`; the body scrolls, the app bar and bottom nav
are fixed. Chip rows are `SizedBox(height: …)` + horizontal `ListView` with `ClipRect`. Two
`TextEditingController`s in a small local state object (Riverpod form state arrives in B2). CTA must sit
inside the scrolling content (the mockup scrolls it), not in a sticky bar.

**Implemented behavior (B1).** The Search tab is real UI on the A2 fakes:

- **Typeahead.** Both fields suggest from `NicheCatalog` (60 niches) and `CityCatalog` (46 cities) after two
  characters. The list is an overlay, so it never pushes the card. Enter or a tap fills the field; both values
  are normalized on submit ("dental clinic" → "Dentists", "Bombay" → "Mumbai").
- **Validation.** 2–60 characters from letters, digits, space and `. , & ' - /`. The CTA stays disabled until
  both fields pass and at least one source is selected.
- **Sources.** Maps is free; the four social pills return `SourceToggleResult.locked` for Free and open `/pro`
  with `LockReason.sourceRequiresPro`. The last selected source cannot be deselected.
- **Quick filters.** Email, Phone and Website write into the same `SearchFilters` the Filters screen returns, so
  the badge and that screen's caption can never disagree. The badge is hidden at 0: the mockup's "2" counts
  the Email + Phone defaults, not active changes.
- **Quota.** At 0 the pill reads exhausted and the CTA opens `/pro` with
  `LockReason.dailySearchLimitReached`; Pro shows "Unlimited". Home checks the quota and never consumes it.
- **Free search flow.** Find Leads → validate → quota → opt-in `AppDialog` → rewarded ad → `/results`. Pro skips
  both the dialog and the ad. No ad or a failed ad proceeds without blocking; closing early stays on Home with a
  snackbar. Home never writes a history entry; B2 does, when a search completes with at least one lead.
- **Recent.** Two rows from the history stream, hidden when empty; "Clear all" empties the list; a row refills
  the fields and runs the same flow.
- **No other ad placement.** There is no banner slot (Section 3.9) and no interstitial can fire on Home: typing,
  launching, loading, the moment after a rewarded ad and the whole Pro session all fail the policy (Section 12).

### 4.2 search_results — Results (pushed, `/results`)

**Purpose.** Scan and act on a result set fast; select for bulk actions; jump to export.

**Navigation.** Opened from home "Find Leads" or a recent row. Back → home. Card tap → `/lead`. Search
icon → in-list search field (B screens). More → sheet (sort, filter, export, select). Export → `/export`.
Filter icon → `/filters`. Smooth scroll bottom → pagination in D/E.

**Layout, top to bottom**

1. **Pushed app bar** 56: back 40 (`arrow_back_rounded` 24); title "Dentists in Ahmedabad"
   (`titleSm`, truncating) with subtitle "42 leads · Maps" (13/500 `textMuted`); actions 40:
   `search_rounded`, `more_vert_rounded`.
2. **Body on `canvas` (`#FAFAFA` / `#0A0A0A`)**:
   - **Stats strip** 48 h, `card`, border, radius 12, three equal cells split by 1 px dividers:
     `icon:group_rounded` 16 + "42" (14 PJS w700) + "Leads" (13/500 `textSecondary`);
     `icon:mail_rounded` + "31" + "Emails"; `icon:call_rounded` + "40" + "Phones".
   - **Info note**: `icon:info_outline_rounded` 16 + "Emails are unverified" (13 `textMuted`) +
     `icon:close_rounded` 16 dismiss. (Copy must become "Public contact details are unverified" to match
     rule e — see Section 8.)
   - **Filter chips** 36, horizontal: "All" selected, then "Email", "Phone", "Website", "WhatsApp",
     "Rating 4+", "Saved". Single-select, filters the list client-side.
   - **Select row** 44: checkbox + "Select all" (13/500); right: two 40 px icon buttons (radius 12,
     `card`, border) `icon:swap_vert_rounded` (sort menu) and `icon:tune_rounded` (filters).
   - **Lead cards** (radius 16, `card`, border, p14, gap 12, soft shadow):
     - Row 1: checkbox; initials tile 40 (radius 12, `surface`, border, PJS 14 w700, e.g. "SD"); name
       (`titleSm`, truncate) + "Dental clinic · Navrangpura" (13/500 `textMuted`); 32 px bookmark button
       (saved = filled `primary`).
     - Row 2: `icon:star_rounded` 14 filled + "4.8" (13/600) + "(184)" (13 `textMuted`) · 4 px dot ·
       **Source badge** "Maps" (24 h, mono 13) · dot · "Open now" 13/500 (`textPrimary`) or
       "Closes 8 PM" (`textMuted`).
     - Rows 3–5: contact lines, 14 mono, leading 20 px icon `call_rounded`/`mail_rounded`/
       `language_rounded` in `textMuted`; missing data renders italic 13 sans "No website found" /
       "No email found" in `textMuted`.
     - Row 6: four equal 44 px buttons (radius 12, `card`, border): `call_rounded`, `chat_rounded`,
       `mail_rounded`, `content_copy_rounded`. Missing channel → disabled at 40% opacity.
     - Mockup data: Shalby Dental Clinic — 4.8 (184) — Maps — Open now — +91 79 4020 1888 /
       contact@shalbydental.com / shalbydental.com. Perfect Smile Orthodontics — 4.6 (92) — Open now —
       +91 98250 44120 / dr.patel@perfectsmile.in / *No website found* (bookmarked). Smile Dental Studio
       — 4.9 (210) — Closes 8 PM — +91 79 2676 9911 / *No email found* / smilestudioahmedabad.com.
       Ahmedabad Dental Care — 4.7 (146) — Open now — +91 79 2630 1120 / care@ahmedabaddental.in /
       ahmedabaddental.in.
3. **Sticky bottom bar**: "Export Leads" (52 h, radius 16) with `file_download_rounded` 20 and a count
   pill "42" (mono 13, `#262626`/`#FAFAFA` inside the button); a 52 × 52 outlined copy-all button
   (`content_copy_rounded`); caption "CSV · Excel · PDF · VCF" (13/500 `textMuted`).
4. No bottom nav (pushed).

**States.** Loading skeleton; empty; single-select filter; all selected (bar switches to
`SelectionActionBar`); a card with missing website/email/phone; saved vs unsaved bookmark; open/closed;
Pro-only source results (rating row hidden — see Section 7).

**Interactive elements.** Back, in-list search, more, 7 filter chips, select-all checkbox, sort, filters,
per-card checkbox, card body, bookmark, 4 action buttons per card, export, copy all.

**Dummy data.** 42 / 31 / 40 in the stats strip; four cards above; export count 42.

**Pro-gated.** None on this screen itself, but social-source result sets only exist for Pro.

**Shared components.** `AppTopBar.pushed`, `StatsStrip`, `InfoNote`, `AppChip`, `AppCard`,
`InitialsAvatar`, `SourceBadge`, `RatingBadge` (inline variant), `ContactRow` (compact result variant),
`AppIconButton`, `BottomActionBar`.

**Lead fields.** name, category, area, phones, emails, website, rating, reviewCount, isOpenNow,
sources, isSaved, id.

**Flutter notes.** `CustomScrollView` + `SliverList` (cards) with the stats/notice/chips/select row in a
`SliverToBoxAdapter` or a pinned `SliverPersistentHeader` (chips are *not* sticky in the mockup — keep
them scrolling). Bottom bar via `bottomNavigationBar`. Result card is its own widget
`features/results/widgets/lead_result_card.dart` in B.

### 4.3 lead_detail — Lead details (pushed, `/lead`)

**Purpose.** The full lead profile: contact, outreach actions, social profiles, business facts, private
notes/tags/status/reminder, destructive actions.

**Navigation.** Opened from a result card or a saved card. Back → previous. Bookmark toggles saved.
Share → share sheet. More → menu (copy all, export single, remove). Call/WhatsApp/Email/Directions →
external intents. Save to contacts → contacts insert (D/E). Website `open_in_new` → browser. Address
`directions` → maps. Pro badge on profiles → `/pro`. Add tag → tag sheet. Reminder row → date/time
picker. "Remove lead" → confirm dialog. No ad placement (Section 3.9).

**Layout, top to bottom**

1. **Pushed app bar** 56: back; "Lead details" (`titleSm` 16/600); actions: bookmark (filled when
   saved), `share_rounded`, `more_vert_rounded`.
2. **Hero card** (`cardSubtle` in light / `card` in dark, radius 16, border, p16, 3 gap): initials tile
   64 (radius 14, `#EBEBEB`/`#262626`, border, PJS 20 w700); name "Shalby Dental Clinic" (`titleMd`);
   "Dental clinic · Navrangpura, Ahmedabad" (13 `textSecondary`); badge row (28 h): rating pill
   (`star_rounded` 16 filled + "4.8" + "(184)" muted), "Maps" pill, and "Open now" pill with a 6 px
   `primary` dot.
3. **Action row**: four 52 px buttons (radius 14, `card`, border, soft shadow): `call_rounded`,
   `chat_bubble_rounded`, `mail_rounded`, `directions_rounded` (24 icons). Below: "Save to contacts"
   48 h, radius 14, primary, `contact_phone_rounded` 20.
4. **Contact details card** (radius 16, `card`, border, header row on `cardSubtle`, rows split by
   dividers): header "CONTACT DETAILS" (13 mono/600 uppercase, tracking +0.04) + right caption
   **"Public contact details"** (13 `textMuted`; the mockup says "Direct & Verified" — replaced, see
   Section 8). Rows:
   - Phone 56: `call_rounded` 20 + label "Phone" 13 `textMuted` + value "+91 79 4020 1888" (15 mono
     w500) + copy 36 button.
   - Mobile (second number) 56: `smartphone_rounded` + "+91 98250 44120" + copy.
   - Email: `mail_rounded` + label "Email" + "contact@shalbydental.example" + copy; under it
     `icon:info_outline_rounded` 16 + "Found on a public page, not verified." (13 `textMuted`).
   - Website 56: `language_rounded` + "shalbydental.example" + `open_in_new_rounded` + copy.
   - Address: `location_on_rounded` + "Navrangpura, Ahmedabad, Gujarat 380009" (14/500, 2 lines) +
     `directions_rounded` + copy.
5. **Profiles card**: header "Profiles" (`titleSm`) + "(4 checked)" + **Pro badge** (lock + "Pro").
   Inner card radius 12 with 4 rows 48: Instagram `photo_camera_rounded` → "@shalbydental_official"
   (mono 13) + `open_in_new_rounded`; LinkedIn `work_rounded` → "company/shalby-dental";
   Facebook `public_rounded` → "Not found" (italic, row at 60% opacity); X `tag_rounded` →
   "X (Twitter)" → "Not found". Found rows sit on `cardSubtle`.
6. **Business details card**: title "Business details"; 2 × 2 fact tiles (radius 12, `cardSubtle`,
   border, p10): Rating `star_rounded` "4.8 / 5.0"; Reviews `reviews_rounded` "184 reviews"; Hours
   `schedule_rounded` "Mon-Sat, 9AM-8PM"; Status `storefront_rounded` "Open now".
7. **My notes card**: header "My notes" + `lock_rounded` 16; right "Only on this device" (13
   `textMuted`). Tag chips: "Hot lead" (outlined), "Follow up" (selected, check), "Add tag" (dashed,
   `add_rounded`). Note textarea (3 rows, placeholder "Add a note about this lead..."). "Lead status"
   label + 4-option segmented control (New selected, filled primary style): New / Contacted / Replied /
   Closed. Follow-up reminder row 44: `alarm_rounded` 18 + "Follow-up reminder" + "Not set" +
   `chevron_right_rounded`.
8. **Secondary actions**: two 44 px outlined buttons, "Copy all details" (`content_copy_rounded`) and
   "Remove lead" (`delete_rounded`). Destructive action stays monochrome; confirmation dialog carries the
   weight (title + body + destructive-styled button using `primary`, not red).
9. **No ad slot.** The mockup's banner is intentionally not built (Section 3.9).

**States.** Saved/unsaved; missing email/phone/website/address (row hidden or "Not found"); social found
vs not found; Pro vs Free (profiles unlocked vs locked); status per value; reminder set/not set; note
empty/filled; tag selected/unselected; phone/email validation states (`ValidationStatus`) shown as a
small suffix icon + label, never color.

**Dummy data.** Everything above (Shalby Dental Clinic). Email/domain use `.example` TLD on purpose —
not real data.

**Pro-gated.** Social profile values (the card is visible as a teaser, rows show "Not found"/blurred
until Pro; lock + Pro badge).

**Shared components.** `AppTopBar.pushed`, `AppCard`, `SectionHeader`, `InitialsAvatar`, `RatingBadge`,
`SourceBadge`, `AppChip`, `ContactRow`, `MonoText`, `AppSegmentedControl`, `ProBadge`, `ToggleRow`,
`AppButton`, `AppIconButton`, `InfoNote`, `AppDialog`.

**Lead fields.** name, category, area, city, state, address, phones (all, with kind), emails (all),
website, socialLinks, rating, reviewCount, isOpenNow, openingHours, sources, tags, note, status,
reminderAt, isSaved, latitude/longitude (for directions).

**Flutter notes.** One `SingleChildScrollView` + `Column`, sections as widgets under
`features/lead_detail/widgets/`. The screen is long: keep the app bar fixed and nothing else. Text
scaling must not break the 2-column fact grid — use `Wrap`/`IntrinsicHeight` rather than fixed heights
for text rows (fixed 56 only where the label is one line).

### 4.4 saved_leads — Saved leads (tab, `/saved`)

**Purpose.** Lightweight on-device CRM: lists, statuses, tags, notes, reminders, bulk actions.

**Navigation.** Tab index 1. Card tap → `/lead`. Search icon → search saved leads. More → menu
(export all, manage lists, clear). List chip → filter; "New list" → create-list dialog. Status segment
→ filter. Sort → menu. View toggle → list/grid (grid deferred). Action buttons → call/chat/email.
Selection bar actions → export (`/export`), add to list, tag, delete. Pro upsell (if free limit hit) →
`/pro`.

**Layout, top to bottom**

1. **Tab app bar** 56: "Saved leads" (`titleLg`) + count pill "128" (mono 13, `surface`, border);
   right: `search_rounded` 40, `more_vert_rounded` 40.
2. **List row** (bordered bottom, on `background`): 40 h scrollable pills: "All 128" (selected),
   "Hot leads 14", "Follow up 9", "Dentists 36", "Cafes 22", and a dashed "New list" (`add_rounded`
   14). Counts in mono 13, muted when unselected.
3. **Status segmented** (5 options, track `surface`, radius 12, p4): All 128 (selected), New 42,
   Contacted 38, Replied 19, Closed 29 — label 13 (selected 700, others 500) with the count below in
   mono 13 (`textMuted`).
4. **Toolbar row** 44: checkbox + "Select all" (13/500 `textSecondary`); right: "Recent" text button
   with `swap_vert_rounded` 14, and a 32 px view toggle (`view_list_rounded`).
5. **Saved cards** (radius 16, `card`, border, p12, gap 8):
   - Row 1: checkbox (16 visual); initials tile 40 (radius 12, `#F0F0F0`/`#262626`, border); name
     (`titleXs` 15/600, truncate) + "Dental clinic · Ahmedabad" (13 `textMuted`); **StatusPill**
     (New / Contacted / Replied / Closed).
   - Row 2 (top border, 6 pt gap): tag chips 20 h radius 6 (`#FAFAFA`/`#141414`, border, 13/500
     `textSecondary`) e.g. "Hot lead", "Dentists"; right: "Saved 2d ago" (mono 13 `textMuted`).
   - Row 3: optional reminder line (`alarm_rounded` 14 + "Tomorrow, 10:00 AM" mono 13/600 + note
     preview `notes_rounded` 14 + one-line text 13); right: three 36 px outlined action buttons
     (`call_rounded`, `chat_rounded`, `mail_rounded`); missing channel disabled at 40%. Row 3's note part
     is omitted when there is no note (Apex Dental Care).
   - Selected card: 1.5 px `primary` border and a filled checkbox.
   - Mockup data: Shalby Dental Clinic (New, Hot lead/Dentists, Saved 2d ago, reminder "Tomorrow, 10:00
     AM", note "Spoke to clinic manager, requested PDF proposal", selected); Perfect Smile
     Orthodontics (Contacted, Follow up, 4d, "Sent outreach email to dr.patel, waiting for response");
     Roastery Coffee House (Replied, Hot lead/Cafes, 1w, "Owner interested in coffee bean wholesale
     supply", email disabled); Apex Dental Care (Closed, Dentists, 2w, no note); Cafe De Bella (New,
     Follow up/Cafes, 3w, "Found via Instagram outreach, needs tasting appointment").
6. **No ad slot.** The mockup's dashed banner is intentionally not built (Section 3.9).
7. **Floating selection bar** (when selection > 0): inverse pill above the nav, live dot + "1 selected",
   actions `file_download_rounded`, `playlist_add_rounded`, `sell_rounded`, `delete_rounded` (36 px
   buttons, 44 tap).
8. **Bottom nav** — 3 tabs, Saved active.

**States.** Empty (EmptyState: bookmark icon, "Nothing saved yet", body, "Find leads" → `/search`);
no results for a filter; free saved-lead limit reached (upsell card); selection 0 vs n; missing
note; missing channel; reminder overdue (icon + weight, no red).

**Interactive elements.** Search, more, list chips, New list, 5 status segments, select all, sort, view
toggle, per-card checkbox, card, 3 action buttons per card, ad action, 4 selection actions, nav tabs.

**Dummy data.** 128 saved / 42 new / 38 contacted / 19 replied / 29 closed; list counts 14/9/36/22;
five cards above.

**Pro-gated.** Unlimited saved leads/lists (free limit is 50 — see Section 6). Reaching the limit shows
`ProUpsellCard` and the save action opens the paywall.

**Shared components.** `AppTopBar.tab`, `AppChip`, `AppSegmentedControl`, `StatusPill`, `AppCard`,
`InitialsAvatar`, `AppIconButton`, `SelectionActionBar`, `EmptyState`,
`ProUpsellCard`, `AppBottomNav`.

**Lead fields.** name, category, area/city, status, tags, note, reminderAt, savedAt, phones, emails,
website, listIds.

**Flutter notes.** `CustomScrollView` with a `SliverAppBar`-free layout: app bar fixed, list chips and
status control scroll with the list (they are not sticky in the mockup). Cards are
`features/saved/widgets/saved_lead_card.dart` in B. Selection state is local in B, Riverpod in C.

### 4.5 search_filters — Filters (modal/pushed, `/filters`)

**Purpose.** Precise pre-search tuning so the lead engine does less work: contact presence, quality
thresholds, keyword include/exclude, geography, depth and result count, cleanup rules.

**Navigation.** Opened from home's "Filters" chip (and from results' tune icon). Close (X) → discard.
"Reset" → defaults. "Apply filters" → returns to home and updates the active count. "No website" locked
row → `/pro`. Deep depth and 200 results locked → `/pro`.

**Layout, top to bottom** (body on `canvas`, 16 padding, 12 gaps)

1. **Pushed app bar (close variant)**: `close_rounded` 24 in a 40 px button; "Filters" (`titleMd`);
   right text action "Reset" (14/500 `textSecondary` → `textPrimary`).
2. **Section cards** (radius 16, `card`, border, p16, soft shadow), each with `SectionHeader`
   (16–18 px icon + title `titleSm` 14/600):
   - **Contact** (`mail_rounded`): rows 48 with label 13/500 and a **switch** on the right. "Has email"
     **on**, "Has phone" **on**, "Has website" off, "Has WhatsApp number" off, "Has social profile
     link" off, "No website" off with an inline **PRO** badge (fill `primary`, lock 14, text 13) and a
     60% opacity disabled switch.
   - **Business quality** (`star_border_rounded`): "Minimum rating" + 5 `OptionPill`s (36 h, radius 8,
     mono 13): Any / 3.0+ / 3.5+ / **4.0+ (selected)** / 4.5+. "Minimum reviews": Any / **10+
     (selected)** / 50+ / 100+. "Status" + 2-option segmented: **Any (selected)** / Open now.
     ("Recently active" was removed — see Section 9.)
   - **Keywords** (`tag_rounded` or `sell_rounded`): "Must include" TagInput with chips "implants",
     "family" + inline placeholder "Type keyword..."; "Exclude" TagInput with "supplies", "training".
     Chips are radius 8, mono 13, fill `#F4F4F5`/`#262626`, `close_rounded` 14.
   - **Area** (`location_on_rounded`): "Country" select showing "India" (`public_rounded` 16 +
     `expand_more_rounded`); "Radius" label + value pill "25 km" (mono 13, `surface`, border) on a
     slider 1–100 km at 25, with 13 px min/max labels "1 km", "50 km", "100 km".
   - **Results** (`assignment_rounded`): "Search depth" with two `RadioTile`s — **Fast** (selected,
     2 px `primary` border, `cardSubtle`, radio selected, subtitle "Listing details only") and **Deep**
     (normal border, 80% opacity, radio empty, PRO badge, subtitle "Also scans websites for emails").
     "Max results": 25 / **50 (selected)** / 100 / 200 with a lock icon and 70% opacity. "Sort by"
     select showing "Relevance" (`expand_more_rounded`).
   - **Cleanup** (`delete_rounded`): rows 48 with switches: "Remove duplicates" **on**, "Skip leads I
     already saved" **on**, "Remove invalid phone numbers" **on**, "Group by city" off.
3. **Sticky bottom bar**: caption row centered, `tune_rounded` 14 + "5 filters active" (mono 13
   `textMuted`); "Apply filters" 52 h, radius 16, primary, `check_rounded` 20.
4. No bottom nav.

**States.** Each toggle on/off; every pill/segment selected state; locked rows (Pro); empty keyword
inputs; radius extremes; active filter count 0 ("No filters active"); apply returns.

**Interactive elements.** Close, Reset, 6 contact switches, 5 rating pills, 4 review pills, 3 status
segments, 2 tag inputs with removable chips, country select, radius slider, 2 depth radios, 4 result
pills, sort select, 4 cleanup switches, Apply.

**Dummy data.** The defaults above (rating 4.0+, reviews 10+, 50 results, 25 km, keywords).

**Pro-gated.** "No website" filter, Deep search depth, 200 results.

**Shared components.** `AppTopBar.pushed` (close), `AppCard`, `SectionHeader`, `ToggleRow`,
`AppSegmentedControl`, `OptionPill`/`OptionPillRow`, `RadioTile`, `TagInput`, `AppChip`, `ProBadge`,
`AppButton`/`BottomActionBar`.

**Lead fields.** Everything it filters on: emails, phones, website, whatsApp, socialLinks, rating,
reviewCount, isOpenNow, name/category (keywords), city/country, lat/lng (radius), plus engine options
(depth, maxResults, sortBy, dedupe, skipSaved, removeInvalidPhones, groupByCity).

**Flutter notes.** `Scaffold` + scroll view + `bottomNavigationBar` (sticky Apply). Dismissing returns
`SearchFilters?` — use `Navigator.pop(context, filters)` so the caller decides whether to apply. Radius
slider uses the themed `Slider`; keep the value pill in sync.

### 4.6 export_leads — Export (pushed, `/export`)

**Purpose.** Configure and run a lead export: scope, format, columns, file name, cleanup, quick copy.

**Navigation.** Opened from results' sticky "Export Leads", from saved's selection bar, or from
settings' "Export all saved leads". Close (X) → discard. "Export as CSV" (label follows selected
format) → runs export and opens the system share sheet. Share icon → share without saving. Quick copy →
clipboard + snackbar.

**Layout, top to bottom** (body on `canvas`, 16 padding, 12 gaps)

1. **Pushed app bar (close variant)**: `close_rounded`; "Export leads" (`titleMd`); empty right slot.
2. **"What to export" card**: uppercase overline 13/600 `textSecondary`; four scope rows 48 with radios:
   **All leads 42 (selected)**, "Selected only 0", "Only with email 31", "Only with phone 40" — counts
   right-aligned in mono 13/600 (muted for unselected).
3. **"Format" card**: 2 × 2 `SelectableTile`s 72 h (radius 12): **CSV** (selected: 1.5 px `primary`
   border, `surface` fill, check circle) with `description_rounded` in a 36 px tile and subtitle ".csv";
   Excel (`.xlsx`, `table_chart_rounded`); PDF (`.pdf`, `picture_as_pdf_rounded`); VCF (".vcf,
   contacts", `contact_page_rounded`). Subtitle in mono 13 `textMuted`.
4. **"Columns" card**: header + "Select all" text action; wrapped chips 36: selected (fill `primary`,
   `check_rounded` 16) "Name", "Phone", "Email", "Website", "Address"; unselected (border `#DCDCDC`,
   text `textSecondary`) "Category", "Rating", "Reviews", "Source", "Social links", "Notes", "Tags",
   "Status".
5. **"File name" card**: outlined field 48, radius 12, border `#CCCCCC`: `description_rounded` 16 muted +
   "dentists-ahmedabad-leads" (mono 14/500) + right suffix ".csv" (mono 13 `textMuted`).
6. **"Cleanup & Formatting" card**: rows 48 with switches: "Remove duplicates" **on**, "Skip leads
   without contact info" off, "Add header row" **on**.
7. **"Quick copy" card**: two 48 px outlined buttons — `mail_rounded` + "Copy emails" + count pill "31",
   `call_rounded` + "Copy phones" + "40"; caption "Copies one per line, ready to paste."
8. **Summary line**: `info_outline_rounded` 16 + "42 leads · 5 columns · CSV · about 12 KB" (mono 13
   `textSecondary`).
9. **Sticky bar**: 52 × 52 outlined share button (`share_rounded`) + "Export as CSV" (52 h, radius 12,
   primary, `file_download_rounded` 20).
10. No bottom nav.

**States.** Scope per value (Selected only disabled at 0); each format selected; columns on/off;
file-name editing (extensions follow format); cleanup toggles; export in progress (button loading at 40%
opacity); no data (EmptyState).

**Interactive elements.** Close, 4 scope radios, 4 format tiles, 14 column chips, Select all, file-name
field, 3 cleanup switches, 2 quick-copy buttons, share, export.

**Dummy data.** 42 / 0 / 31 / 40 scopes; 31 emails, 40 phones; file name; 12 KB estimate.

**Pro-gated.** Unlimited exports and non-CSV formats (free tier is CSV up to a row cap — confirm in
Section 9). The VCF format depends on phone extraction.

**Shared components.** `AppTopBar.pushed` (close), `AppCard`, `RadioTile`, `SelectableTile`, `AppChip`,
`AppTextField`, `ToggleRow`, `AppButton`, `AppIconButton`, `InfoNote`, `BottomActionBar`.

**Lead fields.** All exportable columns: name, phone(s), email(s), website, address, category, rating,
reviews, source(s), social links, notes, tags, status. Scope depends on hasEmail/hasPhone.

**Flutter notes.** Format and column chips must wrap (`Wrap`, spacing 8) rather than scroll. Keep the
total estimated size as a derived placeholder until the engine exists. File writing/sharing is prompt E.

### 4.7 go_pro — ClientHunt Pro paywall (pushed, `/pro`)

**Purpose.** Convert to Pro: three plans, what is included, Free vs Pro, social proof.

**Navigation.** Opened from the Pro pill, locked sources, locked filters, saved-limit upsell, settings'
"Go Pro". Close (X) → back. "Restore" → restore purchases. "Continue" → purchase flow (prompt E).
Footer links → legal/restore.

**Layout, top to bottom**

1. **Pushed app bar (close variant)**: `close_rounded` 24; right text action "Restore" (14/600
   `textSecondary`). No title.
2. **Hero** (centered): 48 px tile (radius 14, `primary` fill, `workspace_premium_rounded` 28 in
   `onPrimary`); "ClientHunt Pro" (`headlineMd`); "Find more leads, from more places." (14
   `textSecondary`).
3. **Plan stack** (gap 8), rows min height 72, radius 16, p14, full-width tappable:
   - **Yearly — selected**: 2 px `primary` border, `card` fill, soft shadow (light). Radio selected
     (20, 2 px border, 10 px inner dot); "Yearly" (`titleXs` 15/700) + **"Best value"** filled badge
     (primary, 13/600 uppercase) + **"Save 16%"** outlined badge; second line "About ₹250 / month"
     (13 `textSecondary`); right: "₹2,999 / year" (mono 14/600).
   - **Monthly**: 1 px border, `cardSubtle`; "Monthly" + "Billed every month"; "₹299 / month".
   - **Weekly**: "Weekly" + "Billed every week"; "₹99 / week".
   (Prices are INR; the glyph is ₹. The plan rows are the radio group — only one selectable.)
4. **"Included in all plans"** card: header with `workspace_premium_rounded` 22; 8 features, each
   `check_circle_rounded` 20 primary + text 14 `textSecondary`:
   "Search Instagram, LinkedIn, Facebook and X" · "Deep search that scans websites for emails" ·
   "Up to 200 results per search" · "Unlimited saved leads and lists" · "Find businesses with no
   website" · "Export to CSV, Excel, PDF and VCF without limits" · "Ad-free experience" ·
   "Priority support". Then a separated row: `lock_rounded` 18 + "AI to organize, format and verify
   leads" + outlined pill "Coming soon" (13).
5. **"Free vs Pro comparison"** card (`balance_rounded` 20): table, header "Feature / Free / Pro"
   (13/600 `textSecondary`, Pro header in a small filled pill), rows separated by hairlines:
   Maps leads ✓/✓ · Social sources —/✓ · Deep search —/✓ · Results per search 50/200 · Saved leads
   50/Unlimited · Ads Yes/No. Pro column bold. Icons 18; "—" is text, not an icon. (The 50 is the
   Free `maxResultsPerSearch`; the "Max results" row on Filters therefore locks 100 and 200.)
6. **"What users say"** card (`forum_rounded` 20 + "4.7" star metric + "Play store" 13): horizontally
   scrolling review cards (width ≈ 264, `cardSubtle`, border, p14): 5 stars (`star_rounded` 17, last one
   `star_half_rounded` for 4.5), review text 13 `textSecondary`, footer with 32 px initials avatar +
   name 13/600 + role 13 `textMuted`. Mockup reviews: Amit K. / Agency Owner; Priya S. / B2B Consultant;
   Rahul M. / Freelancer. Closing caption: **"Sample reviews for design only"** (13 `textMuted`).
7. **Footer**: links row "Terms · Privacy Policy · Restore purchases" (13, underlined on tap); legal
   note `info_outline_rounded` 16 + "Subscription renews automatically until cancelled. Cancel anytime
   in Google Play."
8. **Sticky bar**: "₹2,999 billed yearly" caption (mono 13 `textMuted`); "Continue" 52 h radius 16
   primary with `arrow_forward_rounded` 20.
9. No bottom nav.

**States.** Three plans selected; restore in progress; purchase loading/error (icon + text weight);
reviews loading/unavailable.

**Interactive elements.** Close, Restore, 3 plan rows, 3 footer links, Continue.

**Pro-gated.** This *is* the gate. Everything in the feature list is the Pro entitlement set.

**Shared components.** `AppTopBar.pushed` (close), `AppCard`, `SectionHeader`, `ProBadge`,
`StatusPill`-like small outlined badge, `RadioTile`/plan row, `InitialsAvatar`, `InfoNote` (legal),
`BottomActionBar`.

**Lead fields.** None.

**Flutter notes.** **The three reviews and the 4.7 rating are dummy data.** They live behind
`AppStrings.sampleProReviews` and `kShowSampleProReviews = true` with a comment that they must be
replaced before release. A horizontal `ListView` sized ~264 × ~150. Purchase actions are stubs that
show a snackbar until prompt E.

### 4.8 settings — Settings (tab, `/settings`)

**Purpose.** Theme, country and search defaults, device storage, privacy/ads, support, legal, Pro entry.

**Navigation.** Tab index 2. Pro card "Go Pro" → `/pro`. "Manage subscription" → `/pro` (or store
subscription page later). Theme segment → `themeModeProvider`. Rows with chevrons push placeholder
screens/dialogs in B (they are stubs in A1). External-link rows open URLs (later). Export all saved →
`/export`. Clear history / clear saved → confirm dialogs. Bottom nav → Search, Saved.

**Layout, top to bottom** (body on `canvas`, 16 padding, 20 gaps)

1. **Tab app bar**: "Settings" (`headlineSm` 22/700), no actions.
2. **Pro status card** (inverse: fill `primary`, text `onPrimary`, radius 16, p16; in light this is a
   black card, in dark a white card): 40 px tile (radius 12, `#171717`/`#F5F5F5`, border,
   `workspace_premium_rounded` 20) + "ClientHunt Pro" 16/700 + "Unlock social sources and unlimited
   leads" (13, on primary at 70%) + "Go Pro" pill (32 h, fill `onPrimary`, text `primary`, 13/600).
   Below, outside the card: "Manage subscription" (13 `textMuted`) + `chevron_right_rounded` 16.
3. **Appearance group**: 32 px icon tile (`surface`, `palette_rounded` 16 in `textPrimary`) + "Theme"
   (14/500) and the 3-option segmented Light / Dark / **System** (selected, fill `primary`); then
   "Default country" + value "India" + `expand_more_rounded`.
4. **Search defaults group**: "Default sources" + "Maps" + chevron; "Max results per search" + "50"
   (mono 13) + chevron; "Remove duplicates" switch **on**; "Skip leads I already saved" switch **on**.
5. **Data and storage group**: "Storage used" + "2.4 MB" (mono 13 `textMuted`); "Export all saved
   leads" + chevron; "Clear search history" + chevron; "Clear all saved leads" + chevron (destructive by
   confirmation, still monochrome). Caption under the group: `lock_rounded` 14 + "Your leads are stored
   only on this device." (13 `textMuted`).
6. **Privacy and ads group**: "Ad personalization" switch **on**; "Reset advertising ID" +
   `open_in_new_rounded` 16; "Privacy choices" + chevron.
7. **Support group**: "Rate ClientHunt" + chevron; "Share the app" + chevron; "Send feedback" +
   chevron; "Contact support" + "support@yourdomain" (mono 13) + chevron (external); "Help and FAQ" +
   chevron.
8. **About and legal group**: "Privacy Policy" + external; "Terms of Use" + external; "Open source
   licenses" + chevron; "App version" + "1.0.0 (1)" (mono 13).
9. **Footer**: "Made with care by Craftline Interactive" (13 `textMuted`, centered).
10. **Bottom nav** — 3 tabs, Settings active.

**States.** Theme light/dark/system; toggles on/off; Pro vs Free (Pro card copy changes to "Manage" vs
"Go Pro"); storage empty/data; confirmation dialogs; long labels do not wrap under values.

**Interactive elements.** Go Pro, manage subscription, theme segment, country row, 4 search-default rows,
4 data rows, 4 privacy rows, 5 support rows, 4 about rows, nav tabs.

**Dummy data.** Country India, max results 50, storage 2.4 MB, version 1.0.0 (1), support email.

**Pro-gated.** The Pro status card is the entry point; "Ad personalization" only matters for Free users.

**Shared components.** `AppTopBar.tab`, `SettingsGroup`, `SettingsRow`, `ToggleRow`,
`AppSegmentedControl`, `AppChip`/`ProBadge`, `AppCard`, `AppBottomNav`.

**Lead fields.** None directly; "Export all saved leads" and storage depend on saved counts.

**Flutter notes.** One `SingleChildScrollView` + `Column`; groups are `SettingsGroup(title, children)`
with a rounded card that clips dividers. Theme segment writes to `themeModeProvider` (in memory in A1).
Version string should come from `package_info_plus` in a later prompt — hardcode in A1.

---

## 5. Navigation map

| From | Action | To | Bottom nav |
|------|--------|----|-----------|
| Launch | — | `/search` | shown, Search active |
| Search | "Find Leads" | `/results` | hidden |
| Search | recent row | `/results` (same query) | hidden |
| Search | "Filters" chip | `/filters` | hidden |
| Search | "Pro" pill / locked source | `/pro` | hidden |
| Search | settings icon | `/settings` | shown, Settings active |
| Search | nav Saved / Settings | `/saved` / `/settings` | shown |
| Results | back | previous (Search) | shown again |
| Results | lead card | `/lead` | hidden |
| Results | tune | `/filters` | hidden |
| Results | "Export Leads" | `/export` | hidden |
| Results | more | bottom sheet (sort/filter/export) | hidden |
| Lead detail | back | previous | as previous |
| Lead detail | profiles Pro badge | `/pro` | hidden |
| Lead detail | remove | confirm dialog → previous | hidden |
| Saved | card | `/lead` | hidden |
| Saved | selection export | `/export` | hidden |
| Saved | Pro upsell | `/pro` | hidden |
| Saved | nav Search / Settings | `/search` / `/settings` | shown |
| Filters | close | previous (discard) | as previous |
| Filters | apply | previous (with `SearchFilters`) | as previous |
| Filters | "No website" / Deep / 200 | `/pro` | hidden |
| Export | close | previous | as previous |
| Export | export / share | system share sheet | hidden |
| Pro | close | previous | as previous |
| Pro | continue | purchase flow (E) | hidden |
| Settings | Go Pro / manage | `/pro` | hidden |
| Settings | export all | `/export` | hidden |
| Settings | nav Search / Saved | `/search` / `/saved` | shown |
| any (debug) | — | `/dev/gallery` | hidden |

**Bottom nav visibility.** Only the three tab destinations (`/search`, `/saved`, `/settings`) show the
bottom navigation, implemented with `StatefulShellRoute.indexedStack`. All other destinations are pushed
on the root navigator so the shell (and its nav bar) is covered. Filters is a modal-style pushed route,
not a bottom sheet, because it has its own sticky Apply bar.

**Back-stack rules.** Implemented by the shot stack, not by per-screen overrides — no route intercepts
pop, so the Android system back button always does exactly what the app-bar arrow does.

| Screen | Opened from | Back / close returns to |
|--------|-------------|--------------------------|
| Results (`/results`) | Search (Find Leads or a recent row) | Search, with its form state intact |
| Lead detail (`/lead/:id`) | Results or Saved | The screen that opened it (results or saved), at the same scroll position |
| Filters (`/filters`) | Search's Filters chip, or results' tune icon | Where it was opened; applying pops with the `SearchFilters` result |
| Export (`/export`) | Results' sticky bar, Saved's selection bar, Settings' export row | Where it was opened |
| Pro (`/pro`) | Home Pro pill, Settings Pro card, any locked source chip, any locked filter | Where it was opened |
| Debug gallery (`/dev/gallery`) | Debug builds only | Where it was opened |

Each tab is its own stack inside the shell, so switching tabs and coming back preserves that tab's
position. Navigation calls go through the typed helpers in `lib/core/router/app_routes.dart`
(`goToResults`, `goToLead(id)`, `openFilters`, `openExport`, `openPro`, `goToTab`); no screen builds a
path string. `test/router_test.dart` asserts that the bottom bar is present on exactly the three tab
routes and absent — and restored after pop — on every pushed route.

---

## 6. Pro vs Free matrix

### 6.1 Gated features

| Feature | Free | Pro | Where it is gated in the UI |
|---------|------|-----|------------------------------|
| Maps source | ✓ | ✓ | Home source pills (Maps is always available) |
| Instagram / LinkedIn / Facebook / X sources | ✗ | ✓ | Home locked source chips; paywall feature list |
| Searches per day | 5 | no limit | Home quota pill "3/5 free today" |
| Deep search (crawl websites for emails) | ✗ | ✓ | Filters → Results → Search depth = Deep (lock + PRO) |
| Results per search | 50 | 200 | Filters → Max results 100 and 200 each carry a Pro lock badge on Free; comparison table 50/200 |
| "No website" filter | ✗ | ✓ | Filters → Contact → No website (PRO, disabled switch) |
| Saved leads / lists | 50 | unlimited | Saved leads limit + upsell; comparison table |
| Export formats | CSV, Excel, PDF, VCF | same four, without limits | Export format tiles; paywall list. All four formats are allowed on Free — the Pro claim is "without limits", not "more formats" |
| Ads | opt-in rewarded ad before each search, plus interstitials at breaks | none | Home Find Leads dialog; `AdPolicy` triggers. **No banner slots exist** (Section 3.9) |
| Social profile values | hidden/teaser | ✓ | Lead detail profiles card (Pro badge + "Not found" until Pro) |
| Priority support | ✗ | ✓ | Paywall feature list only |
| AI organize/format/verify leads | — | coming soon | Paywall coming-soon row |

### 6.2 Plans

| Plan | Price | Period | Badges | Caption | Bottom-bar caption |
|------|-------|--------|--------|---------|--------------------|
| Yearly (default selected) | ₹2,999 | year | "Best value" (filled), "Save 16%" (outlined) | "About ₹250 / month" | "₹2,999 billed yearly" |
| Monthly | ₹299 | month | — | "Billed every month" | "₹299 billed monthly" |
| Weekly | ₹99 | week | — | "Billed every week" | "₹99 billed weekly" |

The selected plan drives the sticky bar caption and the button label ("Continue"). Savings math:
₹299 × 12 = ₹3,588; ₹2,999 is 16.4% less → "Save 16%"; ₹2,999 / 12 ≈ ₹249.9 → "About ₹250 / month".
Only the three plan prices are literal, and they live in `ProPlan`. "Save 16%", "About ₹250 / month"
and "₹2,999 billed yearly" are *derived* from those numbers (`savingsPercent`, `caption`,
`billingSummary`), so a price change cannot leave stale copy behind. A test fails on any other rupee
amount in `lib/`. Billing itself is prompt E.

**Entitlements are one value, not scattered booleans.** Every Free/Pro limit in this table is a field
of `Entitlements` (`lib/domain/entitlements/`), with exactly two constants — `freeEntitlements` and
`proEntitlements` — and one `FeatureGate` that answers `canUseSource`, `canUseDeepSearch`,
`maxResultsOptions` and `reasonForLock`. Screens ask the gate; they never compare numbers.

---

## 7. Data requirements for the lead engine

This table is the contract between the UI and the engine prompts (D). "All" means every source type can
produce it *some of the time*; "Maps only" means social-only or website-only leads must hide the UI
element rather than show an empty or zero value.

| UI field | Model field | Maps listing | Website crawl | Social search | Coverage | Validation needed later |
|----------|-------------|--------------|---------------|---------------|----------|--------------------------|
| Name | `name` | ✓ | partial (page title / OG title) | ✓ (profile/display name) | All | Normalize whitespace, strip suffixes ("- Google Maps"), dedupe |
| Category | `category` | ✓ | partial (schema.org, meta) | partial (bio/category) | All, mostly Maps | Map to a canonical niche list; keyword match for include/exclude |
| Address | `address` | ✓ | ✓ (contact page) | partial (bio/"contact" link) | All | Parse into area/city/state/pin; geocode |
| Area / city / state / country | `area`, `city`, `state`, `country` | ✓ | ✓ | partial | All | Canonical names, country whitelist, `groupByCity` key |
| Latitude / longitude | `latitude`, `longitude` | ✓ | ✗ (geocode) | ✗ | Maps (+ derived) | Geocode website/social addresses; radius filtering needs coords |
| Phone(s) | `phones` | ✓ | ✓ (`tel:` links, text) | partial (bio, contact button) | All | E.164 normalization + country default, line type (mobile/landline/toll-free), validity, dedupe, `removeInvalidPhones` |
| Email(s) | `emails` | rare (some listings) | ✓ (`mailto:`, page text) | rare (bio) | Website best, Maps rare | Syntax, MX/domain lookup, role-based flag, disposable domain flag, matches-website-domain, confidence |
| Website | `website` | ✓ | — (it is the crawl subject) | ✓ (bio link) | All | Reachability, HTTP status/redirect, canonical domain, strip tracking params |
| Rating | `rating` | ✓ | ✗ | ✗ | **Maps only** | Range 0–5; hide badge, `minRating` filter and `sortBy=rating` for non-Maps leads |
| Review count | `reviewCount` | ✓ | ✗ | ✗ | **Maps only** | Integer ≥ 0; hide for non-Maps, `minReviews` excludes non-Maps |
| Open now | `isOpenNow` | ✓ | ✗ | ✗ | **Maps only** | Timezone-aware; refresh policy; hide for non-Maps |
| Opening hours | `openingHours` | ✓ | partial | partial | Maps + some web/social | Parse into structured hours; compute open/closed |
| Social profile links | `socialLinks` | partial | ✓ (footer/social icons) | ✓ (canonical profile) | All | Canonicalize URLs, strip query, validate handle/company path, dedupe, confidence |
| WhatsApp availability | derived from phones / `socialLinks` | partial (`wa.me` in listing) | ✓ (`wa.me` links) | partial (bio link) | Some | Must be a mobile number + `wa.me` evidence, not a guess |
| Source(s) | `sources` | ✓ | ✓ | ✓ | All | Set semantics; a lead can be Maps + web; drives the source badge |
| Confidence score | `confidenceScore` | computed | computed | computed | All | 0–100 from contact count, validation status, source agreement |
| Discovered at | `discoveredAt` | ✓ | ✓ | ✓ | All | Clock handling, "2 days ago" formatting |
| Saved state / saved at | `isSaved`, `savedAt` | local | local | local | All | Local only, never from a source |
| Status | `status` | local | local | local | All | Enum only (`newLead`, `contacted`, `replied`, `closed`) |
| Tags | `tags` | local | local | local | All | Trim, dedupe, max count/length |
| Note | `note` | local | local | local | All | Length cap |
| Reminder | `reminderAt` | local | local | local | All | Timezone, past-date handling, local notifications later |
| List membership | `listIds` | local | local | local | All | Referential integrity with `LeadList` |

### 7.1 Filters and sorts that depend on engine capability

| Filter / sort | Depends on | Behaviour for leads that lack the data |
|---------------|-----------|-----------------------------------------|
| `hasEmail` / `hasPhone` / `hasWebsite` / `hasWhatsApp` / `hasSocial` | extraction depth per source | Leads without the field are excluded |
| `noWebsite` (Pro) | Maps `website` presence | Only meaningful on Maps results; social profiles always have a link, so they are excluded |
| `minRating`, `minReviews` | Maps rating/reviews | Non-Maps leads cannot satisfy them → excluded when set |
| `openStatus.openNow` | Maps open state | Non-Maps leads excluded when set |
| `mustInclude` / `exclude` | name, category, description keywords | Applied after normalization; case/space-insensitive |
| `radiusKm` | lat/lng | Non-geocoded leads excluded when radius < country-wide |
| `depth` fast / deep | website crawl | Deep = fetch contact/about pages for emails/phones |
| `maxResults` 25/50/100/200 | engine result cap | 200 is Pro |
| `sortBy` relevance / rating / reviews / newest / name | rating & reviews = Maps only | Rating/review sorts place non-Maps leads last (stable) |
| `dedupe` | name + phone + domain fingerprint | Merge contact points, keep best confidence |
| `skipSaved` | local saved set | Exclude already-saved leads |
| `removeInvalidPhones` | phone validation | Drop leads whose only phones are invalid |
| `groupByCity` | city normalization | Groups section headers |

---

## 8. Discrepancies and resolutions

### 8.1 The known conflicts (a–g)

**a) `DESIGN.md` colors are obsolete.** It specifies indigo `#4F46E5`, teal `#0D9488`, amber
`#F59E0B`, semantic green/red/blue, gradients and a pale indigo background `#F8FAFC`. None of this
appears in the approved screens. **Resolution:** colors come only from `code.html` (Section 2);
`DESIGN.md` is used for font families, the 4/8/12/16/20/24/32/48 spacing steps, the 4/8/12/16/24/pill
radius steps (mapped to 8/12/16/pill in code) and the 100/200/300 ms motion tokens.

**b) Bottom navigation 4 tabs vs 3 tabs.** `home_screen` and `saved_leads` show Search, Saved, History,
Settings; `settings` shows Search, Saved, Settings. There is no History screen mockup. **Resolution:**
three tabs — Search, Saved, Settings — defined once in `lib/core/constants/nav_tabs.dart` as `navTabs`.
Adding History later is a one-line data change plus a route; no widget changes.
**Resolved 26 Nov 2026:** three tabs are final; History is not a destination.

**c) Icon names rendered as text in `search_results`.** The contact rows print `call`, `mail`,
`language` as literal text because the icon font failed to load in that file. **Resolution:** real
rounded icons (`Icons.call_rounded`, `Icons.mail_rounded`, `Icons.language_rounded`) at 20 px in
`textMuted`, exactly as the other screens do. No icon name is ever rendered as string content.

**d) Blue dot in `go_pro`.** The paywall's header chip uses `#60A5FA` (`.spec-pill span.dot`). It sits
outside the phone frame (documentation chrome), but it is still a hue and is removed. **Resolution:**
neutral dot — `#8A8A8A` light / `#737373` dark (`textMuted`); nothing blue exists in the app.

**e) "Direct & Verified".** `lead_detail` labels its contact card "Direct & Verified". The app does not
verify emails or phones yet. **Resolution:** the label becomes **"Public contact details"**, and the
email note stays **"Found on a public page, not verified."** The results-screen notice "Emails are
unverified" is matched to the same language: **"Contact details are sourced publicly and unverified."**
No UI copy anywhere claims verification. Status words use icons + weight only.
**Resolved 26 Nov 2026:** the only approved use of the word "verify" is the Pro feature line "AI to
organize, format and verify leads", which keeps its "Coming soon" badge. `test/decisions_test.dart`
fails if any other string in `app_strings.dart` mentions verification.

**f) Sample reviews and rating in `go_pro`.** Three reviews and a "4.7 Play store" metric are invented.
**Resolution:** kept as design-only dummy data, stored in `AppStrings` with
`kShowSampleProReviews = kDebugMode` and a doc comment "SAMPLE DATA — replace with real Play Store
reviews before release"; the caption "Sample reviews for design only" stays visible. A release build
renders no reviews section and no rating metric at all — invented testimonials never ship.

**g) Mixed Outlined + Rounded Material Symbols.** **Resolution:** `Icons.*_rounded` everywhere,
centralized in `lib/core/constants/app_icons.dart` so a wrong family cannot sneak in.

### 8.2 Additional discrepancies found

| # | Finding | Resolution |
|---|---------|-----------|
| h | Dark frames are inconsistent: `lead_detail` has a light-styled "dark" frame; `saved_leads`, `search_filters`, `export_leads`, `settings` mix light values in; `go_pro` uses its own off-palette dark set | **Final:** dark theme is the normalized `home_screen`/`search_results` dark set (Section 2). The six off-palette dark frames are mockup noise and must never be copied literally. Every alternate maps to a canonical token (Section 2.3) |
| i | Three different neutral families are mixed (neutral `#525252`, zinc `#71717A/#F4F4F5/#E4E4E7`, slate-ish `#666/#555/#444`) | One neutral scale, role-based tokens. Screening maps are in Section 2.3 |
| j | Corners: cards are radius 16, but tiles/actions vary 10/12/14/16/20 and chips/badges are pills | Four radius tokens (8/12/16/pill) plus `tile` 14; every value in the mockups falls on one of them |
| k | Text below 13 px everywhere: 10 px ad tag and filter count, 11 px nav labels/"Pro sources"/"PRO" badges, 12 px Pro pill/ad copy | Raise to 13 px; adjust pill padding so nothing clips. The app-wide minimum is 13 px and is asserted by the gallery |
| l | Touch targets below 48 px: 16 px checkboxes, 28 px badges, 32–40 px icon buttons, 36 px chips | Visual size preserved where safe; tap area expanded to ≥ 48 px with transparent padding or `MaterialTapTargetSize.padded` |
| m | `search_results` uses `#FAFAFA` for its body while home/others use `#FFFFFF`; saved uses `#FFFFFF` | Intentional layering: `canvas` (`#FAFAFA`) for list/filter/export/settings bodies, `background` (`#FFFFFF`) for home/detail. Both are tokens |
| n | Bottom nav shows four tabs on two screens and three on settings; nav heights 56 vs 64, labels 11 vs 12 vs 13 | One `AppBottomNav`: height 64, labels 13, 40 × 28 pill indicator, three tabs |
| o | `saved_leads` list-chip row fades out with a CSS gradient mask | Gradients are banned. The row clips at the content edge; a 1 px border separates the row. No fade |
| p | Two different selected-segment styles (white box with shadow vs filled primary) | Both are supported: boxed-white is the default segmented style, filled-primary is used for the lead-detail status control. Nothing blue, both monochrome |
| q | Switch colors differ per screen (black track/white thumb vs white track/black knob) | One themed monochrome switch: on = `primary` track with `onPrimary` thumb; off = `disabled` track with `background` thumb |
| r | `search_filters` draws its slider thumb as a white circle with a black border; Material's default thumb is a filled dot | Themed `Slider` with `primary` thumb and `primary`/`disabled` track; no custom painting in A1 |
| s | `go_pro` prices say "₹2,999 / year" but its bottom bar says "₹2,999 billed yearly"; monthly/weekly captions are only in the list | Keep both: plan row shows unit price, sticky bar shows the selected plan's billing caption |
| t | `go_pro`'s comparison table uses a literal `—` and plain "Unlimited" (font shifts mid-cell) | `—` stays text; "Unlimited" uses the same 13 px label style as other cells, with Pro column at weight 600 |
| u | `settings` bottom-nav labels are 11 px while `home_screen` uses 12 px | 13 px everywhere |
| v | `export_leads` format tiles are 72 px with an icon tile + title + mono extension, but `search_results` labels the same formats only in the bar caption | Both presentations are correct for their context; no change |
| w | `lead_detail` shows "Mobile (second number)" but the data model must express phone kinds | Label derives from `PhoneKind`: mobile → "Mobile", landline → "Landline", tollFree → "Toll-free", plus a secondary marker when a second phone exists |
| x | `settings` "Contact support" shows `support@yourdomain`, a placeholder domain | Keep as the mockup's placeholder, flagged in `AppStrings` as a TODO until the real address exists |
| y | `home_screen` status bar/time and notch are mockup chrome, not app UI | Not implemented; the real system status bar is used |
| z | `search_results` does not show a bottom nav, but is reached from a tab and the bar has no back-to-search affordance besides the app-bar arrow | Implemented as a pushed route with the app-bar back arrow; bottom nav hidden (as drawn) |

---

## 9. Resolved decisions and remaining questions

### 9.1 Resolved decisions (26 November 2026)

These are final. Where a decision is enforceable, code and tests enforce it — not just this document.

1. **Navigation — exactly three tabs: Search, Saved, Settings.** History is not a destination. The
   Search screen keeps its "Recent" list with "Clear all"; that is where past searches live. The
   two four-tab frames (`home_screen`, `saved_leads`) are outdated. Defined once as `navTabs`.
2. **Dark palette — the normalized values are final.** Dark theme uses the `home_screen` /
   `search_results` dark set recorded in Section 2. The six remaining off-palette dark frames
   (`lead_detail`, `saved_leads`, `search_filters`, `export_leads`, `settings`, `go_pro`) are mockup
   noise and must not be copied literally. Nothing in the app may introduce a new neutral.
3. **Trust copy — "Public contact details", never "Verified".** The lead-detail contact card header
   is "Public contact details"; the email note stays "Found on a public page, not verified." The only
   approved use of the word "verify" is the Pro feature line "AI to organize, format and verify
   leads", which always carries its "Coming soon" badge. `test/decisions_test.dart` fails on any other
   mention of verification in `app_strings.dart`.
4. **Sample Pro reviews and the 4.7 rating are debug-only.** `kShowSampleProReviews` derives from
   `kDebugMode`; a release build renders no "What users say" section and no rating metric. Real Play
   Store reviews must replace the sample list before launch.
5. **Prices are final: ₹2,999 / year, ₹299 / month, ₹99 / week. No trial.** Yearly shows "Save 16%"
   and "About ₹250 / month". Both are *derived* from the plan numbers in `ProPlan`, never written as
   literals, and no other price text may exist anywhere in `lib/` (guarded by a test — this is what
   retires the earlier ₹249 drift).
6. **"Recently active" is removed.** `OpenStatus` has exactly two values, `any` and `openNow`, and
   open-now applies to Maps leads only. The Filters screen shows a 2-option status segment. There is
   no social last-activity data, so offering the filter would be a promise the app cannot keep.
7. **Plans and trial.** The three plans above are the launch set; there is no free trial and no
   annual-only discount beyond the derived 16% saving.

### 9.2 Still open

These do not block any screen prompt (B1–B8): each has a safe default implemented already.

1. **Free saved-lead cap behaviour on lapse** — the Free cap is 50 saved leads. If a Pro subscription
   lapses with more than 50 saved, are the extra leads read-only, oldest-hidden, or export-only?
   Safe default: keep all leads readable, block only *new* saves until under the cap.
2. **WhatsApp action** — show it only when a `wa.me` link exists in the source, or also for any valid
   mobile number? Safe default: mobile numbers only (`PhoneKind.supportsWhatsApp`).
3. **Currency and locale** — INR and English only for v1. Confirm no localization before launch.
4. **Support contact** — `support@yourdomain` is a placeholder and needs a real address.
5. **Export file name** — should the default follow the search ("dentists-ahmedabad-leads") and stay
   editable? Drawn that way; treated as editable.
6. **Verification badges later** — if a future engine exposes validation states, Section 7's
   `ValidationStatus` already models them as icon + label. Confirm the wording before any badge ships.

---

*End of reference.*

## 10. Testing

Two commands must stay green:

```
flutter analyze     # zero issues, no exceptions
flutter test        # every unit, widget, router, guard and golden test
```

| Suite | What it protects |
|-------|------------------|
| `test/app_test.dart` | The app builds in light and dark and the three tabs switch. |
| `test/router_test.dart` | Bottom nav appears on exactly `/search`, `/saved`, `/settings`; every pushed route covers it and restores it on pop. |
| `test/monochrome_guard_test.dart` | No `Color(0x…)` or named `Colors.*` outside `lib/core/theme`. |
| `test/decisions_test.dart` | No copy claims verification; sample reviews follow `kDebugMode`; `OpenStatus` has two values; prices are exact and derived; no stray rupee amount anywhere in `lib/`. |
| `test/entitlements_test.dart` | Every Free/Pro gate rule and the two plan constants. |
| `test/dummy_data_test.dart` | 42 / 31 / 40 leads, 128 saved with the 42/38/19/29 split and 14/9/36/22 lists, deterministic output, and all data is fictional (`.example`, `+91 00000 xxxxx`, no real brand names). |
| `test/fake_engine_test.dart` | The event sequence per scenario and the terminal event for empty, error and cancel. |
| `test/fake_repositories_test.dart` | Saved CRUD, lists and counts, quota drain, history dedupe, settings, subscription, export. |
| `test/golden/shared_widgets_golden_test.dart` | Core widgets at 390 px in both themes (tag `golden`). |

**Goldens.** Generate with

```
flutter test --update-goldens --tags golden
```

Golden images are **platform sensitive**: glyph rasterization and shadows differ between operating systems, so generate them on the same OS that verifies them (these were generated on Windows). Committing goldens generated on another platform will fail here and vice versa. The test tag is declared in `dart_test.yaml`.

Fonts are bundled, so no network is involved. A widget test still starts with the placeholder test font, so the golden file registers Plus Jakarta Sans, Inter, JetBrains Mono and Material Icons from the asset bundle once in `setUpAll`; without that every glyph and icon would render as a block. No other test needs font loading.

## 11. Architecture for B, C and D prompts

### 11.1 Layers and the one seam

```
core/          theme, constants (strings, icons, nav), router          — no data
domain/models  immutable data shapes                                   — no logic
domain/repositories  interfaces only (LeadSearchEngine, LeadRepository,
                     SearchHistoryRepository, SettingsRepository,
                     QuotaRepository, SubscriptionRepository, ExportService)
domain/entitlements  Entitlements + FeatureGate                        — the only Free/Pro truth
data/fake/     in-memory implementations + DummyData                   — development only
app/providers.dart   the seam: one provider per interface              — swap point for C and D
shared/widgets A1 component library                                    — pure props
features/      screens (prompts B1–B8)                                 — consume providers only
```

Rules that keep the seam intact:

1. **A screen never imports `data/fake`.** It imports `domain/repositories`, `domain/models` and `app/providers.dart`.
2. **A screen never compares limits.** It asks `ref.watch(featureGateProvider)` (`canUseSource`, `maxResultsOptions`, `reasonForLock`, …).
3. **A screen never hard-codes a route or a price.** Routes come from `AppRoutes`/`AppNavigator`; prices from `ProPlan`.
4. **All copy comes from `core/constants/app_strings.dart`**, grouped per screen.
5. **Every provider is a plain Riverpod `Provider`/`StreamProvider`**, so a test can `overrideWithValue` any of them.

### 11.2 How a screen prompt consumes providers

Search results, as the pattern for every B prompt:

```dart
class ResultsPage extends ConsumerStatefulWidget { … }

// 1. Entitlements: locked UI, ads, result caps.
final FeatureGate gate = ref.watch(featureGateProvider);

// 2. Data: read the interface, never the fake.
final LeadSearchEngine engine = ref.read(leadSearchEngineProvider);
final LeadRepository saved = ref.read(leadRepositoryProvider);

// 3. Start a run and drive the UI from the event stream.
Stream<SearchEvent> run = engine.search(
  SearchRequest(id: searchId, query: query, filters: filters),
);
```

Saved, Home and Settings follow the same shape with `LeadRepository`, `SearchHistoryRepository`, `QuotaRepository` and `SettingsRepository`; the Export screen uses `ExportService`; the paywall uses `SubscriptionRepository`.

### 11.3 The SearchEvent flow the Results screen follows

The stream always ends with exactly one `SearchCompleted` or `SearchFailed`, and the hierarchy is `sealed`, so a `switch` is exhaustive and a state cannot be forgotten:

| Event | What the screen does |
|-------|----------------------|
| `SearchStarted(searchId, sources)` | Hide the previous list, show the skeleton, draw the per-source status chips as `pending`. |
| `SearchProgress(stage, sourceStatuses, leadsFoundSoFar)` | Update the stage caption (`ResultsStrings.loadingQuerying` … `loadingDeduplicating`), the source chip states (`running` / `done` / `blocked` / `skippedPro` / `failed`) and the live count. |
| `SearchPartialResults(leads, foundSoFar)` | Render these leads immediately and keep the list interactive; keep listening for the rest. |
| `SearchCompleted(summary)` | Fill the stats strip from `total` / `withEmail` / `withPhone`, show per-source outcomes, enable export, write a `SearchHistoryEntry`. |
| `SearchFailed(error)` | Switch on `error.type`: `noResults` → empty state, `noNetwork` → retry state, `rateLimited` → “slow down” copy, `sourceBlocked` → partial-warning, `cancelled` → back to the previous screen. Never parse `message` to decide the state. |

Cancelling is `engine.cancel(searchId)` (the stream then ends with a `cancelled` failure). Disposing the subscription must also cancel the run.

### 11.4 How C and D replace the fakes

* **Prompt C (storage)** implements `LeadRepository`, `SearchHistoryRepository`, `SettingsRepository` and `QuotaRepository` over SQLite and changes only those four provider bodies in `app/providers.dart`. The fake already behaves like a real store (async, stream-first, full CRUD, live list counts), so screens need no edits.
* **Prompt D (engine)** implements `LeadSearchEngine.search`/`cancel` and changes `leadSearchEngineProvider`. It must emit the same events in the same order contract; `test/fake_engine_test.dart` doubles as the contract test, so a real-engine test can assert the identical sequence.
* **Prompt E (billing/export)** implements `SubscriptionRepository` and `ExportService`, changing two providers. Entitlements then come from the store instead of the debug switch, and every gate in the UI already follows.
* Nothing in `data/fake` may leak into `features/`. When C and D land, `data/fake` stays as the test double, which is why its latency and seed are injectable.

### 11.5 Debug controls for building screens

`/dev/gallery` (debug builds only) has a “Fake data scenarios” section: `normal`, `slow`, `empty`, `no network`, `rate limited`, `partial: source blocked`, plus a pretend-Pro switch. That is how B prompts check loading, empty, error and locked states without a network or a purchase. The scenario feeds `FakeLeadSearchEngine`; the Pro switch feeds `FakeSubscriptionRepository`, which is the only thing that decides entitlements.

## 12. Ads model

**There are no banner ads, no native ads and no ad slot in any layout.** The mockup's home banner was removed
(Section 3.9); the only two formats are a *rewarded* ad the user opts into before a Free search and an
*interstitial* at a natural break. Both run through one coordinator and one frequency policy, so no screen can
invent its own rules.

### 12.1 The two formats

| | Rewarded | Interstitial |
|---|---|---|
| When | Before a Free search, after an explicit opt-in | Only at a break the user finished |
| Consent | `AppDialog`: “Watch ad”, “Go Pro”, “Cancel” | None; it is the price of the Free tier |
| If it fails | Proceed anyway, logged | Nothing happens, logged |
| If the user refuses | Stay on Home; no search, no quota use | n/a |
| Pro | Never shown, never loaded | Never shown, never loaded |

### 12.2 Rewarded: the Free search flow

1. Find Leads validates the form. Invalid → nothing happens.
2. The quota is checked. Exhausted → `/pro` with `LockReason.dailySearchLimitReached`.
3. Free users get the opt-in `AppDialog`. Cancel or “Go Pro” releases the button and stays on Home.
4. `AdCoordinator.runRewardedGate()` preloads if needed, shows the ad and returns exactly one of
   `proceed` (reward earned), `cancelledByUser` (closed early) or `skippedNoAd` (no fill, load error, playback
   error, SDK exception).
5. `proceed` and `skippedNoAd` both navigate to `/results`; only `cancelledByUser` stays, with
   `AdsStrings.rewardedDismissed`. An ad problem must never cost a Free user their search.
6. Home records the action in `AdPolicy` but never consumes quota or writes history. B2 does both, after a
   search completes with at least one lead.

### 12.3 Interstitial frequency

One `AdPolicy` per session, in `lib/domain/ads/ad_policy.dart`. All numbers are in `AdPolicyConfig`:

| Rule | Default | Why |
|---|---|---|
| Chance when everything else passes | 35% | Frequent enough to earn, rare enough not to annoy |
| Minimum gap between interstitials | 120 s | Never two in a row |
| Completed user actions between interstitials | 2 | The user has to have *done* something |
| No interstitial in the first | 60 s | Never at launch |
| No interstitial within | 60 s after a rewarded ad | The user just watched one |
| Pro | always false | Paid means ad-free |
| Busy | always false | Never while typing, loading or while a dialog is open |

Triggers are finished actions only: `AdTrigger.resultsClosed` (B2), `leadSaved` and `leadDetailClosed` (B3/B4),
`exportFinished` (B6). App resume is deliberately not a trigger. Screens call
`AdCoordinator.maybeShowInterstitial(trigger, isBusy: …)`; the coordinator applies the policy, shows, and calls
`recordInterstitialShown()`, which resets the action counter and starts the interval clock. `recordUserAction()`
is called when the user completes something.

### 12.4 Failure, logging and the test ad

`AdCoordinator` never throws: an SDK error becomes a logged skip. `AdLogger` is the seam for prompt E's
analytics/crash reporter; the default prints `[ads] …` in debug builds only. `FakeAdService` presents
`TestAdPage`, a plainly labelled five-second stand-in, instead of an SDK. It is debug-only and prompt E replaces
it with AdMob behind the same `AdService` interface.

### 12.5 Debug controls

The gallery's “Search, quota and ads (B1)” section sets the remaining Free searches (0–5), clears and restores
the seeded recents, picks the location outcome and the rewarded/interstitial outcomes, forces the next
interstitial past the policy roll, reads the live policy counters, opens the test ad page and shows the real
opt-in dialog. That is how every ad and quota state is checked without a network, an SDK or a purchase.

### 12.6 What B1 does not do

No ads SDK, no ad unit ids, no consent-management platform, no billing, and no interstitial trigger of its own:
B1 ships the policy, the coordinator, the rewarded flow on Home and the fake ad page, and later prompts call the
triggers they own.

## 13. Engine build policy

The lead engine is prompt D. When its capabilities are specified, **the first step is always a package
search, not a file**.

**Rule.** For every capability the engine needs, check maintained Flutter or Dart packages first. Use a package
whenever one qualifies; write custom code only where none does.

**A package qualifies when all of these hold:**

- actively maintained (recent releases, issues answered, no abandoned upstream);
- a permissive license (MIT/BSD/Apache-2.0; no copyleft we cannot ship);
- Android support on the minimum SDK, with no missing platform channel;
- no unacceptable terms-of-service or legal risk for the data source it touches (scraping restrictions, API
  terms, personal-data rules);
- a small footprint: no transitive dependency that pulls in a second HTTP stack, a database or a large native
  library.

**Capabilities to evaluate this way** (the list will grow as the engine is specified): HTTP with timeouts and
retries, rate limiting and backoff, HTML parsing and CSS selection, phone number parsing and
mobile/landline classification, email syntax and domain checks, DNS/MX lookup, export writers (CSV, XLSX, PDF,
vCard), and vCard generation.

**Recording.** Every package evaluated — accepted or rejected — is written into the engine's section of this
document with: the capability, the package and version, the decision, and the reason in one line (maintenance,
license, platform support, footprint, or data-source terms). A rejected package is as important to record as an
accepted one: it stops the next session from re-running the same evaluation.

**Not done here.** B2 researches no packages and adds no dependency. It only records the policy so prompt D
starts from it.
