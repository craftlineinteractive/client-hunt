import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/fake/fake.dart';
import '../domain/entitlements/entitlements.dart';
import '../domain/entitlements/feature_gate.dart';
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
