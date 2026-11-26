/// Shared copy used in more than one place.
///
/// Screen-local strings can live with their screen; anything repeated, or any
/// string with a legal/trust implication, belongs here so it stays consistent.
abstract final class AppStrings {
  // Product.
  static const String appName = 'ClientHunt';
  static const String wordmark = 'ClientHunt';
  static const String tagline = 'Find your next client';
  static const String question = 'Who are you looking for?';

  // Navigation.
  static const String searchTab = 'Search';
  static const String savedTab = 'Saved';
  static const String settingsTab = 'Settings';

  // Search form.
  static const String nicheHint = 'Niche, e.g. Dentists';
  static const String locationHint = 'City or area, e.g. Ahmedabad';
  static const String sources = 'Sources';
  static const String proSources = 'Pro sources';
  static const String findLeads = 'Find Leads';
  static const String recent = 'Recent';
  static const String clearAll = 'Clear all';
  static const String useMyLocation = 'Use my location';
  static const String filters = 'Filters';
  static const String applyFilters = 'Apply filters';
  static const String reset = 'Reset';

  // Trust language. The app never claims verification.
  static const String publicContactDetails = 'Public contact details';
  static const String notVerifiedNote = 'Found on a public page, not verified.';
  static const String unverifiedNotice =
      'Contact details are sourced publicly and unverified.';
  static const String storedOnDevice =
      'Your leads are stored only on this device.';

  // Ads.
  static const String adLabel = 'Ad';
  static const String adHeadline = 'Scale B2B Outbound on Autopilot';

  // Placeholders.
  static const String placeholderCaption =
      'Placeholder screen — built in a later prompt.';

  // Sample data.
  static const String sampleReviewsCaption = 'Sample reviews for design only';
  static const String sampleRating = '4.7';
  static const String sampleRatingSource = 'Play store';
}

/// **SAMPLE DATA FLAG.**
///
/// The paywall mockup shows three invented reviews and a 4.7 rating. They are
/// design-only and **must be replaced with real Play Store data before release**.
/// Set this to `false` to hide the whole "What users say" section until real
/// reviews exist.
const bool kShowSampleProReviews = true;

/// **SAMPLE DATA — do not ship.** Invented review copy, names and roles from the
/// paywall mockup. Replace with real reviews before release.
const List<({String text, String name, String role, String initials})>
kSampleProReviews = <({String text, String name, String role, String initials})>[
  (
    text:
        'Exporting 200 clinic contacts directly into Excel with verified email '
        'addresses saved me over 15 hours of manual lookup this week alone.',
    name: 'Amit K.',
    role: 'Agency Owner',
    initials: 'AK',
  ),
  (
    text:
        'The deep search feature pulls personal outreach emails from websites '
        'that other scrapers consistently miss. Worth every rupee.',
    name: 'Priya S.',
    role: 'B2B Consultant',
    initials: 'PS',
  ),
  (
    text:
        'Targeting local businesses with no website has been a goldmine for '
        'selling web design packages. Paid for the yearly plan on day one.',
    name: 'Rahul M.',
    role: 'Freelancer',
    initials: 'RM',
  ),
];
