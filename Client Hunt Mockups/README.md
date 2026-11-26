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
| Surface | `surface` | `#F5F5F5` | `#141414` | Grouped input fill, unselected chip fill, segmented-control track, ad slot, pill backgrounds |
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
| `#F5F5F5` | Grouped fields, chips, ad slot, off rows, dividers in export | `surface` / `dividerSubtle` |
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

### 3.9 Ad slot

`AdBannerPlaceholder` — 320 × 50, radius 12, fill `surface` (`#F9F9F9` dashed in saved), 1 px border
(`#E5E5E5`; dashed `#D4D4D4` in saved), centered "Ad" label 13 mono uppercase (mockup 10 px) in
`textMuted` and a 13 px supporting line in `textSecondary`. Variant with a `Learn more` underlined
action. Free users only; Pro removes it. Real ads arrive in prompt E — until then this is a labelled
placeholder, never a fake ad.

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
   - **Ad slot** centered 320 × 50: "AD" + "Scale B2B Outbound on Autopilot".
3. **Bottom nav** — 3 tabs, Search active.

**States.** Empty fields; niche filled only; both filled (CTA enabled); free quota exhausted (quota pill
shows "0/5" and CTA opens paywall); locked source tapped; recent list empty (hide block).

**Interactive elements.** Two text fields, location autofill button, 6 niche chips, 5 source pills,
4 quick-filter chips, Find Leads, Clear all, 2 recent rows, Pro pill, settings button, 3 nav tabs.

**Dummy data.** Quota "3/5 free today"; recent searches above; filters count "2" (Email + Phone).

**Pro-gated.** Social sources (Instagram, LinkedIn, Facebook, X). The "Pro sources" label is
informational, not a control.

**Shared components.** `AppTopBar.tab`, `ProBadge`, `AppChip`, `AppTextField` (+ group), `AppButton`,
`AppCard`, `AdBannerPlaceholder`, `AppBottomNav`, `SectionHeader` (Recent/Sources).

**Lead fields.** None directly (the screen produces `SearchQuery`); recent rows show result counts and
source.

**Flutter notes.** `SingleChildScrollView` over a `Column`; the body scrolls, the app bar and bottom nav
are fixed. Chip rows are `SizedBox(height: …)` + horizontal `ListView` with `ClipRect`. Two
`TextEditingController`s in a small local state object (Riverpod form state arrives in B2). CTA must sit
inside the scrolling content (the mockup scrolls it), not in a sticky bar.

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
`AppIconButton`, `BottomActionBar`, `AdBannerPlaceholder` (Free only, below the list).

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
picker. "Remove lead" → confirm dialog. Ad slot only for Free.

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
9. **Ad slot** 320 × 50, centered, 24 px bottom padding.

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
`AppButton`, `AppIconButton`, `AdBannerPlaceholder`, `InfoNote`.

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
6. **Ad slot** 320 × 50 dashed variant: "Ad" tag + "Auto-sync leads with CRM integration" +
   "Learn more" (Free only).
7. **Floating selection bar** (when selection > 0): inverse pill above the nav, live dot + "1 selected",
   actions `file_download_rounded`, `playlist_add_rounded`, `sell_rounded`, `delete_rounded` (36 px
   buttons, 44 tap).
8. **Bottom nav** — 3 tabs, Saved active.

**States.** Empty (EmptyState: bookmark icon, "Nothing saved yet", body, "Find leads" → `/search`);
no results for a filter; free saved-lead limit reached (banner/upsell card); selection 0 vs n; missing
note; missing channel; reminder overdue (icon + weight, no red).

**Interactive elements.** Search, more, list chips, New list, 5 status segments, select all, sort, view
toggle, per-card checkbox, card, 3 action buttons per card, ad action, 4 selection actions, nav tabs.

**Dummy data.** 128 saved / 42 new / 38 contacted / 19 replied / 29 closed; list counts 14/9/36/22;
five cards above.

**Pro-gated.** Unlimited saved leads/lists (free limit is 50 — see Section 6). Reaching the limit shows
`ProUpsellCard` and the save action opens the paywall.

**Shared components.** `AppTopBar.tab`, `AppChip`, `AppSegmentedControl`, `StatusPill`, `AppCard`,
`InitialsAvatar`, `AppIconButton`, `SelectionActionBar`, `AdBannerPlaceholder`, `EmptyState`,
`ProUpsellCard`, `AppBottomNav`.

**Lead fields.** name, category, area/city, status, tags, note, reminderAt, savedAt, phones, emails,
website, listIds.

**Flutter notes.** `CustomScrollView` with a `SliverAppBar`-free layout: app bar fixed, list chips and
status control scroll with the list (they are not sticky in the mockup). Cards are
`features/saved/widgets/saved_lead_card.dart` in B. Selection state is local in B, Riverpod in C.

<!-- CONTINUE -->
