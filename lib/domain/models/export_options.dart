import 'package:flutter/foundation.dart';

import 'model_equality.dart';

/// File format for an export.
enum ExportFormat {
  /// Comma-separated values. The only format available on Free.
  csv(displayName: 'CSV', fileExtension: '.csv'),

  /// Excel workbook.
  xlsx(displayName: 'Excel', fileExtension: '.xlsx'),

  /// Printable PDF table.
  pdf(displayName: 'PDF', fileExtension: '.pdf'),

  /// vCard contact file, one card per lead.
  vcf(displayName: 'VCF', fileExtension: '.vcf');

  const ExportFormat({required this.displayName, required this.fileExtension});

  /// Format name shown on the tile.
  final String displayName;

  /// Extension appended to the file name.
  final String fileExtension;

  /// Whether this format requires Pro.
  bool get isPro => this != ExportFormat.csv;
}

/// Which leads go into the export.
enum ExportScope {
  /// Every lead in the current result set.
  allLeads(displayName: 'All leads'),

  /// Only the leads selected in the list.
  selectedOnly(displayName: 'Selected only'),

  /// Only leads that have an email.
  onlyWithEmail(displayName: 'Only with email'),

  /// Only leads that have a phone.
  onlyWithPhone(displayName: 'Only with phone');

  const ExportScope({required this.displayName});

  /// Label for the scope radio row.
  final String displayName;
}

/// A column that can be included in an export file.
enum ExportColumn {
  name(displayName: 'Name'),
  phone(displayName: 'Phone'),
  email(displayName: 'Email'),
  website(displayName: 'Website'),
  address(displayName: 'Address'),
  category(displayName: 'Category'),
  rating(displayName: 'Rating'),
  reviews(displayName: 'Reviews'),
  source(displayName: 'Source'),
  socialLinks(displayName: 'Social links'),
  notes(displayName: 'Notes'),
  tags(displayName: 'Tags'),
  status(displayName: 'Status');

  const ExportColumn({required this.displayName});

  /// Chip label.
  final String displayName;
}

/// Everything the Export screen can configure.
///
/// [columns] is a set because order is fixed by [ExportColumn] declaration order
/// when writing the file; the UI shows selection state only.
@immutable
class ExportOptions {
  const ExportOptions({
    this.scope = ExportScope.allLeads,
    this.format = ExportFormat.csv,
    this.columns = const <ExportColumn>{
      ExportColumn.name,
      ExportColumn.phone,
      ExportColumn.email,
      ExportColumn.website,
      ExportColumn.address,
    },
    this.fileName = 'leads',
    this.removeDuplicates = true,
    this.skipNoContact = false,
    this.headerRow = true,
  });

  /// Which leads to include.
  final ExportScope scope;

  /// Output format.
  final ExportFormat format;

  /// Selected columns.
  final Set<ExportColumn> columns;

  /// File name without extension.
  final String fileName;

  /// Merge duplicate leads before writing.
  final bool removeDuplicates;

  /// Drop leads with neither an email nor a phone.
  final bool skipNoContact;

  /// Write a header row (CSV/Excel only).
  final bool headerRow;

  /// The file name plus the selected format's extension.
  String get fullFileName => '$fileName${format.fileExtension}';

  /// Copy with selected fields replaced.
  ExportOptions copyWith({
    ExportScope? scope,
    ExportFormat? format,
    Set<ExportColumn>? columns,
    String? fileName,
    bool? removeDuplicates,
    bool? skipNoContact,
    bool? headerRow,
  }) {
    return ExportOptions(
      scope: scope ?? this.scope,
      format: format ?? this.format,
      columns: columns ?? this.columns,
      fileName: fileName ?? this.fileName,
      removeDuplicates: removeDuplicates ?? this.removeDuplicates,
      skipNoContact: skipNoContact ?? this.skipNoContact,
      headerRow: headerRow ?? this.headerRow,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ExportOptions &&
            other.scope == scope &&
            other.format == format &&
            setsEqual<ExportColumn>(other.columns, columns) &&
            other.fileName == fileName &&
            other.removeDuplicates == removeDuplicates &&
            other.skipNoContact == skipNoContact &&
            other.headerRow == headerRow;
  }

  @override
  int get hashCode => Object.hash(
    scope,
    format,
    setsHash<ExportColumn>(columns),
    fileName,
    removeDuplicates,
    skipNoContact,
    headerRow,
  );

  @override
  String toString() =>
      'ExportOptions($fullFileName, ${columns.length} columns)';
}
