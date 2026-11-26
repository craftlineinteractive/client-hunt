import '../entitlements/entitlements.dart';
import '../models/models.dart';

/// Where the app learns what the user has paid for.
///
/// The fake (`data/fake/fake_subscription_repository.dart`) is the development
/// source; prompt E replaces it with the Play Billing / store implementation.
/// Nothing else in the app may decide what is Free: everything reads
/// [Entitlements] through this stream.
abstract interface class SubscriptionRepository {
  /// Emits the current entitlements, and again whenever they change.
  Stream<Entitlements> watchEntitlements();

  /// The purchasable plans, in display order.
  Future<List<ProPlan>> availablePlans();
}

/// The safe default used before the data layer is consulted: **Free**.
///
/// Treating "unknown" as Pro would give away paid features during startup, a
/// failed purchase restore, or a test; treating it as Free never does.
class FreeSubscriptionRepository implements SubscriptionRepository {
  const FreeSubscriptionRepository();

  @override
  Stream<Entitlements> watchEntitlements() =>
      Stream<Entitlements>.value(freeEntitlements);

  @override
  Future<List<ProPlan>> availablePlans() async => ProPlan.all;
}
