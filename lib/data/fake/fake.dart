/// Development implementations of every domain interface.
///
/// Screens must never import this library: they depend on `domain/repositories`
/// and receive the fakes through providers. Prompt C swaps the storage fakes and
/// prompt D the engine, changing only `lib/app/providers.dart`.
library;

export 'dummy_data.dart';
export 'fake_ad_service.dart';
export 'fake_contact_launcher.dart';
export 'fake_export_service.dart';
export 'fake_lead_repository.dart';
export 'fake_lead_search_engine.dart';
export 'fake_location_service.dart';
export 'fake_quota_repository.dart';
export 'fake_scenario.dart';
export 'fake_search_history_repository.dart';
export 'fake_settings_repository.dart';
export 'fake_subscription_repository.dart';
