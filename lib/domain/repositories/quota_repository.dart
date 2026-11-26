/// The free tier's daily search allowance.
///
/// The *limit* lives in `Entitlements.freeSearchesPerDay`; this repository only
/// tracks consumption. Keeping them apart means a pricing change never has to
/// migrate stored counters.
///
/// Implemented by a fake now and by prompt C's local store later. The count
/// resets at local midnight; prompts B and C decide exactly when that reset runs.
abstract interface class QuotaRepository {
  /// Searches left today. Emits again after every [consumeOne].
  Stream<int> watchRemainingToday();

  /// Spends one search and returns the new remaining count. Junior to the caller:
  /// the Search screen checks the gate first, so this never goes below zero.
  Future<int> consumeOne();
}
