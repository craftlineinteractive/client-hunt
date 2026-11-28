/// The contract between the UI and the data layer.
///
/// Screens depend on these interfaces, never on `data/fake` or a real
/// implementation. Fakes implement them today; prompts C (storage) and D (lead
/// engine) supply the production versions, and only the providers in
/// `lib/app/providers.dart` change.
library;

export 'contact_launcher.dart';
export 'export_service.dart';
export 'lead_repository.dart';
export 'lead_search_engine.dart';
export 'quota_repository.dart';
export 'search_history_repository.dart';
export 'settings_repository.dart';
export 'share_service.dart';
export 'subscription_repository.dart';
