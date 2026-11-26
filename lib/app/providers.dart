import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entitlements/entitlements.dart';
import '../domain/entitlements/feature_gate.dart';
import '../domain/repositories/subscription_repository.dart';

/// **Provider graph.**
///
/// One provider per repository/engine interface, so a screen depends on an
/// interface and never on a concrete class. Every provider is a plain
/// `Provider` — tests override them with `overrideWithValue`, and prompts C and D
/// swap the fake for a real implementation without any widget change.
///
/// Subscription first: the entitlement stream is derived from it, and
/// [featureGateProvider] is what screens should watch for locked/unlocked UI.

/// The subscription source. Free by default; the fake arrives with the data layer
/// and prompt E replaces it with billing.
final Provider<SubscriptionRepository> subscriptionRepositoryProvider =
    Provider<SubscriptionRepository>(
      (Ref ref) => const FreeSubscriptionRepository(),
    );

/// Live entitlements for the signed-in (or anonymous) user.
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
