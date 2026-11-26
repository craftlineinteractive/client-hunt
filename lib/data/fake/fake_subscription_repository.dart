import '../../domain/entitlements/entitlements.dart';
import '../../domain/models/models.dart';
import '../../domain/repositories/subscription_repository.dart';

/// Subscription state for development: Free or Pro, chosen by the debug switch.
///
/// This is the only fake that decides entitlements, so flipping it in the design
/// gallery exercises every locked/unlocked path in the UI without touching any
/// screen code.
class FakeSubscriptionRepository implements SubscriptionRepository {
  const FakeSubscriptionRepository({this.isPro = false});

  /// Whether the pretend user has an active subscription.
  final bool isPro;

  @override
  Stream<Entitlements> watchEntitlements() =>
      Stream<Entitlements>.value(isPro ? proEntitlements : freeEntitlements);

  @override
  Future<List<ProPlan>> availablePlans() async => ProPlan.all;
}
