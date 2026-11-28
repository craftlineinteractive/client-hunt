import 'package:flutter/foundation.dart';

import '../../domain/repositories/contact_launcher.dart';

/// One recorded outreach attempt.
@immutable
class ContactLaunchRecord {
  const ContactLaunchRecord({required this.channel, required this.value});

  /// Which action was requested.
  final ContactChannel channel;

  /// The phone number, address or URL it was given.
  final String value;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ContactLaunchRecord &&
            other.channel == channel &&
            other.value == value;
  }

  @override
  int get hashCode => Object.hash(channel, value);

  @override
  String toString() => 'ContactLaunchRecord(${channel.name}, $value)';
}

/// Records outreach attempts instead of opening anything.
///
/// Development and widget tests use this: it proves the card wired the right
/// channel and value, and lets a test choose the outcome. The real
/// platform-intent implementation arrives in prompt D; the interface it
/// implements is already final.
class FakeContactLauncher implements ContactLauncher {
  FakeContactLauncher({
    this.result = ContactLaunchResult.launched,
    this.latency = Duration.zero,
  });

  /// What every call returns.
  final ContactLaunchResult result;

  /// Simulated launch latency.
  final Duration latency;

  final List<ContactLaunchRecord> _calls = <ContactLaunchRecord>[];

  /// Every attempt, in order.
  List<ContactLaunchRecord> get calls =>
      List<ContactLaunchRecord>.unmodifiable(_calls);

  /// The most recent attempt, or `null`.
  ContactLaunchRecord? get lastCall => _calls.isEmpty ? null : _calls.last;

  /// Forgets recorded calls (tests).
  void clear() => _calls.clear();

  @override
  Future<ContactLaunchResult> call(String phone) =>
      _record(ContactChannel.phone, phone);

  @override
  Future<ContactLaunchResult> whatsApp(String phone) =>
      _record(ContactChannel.whatsApp, phone);

  @override
  Future<ContactLaunchResult> email(String address) =>
      _record(ContactChannel.email, address);

  @override
  Future<ContactLaunchResult> openUrl(String url) =>
      _record(ContactChannel.url, url);

  Future<ContactLaunchResult> _record(
    ContactChannel channel,
    String value,
  ) async {
    _calls.add(ContactLaunchRecord(channel: channel, value: value));
    if (latency > Duration.zero) {
      await Future<void>.delayed(latency);
    }
    return result;
  }
}
