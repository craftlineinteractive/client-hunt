import 'package:flutter/foundation.dart';

/// **All user-facing copy, grouped by screen.**
///
/// Screens reference these constants instead of inline literals so:
/// * wording stays consistent (especially the trust language),
/// * the strings test can guard the rules (`test/decisions_test.dart`),
/// * a future localization pass has one file to translate.
///
/// There is no logic here — only text. Dynamic values (counts, dates) are
/// composed at the call site; short affixes such as [CommonStrings.leadsSuffix]
/// exist so the noun stays identical everywhere.
///
/// **Trust rule:** the app never claims our contact data is verified. The only
/// approved use of "verify" is [ProStrings.aiVerifyFeature], a future Pro
/// capability always shown with a "Coming soon" badge.
abstract final class AppStrings {
  // Product identity.
  static const String appName = 'ClientHunt';
  static const String wordmark = 'ClientHunt';
  static const String tagline = 'Find your next client';
  static const String version = '1.0.0 (1)';
  static const String madeBy = 'Made with care by Craftline Interactive';
  static const String supportEmail = 'support@yourdomain';
}

/// Copy shared by several screens.
abstract final class CommonStrings {
  // Navigation.
  static const String searchTab = 'Search';
  static const String savedTab = 'Saved';
  static const String settingsTab = 'Settings';

  // Verb / action labels.
  static const String cancel = 'Cancel';
  static const String close = 'Close';
  static const String done = 'Done';
  static const String apply = 'Apply';
  static const String reset = 'Reset';
  static const String retry = 'Try again';
  static const String save = 'Save';
  static const String delete = 'Delete';
  static const String add = 'Add';
  static const String selectAll = 'Select all';
  static const String clearAll = 'Clear all';

  // Counts and nouns.
  static const String leadsSuffix = 'leads';
  static const String emailsSuffix = 'emails';
  static const String phonesSuffix = 'phones';
  static const String resultsLabel = 'Results';

  // Tooltips.
  static const String backTooltip = 'Back';
  static const String closeTooltip = 'Close';
  static const String moreTooltip = 'More options';
  static const String copyTooltip = 'Copy';
  static const String sortTooltip = 'Sort';
  static const String filtersTooltip = 'Filters';
  static const String searchTooltip = 'Search';

  // Shared failures.
  static const String noNetworkTitle = 'No connection';
  static const String noNetworkBody = 'Check your connection and try again.';
  static const String genericErrorTitle = 'Something went wrong';
  static const String genericErrorBody = 'Please try again in a moment.';

  // Placeholders.
  static const String placeholderCaption =
      'Placeholder screen — built in a later prompt.';
}

/// Copy for the rewarded and interstitial ad model.
///
/// There are no banner or native ad placements in the product. A Free search is
/// preceded by an opt-in rewarded ad, and interstitials only appear at natural
/// breaks (see the README "Ads model" section).
abstract final class AdsStrings {
  // Rewarded opt-in dialog, shown before a Free search.
  static const String rewardedTitle = 'Watch a short ad to search';
  static const String rewardedBody =
      'Free searches are supported by a short ad. Pro searches run without '
      'ads.';
  static const String rewardedWatch = 'Watch ad';
  static const String rewardedGoPro = 'Go Pro';

  // Rewarded outcomes.
  static const String rewardedDismissed =
      'Watch the full ad to run your search.';
  static const String rewardedFailed = 'The ad could not be shown. Try again.';

  // Test ad page. Debug builds only; prompt E replaces it with AdMob.
  static const String testAdLabel = 'Test ad';
  static const String testAdRewardedHeadline = 'Sample rewarded ad';
  static const String testAdInterstitialHeadline = 'Sample interstitial ad';
  static const String testAdBody =
      'This stands in for a real ad. Prompt E swaps it for AdMob with test ad '
      'unit ids first.';
  static const String testAdRewardNote =
      'The reward is earned when this countdown ends.';
  static const String testAdClose = 'Close';
  static const String testAdSecondsSuffix = 's';

  // Settings and paywall copy that describes the ad model.
  static const String noBannersNote =
      'ClientHunt shows no banner ads — only an optional ad before a free '
      'search, and occasional full-screen ads at natural breaks.';
}

/// Search tab (`/search`).
abstract final class HomeStrings {
  static const String overline = 'Find your next client';
  static const String question = 'Who are you looking for?';
  static const String nicheHint = 'Niche, e.g. Dentists';
  static const String locationHint = 'City or area, e.g. Ahmedabad';
  static const String useMyLocation = 'Use my location';
  static const String sources = 'Sources';
  static const String proSources = 'Pro sources';
  static const String quickFilters = 'Quick filters';
  static const String filtersChip = 'Filters';
  static const String findLeads = 'Find Leads';
  static const String recent = 'Recent';
  static const String clearRecentTitle = 'Clear recent searches?';
  static const String clearRecentBody =
      'This removes your search history from this device. Saved leads are not '
      'affected.';
  static const String clearRecentConfirm = 'Clear history';
  static const String quotaSuffix = 'free today';
  static const String quotaExhaustedTitle = 'Daily searches used';
  static const String quotaExhaustedBody =
      'You have used today\'s free searches. Go Pro for unlimited searches, or '
      'wait until tomorrow.';
  static const String leadsReadySuffix = 'leads found';
}

/// Results (`/results`).
abstract final class ResultsStrings {
  static const String title = 'Search results';
  static const String searchInResults = 'Search within leads';
  static const String statsLeads = 'Leads';
  static const String statsEmails = 'Emails';
  static const String statsPhones = 'Phones';

  /// Approved negation. Not a claim that anything was verified.
  static const String unverifiedNotice =
      'Contact details are sourced publicly and unverified.';

  static const String filterAll = 'All';
  static const String filterEmail = 'Email';
  static const String filterPhone = 'Phone';
  static const String filterWebsite = 'Website';
  static const String filterWhatsApp = 'WhatsApp';
  static const String filterRating4 = 'Rating 4+';
  static const String filterSaved = 'Saved';

  static const String selectAll = 'Select all';
  static const String exportLeads = 'Export Leads';
  static const String exportFormatsCaption = 'CSV · Excel · PDF · VCF';
  static const String copyAllTooltip = 'Copy all contact details';
  static const String resultsFor = 'Results for';

  // Per-card copy.
  static const String noWebsiteFound = 'No website found';
  static const String noEmailFound = 'No email found';
  static const String noPhoneFound = 'No phone found';
  static const String openNow = 'Open now';
  static const String closedNow = 'Closed now';
  static const String saveLeadTooltip = 'Save lead';
  static const String removeSavedTooltip = 'Remove from saved';
  static const String callTooltip = 'Call';
  static const String whatsAppTooltip = 'WhatsApp';
  static const String emailTooltip = 'Email';
  static const String copyContactTooltip = 'Copy contact details';

  // Loading stages.
  static const String loadingQuerying = 'Searching sources';
  static const String loadingParsing = 'Reading listings';
  static const String loadingEnriching = 'Checking websites';
  static const String loadingValidating = 'Validating contacts';
  static const String loadingDeduplicating = 'Removing duplicates';
  static const String searchingMaps = 'Searching Maps';

  // Empty and error states.
  static const String emptyTitle = 'No leads found';
  static const String emptyBody =
      'Try a broader niche, a bigger area, or fewer filters.';
  static const String emptyAction = 'Edit filters';
  static const String resultLimitReached =
      'You reached this plan\'s result limit.';
  static const String cancelledNotice = 'Search cancelled.';

  // Toasts.
  static const String savedToast = 'Lead saved';
  static const String unsavedToast = 'Lead removed from saved';
  static const String copiedToast = 'Copied';
  static const String copiedEmailsToast = 'Emails copied';
  static const String copiedPhonesToast = 'Phones copied';
  static const String limitReachedToast = 'Saved-lead limit reached';
  static const String sourceBlockedToast = 'One source could not be searched';
}

/// Lead detail (`/lead/:id`).
abstract final class LeadDetailStrings {
  static const String title = 'Lead details';
  static const String saveToContacts = 'Save to contacts';
  static const String contactDetailsHeader = 'Contact details';

  /// Replaces the mockup's "Direct & Verified".
  static const String publicContactDetails = 'Public contact details';

  /// Approved negation, kept verbatim from the mockup.
  static const String notVerifiedNote = 'Found on a public page, not verified.';

  static const String phoneLabel = 'Phone';
  static const String secondNumberSuffix = 'second number';
  static const String emailLabel = 'Email';
  static const String websiteLabel = 'Website';
  static const String addressLabel = 'Address';

  static const String profiles = 'Profiles';
  static const String profilesCheckedSuffix = 'checked';
  static const String notFound = 'Not found';
  static const String profilesLockedHint =
      'Social profiles are included with Pro.';

  static const String businessDetails = 'Business details';
  static const String factRating = 'Rating';
  static const String factReviews = 'Reviews';
  static const String factHours = 'Hours';
  static const String factStatus = 'Status';
  static const String reviewsSuffix = 'reviews';

  static const String myNotes = 'My notes';
  static const String onlyOnDevice = 'Only on this device';
  static const String addTag = 'Add tag';
  static const String noteHint = 'Add a note about this lead...';
  static const String leadStatus = 'Lead status';
  static const String followUpReminder = 'Follow-up reminder';
  static const String reminderNotSet = 'Not set';
  static const String copyAllDetails = 'Copy all details';
  static const String removeLead = 'Remove lead';

  // Actions and tooltips.
  static const String callTooltip = 'Call';
  static const String whatsAppTooltip = 'WhatsApp';
  static const String emailTooltip = 'Email';
  static const String directionsTooltip = 'Directions';
  static const String shareTooltip = 'Share';
  static const String bookmarkTooltip = 'Save lead';
  static const String openWebsiteTooltip = 'Open website';
  static const String copyValueTooltip = 'Copy';

  // Confirmations.
  static const String removeTitle = 'Remove this lead?';
  static const String removeBody =
      'The lead and your notes are removed from this device. This cannot be '
      'undone.';
  static const String removeConfirm = 'Remove';

  // Toasts.
  static const String allDetailsCopied = 'All details copied';
  static const String savedToast = 'Lead saved';
  static const String removedToast = 'Lead removed';
  static const String statusUpdatedToast = 'Status updated';
  static const String noteSavedToast = 'Note saved';
  static const String reminderSetToast = 'Reminder set';
  static const String reminderClearedToast = 'Reminder cleared';
}

/// Saved leads (`/saved`).
abstract final class SavedStrings {
  static const String title = 'Saved leads';
  static const String allChip = 'All';
  static const String newList = 'New list';
  static const String newListTitle = 'Name this list';
  static const String newListHint = 'e.g. Ahmedabad clinics';
  static const String sortRecent = 'Recent';
  static const String viewToggleTooltip = 'Switch view';
  static const String savedAtPrefix = 'Saved';
  static const String agoSuffix = 'ago';
  static const String tomorrow = 'Tomorrow';
  static const String addToListTitle = 'Add to list';
  static const String addToListEmpty = 'No lists yet. Create one first.';
  static const String createListAction = 'Create list';

  // Empty states.
  static const String emptyTitle = 'Nothing saved yet';
  static const String emptyBody =
      'Save a lead from search results to start your pipeline.';
  static const String emptyAction = 'Find leads';
  static const String noResultsTitle = 'No leads here';
  static const String noResultsBody =
      'Nothing matches this list, status or search.';

  // Limit.
  static const String limitTitle = 'Saved-lead limit reached';
  static const String limitBody =
      'Free accounts can save 50 leads. Go Pro for unlimited saved leads and '
      'lists.';

  // Selection and deletion.
  static const String selectedSuffix = 'selected';
  static const String deleteTitle = 'Delete selected leads?';
  static const String deleteBody =
      'This removes the leads and their notes from this device.';
  static const String deletedToast = 'Leads deleted';
  static const String tagsUpdatedToast = 'Tags updated';
  static const String addedToListToast = 'Added to list';
  static const String exportSelectedTooltip = 'Export selected';
  static const String addToListTooltip = 'Add to list';
  static const String tagTooltip = 'Tag leads';
  static const String deleteTooltip = 'Delete leads';
}

/// Filters (`/filters`).
abstract final class FiltersStrings {
  static const String title = 'Filters';
  static const String contact = 'Contact';
  static const String hasEmail = 'Has email';
  static const String hasPhone = 'Has phone';
  static const String hasWebsite = 'Has website';
  static const String hasWhatsApp = 'Has WhatsApp number';
  static const String hasSocial = 'Has social profile link';
  static const String noWebsite = 'No website';
  static const String noWebsiteHint = 'Businesses without a website';

  static const String businessQuality = 'Business quality';
  static const String minimumRating = 'Minimum rating';
  static const String minimumReviews = 'Minimum reviews';
  static const String any = 'Any';
  static const String status = 'Status';

  static const String keywords = 'Keywords';
  static const String mustInclude = 'Must include';
  static const String exclude = 'Exclude';
  static const String keywordHint = 'Type keyword...';
  static const String mustIncludeSemantic = 'Must include keywords';
  static const String excludeSemantic = 'Excluded keywords';

  static const String area = 'Area';
  static const String country = 'Country';
  static const String radius = 'Radius';

  static const String results = 'Results';
  static const String searchDepth = 'Search depth';
  static const String fast = 'Fast';
  static const String fastSubtitle = 'Listing details only';
  static const String deep = 'Deep';
  static const String deepSubtitle = 'Also scans websites for emails';
  static const String maxResults = 'Max results';
  static const String sortBy = 'Sort by';

  static const String cleanup = 'Cleanup';
  static const String removeDuplicates = 'Remove duplicates';
  static const String skipSaved = 'Skip leads I already saved';
  static const String removeInvalidPhones = 'Remove invalid phone numbers';
  static const String groupByCity = 'Group by city';

  static const String applyFilters = 'Apply filters';
  static const String activeSuffix = 'filters active';
  static const String noneActive = 'No filters active';
  static const String lockedHint = 'Included with Pro';
}

/// Export (`/export`).
abstract final class ExportStrings {
  static const String title = 'Export leads';
  static const String whatToExport = 'What to export';
  static const String format = 'Format';
  static const String columns = 'Columns';
  static const String selectAll = 'Select all';
  static const String fileName = 'File name';
  static const String cleanup = 'Cleanup & formatting';
  static const String removeDuplicates = 'Remove duplicates';
  static const String skipNoContact = 'Skip leads without contact info';
  static const String headerRow = 'Add header row';
  static const String quickCopy = 'Quick copy';
  static const String copyEmails = 'Copy emails';
  static const String copyPhones = 'Copy phones';
  static const String copyCaption = 'Copies one per line, ready to paste.';
  static const String summarySeparator = ' · ';
  static const String shareTooltip = 'Share file';
  static const String exportPrefix = 'Export as';
  static const String emptyTitle = 'Nothing to export';
  static const String emptyBody = 'Save or find some leads first.';
  static const String emptyAction = 'Find leads';
  static const String copiedEmailsToast = 'Emails copied to clipboard';
  static const String copiedPhonesToast = 'Phones copied to clipboard';
  static const String exportedToast = 'Export ready';
  static const String exportFailedTitle = 'Export failed';
  static const String exportFailedBody = 'The file could not be written.';
  static const String selectedOnlyDisabled = 'Select leads first';
}

/// ClientHunt Pro paywall (`/pro`).
abstract final class ProStrings {
  static const String title = 'ClientHunt Pro';
  static const String subtitle = 'Find more leads, from more places.';
  static const String includedHeader = 'Included in all plans';
  static const String comingSoon = 'Coming soon';
  static const String restore = 'Restore';
  static const String continueLabel = 'Continue';
  static const String comparisonTitle = 'Free vs Pro comparison';
  static const String comparisonFeatureHeader = 'Feature';
  static const String comparisonFreeHeader = 'Free';
  static const String comparisonProHeader = 'Pro';

  // The eight included features.
  static const String featureSocialSources =
      'Search Instagram, LinkedIn, Facebook and X';
  static const String featureDeepSearch =
      'Deep search that scans websites for emails';
  static const String featureResults = 'Up to 200 results per search';
  static const String featureSaved = 'Unlimited saved leads and lists';
  static const String featureNoWebsite = 'Find businesses with no website';
  static const String featureExport = 'Export to CSV, Excel, PDF and VCF';
  static const String featureAds = 'Ad-free experience';
  static const String featureSupport = 'Priority support';

  /// The only approved use of "verify": a future capability, always badged
  /// "Coming soon". It describes the product, not our data.
  static const String aiVerifyFeature =
      'AI to organize, format and verify leads';

  static const List<String> includedFeatures = <String>[
    featureSocialSources,
    featureDeepSearch,
    featureResults,
    featureSaved,
    featureNoWebsite,
    featureExport,
    featureAds,
    featureSupport,
  ];

  // Comparison table cells.
  static const String comparisonMaps = 'Maps leads';
  static const String comparisonSocial = 'Social sources';
  static const String comparisonDeep = 'Deep search';
  static const String comparisonResults = 'Results per search';
  static const String comparisonSaved = 'Saved leads';
  static const String comparisonAds = 'Ads';
  static const String comparisonDash = '—';
  static const String comparisonUnlimited = 'Unlimited';
  static const String comparisonYes = 'Yes';
  static const String comparisonNo = 'No';

  // Social proof (debug builds only).
  static const String whatUsersSay = 'What users say';
  static const String playStore = 'Play store';
  static const String sampleReviewsCaption = 'Sample reviews for design only';

  // Footer and legal.
  static const String terms = 'Terms';
  static const String privacyPolicy = 'Privacy Policy';
  static const String restorePurchases = 'Restore purchases';
  static const String legalNote =
      'Subscription renews automatically until cancelled. Cancel anytime in '
      'Google Play.';
  static const String purchaseUnavailable =
      'Purchases arrive in a later build.';
  static const String restoredNothing = 'No previous purchase found.';
  static const String bestValue = 'Best value';
  static const String planSwitchFailed = 'Could not change plan. Try again.';
}

/// Settings (`/settings`).
abstract final class SettingsStrings {
  static const String title = 'Settings';
  static const String proCardTitle = 'ClientHunt Pro';
  static const String proCardBody = 'Unlock social sources and unlimited leads';
  static const String goPro = 'Go Pro';
  static const String manage = 'Manage';
  static const String manageSubscription = 'Manage subscription';

  static const String appearance = 'Appearance';
  static const String theme = 'Theme';
  static const String themeLight = 'Light';
  static const String themeDark = 'Dark';
  static const String themeSystem = 'System';
  static const String defaultCountry = 'Default country';

  static const String searchDefaults = 'Search defaults';
  static const String defaultSources = 'Default sources';
  static const String maxResults = 'Max results per search';
  static const String removeDuplicates = 'Remove duplicates';
  static const String skipSaved = 'Skip leads I already saved';

  static const String dataStorage = 'Data and storage';
  static const String storageUsed = 'Storage used';
  static const String exportAllSaved = 'Export all saved leads';
  static const String clearSearchHistory = 'Clear search history';
  static const String clearSavedLeads = 'Clear all saved leads';
  static const String storedOnDevice =
      'Your leads are stored only on this device.';

  static const String privacyAds = 'Privacy and ads';
  static const String adPersonalization = 'Ad personalization';
  static const String resetAdId = 'Reset advertising ID';
  static const String privacyChoices = 'Privacy choices';

  static const String support = 'Support';
  static const String rateApp = 'Rate ClientHunt';
  static const String shareApp = 'Share the app';
  static const String sendFeedback = 'Send feedback';
  static const String contactSupport = 'Contact support';
  static const String helpFaq = 'Help and FAQ';

  static const String aboutLegal = 'About and legal';
  static const String privacyPolicy = 'Privacy Policy';
  static const String termsOfUse = 'Terms of Use';
  static const String licenses = 'Open source licenses';
  static const String appVersion = 'App version';

  // Confirmations.
  static const String clearHistoryTitle = 'Clear search history?';
  static const String clearHistoryBody =
      'Recent searches are removed from this device.';
  static const String clearSavedTitle = 'Clear all saved leads?';
  static const String clearSavedBody =
      'Every saved lead, note, tag and reminder is removed from this device. '
      'This cannot be undone.';
  static const String clearSavedConfirm = 'Clear saved leads';

  // Toasts.
  static const String historyClearedToast = 'Search history cleared';
  static const String leadsClearedToast = 'Saved leads cleared';
  static const String settingUpdatedToast = 'Setting updated';
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
