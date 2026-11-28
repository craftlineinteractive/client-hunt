import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/router/app_router.dart';
import '../data/fake/fake.dart';
import '../domain/ads/ad_coordinator.dart';
import '../domain/ads/ad_policy.dart';
import '../domain/entitlements/entitlements.dart';
import '../domain/entitlements/feature_gate.dart';
import '../domain/models/models.dart';
import '../domain/repositories/ad_service.dart';
import '../domain/repositories/location_service.dart';
import '../domain/repositories/repositories.dart';

/// **The provider graph — the seam between UI and data.**
///
/// One provider per domain interface, each returning the fake by default:
///
/// | Provider | Interface | Development source |
/// |---|---|---|
/// | `leadSearchEngineProvider` | `LeadSearchEngine` | `FakeLeadSearchEngine` |
/// | `leadRepositoryProvider` | `LeadRepository` | `FakeLeadRepository` |
/// | `searchHistoryRepositoryProvider` | `SearchHistoryRepository` | fake |
/// | `settingsRepositoryProvider` | `SettingsRepository` | fake |
/// | `quotaRepositoryProvider` | `QuotaRepository` | fake |
/// | `subscriptionRepositoryProvider` | `SubscriptionRepository` | fake |
/// | `exportServiceProvider` | `ExportService` | fake |
///
/// Screens must depend on the *interfaces*: watch a provider, call its methods,
/// and never import `data/fake`. Prompts C and D replace the implementations here
/// — no screen or widget changes. Tests override any provider with
/// `overrideWithValue(...)`.
///
/// The whole graph reads from one [dummyDataSetProvider] so the saved store, the
/// search results and the history agree about the same 42 and 128 leads.

/// The single demo data snapshot every fake is built from.
final Provider<DummyDataSet> dummyDataSetProvider = Provider<DummyDataSet>(
  (Ref ref) => DummyData.build(),
);

/// Runs searches. Rebuilt when the debug scenario changes, so the *next* search
/// uses the new scenario without disturbing existing state.
final Provider<LeadSearchEngine> leadSearchEngineProvider =
    Provider<LeadSearchEngine>((Ref ref) {
      return FakeLeadSearchEngine(
        scenario: ref.watch(fakeScenarioProvider),
        data: ref.watch(dummyDataSetProvider),
      );
    });

/// Saved leads and lists.
final Provider<LeadRepository> leadRepositoryProvider =
    Provider<LeadRepository>((Ref ref) {
      return FakeLeadRepository(data: ref.watch(dummyDataSetProvider));
    });

/// Recent searches.
final Provider<SearchHistoryRepository> searchHistoryRepositoryProvider =
    Provider<SearchHistoryRepository>((Ref ref) {
      return FakeSearchHistoryRepository(data: ref.watch(dummyDataSetProvider));
    });

/// App settings.
final Provider<SettingsRepository> settingsRepositoryProvider =
    Provider<SettingsRepository>((Ref ref) => FakeSettingsRepository());

/// Today's free search count.
final Provider<QuotaRepository> quotaRepositoryProvider =
    Provider<QuotaRepository>((Ref ref) => FakeQuotaRepository());

/// Whether the user has Pro. Controlled by the debug switch for now.
final Provider<SubscriptionRepository> subscriptionRepositoryProvider =
    Provider<SubscriptionRepository>((Ref ref) {
      return FakeSubscriptionRepository(
        isPro: ref.watch(fakeProEnabledProvider),
      );
    });

/// Export file writing and clipboard helpers.
final Provider<ExportService> exportServiceProvider = Provider<ExportService>(
  (Ref ref) => const FakeExportService(),
);

/// Opens the dialler, WhatsApp, the mail composer and the browser.
///
/// A fake that records attempts in B2; prompt D supplies the platform-intent
/// implementation behind the same interface. Copy actions do **not** use this:
/// they go to Flutter's own `Clipboard`.
final Provider<ContactLauncher> contactLauncherProvider =
    Provider<ContactLauncher>((Ref ref) => FakeContactLauncher());

/// Live entitlements for the current (fake) subscription.
///
/// While the stream has not emitted yet, or if it errors, callers should fall
/// back to [freeEntitlements] — never to Pro.
final StreamProvider<Entitlements> entitlementsProvider =
    StreamProvider<Entitlements>(
      (Ref ref) =>
          ref.watch(subscriptionRepositoryProvider).watchEntitlements(),
    );

/// The gate screens use: `ref.watch(featureGateProvider).canUseSource(...)`.
///
/// Falls back to Free until entitlements arrive, so a cold start can never grant
/// a Pro feature for a frame.
final Provider<FeatureGate> featureGateProvider = Provider<FeatureGate>((
  Ref ref,
) {
  final Entitlements entitlements =
      ref.watch(entitlementsProvider).value ?? freeEntitlements;
  return FeatureGate(entitlements);
});

/// The user's settings, streamed. Home reads its defaults from here.
final StreamProvider<AppSettings> settingsProvider =
    StreamProvider<AppSettings>(
      (Ref ref) => ref.watch(settingsRepositoryProvider).watch(),
    );

/// Searches left today, streamed. `null` until the first value arrives.
final StreamProvider<int> remainingSearchesProvider = StreamProvider<int>(
  (Ref ref) => ref.watch(quotaRepositoryProvider).watchRemainingToday(),
);

/// The most recent searches, newest first.
///
/// Two rows, matching the mockup's Recent block; the repo supports any limit.
final StreamProvider<List<SearchHistoryEntry>> recentSearchesProvider =
    StreamProvider<List<SearchHistoryEntry>>(
      (Ref ref) =>
          ref.watch(searchHistoryRepositoryProvider).watchRecent(limit: 2),
    );

/// Resolves the current city. Fake by default; prompt E supplies the platform
/// implementation behind the same interface.
final Provider<LocationService> locationServiceProvider =
    Provider<LocationService>((Ref ref) {
      return FakeLocationService(
        outcome: ref.watch(fakeLocationOutcomeProvider),
      );
    });

/// Rewarded and interstitial ads.
///
/// Rebuilt when the debug panel changes the fake outcomes, so the next ad picks
/// them up. The test-ad page is pushed on [rootNavigatorKey].
final Provider<AdService> adServiceProvider = Provider<AdService>((Ref ref) {
  return FakeAdService(
    config: ref.watch(fakeAdConfigProvider),
    navigatorKey: rootNavigatorKey,
  );
});

/// The single interstitial frequency policy for the session.
///
/// A plain provider, so its counters survive tab switches and screen pushes.
final Provider<AdPolicy> adPolicyProvider = Provider<AdPolicy>(
  (Ref ref) => AdPolicy(),
);

/// The only object screens may use to run an ad.
final Provider<AdCoordinator> adCoordinatorProvider = Provider<AdCoordinator>((
  Ref ref,
) {
  final Entitlements entitlements =
      ref.watch(entitlementsProvider).value ?? freeEntitlements;
  return AdCoordinator(
    adService: ref.watch(adServiceProvider),
    policy: ref.watch(adPolicyProvider),
    entitlements: entitlements,
    isInterstitialForced: () => ref.read(forcedInterstitialProvider),
  );
});
