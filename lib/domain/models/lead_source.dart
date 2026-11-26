/// Where a lead was discovered.
///
/// Maps is available to everyone. Every social source is a Pro entitlement (see
/// README section 6); [isPro] drives the lock icon and the paywall gate so the
/// rule lives in one place.
enum LeadSource {
  /// Google Maps / business listing. The only source with rating, review count
  /// and live open/closed state.
  maps(displayName: 'Maps', isPro: false),

  /// Instagram business/profile search.
  instagram(displayName: 'Instagram', isPro: true),

  /// LinkedIn company/people search.
  linkedin(displayName: 'LinkedIn', isPro: true),

  /// Facebook page search.
  facebook(displayName: 'Facebook', isPro: true),

  /// X (formerly Twitter) profile search.
  x(displayName: 'X', isPro: true),

  /// A plain website found while crawling (not a lead source the user can pick in
  /// A1; used to tag leads that came from a web page).
  web(displayName: 'Web', isPro: false);

  const LeadSource({required this.displayName, required this.isPro});

  /// Human label used in source pills and badges.
  final String displayName;

  /// Whether this source requires a Pro subscription.
  final bool isPro;

  /// True for sources whose leads never carry rating, reviews or open state.
  bool get isSocialOnly => this != LeadSource.maps && this != LeadSource.web;
}
