import '../models/models.dart';

/// The channel an outreach action uses.
enum ContactChannel {
  /// Dial a number.
  phone,

  /// Open a WhatsApp chat with a mobile number.
  whatsApp,

  /// Compose an email.
  email,

  /// Open a web address.
  url,

  /// Open a map/directions app at an address or coordinate query.
  maps,

  /// Insert the lead into the device address book.
  contacts,
}

/// How an outreach action ended.
///
/// Three outcomes, because the UI needs three different responses: silence on
/// success, a "no app can do this" message on [unavailable], and a retryable
/// failure message on [failed]. Never an exception: a missing phone app must not
/// crash a lead list.
enum ContactLaunchResult {
  /// The platform opened the target app.
  launched,

  /// Nothing on this device can handle the request.
  unavailable,

  /// The attempt was made and failed.
  failed,
}

/// Opens the phone, WhatsApp, email client or browser for a lead action.
///
/// Implemented by `FakeContactLauncher` in development; prompt D adds the
/// platform-intent implementation behind the same interface (no `url_launcher`
/// dependency is added in B2). Screens call this and show a snackbar from
/// [ContactLaunchResult]; they never call `launchUrl` themselves.
abstract interface class ContactLauncher {
  /// Opens the dialler with [phone].
  Future<ContactLaunchResult> call(String phone);

  /// Opens a WhatsApp chat with [phone]; only ever called for a mobile number.
  Future<ContactLaunchResult> whatsApp(String phone);

  /// Opens the mail composer for [address].
  Future<ContactLaunchResult> email(String address);

  /// Opens [url] in a browser.
  Future<ContactLaunchResult> openUrl(String url);

  /// Opens a maps app at [query] (an address, or "lat,lng").
  Future<ContactLaunchResult> openMaps(String query);

  /// Inserts [lead] into the device address book.
  ///
  /// The platform implementation needs the contacts permission and arrives in a
  /// later prompt; the interface is final so the UI can be written and tested
  /// now.
  Future<ContactLaunchResult> saveToContacts(Lead lead);
}
