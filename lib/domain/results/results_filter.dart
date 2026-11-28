import 'package:flutter/foundation.dart';

import '../models/models.dart';
import 'contact_rules.dart';

/// The single-select chip above the result list.
///
/// Chips are client-side: the engine already ran, so a chip never searches
/// again. They combine with the text query using AND.
enum ResultsChip {
  /// No chip filter.
  all,

  /// Has at least one email address.
  email,

  /// Has at least one phone number.
  phone,

  /// Has a website.
  website,

  /// Has a mobile number, so WhatsApp is plausible.
  whatsApp,

  /// Maps rating of 4.0 or more. Leads without a rating never match.
  rating4Plus,

  /// Saved by the user.
  saved,
}

/// A chip, a text query and their AND combination.
///
/// Pure data with pure matching, so the controller, the tests and (later) Saved
/// can share one definition of "filtered". [savedIds] is passed in rather than
/// read from a lead, because Results must reflect a bookmark the moment it is
/// toggled — the lead copies inside the session are a snapshot.
@immutable
class ResultsFilter {
  const ResultsFilter({this.chip = ResultsChip.all, this.text = ''});

  /// Selected chip.
  final ResultsChip chip;

  /// Free-text query; empty means no text filtering.
  final String text;

  /// True when anything narrows the list.
  bool get isActive => chip != ResultsChip.all || text.trim().isNotEmpty;

  /// True when the query alone narrows the list (the inline search field).
  bool get hasText => text.trim().isNotEmpty;

  /// Copy with selected fields replaced.
  ResultsFilter copyWith({ResultsChip? chip, String? text}) =>
      ResultsFilter(chip: chip ?? this.chip, text: text ?? this.text);

  /// True when [lead] satisfies the chip **and** the text query.
  bool matches(Lead lead, {required Set<String> savedIds}) {
    if (!_matchesChip(lead, savedIds)) {
      return false;
    }
    final String query = text.trim().toLowerCase();
    if (query.isEmpty) {
      return true;
    }
    return _matchesText(lead, query);
  }

  /// The leads that survive the filter, in their original order.
  List<Lead> apply(Iterable<Lead> leads, {required Set<String> savedIds}) {
    return List<Lead>.unmodifiable(
      leads.where((Lead lead) => matches(lead, savedIds: savedIds)),
    );
  }

  bool _matchesChip(Lead lead, Set<String> savedIds) {
    return switch (chip) {
      ResultsChip.all => true,
      ResultsChip.email => lead.hasEmail,
      ResultsChip.phone => lead.hasPhone,
      ResultsChip.website => lead.hasWebsite,
      ResultsChip.whatsApp => ContactRules.canWhatsApp(lead),
      ResultsChip.rating4Plus => (lead.rating ?? 0) >= 4,
      ResultsChip.saved => lead.isSaved || savedIds.contains(lead.id),
    };
  }

  /// Matches name, category, area, phone digits, email and website domain.
  ///
  /// Phone numbers are compared by digits as well as by their rendered form, so
  /// "0000001001" finds "+91 00000 01001" without the user typing spaces.
  static bool _matchesText(Lead lead, String query) {
    bool contains(String? value) =>
        value != null && value.toLowerCase().contains(query);

    if (contains(lead.name) || contains(lead.category) || contains(lead.area)) {
      return true;
    }

    final String domain = _domainOf(lead.website);
    if (domain.isNotEmpty && domain.contains(query)) {
      return true;
    }

    for (final EmailContact email in lead.emails) {
      if (contains(email.value)) {
        return true;
      }
    }

    final String queryDigits = _digitsOf(query);
    for (final PhoneContact phone in lead.phones) {
      if (contains(phone.value)) {
        return true;
      }
      if (queryDigits.length >= 3 &&
          _digitsOf(phone.value).contains(queryDigits)) {
        return true;
      }
    }

    return false;
  }

  static String _domainOf(String? website) {
    if (website == null || website.isEmpty) {
      return '';
    }
    final String lower = website.toLowerCase();
    final int schemeEnd = lower.indexOf('://');
    final String withoutScheme = schemeEnd == -1
        ? lower
        : lower.substring(schemeEnd + 3);
    final int slash = withoutScheme.indexOf('/');
    return slash == -1 ? withoutScheme : withoutScheme.substring(0, slash);
  }

  static String _digitsOf(String value) => value.replaceAll(RegExp(r'\D'), '');

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ResultsFilter && other.chip == chip && other.text == text;
  }

  @override
  int get hashCode => Object.hash(chip, text);

  @override
  String toString() => 'ResultsFilter(${chip.name}, "$text")';
}

/// Whether [lead] satisfies the parts of [filters] that can be checked locally.
///
/// Applying the whole [SearchFilters] here would be wrong: `hasEmail` and
/// `hasPhone` are **engine** constraints (the search never returns a lead that
/// breaks them), and re-checking them would hide the leads the engine chose to
/// return — the mockup's 42 leads include two without a phone. Open status, depth,
/// max results and the cleanup flags are deliberately absent too: they change the
/// search, so Results asks for a new one instead of pretending.
///
/// What can be applied locally: website presence, WhatsApp presence, social
/// links, "no website", minimum rating, minimum reviews, required and excluded
/// keywords.
bool matchesLocalFilters(Lead lead, SearchFilters filters) {
  if (filters.hasWebsite && !lead.hasWebsite) {
    return false;
  }
  if (filters.hasWhatsApp && !ContactRules.canWhatsApp(lead)) {
    return false;
  }
  if (filters.hasSocial && lead.socialLinks.isEmpty) {
    return false;
  }
  if (filters.noWebsite && lead.hasWebsite) {
    return false;
  }
  final double? minRating = filters.minRating;
  if (minRating != null && (lead.rating ?? 0) < minRating) {
    return false;
  }
  final int? minReviews = filters.minReviews;
  if (minReviews != null && (lead.reviewCount ?? 0) < minReviews) {
    return false;
  }

  final String haystack = <String>[
    lead.name,
    lead.category,
    lead.area,
  ].join(' ').toLowerCase();

  for (final String keyword in filters.mustInclude) {
    if (!haystack.contains(keyword.trim().toLowerCase())) {
      return false;
    }
  }
  for (final String keyword in filters.exclude) {
    if (haystack.contains(keyword.trim().toLowerCase())) {
      return false;
    }
  }
  return true;
}

/// Client-side ordering for a finished (or still arriving) result set.
///
/// Relevance is the engine's own order, so it is the identity: a search's best
/// match stays first no matter when a batch arrived. Rating and reviews exist
/// only for Maps leads, and leads **without** the value sort last instead of
/// being treated as zero.
abstract final class ResultsSort {
  const ResultsSort._();

  /// Sort options shown in the Results menu, in order.
  static const List<SortOption> menuOptions = <SortOption>[
    SortOption.relevance,
    SortOption.rating,
    SortOption.reviews,
    SortOption.name,
  ];

  /// A new list sorted by [option]; the input is left untouched.
  static List<Lead> apply(Iterable<Lead> leads, SortOption option) {
    final List<Lead> sorted = <Lead>[...leads];
    if (option == SortOption.relevance || sorted.length < 2) {
      return List<Lead>.unmodifiable(sorted);
    }

    // A stable tie-break on the incoming order keeps batches deterministic.
    final Map<Lead, int> arrival = <Lead, int>{
      for (int index = 0; index < sorted.length; index++) sorted[index]: index,
    };

    int byArrival(Lead a, Lead b) => arrival[a]!.compareTo(arrival[b]!);

    sorted.sort((Lead a, Lead b) {
      final int primary = switch (option) {
        SortOption.relevance => 0,
        SortOption.rating => _compareNullableDesc(a.rating, b.rating, _cmpNum),
        SortOption.reviews => _compareNullableDesc(
          a.reviewCount,
          b.reviewCount,
          _cmpNum,
        ),
        SortOption.newest => b.discoveredAt.compareTo(a.discoveredAt),
        SortOption.name => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      };
      return primary != 0 ? primary : byArrival(a, b);
    });

    return List<Lead>.unmodifiable(sorted);
  }

  /// Descending, with `null` last in both directions.
  static int _compareNullableDesc<T extends num>(
    T? a,
    T? b,
    int Function(T, T) compare,
  ) {
    if (a == null && b == null) {
      return 0;
    }
    if (a == null) {
      return 1;
    }
    if (b == null) {
      return -1;
    }
    return compare(b, a);
  }

  static int _cmpNum(num a, num b) => a.compareTo(b);
}
