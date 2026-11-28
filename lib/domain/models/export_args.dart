import 'package:flutter/foundation.dart';

import 'export_options.dart';
import 'model_equality.dart';

/// What Results hands to the Export screen.
///
/// The export screen owns formats, columns and file names, but only Results knows
/// *which* leads the user meant and how many there were. Passing them as the route
/// `extra` keeps the two screens decoupled: no shared mutable selection state and
/// no re-derivation of the result set.
///
/// [scope] is a **hint**, not a lock: Export may still offer to export everything
/// in [leadIds]. [leadIds] is already narrowed — the selected leads when there is
/// a selection, otherwise every currently visible (filtered and sorted) lead.
@immutable
class ExportArgs {
  const ExportArgs({
    required this.title,
    required this.leadIds,
    this.scope = ExportScope.allLeads,
    this.resultCount = 0,
    this.withEmail = 0,
    this.withPhone = 0,
  }) : assert(resultCount >= 0, 'A result count cannot be negative'),
       assert(withEmail >= 0, 'An email count cannot be negative'),
       assert(withPhone >= 0, 'A phone count cannot be negative');

  /// The query title ("Dentists in Ahmedabad"), used as a file-name hint.
  final String title;

  /// The lead ids to export, in the order they appear on screen.
  final List<String> leadIds;

  /// Whether this is a selection or the whole visible list.
  final ExportScope scope;

  /// How many leads the search returned before client-side filtering.
  final int resultCount;

  /// How many leads have an email.
  final int withEmail;

  /// How many leads have a phone.
  final int withPhone;

  /// Number of leads in this export.
  int get leadCount => leadIds.length;

  /// True when the selection is what will be exported.
  bool get isSelection => scope == ExportScope.selectedOnly;

  /// Copy with selected fields replaced.
  ExportArgs copyWith({
    String? title,
    List<String>? leadIds,
    ExportScope? scope,
    int? resultCount,
    int? withEmail,
    int? withPhone,
  }) {
    return ExportArgs(
      title: title ?? this.title,
      leadIds: leadIds ?? this.leadIds,
      scope: scope ?? this.scope,
      resultCount: resultCount ?? this.resultCount,
      withEmail: withEmail ?? this.withEmail,
      withPhone: withPhone ?? this.withPhone,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ExportArgs &&
            other.title == title &&
            listsEqual<String>(other.leadIds, leadIds) &&
            other.scope == scope &&
            other.resultCount == resultCount &&
            other.withEmail == withEmail &&
            other.withPhone == withPhone;
  }

  @override
  int get hashCode => Object.hash(
    title,
    listsHash<String>(leadIds),
    scope,
    resultCount,
    withEmail,
    withPhone,
  );

  @override
  String toString() => 'ExportArgs($leadCount leads, ${scope.name}, $title)';
}
