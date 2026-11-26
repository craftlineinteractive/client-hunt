/// How trustworthy a single contact point is.
///
/// There is no color coding in the UI: the status is shown with an icon and a
/// label. The engine assigns it during extraction; A1 only defines the shape.
enum ValidationStatus {
  /// Not checked yet (default for freshly extracted values).
  unchecked(displayName: 'Unchecked'),

  /// Passed every check: syntactically valid and confirmed to belong to the
  /// business (for example an email on the business's own domain with a live MX).
  valid(displayName: 'Valid'),

  /// Passed format checks but not confirmed against the business.
  likelyValid(displayName: 'Likely valid'),

  /// Plausible but risky: role address, free provider, or a pattern guess.
  risky(displayName: 'Risky'),

  /// Failed a hard check (bad syntax, dead domain, wrong line type).
  invalid(displayName: 'Invalid');

  const ValidationStatus({required this.displayName});

  /// Label for the lead-detail contact rows.
  final String displayName;

  /// Whether the value should still be shown as a usable contact.
  bool get isUsable =>
      this == ValidationStatus.valid || this == ValidationStatus.likelyValid;
}
