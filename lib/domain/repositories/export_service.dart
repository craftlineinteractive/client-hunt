import 'package:flutter/foundation.dart';

import '../models/models.dart';

/// What an export produced.
@immutable
class ExportResult {
  const ExportResult({
    required this.filePath,
    required this.byteSize,
    required this.format,
    required this.leadCount,
  });

  /// Absolute path of the written file, shown in the share sheet.
  final String filePath;

  /// File size in bytes, for the "about 12 KB" summary.
  final int byteSize;

  /// Format that was written.
  final ExportFormat format;

  /// Leads included in the file.
  final int leadCount;

  @override
  String toString() =>
      'ExportResult($format: $filePath, $byteSize bytes, $leadCount leads)';
}

/// Writing files and copying contact lists to the clipboard.
///
/// Implemented by a fake now (writes nothing, reports a plausible size) and by
/// prompt E with real CSV/XLSX/PDF/VCF writers plus the share sheet. The interface
/// returns a path so the UI can hand it to the share sheet without knowing the
/// format internals.
abstract interface class ExportService {
  /// Writes [leads] using [options] and returns the file details.
  Future<ExportResult> export(List<Lead> leads, ExportOptions options);

  /// Copies every email, one per line, and returns how many were copied.
  Future<int> copyEmails(List<Lead> leads);

  /// Copies every phone, one per line, and returns how many were copied.
  Future<int> copyPhones(List<Lead> leads);
}
