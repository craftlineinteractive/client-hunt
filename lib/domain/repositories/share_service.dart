import 'contact_launcher.dart';

/// Sends text to the platform share sheet.
///
/// Kept separate from [ContactLauncher] because sharing is not a contact
/// channel: it has no address, it needs no permission, and prompt E may want to
/// log it differently. `share_plus` is deliberately **not** a dependency yet —
/// the fake records the text and the platform implementation arrives with the
/// real intents in prompt D.
abstract interface class ShareService {
  /// Opens the share sheet with [text] and reports how it ended.
  ///
  /// Never throws: a device without a share target answers
  /// [ContactLaunchResult.unavailable].
  Future<ContactLaunchResult> shareText(String text);
}
