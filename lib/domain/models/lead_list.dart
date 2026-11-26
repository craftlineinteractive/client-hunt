import 'package:flutter/foundation.dart';

/// A user-created list of saved leads ("Hot leads", "Follow up", "Dentists").
///
/// [count] is denormalized for the filter chips so the UI can show "Hot leads 14"
/// without loading every saved lead. The data layer (prompt C) keeps it in sync.
@immutable
class LeadList {
  const LeadList({required this.id, required this.name, this.count = 0})
    : assert(count >= 0, 'A list count cannot be negative');

  /// Stable local identifier.
  final String id;

  /// User-facing name.
  final String name;

  /// Number of leads in the list.
  final int count;

  /// Copy with selected fields replaced.
  LeadList copyWith({String? id, String? name, int? count}) {
    return LeadList(
      id: id ?? this.id,
      name: name ?? this.name,
      count: count ?? this.count,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is LeadList &&
            other.id == id &&
            other.name == name &&
            other.count == count;
  }

  @override
  int get hashCode => Object.hash(id, name, count);

  @override
  String toString() => 'LeadList($id, $name, $count)';
}
