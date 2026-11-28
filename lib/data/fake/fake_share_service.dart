import '../../domain/repositories/contact_launcher.dart';
import '../../domain/repositories/share_service.dart';

/// Records what would have been shared instead of opening a share sheet.
///
/// Development and widget tests use this: it proves the screen built the right
/// text, and lets a test choose the outcome.
class FakeShareService implements ShareService {
  FakeShareService({
    this.result = ContactLaunchResult.launched,
    this.latency = Duration.zero,
  });

  /// What every share returns.
  final ContactLaunchResult result;

  /// Simulated platform latency.
  final Duration latency;

  final List<String> _shared = <String>[];

  /// Every shared text, in order.
  List<String> get shared => List<String>.unmodifiable(_shared);

  /// The most recent text, or `null`.
  String? get lastShared => _shared.isEmpty ? null : _shared.last;

  /// Forgets recorded shares (tests).
  void clear() => _shared.clear();

  @override
  Future<ContactLaunchResult> shareText(String text) async {
    _shared.add(text);
    if (latency > Duration.zero) {
      await Future<void>.delayed(latency);
    }
    return result;
  }
}
