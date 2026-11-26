import 'package:flutter/foundation.dart';

/// Shared copy used in more than one place.
///
/// Screen-local strings can live with their screen; anything repeated, or any
/// string with a legal/trust implication, belongs here so it stays consistent.
///
/// **Trust rule:** the app never claims our contact data is verified. The only
/// approved use of "verify" is [aiVerifyFeature], a Pro feature that is marked
/// "Coming soon" and describes a future product capability, not our data.
abstract final class AppStrings {
  // Product.
  static const String appName = 'ClientHunt';
  static const String wordmark = 'ClientHunt';
  static const String tagline = 'Find your next client';
  static const String question = 'Who are you looking for?';

  // Navigation.
  static const String searchTab = 'Search';
  static const String savedTab = 'Saved';
  static const String savedLeadsTitle = 'Saved leads';
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

  /// The only approved use of the word "verify": a *future* Pro capability,
  /// always shown with a "Coming soon" badge. It describes the product, not the
  /// contact data, and `app_strings_test.dart` allowlists exactly this name.
  static const String aiVerifyFeature =
      'AI to organize, format and verify leads';
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
///
/// The flag follows [kDebugMode]: sample reviews and the sample rating render in
/// debug builds only, so a release build shows no social proof at all rather than
/// shipping invented testimonials. Replace this flag *and* [kSampleProReviews]
/// with real, fetched reviews before launch.
const bool kShowSampleProReviews = kDebugMode;

/// **SAMPLE DATA — do not ship.** Invented review copy, names and roles from the
/// paywall mockup. Replace with real reviews before release.
const List<({String text, String name, String role, String initials})>
kSampleProReviews = <({String text, String name, String role, String initials})>[
  (
    text:
        'Exporting 200 clinic contacts directly into Excel with usable email '
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
