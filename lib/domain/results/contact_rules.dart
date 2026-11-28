import '../models/models.dart';

/// Which outreach actions a lead actually supports.
///
/// Pure predicates over a [Lead], so the card, the actions row and any later
/// screen agree about what is possible without repeating the conditions. The
/// rules are deliberately conservative:
///
/// * a call needs *any* phone number;
/// * WhatsApp needs a **mobile** number — a landline or toll-free line cannot
///   receive a WhatsApp message, so the action is disabled rather than failing;
/// * an email needs any address;
/// * copying needs a phone or an email (it copies whichever values exist).
abstract final class ContactRules {
  const ContactRules._();

  /// True when the lead has a number that can be dialled.
  static bool canCall(Lead lead) => lead.hasPhone;

  /// True when the lead has a mobile number, the only kind WhatsApp accepts.
  static bool canWhatsApp(Lead lead) =>
      lead.phones.any((PhoneContact phone) => phone.kind.supportsWhatsApp);

  /// True when the lead has an address.
  static bool canEmail(Lead lead) => lead.hasEmail;

  /// True when there is something to put on the clipboard.
  static bool canCopy(Lead lead) => lead.hasPhone || lead.hasEmail;

  /// The phone the UI treats as the lead's main number.
  ///
  /// The `isPrimary` contact wins; otherwise the first number, which the engine
  /// orders best-first.
  static PhoneContact? primaryPhone(Lead lead) => lead.primaryPhone;

  /// The email the UI treats as the lead's main address, same rule.
  static EmailContact? primaryEmail(Lead lead) => lead.primaryEmail;

  /// The primary mobile number, for WhatsApp, or `null` when none exists.
  static PhoneContact? whatsAppPhone(Lead lead) {
    for (final PhoneContact phone in lead.phones) {
      if (phone.kind.supportsWhatsApp) {
        return phone;
      }
    }
    return null;
  }
}
