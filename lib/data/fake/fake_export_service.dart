import 'dart:async';

import '../../domain/models/models.dart';
import '../../domain/repositories/export_service.dart';

/// Pretends to write an export file and to copy contact lists.
///
/// Nothing touches the filesystem or the clipboard: the returned path is a
/// placeholder under `/exports/`, and the byte size is estimated from the lead
/// count and selected columns. Prompt E replaces this with real writers and the
/// share sheet.
class FakeExportService implements ExportService {
  const FakeExportService({this.latency = const Duration(milliseconds: 150)});

  /// Simulated work latency.
  final Duration latency;

  @override
  Future<ExportResult> export(List<Lead> leads, ExportOptions options) async {
    await _pause();
    const int bytesPerLead = 180;
    final int perLead = bytesPerLead * (2 + options.columns.length) ~/ 7;
    return ExportResult(
      filePath: '/exports/${options.fullFileName}',
      byteSize: (leads.length * perLead).clamp(0, 1 << 31),
      format: options.format,
      leadCount: leads.length,
    );
  }

  @override
  Future<int> copyEmails(List<Lead> leads) async {
    await _pause();
    return leads
        .where((Lead lead) => lead.hasEmail)
        .fold<int>(0, (int total, Lead lead) => total + lead.emails.length);
  }

  @override
  Future<int> copyPhones(List<Lead> leads) async {
    await _pause();
    return leads
        .where((Lead lead) => lead.hasPhone)
        .fold<int>(0, (int total, Lead lead) => total + lead.phones.length);
  }

  Future<void> _pause() async {
    if (latency > Duration.zero) {
      await Future<void>.delayed(latency);
    }
  }
}
