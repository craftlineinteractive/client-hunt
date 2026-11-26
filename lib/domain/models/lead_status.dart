/// The CRM stage of a saved lead.
///
/// These four values are the only statuses the UI knows: the lead-detail
/// segmented control and the saved-leads filter/status pill both read from this
/// enum. No other state is inferred from contact activity.
enum LeadStatus {
  /// Saved but not contacted yet.
  newLead(displayName: 'New'),

  /// Outreach was sent.
  contacted(displayName: 'Contacted'),

  /// The business replied.
  replied(displayName: 'Replied'),

  /// The opportunity is closed (won or lost — the app does not distinguish).
  closed(displayName: 'Closed');

  const LeadStatus({required this.displayName});

  /// Label used by the status pill and segmented control.
  final String displayName;
}
