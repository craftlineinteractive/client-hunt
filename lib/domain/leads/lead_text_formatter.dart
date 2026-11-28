import '../models/models.dart';

/// Turns a [Lead] into the plain-text block used by "Copy all details" and the
/// share sheet.
///
/// The order is fixed so the same lead always copies the same way: name, the
/// category/area line, every phone, every email, website, address, social links,
/// then rating and reviews. Empty fields are skipped entirely — no blank lines
/// and no placeholders — and nothing here claims a value was checked: the block
/// is what the app knows, not a promise that it is accurate.
///
/// [includeSocialLinks] is false for a Free user, whose profile handles are
/// gated on Lead Detail; the formatter then omits the lines rather than leaking
/// them through a copy action.
abstract final class LeadTextFormatter {
  const LeadTextFormatter._();

  /// The text block for [lead].
  static String format(Lead lead, {bool includeSocialLinks = true}) {
    final List<String> lines = <String>[lead.name.trim()];

    final String where = _locationLine(lead);
    if (where.isNotEmpty) {
      lines.add(where);
    }

    for (final PhoneContact phone in lead.phones) {
      lines.add(_phoneLine(phone));
    }
    for (final EmailContact email in lead.emails) {
      final String value = email.value.trim();
      if (value.isNotEmpty) {
        lines.add(value);
      }
    }

    final String? website = lead.website?.trim();
    if (website != null && website.isNotEmpty) {
      lines.add(website);
    }

    final String address = lead.address.trim();
    if (address.isNotEmpty) {
      lines.add(address);
    }

    if (includeSocialLinks) {
      for (final MapEntry<LeadSource, String> social
          in lead.socialLinks.entries) {
        final String url = social.value.trim();
        if (url.isNotEmpty) {
          lines.add('${social.key.displayName}: $url');
        }
      }
    }

    final double? rating = lead.rating;
    if (rating != null) {
      final int? reviews = lead.reviewCount;
      lines.add(
        reviews == null
            ? 'Rating: ${rating.toStringAsFixed(1)}'
            : 'Rating: ${rating.toStringAsFixed(1)} ($reviews reviews)',
      );
    } else if (lead.reviewCount != null) {
      // Reviews without a rating never happen on Maps data, but a block that
      // silently dropped the count would be worse than an odd line.
      lines.add('Reviews: ${lead.reviewCount}');
    }

    return lines.join('\n');
  }

  /// "Dental clinic · Navrangpura, Ahmedabad", skipping missing pieces.
  static String _locationLine(Lead lead) {
    final String category = lead.category.trim();
    final List<String> place = <String>[
      if (lead.area.trim().isNotEmpty) lead.area.trim(),
      if (lead.city.trim().isNotEmpty) lead.city.trim(),
    ];
    final String location = place.join(', ');
    if (category.isEmpty) {
      return location;
    }
    return location.isEmpty ? category : '$category · $location';
  }

  static String _phoneLine(PhoneContact phone) {
    final String value = phone.value.trim();
    final String kind = phone.kind.displayName;
    return value.isEmpty ? kind : '$value ($kind)';
  }
}
