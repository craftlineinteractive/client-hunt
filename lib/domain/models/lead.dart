import 'package:flutter/foundation.dart';

import 'contact_point.dart';
import 'lead_source.dart';
import 'lead_status.dart';
import 'model_equality.dart';

/// A single business the user can save, contact and track.
///
/// [Lead] is a data shape only. It carries three groups of fields:
///
/// * **identity** — name, category, address parts and coordinates;
/// * **discovery** — sources, contact points, social links, Maps-only quality
///   fields, confidence and when it was found;
/// * **CRM** — local state the user owns: saved flag, status, tags, note,
///   reminder and list membership.
///
/// Rating, [reviewCount] and [isOpenNow] are nullable on purpose: they exist only
/// for Maps leads, so a social-only lead must leave them null and the UI must hide
/// the corresponding widgets instead of showing zeros (README section 7).
@immutable
class Lead {
  const Lead({
    required this.id,
    required this.name,
    this.category = '',
    this.address = '',
    this.area = '',
    this.city = '',
    this.state = '',
    this.country = 'India',
    this.latitude,
    this.longitude,
    this.phones = const <PhoneContact>[],
    this.emails = const <EmailContact>[],
    this.website,
    this.socialLinks = const <LeadSource, String>{},
    this.rating,
    this.reviewCount,
    this.isOpenNow,
    this.openingHours,
    this.sources = const <LeadSource>{},
    this.confidenceScore = 0,
    required this.discoveredAt,
    this.isSaved = false,
    this.savedAt,
    this.status = LeadStatus.newLead,
    this.tags = const <String>[],
    this.note = '',
    this.reminderAt,
    this.listIds = const <String>[],
  }) : assert(
         confidenceScore >= 0 && confidenceScore <= 100,
         'Confidence score is 0..100',
       );

  /// Stable local identifier.
  final String id;

  /// Business name.
  final String name;

  /// Canonical category ("Dental clinic", "Artisan cafe").
  final String category;

  /// Full street address, if known.
  final String address;

  /// Neighbourhood / locality.
  final String area;

  /// City.
  final String city;

  /// State or region.
  final String state;

  /// Country.
  final String country;

  /// Latitude, when the source provided coordinates (Maps, or geocoded later).
  final double? latitude;

  /// Longitude, when known.
  final double? longitude;

  /// All discovered phone numbers, best first.
  final List<PhoneContact> phones;

  /// All discovered email addresses, best first.
  final List<EmailContact> emails;

  /// Public website domain or URL.
  final String? website;

  /// Social profile URLs keyed by source.
  final Map<LeadSource, String> socialLinks;

  /// Maps rating 0–5; null for non-Maps leads.
  final double? rating;

  /// Maps review count; null for non-Maps leads.
  final int? reviewCount;

  /// Live open state; null when the source cannot provide it.
  final bool? isOpenNow;

  /// Human opening-hours text ("Mon-Sat, 9AM-8PM").
  final String? openingHours;

  /// Every source this lead was seen on.
  final Set<LeadSource> sources;

  /// Engine confidence, 0 to 100.
  final int confidenceScore;

  /// When the lead was first discovered.
  final DateTime discoveredAt;

  /// Whether the user saved this lead.
  final bool isSaved;

  /// When the user saved it.
  final DateTime? savedAt;

  /// CRM stage.
  final LeadStatus status;

  /// User tags ("Hot lead", "Follow up").
  final List<String> tags;

  /// Private note; on-device only.
  final String note;

  /// Follow-up reminder time.
  final DateTime? reminderAt;

  /// Ids of the user's lists that contain this lead.
  final List<String> listIds;

  /// True when at least one phone number exists.
  bool get hasPhone => phones.isNotEmpty;

  /// True when at least one email exists.
  bool get hasEmail => emails.isNotEmpty;

  /// True when a website was found.
  bool get hasWebsite => website != null && website!.isNotEmpty;

  /// True when there is any way to reach the business.
  bool get hasContactInfo => hasPhone || hasEmail;

  /// The preferred phone, or the first one.
  PhoneContact? get primaryPhone {
    if (phones.isEmpty) {
      return null;
    }
    return phones.firstWhere(
      (PhoneContact phone) => phone.isPrimary,
      orElse: () => phones.first,
    );
  }

  /// The preferred email, or the first one.
  EmailContact? get primaryEmail {
    if (emails.isEmpty) {
      return null;
    }
    return emails.firstWhere(
      (EmailContact email) => email.isPrimary,
      orElse: () => emails.first,
    );
  }

  /// True when the lead came from Maps and therefore may carry rating data.
  bool get hasMapsData => sources.contains(LeadSource.maps);

  /// Copy with selected fields replaced.
  ///
  /// Passing `null` leaves a field unchanged — it does not clear it. To clear a
  /// nullable field, construct a new [Lead] or use [withoutReminder].
  Lead copyWith({
    String? id,
    String? name,
    String? category,
    String? address,
    String? area,
    String? city,
    String? state,
    String? country,
    double? latitude,
    double? longitude,
    List<PhoneContact>? phones,
    List<EmailContact>? emails,
    String? website,
    Map<LeadSource, String>? socialLinks,
    double? rating,
    int? reviewCount,
    bool? isOpenNow,
    String? openingHours,
    Set<LeadSource>? sources,
    int? confidenceScore,
    DateTime? discoveredAt,
    bool? isSaved,
    DateTime? savedAt,
    LeadStatus? status,
    List<String>? tags,
    String? note,
    DateTime? reminderAt,
    List<String>? listIds,
  }) {
    return Lead(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      address: address ?? this.address,
      area: area ?? this.area,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      phones: phones ?? this.phones,
      emails: emails ?? this.emails,
      website: website ?? this.website,
      socialLinks: socialLinks ?? this.socialLinks,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      isOpenNow: isOpenNow ?? this.isOpenNow,
      openingHours: openingHours ?? this.openingHours,
      sources: sources ?? this.sources,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      discoveredAt: discoveredAt ?? this.discoveredAt,
      isSaved: isSaved ?? this.isSaved,
      savedAt: savedAt ?? this.savedAt,
      status: status ?? this.status,
      tags: tags ?? this.tags,
      note: note ?? this.note,
      reminderAt: reminderAt ?? this.reminderAt,
      listIds: listIds ?? this.listIds,
    );
  }

  /// Copy with the follow-up reminder cleared.
  Lead withoutReminder() {
    return Lead(
      id: id,
      name: name,
      category: category,
      address: address,
      area: area,
      city: city,
      state: state,
      country: country,
      latitude: latitude,
      longitude: longitude,
      phones: phones,
      emails: emails,
      website: website,
      socialLinks: socialLinks,
      rating: rating,
      reviewCount: reviewCount,
      isOpenNow: isOpenNow,
      openingHours: openingHours,
      sources: sources,
      confidenceScore: confidenceScore,
      discoveredAt: discoveredAt,
      isSaved: isSaved,
      savedAt: savedAt,
      status: status,
      tags: tags,
      note: note,
      // reminderAt is omitted on purpose: the constructor default clears it.
      listIds: listIds,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Lead &&
            other.id == id &&
            other.name == name &&
            other.category == category &&
            other.address == address &&
            other.area == area &&
            other.city == city &&
            other.state == state &&
            other.country == country &&
            other.latitude == latitude &&
            other.longitude == longitude &&
            listsEqual<PhoneContact>(other.phones, phones) &&
            listsEqual<EmailContact>(other.emails, emails) &&
            other.website == website &&
            mapsEqual<LeadSource, String>(other.socialLinks, socialLinks) &&
            other.rating == rating &&
            other.reviewCount == reviewCount &&
            other.isOpenNow == isOpenNow &&
            other.openingHours == openingHours &&
            setsEqual<LeadSource>(other.sources, sources) &&
            other.confidenceScore == confidenceScore &&
            other.discoveredAt == discoveredAt &&
            other.isSaved == isSaved &&
            other.savedAt == savedAt &&
            other.status == status &&
            listsEqual<String>(other.tags, tags) &&
            other.note == note &&
            other.reminderAt == reminderAt &&
            listsEqual<String>(other.listIds, listIds);
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    id,
    name,
    category,
    address,
    area,
    city,
    state,
    country,
    latitude,
    longitude,
    listsHash<PhoneContact>(phones),
    listsHash<EmailContact>(emails),
    website,
    mapsHash<LeadSource, String>(socialLinks),
    rating,
    reviewCount,
    isOpenNow,
    openingHours,
    setsHash<LeadSource>(sources),
    confidenceScore,
    discoveredAt,
    isSaved,
    savedAt,
    status,
    listsHash<String>(tags),
    note,
    reminderAt,
    listsHash<String>(listIds),
  ]);

  @override
  String toString() =>
      'Lead($id, $name, ${phones.length} phones, ${emails.length} emails)';
}
