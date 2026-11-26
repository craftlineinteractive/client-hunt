@Tags(<String>['golden'])
library;

import 'package:clienthunt/core/constants/app_icons.dart';
import 'package:clienthunt/core/constants/app_strings.dart';
import 'package:clienthunt/core/theme/app_spacing.dart';
import 'package:clienthunt/core/theme/app_theme.dart';
import 'package:clienthunt/data/fake/fake.dart';
import 'package:clienthunt/domain/models/models.dart';
import 'package:clienthunt/shared/widgets/shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pixel snapshots of the shared widgets, light and dark, at 390 px width.
///
/// Regenerate on the machine that will verify them:
///
///     flutter test --update-goldens --tags golden
///
/// Fonts are bundled with the app, so nothing is fetched over the network. A
/// widget test nonetheless starts with the test placeholder font, so this file
/// registers the three bundled families from the asset bundle once; without that
/// every glyph would render as a block. Images are platform sensitive (glyph
/// rasterization differs by OS): a golden generated on Windows is not a valid
/// baseline for macOS.
void main() {
  setUpAll(_loadBundledFonts);

  final DummyDataSet data = DummyData.build(now: DateTime(2026, 11, 26, 9));
  final List<ThemeMode> modes = <ThemeMode>[ThemeMode.light, ThemeMode.dark];

  Future<void> shoot(
    WidgetTester tester,
    String name,
    Widget child,
    ThemeMode mode,
  ) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: mode,
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: child,
          ),
        ),
      ),
    );
    // Fixed-duration pumps rather than pumpAndSettle: the loading button's
    // spinner animates forever, so a settle would time out and the frame would
    // depend on when it stopped.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/$name.${mode.name}.png'),
    );
  }

  testWidgets('AppButton variants and states', (WidgetTester tester) async {
    await tester.pump();
    final Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppButton(label: 'Find Leads', onPressed: () {}),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          label: 'Find Leads',
          onPressed: () {},
          size: AppButtonSize.large,
          icon: AppIcons.search,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          label: 'Secondary',
          onPressed: () {},
          variant: AppButtonVariant.secondary,
          icon: AppIcons.email,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          label: 'Ghost action',
          onPressed: () {},
          variant: AppButtonVariant.ghost,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton(label: 'Loading', onPressed: () {}, isLoading: true),
        const SizedBox(height: AppSpacing.sm),
        const AppButton(label: 'Disabled'),
      ],
    );

    for (final ThemeMode mode in modes) {
      await shoot(tester, 'app_button', content, mode);
    }
  });

  testWidgets('AppChip states', (WidgetTester tester) async {
    final Widget content = Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: <Widget>[
        AppChip(label: 'Selected', isSelected: true, onTap: () {}),
        AppChip(label: 'Unselected', tone: AppChipTone.outlined, onTap: () {}),
        AppChip(
          label: 'Maps',
          isSelected: true,
          showCheckWhenSelected: true,
          leadingIcon: AppIcons.maps,
          size: AppChipSize.large,
          onTap: () {},
        ),
        AppChip(
          label: 'Instagram',
          leadingIcon: AppIcons.instagram,
          size: AppChipSize.large,
          isLocked: true,
          onTap: () {},
        ),
        AppChip(
          label: 'Hot leads',
          trailingCount: 14,
          tone: AppChipTone.outlined,
          onTap: () {},
        ),
        const AppChip(
          label: 'Disabled',
          tone: AppChipTone.outlined,
          isEnabled: false,
        ),
      ],
    );

    for (final ThemeMode mode in modes) {
      await shoot(tester, 'app_chip', content, mode);
    }
  });

  testWidgets('StatusPill and ProBadge', (WidgetTester tester) async {
    const Widget content = Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        StatusPill(label: 'New'),
        StatusPill(label: 'Contacted'),
        StatusPill(label: 'Replied'),
        StatusPill(label: 'Closed'),
        ProBadge(),
        ProBadge(showLock: false),
        FreeBadge(),
        SourceBadge(label: 'Maps'),
      ],
    );

    for (final ThemeMode mode in modes) {
      await shoot(tester, 'status_pill_pro_badge', content, mode);
    }
  });

  testWidgets('LeadCard with full data', (WidgetTester tester) async {
    final Widget content = LeadCard(
      lead: data.heroLead,
      onTap: () {},
      onBookmark: () {},
    );

    for (final ThemeMode mode in modes) {
      await shoot(tester, 'lead_card_full', content, mode);
    }
  });

  testWidgets('LeadCard with a missing email', (WidgetTester tester) async {
    final Lead noEmail = data.dentistResults.firstWhere(
      (Lead lead) => !lead.hasEmail,
    );
    final Widget content = LeadCard(
      lead: noEmail,
      onTap: () {},
      onBookmark: () {},
    );

    for (final ThemeMode mode in modes) {
      await shoot(tester, 'lead_card_missing_email', content, mode);
    }
  });

  testWidgets('LeadCard saved and selected', (WidgetTester tester) async {
    final Lead saved = data.savedLeads.first.copyWith(
      status: LeadStatus.contacted,
    );
    final Widget content = LeadCard(
      lead: saved,
      isSelected: true,
      showCheckbox: true,
      onTap: () {},
      onBookmark: () {},
      trailing: const StatusPill(label: 'Contacted'),
    );

    for (final ThemeMode mode in modes) {
      await shoot(tester, 'lead_card_saved', content, mode);
    }
  });

  testWidgets('ContactRow layouts', (WidgetTester tester) async {
    final Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: ContactRow(
                  icon: AppIcons.phone,
                  label: LeadDetailStrings.phoneLabel,
                  value: '+91 00000 00001',
                  onCopy: () {},
                  copyTooltip: 'Copy phone',
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: ContactRow(
                  icon: AppIcons.email,
                  label: LeadDetailStrings.emailLabel,
                  value: 'contact@northline-dental-studio.example',
                  extraIcon: AppIcons.externalLink,
                  extraTooltip: 'Open',
                  onExtra: () {},
                  onCopy: () {},
                  copyTooltip: 'Copy email',
                ),
              ),
              const Divider(height: 1),
              const Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: ContactRow(
                  icon: AppIcons.website,
                  value: '',
                  isMissing: true,
                  missingText: ResultsStrings.noWebsiteFound,
                ),
              ),
              const Divider(height: 1),
              const Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: ContactRow(
                  icon: AppIcons.mobile,
                  value: '+91 00000 00002',
                  isCompact: true,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    for (final ThemeMode mode in modes) {
      await shoot(tester, 'contact_row', content, mode);
    }
  });

  testWidgets('SettingsGroup with rows and toggles', (
    WidgetTester tester,
  ) async {
    final Widget content = SettingsGroup(
      title: SettingsStrings.searchDefaults,
      children: <Widget>[
        SettingsRow(
          label: SettingsStrings.defaultSources,
          icon: AppIcons.layers,
          value: 'Maps',
          onTap: () {},
        ),
        SettingsRow(
          label: SettingsStrings.maxResults,
          icon: AppIcons.numbers,
          value: '50',
          isMonoValue: true,
          onTap: () {},
        ),
        ToggleRow(
          label: SettingsStrings.removeDuplicates,
          icon: AppIcons.copyStack,
          value: true,
          onChanged: (bool value) {},
        ),
        ToggleRow(
          label: SettingsStrings.skipSaved,
          icon: AppIcons.savedOutline,
          value: false,
          onChanged: (bool value) {},
        ),
        SettingsRow(
          label: SettingsStrings.privacyPolicy,
          icon: AppIcons.shield,
          trailing: SettingsTrailing.external,
          onTap: () {},
        ),
      ],
    );

    for (final ThemeMode mode in modes) {
      await shoot(tester, 'settings_group', content, mode);
    }
  });

  testWidgets('StickyActionBar', (WidgetTester tester) async {
    final Widget content = BottomActionBar(
      primaryLabel: ResultsStrings.exportLeads,
      primaryIcon: AppIcons.download,
      onPrimary: () {},
      caption: ResultsStrings.exportFormatsCaption,
    );

    for (final ThemeMode mode in modes) {
      await shoot(tester, 'sticky_action_bar', content, mode);
    }
  });

  testWidgets('SelectionActionBar', (WidgetTester tester) async {
    final Widget content = SelectionActionBar(
      selectedCount: 3,
      actions: <SelectionAction>[
        SelectionAction(
          icon: AppIcons.download,
          tooltip: SavedStrings.exportSelectedTooltip,
          onTap: () {},
        ),
        SelectionAction(
          icon: AppIcons.addToList,
          tooltip: SavedStrings.addToListTooltip,
          onTap: () {},
        ),
        SelectionAction(
          icon: AppIcons.delete,
          tooltip: SavedStrings.deleteTooltip,
          onTap: () {},
          isDestructive: true,
        ),
      ],
    );

    for (final ThemeMode mode in modes) {
      await shoot(tester, 'selection_action_bar', content, mode);
    }
  });

  testWidgets('AppBottomNav', (WidgetTester tester) async {
    final Widget content = ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AppBottomNav(currentIndex: 0, onTap: (int index) {}),
    );

    for (final ThemeMode mode in modes) {
      await shoot(tester, 'app_bottom_nav', content, mode);
    }
  });
}

/// Registers the bundled font families for the test renderer.
Future<void> _loadBundledFonts() async {
  Future<void> load(String family, String asset) async {
    final FontLoader loader = FontLoader(family)
      ..addFont(rootBundle.load(asset));
    await loader.load();
  }

  await load(
    'Plus Jakarta Sans',
    'assets/fonts/plus_jakarta_sans/PlusJakartaSans-Variable.ttf',
  );
  await load('Inter', 'assets/fonts/inter/Inter-Variable.ttf');
  await load(
    'JetBrains Mono',
    'assets/fonts/jetbrains_mono/JetBrainsMono-Variable.ttf',
  );
  // Icons come from the Material icon font, which the test renderer also starts
  // without; `uses-material-design: true` puts it in the bundle.
  await load('MaterialIcons', 'fonts/MaterialIcons-Regular.otf');
}
