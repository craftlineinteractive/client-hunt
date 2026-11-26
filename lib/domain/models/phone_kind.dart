/// The line type of a phone number.
///
/// Derived by the engine from numbering-plan rules, never guessed from length
/// alone. Used for the lead-detail row label ("Mobile", "Landline",
/// "Toll-free") and to decide whether a WhatsApp action is plausible — WhatsApp
/// needs a mobile number, not a landline.
enum PhoneKind {
  /// Mobile number.
  mobile(displayName: 'Mobile'),

  /// Fixed-line number.
  landline(displayName: 'Landline'),

  /// Toll-free / customer-care number.
  tollFree(displayName: 'Toll-free'),

  /// Not determined yet.
  unknown(displayName: 'Phone');

  const PhoneKind({required this.displayName});

  /// Row label used on lead detail.
  final String displayName;

  /// Whether a WhatsApp chat can be assumed to work with this number.
  bool get supportsWhatsApp => this == PhoneKind.mobile;
}
